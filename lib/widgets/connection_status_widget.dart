import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/websocket_manager.dart' as ws;
import '../services/status_refresh_manager.dart';
import '../providers/group_provider.dart';
import '../utils/localization_helper.dart';
import 'dart:async';
import '../config/debug_config.dart';

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
  final StatusRefreshManager _statusRefreshManager = StatusRefreshManager();
  ws.ConnectionState _connectionState = ws.ConnectionState.disconnected;
  ws.NetworkStatus _networkStatus = ws.NetworkStatus.unknown;
  
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  // 🔥 优化：移除定时器相关变量，改为事件驱动
  DateTime? _lastRefreshTime;
  bool _isRefreshing = false;
  static const Duration _throttleInterval = Duration(seconds: 30); // 节流间隔缩短为30秒
  
  // 🔥 保留必要的变量以避免编译错误
  int _refreshRequestCount = 0;
  static const int _maxRefreshPerHour = 12;
  Timer? _statusRefreshTimer;
  static const Duration _refreshInterval = Duration(minutes: 5);

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
    
    // 🔥 优化：移除定时器，使用事件驱动的状态刷新管理器
    // 无需手动启动定时器，状态刷新管理器会在需要时自动触发
  }

  @override
  void dispose() {
    _animationController.dispose();
    // 🔥 优化：无需清理定时器
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
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
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
          
          SizedBox(width: 6),
          
          // 设备总数量 - 移动端显示"m台设备"，桌面端隐藏
          if (_isMobile()) 
            GestureDetector(
              onTap: () {
                // 🔥 修改：点击设备数量时强制刷新设备状态并进行诊断
                print('🔄 用户点击设备数量，触发状态刷新和诊断...');
                
                // 1. 触发诊断
                final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                groupProvider.diagnosisDeviceStatus();
                
                // 2. 强制刷新设备状态
      _manualRefreshDeviceStatus();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: totalCount > 0 
                    ? Colors.blue.withOpacity(0.1) 
                    : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: totalCount > 0 
                      ? Colors.blue.withOpacity(0.3) 
                      : Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.devices,
                      size: 10,
                      color: totalCount > 0 ? Colors.blue[700] : Colors.grey[600],
                    ),
                    SizedBox(width: 4),
                    Text(
                      LocalizationHelper.of(context).deviceCount(totalCount),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: totalCount > 0 ? Colors.blue[700] : Colors.grey[600],
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
        return LocalizationHelper.of(context).connected;
      case ws.ConnectionState.connecting:
        return LocalizationHelper.of(context).connecting;
      case ws.ConnectionState.reconnecting:
        return LocalizationHelper.of(context).reconnecting;
      case ws.ConnectionState.failed:
        return LocalizationHelper.of(context).connectionFailed;
      case ws.ConnectionState.disconnected:
        return LocalizationHelper.of(context).disconnected;
    }
  }

  String _getNetworkText() {
    switch (_networkStatus) {
      case ws.NetworkStatus.available:
        return LocalizationHelper.of(context).networkNormal;
      case ws.NetworkStatus.limited:
        return LocalizationHelper.of(context).networkLimited;
      case ws.NetworkStatus.unavailable:
        return LocalizationHelper.of(context).networkUnavailable;
      case ws.NetworkStatus.unknown:
        return LocalizationHelper.of(context).checking;
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
  
  // 🔥 优化：智能设备状态刷新 - 实现节流机制
  void _forceRefreshDeviceStatus() {
    final now = DateTime.now();
    
    // 检查是否正在刷新
    if (_isRefreshing) {
      DebugConfig.debugPrint('设备状态刷新正在进行中，跳过重复请求', module: 'SYNC');
      return;
    }
    
    // 检查节流间隔
    if (_lastRefreshTime != null) {
      final timeSinceLastRefresh = now.difference(_lastRefreshTime!);
      if (timeSinceLastRefresh < _throttleInterval) {
        DebugConfig.debugPrint('设备状态刷新请求过于频繁，跳过 (距离上次 ${timeSinceLastRefresh.inSeconds}秒)', module: 'SYNC');
        return;
      }
    }
    
    // 检查每小时限制
    _refreshRequestCount++;
    if (_refreshRequestCount > _maxRefreshPerHour) {
      DebugConfig.debugPrint('已达到每小时刷新限制 ($_maxRefreshPerHour)，跳过请求', module: 'SYNC');
      return;
    }
    
    if (!_wsManager.isConnected) {
      DebugConfig.debugPrint('WebSocket未连接，无法刷新设备状态', module: 'SYNC');
      return;
    }
    
    _isRefreshing = true;
    _lastRefreshTime = now;
    
    DebugConfig.debugPrint('执行设备状态刷新 (节流保护)', module: 'SYNC');
    
    try {
      // 🔥 优化：只发送一个合并的请求，而不是4个独立请求
      _wsManager.emit('batch_device_status_request', {
        'requests': [
          'group_devices_status',
          'online_devices',
          'device_status',
          'activity_update'
        ],
        'timestamp': DateTime.now().toIso8601String(),
        'reason': 'optimized_refresh',
        'throttled': true
      });
      
      DebugConfig.debugPrint('设备状态批量刷新请求已发送', module: 'SYNC');
      
      // 如果服务器不支持批量请求，降级为原有方式但加延迟
      Future.delayed(Duration(milliseconds: 500), () {
        if (_wsManager.isConnected) {
          _wsManager.emit('request_group_devices_status', {
        'timestamp': DateTime.now().toIso8601String(),
            'reason': 'fallback_refresh'
          });
        }
      });
      
    } catch (e) {
      DebugConfig.errorPrint('设备状态刷新失败: $e');
    } finally {
      // 1秒后解除刷新锁定
      Future.delayed(Duration(seconds: 1), () {
        _isRefreshing = false;
      });
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
      _manualRefreshDeviceStatus();
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

  // 🔥 优化：大幅延长状态刷新间隔，减少服务器压力
  void _startStatusRefreshTimer() {
    _statusRefreshTimer?.cancel();
    
    // 🔥 优化：从3秒改为5分钟，减少99%的请求
    _statusRefreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (_wsManager.isConnected) {
        _forceRefreshDeviceStatus();
      }
    });
    
    DebugConfig.debugPrint('状态刷新定时器已启动 (间隔: ${_refreshInterval.inMinutes}分钟)', module: 'SYNC');
    
    // 🔥 新增：重置每小时计数器
    Timer.periodic(Duration(hours: 1), (timer) {
      _refreshRequestCount = 0;
      DebugConfig.debugPrint('重置每小时刷新计数器', module: 'SYNC');
    });
  }

  // 🔥 新增：仅在必要时手动刷新
  void _manualRefreshDeviceStatus() {
    DebugConfig.debugPrint('用户手动触发设备状态刷新', module: 'SYNC');
    
    // 手动刷新可以绕过部分节流限制，但仍有基本保护
    final now = DateTime.now();
    if (_lastRefreshTime != null) {
      final timeSinceLastRefresh = now.difference(_lastRefreshTime!);
      if (timeSinceLastRefresh < Duration(seconds: 30)) {
        DebugConfig.debugPrint('手动刷新过于频繁，请等待30秒', module: 'SYNC');
        return;
      }
    }
    
    // 临时绕过节流限制进行手动刷新
    final originalLastRefresh = _lastRefreshTime;
    _lastRefreshTime = null;
    _forceRefreshDeviceStatus();
    _lastRefreshTime = originalLastRefresh; // 恢复原来的时间
  }

  // 判断是否为移动端
  bool _isMobile() {
    if (kIsWeb) {
      return MediaQuery.of(context).size.width < 800;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
           defaultTargetPlatform == TargetPlatform.iOS;
  }
} 