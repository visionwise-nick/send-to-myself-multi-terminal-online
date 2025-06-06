import 'package:flutter/foundation.dart';
import 'offline_sync_service.dart';
import 'local_storage_service.dart';

/// 同步管理器
/// 负责协调离线同步服务和本地存储，提供完整的离线消息同步功能
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final OfflineSyncService _offlineSyncService = OfflineSyncService();
  final LocalStorageService _localStorage = LocalStorageService();
  
  bool _isSyncing = false;
  
  /// 检查是否正在同步
  bool get isSyncing => _isSyncing;

  /// 应用启动时执行完整的离线同步
  /// 这是主要的集成入口点
  Future<SyncResult> performAppStartupSync() async {
    if (_isSyncing) {
      debugPrint('同步已在进行中，跳过重复同步');
      return SyncResult.skip('同步已在进行中');
    }

    _isSyncing = true;
    debugPrint('开始应用启动离线同步...');
    
    try {
      // 1. 执行基础的离线消息同步
      final startupResult = await _offlineSyncService.performStartupSync();
      
      if (!startupResult.success) {
        return SyncResult.error(startupResult.error ?? '启动同步失败');
      }
      
      final offlineMessages = startupResult.offlineMessages;
      if (offlineMessages == null) {
        return SyncResult.error('未获取到离线消息结果');
      }
      
      // 2. 处理同步到的消息
      int processedCount = 0;
      if (offlineMessages.messages.isNotEmpty) {
        processedCount = await _processOfflineMessages(offlineMessages.messages);
      }
      
      debugPrint('应用启动同步完成: 获取${offlineMessages.messages.length}条，处理${processedCount}条消息');
      
      return SyncResult.success(
        totalFetched: offlineMessages.messages.length,
        totalProcessed: processedCount,
        syncedAt: startupResult.syncedAt,
      );
      
    } catch (e) {
      debugPrint('应用启动同步失败: $e');
      return SyncResult.error(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// 同步特定群组的历史消息
  Future<SyncResult> syncGroupHistory({
    required String groupId,
    DateTime? fromTime,
    int limit = 50,
    bool saveToLocal = true,
  }) async {
    try {
      debugPrint('开始同步群组 $groupId 的历史消息...');
      
      final result = await _offlineSyncService.syncGroupHistory(
        groupId: groupId,
        fromTime: fromTime,
        limit: limit,
      );
      
      int processedCount = 0;
      if (saveToLocal && result.messages.isNotEmpty) {
        // 保存群组消息到本地存储
        final existingMessages = await _localStorage.loadChatMessages('group_$groupId');
        final allMessages = _mergeMessages(existingMessages, result.messages);
        await _localStorage.saveChatMessages('group_$groupId', allMessages);
        processedCount = result.messages.length;
      }
      
      debugPrint('群组历史同步完成: $groupId, ${result.messages.length}条消息');
      
      return SyncResult.success(
        totalFetched: result.messages.length,
        totalProcessed: processedCount,
        syncedAt: result.syncInfo.syncedAt,
        groupId: groupId,
      );
      
    } catch (e) {
      debugPrint('群组历史同步失败: $groupId, $e');
      return SyncResult.error(e.toString(), groupId: groupId);
    }
  }

  /// 同步多个群组的历史消息
  Future<Map<String, SyncResult>> syncMultipleGroupsHistory({
    required List<String> groupIds,
    DateTime? fromTime,
    int limitPerGroup = 50,
  }) async {
    final results = <String, SyncResult>{};
    
    debugPrint('开始批量同步 ${groupIds.length} 个群组的历史消息...');
    
    // 并发同步多个群组
    final futures = groupIds.map((groupId) async {
      final result = await syncGroupHistory(
        groupId: groupId,
        fromTime: fromTime,
        limit: limitPerGroup,
      );
      return MapEntry(groupId, result);
    });
    
    final completed = await Future.wait(futures);
    
    for (final entry in completed) {
      results[entry.key] = entry.value;
    }
    
    final successCount = results.values.where((r) => r.success).length;
    debugPrint('批量群组同步完成: 成功 $successCount/${groupIds.length} 个群组');
    
    return results;
  }

  /// 增量同步（应用从后台恢复时使用）
  Future<SyncResult> performIncrementalSync() async {
    try {
      final lastOnlineTime = await _offlineSyncService.getLastOnlineTime();
      if (lastOnlineTime == null) {
        // 如果没有记录，执行完整启动同步
        return await performAppStartupSync();
      }
      
      // 只同步从上次在线时间到现在的消息
      final result = await _offlineSyncService.syncOfflineMessages(
        fromTime: lastOnlineTime,
        limit: 100,
      );
      
      int processedCount = 0;
      if (result.messages.isNotEmpty) {
        processedCount = await _processOfflineMessages(result.messages);
      }
      
      // 更新最后在线时间
      await _offlineSyncService.saveLastOnlineTime();
      
      debugPrint('增量同步完成: ${result.messages.length}条新消息');
      
      return SyncResult.success(
        totalFetched: result.messages.length,
        totalProcessed: processedCount,
        syncedAt: result.syncInfo.syncedAt,
      );
      
    } catch (e) {
      debugPrint('增量同步失败: $e');
      return SyncResult.error(e.toString());
    }
  }

  /// 处理离线消息列表
  Future<int> _processOfflineMessages(List<Map<String, dynamic>> messages) async {
    int processedCount = 0;
    
    // 按对话分组消息
    final Map<String, List<Map<String, dynamic>>> conversationMessages = {};
    
    for (final message in messages) {
      String conversationId;
      
      // 判断消息类型并生成对话ID
      if (message['type'] == 'group') {
        conversationId = 'group_${message['groupId']}';
      } else {
        // 1v1消息
        final senderId = message['senderId'];
        final recipientId = message['recipientId'];
        // 生成一致的对话ID（按字典序排列）
        final ids = [senderId, recipientId]..sort();
        conversationId = 'private_${ids[0]}_${ids[1]}';
      }
      
      conversationMessages.putIfAbsent(conversationId, () => []).add(message);
    }
    
    // 为每个对话保存消息
    for (final entry in conversationMessages.entries) {
      try {
        final conversationId = entry.key;
        final newMessages = entry.value;
        
        // 加载现有消息
        final existingMessages = await _localStorage.loadChatMessages(conversationId);
        
        // 合并消息（去重并排序）
        final allMessages = _mergeMessages(existingMessages, newMessages);
        
        // 保存合并后的消息
        await _localStorage.saveChatMessages(conversationId, allMessages);
        
        processedCount += newMessages.length;
        debugPrint('处理对话 $conversationId: ${newMessages.length} 条新消息');
        
      } catch (e) {
        debugPrint('处理对话消息失败: ${entry.key}, $e');
      }
    }
    
    return processedCount;
  }

  /// 合并消息列表（去重并按时间排序）
  List<Map<String, dynamic>> _mergeMessages(
    List<Map<String, dynamic>> existingMessages,
    List<Map<String, dynamic>> newMessages,
  ) {
    // 创建消息ID到消息的映射，用于去重
    final Map<String, Map<String, dynamic>> messageMap = {};
    
    // 添加现有消息
    for (final message in existingMessages) {
      final id = message['id'];
      if (id != null) {
        messageMap[id] = message;
      }
    }
    
    // 添加新消息（会覆盖相同ID的旧消息）
    for (final message in newMessages) {
      final id = message['id'];
      if (id != null) {
        messageMap[id] = message;
      }
    }
    
    // 转换为列表并按时间排序
    final allMessages = messageMap.values.toList();
    allMessages.sort((a, b) {
      final timeA = DateTime.tryParse(a['timestamp'] ?? '');
      final timeB = DateTime.tryParse(b['timestamp'] ?? '');
      if (timeA == null || timeB == null) return 0;
      return timeA.compareTo(timeB);
    });
    
    return allMessages;
  }

  /// 清理旧的同步数据（可选的维护功能）
  Future<void> cleanupOldSyncData({Duration maxAge = const Duration(days: 30)}) async {
    try {
      debugPrint('开始清理超过 ${maxAge.inDays} 天的旧同步数据...');
      
      // 这里可以实现清理逻辑，比如删除过旧的消息
      // 具体实现取决于应用的需求
      
      debugPrint('同步数据清理完成');
    } catch (e) {
      debugPrint('清理同步数据失败: $e');
    }
  }

  /// 获取同步状态信息
  Future<SyncStatus> getSyncStatus() async {
    final lastOnlineTime = await _offlineSyncService.getLastOnlineTime();
    
    return SyncStatus(
      isSyncing: _isSyncing,
      lastOnlineTime: lastOnlineTime,
      lastSyncTime: lastOnlineTime, // 可以单独维护最后同步时间
    );
  }

  /// 手动保存在线时间（应用生命周期管理）
  Future<void> markAsOnline() async {
    await _offlineSyncService.saveLastOnlineTime();
  }

  /// 应用生命周期集成助手
  AppLifecycleIntegration get lifecycleIntegration => AppLifecycleIntegration(this);
}

/// 同步结果
class SyncResult {
  final bool success;
  final String? error;
  final int totalFetched;
  final int totalProcessed;
  final DateTime? syncedAt;
  final String? groupId;

  SyncResult._({
    required this.success,
    this.error,
    this.totalFetched = 0,
    this.totalProcessed = 0,
    this.syncedAt,
    this.groupId,
  });

  factory SyncResult.success({
    required int totalFetched,
    required int totalProcessed,
    required DateTime syncedAt,
    String? groupId,
  }) {
    return SyncResult._(
      success: true,
      totalFetched: totalFetched,
      totalProcessed: totalProcessed,
      syncedAt: syncedAt,
      groupId: groupId,
    );
  }

  factory SyncResult.error(String error, {String? groupId}) {
    return SyncResult._(
      success: false,
      error: error,
      groupId: groupId,
    );
  }

  factory SyncResult.skip(String reason) {
    return SyncResult._(
      success: true,
      error: reason,
    );
  }
}

/// 同步状态
class SyncStatus {
  final bool isSyncing;
  final DateTime? lastOnlineTime;
  final DateTime? lastSyncTime;

  SyncStatus({
    required this.isSyncing,
    this.lastOnlineTime,
    this.lastSyncTime,
  });
}

/// 应用生命周期集成助手
class AppLifecycleIntegration {
  final SyncManager _syncManager;

  AppLifecycleIntegration(this._syncManager);

  /// 应用启动时调用
  Future<SyncResult> onAppStartup() async {
    debugPrint('应用启动 - 开始离线消息同步');
    return await _syncManager.performAppStartupSync();
  }

  /// 应用从后台恢复时调用
  Future<SyncResult> onAppResumed() async {
    debugPrint('应用恢复 - 开始增量消息同步');
    return await _syncManager.performIncrementalSync();
  }

  /// 应用进入后台时调用
  Future<void> onAppPaused() async {
    debugPrint('应用进入后台 - 保存在线时间');
    await _syncManager.markAsOnline();
  }

  /// 应用即将终止时调用
  Future<void> onAppDetached() async {
    debugPrint('应用终止 - 保存在线时间');
    await _syncManager.markAsOnline();
  }
} 