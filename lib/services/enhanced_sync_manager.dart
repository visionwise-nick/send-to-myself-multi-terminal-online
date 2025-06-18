import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'offline_sync_service.dart';
import 'local_storage_service.dart';
import 'websocket_manager.dart';
import '../config/app_config.dart';

/// 增强的同步管理器
/// 重点优化后台恢复、群组切换、掉线重连和消息去重机制
class EnhancedSyncManager {
  static final EnhancedSyncManager _instance = EnhancedSyncManager._internal();
  factory EnhancedSyncManager() => _instance;
  EnhancedSyncManager._internal();

  final OfflineSyncService _offlineSyncService = OfflineSyncService();
  final LocalStorageService _localStorage = LocalStorageService();
  final WebSocketManager _webSocketManager = WebSocketManager();
  
  bool _isSyncing = false;
  bool _isBackgroundSync = false;
  String? _currentGroupId;
  DateTime? _lastFullSync;
  DateTime? _appPausedTime;
  Timer? _periodicSyncTimer;
  String? _cachedDeviceId; // 缓存设备ID
  
  // 消息去重缓存
  final Set<String> _processedMessageIds = <String>{};
  final Map<String, DateTime> _messageTimestamps = <String, DateTime>{};
  final int _maxCacheSize = 1000;
  
  // 监听器
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _messageSubscription;
  
  // 🔥 新增：UI更新通知流
  final StreamController<SyncUIUpdateEvent> _uiUpdateController = 
      StreamController<SyncUIUpdateEvent>.broadcast();
  
  /// UI更新事件流 - 其他组件可以监听此流来获取同步更新
  Stream<SyncUIUpdateEvent> get onUIUpdateRequired => _uiUpdateController.stream;
  
  /// 检查是否正在同步
  bool get isSyncing => _isSyncing;
  bool get isBackgroundSync => _isBackgroundSync;
  String? get currentGroupId => _currentGroupId;

  /// 设置当前群组ID
  void setCurrentGroupId(String? groupId) {
    if (_currentGroupId != groupId) {
      _currentGroupId = groupId;
      debugPrint('📱 设置当前群组ID: $groupId');
    }
  }

  /// 初始化增强同步管理器
  Future<void> initialize() async {
    debugPrint('🚀 初始化增强同步管理器...');
    
    // 加载缓存的消息ID
    await _loadProcessedMessageIds();
    
    // 加载缓存的设备ID
    await _loadCachedDeviceId();
    
    // 监听WebSocket连接状态变化
    _connectionSubscription = _webSocketManager.onConnectionStateChanged.listen(_onConnectionStateChanged);
    
    // 监听消息接收
    _messageSubscription = _webSocketManager.onMessageReceived.listen(_onMessageReceived);
    
    // 启动定期同步
    _startPeriodicSync();
    
    debugPrint('✅ 增强同步管理器初始化完成');
  }

  /// 销毁资源
  void dispose() {
    _connectionSubscription?.cancel();
    _messageSubscription?.cancel();
    _periodicSyncTimer?.cancel();
  }

  /// 连接状态变化处理
  void _onConnectionStateChanged(ConnectionState state) async {
    switch (state) {
      case ConnectionState.connected:
        debugPrint('🔄 WebSocket已连接，开始恢复同步...');
        await _performConnectionRestoreSync();
        break;
      case ConnectionState.disconnected:
      case ConnectionState.failed:
        debugPrint('⚠️ WebSocket连接断开，停止同步');
        break;
      default:
        break;
    }
  }

  /// 消息接收处理
  void _onMessageReceived(Map<String, dynamic> message) async {
    final messageType = message['type'] as String?;
    
    switch (messageType) {
      case 'offline_messages':
        await _handleOfflineMessages(message['data']);
        break;
      case 'group_messages_synced':
        await _handleGroupMessageSync(message['data']);
        break;
      case 'private_messages_synced':
        await _handlePrivateMessageSync(message['data']);
        break;
      case 'message': // 实时消息
        await _handleRealtimeMessage(message);
        break;
    }
  }

