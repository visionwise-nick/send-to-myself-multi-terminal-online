#!/usr/bin/env dart

/// 🔧 消息去重修复验证测试
/// 测试修复后的去重逻辑是否解决了消息遗漏问题

import 'dart:math';

void main() {
  print('🔧 开始验证消息去重修复效果...');
  print('测试时间: ${DateTime.now()}');
  
  // 测试1: 时间解析失败处理
  testTimestampParsingFailure();
  
  // 测试2: 文件重发场景
  testFileResendScenario();
  
  // 测试3: 文本消息时间窗口
  testTextMessageTimeWindow();
  
  // 测试4: 服务器时间差异容忍
  testServerTimeDifference();
  
  print('\n🎉 所有去重修复测试完成！');
}

/// 测试时间解析失败的处理
void testTimestampParsingFailure() {
  print('\n=== 测试1: 时间解析失败处理 ===');
  
  // 模拟时间戳格式错误的消息
  final messagesWithBadTimestamp = [
    {
      'id': 'msg_001',
      'text': '正常消息',
      'timestamp': '2024-01-01T10:00:00Z',
      'senderId': 'user_1',
    },
    {
      'id': 'msg_002',
      'text': '时间戳错误的消息',
      'timestamp': 'invalid_timestamp', // 无效时间戳
      'senderId': 'user_1',
    },
    {
      'id': 'msg_003',
      'text': '另一条正常消息',
      'timestamp': '2024-01-01T10:02:00Z',
      'senderId': 'user_2',
    },
  ];
  
  print('📤 测试消息: ${messagesWithBadTimestamp.length} 条');
  
  // 模拟修复后的文本去重逻辑
  final processedMessages = <Map<String, dynamic>>[];
  
  for (final msg in messagesWithBadTimestamp) {
    final isDuplicate = simulateFixedTextDeduplication(processedMessages, msg);
    if (!isDuplicate) {
      processedMessages.add(msg);
      print('✅ 消息通过去重检查: ${msg['text']}');
    } else {
      print('⏭️ 消息被识别为重复: ${msg['text']}');
    }
  }
  
  // 验证结果
  if (processedMessages.length == 3) {
    print('✅ 时间解析失败处理测试通过！所有消息都被正确处理');
  } else {
    print('❌ 时间解析失败处理测试失败！');
  }
}

/// 测试文件重发场景
void testFileResendScenario() {
  print('\n=== 测试2: 文件重发场景 ===');
  
  final now = DateTime.now();
  final fileMessages = [
    {
      'id': 'file_001',
      'fileName': 'document.pdf',
      'fileSize': 1024000,
      'fileType': 'file',
      'timestamp': now.toIso8601String(),
      'senderId': 'user_1',
    },
    {
      'id': 'file_002',
      'fileName': 'document.pdf',
      'fileSize': 1024000,
      'fileType': 'file',
      'timestamp': now.add(Duration(seconds: 30)).toIso8601String(), // 30秒后
      'senderId': 'user_1',
    },
    {
      'id': 'file_003',
      'fileName': 'document.pdf',
      'fileSize': 1024000,
      'fileType': 'file',
      'timestamp': now.add(Duration(minutes: 6)).toIso8601String(), // 6分钟后
      'senderId': 'user_1',
    },
    {
      'id': 'file_004',
      'fileName': 'document.pdf',
      'fileSize': 1024000,
      'fileType': 'file',
      'timestamp': now.add(Duration(minutes: 2)).toIso8601String(), // 2分钟后
      'senderId': 'user_2', // 不同发送者
    },
  ];
  
  print('📤 测试文件消息: ${fileMessages.length} 条');
  
  final processedFiles = <Map<String, dynamic>>[];
  
  for (final msg in fileMessages) {
    final isDuplicate = simulateFixedFileDeduplication(processedFiles, msg);
    if (!isDuplicate) {
      processedFiles.add(msg);
      print('✅ 文件消息通过去重检查: ${msg['fileName']} (发送者: ${msg['senderId']})');
    } else {
      print('⏭️ 文件消息被识别为重复: ${msg['fileName']} (发送者: ${msg['senderId']})');
    }
  }
  
  // 验证结果：应该有3条消息通过（第1条、第3条6分钟后、第4条不同发送者）
  if (processedFiles.length == 3) {
    print('✅ 文件重发场景测试通过！正确识别了时间窗口内的重复和不同发送者');
  } else {
    print('❌ 文件重发场景测试失败！处理了 ${processedFiles.length} 条，预期 3 条');
  }
}

