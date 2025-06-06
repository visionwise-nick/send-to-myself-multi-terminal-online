import 'dart:async';
import 'package:flutter/foundation.dart';
import 'enhanced_sync_manager.dart';

/// 群组切换同步服务
/// 监听群组切换事件并自动触发相应的消息同步
class GroupSwitchSyncService {
  static final GroupSwitchSyncService _instance = GroupSwitchSyncService._internal();
  factory GroupSwitchSyncService() => _instance;
  GroupSwitchSyncService._internal();

  final EnhancedSyncManager _enhancedSyncManager = EnhancedSyncManager();
  
  String? _currentGroupId;
  String? _previousGroupId;
  Timer? _syncDebounceTimer;
  final Map<String, DateTime> _lastSyncTimes = {};
  final Duration _syncCooldown = const Duration(seconds: 30); // 防止频繁同步
  
  // 流控制器
  final StreamController<GroupSwitchEvent> _groupSwitchController = 
      StreamController<GroupSwitchEvent>.broadcast();
  
  Stream<GroupSwitchEvent> get onGroupSwitch => _groupSwitchController.stream;

  /// 通知群组切换
  Future<void> notifyGroupSwitch(String groupId) async {
    debugPrint('🔄 群组切换通知: $groupId');
    
    // 记录切换事件
    _previousGroupId = _currentGroupId;
    _currentGroupId = groupId;
    
    // 发送群组切换事件
    _groupSwitchController.add(GroupSwitchEvent(
      newGroupId: groupId,
      previousGroupId: _previousGroupId,
      timestamp: DateTime.now(),
    ));
    
    // 检查是否需要同步
    if (_shouldTriggerSync(groupId)) {
      _scheduleGroupSync(groupId);
    }
  }

  /// 检查是否应该触发同步
  bool _shouldTriggerSync(String groupId) {
    // 检查冷却时间
    final lastSyncTime = _lastSyncTimes[groupId];
    if (lastSyncTime != null) {
      final timeSinceLastSync = DateTime.now().difference(lastSyncTime);
      if (timeSinceLastSync < _syncCooldown) {
        debugPrint('⏸️ 群组 $groupId 同步冷却中，跳过同步');
        return false;
      }
    }
    
    return true;
  }

  /// 调度群组同步（防抖动）
  void _scheduleGroupSync(String groupId) {
    // 取消之前的定时器
    _syncDebounceTimer?.cancel();
    
    // 设置新的防抖定时器
    _syncDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performGroupSync(groupId);
    });
  }

  /// 执行群组同步
  Future<void> _performGroupSync(String groupId) async {
    try {
      debugPrint('🔄 开始群组切换同步: $groupId');
      
      // 记录同步时间
      _lastSyncTimes[groupId] = DateTime.now();
      
      // 执行增强的群组切换同步
      final result = await _enhancedSyncManager.performGroupSwitchSync(groupId);
      
      if (result.success) {
        debugPrint('✅ 群组切换同步完成: ${result.totalFetched} 条消息');
        
        // 发送同步完成事件
        _groupSwitchController.add(GroupSwitchEvent(
          newGroupId: groupId,
          previousGroupId: _previousGroupId,
          timestamp: DateTime.now(),
          syncResult: result,
        ));
      } else {
        debugPrint('❌ 群组切换同步失败: ${result.error}');
      }
    } catch (e) {
      debugPrint('❌ 群组切换同步出错: $e');
    }
  }

  /// 强制同步指定群组
  Future<EnhancedSyncResult> forceSyncGroup(String groupId) async {
    debugPrint('🔄 强制同步群组: $groupId');
    
    // 清除冷却时间限制
    _lastSyncTimes.remove(groupId);
    
    // 执行同步
    return await _enhancedSyncManager.performGroupSwitchSync(groupId);
  }

  /// 预加载群组消息（在用户可能切换之前）
  Future<void> preloadGroupMessages(List<String> groupIds) async {
    debugPrint('📋 预加载群组消息: ${groupIds.length} 个群组');
    
    for (final groupId in groupIds) {
      try {
        // 检查是否需要预加载
        final lastSyncTime = _lastSyncTimes[groupId];
        final shouldPreload = lastSyncTime == null || 
            DateTime.now().difference(lastSyncTime) > const Duration(minutes: 15);
        
        if (shouldPreload) {
          debugPrint('📥 预加载群组: $groupId');
          await _enhancedSyncManager.performGroupSwitchSync(groupId);
          
          // 添加小延迟避免过快请求
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } catch (e) {
        debugPrint('⚠️ 预加载群组 $groupId 失败: $e');
      }
    }
  }

  /// 获取当前群组ID
  String? get currentGroupId => _currentGroupId;

  /// 获取上一个群组ID
  String? get previousGroupId => _previousGroupId;

  /// 获取群组最后同步时间
  DateTime? getLastSyncTime(String groupId) {
    return _lastSyncTimes[groupId];
  }

  /// 清理过期的同步记录
  void cleanupSyncHistory() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _lastSyncTimes.forEach((groupId, syncTime) {
      if (now.difference(syncTime) > const Duration(hours: 24)) {
        expiredKeys.add(groupId);
      }
    });
    
    for (final key in expiredKeys) {
      _lastSyncTimes.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      debugPrint('🧹 清理了 ${expiredKeys.length} 个过期的群组同步记录');
    }
  }

  /// 销毁服务
  void dispose() {
    _syncDebounceTimer?.cancel();
    _groupSwitchController.close();
  }
}

/// 群组切换事件
class GroupSwitchEvent {
  final String newGroupId;
  final String? previousGroupId;
  final DateTime timestamp;
  final EnhancedSyncResult? syncResult;

  GroupSwitchEvent({
    required this.newGroupId,
    this.previousGroupId,
    required this.timestamp,
    this.syncResult,
  });

  bool get hasSyncResult => syncResult != null;
  bool get syncSuccess => syncResult?.success ?? false;
  
  @override
  String toString() {
    return 'GroupSwitchEvent(new: $newGroupId, previous: $previousGroupId, sync: ${syncSuccess ? "success" : "none"})';
  }
} 