  /// 应用启动时的增强同步
  Future<EnhancedSyncResult> performAppStartupSync() async {
    if (_isSyncing) {
      debugPrint('⏳ 同步已在进行中，跳过重复同步');
      return EnhancedSyncResult.skip('同步已在进行中');
    }

    _isSyncing = true;
    debugPrint('🚀 开始增强应用启动同步...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取上次应用关闭时间
      final lastAppCloseTimeStr = prefs.getString('last_app_close_time');
      DateTime? lastAppCloseTime;
      if (lastAppCloseTimeStr != null) {
        lastAppCloseTime = DateTime.parse(lastAppCloseTimeStr);
      }
      
      // 获取上次完整同步时间
      final lastFullSyncTimeStr = prefs.getString('last_full_sync_time');
      if (lastFullSyncTimeStr != null) {
        _lastFullSync = DateTime.parse(lastFullSyncTimeStr);
      }
      
      // 计算同步起始时间
      DateTime syncFromTime;
      if (lastAppCloseTime != null) {
        // 使用应用关闭时间，但提前30分钟以确保不漏消息
        syncFromTime = lastAppCloseTime.subtract(const Duration(minutes: 30));
      } else if (_lastFullSync != null) {
        // 使用上次完整同步时间
        syncFromTime = _lastFullSync!.subtract(const Duration(minutes: 15));
      } else {
        // 默认同步最近24小时
        syncFromTime = DateTime.now().subtract(const Duration(hours: 24));
      }
      
      debugPrint('📅 同步起始时间: $syncFromTime');
      
      // 执行多阶段同步
      final result = await _performMultiPhaseSync(syncFromTime);
      
      // 更新同步时间
      final now = DateTime.now();
      await prefs.setString('last_full_sync_time', now.toIso8601String());
      _lastFullSync = now;
      
      debugPrint('✅ 增强应用启动同步完成');
      return result;
      
    } catch (e) {
      debugPrint('❌ 增强应用启动同步失败: $e');
      return EnhancedSyncResult.error(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// 多阶段同步
  Future<EnhancedSyncResult> _performMultiPhaseSync(DateTime fromTime) async {
    int totalFetched = 0;
    int totalProcessed = 0;
    
    try {
      // 阶段1: 基础离线消息同步
      debugPrint('📱 阶段1: 基础离线消息同步');
      final offlineResult = await _offlineSyncService.syncOfflineMessages(
        fromTime: fromTime,
        limit: 200,
      );
      
      if (offlineResult.messages.isNotEmpty) {
        final processed = await _processMessagesWithEnhancedDeduplication(offlineResult.messages);
        totalFetched += offlineResult.messages.length;
        totalProcessed += processed;
        debugPrint('✅ 阶段1完成: ${offlineResult.messages.length} 条消息');
      }
      
      // 阶段2: 群组历史消息补充同步
      debugPrint('📱 阶段2: 群组历史消息补充同步');
      final groupIds = await _getActiveGroupIds();
      for (final groupId in groupIds) {
        try {
          final groupResult = await _offlineSyncService.syncGroupHistory(
            groupId: groupId,
            fromTime: fromTime,
            limit: 50,
          );
          
          if (groupResult.messages.isNotEmpty) {
            final processed = await _processMessagesWithEnhancedDeduplication(groupResult.messages);
            totalFetched += groupResult.messages.length;
            totalProcessed += processed;
            debugPrint('✅ 群组 $groupId: ${groupResult.messages.length} 条消息');
          }
        } catch (e) {
          debugPrint('⚠️ 群组 $groupId 同步失败: $e');
        }
      }
      
      // 阶段3: WebSocket实时同步请求
      debugPrint('📱 阶段3: WebSocket实时同步请求');
      _requestWebSocketSync(fromTime);
      
      return EnhancedSyncResult.success(
        totalFetched: totalFetched,
        totalProcessed: totalProcessed,
        syncedAt: DateTime.now(),
        phases: ['offline_sync', 'group_history', 'websocket_request'],
      );
      
    } catch (e) {
      debugPrint('❌ 多阶段同步失败: $e');
      return EnhancedSyncResult.error(e.toString());
    }
  }

  /// 应用从后台恢复时的增强同步
  Future<EnhancedSyncResult> performBackgroundResumeSync() async {
    if (_isBackgroundSync) {
      debugPrint('⏳ 后台同步已在进行中，跳过重复同步');
      return EnhancedSyncResult.skip('后台同步已在进行中');
    }

    _isBackgroundSync = true;
    debugPrint('🔄 开始后台恢复增强同步...');
    
    try {
      // 🔥 新增：强制执行当前群组消息同步
      if (_currentGroupId != null) {
        debugPrint('📱 优先同步当前群组消息: $_currentGroupId');
        await _forceCurrentGroupSync();
      }
      
      // 计算应用暂停时长
      final pauseDuration = _appPausedTime != null 
          ? DateTime.now().difference(_appPausedTime!)
          : const Duration(minutes: 5);
      
      debugPrint('⏱️ 应用暂停时长: ${pauseDuration.inMinutes} 分钟');
      
      // 🔧 修复：优化同步策略，确保任何情况下都能获取离线消息
      EnhancedSyncResult result;
      
      if (pauseDuration.inMinutes < 2) {
        // 极短暂停：快速同步（但包含HTTP API调用）
        debugPrint('📱 选择快速同步策略（<2分钟）');
        result = await _performQuickSync();
      } else if (pauseDuration.inMinutes < 30) {
        // 短暂暂停：增量同步  
        debugPrint('📱 选择增量同步策略（2-30分钟）');
        result = await _performIncrementalSync(_appPausedTime!);
      } else if (pauseDuration.inHours < 8) {
        // 中等暂停：增强增量同步
        debugPrint('📱 选择增强增量同步策略（30分钟-8小时）');
        result = await _performIncrementalSync(_appPausedTime!);
      } else {
        // 长时间暂停：完整同步
        debugPrint('📱 选择完整同步策略（>8小时）');
        result = await _performFullBackgroundSync(_appPausedTime!);
      }
      
      debugPrint('✅ 后台恢复同步完成: ${result.totalFetched} 条消息');
      return result;
      
    } catch (e) {
      debugPrint('❌ 后台恢复同步失败: $e');
      return EnhancedSyncResult.error(e.toString());
    } finally {
      _isBackgroundSync = false;
    }
  }

  /// 🔥 新增：强制当前群组消息同步
  Future<void> _forceCurrentGroupSync() async {
    if (_currentGroupId == null) return;
    
    try {
      debugPrint('🔄 强制同步当前群组: $_currentGroupId');
      
      // 使用新的群组消息查询接口
      final newMessages = await _fetchGroupMessagesWithNewAPI(_currentGroupId!, limit: 50);
      
      if (newMessages.isNotEmpty) {
        debugPrint('📥 从群组API获取到 ${newMessages.length} 条消息');
        
        // 处理并保存新消息
        final processed = await _processMessagesWithEnhancedDeduplication(newMessages);
        
        if (processed > 0) {
          debugPrint('✅ 成功处理 $processed 条新群组消息');
          
          // 立即通知UI更新
          _notifyUIUpdate(SyncUIUpdateEvent(
            type: 'force_global_refresh',
            conversationId: _currentGroupId,
            messageCount: processed,
            timestamp: DateTime.now(),
            syncType: 'background_group_sync',
          ));
        }
      } else {
        debugPrint('📝 群组无新消息');
      }
    } catch (e) {
      debugPrint('❌ 强制群组同步失败: $e');
    }
  }

  /// 🔥 新增：使用新的群组消息查询API
  Future<List<Map<String, dynamic>>> _fetchGroupMessagesWithNewAPI(String groupId, {int limit = 20, String? before}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        throw Exception('无认证令牌');
      }
      
      // 构建请求URL
      var url = '${AppConfig.API_BASE_URL}/api/messages/group/$groupId';
      final params = <String, String>{
        'limit': limit.toString(),
      };
      if (before != null) {
        params['before'] = before;
      }
      
      if (params.isNotEmpty) {
        final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
        url += '?$queryString';
      }
      
      debugPrint('📡 请求群组消息: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('📡 群组消息API响应状态: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> messagesJson = jsonDecode(response.body);
        final messages = messagesJson.cast<Map<String, dynamic>>();
        
        debugPrint('📥 获取到 ${messages.length} 条群组消息');
        return messages;
      } else {
        debugPrint('❌ 群组消息API失败: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ 获取群组消息失败: $e');
      return [];
    }
  }

  /// 群组切换时的消息同步
  Future<EnhancedSyncResult> performGroupSwitchSync(String groupId) async {
    debugPrint('🔄 群组切换同步: $groupId');
    
    try {
      _currentGroupId = groupId;
      
      // 获取群组的最新消息
      final result = await _offlineSyncService.syncGroupHistory(
        groupId: groupId,
        fromTime: DateTime.now().subtract(const Duration(hours: 6)), // 同步最近6小时
        limit: 100,
      );
      
      // 处理消息
      final processed = await _processMessagesWithEnhancedDeduplication(result.messages);
      
      // 通过WebSocket请求该群组的实时状态
      _requestGroupRealtimeSync(groupId);
      
      debugPrint('✅ 群组切换同步完成: ${result.messages.length} 条消息');
      
      return EnhancedSyncResult.success(
        totalFetched: result.messages.length,
        totalProcessed: processed,
        syncedAt: DateTime.now(),
        groupId: groupId,
      );
      
    } catch (e) {
      debugPrint('❌ 群组切换同步失败: $e');
      return EnhancedSyncResult.error(e.toString(), groupId: groupId);
    }
  }

  /// 连接恢复后的同步
  Future<void> _performConnectionRestoreSync() async {
    debugPrint('🔄 连接恢复同步...');
    
    try {
      // 等待连接稳定
      await Future.delayed(const Duration(seconds: 2));
      
      // 🔥 关键修复：立即使用HTTP API拉取当前群组的历史消息
      if (_currentGroupId != null) {
        debugPrint('📱 连接恢复 - 立即同步当前群组: $_currentGroupId');
        await _forceCurrentGroupSync();
      }
      
      // 请求离线期间的消息
      final lastOnlineTime = await _getLastOnlineTime();
      if (lastOnlineTime != null) {
        _requestWebSocketSync(lastOnlineTime);
      }
      
      // 🔥 增强：使用HTTP API拉取所有活跃群组的最新消息
      final activeGroups = await _getActiveGroupIds();
      for (final groupId in activeGroups.take(3)) { // 限制最多3个群组避免过载
        if (groupId != _currentGroupId) { // 当前群组已经同步过了
          try {
            debugPrint('📱 连接恢复 - 同步群组: $groupId');
            final messages = await _fetchGroupMessagesWithNewAPI(groupId, limit: 20);
            if (messages.isNotEmpty) {
              await _processMessagesWithEnhancedDeduplication(messages);
              debugPrint('✅ 群组 $groupId 同步了 ${messages.length} 条消息');
            }
          } catch (e) {
            debugPrint('⚠️ 群组 $groupId 同步失败: $e');
          }
        }
      }
      
      // 如果有当前群组，请求该群组的实时WebSocket状态
      if (_currentGroupId != null) {
        _requestGroupRealtimeSync(_currentGroupId!);
      }
      
      // 请求全局状态同步
      _requestGlobalStateSync();
      
    } catch (e) {
      debugPrint('❌ 连接恢复同步失败: $e');
    }
  }

  /// 🔥 统一的消息去重处理 - 仅基于消息ID进行唯一去重
  Future<int> _processMessagesWithEnhancedDeduplication(List<Map<String, dynamic>> messages) async {
    int processedCount = 0;
    final Map<String, List<Map<String, dynamic>>> conversationMessages = {};
    
    debugPrint('📥 开始处理消息，统一使用消息ID去重机制');
    
    for (final message in messages) {
      final messageId = message['id'] as String?;
      if (messageId == null) {
        debugPrint('⚠️ 跳过无ID消息');
        continue;
      }
      
      // 🔥 统一去重机制：仅检查消息ID是否已处理
      if (_isMessageIdProcessed(messageId)) {
        debugPrint('⏭️ 跳过重复消息ID: $messageId');
        continue;
      }
      
      // 标记消息ID已处理
      _markMessageIdProcessed(messageId);
      
      // 分组消息到对应的对话
      final conversationId = _getConversationId(message);
      conversationMessages.putIfAbsent(conversationId, () => []).add(message);
      
      debugPrint('✅ 消息ID通过去重检查: $messageId -> $conversationId');
    }
    
    // 处理每个对话的消息
    for (final entry in conversationMessages.entries) {
      try {
        final conversationId = entry.key;
        final newMessages = entry.value;
        
        // 加载现有消息
        final existingMessages = await _localStorage.loadChatMessages(conversationId);
        
        // 🔥 简化的消息合并：直接基于消息ID去重
        final mergedMessages = _mergeMessagesByIdOnly(existingMessages, newMessages);
        
        // 保存合并后的消息
        await _localStorage.saveChatMessages(conversationId, mergedMessages);
        
        processedCount += newMessages.length;
        debugPrint('💾 对话 $conversationId: 新增 ${newMessages.length} 条消息');
        
      } catch (e) {
        debugPrint('❌ 处理对话消息失败: ${entry.key}, $e');
      }
    }
    
    // 清理过期的消息ID缓存
    _cleanupMessageIdCache();
    
    if (processedCount > 0) {
      _notifyUIUpdate(SyncUIUpdateEvent(
        type: 'sync_completed',
        messageCount: processedCount,
        timestamp: DateTime.now(),
        syncType: 'id_based_deduplication',
      ));
    }
    
    debugPrint('✅ 消息处理完成，共处理 $processedCount 条消息');
    return processedCount;
  }

  /// 🔥 新增：检查消息ID是否已处理（仅基于ID）
  bool _isMessageIdProcessed(String messageId) {
    return _processedMessageIds.contains(messageId);
  }

  /// 🔥 新增：标记消息ID已处理（仅记录ID和时间）
  void _markMessageIdProcessed(String messageId) {
    _processedMessageIds.add(messageId);
    _messageTimestamps[messageId] = DateTime.now();
  }

  /// 🔥 新增：基于消息ID的简化合并
  List<Map<String, dynamic>> _mergeMessagesByIdOnly(
    List<Map<String, dynamic>> existingMessages,
    List<Map<String, dynamic>> newMessages,
  ) {
    final existingIds = existingMessages.map((msg) => msg['id']?.toString()).toSet();
    final mergedMessages = List<Map<String, dynamic>>.from(existingMessages);
    
    // 只添加ID不存在的新消息
    for (final newMessage in newMessages) {
      final messageId = newMessage['id']?.toString();
      if (messageId != null && !existingIds.contains(messageId)) {
        mergedMessages.add(newMessage);
        debugPrint('🆕 添加新消息: $messageId');
      } else {
        debugPrint('🔄 跳过已存在消息ID: $messageId');
      }
    }
    
    // 按时间排序
    mergedMessages.sort((a, b) {
      try {
        final timeA = DateTime.parse(a['timestamp'] ?? DateTime.now().toIso8601String());
        final timeB = DateTime.parse(b['timestamp'] ?? DateTime.now().toIso8601String());
        return timeA.compareTo(timeB);
      } catch (e) {
        debugPrint('⚠️ 消息时间排序失败: $e');
        return 0;
      }
    });
    
    return mergedMessages;
  }

  /// 🔥 新增：清理消息ID缓存（简化版）
  void _cleanupMessageIdCache() {
    final now = DateTime.now();
    
    // 清理2小时前的消息ID
    final expiredIds = <String>[];
    _messageTimestamps.forEach((id, timestamp) {
      if (now.difference(timestamp).inHours >= 2) {
        expiredIds.add(id);
      }
    });
    
    // 如果缓存过大，清理最旧的记录
    if (_processedMessageIds.length > _maxCacheSize) {
      final sortedEntries = _messageTimestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      final excess = _processedMessageIds.length - (_maxCacheSize * 0.8).round();
      for (int i = 0; i < excess && i < sortedEntries.length; i++) {
        expiredIds.add(sortedEntries[i].key);
      }
    }
    
    // 执行清理
    for (final id in expiredIds) {
      _processedMessageIds.remove(id);
      _messageTimestamps.remove(id);
    }
    
    if (expiredIds.isNotEmpty) {
      debugPrint('🧹 清理了 ${expiredIds.length} 个过期消息ID');
    }
  }

  /// 快速同步（短暂暂停后）- 增强版
  Future<EnhancedSyncResult> _performQuickSync() async {
    debugPrint('⚡ 执行快速同步（增强版）...');
    
    try {
      // 🔧 修复：扩大时间范围，确保不遗漏消息
      final now = DateTime.now();
      final fromTime = _appPausedTime != null 
          ? _appPausedTime!.subtract(const Duration(minutes: 5)) // 向前推5分钟确保不遗漏
          : now.subtract(const Duration(minutes: 15)); // 默认15分钟
      
      debugPrint('📡 快速同步起始时间: $fromTime (向前推5分钟确保完整性)');
      
      // 🔥 修复：使用现有可用的API进行同步
      final futures = <Future>[];
      
      // 🔧 临时禁用离线消息API（404错误），改用WebSocket同步
      debugPrint('⚠️ 离线消息API不可用，跳过HTTP同步，依赖WebSocket');
      
      // 1. 如果有当前群组，优先同步群组历史
      if (_currentGroupId != null) {
        try {
          final groupHistoryFuture = _offlineSyncService.syncGroupHistory(
            groupId: _currentGroupId!,
            fromTime: fromTime,
            limit: 100, // 增加群组消息限制
          );
          futures.add(groupHistoryFuture);
          debugPrint('📱 添加群组历史同步: $_currentGroupId');
        } catch (e) {
          debugPrint('❌ 群组历史同步添加失败: $e');
        }
      }
      
      // 2. 🔥 新增：依赖WebSocket进行实时同步
      _requestWebSocketSync(fromTime);
      _requestQuickSync();
      debugPrint('📡 已发送WebSocket同步请求，等待响应');
      
      // 3. 🔥 新增：如果没有群组，创建一个立即完成的Future避免空数组
      if (futures.isEmpty) {
        futures.add(Future.value(OfflineMessagesResult(
          deviceId: _getDeviceId() ?? 'unknown',
          messages: [], 
          syncInfo: OfflineSyncInfo(
            total: 0,
            returned: 0,
            fromTime: fromTime,
            syncedAt: DateTime.now(),
          ),
        )));
        debugPrint('📝 没有HTTP同步任务，创建空结果');
      }
      
      // 等待所有同步完成
      final results = await Future.wait(futures);
      
      // 处理所有获取的消息
      List<Map<String, dynamic>> allMessages = [];
      int totalFetched = 0;
      
      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        if (result is OfflineMessagesResult && result.messages.isNotEmpty) {
          allMessages.addAll(result.messages);
          totalFetched += result.messages.length;
          debugPrint('📥 离线消息: ${result.messages.length} 条');
        } else if (result is GroupHistoryResult && result.messages.isNotEmpty) {
          allMessages.addAll(result.messages);
          totalFetched += result.messages.length;
          debugPrint('📥 群组历史: ${result.messages.length} 条');
        }
      }
      
      // 🔥 关键修复：立即处理消息并通知UI
      final processed = await _processMessagesWithEnhancedDeduplication(allMessages);
      
      // 🔥 立即发送UI更新通知（不延迟）
      if (processed > 0) {
        _notifyUIUpdate(SyncUIUpdateEvent(
          type: 'force_global_refresh',
          messageCount: processed,
          timestamp: DateTime.now(),
          syncType: 'quick_sync_complete',
        ));
      }
      
      debugPrint('✅ 快速同步完成: 获取 $totalFetched 条，处理 $processed 条消息');
      
             // 3. 发送WebSocket同步请求
       _requestWebSocketSync(fromTime);
       _requestQuickSync();
      
      return EnhancedSyncResult.success(
        totalFetched: totalFetched,
        totalProcessed: processed,
        syncedAt: DateTime.now(),
        phases: ['offline_quick', 'group_history', 'websocket_request'],
      );
      
    } catch (e) {
      debugPrint('❌ 快速同步失败: $e');
      return EnhancedSyncResult.error(e.toString());
    }
  }

  /// 增量同步（中等暂停后）
  Future<EnhancedSyncResult> _performIncrementalSync(DateTime fromTime) async {
    debugPrint('📈 执行增量同步...');
    
    try {
      // 🔧 修复：根据离线时间动态调整同步限制
      final now = DateTime.now();
      final offlineDuration = now.difference(fromTime);
      
      int limit = 100; // 默认限制
      if (offlineDuration.inHours > 2) {
        limit = 200; // 长时间离线获取更多消息
      } else if (offlineDuration.inMinutes > 30) {
        limit = 150; // 中等时间离线
      }
      
      debugPrint('📊 离线时长: ${offlineDuration.inMinutes}分钟，同步限制: $limit');
      
      final result = await _offlineSyncService.syncOfflineMessages(
        fromTime: fromTime,
        limit: limit,
      );
      
      final processed = await _processMessagesWithEnhancedDeduplication(result.messages);
      
      // 同时请求WebSocket同步
      _requestWebSocketSync(fromTime);
      
      debugPrint('✅ 增量同步完成: ${result.messages.length} 条消息');
      
      return EnhancedSyncResult.success(
        totalFetched: result.messages.length,
        totalProcessed: processed,
        syncedAt: DateTime.now(),
        phases: ['offline_incremental', 'websocket_request'],
      );
      
    } catch (e) {
      debugPrint('❌ 增量同步失败: $e');
      return EnhancedSyncResult.error(e.toString());
    }
  }

  /// 完整后台同步（长时间暂停后）
  Future<EnhancedSyncResult> _performFullBackgroundSync(DateTime fromTime) async {
    debugPrint('🔄 执行完整后台同步...');
    
    // 与应用启动同步类似，但限制同步范围
    return await _performMultiPhaseSync(fromTime);
  }

  /// WebSocket同步请求
  void _requestWebSocketSync(DateTime fromTime) {
    if (_webSocketManager.isConnected) {
      debugPrint('📡 请求WebSocket同步: $fromTime');
      
      // 发送同步请求（通过公共接口）
      _sendWebSocketMessage('sync_messages_since', {
        'since': fromTime.toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
        'device_id': _getDeviceId(),
      });
    }
  }

  /// 请求群组实时同步
  void _requestGroupRealtimeSync(String groupId) {
    if (_webSocketManager.isConnected) {
      debugPrint('📡 请求群组实时同步: $groupId');
      
      _sendWebSocketMessage('sync_group_messages', {
        'group_id': groupId,
        'timestamp': DateTime.now().toIso8601String(),
        'limit': 50,
      });
    }
  }

  /// 请求快速同步
  void _requestQuickSync() {
    if (_webSocketManager.isConnected) {
      debugPrint('📡 请求快速同步');
      
      _sendWebSocketMessage('quick_sync', {
        'timestamp': DateTime.now().toIso8601String(),
        'device_id': _getDeviceId(),
      });
    }
  }

  /// 请求全局状态同步
  void _requestGlobalStateSync() {
    if (_webSocketManager.isConnected) {
      debugPrint('📡 请求全局状态同步');
      
      _sendWebSocketMessage('sync_global_state', {
        'timestamp': DateTime.now().toIso8601String(),
        'device_id': _getDeviceId(),
      });
    }
  }

  /// 发送WebSocket消息（公共辅助方法）- 修复版
  void _sendWebSocketMessage(String event, Map<String, dynamic> data) {
    try {
      debugPrint('🔗 尝试发送WebSocket消息: $event');
      debugPrint('📤 消息数据: $data');
      
      // 🔧 修复：使用WebSocketManager的emit方法发送消息
      if (_webSocketManager.isConnected) {
        _webSocketManager.emit(event, data);
        debugPrint('✅ WebSocket已连接，发送消息: $event');
      } else {
        debugPrint('⚠️ WebSocket未连接，消息丢弃: $event (让WebSocketManager处理重连)');
        // 🔥 修复：移除独立重连逻辑，交给WebSocketManager统一处理
        // 避免重复重连导致的连接混乱
      }
    } catch (e) {
      debugPrint('❌ 发送WebSocket消息失败: $e');
    }
  }
  
  /// 🔥 已移除：确保WebSocket连接 (避免重复重连)
  /// 重连逻辑统一由WebSocketManager处理，避免多处重连导致的冲突
  // Future<void> _ensureWebSocketConnection() async { ... }

  /// 处理离线消息
  Future<void> _handleOfflineMessages(dynamic data) async {
    debugPrint('📥 处理离线消息响应');
    
    if (data is Map<String, dynamic> && data['messages'] is List) {
      final messages = List<Map<String, dynamic>>.from(data['messages']);
      await _processMessagesWithEnhancedDeduplication(messages);
      debugPrint('✅ 处理了 ${messages.length} 条离线消息');
    }
  }

  /// 处理群组消息同步
  Future<void> _handleGroupMessageSync(dynamic data) async {
    debugPrint('📝 处理群组消息同步响应');
    
    if (data is Map<String, dynamic> && data['messages'] is List) {
      final messages = List<Map<String, dynamic>>.from(data['messages']);
      await _processMessagesWithEnhancedDeduplication(messages);
      debugPrint('✅ 处理了 ${messages.length} 条群组消息');
    }
  }

  /// 处理私聊消息同步
  Future<void> _handlePrivateMessageSync(dynamic data) async {
    debugPrint('💬 处理私聊消息同步响应');
    
    if (data is Map<String, dynamic> && data['messages'] is List) {
      final messages = List<Map<String, dynamic>>.from(data['messages']);
      await _processMessagesWithEnhancedDeduplication(messages);
      debugPrint('✅ 处理了 ${messages.length} 条私聊消息');
    }
  }

  /// 处理实时消息
  Future<void> _handleRealtimeMessage(Map<String, dynamic> message) async {
    debugPrint('📩 处理实时消息');
    
    await _processMessagesWithEnhancedDeduplication([message]);
  }

  /// 启动定期同步
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (!_isSyncing && _webSocketManager.isConnected) {
        debugPrint('⏰ 执行定期同步检查');
        _requestQuickSync();
      }
    });
  }

  /// 应用进入后台
  Future<void> onAppPaused() async {
    _appPausedTime = DateTime.now();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_app_close_time', _appPausedTime!.toIso8601String());
    
    // 保存已处理的消息ID
    await _saveProcessedMessageIds();
    
    debugPrint('📱 应用进入后台: $_appPausedTime');
  }

  /// 应用从后台恢复
  Future<void> onAppResumed() async {
    debugPrint('📱 应用从后台恢复');
    
    // 执行后台恢复同步
    final result = await performBackgroundResumeSync();
    debugPrint('🔄 后台恢复同步结果: ${result.success}');
  }

  /// 获取对话ID
  String _getConversationId(Map<String, dynamic> message) {
    if (message['type'] == 'group' || message['groupId'] != null) {
      return 'group_${message['groupId']}';
    } else {
      final senderId = message['senderId'];
      final recipientId = message['recipientId'];
      final ids = [senderId, recipientId]..sort();
      return 'private_${ids[0]}_${ids[1]}';
    }
  }

  /// 获取活跃群组ID列表
  Future<List<String>> _getActiveGroupIds() async {
    // 这里可以从本地存储或API获取用户加入的群组列表
    // 暂时返回空列表，实际实现时需要根据业务逻辑获取
    return [];
  }

  /// 获取设备ID
  String? _getDeviceId() {
    return _cachedDeviceId;
  }

  /// 加载缓存的设备ID
  Future<void> _loadCachedDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serverDeviceData = prefs.getString('server_device_data');
      if (serverDeviceData != null) {
        final Map<String, dynamic> data = jsonDecode(serverDeviceData);
        _cachedDeviceId = data['id'];
        debugPrint('📱 加载缓存设备ID: $_cachedDeviceId');
      }
    } catch (e) {
      debugPrint('⚠️ 加载设备ID失败: $e');
    }
  }

  /// 获取最后在线时间
  Future<DateTime?> _getLastOnlineTime() async {
    return await _offlineSyncService.getLastOnlineTime();
  }

  /// 加载已处理的消息ID
  Future<void> _loadProcessedMessageIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idsJson = prefs.getString('processed_message_ids');
      if (idsJson != null) {
        final List<dynamic> idsList = jsonDecode(idsJson);
        _processedMessageIds.clear();
        _processedMessageIds.addAll(idsList.cast<String>());
        debugPrint('📥 加载了 ${_processedMessageIds.length} 个已处理消息ID');
      }
    } catch (e) {
      debugPrint('⚠️ 加载已处理消息ID失败: $e');
    }
  }

  /// 保存已处理的消息ID
  Future<void> _saveProcessedMessageIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idsList = _processedMessageIds.toList();
      
      // 只保存最近的消息ID
      if (idsList.length > _maxCacheSize) {
        idsList.removeRange(0, idsList.length - _maxCacheSize);
        _processedMessageIds.clear();
        _processedMessageIds.addAll(idsList);
      }
      
      await prefs.setString('processed_message_ids', jsonEncode(idsList));
      debugPrint('💾 保存了 ${idsList.length} 个已处理消息ID');
    } catch (e) {
      debugPrint('⚠️ 保存已处理消息ID失败: $e');
    }
  }

  /// 获取同步状态
  Future<EnhancedSyncStatus> getSyncStatus() async {
    final lastOnlineTime = await _getLastOnlineTime();
    
    return EnhancedSyncStatus(
      isSyncing: _isSyncing,
      isBackgroundSync: _isBackgroundSync,
      lastOnlineTime: lastOnlineTime,
      lastFullSync: _lastFullSync,
      currentGroupId: _currentGroupId,
      processedMessageCount: _processedMessageIds.length,
      isWebSocketConnected: _webSocketManager.isConnected,
    );
  }

  /// 🔥 新增：发送UI更新通知 - 增强版
  void _notifyUIUpdate(SyncUIUpdateEvent event) {
    debugPrint('📢 发送UI更新通知: ${event.toString()}');
    
    if (!_uiUpdateController.isClosed) {
      _uiUpdateController.add(event);
      
      // 🔥 新增：延迟发送全局刷新事件
      Timer(Duration(milliseconds: 500), () {
        if (!_uiUpdateController.isClosed) {
          _uiUpdateController.add(SyncUIUpdateEvent(
            type: 'force_refresh_all',
            messageCount: event.messageCount,
            timestamp: DateTime.now(),
            syncType: 'delayed_force_refresh',
          ));
        }
      });
    }
  }
  
  /// 🔥 新增：强制刷新所有UI
  void forceRefreshAllUI() {
    debugPrint('🔄 强制刷新所有UI...');
    
    if (!_uiUpdateController.isClosed) {
      _uiUpdateController.add(SyncUIUpdateEvent(
        type: 'force_global_refresh',
        messageCount: 0,
        timestamp: DateTime.now(),
        syncType: 'manual_force_refresh',
      ));
    }
  }
}

