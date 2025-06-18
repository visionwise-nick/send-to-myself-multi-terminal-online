// 消息群组归属测试
// 验证消息是否正确分配到对应的群组/私聊中，防止消息串群

import 'dart:convert';

class MessageGroupSeparationTest {
  
  // 测试消息归属检查逻辑
  static void testMessageConversationCheck() {
    print('=== 消息群组归属测试 ===\n');
    
    // 测试场景1：群组消息归属检查
    print('测试1：群组消息归属检查');
    testGroupMessageBelonging();
    print('');
    
    // 测试场景2：私聊消息归属检查  
    print('测试2：私聊消息归属检查');
    testPrivateMessageBelonging();
    print('');
    
    // 测试场景3：混合场景 - 防止消息串群
    print('测试3：防止消息串群');
    testMessageCrossTalk();
    print('');
    
    print('测试完成！');
  }
  
  // 测试群组消息归属
  static void testGroupMessageBelonging() {
    // 模拟当前群组对话
    final currentGroupConversation = {
      'type': 'group',
      'groupData': {'id': 'group_123'},
    };
    
    // 测试用例：属于当前群组的消息
    final belongingGroupMessage = {
      'id': 'msg_001',
      'groupId': 'group_123',
      'content': '属于当前群组的消息',
      'sourceDeviceId': 'device_456'
    };
    
    final result1 = isMessageForCurrentConversation(
      belongingGroupMessage, 
      true, 
      currentGroupConversation
    );
    print('群组消息归属检查 - 正确群组: ${result1 ? "✅ 通过" : "❌ 错误拒绝"}');
    
    // 测试用例：不属于当前群组的消息
    final wrongGroupMessage = {
      'id': 'msg_002',
      'groupId': 'group_456', // 不同的群组ID
      'content': '属于其他群组的消息',
      'sourceDeviceId': 'device_789'
    };
    
    final result2 = isMessageForCurrentConversation(
      wrongGroupMessage, 
      true, 
      currentGroupConversation
    );
    print('群组消息归属检查 - 错误群组: ${result2 ? "❌ 错误接收" : "✅ 正确拒绝"}');
    
    // 测试用例：私聊消息发送到群组对话
    final privateMsgInGroup = {
      'id': 'msg_003',
      'sourceDeviceId': 'device_456',
      'targetDeviceId': 'device_123',
      'content': '私聊消息错误进入群组',
    };
    
    final result3 = isMessageForCurrentConversation(
      privateMsgInGroup, 
      false, 
      currentGroupConversation
    );
    print('私聊消息进入群组检查: ${result3 ? "❌ 错误接收" : "✅ 正确拒绝"}');
  }
  
  // 测试私聊消息归属
  static void testPrivateMessageBelonging() {
    // 模拟当前私聊对话
    final currentPrivateConversation = {
      'type': 'private',
      'deviceData': {'id': 'device_456'},
    };
    
    // 测试用例：来自对话设备的消息
    final fromTargetDevice = {
      'id': 'msg_004',
      'sourceDeviceId': 'device_456',
      'targetDeviceId': 'device_123',
      'content': '来自目标设备的消息',
    };
    
    final result1 = isMessageForCurrentConversation(
      fromTargetDevice, 
      false, 
      currentPrivateConversation
    );
    print('私聊消息归属检查 - 来自目标设备: ${result1 ? "✅ 通过" : "❌ 错误拒绝"}');
    
    // 测试用例：发送给对话设备的消息
    final toTargetDevice = {
      'id': 'msg_005',
      'sourceDeviceId': 'device_123',
      'targetDeviceId': 'device_456',
      'content': '发送给目标设备的消息',
    };
    
    final result2 = isMessageForCurrentConversation(
      toTargetDevice, 
      false, 
      currentPrivateConversation
    );
    print('私聊消息归属检查 - 发送给目标设备: ${result2 ? "✅ 通过" : "❌ 错误拒绝"}');
    
    // 测试用例：与当前对话无关的私聊消息
    final unrelatedPrivateMsg = {
      'id': 'msg_006',
      'sourceDeviceId': 'device_789',
      'targetDeviceId': 'device_abc',
      'content': '无关的私聊消息',
    };
    
    final result3 = isMessageForCurrentConversation(
      unrelatedPrivateMsg, 
      false, 
      currentPrivateConversation
    );
    print('私聊消息归属检查 - 无关消息: ${result3 ? "❌ 错误接收" : "✅ 正确拒绝"}');
    
    // 测试用例：群组消息发送到私聊对话
    final groupMsgInPrivate = {
      'id': 'msg_007',
      'groupId': 'group_123',
      'content': '群组消息错误进入私聊',
      'sourceDeviceId': 'device_456'
    };
    
    final result4 = isMessageForCurrentConversation(
      groupMsgInPrivate, 
      true, 
      currentPrivateConversation
    );
    print('群组消息进入私聊检查: ${result4 ? "❌ 错误接收" : "✅ 正确拒绝"}');
  }
  
