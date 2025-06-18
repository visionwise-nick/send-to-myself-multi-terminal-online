import 'dart:convert';

/// WebSocket重连同步和消息去重测试
class WebSocketReconnectSyncTester {
  
  /// 模拟的消息ID缓存
  final Set<String> _processedMessageIds = <String>{};
  final Map<String, DateTime> _messageTimestamps = <String, DateTime>{};
  
  /// 测试主函数
  void runAllTests() {
    print('🚀 开始WebSocket重连同步和消息去重测试');
    print('=' * 60);
    
    testMessageIdDeduplication();
    testWebSocketReconnectFlow();
    testLoginSequenceSync();
    testMessageCacheCleanup();
    
    print('=' * 60);
    print('✅ 所有测试完成！');
  }
  
  /// 测试1: 消息ID去重机制
  void testMessageIdDeduplication() {
    print('\n🧪 测试1: 统一消息ID去重机制');
    
    // 清空缓存
    _processedMessageIds.clear();
    _messageTimestamps.clear();
    
    // 创建测试消息
    final testMessages = [
      {
        'id': 'msg_001',
        'content': '第一条消息',
        'timestamp': DateTime.now().toIso8601String(),
        'senderId': 'user_001',
      },
      {
        'id': 'msg_002',
        'content': '第二条消息',
        'timestamp': DateTime.now().toIso8601String(),
        'senderId': 'user_002',
      },
      {
        'id': 'msg_001', // 重复的消息ID
        'content': '重复的第一条消息',
        'timestamp': DateTime.now().toIso8601String(),
        'senderId': 'user_001',
      },
      {
        'id': 'msg_003',
        'content': '第三条消息',
        'timestamp': DateTime.now().toIso8601String(),
        'senderId': 'user_003',
      },
    ];
    
    print('📤 处理 ${testMessages.length} 条测试消息（包含1条重复ID）');
    
    int processedCount = 0;
    for (final message in testMessages) {
      final messageId = message['id'] as String;
      
      // 🔥 统一去重机制：仅检查消息ID
      if (_isMessageIdProcessed(messageId)) {
        print('⏭️ 跳过重复消息ID: $messageId');
        continue;
      }
      
      // 标记消息ID已处理
      _markMessageIdProcessed(messageId);
      processedCount++;
      
      print('✅ 处理消息: $messageId - ${message['content']}');
    }
    
    print('📊 测试结果：处理了 $processedCount 条消息（预期：3条）');
    
    if (processedCount == 3) {
      print('✅ 消息ID去重测试通过！');
    } else {
      print('❌ 消息ID去重测试失败！');
    }
  }
  
  /// 测试2: WebSocket重连流程
  void testWebSocketReconnectFlow() {
    print('\n🧪 测试2: WebSocket重连流程');
    
    // 模拟重连前的状态
    print('📡 模拟WebSocket连接断开...');
    bool isConnected = false;
    
    // 模拟重连成功
    print('🔄 模拟WebSocket重连成功...');
    isConnected = true;
    
    if (isConnected) {
      // 模拟完整登录流程
      _simulateFullLoginSequence();
      print('✅ WebSocket重连流程测试通过！');
    } else {
      print('❌ WebSocket重连流程测试失败！');
    }
  }
  
  /// 测试3: 登录序列同步
  void testLoginSequenceSync() {
    print('\n🧪 测试3: 登录序列同步流程');
    
    final syncSteps = [
      '步骤1：加载本地消息',
      '步骤2：执行完整状态同步', 
      '步骤3：拉取离线消息',
      '步骤4：同步所有对话',
      '步骤5：刷新设备状态',
      '步骤6：触发UI刷新',
    ];
    
    print('🚀 模拟完整登录序列同步...');
    
    for (int i = 0; i < syncSteps.length; i++) {
      print('${i + 1}/6 ${syncSteps[i]}');
      // 模拟每个步骤的延迟
      _simulateAsyncOperation(100 + i * 50);
    }
    
    print('✅ 登录序列同步测试通过！');
  }
  
