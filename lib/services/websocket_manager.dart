import 'dart:async';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/app_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed
}

enum NetworkStatus {
  unknown,
  available,
  unavailable,
  limited
}

class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;
  WebSocketManager._internal();

  IO.Socket? _socket;
  ConnectionState _connectionState = ConnectionState.disconnected;
  NetworkStatus _networkStatus = NetworkStatus.unknown;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  Timer? _networkMonitorTimer;
  Timer? _connectionHealthTimer;
  Timer? _messageReceiveTestTimer;
  Timer? _activeSyncTimer;
  bool _isManualDisconnect = false;
  DateTime? _lastSuccessfulConnection;
  DateTime? _lastMessageReceived;
  
  // 认证信息
  String? _deviceId;
  String? _token;
  
  // 事件流控制器
  final StreamController<ConnectionState> _connectionStateController = 
      StreamController<ConnectionState>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _errorController = 
      StreamController<String>.broadcast();
  final StreamController<NetworkStatus> _networkStatusController = 
      StreamController<NetworkStatus>.broadcast();

  // 公共接口
  ConnectionState get connectionState => _connectionState;
  NetworkStatus get networkStatus => _networkStatus;
  bool get isConnected => _connectionState == ConnectionState.connected;
  bool get isConnecting => _connectionState == ConnectionState.connecting;
  bool get isReconnecting => _connectionState == ConnectionState.reconnecting;
  
  Stream<ConnectionState> get onConnectionStateChanged => _connectionStateController.stream;
  Stream<Map<String, dynamic>> get onMessageReceived => _messageController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<NetworkStatus> get onNetworkStatusChanged => _networkStatusController.stream;

  /// 初始化WebSocket连接
  Future<bool> initialize({
    required String deviceId,
    required String token,
  }) async {
    try {
      _log('🚀 初始化WebSocket连接...');
      _deviceId = deviceId;
      _token = token;
      
      _setConnectionState(ConnectionState.connecting);
      
      // 启动网络监控
      _startNetworkMonitoring();
      
      // 检查网络连接
      if (!await _checkNetworkConnectivity()) {
        throw Exception('网络连接不可用');
      }

      // 创建Socket连接
      await _createSocketConnection();
      
      // 等待连接完成
      return await _waitForConnection();
      
    } catch (e) {
      _handleError('初始化失败: $e');
      _setConnectionState(ConnectionState.failed);
      return false;
    }
  }

  /// 创建Socket连接
  Future<void> _createSocketConnection() async {
    _log('📡 创建Socket连接到: ${AppConfig.WEBSOCKET_URL}');
    
    // 清理旧连接
    _cleanupSocket();
    
    _socket = IO.io(AppConfig.WEBSOCKET_URL, IO.OptionBuilder()
      .setPath(AppConfig.WEBSOCKET_PATH)
      .setTransports(['websocket', 'polling']) // 支持fallback
      .setQuery({
        'deviceId': _deviceId!,
        'token': _token!,
      })
      .setTimeout(AppConfig.CONNECT_TIMEOUT)
      .setReconnectionAttempts(0) // 禁用自动重连，手动控制
      .enableAutoConnect()
      .enableForceNew() // 强制新连接
      .disableReconnection() // 禁用自动重连
      .build()
    );

    _setupEventHandlers();
  }

  /// 设置事件处理器
  void _setupEventHandlers() {
    _socket?.on('connect', (_) {
      _log('✅ WebSocket连接成功! Socket ID: ${_socket?.id}');
      _onConnectionSuccess();
    });

    _socket?.on('disconnect', (reason) {
      _log('⚠️ WebSocket连接断开: $reason');
      _onConnectionLost(reason);
    });

    _socket?.on('connect_error', (error) {
      _log('❌ WebSocket连接错误: $error');
      _handleConnectionError(error);
    });

    _socket?.on('error', (error) {
      _log('❌ WebSocket通用错误: $error');
      _handleSocketError(error);
    });

    // 心跳响应
    _socket?.on('pong', (_) {
      _log('💓 收到心跳响应');
      _lastMessageReceived = DateTime.now();
    });

    // 🔥 新增：连接测试响应
    _socket?.on('connection_test_response', (data) {
      _log('🧪 收到连接测试响应');
      _lastMessageReceived = DateTime.now();
    });

    // 🔥 新增：服务器心跳
    _socket?.on('server_ping', (_) {
      _log('📡 收到服务器心跳');
      _lastMessageReceived = DateTime.now();
      // 立即响应服务器心跳
      _socket?.emit('pong', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    // 🔥 新增：消息接收测试响应
    _socket?.on('message_receive_test_response', (data) {
      _log('🧪 收到消息接收测试响应');
      _lastMessageReceived = DateTime.now();
      
      // 标记测试完成
      final testId = data['test_id'];
      if (testId != null && _pendingTests.containsKey(testId)) {
        _pendingTests.remove(testId);
        _log('✅ 消息接收测试通过');
      }
    });

    // 业务消息处理
    _socket?.on('message', (data) {
      _log('📩 收到通用消息: ${data.toString().substring(0, 100)}...');
      _lastMessageReceived = DateTime.now();
      _messageController.add(Map<String, dynamic>.from(data));
    });

    // 设备状态相关消息
    _socket?.on('group_devices_status', (data) {
      _log('📊 收到群组设备状态更新');
      _lastMessageReceived = DateTime.now();
      _messageController.add({
        'type': 'group_devices_status',
        'data': data,
        'timestamp': DateTime.now().toIso8601String()
      });
    });

    _socket?.on('online_devices', (data) {
      _log('📱 收到在线设备列表更新');
      _lastMessageReceived = DateTime.now();
      _messageController.add({
        'type': 'online_devices',
        'data': data,
        'timestamp': DateTime.now().toIso8601String()
      });
    });

    _socket?.on('device_status_update', (data) {
      _log('🔄 收到设备状态更新');
      _lastMessageReceived = DateTime.now();
      _messageController.add({
        'type': 'device_status_update',
        'data': data,
        'timestamp': DateTime.now().toIso8601String()
      });
    });

    // 🔥 关键修复：添加聊天消息监听
    _socket?.on('new_message', (data) {
      _log('💬 收到新的1v1消息');
      _lastMessageReceived = DateTime.now();
      _messageController.add({
        'type': 'new_private_message',
        'data': data,
        'timestamp': DateTime.now().toIso8601String()
      });
    });

    _socket?.on('new_group_message', (data) {
      _log('💬 收到新的群组消息');
      _lastMessageReceived = DateTime.now();
      _messageController.add({
        'type': 'new_group_message',
        'data': data,
        'timestamp': DateTime.now().toIso8601String()
      });
    });

    _socket?.on('file_message_received', (data) {
      _log('📎 收到文件消息');
      _lastMessageReceived = DateTime.now();
      _messageController.add({
        'type': 'new_private_message',
        'data': data,
        'timestamp': DateTime.now().toIso8601String()
      });
    });

    _socket?.on('group_file_message', (data) {
      _log('📎 收到群组文件消息');
      _lastMessageReceived = DateTime.now();
      _messageController.add({
        'type': 'new_group_message',
        'data': data,
        'timestamp': DateTime.now().toIso8601String()
      });
    });

    // 消息状态更新
    _socket?.on('message_sent', (data) {
      _log('✅ 消息发送确认');
      _lastMessageReceived = DateTime.now();
      _messageController.add({
        'type': 'message_sent_confirmation',
        'data': data,
        'timestamp': DateTime.now().toIso8601String()
      });
    });

    _socket?.on('message_status_updated', (data) {
      _log('📋 消息状态更新');
      _lastMessageReceived = DateTime.now();
      _messageController.add({
        'type': 'message_status_updated',
        'data': data,
        'timestamp': DateTime.now().toIso8601String()
      });
    });
    
    // 🔥 新增：最近消息响应
    _socket?.on('recent_messages', (data) {
      _log('📬 收到最近消息列表');
      _lastMessageReceived = DateTime.now();
      _messageController.add({
        'type': 'recent_messages',
        'data': data,
        'timestamp': DateTime.now().toIso8601String()
      });
    });
  }

  /// 连接成功处理
  void _onConnectionSuccess() {
    _setConnectionState(ConnectionState.connected);
    _reconnectAttempts = 0;
    _lastSuccessfulConnection = DateTime.now();
    _lastMessageReceived = DateTime.now();
    
    _startHeartbeat();
    _startConnectionHealthCheck();
    _startMessageReceiveTest();
    _startActiveSync();
    
    // 🔥 关键修复：连接成功后立即同步所有状态
    _performFullStateSync();
    
    _log('🎉 WebSocket连接建立成功，开始状态同步');
  }
  
  /// 执行完整的状态同步
  void _performFullStateSync() {
    _log('🔄 执行完整状态同步...');
    
    // 延迟1秒确保连接稳定后再请求状态
    Timer(Duration(seconds: 1), () {
      if (_socket?.connected == true) {
        _log('📡 请求群组设备状态...');
        _socket?.emit('request_group_devices_status', {
          'timestamp': DateTime.now().toIso8601String(),
          'reason': 'connection_restored'
        });
        
        _log('📱 请求在线设备列表...');
        _socket?.emit('get_online_devices', {
          'timestamp': DateTime.now().toIso8601String(),
          'reason': 'connection_restored'
        });
        
        _log('💬 请求未读消息同步...');
        _socket?.emit('sync_messages', {
          'timestamp': DateTime.now().toIso8601String(),
          'reason': 'connection_restored'
        });
        
        // 🔥 新增：请求最近消息
        _socket?.emit('get_recent_messages', {
          'timestamp': DateTime.now().toIso8601String(),
          'reason': 'connection_restored',
          'limit': 50 // 获取最近50条消息
        });
        
        _log('🔔 通知设备活跃状态...');
        _socket?.emit('device_activity_update', {
          'status': 'active',
          'timestamp': DateTime.now().toIso8601String(),
          'last_active': DateTime.now().toIso8601String(),
          'reason': 'connection_restored'
        });
        
        _log('✅ 状态同步请求已发送');
      }
    });
  }

  /// 连接断开处理
  void _onConnectionLost(dynamic reason) {
    _stopHeartbeat();
    _stopConnectionHealthCheck();
    _stopMessageReceiveTest();
    _stopActiveSync();
    
    if (_isManualDisconnect) {
      _setConnectionState(ConnectionState.disconnected);
      return;
    }

    // 检查断开原因
    final reasonStr = reason.toString();
    if (reasonStr.contains('server disconnect') || reasonStr.contains('logged_out')) {
      _log('🚪 服务器主动断开连接，可能是登出');
      _setConnectionState(ConnectionState.disconnected);
      _handleError('您已从其他设备登出，连接已断开');
      return;
    }

    _log('🔄 连接断开，准备重连...');
    _setConnectionState(ConnectionState.reconnecting);
    _scheduleReconnect();
  }

  /// 处理连接错误
  void _handleConnectionError(dynamic error) {
    _log('❌ 连接错误: $error');
    
    if (!_isManualDisconnect) {
      _setConnectionState(ConnectionState.reconnecting);
      _scheduleReconnect(isError: true);
    }
  }

  /// 处理Socket错误
  void _handleSocketError(dynamic error) {
    _log('⚠️ Socket错误: $error');
    _handleError('Socket错误: $error');
  }

  /// 检查网络连接
  Future<bool> _checkNetworkConnectivity() async {
    _log('🔍 检查网络连接...');
    
    if (kIsWeb) {
      // Web环境：使用HTTP请求检查网络连接
      return await _checkWebNetworkConnectivity();
    } else {
      // 移动/桌面环境：使用DNS解析检查
      return await _checkNativeNetworkConnectivity();
    }
  }
  
  /// Web环境网络检查
  Future<bool> _checkWebNetworkConnectivity() async {
    final testUrls = [
      'https://www.google.com/',
      'https://www.cloudflare.com/',
      'https://sendtomyself-api-adecumh2za-uc.a.run.app/health',
    ];
    
    for (final url in testUrls) {
      try {
        _log('🌐 尝试连接: $url');
        final response = await http.get(Uri.parse(url))
            .timeout(Duration(milliseconds: AppConfig.NETWORK_CHECK_TIMEOUT));
        
        if (response.statusCode < 500) { // 任何非5xx错误都表示网络连通
          _log('✅ 网络连接正常 (通过: $url)');
          _setNetworkStatus(NetworkStatus.available);
          return true;
        }
      } catch (e) {
        _log('❌ 连接$url失败: $e');
        continue;
      }
    }
    
    _log('❌ 所有网络检查都失败');
    _setNetworkStatus(NetworkStatus.unavailable);
    return false;
  }
  
  /// 原生环境网络检查
  Future<bool> _checkNativeNetworkConnectivity() async {
    // 测试多个域名以提高成功率
    final testDomains = [
      'google.com',
      '8.8.8.8',
      'cloudflare.com',
    ];
    
    for (final domain in testDomains) {
      try {
        _log('🌐 尝试连接: $domain');
        final result = await InternetAddress.lookup(domain)
            .timeout(Duration(milliseconds: AppConfig.NETWORK_CHECK_TIMEOUT));
        
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          _log('✅ 网络连接正常 (通过: $domain)');
          _setNetworkStatus(NetworkStatus.available);
          return true;
        }
      } catch (e) {
        _log('❌ 连接$domain失败: $e');
        continue;
      }
    }
    
    _log('❌ 所有网络检查都失败');
    _setNetworkStatus(NetworkStatus.unavailable);
    return false;
  }

  /// 检查服务器连通性
  Future<bool> _checkServerConnectivity() async {
    try {
      _log('🔍 检查服务器连通性...');
      
      if (kIsWeb) {
        // Web环境：使用HTTP请求检查服务器
        final response = await http.get(
          Uri.parse('https://sendtomyself-api-adecumh2za-uc.a.run.app/health')
        ).timeout(Duration(milliseconds: AppConfig.DNS_CHECK_TIMEOUT));
        
        if (response.statusCode < 500) {
          _log('✅ 服务器连通性正常: ${response.statusCode}');
          return true;
        }
      } else {
        // 原生环境：使用DNS解析检查
        final result = await InternetAddress.lookup('sendtomyself-api-adecumh2za-uc.a.run.app')
            .timeout(Duration(milliseconds: AppConfig.DNS_CHECK_TIMEOUT));
        
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          _log('✅ 服务器连通性正常: ${result[0].address}');
          return true;
        }
      }
    } catch (e) {
      _log('⚠️ 服务器连通性检查失败: $e');
      
      // 如果检查失败但网络可能正常，仍允许尝试连接
      if (_networkStatus == NetworkStatus.available) {
        _log('🔄 网络正常，允许尝试连接服务器');
        return true;
      }
    }
    return false;
  }

  /// 智能重连调度
  void _scheduleReconnect({bool isError = false}) {
    if (_reconnectAttempts >= AppConfig.MAX_RECONNECT_ATTEMPTS) {
      _log('❌ 达到最大重连次数(${AppConfig.MAX_RECONNECT_ATTEMPTS})，停止重连');
      _setConnectionState(ConnectionState.failed);
      _handleError('连接失败，已达到最大重连次数');
      return;
    }

    final delayIndex = _reconnectAttempts.clamp(0, AppConfig.RECONNECT_DELAYS.length - 1);
    final delay = AppConfig.RECONNECT_DELAYS[delayIndex];
    
    _reconnectAttempts++;
    
    _log('⏰ 安排${delay}秒后进行第${_reconnectAttempts}次重连 (${isError ? "错误重连" : "正常重连"})');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      _attemptReconnect();
    });
  }

  /// 尝试重连
  Future<void> _attemptReconnect() async {
    if (_isManualDisconnect) return;
    
    _log('🔄 开始第${_reconnectAttempts}次重连... (${_reconnectAttempts}/${AppConfig.MAX_RECONNECT_ATTEMPTS})');
    
    try {
      // 检查网络状态
      if (!await _checkNetworkConnectivity()) {
        throw Exception('网络连接不可用');
      }

      // 检查服务器连通性
      if (!await _checkServerConnectivity()) {
        throw Exception('服务器不可达');
      }

      // 重新创建连接
      await _createSocketConnection();
      
    } catch (e) {
      _log('❌ 重连失败: $e');
      _scheduleReconnect(isError: true);
    }
  }

  /// 等待连接完成
  Future<bool> _waitForConnection() async {
    final completer = Completer<bool>();
    Timer? timeoutTimer;

    // 设置超时
    timeoutTimer = Timer(Duration(milliseconds: AppConfig.CONNECT_TIMEOUT + 5000), () {
      if (!completer.isCompleted) {
        _log('⏰ 连接等待超时');
        completer.complete(false);
      }
    });

    // 监听连接状态变化
    late StreamSubscription subscription;
    subscription = _connectionStateController.stream.listen((state) {
      if (state == ConnectionState.connected && !completer.isCompleted) {
        timeoutTimer?.cancel();
        subscription.cancel();
        completer.complete(true);
      } else if (state == ConnectionState.failed && !completer.isCompleted) {
        timeoutTimer?.cancel();
        subscription.cancel();
        completer.complete(false);
      }
    });
    
    final result = await completer.future;
    timeoutTimer?.cancel();
    
    return result;
  }

  /// 开始心跳
  void _startHeartbeat() {
    _stopHeartbeat();
    
    _heartbeatTimer = Timer.periodic(Duration(milliseconds: AppConfig.HEARTBEAT_INTERVAL), (_) {
      if (_socket?.connected == true) {
        _log('💓 发送心跳ping');
        _socket?.emit('ping', {
          'timestamp': DateTime.now().toIso8601String(),
          'clientTime': DateTime.now().millisecondsSinceEpoch,
        });
        
        // 🔥 关键修复：每次心跳时检查消息接收状态
        _checkMessageReceiveHealth();
      }
    });
  }

  /// 🔥 新增：检查消息接收健康状态
  void _checkMessageReceiveHealth() {
    if (_lastMessageReceived != null) {
      final timeSinceLastMessage = DateTime.now().difference(_lastMessageReceived!);
      
      // 如果超过3分钟没收到任何消息（包括心跳响应），认为连接可能有问题
      if (timeSinceLastMessage.inMinutes >= 3) {
        _log('⚠️ 警告：${timeSinceLastMessage.inMinutes}分钟未收到消息，可能连接异常');
        
        // 发送测试消息检查连接
        _sendConnectionTest();
        
        // 如果超过5分钟，强制重新设置监听器
        if (timeSinceLastMessage.inMinutes >= 5) {
          _log('🔄 消息接收异常，重新设置监听器');
          _refreshEventHandlers();
        }
        
        // 如果超过8分钟，强制重连
        if (timeSinceLastMessage.inMinutes >= 8) {
          _log('❌ 连接可能断开，执行强制重连');
          _forceReconnect();
        }
      }
    }
  }
  
  /// 🔥 新增：发送连接测试
  void _sendConnectionTest() {
    _log('🧪 发送连接测试消息');
    if (_socket?.connected == true) {
      _socket?.emit('connection_test', {
        'timestamp': DateTime.now().toIso8601String(),
        'test_id': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
  
  /// 🔥 新增：刷新事件监听器
  void _refreshEventHandlers() {
    _log('🔄 刷新WebSocket事件监听器...');
    
    if (_socket?.connected == true) {
      // 清除旧的监听器
      _socket?.clearListeners();
      
      // 重新设置监听器
      _setupEventHandlers();
      
      // 重新请求状态同步
      _performFullStateSync();
      
      _log('✅ 事件监听器已刷新');
    }
  }

  /// 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 开始连接健康检查
  void _startConnectionHealthCheck() {
    _stopConnectionHealthCheck();
    
    _connectionHealthTimer = Timer.periodic(Duration(milliseconds: AppConfig.CONNECTION_HEALTH_CHECK), (_) {
      _checkConnectionHealth();
    });
  }

  /// 停止连接健康检查
  void _stopConnectionHealthCheck() {
    _connectionHealthTimer?.cancel();
    _connectionHealthTimer = null;
  }

  /// 检查连接健康状态
  void _checkConnectionHealth() {
    if (_lastMessageReceived != null) {
      final timeSinceLastMessage = DateTime.now().difference(_lastMessageReceived!);
      
      if (timeSinceLastMessage.inMinutes > 5) {
        _log('⚠️ 连接可能不健康：${timeSinceLastMessage.inMinutes}分钟未收到消息');
        
        if (timeSinceLastMessage.inMinutes > 10) {
          _log('❌ 连接超时，强制重连');
          _forceReconnect();
        }
      }
    }
  }

  /// 开始网络监控
  void _startNetworkMonitoring() {
    _stopNetworkMonitoring();
    
    _networkMonitorTimer = Timer.periodic(Duration(milliseconds: AppConfig.NETWORK_MONITOR_INTERVAL), (_) {
      _monitorNetwork();
    });
  }

  /// 停止网络监控
  void _stopNetworkMonitoring() {
    _networkMonitorTimer?.cancel();
    _networkMonitorTimer = null;
  }

  /// 监控网络状态
  void _monitorNetwork() {
    if (!isConnected) {
      _log('🔍 检查网络状态恢复...');
      _checkNetworkConnectivity().then((isAvailable) {
        if (isAvailable && !_isManualDisconnect && _connectionState != ConnectionState.connecting) {
          _log('📶 网络已恢复，尝试重连...');
          _reconnectAttempts = 0; // 重置重连计数
          _attemptReconnect();
        }
      });
    }
  }

  /// 强制重连
  void _forceReconnect() {
    _log('🔄 执行强制重连...');
    
    _cleanupSocket();
    _stopAllTimers();
    
    if (!_isManualDisconnect && _deviceId != null && _token != null) {
      _setConnectionState(ConnectionState.reconnecting);
      _scheduleReconnect();
    }
  }

  /// 清理Socket连接
  void _cleanupSocket() {
    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// 停止所有定时器
  void _stopAllTimers() {
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    _stopConnectionHealthCheck();
    _stopMessageReceiveTest();
    _stopActiveSync();
  }

  /// 设置连接状态
  void _setConnectionState(ConnectionState state) {
    if (_connectionState != state) {
      final oldState = _connectionState;
      _connectionState = state;
      _log('🔄 连接状态变化: $oldState -> $state');
      _connectionStateController.add(state);
    }
  }

  /// 设置网络状态
  void _setNetworkStatus(NetworkStatus status) {
    if (_networkStatus != status) {
      final oldStatus = _networkStatus;
      _networkStatus = status;
      _log('📶 网络状态变化: $oldStatus -> $status');
      _networkStatusController.add(status);
    }
  }

  /// 处理错误
  void _handleError(String error) {
    _log('❌ 错误: $error');
    _errorController.add(error);
  }

  /// 日志输出
  void _log(String message) {
    if (AppConfig.DEBUG_WEBSOCKET) {
      print('🔌 WebSocketManager: $message');
    }
  }

  /// 发送消息
  void emit(String event, [dynamic data]) {
    if (_socket?.connected == true) {
      _log('📤 发送消息: $event');
      _socket?.emit(event, data);
    } else {
      _log('⚠️ WebSocket未连接，无法发送消息: $event');
    }
  }

  /// 手动断开连接
  void disconnect() {
    _log('🔌 手动断开WebSocket连接');
    _isManualDisconnect = true;
    _stopAllTimers();
    _stopNetworkMonitoring();
    _cleanupSocket();
    _setConnectionState(ConnectionState.disconnected);
  }

  /// 手动重连
  Future<bool> reconnect() async {
    if (_deviceId == null || _token == null) {
      _handleError('缺少认证信息，无法重连');
      return false;
    }

    _log('🔄 手动重连WebSocket...');
    disconnect();
    await Future.delayed(Duration(milliseconds: 500));
    _isManualDisconnect = false;
    _reconnectAttempts = 0;
    return await initialize(deviceId: _deviceId!, token: _token!);
  }

  /// 获取连接信息
  Map<String, dynamic> getConnectionInfo() {
    return {
      'connectionState': _connectionState.toString(),
      'networkStatus': _networkStatus.toString(),
      'isConnected': isConnected,
      'reconnectAttempts': _reconnectAttempts,
      'maxReconnectAttempts': AppConfig.MAX_RECONNECT_ATTEMPTS,
      'lastSuccessfulConnection': _lastSuccessfulConnection?.toIso8601String(),
      'lastMessageReceived': _lastMessageReceived?.toIso8601String(),
      'socketId': _socket?.id,
      'deviceId': _deviceId,
    };
  }

  /// 清理资源
  void dispose() {
    _log('🧹 清理WebSocket资源...');
    disconnect();
    _connectionStateController.close();
    _messageController.close();
    _errorController.close();
    _networkStatusController.close();
  }

  /// 🔥 新增：开始消息接收测试
  void _startMessageReceiveTest() {
    _stopMessageReceiveTest();
    
    // 每2分钟测试一次消息接收能力
    _messageReceiveTestTimer = Timer.periodic(Duration(minutes: 2), (_) {
      _performMessageReceiveTest();
    });
  }
  
  /// 🔥 新增：停止消息接收测试
  void _stopMessageReceiveTest() {
    _messageReceiveTestTimer?.cancel();
    _messageReceiveTestTimer = null;
  }
  
  /// 🔥 新增：执行消息接收测试
  void _performMessageReceiveTest() {
    if (_socket?.connected == true) {
      _log('🧪 执行消息接收测试...');
      
      final testId = DateTime.now().millisecondsSinceEpoch;
      _pendingTests[testId] = DateTime.now();
      
      // 发送测试消息
      _socket?.emit('message_receive_test', {
        'test_id': testId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // 3秒后检查是否收到响应
      Timer(Duration(seconds: 3), () {
        if (_pendingTests.containsKey(testId)) {
          _log('❌ 消息接收测试失败，未收到响应');
          _pendingTests.remove(testId);
          
          // 测试失败，尝试刷新监听器
          _refreshEventHandlers();
        }
      });
    }
  }
  
  Map<int, DateTime> _pendingTests = {}; // 🔥 新增：待处理的测试
  
  /// 🔥 新增：开始主动同步
  void _startActiveSync() {
    _stopActiveSync();
    
    // 每5分钟主动同步一次消息和状态
    _activeSyncTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _performActiveSync();
    });
  }
  
  /// 🔥 新增：停止主动同步
  void _stopActiveSync() {
    _activeSyncTimer?.cancel();
    _activeSyncTimer = null;
  }
  
  /// 🔥 新增：执行主动同步
  void _performActiveSync() {
    if (_socket?.connected == true) {
      _log('🔄 执行主动消息和状态同步...');
      
      // 主动请求最新消息
      _socket?.emit('get_recent_messages', {
        'timestamp': DateTime.now().toIso8601String(),
        'reason': 'active_sync',
        'limit': 20
      });
      
      // 主动请求设备状态
      _socket?.emit('request_group_devices_status', {
        'timestamp': DateTime.now().toIso8601String(),
        'reason': 'active_sync'
      });
      
      // 主动请求在线设备
      _socket?.emit('get_online_devices', {
        'timestamp': DateTime.now().toIso8601String(),
        'reason': 'active_sync'
      });
      
      _log('✅ 主动同步请求已发送');
    }
  }
} 