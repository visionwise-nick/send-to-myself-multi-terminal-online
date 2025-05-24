import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'device_auth_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();
  
  IO.Socket? _socket;
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
  
  bool get isConnected => _socket?.connected ?? false;
  Timer? _pingTimer;
  
  // 发送1v1聊天消息
  void sendPrivateMessage({
    required String targetDeviceId,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    if (!isConnected) {
      print('WebSocket未连接，无法发送消息');
      return;
    }
    
    final messageData = {
      'type': 'chat',
      'targetDeviceId': targetDeviceId,
      'content': content,
      if (metadata != null) 'metadata': metadata,
    };
    
    print('发送1v1消息: $messageData');
    _socket!.emit('message', messageData);
  }
  
  // 发送群组聊天消息
  void sendGroupMessage({
    required String groupId,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    if (!isConnected) {
      print('WebSocket未连接，无法发送群组消息');
      return;
    }
    
    final messageData = {
      'type': 'group_chat',
      'groupId': groupId,
      'content': content,
      if (metadata != null) 'metadata': metadata,
    };
    
    print('发送群组消息: $messageData');
    _socket!.emit('message', messageData);
  }
  
  // 发送消息已接收回执
  void sendMessageReceived(String messageId) {
    if (!isConnected) {
      print('WebSocket未连接，无法发送已接收回执');
      return;
    }
    
    final receiptData = {
      'type': 'message_received',
      'messageId': messageId,
    };
    
    print('发送已接收回执: $receiptData');
    _socket!.emit('message', receiptData);
  }
  
  // 初始化并连接WebSocket
  Future<void> connect() async {
    // 如果已经有socket实例并且已连接，直接返回
    if (_socket != null && _socket!.connected) {
      print('WebSocket已连接');
      return;
    }
    
    // 获取认证令牌和设备信息
    final token = await _authService.getAuthToken();
    if (token == null) {
      print('未检测到授权令牌，尝试注册设备...');
      try {
        final result = await _authService.registerDevice();
        print('设备注册成功: ${result['device']['id']}');
      } catch (e) {
        print('设备注册失败: $e');
        throw Exception('未登录，无法连接WebSocket');
      }
    }
    
    // 重新获取令牌
    final updatedToken = await _authService.getAuthToken();
    if (updatedToken == null) {
      throw Exception('未登录，无法连接WebSocket');
    }
    
    // 获取服务器分配的设备ID
    final serverDeviceId = await _authService.getServerDeviceId();
    if (serverDeviceId == null) {
      print('未找到服务器设备ID，尝试获取设备资料...');
      try {
        final profileData = await _authService.getProfile();
        print('获取到服务器设备ID: ${profileData['device']['id']}');
      } catch (e) {
        print('获取设备资料失败: $e');
        throw Exception('无法获取服务器设备ID');
      }
    }
    
    // 使用最新的服务器设备ID
    final deviceId = await _authService.getServerDeviceId();
    if (deviceId == null) {
      throw Exception('无法获取服务器设备ID，连接失败');
    }
    
    print('正在连接WebSocket...');
    print('服务器设备ID: $deviceId');
    print('认证令牌: ${updatedToken.substring(0, 20)}...');
    
    try {
      // 取消现有的ping计时器
      _pingTimer?.cancel();
      
      // 完全按照Node.js脚本创建连接
      _socket = IO.io(
        'https://sendtomyself-api-adecumh2za-uc.a.run.app',
        {
          'path': '/ws',
          'transports': ['websocket'],
          'query': {
            'token': updatedToken,
            'deviceId': deviceId
          },
          'reconnection': true,
          'reconnectionAttempts': 5,
          'reconnectionDelay': 1000
        }
      );
      
      // 设置Socket.IO事件监听器
      _socket!.onConnect((_) {
        print('✅ WebSocket连接成功! Socket ID: ${_socket!.id}');
        _startPingTimer(); // 开始发送定期ping
        
        // 连接成功后立即请求设备状态
        _requestDeviceStatus();
        
        // 请求群组设备状态
        _requestGroupDevicesStatus();
      });
      
      _socket!.on('message', (data) {
        print('📩 收到消息: $data');
        if (data is Map) {
          _messageController.add(Map<String, dynamic>.from(data));
          
          // 根据消息类型处理
          if (data.containsKey('type')) {
            final messageType = data['type'];
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
              case 'device_joined_group':
                print('设备加入群组通知');
                // 发送设备状态更新通知
                _deviceStatusController.add({
                  'type': 'device_status',
                  'action': 'joined',
                  'device': data['device'],
                  'groupId': data['groupId'],
                  'timestamp': DateTime.now().toIso8601String()
                });
                // 发送群组变化通知
                _groupChangeController.add({
                  'type': 'device_joined',
                  'device': data['device'],
                  'groupId': data['groupId'],
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
              case 'device_left_group':
                print('设备离开群组通知');
                _deviceStatusController.add({
                  'type': 'device_status',
                  'action': 'left',
                  'deviceId': data['deviceId'],
                  'groupId': data['groupId'],
                  'timestamp': DateTime.now().toIso8601String()
                });
                // 发送群组变化通知
                _groupChangeController.add({
                  'type': 'device_left',
                  'deviceId': data['deviceId'],
                  'groupId': data['groupId'],
                  'timestamp': DateTime.now().toIso8601String()
                });
                break;
              case 'group_devices_status':
                print('群组设备状态更新');
                _handleGroupDevicesStatus(data);
                break;
              case 'online_devices':
                print('在线设备列表更新');
                _handleOnlineDevicesUpdate(data);
                break;
              case 'removed_from_group':
                print('被移出群组通知');
                break;
              case 'group_ownership_changed':
                print('群组所有权变更通知');
                break;
              case 'group_deleted':
                print('群组已删除通知');
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
                  'message': data['data']?['message'],
                  'senderDevice': data['data']?['senderDevice'],
                  'groupId': data['data']?['message']?['groupId'],
                  'timestamp': DateTime.now().toIso8601String()
                });
                break;
              case 'message_sent':
                // 1v1消息发送确认
                print('1v1消息发送确认: ${data['messageId']}');
                _chatMessageController.add({
                  'type': 'message_sent_confirmation',
                  'messageId': data['messageId'],
                  'timestamp': DateTime.now().toIso8601String()
                });
                break;
              case 'group_message_sent':
                // 群组消息发送确认
                print('群组消息发送确认: ${data['messageId']}');
                _chatMessageController.add({
                  'type': 'group_message_sent_confirmation',
                  'messageId': data['messageId'],
                  'timestamp': DateTime.now().toIso8601String()
                });
                break;
              case 'message_status_updated':
                // 消息状态更新(如已读)
                print('消息状态更新: ${data['messageId']} -> ${data['status']}');
                _chatMessageController.add({
                  'type': 'message_status_updated',
                  'messageId': data['messageId'],
                  'status': data['status'],
                  'timestamp': DateTime.now().toIso8601String()
                });
                break;
            }
          }
        }
      });
      
      _socket!.onDisconnect((reason) {
        print('⚠️ WebSocket连接断开: $reason');
        _pingTimer?.cancel(); // 停止ping
        
        // 检查是否是服务端主动断开（登出）
        if (reason == 'io server disconnect') {
          print('服务端主动断开连接，可能是登出操作');
          _logoutController.add({
            'type': 'forced_disconnect',
            'message': '您已从其他设备登出，连接已断开',
            'reason': reason,
            'timestamp': DateTime.now().toIso8601String()
          });
        }
      });
      
      _socket!.onConnectError((error) {
        print('❌ WebSocket连接错误: $error');
        
        // 检查是否是登出导致的连接错误
        if (error.toString().contains('设备已登出') || 
            error.toString().contains('device_logged_out') ||
            error.toString().contains('已登出')) {
          print('设备已登出，无法重连');
          _logoutController.add({
            'type': 'reconnect_blocked',
            'message': '设备已登出，请重新登录',
            'error': error.toString(),
            'timestamp': DateTime.now().toIso8601String()
          });
        }
      });
      
      _socket!.onError((error) {
        print('WebSocket错误: $error');
      });
      
      print('WebSocket初始化完成');
    } catch (e) {
      print('WebSocket连接创建失败: $e');
      rethrow;
    }
  }
  
  // 请求设备状态
  void _requestDeviceStatus() {
    if (_socket != null && _socket!.connected) {
      print('请求设备状态...');
      _socket!.emit('request_device_status', {
        'timestamp': DateTime.now().toIso8601String()
      });
    }
  }
  
  // 请求群组设备状态
  void _requestGroupDevicesStatus() {
    if (_socket != null && _socket!.connected) {
      print('请求群组设备状态...');
      _socket!.emit('request_group_devices_status', {
        'timestamp': DateTime.now().toIso8601String()
      });
    }
  }
  
  // 请求在线设备列表
  void _requestOnlineDevices() {
    if (_socket != null && _socket!.connected) {
      print('请求在线设备列表...');
      _socket!.emit('get_online_devices', {
        'timestamp': DateTime.now().toIso8601String()
      });
    }
  }
  
  // 处理群组设备状态
  void _handleGroupDevicesStatus(Map data) {
    if (data.containsKey('devices') && data.containsKey('groupId')) {
      print('收到群组设备状态: 群组ID=${data['groupId']}, ${data['devices'].length}台设备');
      
      // 正确处理设备状态，根据服务器数据和活跃时间判断
      final List<Map<String, dynamic>> processedDevices = [];
      for (final device in data['devices']) {
        if (device is Map) {
          final Map<String, dynamic> processedDevice = Map<String, dynamic>.from(device);
          
          // 根据服务器返回的is_online状态和最后活跃时间来判断设备在线状态
          bool isOnline = false;
          
          // 首先检查服务器返回的is_online状态
          if (device['is_online'] == true) {
            // 如果服务器说在线，再检查最后活跃时间
            if (device['last_active_time'] != null) {
              try {
                final lastActiveTime = DateTime.parse(device['last_active_time']);
                final now = DateTime.now();
                final timeDifference = now.difference(lastActiveTime);
                
                // 如果30分钟内有活动才认为是在线，否则优先使用服务器状态
                if (timeDifference.inMinutes <= 5) {
                  isOnline = true;
                  print('设备${device['name']}(${device['id']})在线 - 最后活跃: ${timeDifference.inMinutes}分钟前');
                } else {
                  // 超过30分钟但服务器说在线，可能是WebSocket连接问题，保持在线状态
                  isOnline = true;
                  print('设备${device['name']}(${device['id']})在线 - 服务器状态优先 (最后活跃: ${timeDifference.inMinutes}分钟前)');
                }
              } catch (e) {
                print('解析设备活跃时间失败: $e');
                // 解析失败时使用服务器的is_online状态
                isOnline = device['is_online'] == true;
              }
            } else {
              // 没有活跃时间但服务器说在线，保持在线状态
              isOnline = true;
            }
          } else {
            // 服务器明确说离线
            isOnline = false;
            print('设备${device['name']}(${device['id']})离线 - 服务器状态');
          }
          
          // 检查是否已登出
          if (device['is_logged_out'] == true) {
            isOnline = false;
            print('设备${device['name']}(${device['id']})已登出');
          }
          
          processedDevice['isOnline'] = isOnline;
          processedDevice['is_online'] = isOnline;
          processedDevices.add(processedDevice);
        }
      }
      
      _deviceStatusController.add({
        'type': 'group_devices_status',
        'groupId': data['groupId'],
        'groupName': data['groupName'],
        'devices': processedDevices,
        'timestamp': DateTime.now().toIso8601String()
      });
    }
  }
  
  // 处理在线设备列表更新
  void _handleOnlineDevicesUpdate(Map data) {
    if (data.containsKey('devices') && data['devices'] is List) {
      print('收到在线设备列表: ${data['devices'].length}台设备');
      
      // 正确处理设备状态，根据服务器数据和活跃时间判断
      final List<Map<String, dynamic>> processedDevices = [];
      for (final device in data['devices']) {
        if (device is Map) {
          final Map<String, dynamic> processedDevice = Map<String, dynamic>.from(device);
          
          // 根据服务器返回的is_online状态和最后活跃时间来判断设备在线状态
          bool isOnline = false;
          
          // 首先检查服务器返回的is_online状态
          if (device['is_online'] == true) {
            // 如果服务器说在线，再检查最后活跃时间
            if (device['last_active_time'] != null) {
              try {
                final lastActiveTime = DateTime.parse(device['last_active_time']);
                final now = DateTime.now();
                final timeDifference = now.difference(lastActiveTime);
                
                // 如果30分钟内有活动才认为是在线，否则优先使用服务器状态
                if (timeDifference.inMinutes <= 30) {
                  isOnline = true;
                  print('在线设备${device['name']}(${device['id']}) - 最后活跃: ${timeDifference.inMinutes}分钟前');
                } else {
                  // 超过30分钟但服务器说在线，可能是WebSocket连接问题，保持在线状态
                  isOnline = true;
                  print('在线设备${device['name']}(${device['id']})在线 - 服务器状态优先 (最后活跃: ${timeDifference.inMinutes}分钟前)');
                }
              } catch (e) {
                print('解析设备活跃时间失败: $e');
                // 解析失败时使用服务器的is_online状态
                isOnline = device['is_online'] == true;
              }
            } else {
              // 没有活跃时间但服务器说在线，保持在线状态
              isOnline = true;
            }
          }
          
          // 检查是否已登出
          if (device['is_logged_out'] == true) {
            isOnline = false;
            print('设备${device['name']}(${device['id']})已登出');
          }
          
          processedDevice['isOnline'] = isOnline;
          processedDevice['is_online'] = isOnline;
          processedDevices.add(processedDevice);
        }
      }
      
      _deviceStatusController.add({
        'type': 'online_devices',
        'devices': processedDevices,
        'timestamp': DateTime.now().toIso8601String()
      });
    }
  }
  
  // 开始定期发送ping
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (_socket != null && _socket!.connected) {
        print('发送ping保持连接...');
        // 发送带有设备状态的ping，而不是空对象
        _socket!.emit('ping', {
          'status': 'active',
          'timestamp': DateTime.now().toIso8601String()
        });
        
        // 每次ping都请求设备状态和群组设备状态，提高实时性
        _requestDeviceStatus();
        _requestGroupDevicesStatus();
      } else {
        print('连接已断开，停止ping');
        timer.cancel();
        // 尝试重新连接
        connect();
      }
    });
  }
  
  // 断开连接
  void disconnect() {
    _pingTimer?.cancel();
    _socket?.disconnect();
    print('WebSocket已断开连接');
  }
  
  // 发送消息
  void emit(String event, dynamic data) {
    if (_socket != null && _socket!.connected) {
      print('发送WebSocket消息: event=$event, data=$data');
      _socket!.emit(event, data);
    } else {
      print('Socket未连接，无法发送消息');
      connect(); // 尝试重新连接
    }
  }
  
  // 手动刷新设备状态
  void refreshDeviceStatus() {
    _requestDeviceStatus();
    _requestGroupDevicesStatus();
  }
  
  // 资源释放
  void dispose() {
    _pingTimer?.cancel();
    disconnect();
    _messageController.close();
    _deviceStatusController.close();
    _logoutController.close();
    _chatMessageController.close();
    _groupChangeController.close();
    print('WebSocket资源已释放');
  }
} 