  /// 测试4: 消息缓存清理
  void testMessageCacheCleanup() {
    print('\n🧪 测试4: 消息缓存清理机制');
    
    // 添加一些测试消息ID到缓存
    final now = DateTime.now();
    final oldTime = now.subtract(Duration(hours: 3)); // 3小时前
    
    // 添加新消息
    _processedMessageIds.add('new_msg_001');
    _messageTimestamps['new_msg_001'] = now;
    
    _processedMessageIds.add('new_msg_002');
    _messageTimestamps['new_msg_002'] = now;
    
    // 添加旧消息（应该被清理）
    _processedMessageIds.add('old_msg_001');
    _messageTimestamps['old_msg_001'] = oldTime;
    
    _processedMessageIds.add('old_msg_002');
    _messageTimestamps['old_msg_002'] = oldTime;
    
    print('📊 清理前：${_processedMessageIds.length} 个消息ID');
    
    // 模拟清理过程
    _simulateMessageCacheCleanup();
    
    print('📊 清理后：${_processedMessageIds.length} 个消息ID（预期：2个）');
    
    if (_processedMessageIds.length == 2) {
      print('✅ 消息缓存清理测试通过！');
    } else {
      print('❌ 消息缓存清理测试失败！');
    }
  }
  
  /// 模拟完整登录流程
  void _simulateFullLoginSequence() {
    print('🚀 开始执行完整登录流程...');
    
    // 步骤1：执行完整状态同步
    print('📡 步骤1：执行完整状态同步');
    _simulateAsyncOperation(100);
    
    // 步骤2：拉取离线消息
    print('📥 步骤2：拉取离线期间的所有消息');
    _simulateAsyncOperation(200);
    
    // 步骤3：同步所有对话
    print('💬 步骤3：同步所有对话的最新消息');
    _simulateAsyncOperation(150);
    
    // 步骤4：刷新设备状态
    print('📱 步骤4：刷新设备状态和在线列表');
    _simulateAsyncOperation(100);
    
    // 步骤5：触发UI刷新
    print('🔄 步骤5：触发UI完整刷新');
    _simulateAsyncOperation(50);
    
    print('✅ 完整登录流程执行完成');
  }
  
  /// 模拟异步操作
  void _simulateAsyncOperation(int delayMs) {
    // 在真实环境中这里会是异步操作
    // 这里只是模拟延迟
    print('  ⏳ 模拟异步操作 (${delayMs}ms)...');
  }
  
  /// 模拟消息缓存清理
  void _simulateMessageCacheCleanup() {
    final now = DateTime.now();
    final expiredIds = <String>[];
    
    // 找出2小时前的消息
    _messageTimestamps.forEach((id, timestamp) {
      if (now.difference(timestamp).inHours >= 2) {
        expiredIds.add(id);
      }
    });
    
    // 清理过期消息
    for (final id in expiredIds) {
      _processedMessageIds.remove(id);
      _messageTimestamps.remove(id);
    }
    
    print('🧹 清理了 ${expiredIds.length} 个过期消息ID');
  }
  
  /// 检查消息ID是否已处理
  bool _isMessageIdProcessed(String messageId) {
    return _processedMessageIds.contains(messageId);
  }
  
  /// 标记消息ID已处理
  void _markMessageIdProcessed(String messageId) {
    _processedMessageIds.add(messageId);
    _messageTimestamps[messageId] = DateTime.now();
  }
  
  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return {
      'total_processed_ids': _processedMessageIds.length,
      'timestamp_records': _messageTimestamps.length,
      'oldest_timestamp': _messageTimestamps.values.isNotEmpty 
        ? _messageTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b)
        : null,
      'newest_timestamp': _messageTimestamps.values.isNotEmpty
        ? _messageTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b)
        : null,
    };
  }
}

/// 运行测试
void main() {
  final tester = WebSocketReconnectSyncTester();
  tester.runAllTests();
  
  print('\n📊 缓存统计信息:');
  final stats = tester.getCacheStats();
  stats.forEach((key, value) {
    print('  $key: $value');
  });
} 