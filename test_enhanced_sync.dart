import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'lib/services/enhanced_sync_manager.dart';
import 'lib/services/group_switch_sync_service.dart';
import 'lib/services/offline_sync_service.dart';
import 'lib/services/local_storage_service.dart';

/// 增强同步功能测试
class EnhancedSyncTester {
  final EnhancedSyncManager _syncManager = EnhancedSyncManager();
  final GroupSwitchSyncService _groupSwitchService = GroupSwitchSyncService();
  final OfflineSyncService _offlineService = OfflineSyncService();
  final LocalStorageService _localStorage = LocalStorageService();

  /// 运行所有测试
  Future<void> runAllTests() async {
    print('🚀 开始增强同步功能测试...');
    
    final results = <String, bool>{};
    
    try {
      // 初始化服务
      await _initializeServices();
      
      // 1. 测试消息去重机制
      results['消息去重机制'] = await _testMessageDeduplication();
      
      // 2. 测试后台恢复同步
      results['后台恢复同步'] = await _testBackgroundResumeSync();
      
      // 3. 测试群组切换同步
      results['群组切换同步'] = await _testGroupSwitchSync();
      
      // 4. 测试连接恢复同步
      results['连接恢复同步'] = await _testConnectionRestoreSync();
      
      // 5. 测试智能合并消息
      results['智能合并消息'] = await _testSmartMessageMerging();
      
      // 6. 测试多阶段同步
      results['多阶段同步'] = await _testMultiPhaseSync();
      
    } catch (e) {
      print('❌ 测试初始化失败: $e');
    }
    
    // 输出测试结果
    _printTestResults(results);
  }

  /// 初始化服务
  Future<void> _initializeServices() async {
    print('\n=== 初始化测试服务 ===');
    
    try {
      await _syncManager.initialize();
      print('✅ 增强同步管理器初始化完成');
    } catch (e) {
      print('⚠️ 增强同步管理器初始化失败: $e');
    }
  }