  // 测试防止消息串群的综合场景
  static void testMessageCrossTalk() {
    print('模拟多群组环境下的消息分离...');
    
    // 群组A的对话环境
    final groupAConversation = {
      'type': 'group',
      'groupData': {'id': 'group_A'},
    };
    
    // 群组B的对话环境  
    final groupBConversation = {
      'type': 'group',
      'groupData': {'id': 'group_B'},
    };
    
    // 私聊对话环境
    final privateConversation = {
      'type': 'private',
      'deviceData': {'id': 'device_target'},
    };
    
    // 创建各种消息
    final messages = [
      {
        'id': 'msg_A1',
        'groupId': 'group_A',
        'content': '群组A的消息1',
        'sourceDeviceId': 'device_1'
      },
      {
        'id': 'msg_A2', 
        'groupId': 'group_A',
        'content': '群组A的消息2',
        'sourceDeviceId': 'device_2'
      },
      {
        'id': 'msg_B1',
        'groupId': 'group_B',
        'content': '群组B的消息1',
        'sourceDeviceId': 'device_3'
      },
      {
        'id': 'msg_P1',
        'sourceDeviceId': 'device_target',
        'targetDeviceId': 'device_current',
        'content': '私聊消息1'
      },
      {
        'id': 'msg_P2',
        'sourceDeviceId': 'device_other',
        'targetDeviceId': 'device_someone',
        'content': '其他私聊消息'
      }
    ];
    
    // 测试群组A环境下的消息分离
    print('📱 群组A环境下的消息筛选:');
    for (final msg in messages) {
      final isGroupMsg = msg['groupId'] != null;
      final shouldReceive = isMessageForCurrentConversation(msg, isGroupMsg, groupAConversation);
      final msgType = isGroupMsg ? '群组' : '私聊';
      final result = shouldReceive ? '✅接收' : '❌拒绝';
      print('  ${msg['id']} ($msgType): $result');
    }
    
    // 测试群组B环境下的消息分离
    print('📱 群组B环境下的消息筛选:');
    for (final msg in messages) {
      final isGroupMsg = msg['groupId'] != null;
      final shouldReceive = isMessageForCurrentConversation(msg, isGroupMsg, groupBConversation);
      final msgType = isGroupMsg ? '群组' : '私聊';
      final result = shouldReceive ? '✅接收' : '❌拒绝';
      print('  ${msg['id']} ($msgType): $result');
    }
    
    // 测试私聊环境下的消息分离
    print('📱 私聊环境下的消息筛选:');
    for (final msg in messages) {
      final isGroupMsg = msg['groupId'] != null;
      final shouldReceive = isMessageForCurrentConversation(msg, isGroupMsg, privateConversation);
      final msgType = isGroupMsg ? '群组' : '私聊';
      final result = shouldReceive ? '✅接收' : '❌拒绝';
      print('  ${msg['id']} ($msgType): $result');
    }
  }
  
  // 消息归属检查逻辑（复制自实际代码）
  static bool isMessageForCurrentConversation(
    Map<String, dynamic> message, 
    bool isGroupMessage, 
    Map<String, dynamic> conversation
  ) {
    if (isGroupMessage) {
      // 群组消息
      if (conversation['type'] != 'group') return false;
      final groupId = message['groupId'];
      final conversationGroupId = conversation['groupData']?['id'];
      return groupId == conversationGroupId;
    } else {
      // 私聊消息
      if (conversation['type'] == 'group') return false;
      final sourceDeviceId = message['sourceDeviceId'];
      final targetDeviceId = message['targetDeviceId'];
      final conversationDeviceId = conversation['deviceData']?['id'];
      return sourceDeviceId == conversationDeviceId || targetDeviceId == conversationDeviceId;
    }
  }
}

void main() {
  MessageGroupSeparationTest.testMessageConversationCheck();
} 