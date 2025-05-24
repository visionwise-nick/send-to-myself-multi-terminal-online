import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
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
    
    // 监听AuthProvider变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.addListener(_onAuthProviderChanged);
    });
  }

  @override
  void dispose() {
    // 移除AuthProvider监听
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.removeListener(_onAuthProviderChanged);
    
    _messageSubscription?.cancel();
    _chatMessageSubscription?.cancel();
    _groupChangeSubscription?.cancel();
    _refreshController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  // AuthProvider变化处理
  void _onAuthProviderChanged() {
    if (mounted) {
      print('检测到AuthProvider变化，刷新对话列表');
      _loadConversations();
    }
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
        switch (data['type']) {
          case 'new_private_message':
            _handleNewPrivateMessage(data);
            break;
          case 'new_group_message':
            _handleNewGroupMessage(data);
            break;
          case 'message_sent_confirmation':
          case 'group_message_sent_confirmation':
            _handleMessageSentConfirmation(data);
            break;
          case 'message_status_updated':
            _handleMessageStatusUpdate(data);
            break;
        }
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
  
  // 处理新的私聊消息
  void _handleNewPrivateMessage(Map<String, dynamic> data) {
    final message = data['message'];
    if (message == null) return;
    
    final sourceDeviceId = message['sourceDeviceId'];
    if (sourceDeviceId == null) return;
    
    // 在对话列表中找到对应的私聊对话并更新最后消息
    final conversationIndex = _conversations.indexWhere(
      (conv) => conv['type'] == 'private' && conv['deviceData']?['id'] == sourceDeviceId
    );
    
    if (conversationIndex != -1) {
      setState(() {
        _conversations[conversationIndex]['lastMessage'] = message['content'] ?? '收到新消息';
        _conversations[conversationIndex]['lastTime'] = message['createdAt'] ?? DateTime.now().toIso8601String();
        _conversations[conversationIndex]['unreadCount'] = (_conversations[conversationIndex]['unreadCount'] ?? 0) + 1;
        
        // 重新排序对话列表
        _sortConversations();
      });
    }
  }
  
  // 处理新的群组消息
  void _handleNewGroupMessage(Map<String, dynamic> data) {
    final message = data['message'];
    if (message == null) return;
    
    final groupId = message['groupId'];
    if (groupId == null) return;
    
    // 在对话列表中找到对应的群组对话并更新最后消息
    final conversationIndex = _conversations.indexWhere(
      (conv) => conv['type'] == 'group' && conv['groupData']?['id'] == groupId
    );
    
    if (conversationIndex != -1) {
      setState(() {
        _conversations[conversationIndex]['lastMessage'] = message['content'] ?? '收到新消息';
        _conversations[conversationIndex]['lastTime'] = message['createdAt'] ?? DateTime.now().toIso8601String();
        _conversations[conversationIndex]['unreadCount'] = (_conversations[conversationIndex]['unreadCount'] ?? 0) + 1;
        
        // 重新排序对话列表
        _sortConversations();
      });
    }
  }
  
  // 处理消息发送确认
  void _handleMessageSentConfirmation(Map<String, dynamic> data) {
    print('消息发送确认: ${data['messageId']}');
    // 可以在这里更新UI显示消息发送状态
  }
  
  // 处理消息状态更新
  void _handleMessageStatusUpdate(Map<String, dynamic> data) {
    print('消息状态更新: ${data['messageId']} -> ${data['status']}');
    // 可以在这里更新UI显示消息已读状态
  }
  
  // 对话列表排序
  void _sortConversations() {
    _conversations.sort((a, b) {
      final timeA = DateTime.parse(a['lastTime']);
      final timeB = DateTime.parse(b['lastTime']);
      return timeB.compareTo(timeA);
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
      final groups = authProvider.groups ?? [];
      final currentDevice = authProvider.deviceInfo;
      
      print('开始加载对话列表');
      print('群组数量: ${groups.length}');
      print('当前设备: ${currentDevice?['id']}');
      
      // 构建对话列表：群聊 + 私聊
      List<Map<String, dynamic>> conversations = [];
      Set<String> processedDeviceIds = {}; // 用于避免重复添加设备
      
      // 添加群聊对话和私聊对话
      for (var group in groups) {
        final devices = List<Map<String, dynamic>>.from(group['devices'] ?? []);
        final groupId = group['id'];
        
        print('处理群组: ${group['name']}, 设备数量: ${devices.length}');
        
        // 1. 添加群聊对话（如果群组有多于1个设备）
        if (devices.length > 1) {
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
            'title': group['name'] ?? '群组',
            'subtitle': '${devices.length}台设备',
            'avatar': _getGroupAvatar(devices),
            'lastMessage': lastGroupMessage?['content'] ?? '点击开始群聊',
            'lastTime': lastGroupMessage?['createdAt'] ?? DateTime.now().toIso8601String(),
            'unreadCount': 0,
            'isOnline': devices.any((d) => d['isOnline'] == true),
            'groupData': group,
          });
          
          print('添加群聊对话: ${group['name']}');
        }
        
        // 2. 添加设备间的私聊对话（包括当前群组中的所有其他设备）
        if (currentDevice != null) {
          for (var device in devices) {
            final deviceId = device['id'];
            
            // 跳过当前设备，但确保添加所有其他设备
            if (deviceId != currentDevice['id'] && !processedDeviceIds.contains(deviceId)) {
              processedDeviceIds.add(deviceId);
              
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
                'title': device['name'] ?? '未知设备',
                'subtitle': device['type'] ?? '未知类型',
                'avatar': _getDeviceAvatar(device['type']),
                'lastMessage': lastPrivateMessage?['content'] ?? '点击开始聊天',
                'lastTime': lastPrivateMessage?['createdAt'] ?? device['last_active_time'] ?? DateTime.now().toIso8601String(),
                'unreadCount': 0,
                'isOnline': device['isOnline'] == true,
                'deviceData': device,
              });
              
              print('添加私聊对话: ${device['name']} (${device['id']})');
            }
          }
        }
      }
      
      // 按最后消息时间排序
      conversations.sort((a, b) {
        final timeA = DateTime.parse(a['lastTime']);
        final timeB = DateTime.parse(b['lastTime']);
        return timeB.compareTo(timeA);
      });
      
      print('总对话数量: ${conversations.length}');
      
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isRefreshing = false;
        });
      }
      
      if (_refreshController.isRefresh) {
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      print('加载对话失败: $e');
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
      if (_refreshController.isRefresh) {
        _refreshController.refreshFailed();
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SmartRefresher(
        controller: _refreshController,
        onRefresh: _loadConversations,
        header: const WaterDropHeader(
          waterDropColor: AppTheme.primaryColor,
        ),
        child: _conversations.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final conversation = _conversations[index];
                return _buildConversationCard(conversation, index);
              },
            ),
      ),
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
  
  Widget _buildConversationCard(Map<String, dynamic> conversation, int index) {
    final bool isGroup = conversation['type'] == 'group';
    final bool isOnline = conversation['isOnline'] == true;
    final int unreadCount = conversation['unreadCount'] ?? 0;
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + index * 50),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openChatScreen(conversation),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.borderColor,
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.shadowColor,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // 头像
                        _buildAvatar(conversation),
                        
                        const SizedBox(width: 12),
                        
                        // 对话信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      conversation['title'],
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    TimeUtils.formatRelativeTime(conversation['lastTime']),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textTertiaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 4),
                              
                              Row(
                                children: [
                                  // 在线状态指示器
                                  if (!isGroup)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: isOnline ? AppTheme.onlineColor : AppTheme.offlineColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  
                                  Expanded(
                                    child: Text(
                                      conversation['subtitle'],
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 4),
                              
                              Text(
                                conversation['lastMessage'],
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textTertiaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // 右侧信息
                        Column(
                          children: [
                            // 未读消息数
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            
                            const SizedBox(height: 8),
                            
                            // 类型图标
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isGroup 
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : AppTheme.onlineColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                isGroup ? Icons.group_rounded : Icons.person_rounded,
                                size: 12,
                                color: isGroup ? AppTheme.primaryColor : AppTheme.onlineColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAvatar(Map<String, dynamic> conversation) {
    final String avatar = conversation['avatar'];
    final bool isOnline = conversation['isOnline'] == true;
    final bool isGroup = conversation['type'] == 'group';
    
    return Stack(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isGroup 
              ? AppTheme.primaryColor.withOpacity(0.1)
              : isOnline 
                ? AppTheme.onlineColor.withOpacity(0.1)
                : AppTheme.offlineColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              avatar,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        
        // 在线状态指示器（仅私聊显示）
        if (!isGroup)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isOnline ? AppTheme.onlineColor : AppTheme.offlineColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.cardColor, width: 2),
              ),
            ),
          ),
      ],
    );
  }
  
  // 打开聊天界面
  void _openChatScreen(Map<String, dynamic> conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversation: conversation),
      ),
    );
  }
} 