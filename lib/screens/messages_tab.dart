import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_theme.dart';
import '../services/websocket_service.dart';
import '../services/chat_service.dart';
import '../utils/time_utils.dart';
import '../utils/localization_helper.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'chat_screen.dart';
import '../config/debug_config.dart';
import 'dart:math' as math;

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
  
  // 🔥 新增：缓存和节流机制
  final Map<String, Map<String, dynamic>> _messageCache = {}; // 消息缓存
  final Map<String, DateTime> _lastRequestTime = {}; // 最后请求时间
  DateTime? _lastRefreshTime; // 最后刷新时间
  static const Duration _cacheValidDuration = Duration(minutes: 5); // 缓存有效期5分钟
  static const Duration _requestThrottleDuration = Duration(seconds: 30); // 请求节流30秒
  static const Duration _refreshThrottleDuration = Duration(seconds: 10); // 刷新节流10秒
  
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
  
  // 🔥 优化：智能加载对话 - 减少服务器请求
  Future<void> _loadConversations() async {
    final now = DateTime.now();
    
    // 检查刷新节流
    if (_lastRefreshTime != null) {
      final timeSinceLastRefresh = now.difference(_lastRefreshTime!);
      if (timeSinceLastRefresh < _refreshThrottleDuration) {
        DebugConfig.debugPrint('对话刷新过于频繁，跳过 (距离上次 ${timeSinceLastRefresh.inSeconds}秒)', module: 'MESSAGE');
        return;
      }
    }
    
    _lastRefreshTime = now;
    
    if (!mounted) return;
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final currentGroup = groupProvider.currentGroup;
      final currentDevice = authProvider.deviceInfo ?? authProvider.profile;
      
      if (currentGroup == null) {
        DebugConfig.debugPrint('当前没有选择群组，清空对话列表', module: 'MESSAGE');
        if (mounted) {
          setState(() {
            _conversations = [];
            _isRefreshing = false;
          });
        }
        return;
      }
      
      DebugConfig.debugPrint('开始加载对话列表');
      DebugConfig.debugPrint('当前群组: ${currentGroup?['name']}');
      DebugConfig.debugPrint('当前设备: ${currentDevice?['id']} (${currentDevice?['name']})');
      
      // 构建对话列表：群聊 + 私聊
      List<Map<String, dynamic>> conversations = [];
      Set<String> processedDeviceIds = {}; // 用于避免重复添加设备
      
      // 获取本地化文本
      final l10n = LocalizationHelper.of(context);
      
      // 只处理当前选中的群组
      if (currentGroup != null && currentDevice != null) {
        final devices = List<Map<String, dynamic>>.from(currentGroup['devices'] ?? []);
        final groupId = currentGroup['id'];
        
        DebugConfig.debugPrint('处理群组: ${currentGroup['name']}, 设备数量: ${devices.length}');
        
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
            DebugConfig.errorPrint('获取群组最新消息失败: $e');
          }
          
          conversations.add({
            'id': 'group_$groupId',
            'type': 'group',
            'title': currentGroup['name'] ?? l10n.groups,
            'subtitle': devices.length == 1 ? l10n.onlyMyself : l10n.devicesCount(devices.length),
            'avatar': _getGroupAvatar(devices),
            'lastMessage': lastGroupMessage?['content'] ?? (devices.length == 1 ? l10n.sendToMyself : l10n.clickToStartGroupChat),
            'lastTime': lastGroupMessage?['createdAt'] ?? DateTime.now().toIso8601String(),
            'unreadCount': 0,
            'isOnline': devices.any((d) => d['isOnline'] == true),
            'groupData': currentGroup,
          });
          
          DebugConfig.debugPrint('添加群聊对话: ${currentGroup['name']} (${devices.length}台设备)');
        }
        
        // 2. 添加设备间的私聊对话（包括当前群组中的所有设备，包含自己）
        if (devices.isNotEmpty) {
          DebugConfig.debugPrint('开始加载对话，设备数量: ${devices.length}', module: 'MESSAGE');
          
          // 🔥 优化：批处理消息获取，而不是逐个请求
          final List<Future<void>> messageFutures = [];
          
          for (var device in devices) {
            final deviceId = device['id'];
            
          // 添加所有设备的私聊对话，包括自己
          if (deviceId != null && !processedDeviceIds.contains(deviceId)) {
              processedDeviceIds.add(deviceId);
            
            final isCurrentDevice = deviceId == currentDevice['id'];
              
              // 🔥 创建异步任务，而不是立即执行
              messageFutures.add(_loadDeviceConversation(
                device, deviceId, isCurrentDevice, conversations, l10n));
                }
          }
          
          // 🔥 并发执行，但限制并发数量避免服务器过载
          const batchSize = 3; // 每批最多3个请求
          for (int i = 0; i < messageFutures.length; i += batchSize) {
            final batch = messageFutures
                .skip(i)
                .take(math.min(batchSize, messageFutures.length - i))
                .toList();
            await Future.wait(batch);
            
            // 批次间稍作延迟
            if (i + batchSize < messageFutures.length) {
              await Future.delayed(const Duration(milliseconds: 200));
            }
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
          DebugConfig.errorPrint('时间排序失败: $e');
          return 0;
        }
      });
      
      DebugConfig.debugPrint('总对话数量: ${conversations.length}');
      
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
      DebugConfig.errorPrint('加载对话失败: $e');
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
          final l10n = LocalizationHelper.of(context);
          final groupConversation = {
            'id': 'group_${currentGroup['id']}',
            'type': 'group',
            'title': currentGroup['name'] ?? l10n.groups,
            'subtitle': devices.length == 1 ? l10n.onlyMyself : l10n.devicesCount(devices.length),
            'avatar': _getGroupAvatar(devices),
            'lastMessage': devices.length == 1 ? l10n.sendToMyself : l10n.clickToStartGroupChat,
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
    final l10n = LocalizationHelper.of(context);
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
            l10n.noConversations,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.joinGroupToStartChat,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textTertiaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoGroupSelectedState() {
    final l10n = LocalizationHelper.of(context);
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
            l10n.pleaseSelectGroup,
            style: AppTheme.displayStyle,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.clickGroupSelectorHint,
            style: AppTheme.captionStyle,
          ),
      ],
      ),
    );
  }

  // 🔥 新增：智能加载单个设备对话
  Future<void> _loadDeviceConversation(
    Map<String, dynamic> device,
    String deviceId,
    bool isCurrentDevice,
    List<Map<String, dynamic>> conversations,
    dynamic l10n,
  ) async {
    final now = DateTime.now();
    
    // 检查缓存是否有效
    if (_messageCache.containsKey(deviceId)) {
      final lastRequestTime = _lastRequestTime[deviceId];
      if (lastRequestTime != null) {
        final timeSinceLastRequest = now.difference(lastRequestTime);
        if (timeSinceLastRequest < _cacheValidDuration) {
          // 使用缓存数据
          final cachedMessage = _messageCache[deviceId];
          _addConversationFromCache(device, deviceId, isCurrentDevice, conversations, l10n, cachedMessage);
          DebugConfig.debugPrint('使用缓存数据: ${device['name']} (缓存年龄: ${timeSinceLastRequest.inMinutes}分钟)', module: 'MESSAGE');
          return;
        }
      }
    }
    
    // 检查请求节流
    final lastRequestTime = _lastRequestTime[deviceId];
    if (lastRequestTime != null) {
      final timeSinceLastRequest = now.difference(lastRequestTime);
      if (timeSinceLastRequest < _requestThrottleDuration) {
        // 使用默认数据，跳过网络请求
        _addConversationDefault(device, deviceId, isCurrentDevice, conversations, l10n);
        DebugConfig.debugPrint('请求过于频繁，使用默认数据: ${device['name']} (距离上次 ${timeSinceLastRequest.inSeconds}秒)', module: 'MESSAGE');
        return;
      }
    }

    // 获取与该设备的最新消息
    Map<String, dynamic>? lastPrivateMessage;
    try {
      _lastRequestTime[deviceId] = now;
      DebugConfig.debugPrint('获取设备消息: ${device['name']} ($deviceId)', module: 'MESSAGE');
      
      final privateMessages = await _chatService.getPrivateMessages(targetDeviceId: deviceId, limit: 1);
      if (privateMessages['messages'] != null && (privateMessages['messages'] as List).isNotEmpty) {
        lastPrivateMessage = (privateMessages['messages'] as List).first;
        // 缓存结果
        _messageCache[deviceId] = lastPrivateMessage!;
      } else {
        // 缓存空结果
        _messageCache[deviceId] = {};
      }
    } catch (e) {
      DebugConfig.errorPrint('获取与设备${device['name']}的最新消息失败: $e');
      // 即使失败也要缓存，避免重复请求
      _messageCache[deviceId] = {};
    }

    _addConversationFromMessage(device, deviceId, isCurrentDevice, conversations, l10n, lastPrivateMessage);
  }

  // 🔥 新增：从缓存数据添加对话
  void _addConversationFromCache(
    Map<String, dynamic> device,
    String deviceId,
    bool isCurrentDevice,
    List<Map<String, dynamic>> conversations,
    dynamic l10n,
    Map<String, dynamic>? cachedMessage,
  ) {
    conversations.add({
      'id': 'private_$deviceId',
      'type': 'private',
      'title': isCurrentDevice ? '${device['name']} (${l10n.myself})' : (device['name'] ?? l10n.unknownDevice),
      'subtitle': isCurrentDevice ? l10n.sendToMyself : (device['type'] ?? l10n.unknownType),
      'avatar': _getDeviceAvatar(device['type']),
      'lastMessage': cachedMessage?['content'] ?? (isCurrentDevice ? l10n.sendToMyself : l10n.clickToStartChat),
      'lastTime': cachedMessage?['createdAt'] ?? device['last_active_time'] ?? DateTime.now().toIso8601String(),
      'unreadCount': 0,
      'isOnline': device['isOnline'] == true,
      'deviceData': device,
    });
  }

  // 🔥 新增：从消息数据添加对话
  void _addConversationFromMessage(
    Map<String, dynamic> device,
    String deviceId,
    bool isCurrentDevice,
    List<Map<String, dynamic>> conversations,
    dynamic l10n,
    Map<String, dynamic>? lastPrivateMessage,
  ) {
    conversations.add({
      'id': 'private_$deviceId',
      'type': 'private',
      'title': isCurrentDevice ? '${device['name']} (${l10n.myself})' : (device['name'] ?? l10n.unknownDevice),
      'subtitle': isCurrentDevice ? l10n.sendToMyself : (device['type'] ?? l10n.unknownType),
      'avatar': _getDeviceAvatar(device['type']),
      'lastMessage': lastPrivateMessage?['content'] ?? (isCurrentDevice ? l10n.sendToMyself : l10n.clickToStartChat),
      'lastTime': lastPrivateMessage?['createdAt'] ?? device['last_active_time'] ?? DateTime.now().toIso8601String(),
      'unreadCount': 0,
      'isOnline': device['isOnline'] == true,
      'deviceData': device,
    });

    DebugConfig.debugPrint('添加私聊对话: ${device['name']} (${device['id']})${isCurrentDevice ? ' - 自己' : ''}', module: 'MESSAGE');
  }

  // 🔥 新增：使用默认数据添加对话
  void _addConversationDefault(
    Map<String, dynamic> device,
    String deviceId,
    bool isCurrentDevice,
    List<Map<String, dynamic>> conversations,
    dynamic l10n,
  ) {
    conversations.add({
      'id': 'private_$deviceId',
      'type': 'private',
      'title': isCurrentDevice ? '${device['name']} (${l10n.myself})' : (device['name'] ?? l10n.unknownDevice),
      'subtitle': isCurrentDevice ? l10n.sendToMyself : (device['type'] ?? l10n.unknownType),
      'avatar': _getDeviceAvatar(device['type']),
      'lastMessage': isCurrentDevice ? l10n.sendToMyself : l10n.clickToStartChat,
      'lastTime': device['last_active_time'] ?? DateTime.now().toIso8601String(),
      'unreadCount': 0,
      'isOnline': device['isOnline'] == true,
      'deviceData': device,
    });

    DebugConfig.debugPrint('添加私聊对话(默认): ${device['name']} (${device['id']})${isCurrentDevice ? ' - 自己' : ''}', module: 'MESSAGE');
  }
} 