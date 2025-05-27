# WebSocket连接稳定性改进

## 问题描述

原应用在使用过程中出现定期的WebSocket连接错误：
```
SocketException: Failed host lookup: 'sendtomyself-api-adecumh2za-uc.a.run.app' (OS Error: No address associated with hostname, errno = 7)
```

这个错误表示DNS解析失败，通常由以下原因导致：
- 网络连接不稳定或断开
- DNS服务器无法解析域名
- 服务器暂时不可用
- 网络切换（WiFi ↔ 移动网络）
- 原有重试机制不够健壮

## 解决方案概述

实施了一套完整的连接稳定性改进方案，包括：
1. **网络状态检查** - 连接前检查网络和DNS
2. **指数退避重连** - 智能重连算法
3. **连接健康监控** - 实时监控连接状态
4. **错误分类处理** - 针对不同错误类型的处理策略

## 核心改进

### 1. 连接前预检查

#### 网络连接检查
```dart
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
```

#### DNS解析检查
```dart
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
    
    // 备用检查：如果DNS解析失败，检查是否是网络问题
    try {
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
```

### 2. 智能重连机制

#### 指数退避算法
```dart
void _scheduleReconnect({bool isNetworkError = false}) {
  if (_reconnectAttempts >= _maxReconnectAttempts) {
    print('❌ 达到最大重连次数，停止重连');
    _shouldReconnect = false;
    return;
  }
  
  _reconnectAttempts++;
  
  // 指数退避算法，网络错误时使用更长延迟
  int baseDelay = isNetworkError ? 10 : 5; // 网络错误基础延迟10秒，其他5秒
  int delay = (baseDelay * (1 << (_reconnectAttempts - 1))).clamp(baseDelay, isNetworkError ? 120 : 60);
  
  print('⏰ 安排${delay}秒后进行第${_reconnectAttempts}次重连${isNetworkError ? '(网络错误)' : ''}');
  
  _reconnectTimer = Timer(Duration(seconds: delay), () {
    if (_shouldReconnect && !isConnected) {
      print('🔄 开始第${_reconnectAttempts}次重连...');
      connect().catchError((e) {
        print('重连失败: $e');
      });
    }
  });
}
```

#### 重连延迟策略
| 重连次数 | 普通错误延迟 | 网络错误延迟 |
|---------|-------------|-------------|
| 1       | 5秒         | 10秒        |
| 2       | 10秒        | 20秒        |
| 3       | 20秒        | 40秒        |
| 4       | 40秒        | 80秒        |
| 5+      | 60秒(最大)   | 120秒(最大)  |

### 3. 连接健康监控

#### 连接状态管理
```dart
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
```

#### 动态Ping间隔
```dart
void _startPingTimer() {
  _pingTimer?.cancel();
  
  // 根据连接健康状况动态调整ping间隔
  int pingInterval = _isConnectionHealthy ? 30 : 15; // 健康时30秒，不健康时15秒
  
  _pingTimer = Timer.periodic(Duration(seconds: pingInterval), (timer) {
    if (_socket != null && _socket!.connected) {
      print('🏓 发送ping保持连接... (间隔: ${pingInterval}秒)');
      
      _socket!.emit('ping', {
        'status': 'active',
        'timestamp': DateTime.now().toIso8601String(),
        'clientTime': DateTime.now().millisecondsSinceEpoch,
      });
      
      _checkConnectionHealth();
      
      // 只在连接稳定时请求设备状态
      if (_reconnectAttempts == 0) {
        _requestDeviceStatus();
        _requestGroupDevicesStatus();
      }
    } else {
      print('❌ 连接已断开，停止ping');
      timer.cancel();
      
      if (_shouldReconnect && !_isReconnecting) {
        print('🔄 检测到连接断开，开始重连...');
        _scheduleReconnect();
      }
    }
  });
}
```

#### 连接健康检查
```dart
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
```

### 4. 错误分类处理