/// 测试文本消息时间窗口
void testTextMessageTimeWindow() {
  print('\n=== 测试3: 文本消息时间窗口 ===');
  
  final now = DateTime.now();
  final textMessages = [
    {
      'id': 'text_001',
      'text': '测试消息',
      'timestamp': now.toIso8601String(),
      'senderId': 'user_1',
    },
    {
      'id': 'text_002',
      'text': '测试消息',
      'timestamp': now.add(Duration(seconds: 5)).toIso8601String(), // 5秒后，应该被去重
      'senderId': 'user_1',
    },
    {
      'id': 'text_003',
      'text': '测试消息',
      'timestamp': now.add(Duration(seconds: 15)).toIso8601String(), // 15秒后，应该通过
      'senderId': 'user_1',
    },
  ];
  
  print('📤 测试文本消息: ${textMessages.length} 条');
  
  final processedTexts = <Map<String, dynamic>>[];
  
  for (final msg in textMessages) {
    final isDuplicate = simulateFixedTextDeduplication(processedTexts, msg);
    if (!isDuplicate) {
      processedTexts.add(msg);
      print('✅ 文本消息通过去重检查: ${msg['text']} (${msg['timestamp']})');
    } else {
      print('⏭️ 文本消息被识别为重复: ${msg['text']} (${msg['timestamp']})');
    }
  }
  
  // 验证结果：应该有2条消息通过（第1条和第3条）
  if (processedTexts.length == 2) {
    print('✅ 文本消息时间窗口测试通过！');
  } else {
    print('❌ 文本消息时间窗口测试失败！处理了 ${processedTexts.length} 条，预期 2 条');
  }
}

/// 测试服务器时间差异容忍
void testServerTimeDifference() {
  print('\n=== 测试4: 服务器时间差异容忍 ===');
  
  // 模拟增强同步管理器的时间戳比较
  final messageId = 'msg_time_test';
  final baseTime = DateTime.now();
  
  final testCases = [
    {
      'name': '完全相同时间',
      'time1': baseTime,
      'time2': baseTime,
      'shouldBeDuplicate': true,
    },
    {
      'name': '500毫秒差异',
      'time1': baseTime,
      'time2': baseTime.add(Duration(milliseconds: 500)),
      'shouldBeDuplicate': true,
    },
    {
      'name': '1.5秒差异',
      'time1': baseTime,
      'time2': baseTime.add(Duration(milliseconds: 1500)),
      'shouldBeDuplicate': false,
    },
  ];
  
  for (final testCase in testCases) {
    final time1 = testCase['time1'] as DateTime;
    final time2 = testCase['time2'] as DateTime;
    final expected = testCase['shouldBeDuplicate'] as bool;
    
    final isDuplicate = simulateFixedTimestampComparison(messageId, time1, time2);
    final result = isDuplicate == expected;
    
    print('${result ? '✅' : '❌'} ${testCase['name']}: $isDuplicate (预期: $expected)');
  }
}

/// 模拟修复后的文本去重逻辑
bool simulateFixedTextDeduplication(List<Map<String, dynamic>> existingMessages, Map<String, dynamic> newMessage) {
  final content = newMessage['text']?.trim();
  if (content == null || content.isEmpty) return false;
  
  final senderId = newMessage['senderId'];
  final messageTime = DateTime.tryParse(newMessage['timestamp'] ?? '');
  
  return existingMessages.any((existingMsg) {
    if (existingMsg['fileType'] != null) return false;
    if (existingMsg['text']?.trim() != content) return false;
    if (existingMsg['senderId'] != senderId) return false;
    
    if (messageTime != null) {
      try {
        final existingTime = DateTime.parse(existingMsg['timestamp']);
        final timeDiff = (messageTime.millisecondsSinceEpoch - existingTime.millisecondsSinceEpoch).abs();
        return timeDiff < 10000; // 10秒内认为是重复
      } catch (e) {
        // 🔧 修复：时间解析失败时，不认为是重复
        print('时间解析失败，允许通过: $content');
        return false;
      }
    }
    
    return false;
  });
}

/// 模拟修复后的文件去重逻辑
bool simulateFixedFileDeduplication(List<Map<String, dynamic>> existingMessages, Map<String, dynamic> newMessage) {
  final fileName = newMessage['fileName'];
  final fileSize = newMessage['fileSize'] ?? 0;
  final senderId = newMessage['senderId'];
  final messageTime = DateTime.tryParse(newMessage['timestamp'] ?? '');
  
  return existingMessages.any((existingMsg) {
    if (existingMsg['fileType'] == null) return false;
    if (existingMsg['fileName'] != fileName) return false;
    if ((existingMsg['fileSize'] ?? 0) != fileSize) return false;
    if (existingMsg['senderId'] != senderId) return false;
    
    if (messageTime != null) {
      try {
        final existingTime = DateTime.parse(existingMsg['timestamp']);
        final timeDiff = (messageTime.millisecondsSinceEpoch - existingTime.millisecondsSinceEpoch).abs();
        return timeDiff < 300000; // 5分钟内认为是重复
      } catch (e) {
        // 时间解析失败，但其他信息都相同，认为是重复
        return true;
      }
    }
    
    return false;
  });
}

/// 模拟修复后的时间戳比较
bool simulateFixedTimestampComparison(String messageId, DateTime timestamp1, DateTime timestamp2) {
  // 🔧 修复：允许1秒内的时间差异
  final timeDiff = (timestamp1.millisecondsSinceEpoch - timestamp2.millisecondsSinceEpoch).abs();
  return timeDiff < 1000; // 1秒内认为是同一条消息
} 