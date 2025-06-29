import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'dart:io';
import 'device_auth_service.dart';
import 'websocket_manager.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../config/debug_config.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal() {
    // 🔥 关键修复：监听新的WebSocket管理器消息并转发
    _setupWebSocketManagerBridge();
  }
  
  // 🔥 重要：完全依赖WebSocketManager，不再维护自己的Socket
  final WebSocketManager _wsManager = WebSocketManager();
  StreamSubscription? _wsManagerSubscription;
  final DeviceAuthService _authService = DeviceAuthService();
  
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // 添加专门用于设备状态更新的控制器
  final StreamController<Map<String, dynamic>> _deviceStatusController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // 添加登出状态监听控制器
  final StreamController<Map<String, dynamic>> _logoutController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // 添加聊天消息监听控制器
  final StreamController<Map<String, dynamic>> _chatMessageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // 添加群组变化监听控制器
  final StreamController<Map<String, dynamic>> _groupChangeController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onDeviceStatusChange => _deviceStatusController.stream;
  Stream<Map<String, dynamic>> get onLogout => _logoutController.stream;
  Stream<Map<String, dynamic>> get onChatMessage => _chatMessageController.stream;
  Stream<Map<String, dynamic>> get onGroupChange => _groupChangeController.stream;
  
  // 🔥 重要：通过WebSocketManager获取连接状态
  bool get isConnected => _wsManager.isConnected;
  
  DateTime? _lastDeviceStatusRefresh;
  bool _isRefreshingDeviceStatus = false;
  static const Duration _deviceStatusThrottleInterval = Duration(minutes: 1); // 节流间隔1分钟
  
  // 🔥 关键修复：设置WebSocket管理器桥接
  void _setupWebSocketManagerBridge() {
    _wsManagerSubscription = _wsManager.onMessageReceived.listen((data) {
      _handleWebSocketManagerMessage(data);
    });
  }
  
  // 处理来自WebSocket管理器的消息并转发到相应的流
  void _handleWebSocketManagerMessage(Map<String, dynamic> data) {
    final type = data['type'];
    DebugConfig.debugPrint('WebSocketService桥接消息: $type', module: 'WEBSOCKET');
    
    switch (type) {
      case 'new_private_message':
      case 'new_group_message':
        // 🔥 关键修复：确保群组消息正确转发
        DebugConfig.debugPrint('转发聊天消息到聊天流: $type', module: 'MESSAGE');
        
        // 🔥 重要修复：正确解析消息数据结构
        final messageData = data['data'];
        if (messageData != null) {
          // 🔥 关键修复：确保消息结构正确
          final message = messageData['message'];
          if (message != null) {
            _chatMessageController.add({
              'type': type,
              'message': message, // 直接传递消息对象
              'data': messageData,
              'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
            });
            DebugConfig.debugPrint('聊天消息已正确转发: ${message['id']}', module: 'MESSAGE');
          } else {
            DebugConfig.errorPrint('消息对象为空，无法转发');
          }
        } else {
          DebugConfig.errorPrint('消息数据为空，无法转发');
        }
        break;
        
      case 'file_message_received':
        // 🔥 新增：处理文件消息
        DebugConfig.debugPrint('转发文件消息到聊天流', module: 'MESSAGE');
        final messageData = data['data'];
        if (messageData != null && messageData['message'] != null) {
          _chatMessageController.add({
            'type': 'new_private_message',
            'message': messageData['message'],
            'data': messageData,
            'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
          });
          DebugConfig.debugPrint('文件消息已转发: ${messageData['message']['id']}', module: 'MESSAGE');
        }
        break;
        
      case 'group_file_message':
        // 🔥 新增：处理群组文件消息
        DebugConfig.debugPrint('转发群组文件消息到聊天流', module: 'MESSAGE');
        final messageData = data['data'];
        if (messageData != null && messageData['message'] != null) {
          _chatMessageController.add({
            'type': 'new_group_message',
            'message': messageData['message'],
            'data': messageData,
            'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
          });
          DebugConfig.debugPrint('群组文件消息已转发: ${messageData['message']['id']}', module: 'MESSAGE');
        }
        break;
        
      case 'group_devices_status':
        // 转发群组设备状态到设备状态控制器
        DebugConfig.debugPrint('桥接群组设备状态到设备状态流: ${data['groupId']}', module: 'WEBSOCKET');
        _deviceStatusController.add({
          'type': 'group_devices_status',
          'groupId': data['groupId'],
          'devices': data['devices'],
          'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
        });
        break;
        
      case 'online_devices':
        // 转发在线设备列表到设备状态控制器
        DebugConfig.debugPrint('桥接在线设备列表到设备状态流', module: 'WEBSOCKET');
        _deviceStatusController.add({
          'type': 'online_devices',
          'devices': data['devices'],
          'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
        });
        break;
        
      case 'device_status_update':
        // 转发设备状态更新到设备状态控制器
        DebugConfig.debugPrint('桥接设备状态更新到设备状态流', module: 'WEBSOCKET');
        _deviceStatusController.add({
          'type': 'device_status_update',
          'data': data,
          'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
        });
        break;
        
      case 'recent_messages': // 🔥 新增：处理最近消息
        // 转发最近消息到聊天消息流
        DebugConfig.debugPrint('桥接最近消息到聊天流', module: 'MESSAGE');
        _chatMessageController.add(data);
        break;
        
      case 'offline_messages': // 🔥 新增：处理离线消息
        // 转发离线消息到聊天消息流
        DebugConfig.debugPrint('桥接离线消息到聊天流', module: 'MESSAGE');
        _chatMessageController.add(data);
        break;
        
      case 'group_messages_synced': // 🔥 新增：处理群组消息同步
        // 转发群组消息同步到聊天消息流
        DebugConfig.debugPrint('桥接群组消息同步到聊天流', module: 'MESSAGE');
        _chatMessageController.add(data);
        break;
        
      case 'private_messages_synced': // 🔥 新增：处理私聊消息同步
        // 转发私聊消息同步到聊天消息流
        DebugConfig.debugPrint('桥接私聊消息同步到聊天流', module: 'MESSAGE');
        _chatMessageController.add(data);
        break;
        
      case 'message_sent_confirmation':
      case 'group_message_sent_confirmation':
      case 'message_status_updated':
        // 🔥 新增：转发消息状态更新
        DebugConfig.debugPrint('转发消息状态更新: $type', module: 'MESSAGE');
        _chatMessageController.add(data);
        break;
        
      case 'force_refresh_history': // 🔥 新增：处理强制刷新历史消息事件
        // 转发强制刷新历史消息事件到聊天消息流
        DebugConfig.debugPrint('桥接强制刷新历史消息事件到聊天流', module: 'MESSAGE');
        _chatMessageController.add(data);
        break;
        
      default:
        // 转发其他消息到通用消息流
        DebugConfig.debugPrint('转发其他消息到通用流: $type', module: 'WEBSOCKET');
        _messageController.add(data);
        break;
    }
  }
  
  // 发送1v1聊天消息 - 通过WebSocketManager
  void sendPrivateMessage({
    required String targetDeviceId,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    if (!isConnected) {
      DebugConfig.warningPrint('WebSocket未连接，无法发送消息');
      return;
    }
    
    // 🔥 修复：通过WebSocketManager发送消息
    _wsManager.emit('message', {
      'type': 'chat',
      'targetDeviceId': targetDeviceId,
      'content': content,
      if (metadata != null) 'metadata': metadata,
    });
  }
  
  // 发送群组聊天消息 - 通过WebSocketManager
  void sendGroupMessage({
    required String groupId,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    if (!isConnected) {
      DebugConfig.warningPrint('WebSocket未连接，无法发送群组消息');
      return;
    }
    
    // 🔥 修复：通过WebSocketManager发送群组消息
    _wsManager.emit('message', {
      'type': 'group_chat',
      'groupId': groupId,
      'content': content,
      if (metadata != null) 'metadata': metadata,
    });
  }
  
  // 发送消息已接收回执 - 通过WebSocketManager
  void sendMessageReceived(String messageId) {
    if (!isConnected) {
      DebugConfig.warningPrint('WebSocket未连接，无法发送已接收回执');
      return;
    }
    
    // 🔥 修复：通过WebSocketManager发送回执
    _wsManager.emit('message', {
      'type': 'message_received',
      'messageId': messageId,
    });
  }
  
  // 手动重连
  Future<bool> reconnect() async {
    DebugConfig.debugPrint('手动重连WebSocket...', module: 'WEBSOCKET');
    return await _wsManager.reconnect();
  }
  
  // 🔥 重要修复：初始化并连接WebSocket - 完全依赖WebSocketManager
  Future<void> connect() async {
    try {
      DebugConfig.debugPrint('通过WebSocketManager初始化连接...', module: 'WEBSOCKET');
      
      // 获取认证信息
      final token = await _authService.getAuthToken();
      final deviceId = await _authService.getServerDeviceId();
      
      if (token == null || deviceId == null) {
        throw Exception('未登录，无法连接WebSocket');
      }
      
      // 使用WebSocketManager进行连接
      final success = await _wsManager.initialize(
        deviceId: deviceId,
        token: token,
      );
      
      if (!success) {
        throw Exception('WebSocketManager连接失败');
      }
      
      DebugConfig.debugPrint('WebSocketService通过WebSocketManager连接成功', module: 'WEBSOCKET');
      
    } catch (e) {
      DebugConfig.errorPrint('WebSocketService连接失败: $e');
      rethrow;
    }
  }
  
  // 发送消息
  void emit(String event, dynamic data) {
    if (_wsManager.isConnected) {
      DebugConfig.debugPrint('发送WebSocket消息: event=$event', module: 'WEBSOCKET');
      _wsManager.emit(event, data);
    } else {
      DebugConfig.warningPrint('Socket未连接，无法发送消息 (event=$event)');
    }
  }
  
  // 🔥 优化：添加节流机制的设备状态刷新
  void refreshDeviceStatus() {
    final now = DateTime.now();
    
    // 检查是否正在刷新
    if (_isRefreshingDeviceStatus) {
      DebugConfig.debugPrint('设备状态刷新正在进行中，跳过重复请求', module: 'WEBSOCKET');
      return;
    }
    
    // 检查节流间隔
    if (_lastDeviceStatusRefresh != null) {
      final timeSinceLastRefresh = now.difference(_lastDeviceStatusRefresh!);
      if (timeSinceLastRefresh < _deviceStatusThrottleInterval) {
        DebugConfig.debugPrint('设备状态刷新请求过于频繁，跳过 (距离上次 ${timeSinceLastRefresh.inSeconds}秒)', module: 'WEBSOCKET');
        return;
      }
    }
    
    if (!isConnected) {
      DebugConfig.debugPrint('WebSocket未连接，无法刷新设备状态', module: 'WEBSOCKET');
      return;
    }
    
    _isRefreshingDeviceStatus = true;
    _lastDeviceStatusRefresh = now;
    
    DebugConfig.debugPrint('执行WebSocket设备状态刷新 (节流保护)', module: 'WEBSOCKET');
    
    try {
      // 🔥 优化：发送单一的设备状态刷新请求
      emit('refresh_device_status', {
        'timestamp': DateTime.now().toIso8601String(),
        'reason': 'throttled_refresh'
      });
      
      DebugConfig.debugPrint('WebSocket设备状态刷新请求已发送', module: 'WEBSOCKET');
      
    } catch (e) {
      DebugConfig.errorPrint('WebSocket设备状态刷新失败: $e');
    } finally {
      // 3秒后解除刷新锁定
      Future.delayed(Duration(seconds: 3), () {
        _isRefreshingDeviceStatus = false;
      });
    }
  }
  
  // 立即同步设备状态（用于重要状态变化）
  void forceSyncDeviceStatus() {
    if (_wsManager.isConnected) {
      DebugConfig.debugPrint('强制同步设备状态...', module: 'SYNC');
      
      // 立即发送状态更新请求
      _wsManager.emit('force_status_sync', {
        'timestamp': DateTime.now().toIso8601String(),
        'sync_reason': 'manual_refresh'
      });
      
      // 同时请求各种状态更新
      _wsManager.emit('request_device_status', {
        'timestamp': DateTime.now().toIso8601String()
      });
      _wsManager.emit('request_group_devices_status', {
        'timestamp': DateTime.now().toIso8601String()
      });
      _wsManager.emit('get_online_devices', {
        'timestamp': DateTime.now().toIso8601String()
      });
    }
  }
  
  // 当设备活跃状态发生变化时调用
  void notifyDeviceActivityChange() {
    if (_wsManager.isConnected) {
      DebugConfig.debugPrint('通知设备活跃状态变化...', module: 'SYNC');
      
      _wsManager.emit('device_activity_update', {
        'status': 'active',
        'timestamp': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
      });
      
      // 延迟一秒后请求更新状态，确保服务器处理完成
      Future.delayed(Duration(seconds: 1), () {
        if (_wsManager.isConnected) {
          forceSyncDeviceStatus();
        }
      });
    }
  }
  
  // 获取连接信息
  Map<String, dynamic> getConnectionInfo() {
    return _wsManager.getConnectionInfo();
  }
  
  // 断开连接
  void disconnect() {
    DebugConfig.debugPrint('断开WebSocket连接...', module: 'WEBSOCKET');
    _wsManager.disconnect();
    DebugConfig.debugPrint('WebSocket连接已断开', module: 'WEBSOCKET');
  }
  
  // 资源释放
  void dispose() {
    DebugConfig.debugPrint('开始清理WebSocket资源...', module: 'WEBSOCKET');
    
    // 通过WebSocketManager处理清理
    _wsManager.dispose();
    _wsManagerSubscription?.cancel(); // 🔥 清理WebSocket管理器订阅
    
    // 关闭所有流控制器
    if (!_messageController.isClosed) {
      _messageController.close();
    }
    if (!_deviceStatusController.isClosed) {
      _deviceStatusController.close();
    }
    if (!_logoutController.isClosed) {
      _logoutController.close();
    }
    if (!_chatMessageController.isClosed) {
      _chatMessageController.close();
    }
    if (!_groupChangeController.isClosed) {
      _groupChangeController.close();
    }
    
    DebugConfig.debugPrint('WebSocket资源已完全释放', module: 'WEBSOCKET');
  }
  
  // 处理不同类型的消息
  void _handleMessageByType(String messageType, Map<String, dynamic> data) {
    switch (messageType) {
      case 'system':
        // 处理系统消息
        if (data['content'] == 'device_logged_out') {
          DebugConfig.warningPrint('收到登出通知: ${data['message']}');
          _logoutController.add({
            'type': 'logout_notification',
            'message': data['message'] ?? '设备已登出，连接即将断开',
            'timestamp': DateTime.now().toIso8601String()
          });
        } else if (data['content'] == 'device_status_update' && data.containsKey('device_statuses')) {
          DebugConfig.debugPrint('收到设备状态更新', module: 'SYNC');
          _deviceStatusController.add({
            'type': 'device_status_update',
            'device_statuses': data['device_statuses'],
            'timestamp': DateTime.now().toIso8601String()
          });
        }
        break;
      
      // 群组管理相关通知
      case 'device_joined_group':
        DebugConfig.debugPrint('设备加入群组通知', module: 'SYNC');
        _groupChangeController.add({
          'type': 'device_joined_group',
          'device': data['device'],
          'group': data['group'],
          'joinedAt': data['joinedAt'],
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
      
      case 'device_left_group':
        DebugConfig.debugPrint('设备离开群组通知', module: 'SYNC');
        _groupChangeController.add({
          'type': 'device_left_group',
          'device': data['device'],
          'group': data['group'],
          'leftAt': data['leftAt'],
          'ownershipChanged': data['ownershipChanged'],
          'leaveReason': data['leaveReason'],
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
      
      case 'group_created':
        DebugConfig.debugPrint('群组创建通知', module: 'SYNC');
        _groupChangeController.add({
          'type': 'group_created',
          'group': data['group'],
          'creator': data['creator'],
          'createdAt': data['createdAt'],
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
      
      case 'group_updated':
        DebugConfig.debugPrint('群组更新通知', module: 'SYNC');
        _groupChangeController.add({
          'type': 'group_updated',
          'group': data['group'],
          'updatedFields': data['updatedFields'],
          'updatedAt': data['updatedAt'],
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
      
      case 'group_deleted':
        DebugConfig.warningPrint('群组删除通知');
        _groupChangeController.add({
          'type': 'group_deleted',
          'groupId': data['groupId'],
          'groupName': data['groupName'],
          'reason': data['reason'],
          'deletedAt': data['deletedAt'],
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
        
      case 'device_status_changed':
        DebugConfig.debugPrint('设备状态变更通知', module: 'SYNC');
        _deviceStatusController.add({
          'type': 'device_status',
          'action': 'status_changed',
          'device': data['device'],
          'status': data['status'],
          'online': data['status'] == 'online',
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
        
      case 'group_devices_status':
        DebugConfig.debugPrint('群组设备状态更新', module: 'SYNC');
        // 直接转发到设备状态控制器
        _deviceStatusController.add({
          'type': 'group_devices_status',
          'data': data,
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
        
      case 'online_devices':
        DebugConfig.debugPrint('在线设备列表更新', module: 'SYNC');
        // 直接转发到设备状态控制器
        _deviceStatusController.add({
          'type': 'online_devices',
          'data': data,
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
        
      case 'new_message':
        // 处理新的1v1消息
        DebugConfig.debugPrint('收到新的1v1消息', module: 'MESSAGE');
        _chatMessageController.add({
          'type': 'new_private_message',
          'message': data['message'],
          'sourceDeviceId': data['message']?['sourceDeviceId'],
          'targetDeviceId': data['message']?['targetDeviceId'],
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
        
      case 'new_group_message':
        // 处理新的群组消息
        DebugConfig.debugPrint('收到新的群组消息', module: 'MESSAGE');
        _chatMessageController.add({
          'type': 'new_group_message',
          'message': data['data']?['message'] ?? data['message'],
          'senderDevice': data['data']?['senderDevice'] ?? data['senderDevice'],
          'groupId': data['data']?['message']?['groupId'] ?? data['groupId'],
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
        
      case 'file_message_received':
      case 'private_file_message':
        // 处理文件消息 - 确保实时处理
        DebugConfig.debugPrint('收到私聊文件消息', module: 'MESSAGE');
        _chatMessageController.add({
          'type': 'new_private_message',
          'message': data['message'] ?? data,
          'sourceDeviceId': data['message']?['sourceDeviceId'] ?? data['sourceDeviceId'],
          'targetDeviceId': data['message']?['targetDeviceId'] ?? data['targetDeviceId'],
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
        
      case 'group_file_message':
        // 处理群组文件消息 - 确保实时处理
        DebugConfig.debugPrint('收到群组文件消息', module: 'MESSAGE');
        _chatMessageController.add({
          'type': 'new_group_message',
          'message': data['message'] ?? data,
          'senderDevice': data['senderDevice'],
          'groupId': data['groupId'] ?? data['message']?['groupId'],
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
        
      default:
        DebugConfig.debugPrint('未处理的消息类型: $messageType', module: 'WEBSOCKET');
        break;
    }
  }
} 