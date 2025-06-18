/// 消息误拦截问题分析
/// 
/// 分析当前消息处理流程中可能导致接收消息被误拦截的各种情况

import 'dart:convert';

class MessageInterceptionAnalysis {
  
  /// 分析1：实时消息处理路径的潜在问题
  static void analyzeRealTimeMessageFlow() {
    print('\n=== 分析1：实时消息处理路径 ===');
    
    print('📥 实时消息接收流程:');
    print('1. WebSocket接收消息 -> _handleIncomingMessage');
    print('2. 检查消息ID是否为空');
    print('3. 🚨 检查_processedMessageIds (可能误拦截)');
    print('4. 检查是否属于当前对话');
    print('5. 调用_addMessageToChat');
    print('6. 在_addMessageToChat中再次检查消息是否已存在');
    
    print('\n🚨 潜在问题点:');
    print('- 第3步：_processedMessageIds可能包含历史消息ID');
    print('- 第6步：重复检查可能过于严格');
    
    // 模拟场景
    final processedIds = {'msg_001', 'msg_002', 'msg_003'};
    final incomingMessage = {'id': 'msg_002', 'content': '重要消息'};
    
    if (processedIds.contains(incomingMessage['id'])) {
      print('❌ 实时消息被误拦截: ${incomingMessage['id']}');
      print('   原因：ID已在处理缓存中（可能来自历史同步）');
    }
  }
  
  /// 分析2：_addMessageToChat中的拦截逻辑
  static void analyzeAddMessageToChatFlow() {
    print('\n=== 分析2：_addMessageToChat拦截逻辑 ===');
    
    print('📥 _addMessageToChat处理流程:');
    print('1. 检查messageId是否为空');
    print('2. 检查消息是否已存在于_messages列表');
    print('3. 🚨 异步获取设备ID，检查是否本机消息');
    print('4. 添加到界面');
    
    print('\n🚨 潜在问题点:');
    print('- 异步设备ID获取可能导致时序问题');
    print('- 本机消息过滤逻辑可能有误判');
    
    // 模拟异步问题
    print('\n🔍 模拟异步时序问题:');
    print('时刻T1: 接收到消息，开始异步获取设备ID');
    print('时刻T2: 相同消息从另一路径到达');
    print('时刻T3: 第一个异步操作完成，添加消息');
    print('时刻T4: 第二个异步操作完成，检测到重复，跳过');
    print('结果: 可能出现竞态条件');
  }
  
  /// 分析3：设备ID判断逻辑的准确性
  static void analyzeDeviceIdLogic() {
    print('\n=== 分析3：设备ID判断逻辑 ===');
    
    // 模拟不同的消息来源场景
    final currentDeviceId = 'device_A';
    final testMessages = [
      {
        'id': 'msg_001',
        'sourceDeviceId': 'device_B', // 其他设备发送，应该接收
        'content': '来自设备B的消息'
      },
      {
        'id': 'msg_002', 
        'sourceDeviceId': 'device_A', // 本机发送，应该过滤
        'content': '本机发送的消息'
      },
      {
        'id': 'msg_003',
        'sourceDeviceId': null, // 异常情况：缺少sourceDeviceId
        'content': '缺少设备ID的消息'
      },
      {
        'id': 'msg_004',
        'sourceDeviceId': '', // 异常情况：空字符串
        'content': '空设备ID的消息'
      }
    ];
    
    print('🔍 测试各种设备ID场景:');
    for (final msg in testMessages) {
      final sourceDeviceId = msg['sourceDeviceId'];
      final shouldFilter = sourceDeviceId == currentDeviceId;
      final isValidSource = sourceDeviceId != null && sourceDeviceId.toString().isNotEmpty;
      
      print('消息${msg['id']}: sourceDeviceId=$sourceDeviceId');
      print('  应过滤: $shouldFilter');
      print('  有效来源: $isValidSource');
      
      // 🚨 发现问题：缺少对无效sourceDeviceId的处理
      if (!isValidSource && !shouldFilter) {
        print('  ⚠️  警告：无效sourceDeviceId可能导致误判');
      }
    }
  }
  
  /// 分析4：消息ID类型和比较问题
  static void analyzeMessageIdComparison() {
    print('\n=== 分析4：消息ID类型和比较问题 ===');
    
    // 模拟不同类型的消息ID
    final mixedMessageIds = [
      {'id': 'string_id_001', 'type': 'String'},
      {'id': 123456, 'type': 'int'},
      {'id': 123.456, 'type': 'double'},
      {'id': null, 'type': 'null'},
    ];
    
    final processedIds = <String>{'string_id_001', '123456'};
    
    print('🔍 测试不同类型ID的比较:');
    for (final msgData in mixedMessageIds) {
      final messageId = msgData['id'];
      final idString = messageId?.toString();
      final inProcessed = processedIds.contains(idString);
      
      print('消息ID: $messageId (${msgData['type']})');
      print('  转换为字符串: "$idString"');
      print('  在处理缓存中: $inProcessed');
      
      // 🚨 潜在问题：类型转换可能导致误匹配
      if (messageId is int && idString == '123456') {
        print('  ⚠️  警告：数字ID与字符串ID匹配，可能误拦截');
      }
    }
  }
  
