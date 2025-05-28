import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/websocket_manager.dart' as ws;
import '../providers/group_provider.dart';

class ConnectionStatusWidget extends StatefulWidget {
  final bool showDetailed;
  final bool showDeviceCount;
  
  const ConnectionStatusWidget({
    Key? key,
    this.showDetailed = false,
    this.showDeviceCount = false,
  }) : super(key: key);

  @override
  _ConnectionStatusWidgetState createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> 
    with SingleTickerProviderStateMixin {
  final ws.WebSocketManager _wsManager = ws.WebSocketManager();
  ws.ConnectionState _connectionState = ws.ConnectionState.disconnected;
  ws.NetworkStatus _networkStatus = ws.NetworkStatus.unknown;
  
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // 初始化动画
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // 获取初始状态
    _connectionState = _wsManager.connectionState;
    _networkStatus = _wsManager.networkStatus;
    
    // 监听状态变化
    _wsManager.onConnectionStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _connectionState = state;
        });
        _updateAnimation();
      }
    });
    
    _wsManager.onNetworkStatusChanged.listen((status) {
      if (mounted) {
        setState(() {
          _networkStatus = status;
        });
      }
    });
    
    _updateAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateAnimation() {
    switch (_connectionState) {
      case ws.ConnectionState.connecting:
      case ws.ConnectionState.reconnecting:
        _animationController.repeat(reverse: true);
        break;
      case ws.ConnectionState.connected:
        _animationController.stop();
        _animationController.value = 1.0;
        break;
      default:
        _animationController.stop();
        _animationController.value = 0.8;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showDetailed) {
      return _buildDetailedStatus();
    } else {
      return widget.showDeviceCount 
        ? _buildCompactWithDeviceCount() 
        : _buildCompactStatus();
    }
  }

  Widget _buildCompactWithDeviceCount() {
    final groupProvider = Provider.of<GroupProvider>(context);
    final onlineCount = groupProvider.onlineDevicesCount;
    final totalCount = groupProvider.totalDevicesCount;
    
    return GestureDetector(
      onTap: () async {
        // 调试功能：点击时强制刷新连接状态
        print('🔄 手动刷新连接状态...');
        try {
          if (!_wsManager.isConnected) {
            await _wsManager.reconnect();
          } else {
            _wsManager.emit('ping', {
              'test': true,
              'timestamp': DateTime.now().toIso8601String(),
            });
          }
        } catch (e) {
          print('❌ 刷新连接状态失败: $e');
        }
      },
      onLongPress: () {
        // 🔥 新增：长按显示调试菜单
        _showDebugMenu();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // WebSocket连接状态
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusColor().withOpacity(0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(width: 6),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: 8),
          
          // 设备在线数量
          GestureDetector(
            onTap: () {
              // 🔥 新增：点击设备数量时强制刷新设备状态
              _forceRefreshDeviceStatus();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: onlineCount > 0 
                  ? Colors.green.withOpacity(0.1) 
                  : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: onlineCount > 0 
                    ? Colors.green.withOpacity(0.3) 
                    : Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: onlineCount > 0 ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '$onlineCount/$totalCount在线',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: onlineCount > 0 ? Colors.green[700] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatus() {
    return GestureDetector(
      onTap: () async {
        // 调试功能：点击时强制刷新连接状态
        print('🔄 手动刷新连接状态...');
        try {
          if (!_wsManager.isConnected) {
            // 如果未连接，尝试重连
            await _wsManager.reconnect();
          } else {
            // 如果已连接，发送测试消息
            _wsManager.emit('ping', {
              'test': true,
              'timestamp': DateTime.now().toIso8601String(),
            });
          }
        } catch (e) {
          print('❌ 刷新连接状态失败: $e');
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getStatusColor().withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                      boxShadow: _connectionState == ws.ConnectionState.connected 
                        ? [
                            BoxShadow(
                              color: _getStatusColor().withOpacity(0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                    ),
                  ),
                );
              },
            ),
            SizedBox(width: 6),
            Text(
              _getStatusText(),
              style: TextStyle(
                color: _getStatusColor(),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStatus() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 连接状态
          Row(
            children: [
              Icon(
                _getStatusIcon(),
                color: _getStatusColor(),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '连接状态',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          
          // 网络状态
          Row(
            children: [
              Icon(
                _getNetworkIcon(),
                color: _getNetworkColor(),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '网络状态',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getNetworkColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getNetworkText(),
                  style: TextStyle(
                    color: _getNetworkColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          // 连接信息
          if (_connectionState != ws.ConnectionState.disconnected) ...[
            SizedBox(height: 8),
            Divider(height: 1),
            SizedBox(height: 8),
            _buildConnectionInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionInfo() {
    final info = _wsManager.getConnectionInfo();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '连接详情',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        if (info['reconnectAttempts'] > 0)
          _buildInfoRow('重连次数', '${info['reconnectAttempts']}/${info['maxReconnectAttempts']}'),
        if (info['lastSuccessfulConnection'] != null)
          _buildInfoRow('最后连接', _formatTime(info['lastSuccessfulConnection'])),
        if (info['socketId'] != null)
          _buildInfoRow('Socket ID', info['socketId'].toString().substring(0, 8) + '...'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '未知';
    try {
      final time = DateTime.parse(timeStr);
      final now = DateTime.now();
      final diff = now.difference(time);
      
      if (diff.inMinutes < 1) {
        return '刚刚';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}分钟前';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}小时前';
      } else {
        return '${diff.inDays}天前';
      }
    } catch (e) {
      return '未知';
    }
  }

  Color _getStatusColor() {
    switch (_connectionState) {
      case ws.ConnectionState.connected:
        return Colors.green;
      case ws.ConnectionState.connecting:
      case ws.ConnectionState.reconnecting:
        return Colors.orange;
      case ws.ConnectionState.failed:
        return Colors.red;
      case ws.ConnectionState.disconnected:
        return Colors.grey;
    }
  }

  Color _getNetworkColor() {
    switch (_networkStatus) {
      case ws.NetworkStatus.available:
        return Colors.green;
      case ws.NetworkStatus.limited:
        return Colors.orange;
      case ws.NetworkStatus.unavailable:
        return Colors.red;
      case ws.NetworkStatus.unknown:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_connectionState) {
      case ws.ConnectionState.connected:
        return Icons.wifi;
      case ws.ConnectionState.connecting:
      case ws.ConnectionState.reconnecting:
        return Icons.wifi_find;
      case ws.ConnectionState.failed:
        return Icons.wifi_off;
      case ws.ConnectionState.disconnected:
        return Icons.wifi_off_outlined;
    }
  }

  IconData _getNetworkIcon() {
    switch (_networkStatus) {
      case ws.NetworkStatus.available:
        return Icons.signal_wifi_4_bar;
      case ws.NetworkStatus.limited:
        return Icons.network_wifi;
      case ws.NetworkStatus.unavailable:
        return Icons.signal_wifi_off;
      case ws.NetworkStatus.unknown:
        return Icons.wifi_find;
    }
  }

  String _getStatusText() {
    switch (_connectionState) {
      case ws.ConnectionState.connected:
        return '已连接';
      case ws.ConnectionState.connecting:
        return '连接中';
      case ws.ConnectionState.reconnecting:
        return '重连中';
      case ws.ConnectionState.failed:
        return '连接失败';
      case ws.ConnectionState.disconnected:
        return '未连接';
    }
  }

  String _getNetworkText() {
    switch (_networkStatus) {
      case ws.NetworkStatus.available:
        return '网络正常';
      case ws.NetworkStatus.limited:
        return '网络受限';
      case ws.NetworkStatus.unavailable:
        return '网络不可用';
      case ws.NetworkStatus.unknown:
        return '检查中';
    }
  }

  // 🔥 新增：显示调试菜单
  void _showDebugMenu() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('🔧 连接调试菜单'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.refresh, color: Colors.blue),
                title: Text('强制重连WebSocket'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _forceReconnect();
                },
              ),
              ListTile(
                leading: Icon(Icons.sync, color: Colors.green),
                title: Text('同步设备状态'),
                onTap: () {
                  Navigator.of(context).pop();
                  _forceRefreshDeviceStatus();
                },
              ),
              ListTile(
                leading: Icon(Icons.message, color: Colors.orange),
                title: Text('同步消息'),
                onTap: () {
                  Navigator.of(context).pop();
                  _forceSyncMessages();
                },
              ),
              ListTile(
                leading: Icon(Icons.network_check, color: Colors.purple),
                title: Text('网络诊断'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openNetworkDiagnostics();
                },
              ),
              ListTile(
                leading: Icon(Icons.speed, color: Colors.red),
                title: Text('连接测试'),
                onTap: () {
                  Navigator.of(context).pop();
                  _performConnectionTest();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('关闭'),
            ),
          ],
        );
      },
    );
  }
  
  // 🔥 新增：强制重连
  Future<void> _forceReconnect() async {
    print('🔄 强制重连WebSocket...');
    try {
      _wsManager.disconnect();
      await Future.delayed(Duration(seconds: 1));
      await _wsManager.reconnect();
      print('✅ 强制重连完成');
    } catch (e) {
      print('❌ 强制重连失败: $e');
    }
  }
  
  // 🔥 新增：强制刷新设备状态
  void _forceRefreshDeviceStatus() {
    print('🔄 强制刷新设备状态...');
    if (_wsManager.isConnected) {
      _wsManager.emit('request_group_devices_status', {
        'timestamp': DateTime.now().toIso8601String(),
        'reason': 'manual_refresh'
      });
      _wsManager.emit('get_online_devices', {
        'timestamp': DateTime.now().toIso8601String(),
        'reason': 'manual_refresh'
      });
      print('✅ 设备状态刷新请求已发送');
    } else {
      print('❌ WebSocket未连接，无法刷新设备状态');
    }
  }
  
  // 🔥 新增：强制同步消息
  void _forceSyncMessages() {
    print('🔄 强制同步消息...');
    if (_wsManager.isConnected) {
      _wsManager.emit('sync_messages', {
        'timestamp': DateTime.now().toIso8601String(),
        'reason': 'manual_sync'
      });
      print('✅ 消息同步请求已发送');
    } else {
      print('❌ WebSocket未连接，无法同步消息');
    }
  }
  
  // 🔥 新增：打开网络诊断
  void _openNetworkDiagnostics() {
    Navigator.of(context).pushNamed('/network-debug');
  }

  // 🔥 新增：连接测试
  void _performConnectionTest() {
    print('🧪 连接测试...');
    _showConnectionTestDialog();
  }
  
  // 显示连接测试对话框
  void _showConnectionTestDialog() async {
    final results = <String>[];
    
    // 显示测试进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('🧪 连接测试'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在测试WebSocket连接...'),
            ],
          ),
        );
      },
    );
    
    try {
      // 测试1：检查连接状态
      results.add('🔌 WebSocket状态: ${_wsManager.isConnected ? "已连接" : "未连接"}');
      
      // 测试2：发送测试消息
      if (_wsManager.isConnected) {
        results.add('📤 发送测试消息...');
        _wsManager.emit('connection_test', {
          'timestamp': DateTime.now().toIso8601String(),
          'test_id': DateTime.now().millisecondsSinceEpoch,
        });
        
        // 等待2秒
        await Future.delayed(Duration(seconds: 2));
        results.add('✅ 测试消息已发送');
      } else {
        results.add('❌ 无法发送测试消息：连接断开');
      }
      
      // 测试3：检查最后收到消息的时间
      final info = _wsManager.getConnectionInfo();
      final lastMessage = info['lastMessageReceived'];
      if (lastMessage != null) {
        try {
          final lastTime = DateTime.parse(lastMessage);
          final timeDiff = DateTime.now().difference(lastTime);
          results.add('📬 最后收到消息: ${timeDiff.inMinutes}分钟前');
          
          if (timeDiff.inMinutes > 5) {
            results.add('⚠️ 警告：超过5分钟未收到消息');
          } else {
            results.add('✅ 消息接收正常');
          }
        } catch (e) {
          results.add('❌ 解析时间失败: $e');
        }
      } else {
        results.add('❌ 未收到任何消息');
      }
      
      // 测试4：强制状态同步
      results.add('🔄 触发状态同步...');
      _forceRefreshDeviceStatus();
      _forceSyncMessages();
      results.add('✅ 状态同步请求已发送');
      
    } catch (e) {
      results.add('❌ 测试失败: $e');
    }
    
    // 关闭进度对话框
    Navigator.of(context).pop();
    
    // 显示测试结果
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('🧪 连接测试结果'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: results.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    results[index],
                    style: TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('关闭'),
            ),
          ],
        );
      },
    );
  }
} 