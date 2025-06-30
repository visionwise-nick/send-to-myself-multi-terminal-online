import 'dart:async';
import 'package:flutter/widgets.dart';
import '../config/debug_config.dart';
import 'websocket_service.dart';
import 'websocket_manager.dart';

/// 状态刷新管理器 - 基于事件驱动，不使用定时器
/// 只在必要的应用状态变化时触发状态刷新
class StatusRefreshManager {
  static final StatusRefreshManager _instance = StatusRefreshManager._internal();
  factory StatusRefreshManager() => _instance;
  StatusRefreshManager._internal();

  // 事件流控制器
  final StreamController<StatusRefreshTrigger> _refreshTriggerController = 
      StreamController<StatusRefreshTrigger>.broadcast();

  // 最后刷新时间记录，防止频繁刷新
  DateTime? _lastRefreshTime;
  final Duration _minRefreshInterval = const Duration(seconds: 10); // 最小刷新间隔10秒

  /// 状态刷新触发器类型
  static const String TRIGGER_APP_RESUME = 'app_resume';
  static const String TRIGGER_LOGIN = 'login';
  static const String TRIGGER_LOGOUT = 'logout';
  static const String TRIGGER_WEBSOCKET_CONNECTED = 'websocket_connected';
  static const String TRIGGER_GROUP_CHANGED = 'group_changed';
  static const String TRIGGER_MANUAL_REFRESH = 'manual_refresh';
  static const String TRIGGER_APP_START = 'app_start';
  static const String TRIGGER_NETWORK_RESTORED = 'network_restored';

  /// 获取状态刷新事件流
  Stream<StatusRefreshTrigger> get onRefreshTriggered => _refreshTriggerController.stream;

  /// 初始化状态刷新管理器
  void initialize() {
    DebugConfig.debugPrint('初始化状态刷新管理器 - 事件驱动模式', module: 'STATUS');
    
    // 监听刷新事件并执行实际的状态刷新
    onRefreshTriggered.listen(_performStatusRefresh);
  }

  /// 触发状态刷新
  void triggerRefresh(String trigger, {String? reason, Map<String, dynamic>? data}) {
    // 检查刷新频率限制（手动刷新例外）
    if (trigger != TRIGGER_MANUAL_REFRESH && _isRefreshTooFrequent()) {
      DebugConfig.debugPrint('状态刷新过于频繁，跳过此次刷新: $trigger', module: 'STATUS');
      return;
    }

    DebugConfig.debugPrint('触发状态刷新: $trigger ${reason != null ? "($reason)" : ""}', module: 'STATUS');
    
    final refreshTrigger = StatusRefreshTrigger(
      trigger: trigger,
      reason: reason,
      data: data,
      timestamp: DateTime.now(),
    );

    _refreshTriggerController.add(refreshTrigger);
  }

  /// 检查是否刷新过于频繁
  bool _isRefreshTooFrequent() {
    if (_lastRefreshTime == null) return false;
    
    final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
    return timeSinceLastRefresh < _minRefreshInterval;
  }

  /// 执行实际的状态刷新
  void _performStatusRefresh(StatusRefreshTrigger trigger) async {
    try {
      DebugConfig.debugPrint('开始执行状态刷新: ${trigger.trigger}', module: 'STATUS');
      _lastRefreshTime = DateTime.now();

      // 刷新WebSocket状态
      await _refreshWebSocketStatus();
      
      // 刷新设备状态
      await _refreshDeviceStatus();

      DebugConfig.debugPrint('状态刷新完成: ${trigger.trigger}', module: 'STATUS');

    } catch (e) {
      DebugConfig.errorPrint('状态刷新失败: ${trigger.trigger} - $e');
    }
  }

  /// 刷新WebSocket连接状态
  Future<void> _refreshWebSocketStatus() async {
    try {
      final wsManager = WebSocketManager();
      final wsService = WebSocketService();

      // 检查连接状态
      if (!wsManager.isConnected && !wsService.isConnected) {
        DebugConfig.debugPrint('WebSocket未连接，尝试重连...', module: 'STATUS');
        
        // 尝试重连 WebSocketManager
        if (!wsManager.isConnected) {
          await wsManager.reconnect();
        }
        
        // 尝试重连 WebSocketService  
        if (!wsService.isConnected) {
          await wsService.reconnect();
        }
      }

    } catch (e) {
      DebugConfig.errorPrint('WebSocket状态刷新失败: $e');
    }
  }

  /// 刷新设备状态
  Future<void> _refreshDeviceStatus() async {
    try {
      final wsManager = WebSocketManager();
      final wsService = WebSocketService();

      // 通过WebSocketManager刷新设备状态
      if (wsManager.isConnected) {
        wsManager.emit('get_group_devices_status', {
          'timestamp': DateTime.now().toIso8601String(),
          'reason': 'status_refresh_manager'
        });
        DebugConfig.debugPrint('已发送设备状态请求(WebSocketManager)', module: 'STATUS');
      }

      // 通过WebSocketService刷新设备状态
      if (wsService.isConnected) {
        wsService.refreshDeviceStatus();
        DebugConfig.debugPrint('已发送设备状态请求(WebSocketService)', module: 'STATUS');
      }

    } catch (e) {
      DebugConfig.errorPrint('设备状态刷新失败: $e');
    }
  }

  /// 手动触发状态刷新（用于用户交互）
  void manualRefresh({String? reason}) {
    triggerRefresh(TRIGGER_MANUAL_REFRESH, reason: reason);
  }

  /// 应用启动时触发
  void onAppStart() {
    triggerRefresh(TRIGGER_APP_START, reason: '应用启动');
  }

  /// 应用从后台恢复时触发
  void onAppResume() {
    triggerRefresh(TRIGGER_APP_RESUME, reason: '从后台恢复');
  }

  /// 用户登录时触发
  void onLogin() {
    triggerRefresh(TRIGGER_LOGIN, reason: '用户登录');
  }

  /// 用户登出时触发
  void onLogout() {
    triggerRefresh(TRIGGER_LOGOUT, reason: '用户登出');
  }

  /// WebSocket连接建立时触发
  void onWebSocketConnected() {
    triggerRefresh(TRIGGER_WEBSOCKET_CONNECTED, reason: 'WebSocket连接建立');
  }

  /// 群组切换时触发
  void onGroupChanged(String? newGroupId) {
    triggerRefresh(TRIGGER_GROUP_CHANGED, 
      reason: '群组切换', 
      data: {'groupId': newGroupId}
    );
  }

  /// 网络恢复时触发
  void onNetworkRestored() {
    triggerRefresh(TRIGGER_NETWORK_RESTORED, reason: '网络连接恢复');
  }

  /// 释放资源
  void dispose() {
    _refreshTriggerController.close();
  }
}

/// 状态刷新触发器数据类
class StatusRefreshTrigger {
  final String trigger;
  final String? reason;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  StatusRefreshTrigger({
    required this.trigger,
    this.reason,
    this.data,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'StatusRefreshTrigger(trigger: $trigger, reason: $reason, data: $data, timestamp: $timestamp)';
  }
} 