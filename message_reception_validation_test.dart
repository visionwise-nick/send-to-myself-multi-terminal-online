// 消息接收验证测试
// 验证简化后的消息处理逻辑是否符合用户要求：
// 1. 接收消息：只检查ID重复，其他情况都接收
// 2. 发送消息：100%过滤

import 'dart:convert';

class MessageReceptionTest {
  // 模拟当前设备ID
  static const String currentDeviceId = "device_123";
  
  // 模拟消息列表（显示中的消息）
  static List<Map<String, dynamic>> displayMessages = [];
  
  // 测试消息接收逻辑
  static void testMessageReception() {
    print('=== 消息接收逻辑测试 ===\n');
    
    // 清空测试环境
    displayMessages.clear();
    
    // 测试用例1：正常接收消息
    print('测试1：正常接收其他设备的消息');
    final message1 = {
      'id': 'msg_001',
      'content': '来自其他设备的消息',
      'sourceDeviceId': 'device_456',
    };
    final result1 = shouldReceiveMessage(message1);
    print('结果：${result1 ? "✅ 接收" : "❌ 拒绝"}');
    if (result1) displayMessages.add(message1);
    print('');
    
    // 测试用例2：100%过滤本机发送的消息
    print('测试2：过滤本机发送的消息');
    final message2 = {
      'id': 'msg_002', 
      'content': '本机发送的消息',
      'sourceDeviceId': currentDeviceId,
    };
    final result2 = shouldReceiveMessage(message2);
    print('结果：${result2 ? "❌ 错误接收" : "✅ 正确过滤"}');
    print('');
    
    // 测试用例3：重复消息ID检查
    print('测试3：重复消息ID检查');
    final message3 = {
      'id': 'msg_001', // 与第一条消息ID相同
      'content': '重复ID的消息',
      'sourceDeviceId': 'device_789',
    };
    final result3 = shouldReceiveMessage(message3);
    print('结果：${result3 ? "❌ 错误接收重复" : "✅ 正确过滤重复"}');
    print('');
    
    // 测试用例4：无效sourceDeviceId也要接收
    print('测试4：无效sourceDeviceId的消息接收');
    final message4 = {
      'id': 'msg_004',
      'content': '无效sourceDeviceId的消息',
      'sourceDeviceId': null,
    };
    final result4 = shouldReceiveMessage(message4);
    print('结果：${result4 ? "✅ 接收" : "❌ 错误拒绝"}');
    if (result4) displayMessages.add(message4);
    print('');
    
    // 测试用例5：空字符串sourceDeviceId也要接收
    print('测试5：空字符串sourceDeviceId的消息接收');
    final message5 = {
      'id': 'msg_005',
      'content': '空sourceDeviceId的消息',
      'sourceDeviceId': '',
    };
    final result5 = shouldReceiveMessage(message5);
    print('结果：${result5 ? "✅ 接收" : "❌ 错误拒绝"}');
    if (result5) displayMessages.add(message5);
    print('');
    
    // 测试用例6：未知格式的消息也要接收（只要ID不重复）
    print('测试6：未知格式消息接收');
    final message6 = {
      'id': 'msg_006',
      'unknownField': '未知字段',
      'sourceDeviceId': 'unknown_device',
    };
    final result6 = shouldReceiveMessage(message6);
    print('结果：${result6 ? "✅ 接收" : "❌ 错误拒绝"}');
    if (result6) displayMessages.add(message6);
    print('');
    
    // 显示最终统计
    print('=== 测试总结 ===');
    print('显示列表中的消息数量: ${displayMessages.length}');
    print('消息ID列表:');
    for (final msg in displayMessages) {
      print('  - ${msg['id']}: ${msg['content'] ?? msg['unknownField']}');
    }
    
    // 验证核心原则
    print('\n=== 核心原则验证 ===');
    final hasOwnMessage = displayMessages.any((msg) => msg['sourceDeviceId'] == currentDeviceId);
    print('是否包含本机消息: ${hasOwnMessage ? "❌ 错误" : "✅ 正确"}');
    
    final hasDuplicateIds = displayMessages.map((msg) => msg['id']).toSet().length != displayMessages.length;
    print('是否有重复ID: ${hasDuplicateIds ? "❌ 错误" : "✅ 正确"}');
    
    print('\n测试完成！');
  }
  
  // 简化的消息接收判断逻辑（基于用户要求）
  static bool shouldReceiveMessage(Map<String, dynamic> message) {
    final messageId = message['id'];
    if (messageId == null) {
      print('  - 消息ID为空，拒绝');
      return false;
    }
    
    final messageIdString = messageId.toString();
    
    // 核心原则1：100%过滤本机发送的消息
    final sourceDeviceId = message['sourceDeviceId'];
    if (sourceDeviceId == currentDeviceId) {
      print('  - 本机发送的消息，100%过滤');
      return false;
    }
    
    // 核心原则2：接收消息只检查ID重复
    final isDuplicate = displayMessages.any((msg) => msg['id']?.toString() == messageIdString);
    if (isDuplicate) {
      print('  - 发现重复消息ID，过滤');
      return false;
    }
    
    // 其他所有情况都接收
    print('  - 通过检查，接收消息');
    return true;
  }
}

void main() {
  MessageReceptionTest.testMessageReception();
} 
 
 
 
 
 
 
 
 
 
 
 
 
 