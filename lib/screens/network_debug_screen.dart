import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import '../services/websocket_manager.dart' as ws;
import '../widgets/connection_status_widget.dart';
import '../config/app_config.dart';
import '../utils/localization_helper.dart';

class NetworkDebugScreen extends StatefulWidget {
  @override
  _NetworkDebugScreenState createState() => _NetworkDebugScreenState();
}

class _NetworkDebugScreenState extends State<NetworkDebugScreen> {
  final ws.WebSocketManager _wsManager = ws.WebSocketManager();
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  Timer? _pingTimer;
  
  bool _isRunningTests = false;
  Map<String, dynamic>? _connectionInfo;
  
  @override
  void initState() {
    super.initState();
    _startLogging();
    _updateConnectionInfo();
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }

  void _startLogging() {
    // 监听WebSocket状态变化
    _wsManager.onConnectionStateChanged.listen((state) {
      _addLog('🔄 ${LocalizationHelper.of(context).connectionStatusChanged}: $state');
      _updateConnectionInfo();
    });

    _wsManager.onNetworkStatusChanged.listen((status) {
      _addLog('📶 ${LocalizationHelper.of(context).networkStatusChanged}: $status');
    });

    _wsManager.onError.listen((error) {
      _addLog('❌ ${LocalizationHelper.of(context).errorOccurred}: $error');
    });

    _wsManager.onMessageReceived.listen((message) {
      _addLog('📩 ${LocalizationHelper.of(context).messageReceived}: ${message['type'] ?? 'unknown'}');
    });
  }