/// UI同步更新事件
class SyncUIUpdateEvent {
  final String type; // 'messages_updated', 'conversation_updated', 'sync_completed'
  final String? conversationId;
  final int messageCount;
  final List<String> messageIds;
  final DateTime timestamp;
  final String? syncType;

  SyncUIUpdateEvent({
    required this.type,
    this.conversationId,
    this.messageCount = 0,
    this.messageIds = const [],
    required this.timestamp,
    this.syncType,
  });

  @override
  String toString() => 'SyncUIUpdateEvent(type: $type, conversationId: $conversationId, messageCount: $messageCount, syncType: $syncType)';
}

/// 增强同步结果
class EnhancedSyncResult {
  final bool success;
  final String? error;
  final int totalFetched;
  final int totalProcessed;
  final DateTime? syncedAt;
  final String? groupId;
  final List<String> phases;

  EnhancedSyncResult._({
    required this.success,
    this.error,
    this.totalFetched = 0,
    this.totalProcessed = 0,
    this.syncedAt,
    this.groupId,
    this.phases = const [],
  });

  factory EnhancedSyncResult.success({
    required int totalFetched,
    required int totalProcessed,
    required DateTime syncedAt,
    String? groupId,
    List<String> phases = const [],
  }) {
    return EnhancedSyncResult._(
      success: true,
      totalFetched: totalFetched,
      totalProcessed: totalProcessed,
      syncedAt: syncedAt,
      groupId: groupId,
      phases: phases,
    );
  }

  factory EnhancedSyncResult.error(String error, {String? groupId}) {
    return EnhancedSyncResult._(
      success: false,
      error: error,
      groupId: groupId,
    );
  }

  factory EnhancedSyncResult.skip(String reason) {
    return EnhancedSyncResult._(
      success: true,
      error: reason,
    );
  }
}

/// 增强同步状态
class EnhancedSyncStatus {
  final bool isSyncing;
  final bool isBackgroundSync;
  final DateTime? lastOnlineTime;
  final DateTime? lastFullSync;
  final String? currentGroupId;
  final int processedMessageCount;
  final bool isWebSocketConnected;

  EnhancedSyncStatus({
    required this.isSyncing,
    required this.isBackgroundSync,
    this.lastOnlineTime,
    this.lastFullSync,
    this.currentGroupId,
    required this.processedMessageCount,
    required this.isWebSocketConnected,
  });
} 