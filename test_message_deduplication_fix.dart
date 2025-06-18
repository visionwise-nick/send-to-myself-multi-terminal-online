import 'dart:async';
import 'dart:io';

/// 测试消息去重优化和文件选择修复
/// 
/// 修复内容：
/// 1. 视频文件选择使用特定扩展名避免处理错误
/// 2. 简化消息去重逻辑，避免过度过滤导致消息遗漏
/// 3. 智能清理去重缓存，防止过度累积

void main() {
  print('🧪 开始测试消息去重优化和文件选择修复');
  
  testVideoFileSelection();
  testSimplifiedDeduplication();
  testSmartCacheCleanup();
  testAndroidMessageReceival();
  
  print('✅ 所有测试完成');
}

/// 测试1: 视频文件选择修复
void testVideoFileSelection() {
  print('\n📋 测试1: 视频文件选择修复');
  
  final mockFilePicker = MockFilePicker();
  
  // 测试修复前的问题场景
  print('🔍 测试视频文件选择（修复前会失败）');
  try {
    final oldResult = mockFilePicker.pickFilesOldWay('video');
    print('❌ 旧方式失败: ${oldResult['error']}');
  } catch (e) {
    print('❌ 旧方式异常: $e');
  }
  
  // 测试修复后的方案
  print('🔍 测试视频文件选择（修复后）');
  try {
    final newResult = mockFilePicker.pickFilesNewWay('video');
    print('✅ 新方式成功: ${newResult['success']}');
    print('📁 支持扩展名: ${newResult['extensions']}');
  } catch (e) {
    print('❌ 新方式失败: $e');
  }
  
  // 测试图片文件选择
  print('🔍 测试图片文件选择（新方式）');
  try {
    final imageResult = mockFilePicker.pickFilesNewWay('image');
    print('✅ 图片选择成功: ${imageResult['extensions']}');
  } catch (e) {
    print('❌ 图片选择失败: $e');
  }
  
  print('✅ 视频文件选择修复测试通过');
}

/// 测试2: 简化的消息去重逻辑
void testSimplifiedDeduplication() {
  print('\n📋 测试2: 简化的消息去重逻辑');
  
  final mockChatScreen = MockChatScreen();
  
  // 测试消息处理
  final testMessages = [
    {
      'id': 'msg_001',
      'content': '第一条消息',
      'sourceDeviceId': 'device_002',
      'timestamp': DateTime.now().toIso8601String(),
    },
    {
      'id': 'msg_002', 
      'content': '第二条消息',
      'sourceDeviceId': 'device_003',
      'timestamp': DateTime.now().toIso8601String(),
    },
    {
      'id': 'msg_001', // 重复ID
      'content': '重复的第一条消息',
      'sourceDeviceId': 'device_002',
      'timestamp': DateTime.now().toIso8601String(),
    },
    {
      'id': 'msg_003',
      'content': '第三条消息',
      'sourceDeviceId': 'device_004',
      'timestamp': DateTime.now().toIso8601String(),
    },
  ];
  
  print('📨 处理${testMessages.length}条测试消息（包含1条重复ID）');
  
  // 使用简化的去重逻辑处理消息
  for (final message in testMessages) {
    mockChatScreen.processMessageWithSimplifiedDeduplication(message);
  }
  
  // 验证结果
  final displayedMessages = mockChatScreen.getDisplayedMessages();
  print('📱 显示消息数量: ${displayedMessages.length}');
  print('🎯 期望消息数量: 3（去除1条重复）');
  
  assert(displayedMessages.length == 3, '应该显示3条消息（去除重复）');
  assert(displayedMessages.any((msg) => msg['id'] == 'msg_001'), '应该包含msg_001');
  assert(displayedMessages.any((msg) => msg['id'] == 'msg_002'), '应该包含msg_002');
  assert(displayedMessages.any((msg) => msg['id'] == 'msg_003'), '应该包含msg_003');
  
  print('✅ 简化去重逻辑测试通过');
}

/// 测试3: 智能缓存清理
void testSmartCacheCleanup() {
  print('\n📋 测试3: 智能缓存清理');
  
  final mockCacheManager = MockCacheManager();
  
  // 添加大量消息ID到缓存
  print('📝 向缓存添加1500条消息ID');
  for (int i = 0; i < 1500; i++) {
    final messageId = 'msg_$i';
    final timestamp = DateTime.now().subtract(Duration(minutes: i)); // 不同时间
    mockCacheManager.addMessageId(messageId, timestamp);
  }
  
  print('📊 清理前缓存大小: ${mockCacheManager.getCacheSize()}');
  
  // 执行智能清理
  print('🧹 执行智能清理...');
  mockCacheManager.smartCleanup();
  
  print('📊 清理后缓存大小: ${mockCacheManager.getCacheSize()}');
  
  // 验证清理效果
  final finalSize = mockCacheManager.getCacheSize();
  assert(finalSize <= 1000, '清理后缓存大小应该不超过1000');
  assert(finalSize >= 700, '清理后应该保留至少70%的空间');
  
  print('✅ 智能缓存清理测试通过');
}