  /// 分析5：并发消息处理的竞态条件
  static void analyzeConcurrencyIssues() {
    print('\n=== 分析5：并发消息处理竞态条件 ===');
    
    print('🔍 并发场景分析:');
    print('场景1: 历史同步与实时消息同时到达');
    print('  - 历史同步：从API获取消息列表，包含msg_100');
    print('  - 实时消息：WebSocket推送msg_100');
    print('  - 问题：两者可能并发处理同一消息');
    
    print('\n场景2: 快速连续消息接收');
    print('  - 设备B快速发送msg_200, msg_201, msg_202');
    print('  - 设备A同时处理这三条消息');
    print('  - 问题：异步处理可能导致顺序混乱或重复');
    
    print('\n场景3: 群组切换期间的消息处理');
    print('  - 用户从群组A切换到群组B');
    print('  - 切换过程中收到群组A的消息');
    print('  - 问题：消息可能被分配到错误的对话');
    
    // 模拟竞态条件
    print('\n🔍 模拟竞态条件:');
    final sharedMessageList = <Map<String, dynamic>>[];
    final processedIds = <String>{};
    
    // 模拟两个并发操作
    void processMessage1() {
      final msg = {'id': 'msg_race', 'content': '竞态消息'};
      if (!processedIds.contains(msg['id'])) {
        processedIds.add(msg['id']!);
        sharedMessageList.add(msg);
        print('  操作1: 添加消息 ${msg['id']}');
      } else {
        print('  操作1: 检测到重复，跳过 ${msg['id']}');
      }
    }
    
    void processMessage2() {
      final msg = {'id': 'msg_race', 'content': '竞态消息'};
      if (!sharedMessageList.any((m) => m['id'] == msg['id'])) {
        sharedMessageList.add(msg);
        print('  操作2: 添加消息 ${msg['id']}');
      } else {
        print('  操作2: 检测到重复，跳过 ${msg['id']}');
      }
    }
    
    // 并发执行（模拟）
    processMessage1();
    processMessage2();
    
    print('结果: 消息列表长度 = ${sharedMessageList.length}');
    if (sharedMessageList.length > 1) {
      print('❌ 检测到重复消息！');
    }
  }
  
  /// 分析6：历史消息同步的过滤逻辑
  static void analyzeHistorySyncFiltering() {
    print('\n=== 分析6：历史消息同步过滤逻辑 ===');
    
    print('📥 历史同步的过滤步骤:');
    print('1. 过滤本机发送的消息 (sourceDeviceId)');
    print('2. 检查是否已在显示列表中');
    print('3. 🚨 问题：不检查实时处理缓存，可能导致重复');
    
    // 模拟历史同步场景
    final currentDeviceId = 'device_A';
    final displayMessages = [
      {'id': 'msg_001', 'text': '已显示消息1'},
    ];
    final processedIds = {'msg_002', 'msg_003'}; // 实时处理过的ID
    
    final historyMessages = [
      {'id': 'msg_001', 'sourceDeviceId': 'device_B', 'content': '重复消息'},
      {'id': 'msg_002', 'sourceDeviceId': 'device_B', 'content': '实时处理过的消息'},
      {'id': 'msg_004', 'sourceDeviceId': 'device_B', 'content': '新消息'},
    ];
    
    print('\n🔍 历史同步过滤测试:');
    for (final msg in historyMessages) {
      final messageId = msg['id']!;
      final sourceDeviceId = msg['sourceDeviceId'];
      
      // 1. 过滤本机消息
      if (sourceDeviceId == currentDeviceId) {
        print('${messageId}: 本机消息，过滤');
        continue;
      }
      
      // 2. 检查显示列表
      final inDisplay = displayMessages.any((m) => m['id'] == messageId);
      if (inDisplay) {
        print('${messageId}: 已在显示列表，跳过');
        continue;
      }
      
      // 3. 检查实时处理缓存（当前逻辑不检查）
      final inProcessed = processedIds.contains(messageId);
      if (inProcessed) {
        print('${messageId}: ⚠️  在实时缓存中，但历史同步不检查，可能重复');
      }
      
      print('${messageId}: ✅ 通过过滤，将添加到显示列表');
    }
  }
  
  /// 运行所有分析
  static void runAllAnalysis() {
    print('🔍 消息误拦截问题深度分析');
    print('=' * 60);
    
    analyzeRealTimeMessageFlow();
    analyzeAddMessageToChatFlow();
    analyzeDeviceIdLogic();
    analyzeMessageIdComparison();
    analyzeConcurrencyIssues();
    analyzeHistorySyncFiltering();
    
    print('\n' + '=' * 60);
    print('📋 发现的潜在问题总结:');
    print('1. ❌ 实时消息可能被历史同步的ID缓存误拦截');
    print('2. ❌ 异步设备ID获取可能导致时序问题'); 
    print('3. ❌ 无效sourceDeviceId缺少处理逻辑');
    print('4. ❌ 消息ID类型转换可能导致误匹配');
    print('5. ❌ 并发处理存在竞态条件风险');
    print('6. ❌ 历史同步不检查实时缓存，可能重复处理');
    
    print('\n🔧 推荐修复方案:');
    print('1. 分离实时消息和历史消息的去重机制');
    print('2. 改进设备ID获取为同步方式或预加载');
    print('3. 增加sourceDeviceId有效性检查');
    print('4. 统一消息ID为字符串类型处理');
    print('5. 增加消息处理锁机制防止竞态');
    print('6. 优化历史同步的去重逻辑');
  }
}

void main() {
  MessageInterceptionAnalysis.runAllAnalysis();
} 
 
 
 
 
 
 
 
 
 
 
 
 
 