#### DNS错误特殊处理
```dart
void _onConnectionError(dynamic error) {
  _consecutiveFailures++;
  _isConnectionHealthy = false;
  
  final errorStr = error.toString();
  
  // DNS或网络错误 - 使用更长的重连延迟
  if (errorStr.contains('Failed host lookup') || 
      errorStr.contains('No address associated with hostname')) {
    print('DNS解析错误，网络或服务器可能有问题');
    
    if (_shouldReconnect) {
      _scheduleReconnect(isNetworkError: true); // 使用网络错误的长延迟
    }
    return;
  }
  
  // 登出错误 - 停止重连
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
  
  // 其他连接错误 - 正常重连
  if (_shouldReconnect) {
    _scheduleReconnect();
  }
}
```

### 5. 改进的资源管理

#### 防止重复连接
```dart
Future<void> connect() async {
  // 防止重复连接
  if (_isReconnecting) {
    print('正在重连中，跳过新的连接请求');
    return;
  }
  
  // 如果已连接且健康，直接返回
  if (_socket != null && _socket!.connected && _isConnectionHealthy) {
    print('WebSocket已连接且健康');
    return;
  }
  
  // ... 连接逻辑
}
```

#### 完善的资源清理
```dart
void dispose() {
  print('🧹 开始清理WebSocket资源...');
  
  _shouldReconnect = false; // 确保不会再重连
  
  _pingTimer?.cancel();
  _reconnectTimer?.cancel();
  
  if (_socket != null) {
    _socket!.disconnect();
    _socket = null;
  }
  
  // 安全关闭所有流控制器
  if (!_messageController.isClosed) _messageController.close();
  if (!_deviceStatusController.isClosed) _deviceStatusController.close();
  if (!_logoutController.isClosed) _logoutController.close();
  if (!_chatMessageController.isClosed) _chatMessageController.close();
  if (!_groupChangeController.isClosed) _groupChangeController.close();
  
  print('✅ WebSocket资源已完全释放');
}
```

## 新增功能

### 1. 手动重连
```dart
Future<void> reconnect() async {
  print('🔄 手动重连WebSocket...');
  
  // 重置重连计数
  _reconnectAttempts = 0;
  _shouldReconnect = true;
  
  // 断开当前连接
  disconnect();
  
  // 等待后重连
  await Future.delayed(Duration(seconds: 1));
  
  try {
    await connect();
  } catch (e) {
    print('手动重连失败: $e');
  }
}
```

### 2. 连接状态信息
```dart
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
```

### 3. 强制重连
```dart
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
```

## 连接状态指示器

### 连接状态
- ✅ **连接正常且健康** - 正常运行
- 🟡 **连接但不健康** - 减少ping间隔，监控状态
- 🔄 **重连中** - 显示重连进度
- ❌ **连接失败** - 显示错误信息

### 错误类型
- 🌐 **网络错误** - DNS解析失败，使用长延迟重连
- 🔐 **认证错误** - 登出状态，停止重连
- ⚡ **连接超时** - 强制重连
- 🔌 **连接断开** - 正常重连

## 使用建议

### 对用户
1. **网络切换时** - 应用会自动检测并重连
2. **连接问题时** - 查看连接状态，必要时手动重连
3. **长时间离线** - 重新打开应用会自动连接

### 对开发者
1. **监控连接状态** - 使用`getConnectionInfo()`获取详细信息
2. **手动重连** - 调用`reconnect()`方法
3. **资源清理** - 确保调用`dispose()`方法

## 测试验证

### 测试场景
1. **网络切换测试** - WiFi ↔ 移动网络
2. **DNS解析失败测试** - 模拟DNS问题
3. **服务器不可用测试** - 模拟服务器宕机
4. **长时间运行测试** - 检查连接稳定性
5. **频繁重连测试** - 验证重连逻辑

### 预期结果
- ✅ DNS错误时使用指数退避重连
- ✅ 网络切换后自动重连
- ✅ 连接健康状况实时监控
- ✅ 资源使用优化，避免过度重连
- ✅ 错误日志清晰，便于调试

这套改进方案显著提高了WebSocket连接的稳定性和可靠性，有效解决了DNS解析失败等网络问题导致的连接中断。 