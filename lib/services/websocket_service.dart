import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'dart:io';
import 'device_auth_service.dart';
import 'websocket_manager.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

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
  
  // 🔥 关键修复：设置WebSocket管理器桥接
  void _setupWebSocketManagerBridge() {
    _wsManagerSubscription = _wsManager.onMessageReceived.listen((data) {
      _handleWebSocketManagerMessage(data);
    });
  }
  
  // 处理来自WebSocket管理器的消息并转发到相应的流
  void _handleWebSocketManagerMessage(Map<String, dynamic> data) {
    final type = data['type'];
    print('🌉 WebSocketService桥接消息: $type');
    
    switch (type) {
      case 'new_private_message':
      case 'new_group_message':
        // 🔥 关键修复：确保群组消息正确转发
        print('🔥 转发聊天消息到聊天流: $type, 数据: ${data['data']}');
        
        // 🔥 重要修复：确保消息数据结构正确
        final messageData = data['data'];
        if (messageData != null) {
          _chatMessageController.add({
            'type': type,
            'message': messageData['message'],
            'data': messageData,
            'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
          });
          print('✅ 群组消息已转发到聊天流');
        } else {
          print('❌ 消息数据为空，无法转发');
        }
        break;
        
      case 'file_message_received':
        // 🔥 新增：处理文件消息
        print('📎 转发文件消息到聊天流');
        final messageData = data['data'];
        if (messageData != null) {
          _chatMessageController.add({
            'type': 'new_private_message',
            'message': messageData['message'],
            'data': messageData,
            'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
          });
        }
        break;
        
      case 'group_file_message':
        // 🔥 新增：处理群组文件消息
        print('📎 转发群组文件消息到聊天流');
        final messageData = data['data'];
        if (messageData != null) {
          _chatMessageController.add({
            'type': 'new_group_message',
            'message': messageData['message'],
            'data': messageData,
            'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
          });
        }
        break;
        
      case 'group_devices_status':
      case 'online_devices':
      case 'device_status_update':
        // 转发设备状态消息到设备状态流
        _deviceStatusController.add(data);
        break;
        
      case 'recent_messages': // 🔥 新增：处理最近消息
        // 转发最近消息到聊天消息流
        print('📬 桥接最近消息到聊天流');
        _chatMessageController.add(data);
        break;
        
      case 'message_sent_confirmation':
      case 'group_message_sent_confirmation':
      case 'message_status_updated':
        // 🔥 新增：转发消息状态更新
        print('📋 转发消息状态更新: $type');
        _chatMessageController.add(data);
        break;
        
      default:
        // 转发其他消息到通用消息流
        print('📨 转发其他消息到通用流: $type');
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
      print('WebSocket未连接，无法发送消息');
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
      print('WebSocket未连接，无法发送群组消息');
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
      print('WebSocket未连接，无法发送已接收回执');
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
    print('🔄 手动重连WebSocket...');
    return await _wsManager.reconnect();
  }
  
  // 🔥 重要修复：初始化并连接WebSocket - 完全依赖WebSocketManager
  Future<void> connect() async {
    try {
      print('🔄 通过WebSocketManager初始化连接...');
      
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
      
      print('✅ WebSocketService通过WebSocketManager连接成功');
      
    } catch (e) {
      print('❌ WebSocketService连接失败: $e');
      rethrow;
    }
  }
  
  // 发送消息
  void emit(String event, dynamic data) {
    if (_wsManager.isConnected) {
      print('📤 发送WebSocket消息: event=$event');
      _wsManager.emit(event, data);
    } else {
      print('❌ Socket未连接，无法发送消息 (event=$event)');
    }
  }
  
  // 手动刷新设备状态
  void refreshDeviceStatus() {
    if (isConnected) {
      _wsManager.emit('request_device_status', {
        'timestamp': DateTime.now().toIso8601String()
      });
      _wsManager.emit('request_group_devices_status', {
        'timestamp': DateTime.now().toIso8601String()
      });
      _wsManager.emit('get_online_devices', {
        'timestamp': DateTime.now().toIso8601String()
      });
      print('🔄 手动刷新设备状态完成');
    } else {
      print('❌ WebSocket未连接，无法刷新设备状态');
    }
  }
  
  // 立即同步设备状态（用于重要状态变化）
  void forceSyncDeviceStatus() {
    if (_wsManager.isConnected) {
      print('🚀 强制同步设备状态...');
      
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
      print('📱 通知设备活跃状态变化...');
      
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
    print('🔌 断开WebSocket连接...');
    _wsManager.disconnect();
    print('✅ WebSocket连接已断开');
  }
  
  // 资源释放
  void dispose() {
    print('🧹 开始清理WebSocket资源...');
    
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
    
    print('✅ WebSocket资源已完全释放');
  }
  
  // 处理不同类型的消息
  void _handleMessageByType(String messageType, Map<String, dynamic> data) {
    switch (messageType) {
      case 'system':
        // 处理系统消息
        if (data['content'] == 'device_logged_out') {
          print('收到登出通知: ${data['message']}');
          _logoutController.add({
            'type': 'logout_notification',
            'message': data['message'] ?? '设备已登出，连接即将断开',
            'timestamp': DateTime.now().toIso8601String()
          });
        } else if (data['content'] == 'device_status_update' && data.containsKey('device_statuses')) {
          print('收到设备状态更新');
          _deviceStatusController.add({
            'type': 'device_status_update',
            'device_statuses': data['device_statuses'],
            'timestamp': DateTime.now().toIso8601String()
          });
        }
        break;
      
      // 群组管理相关通知
      case 'device_joined_group':
        print('设备加入群组通知');
        _groupChangeController.add({
          'type': 'device_joined_group',
          'device': data['device'],
          'group': data['group'],
          'joinedAt': data['joinedAt'],
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
      
      case 'device_left_group':
        print('设备离开群组通知');
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
        print('群组创建通知');
        _groupChangeController.add({
          'type': 'group_created',
          'group': data['group'],
          'creator': data['creator'],
          'createdAt': data['createdAt'],
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
      
      case 'group_updated':
        print('群组更新通知');
        _groupChangeController.add({
          'type': 'group_updated',
          'group': data['group'],
          'updatedFields': data['updatedFields'],
          'updatedAt': data['updatedAt'],
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
      
      case 'group_deleted':
        print('群组删除通知');
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
        print('设备状态变更通知');
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
        print('群组设备状态更新');
        // 直接转发到设备状态控制器
        _deviceStatusController.add({
          'type': 'group_devices_status',
          'data': data,
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
        
      case 'online_devices':
        print('在线设备列表更新');
        // 直接转发到设备状态控制器
        _deviceStatusController.add({
          'type': 'online_devices',
          'data': data,
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
        
      case 'new_message':
        // 处理新的1v1消息
        print('收到新的1v1消息');
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
        print('收到新的群组消息');
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
        print('收到私聊文件消息');
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
        print('收到群组文件消息');
        _chatMessageController.add({
          'type': 'new_group_message',
          'message': data['message'] ?? data,
          'senderDevice': data['senderDevice'],
          'groupId': data['groupId'] ?? data['message']?['groupId'],
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
        
      default:
        print('未知的消息类型: $messageType');
        break;
    }
  }
} 