  void _addLog(String message) {
    if (mounted) {
      setState(() {
        _logs.add('${DateTime.now().toString().substring(11, 19)} $message');
        if (_logs.length > 100) {
          _logs.removeAt(0);
        }
      });
      
      // 自动滚动到底部
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _updateConnectionInfo() {
    setState(() {
      _connectionInfo = _wsManager.getConnectionInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationHelper.of(context).networkDiagnosticTool),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: _clearLogs,
            tooltip: LocalizationHelper.of(context).clearLogs,
          ),
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: _copyLogs,
            tooltip: LocalizationHelper.of(context).copyLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // 连接状态面板
          _buildStatusPanel(),
          
          // 操作按钮
          _buildActionButtons(),
          
          // 日志显示
          Expanded(
            child: _buildLogView(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPanel() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        children: [
          Text(
            LocalizationHelper.of(context).connectionStatus,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          
          // 详细连接状态组件
          ConnectionStatusWidget(showDetailed: true),
          
          if (_connectionInfo != null) ...[
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            _buildConnectionDetails(),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionDetails() {
    if (_connectionInfo == null) return SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationHelper.of(context).connectionDetails,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        
        ..._connectionInfo!.entries.map((entry) {
          String value = entry.value?.toString() ?? 'null';
          if (value.length > 50) {
            value = value.substring(0, 50) + '...';
          }
          
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    '${entry.key}:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ElevatedButton.icon(
            onPressed: _isRunningTests ? null : _runNetworkTests,
            icon: Icon(Icons.network_check),
            label: Text(LocalizationHelper.of(context).networkTest),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          
          ElevatedButton.icon(
            onPressed: _testWebSocketConnection,
            icon: Icon(Icons.wifi),
            label: Text(LocalizationHelper.of(context).testWebSocket),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          
          ElevatedButton.icon(
            onPressed: _forceReconnect,
            icon: Icon(Icons.refresh),
            label: Text(LocalizationHelper.of(context).forceReconnect),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
          
          ElevatedButton.icon(
            onPressed: _startPingTest,
            icon: Icon(Icons.timer),
            label: Text(LocalizationHelper.of(context).pingTest),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogView() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text(
                  LocalizationHelper.of(context).diagnosticLogs,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Text(
                  LocalizationHelper.of(context).recordsCount(_logs.length),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(8),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    log,
                    style: TextStyle(
                      color: _getLogColor(log),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('❌')) return Colors.red[300]!;
    if (log.contains('✅')) return Colors.green[300]!;
    if (log.contains('⚠️')) return Colors.orange[300]!;
    if (log.contains('🔄')) return Colors.blue[300]!;
    if (log.contains('📩')) return Colors.purple[300]!;
    if (log.contains('📶')) return Colors.cyan[300]!;
    return Colors.grey[300]!;
  }

  Future<void> _runNetworkTests() async {
    setState(() {
      _isRunningTests = true;
    });

    _addLog('🚀 ${LocalizationHelper.of(context).startingNetworkDiagnostic}');

    // 测试基本网络连接
    _addLog('🔍 ${LocalizationHelper.of(context).testingBasicConnectivity}');
    await _testBasicConnectivity();

    // 测试DNS解析
    _addLog('🔍 ${LocalizationHelper.of(context).testingDnsResolution}');
    await _testDnsResolution();

    // 测试服务器连通性
    _addLog('🔍 ${LocalizationHelper.of(context).testingServerConnectivity}');
    await _testServerConnectivity();

    setState(() {
      _isRunningTests = false;
    });

    _addLog('✅ ${LocalizationHelper.of(context).networkDiagnosticComplete}');
  }

  Future<void> _testBasicConnectivity() async {
    final testDomains = ['google.com', '8.8.8.8', 'cloudflare.com'];

    for (final domain in testDomains) {
      try {
        _addLog('🌐 ${LocalizationHelper.of(context).testingConnection}: $domain');
        final result = await InternetAddress.lookup(domain)
            .timeout(Duration(seconds: 5));

        if (result.isNotEmpty) {
          _addLog('✅ $domain ${LocalizationHelper.of(context).connectionSuccessful}: ${result.first.address}');
        } else {
          _addLog('❌ $domain ${LocalizationHelper.of(context).connectionFailed}: ${LocalizationHelper.of(context).noResult}');
        }
      } catch (e) {
        _addLog('❌ $domain ${LocalizationHelper.of(context).connectionFailed}: $e');
      }
    }
  }

  Future<void> _testDnsResolution() async {
    try {
      _addLog(LocalizationHelper.of(context).resolvingServerDomain);
      final result = await InternetAddress.lookup(
        'sendtomyself-api-adecumh2za-uc.a.run.app'
      ).timeout(Duration(seconds: 10));

      if (result.isNotEmpty) {
        _addLog(LocalizationHelper.of(context).serverDnsSuccess(result.first.address));
      } else {
        _addLog(LocalizationHelper.of(context).serverDnsFailed);
      }
    } catch (e) {
      _addLog(LocalizationHelper.of(context).serverDnsError(e.toString()));
    }
  }

  Future<void> _testServerConnectivity() async {
    try {
      _addLog(LocalizationHelper.of(context).testingServerConnection);
      final socket = await Socket.connect(
        'sendtomyself-api-adecumh2za-uc.a.run.app',
        443,
      ).timeout(Duration(seconds: 10));

      _addLog(LocalizationHelper.of(context).serverConnectionSuccess);
      socket.destroy();
    } catch (e) {
      _addLog(LocalizationHelper.of(context).serverConnectionFailed(e.toString()));
    }
  }

  void _testWebSocketConnection() async {
    _addLog('🧪 开始WebSocket连接测试...');
    
    // 获取当前连接状态
    final currentState = _wsManager.connectionState;
    _addLog('📊 当前连接状态: $currentState');
    
    if (currentState == ws.ConnectionState.connected) {
      _addLog('📡 发送测试ping...');
      _wsManager.emit('ping', {
        'test': true,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } else {
      _addLog('⚠️ WebSocket未连接，无法发送测试消息');
    }
  }

  void _forceReconnect() async {
    _addLog('🔄 执行强制重连...');
    await _wsManager.reconnect();
    _updateConnectionInfo();
  }

  void _startPingTest() {
    if (_pingTimer != null) {
      _pingTimer!.cancel();
      _pingTimer = null;
      _addLog('⏹️ 停止Ping测试');
      return;
    }

    _addLog('🏓 开始Ping测试 (每5秒)');
    _pingTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_wsManager.connectionState == ws.ConnectionState.connected) {
        _wsManager.emit('ping', {
          'test_ping': true,
          'timestamp': DateTime.now().toIso8601String(),
        });
        _addLog('🏓 发送测试ping');
      } else {
        _addLog('⚠️ 连接断开，暂停ping测试');
      }
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
    _addLog('🧹 日志已清除');
  }

  void _copyLogs() {
    final logsText = _logs.join('\n');
    Clipboard.setData(ClipboardData(text: logsText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('日志已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }
} 