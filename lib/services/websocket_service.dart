import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'dart:io';
import 'device_auth_service.dart';
import 'dart:convert';

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
  Timer? _reconnectTimer;
  DateTime? _lastPongTime; // 添加最后pong时间记录
  
  // 重连控制
  int _reconnectAttempts = 0;
  int _maxReconnectAttempts = 10;
  bool _isReconnecting = false;
  bool _shouldReconnect = true;
  
  // 网络状态检查
  bool _isNetworkAvailable = true;
  DateTime? _lastSuccessfulConnection;
  
  // 连接健康检查
  bool _isConnectionHealthy = true;
  int _consecutiveFailures = 0;
  
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
    // 如果正在重连，避免重复连接
    if (_isReconnecting) {
      print('正在重连中，跳过新的连接请求');
      return;
    }
    
    // 如果已经有socket实例并且已连接，直接返回
    if (_socket != null && _socket!.connected && _isConnectionHealthy) {
      print('WebSocket已连接且健康');
      return;
    }
    
    try {
      _isReconnecting = true;
      
      // 1. 检查网络连接
      if (!await _checkNetworkConnectivity()) {
        throw Exception('网络连接不可用');
      }
      
      // 2. 检查DNS解析
      if (!await _checkDnsResolution()) {
        throw Exception('DNS解析失败，无法访问服务器');
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
      print('重连尝试: ${_reconnectAttempts}/${_maxReconnectAttempts}');
      
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
          'reconnection': false, // 禁用自动重连，我们自己控制
          'timeout': 20000, // 20秒连接超时
        }
      );
      
      // 设置Socket.IO事件监听器
      _socket!.onConnect((_) {
        print('✅ WebSocket连接成功! Socket ID: ${_socket!.id}');
        _onConnectionSuccess();
        
        // 连接成功后立即请求设备状态
        _requestDeviceStatus();
        
        // 请求群组设备状态
        _requestGroupDevicesStatus();
      });
      
      _socket!.on('message', (data) {
        print('📩 收到消息: $data');
        _onMessageReceived();
        
        if (data is Map) {
          _messageController.add(Map<String, dynamic>.from(data));
          
          // 根据消息类型处理
          if (data.containsKey('type')) {
            final messageType = data['type'];
            _handleMessageByType(messageType, Map<String, dynamic>.from(data));
          }
        }
      });
      
      _socket!.onDisconnect((reason) {
        print('⚠️ WebSocket连接断开: $reason');
        _onConnectionLost(reason);
      });
      
      _socket!.onConnectError((error) {
        print('❌ WebSocket连接错误: $error');
        _onConnectionError(error);
      });
      
      _socket!.onError((error) {
        print('❌ WebSocket错误: $error');
        _onSocketError(error);
      });
      
      print('WebSocket初始化完成');
      
    } catch (e) {
      print('❌ WebSocket连接失败: $e');
      _onConnectionFailed(e);
      rethrow;
    } finally {
      _isReconnecting = false;
    }
  }
  
  // 检查网络连接
  Future<bool> _checkNetworkConnectivity() async {
    try {
      print('检查网络连接...');
      final result = await InternetAddress.lookup('google.com')
          .timeout(Duration(seconds: 10));
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('✅ 网络连接正常');
        _isNetworkAvailable = true;
        return true;
      }
    } catch (e) {
      print('❌ 网络连接检查失败: $e');
      _isNetworkAvailable = false;
    }
    return false;
  }
  
  // 检查DNS解析
  Future<bool> _checkDnsResolution() async {
    try {
      print('检查服务器DNS解析...');
      final result = await InternetAddress.lookup('sendtomyself-api-adecumh2za-uc.a.run.app')
          .timeout(Duration(seconds: 15));
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('✅ 服务器DNS解析成功: ${result[0].address}');
        return true;
      }
    } catch (e) {
      print('❌ 服务器DNS解析失败: $e');
      
      // 如果DNS解析失败，尝试备用检查
      try {
        print('尝试备用DNS检查...');
        final result = await InternetAddress.lookup('google.com')
            .timeout(Duration(seconds: 10));
        if (result.isNotEmpty) {
          print('⚠️ 网络正常但服务器DNS解析失败，可能是服务器问题');
        }
      } catch (e2) {
        print('❌ 备用DNS检查也失败，网络可能有问题: $e2');
      }
    }
    return false;
  }
  
  // 连接成功处理
  void _onConnectionSuccess() {
    _reconnectAttempts = 0;
    _consecutiveFailures = 0;
    _isConnectionHealthy = true;
    _lastSuccessfulConnection = DateTime.now();
    _shouldReconnect = true;
    
    // 取消重连定时器
    _reconnectTimer?.cancel();
    
    _startPingTimer(); // 开始发送定期ping
    print('🎉 WebSocket连接恢复正常');
  }
  
  // 收到消息时的处理（连接健康检查）
  void _onMessageReceived() {
    _isConnectionHealthy = true;
    _consecutiveFailures = 0;
    _lastPongTime = DateTime.now();
  }
  
  // 连接丢失处理
  void _onConnectionLost(String? reason) {
    _isConnectionHealthy = false;
    _pingTimer?.cancel(); // 停止ping
    
    print('连接断开原因: $reason');
    
    // 检查是否是服务端主动断开（登出）
    if (reason == 'io server disconnect') {
      print('服务端主动断开连接，可能是登出操作');
      _shouldReconnect = false;
      _logoutController.add({
        'type': 'forced_disconnect',
        'message': '您已从其他设备登出，连接已断开',
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String()
      });
      return;
    }
    
    // 其他原因的断开，尝试重连
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }
  
  // 连接错误处理
  void _onConnectionError(dynamic error) {
    _consecutiveFailures++;
    _isConnectionHealthy = false;
    
    final errorStr = error.toString();
    
    // 检查是否是登出导致的连接错误
    if (errorStr.contains('设备已登出') || 
        errorStr.contains('device_logged_out') ||
        errorStr.contains('已登出')) {
      print('设备已登出，无法重连');
      _shouldReconnect = false;
      _logoutController.add({
        'type': 'reconnect_blocked',
        'message': '设备已登出，请重新登录',
        'error': errorStr,
        'timestamp': DateTime.now().toIso8601String()
      });
      return;
    }
    
    // DNS或网络错误
    if (errorStr.contains('Failed host lookup') || 
        errorStr.contains('No address associated with hostname')) {
      print('DNS解析错误，网络或服务器可能有问题');
      
      // 增加更长的重连延迟
      if (_shouldReconnect) {
        _scheduleReconnect(isNetworkError: true);
      }
      return;
    }
    
    // 其他连接错误
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }
  
  // Socket错误处理
  void _onSocketError(dynamic error) {
    print('Socket错误: $error');
    _consecutiveFailures++;
    _isConnectionHealthy = false;
  }
  
  // 连接失败处理
  void _onConnectionFailed(dynamic error) {
    _consecutiveFailures++;
    _isConnectionHealthy = false;
    
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }
  
  // 安排重连
  void _scheduleReconnect({bool isNetworkError = false}) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ 达到最大重连次数，停止重连');
      _shouldReconnect = false;
      return;
    }
    
    _reconnectAttempts++;
    
    // 指数退避算法，网络错误时使用更长延迟
    int baseDelay = isNetworkError ? 10 : 5; // 网络错误基础延迟10秒，其他5秒
    int delay = (baseDelay * (1 << (_reconnectAttempts - 1))).clamp(baseDelay, isNetworkError ? 120 : 60); // 最大延迟2分钟/1分钟
    
    print('⏰ 安排${delay}秒后进行第${_reconnectAttempts}次重连${isNetworkError ? '(网络错误)' : ''}');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      if (_shouldReconnect && !isConnected) {
        print('🔄 开始第${_reconnectAttempts}次重连...');
        connect().catchError((e) {
          print('重连失败: $e');
        });
      }
    });
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
                
                // 缩短在线判断时间到3分钟，提高准确性
                if (timeDifference.inMinutes <= 3) {
                  isOnline = true;
                  print('设备${device['name']}(${device['id']})在线 - 最后活跃: ${timeDifference.inMinutes}分钟前');
                } else if (timeDifference.inMinutes <= 10) {
                  // 3-10分钟内显示为"刚刚离线"但保持在线状态用于通信
                  isOnline = true;
                  print('设备${device['name']}(${device['id']})刚刚离线 - 最后活跃: ${timeDifference.inMinutes}分钟前');
                } else {
                  // 超过10分钟认为真正离线
                  isOnline = false;
                  print('设备${device['name']}(${device['id']})离线 - 最后活跃: ${timeDifference.inMinutes}分钟前');
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
                
                // 缩短在线判断时间到3分钟，保持与群组设备状态一致
                if (timeDifference.inMinutes <= 3) {
                  isOnline = true;
                  print('在线设备${device['name']}(${device['id']}) - 最后活跃: ${timeDifference.inMinutes}分钟前');
                } else if (timeDifference.inMinutes <= 10) {
                  // 3-10分钟内显示为"刚刚离线"但保持在线状态用于通信
                  isOnline = true;
                  print('在线设备${device['name']}(${device['id']})刚刚离线 - 最后活跃: ${timeDifference.inMinutes}分钟前');
                } else {
                  // 超过10分钟认为真正离线
                  isOnline = false;
                  print('在线设备${device['name']}(${device['id']})离线 - 最后活跃: ${timeDifference.inMinutes}分钟前');
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
    
    // 优化ping间隔：根据连接健康状况动态调整
    int pingInterval = _isConnectionHealthy ? 30 : 15; // 连接健康时30秒，不健康时15秒
    
    _pingTimer = Timer.periodic(Duration(seconds: pingInterval), (timer) {
      if (_socket != null && _socket!.connected) {
        print('🏓 发送ping保持连接... (间隔: ${pingInterval}秒)');
        
        // 发送带有设备状态的ping
        _socket!.emit('ping', {
          'status': 'active',
          'timestamp': DateTime.now().toIso8601String(),
          'clientTime': DateTime.now().millisecondsSinceEpoch,
        });
        
        // 检查连接健康状况
        _checkConnectionHealth();
        
        // 定期请求设备状态更新（降低频率）
        if (_reconnectAttempts == 0) { // 只在连接稳定时请求
          _requestDeviceStatus();
          _requestGroupDevicesStatus();
        }
      } else {
        print('❌ 连接已断开，停止ping');
        timer.cancel();
        
        // 如果应该重连但连接已断开，尝试重新连接
        if (_shouldReconnect && !_isReconnecting) {
          print('🔄 检测到连接断开，开始重连...');
          _scheduleReconnect();
        }
      }
    });
  }
  
  // 检查连接健康状况
  void _checkConnectionHealth() {
    if (_lastPongTime != null) {
      final timeSinceLastPong = DateTime.now().difference(_lastPongTime!);
      
      // 如果超过2分钟没收到任何消息，认为连接可能有问题
      if (timeSinceLastPong.inMinutes > 2) {
        print('⚠️ 连接可能不健康：${timeSinceLastPong.inMinutes}分钟未收到消息');
        _isConnectionHealthy = false;
        
        // 如果超过5分钟，强制重连
        if (timeSinceLastPong.inMinutes > 5) {
          print('❌ 连接超时，强制重连');
          _forceReconnect();
        }
      } else {
        _isConnectionHealthy = true;
      }
    }
  }
  
  // 强制重连
  void _forceReconnect() {
    print('🔄 执行强制重连...');
    
    // 断开当前连接
    _socket?.disconnect();
    _socket = null;
    
    // 重置状态
    _isConnectionHealthy = false;
    _pingTimer?.cancel();
    
    // 安排重连
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }
  
  // 手动重连方法
  Future<void> reconnect() async {
    print('🔄 手动重连WebSocket...');
    
    // 重置重连计数
    _reconnectAttempts = 0;
    _shouldReconnect = true;
    
    // 断开当前连接
    disconnect();
    
    // 等待一秒后重连
    await Future.delayed(Duration(seconds: 1));
    
    try {
      await connect();
    } catch (e) {
      print('手动重连失败: $e');
    }
  }
  
  // 断开连接
  void disconnect() {
    print('🔌 断开WebSocket连接');
    
    _shouldReconnect = false; // 主动断开时不自动重连
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
    
    _isConnectionHealthy = false;
    print('WebSocket已断开连接');
  }
  
  // 发送消息
  void emit(String event, dynamic data) {
    if (_socket != null && _socket!.connected && _isConnectionHealthy) {
      print('📤 发送WebSocket消息: event=$event');
      _socket!.emit(event, data);
    } else {
      print('❌ Socket未连接或不健康，无法发送消息 (event=$event)');
      
      // 如果连接不健康，尝试重新连接
      if (_shouldReconnect && !_isReconnecting) {
        print('🔄 尝试重新连接以发送消息...');
        connect().catchError((e) {
          print('为发送消息而重连失败: $e');
        });
      }
    }
  }
  
  // 手动刷新设备状态
  void refreshDeviceStatus() {
    if (isConnected && _isConnectionHealthy) {
      _requestDeviceStatus();
      _requestGroupDevicesStatus();
    } else {
      print('⚠️ 连接不健康，跳过设备状态刷新');
    }
  }
  
  // 获取连接状态信息
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': isConnected,
      'isHealthy': _isConnectionHealthy,
      'reconnectAttempts': _reconnectAttempts,
      'maxReconnectAttempts': _maxReconnectAttempts,
      'shouldReconnect': _shouldReconnect,
      'isReconnecting': _isReconnecting,
      'lastSuccessfulConnection': _lastSuccessfulConnection?.toIso8601String(),
      'lastPongTime': _lastPongTime?.toIso8601String(),
      'consecutiveFailures': _consecutiveFailures,
      'isNetworkAvailable': _isNetworkAvailable,
    };
  }
  
  // 资源释放
  void dispose() {
    print('🧹 开始清理WebSocket资源...');
    
    _shouldReconnect = false; // 确保不会再重连
    
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
    
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
      
      case 'removed_from_group':
        print('被移除出群组通知');
        _groupChangeController.add({
          'type': 'removed_from_group',
          'group': data['group'],
          'removedAt': data['removedAt'],
          'action': data['action'],
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
      
      case 'group_ownership_changed':
        print('群组所有权变更通知');
        _groupChangeController.add({
          'type': 'group_ownership_changed',
          'group': data['group'],
          'previousOwner': data['previousOwner'],
          'newOwner': data['newOwner'],
          'reason': data['reason'],
          'changedAt': data['changedAt'],
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
      
      case 'group_renamed':
        print('群组重命名通知');
        _groupChangeController.add({
          'type': 'group_renamed',
          'groupId': data['groupId'],
          'oldName': data['oldName'],
          'newName': data['newName'],
          'renamedBy': data['renamedBy'],
          'renamedAt': data['renamedAt'],
          'timestamp': DateTime.now().toIso8601String()
        });
        break;
      
      case 'device_renamed':
        print('设备重命名通知');
        _groupChangeController.add({
          'type': 'device_renamed',
          'deviceId': data['deviceId'],
          'newName': data['newName'],
          'renamedAt': data['renamedAt'],
          'groupId': data['groupId'],
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
        _handleGroupDevicesStatus(data);
        break;
        
      case 'online_devices':
        print('在线设备列表更新');
        _handleOnlineDevicesUpdate(data);
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
        
      default:
        print('未知的消息类型: $messageType');
        break;
    }
  }
} 