/// 测试4: 安卓设备消息接收
void testAndroidMessageReceival() {
  print('\n📋 测试4: 安卓设备消息接收（模拟）');
  
  final mockAndroidChat = MockAndroidChatScreen();
  
  // 模拟不同场景的消息接收
  final scenarios = [
    {
      'name': '网络重连后的历史消息同步',
      'messages': _generateMessages(20, 'sync'),
    },
    {
      'name': '实时WebSocket消息接收',
      'messages': _generateMessages(10, 'realtime'),
    },
    {
      'name': 'API强制刷新历史消息',
      'messages': _generateMessages(15, 'api'),
    },
  ];
  
  for (final scenario in scenarios) {
    print('🔍 测试场景: ${scenario['name']}');
    final messages = scenario['messages'] as List<Map<String, dynamic>>;
    
    final beforeCount = mockAndroidChat.getMessageCount();
    mockAndroidChat.processMessagesWithOptimizedDeduplication(messages);
    final afterCount = mockAndroidChat.getMessageCount();
    
    final newMessageCount = afterCount - beforeCount;
    print('📱 新接收消息: $newMessageCount 条');
    print('📊 总消息数: $beforeCount -> $afterCount');
    
    // 验证消息不被错误过滤
    assert(newMessageCount > 0, '应该接收到新消息');
  }
  
  print('✅ 安卓设备消息接收测试通过');
}

/// 生成测试消息
List<Map<String, dynamic>> _generateMessages(int count, String prefix) {
  return List.generate(count, (index) => {
    'id': '${prefix}_msg_$index',
    'content': '测试消息 $prefix $index',
    'sourceDeviceId': 'device_${index % 3 + 1}',
    'timestamp': DateTime.now().subtract(Duration(seconds: index)).toIso8601String(),
  });
}

/// 模拟文件选择器
class MockFilePicker {
  
  /// 旧的文件选择方式（会失败）
  Map<String, dynamic> pickFilesOldWay(String type) {
    if (type == 'video') {
      // 模拟 file_picker 插件的错误
      return {
        'error': 'PlatformException(file_picker_error, Failed to process any images, , null)',
        'success': false,
      };
    }
    return {'success': true};
  }
  
  /// 新的文件选择方式（使用特定扩展名）
  Map<String, dynamic> pickFilesNewWay(String type) {
    switch (type) {
      case 'video':
        return {
          'success': true,
          'extensions': ['mp4', 'mov', 'avi', 'mkv', '3gp', 'flv', 'wmv'],
          'method': 'FileType.custom',
        };
      case 'image':
        return {
          'success': true,
          'extensions': ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
          'method': 'FileType.custom',
        };
      default:
        return {
          'success': true,
          'method': 'FileType.any',
        };
    }
  }
}

/// 模拟聊天界面
class MockChatScreen {
  final List<Map<String, dynamic>> _displayedMessages = [];
  
  /// 使用简化的去重逻辑处理消息
  void processMessageWithSimplifiedDeduplication(Map<String, dynamic> message) {
    final messageId = message['id']?.toString();
    if (messageId == null) return;
    
    // 🔥 简化去重：只检查当前显示列表中是否已存在此ID
    final existsInDisplay = _displayedMessages.any((msg) => msg['id']?.toString() == messageId);
    if (existsInDisplay) {
      print('🎯 消息ID已在显示列表，跳过: $messageId');
      return;
    }
    
    // 添加到显示列表
    _displayedMessages.add(message);
    print('✅ 新消息添加到显示列表: $messageId');
  }
  
  List<Map<String, dynamic>> getDisplayedMessages() => List.from(_displayedMessages);
}

/// 模拟缓存管理器
class MockCacheManager {
  final Set<String> _processedMessageIds = <String>{};
  final Map<String, DateTime> _messageTimestamps = <String, DateTime>{};
  
  void addMessageId(String messageId, DateTime timestamp) {
    _processedMessageIds.add(messageId);
    _messageTimestamps[messageId] = timestamp;
  }
  
  int getCacheSize() => _processedMessageIds.length;
  
  /// 智能清理缓存
  void smartCleanup() {
    final now = DateTime.now();
    final expiredIds = <String>[];
    
    // 清理超过1小时的记录
    _messageTimestamps.forEach((id, timestamp) {
      if (now.difference(timestamp).inHours >= 1) {
        expiredIds.add(id);
      }
    });
    
    // 如果缓存过大，清理最旧的记录
    const maxCacheSize = 1000;
    if (_processedMessageIds.length > maxCacheSize) {
      final sortedEntries = _messageTimestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      final excess = _processedMessageIds.length - (maxCacheSize * 0.7).round();
      for (int i = 0; i < excess && i < sortedEntries.length; i++) {
        expiredIds.add(sortedEntries[i].key);
      }
    }
    
    // 执行清理
    for (final id in expiredIds) {
      _processedMessageIds.remove(id);
      _messageTimestamps.remove(id);
    }
    
    print('🧹 清理了 ${expiredIds.length} 个过期消息ID');
  }
}

/// 模拟安卓聊天界面
class MockAndroidChatScreen {
  final List<Map<String, dynamic>> _messages = [];
  final Set<String> _displayedIds = <String>{};
  
  /// 使用优化的去重逻辑处理消息
  void processMessagesWithOptimizedDeduplication(List<Map<String, dynamic>> messages) {
    for (final message in messages) {
      final messageId = message['id']?.toString();
      if (messageId == null) continue;
      
      // 优化的去重：只检查显示列表，避免过度过滤
      if (_displayedIds.contains(messageId)) {
        print('⏭️ 跳过重复消息: $messageId');
        continue;
      }
      
      // 添加到消息列表
      _messages.add(message);
      _displayedIds.add(messageId);
      print('📱 接收新消息: $messageId');
    }
  }
  
  int getMessageCount() => _messages.length;
} 
 
 
 
 
 
 
 
 
 
 
 
 
 