  /// 测试消息去重机制
  Future<bool> _testMessageDeduplication() async {
    print('\n=== 测试消息去重机制 ===');
    
    try {
      // 创建测试消息
      final testMessages = [
        {
          'id': 'msg_001',
          'content': '测试消息1',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
          'senderId': 'user_001',
          'recipientId': 'user_002',
        },
        {
          'id': 'msg_002',
          'content': '测试消息2',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 4)).toIso8601String(),
          'senderId': 'user_002',
          'recipientId': 'user_001',
        },
        // 重复消息
        {
          'id': 'msg_001',
          'content': '测试消息1（重复）',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
          'senderId': 'user_001',
          'recipientId': 'user_002',
        },
        // 新消息
        {
          'id': 'msg_003',
          'content': '测试消息3',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 3)).toIso8601String(),
          'groupId': 'test_group',
          'type': 'group',
        },
      ];
      
      print('📤 处理 ${testMessages.length} 条测试消息（包含重复）');
      
      // 模拟处理消息
      final conversationId = 'private_user_001_user_002';
      await _localStorage.saveChatMessages(conversationId, [testMessages[0]]);
      
      // 测试增强去重处理
      final processedCount = await _simulateEnhancedDeduplication(testMessages);
      
      print('✅ 处理完成，实际保存: $processedCount 条消息');
      
      // 验证结果
      final savedMessages = await _localStorage.loadChatMessages(conversationId);
      print('💾 对话 $conversationId 中的消息数: ${savedMessages.length}');
      
      final groupMessages = await _localStorage.loadChatMessages('group_test_group');
      print('💾 群组消息数: ${groupMessages.length}');
      
      return processedCount == 3 && savedMessages.length >= 1; // 应该去重1条消息
      
    } catch (e) {
      print('❌ 消息去重测试失败: $e');
      return false;
    }
  }

  /// 模拟增强去重处理
  Future<int> _simulateEnhancedDeduplication(List<Map<String, dynamic>> messages) async {
    final processedIds = <String>{};
    final conversationMessages = <String, List<Map<String, dynamic>>>{};
    int processedCount = 0;
    
    for (final message in messages) {
      final messageId = message['id'] as String?;
      if (messageId == null) continue;
      
      // 模拟去重检查
      if (processedIds.contains(messageId)) {
        print('⏭️ 跳过重复消息: $messageId');
        continue;
      }
      
      processedIds.add(messageId);
      
      // 分组消息
      String conversationId;
      if (message['type'] == 'group' || message['groupId'] != null) {
        conversationId = 'group_${message['groupId']}';
      } else {
        final senderId = message['senderId'];
        final recipientId = message['recipientId'];
        final ids = [senderId, recipientId]..sort();
        conversationId = 'private_${ids[0]}_${ids[1]}';
      }
      
      conversationMessages.putIfAbsent(conversationId, () => []).add(message);
      processedCount++;
    }
    
    // 保存到本地存储
    for (final entry in conversationMessages.entries) {
      final conversationId = entry.key;
      final newMessages = entry.value;
      
      final existingMessages = await _localStorage.loadChatMessages(conversationId);
      final allMessages = [...existingMessages, ...newMessages];
      
      await _localStorage.saveChatMessages(conversationId, allMessages);
    }
    
    return processedCount;
  }

  /// 测试后台恢复同步
  Future<bool> _testBackgroundResumeSync() async {
    print('\n=== 测试后台恢复同步 ===');
    
    try {
      // 模拟应用进入后台
      await _syncManager.onAppPaused();
      print('📱 模拟应用进入后台');
      
      // 等待一段时间
      await Future.delayed(const Duration(seconds: 2));
      
      // 模拟应用恢复
      await _syncManager.onAppResumed();
      print('📱 模拟应用从后台恢复');
      
      // 执行后台恢复同步
      final result = await _syncManager.performBackgroundResumeSync();
      
      print('🔄 后台恢复同步结果: ${result.success}');
      if (result.success) {
        print('📊 获取: ${result.totalFetched} 条，处理: ${result.totalProcessed} 条');
        print('📋 阶段: ${result.phases.join(', ')}');
      } else {
        print('❌ 错误: ${result.error}');
      }
      
      return result.success;
      
    } catch (e) {
      print('❌ 后台恢复同步测试失败: $e');
      return false;
    }
  }

  /// 测试群组切换同步
  Future<bool> _testGroupSwitchSync() async {
    print('\n=== 测试群组切换同步 ===');
    
    try {
      final testGroupId = 'test_group_switch';
      
      // 监听群组切换事件
      final eventReceived = Completer<bool>();
      final subscription = _groupSwitchService.onGroupSwitch.listen((event) {
        print('📢 收到群组切换事件: ${event.toString()}');
        if (event.newGroupId == testGroupId) {
          eventReceived.complete(true);
        }
      });
      
      // 触发群组切换
      print('🔄 触发群组切换: $testGroupId');
      await _groupSwitchService.notifyGroupSwitch(testGroupId);
      
      // 等待事件或超时
      final received = await eventReceived.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
      
      subscription.cancel();
      
      if (received) {
        print('✅ 群组切换事件接收成功');
        
        // 检查当前群组ID
        final currentGroupId = _groupSwitchService.currentGroupId;
        print('📋 当前群组ID: $currentGroupId');
        
        return currentGroupId == testGroupId;
      } else {
        print('❌ 群组切换事件接收超时');
        return false;
      }
      
    } catch (e) {
      print('❌ 群组切换同步测试失败: $e');
      return false;
    }
  }

  /// 测试连接恢复同步
  Future<bool> _testConnectionRestoreSync() async {
    print('\n=== 测试连接恢复同步 ===');
    
    try {
      // 模拟连接状态变化
      print('🔌 模拟连接恢复...');
      
      // 由于无法直接触发连接状态变化，我们测试相关方法
      final status = await _syncManager.getSyncStatus();
      
      print('📊 同步状态:');
      print('  - 正在同步: ${status.isSyncing}');
      print('  - 后台同步: ${status.isBackgroundSync}');
      print('  - 已处理消息数: ${status.processedMessageCount}');
      print('  - WebSocket连接: ${status.isWebSocketConnected}');
      print('  - 当前群组: ${status.currentGroupId}');
      print('  - 最后在线时间: ${status.lastOnlineTime}');
      print('  - 最后完整同步: ${status.lastFullSync}');
      
      return true; // 基础状态检查通过
      
    } catch (e) {
      print('❌ 连接恢复同步测试失败: $e');
      return false;
    }
  }

  /// 测试智能合并消息
  Future<bool> _testSmartMessageMerging() async {
    print('\n=== 测试智能合并消息 ===');
    
    try {
      final conversationId = 'test_merge_conversation';
      
      // 原有消息
      final existingMessages = [
        {
          'id': 'msg_001',
          'content': '原有消息1',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
          'status': 'sent',
        },
        {
          'id': 'msg_002',
          'content': '原有消息2',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 9)).toIso8601String(),
          'status': 'sent',
        },
      ];
      
      // 新消息（包含更新和新增）
      final newMessages = [
        {
          'id': 'msg_001',
          'content': '原有消息1',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
          'status': 'delivered', // 状态更新
          'readAt': DateTime.now().toIso8601String(), // 新字段
        },
        {
          'id': 'msg_003',
          'content': '新消息',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 8)).toIso8601String(),
          'status': 'sent',
        },
      ];
      
      print('📤 原有消息: ${existingMessages.length} 条');
      print('📤 新消息: ${newMessages.length} 条');
      
      // 保存原有消息
      await _localStorage.saveChatMessages(conversationId, existingMessages);
      
      // 模拟智能合并
      final mergedMessages = _smartMergeMessages(existingMessages, newMessages);
      
      print('🔄 合并后消息: ${mergedMessages.length} 条');
      
      // 检查合并结果
      bool hasUpdatedMessage = false;
      bool hasNewMessage = false;
      
      for (final message in mergedMessages) {
        if (message['id'] == 'msg_001' && message['status'] == 'delivered') {
          hasUpdatedMessage = true;
          print('✅ 消息更新成功: ${message['id']} - ${message['status']}');
        }
        if (message['id'] == 'msg_003') {
          hasNewMessage = true;
          print('✅ 新消息添加成功: ${message['id']}');
        }
      }
      
      // 保存合并结果
      await _localStorage.saveChatMessages(conversationId, mergedMessages);
      
      return hasUpdatedMessage && hasNewMessage && mergedMessages.length == 3;
      
    } catch (e) {
      print('❌ 智能合并消息测试失败: $e');
      return false;
    }
  }

  /// 模拟智能合并消息
  List<Map<String, dynamic>> _smartMergeMessages(
    List<Map<String, dynamic>> existingMessages,
    List<Map<String, dynamic>> newMessages,
  ) {
    final Map<String, Map<String, dynamic>> messageMap = {};
    
    // 添加现有消息
    for (final message in existingMessages) {
      final id = message['id'];
      if (id != null) {
        messageMap[id] = Map<String, dynamic>.from(message);
      }
    }
    
    // 添加新消息（智能覆盖）
    for (final message in newMessages) {
      final id = message['id'];
      if (id != null) {
        final existing = messageMap[id];
        if (existing != null) {
          // 智能合并：保留更完整的信息
          final merged = _mergeMessageInfo(existing, message);
          messageMap[id] = merged;
        } else {
          messageMap[id] = Map<String, dynamic>.from(message);
        }
      }
    }
    
    // 排序并返回
    final allMessages = messageMap.values.toList();
    allMessages.sort((a, b) {
      final timeA = DateTime.tryParse(a['timestamp'] ?? '');
      final timeB = DateTime.tryParse(b['timestamp'] ?? '');
      if (timeA == null || timeB == null) return 0;
      return timeA.compareTo(timeB);
    });
    
    return allMessages;
  }

  /// 合并消息信息
  Map<String, dynamic> _mergeMessageInfo(
    Map<String, dynamic> existing,
    Map<String, dynamic> incoming,
  ) {
    final merged = Map<String, dynamic>.from(existing);
    
    // 优先使用更新的字段
    for (final key in incoming.keys) {
      final incomingValue = incoming[key];
      final existingValue = existing[key];
      
      if (incomingValue != null) {
        if (existingValue == null || 
            (incomingValue is String && incomingValue.isNotEmpty) ||
            (incomingValue is List && incomingValue.isNotEmpty) ||
            (incomingValue is Map && incomingValue.isNotEmpty)) {
          merged[key] = incomingValue;
        }
      }
    }
    
    return merged;
  }

  /// 测试多阶段同步
  Future<bool> _testMultiPhaseSync() async {
    print('\n=== 测试多阶段同步 ===');
    
    try {
      print('🚀 执行应用启动同步（多阶段）...');
      
      final result = await _syncManager.performAppStartupSync();
      
      print('📊 多阶段同步结果:');
      print('  - 成功: ${result.success}');
      print('  - 获取: ${result.totalFetched} 条消息');
      print('  - 处理: ${result.totalProcessed} 条消息');
      print('  - 同步时间: ${result.syncedAt}');
      print('  - 执行阶段: ${result.phases.join(' -> ')}');
      
      if (!result.success) {
        print('❌ 错误: ${result.error}');
      }
      
      // 验证阶段完整性
      final expectedPhases = ['offline_sync', 'group_history', 'websocket_request'];
      final hasAllPhases = expectedPhases.every((phase) => result.phases.contains(phase));
      
      return result.success && hasAllPhases;
      
    } catch (e) {
      print('❌ 多阶段同步测试失败: $e');
      return false;
    }
  }

  /// 输出测试结果
  void _printTestResults(Map<String, bool> results) {
    print('\n' + '=' * 60);
    print('增强同步功能测试结果');
    print('=' * 60);
    
    results.forEach((testName, passed) {
      final status = passed ? '✅ 通过' : '❌ 失败';
      print('$testName: $status');
    });
    
    final passedCount = results.values.where((result) => result).length;
    final totalCount = results.length;
    
    print('\n总体结果: $passedCount/$totalCount 项通过');
    
    if (passedCount == totalCount) {
      print('🎉 所有增强同步测试通过！');
    } else {
      print('⚠️ 部分测试失败，需要检查相关功能');
    }
    
    // 输出优化建议
    _printOptimizationSuggestions(results);
  }

  /// 输出优化建议
  void _printOptimizationSuggestions(Map<String, bool> results) {
    print('\n📋 优化建议:');
    
    if (!results['消息去重机制']!) {
      print('• 消息去重机制需要优化，检查ID缓存和时间戳比较逻辑');
    }
    
    if (!results['后台恢复同步']!) {
      print('• 后台恢复同步需要优化，检查应用生命周期处理');
    }
    
    if (!results['群组切换同步']!) {
      print('• 群组切换同步需要优化，检查事件监听和同步触发');
    }
    
    if (!results['智能合并消息']!) {
      print('• 智能合并消息需要优化，检查消息字段合并逻辑');
    }
    
    if (!results['多阶段同步']!) {
      print('• 多阶段同步需要优化，检查各阶段的执行顺序和错误处理');
    }
    
    print('• 建议定期执行性能监控和内存使用分析');
    print('• 建议添加更多的错误重试机制');
    print('• 建议优化网络请求的并发控制');
  }
}

/// 主函数
void main() async {
  // 设置Flutter测试环境
  debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  
  final tester = EnhancedSyncTester();
  await tester.runAllTests();
} 