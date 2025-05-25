import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_theme.dart';
import '../services/websocket_service.dart';
import '../services/chat_service.dart';
import '../utils/time_utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'chat_screen.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> with TickerProviderStateMixin {
  // 聊天相关状态
  List<Map<String, dynamic>> _conversations = [];
  StreamSubscription? _messageSubscription;
  StreamSubscription? _chatMessageSubscription;
  StreamSubscription? _groupChangeSubscription;
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  bool _isRefreshing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ChatService _chatService = ChatService();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    // 初始化聊天数据
    _loadConversations();
    _subscribeToMessages();
    _subscribeToChatMessages();
    _subscribeToGroupChanges();
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _chatMessageSubscription?.cancel();
    _groupChangeSubscription?.cancel();
    _refreshController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  // 订阅消息更新
  void _subscribeToMessages() {
    final websocketService = WebSocketService();
    _messageSubscription = websocketService.onDeviceStatusChange.listen((data) {
      // 处理设备状态变化
      if (mounted) {
        _loadConversations();
      }
    });
  }
  
  // 订阅聊天消息
  void _subscribeToChatMessages() {
    final websocketService = WebSocketService();
    _chatMessageSubscription = websocketService.onChatMessage.listen((data) {
      // 处理新的聊天消息
      if (mounted) {
        print('收到聊天消息更新: ${data['type']}');
        _loadConversations(); // 简化处理，直接重新加载
      }
    });
  }
  
  // 订阅群组变化
  void _subscribeToGroupChanges() {
    final websocketService = WebSocketService();
    _groupChangeSubscription = websocketService.onGroupChange.listen((data) {
      // 处理群组变化
      if (mounted) {
        print('群组变化: $data');
        _loadConversations();
      }
    });
  }
  
  // 加载对话列表
  Future<void> _loadConversations() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final currentGroup = groupProvider.currentGroup;
      final currentDevice = authProvider.deviceInfo ?? authProvider.profile;
      
      print('开始加载对话列表');
      print('当前群组: ${currentGroup?['name']}');
      print('当前设备: ${currentDevice?['id']} (${currentDevice?['name']})');
      
      // 构建对话列表：群聊 + 私聊
      List<Map<String, dynamic>> conversations = [];
      Set<String> processedDeviceIds = {}; // 用于避免重复添加设备
      
      // 只处理当前选中的群组
      if (currentGroup != null && currentDevice != null) {
        final devices = List<Map<String, dynamic>>.from(currentGroup['devices'] ?? []);
        final groupId = currentGroup['id'];
        
        print('处理群组: ${currentGroup['name']}, 设备数量: ${devices.length}');
        
        // 1. 添加群聊对话（包括只有自己一台设备的情况）
        if (devices.isNotEmpty) {
          // 尝试获取群组的最新消息
          Map<String, dynamic>? lastGroupMessage;
          try {
            final groupMessages = await _chatService.getGroupMessages(groupId: groupId, limit: 1);
            if (groupMessages['messages'] != null && (groupMessages['messages'] as List).isNotEmpty) {
              lastGroupMessage = (groupMessages['messages'] as List).first;
            }
          } catch (e) {
            print('获取群组最新消息失败: $e');
          }
          
          conversations.add({
            'id': 'group_$groupId',
            'type': 'group',
            'title': currentGroup['name'] ?? '群组',
            'subtitle': devices.length == 1 ? '仅有自己' : '${devices.length}台设备',
            'avatar': _getGroupAvatar(devices),
            'lastMessage': lastGroupMessage?['content'] ?? (devices.length == 1 ? '发给自己的消息' : '点击开始群聊'),
            'lastTime': lastGroupMessage?['createdAt'] ?? DateTime.now().toIso8601String(),
            'unreadCount': 0,
            'isOnline': devices.any((d) => d['isOnline'] == true),
            'groupData': currentGroup,
          });
          
          print('添加群聊对话: ${currentGroup['name']} (${devices.length}台设备)');
        }
        
        // 2. 添加设备间的私聊对话（包括当前群组中的所有设备，包含自己）
          for (var device in devices) {
            final deviceId = device['id'];
            
          // 添加所有设备的私聊对话，包括自己
          if (deviceId != null && !processedDeviceIds.contains(deviceId)) {
              processedDeviceIds.add(deviceId);
            
            final isCurrentDevice = deviceId == currentDevice['id'];
              
              // 尝试获取与该设备的最新消息
              Map<String, dynamic>? lastPrivateMessage;
              try {
                final privateMessages = await _chatService.getPrivateMessages(targetDeviceId: deviceId, limit: 1);
                if (privateMessages['messages'] != null && (privateMessages['messages'] as List).isNotEmpty) {
                  lastPrivateMessage = (privateMessages['messages'] as List).first;
                }
              } catch (e) {
                print('获取与设备${device['name']}的最新消息失败: $e');
              }
              
              conversations.add({
                'id': 'private_$deviceId',
                'type': 'private',
              'title': isCurrentDevice ? '${device['name']} (我)' : (device['name'] ?? '未知设备'),
              'subtitle': isCurrentDevice ? '给自己发消息' : (device['type'] ?? '未知类型'),
                'avatar': _getDeviceAvatar(device['type']),
              'lastMessage': lastPrivateMessage?['content'] ?? (isCurrentDevice ? '给自己发消息' : '点击开始聊天'),
                'lastTime': lastPrivateMessage?['createdAt'] ?? device['last_active_time'] ?? DateTime.now().toIso8601String(),
                'unreadCount': 0,
                'isOnline': device['isOnline'] == true,
                'deviceData': device,
              });
              
            print('添加私聊对话: ${device['name']} (${device['id']})${isCurrentDevice ? ' - 自己' : ''}');
          }
        }
      }
      
      // 按最后消息时间排序
      conversations.sort((a, b) {
        try {
          final timeA = DateTime.parse(a['lastTime'] ?? DateTime.now().toIso8601String());
          final timeB = DateTime.parse(b['lastTime'] ?? DateTime.now().toIso8601String());
        return timeB.compareTo(timeA);
        } catch (e) {
          print('时间排序失败: $e');
          return 0;
        }
      });
      
      print('总对话数量: ${conversations.length}');
      
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isRefreshing = false;
        });
      
        // 完成下拉刷新
      if (_refreshController.isRefresh) {
        _refreshController.refreshCompleted();
        }
      }
    } catch (e) {
      print('加载对话失败: $e');
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        
        // 刷新失败
      if (_refreshController.isRefresh) {
        _refreshController.refreshFailed();
        }
      }
    }
  }
  
  String _getGroupAvatar(List<Map<String, dynamic>> devices) {
    // 根据设备类型生成群组头像
    if (devices.any((d) => d['type']?.contains('iPhone') == true)) {
      return '📱';
    } else if (devices.any((d) => d['type']?.contains('电脑') == true)) {
      return '💻';
    }
    return '👥';
  }
  
  String _getDeviceAvatar(String? deviceType) {
    switch (deviceType?.toLowerCase()) {
      case 'iphone':
      case 'ios设备':
        return '📱';
      case 'ipad':
        return '📟';
      case 'android':
      case 'android手机':
      case '安卓手机':
        return '📱';
      case 'mac电脑':
        return '💻';
      case 'windows电脑':
        return '💻';
      case 'linux电脑':
        return '🖥️';
      case 'web浏览器':
        return '🌐';
      default:
        return '📱';
    }
  }

    @override
  Widget build(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        final currentGroup = groupProvider.currentGroup;
        
        // 如果有选择的群组，显示群聊界面
        if (currentGroup != null) {
          // 构建群组对话数据
          final devices = List<Map<String, dynamic>>.from(currentGroup['devices'] ?? []);
          final groupConversation = {
            'id': 'group_${currentGroup['id']}',
            'type': 'group',
            'title': currentGroup['name'] ?? '群组',
            'subtitle': devices.length == 1 ? '仅有自己' : '${devices.length}台设备',
            'avatar': _getGroupAvatar(devices),
            'lastMessage': devices.length == 1 ? '发给自己的消息' : '点击开始群聊',
            'lastTime': DateTime.now().toIso8601String(),
            'unreadCount': 0,
            'isOnline': devices.any((d) => d['isOnline'] == true),
            'groupData': currentGroup,
          };
          
          // 使用群组ID作为key，确保群组变化时ChatScreen重建
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ChatScreen(
              key: ValueKey('chat_${currentGroup['id']}'),
              conversation: groupConversation,
            ),
          );
        }
        
        // 没有选择群组时显示空状态
        return FadeTransition(
          opacity: _fadeAnimation,
          child: _buildNoGroupSelectedState(),
        );
      },
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: AppTheme.textTertiaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无对话',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '加入设备群组后即可开始聊天',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textTertiaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoGroupSelectedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.groups_rounded,
              size: 28,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '请选择群组',
            style: AppTheme.displayStyle,
          ),
          const SizedBox(height: 8),
          Text(
            '点击顶部群组选择器来选择或创建群组',
            style: AppTheme.captionStyle,
          ),
      ],
      ),
    );
  }
} 