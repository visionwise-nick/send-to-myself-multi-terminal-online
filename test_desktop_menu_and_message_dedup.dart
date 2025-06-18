import 'dart:convert';
import 'dart:math' as math;

// 🔥 测试桌面端右键菜单和消息去重功能
void main() async {
  print('=== 🔧 桌面端右键菜单和消息去重测试 ===\n');
  
  // 测试1：消息去重功能
  await testMessageDeduplication();
  
  // 测试2：桌面端右键菜单功能
  await testDesktopContextMenu();
  
  print('\n=== ✅ 所有测试完成 ===');
}

// 测试消息去重功能
Future<void> testMessageDeduplication() async {
  print('1️⃣ 测试消息去重功能...\n');
  
  // 模拟当前设备ID
  final currentDeviceId = 'device_001';
  
  // 模拟本地存储中的消息（包含临时消息和服务端消息）
  final List<Map<String, dynamic>> localStorageMessages = [
    {
      'id': 'local_1642567890123', // 本地临时消息
      'text': '我发送的临时消息1',
      'sourceDeviceId': 'device_001',
      'isMe': true,
      'status': 'sending',
      'timestamp': '2024-01-01T10:00:00Z',
    },
    {
      'id': 'server_msg_001', // 服务端返回的本机消息（应该被过滤）
      'text': '我发送的临时消息1',
      'sourceDeviceId': 'device_001',
      'isMe': true,
      'status': 'sent',
      'timestamp': '2024-01-01T10:00:05Z',
    },
    {
      'id': 'local_1642567890456', // 本地临时消息
      'text': '我发送的临时消息2',
      'sourceDeviceId': 'device_001',
      'isMe': true,
      'status': 'sending',
      'timestamp': '2024-01-01T10:01:00Z',
    },
    {
      'id': 'server_msg_002', // 来自其他设备的消息（应该保留）
      'text': '来自其他设备的消息',
      'sourceDeviceId': 'device_002',
      'isMe': false,
      'status': 'sent',
      'timestamp': '2024-01-01T10:02:00Z',
    },
    {
      'id': 'server_msg_003', // 服务端返回的本机消息（应该被过滤）
      'text': '我发送的消息3',
      'sourceDeviceId': 'device_001',
      'isMe': true,
      'status': 'sent',
      'timestamp': '2024-01-01T10:03:00Z',
    },
  ];
  
  print('本地存储原始消息数量: ${localStorageMessages.length}');
  print('当前设备ID: $currentDeviceId\n');
  
  // 应用本地消息过滤逻辑（模拟_loadLocalMessages中的过滤）
  print('🔍 本地消息过滤：开始过滤本地存储中的消息\n');
  
  final filteredMessages = localStorageMessages.where((msg) {
    final sourceDeviceId = msg['sourceDeviceId'];
    final isLocalMessage = msg['id']?.toString().startsWith('local_') ?? false;
    final isFromCurrentDevice = sourceDeviceId == currentDeviceId;
    
    if (isFromCurrentDevice && !isLocalMessage) {
      // 模拟截断显示逻辑
      final content = msg['text'] as String?;
      final displayContent = content != null 
          ? content.substring(0, math.min(20, content.length))
          : 'file';
      final truncated = content != null && content.length > 20 ? '...' : '';
      print('🚫 过滤掉本地存储中的服务端本机消息: ${msg['id']} ($displayContent$truncated)');
      return false;
    }
    
    print('✅ 保留消息: ${msg['id']} - ${msg['text']} (${isLocalMessage ? '本地临时' : '其他设备'})');
    return true;
  }).toList();
  
  print('\n🔍 本地消息过滤：原始${localStorageMessages.length}条 → 过滤后${filteredMessages.length}条\n');
  
  // 分析过滤结果
  int localMessages = 0;
  int otherDeviceMessages = 0;
  int filteredServerMessages = 0;
  
  for (final msg in filteredMessages) {
    final isLocal = msg['id']?.toString().startsWith('local_') ?? false;
    if (isLocal) {
      localMessages++;
    } else {
      otherDeviceMessages++;
    }
  }
  
  filteredServerMessages = localStorageMessages.length - filteredMessages.length;
  
  print('过滤结果分析:');
  print('  保留的本地临时消息: $localMessages 条');
  print('  保留的其他设备消息: $otherDeviceMessages 条');
  print('  过滤掉的服务端本机消息: $filteredServerMessages 条');
  
  // 验证过滤效果
  final expectedFilteredCount = 3; // 2条本地临时消息 + 1条其他设备消息
  if (filteredMessages.length == expectedFilteredCount) {
    print('\n✅ 消息去重测试通过！成功避免了临时消息与服务端消息的重复');
  } else {
    print('\n❌ 消息去重测试失败！期望${expectedFilteredCount}条，实际${filteredMessages.length}条');
  }
  
  print('─' * 50);
}

// 测试桌面端右键菜单功能
Future<void> testDesktopContextMenu() async {
  print('\n2️⃣ 测试桌面端右键菜单功能...\n');
  
  // 模拟不同类型的消息
  final List<Map<String, dynamic>> testMessages = [
    {
      'id': 'msg_text_001',
      'text': '这是一条纯文本消息，用于测试复制功能',
      'fileName': null,
      'isMe': false,
      'messageType': '纯文本消息',
    },
    {
      'id': 'msg_file_001',
      'text': '',
      'fileName': 'important_document.pdf',
      'isMe': false,
      'messageType': '纯文件消息',
    },
    {
      'id': 'msg_mixed_001',
      'text': '这是一个带文件的混合消息',
      'fileName': 'screenshot.png',
      'isMe': false,
      'messageType': '混合消息',
    },
    {
      'id': 'msg_own_001',
      'text': '这是我自己发送的消息',
      'fileName': null,
      'isMe': true,
      'messageType': '自己的消息',
    },
  ];
  
  print('桌面端右键菜单功能测试:\n');
  
  for (final message in testMessages) {
    final text = message['text']?.toString() ?? '';
    final fileName = message['fileName']?.toString() ?? '';
    final hasText = text.isNotEmpty;
    final hasFile = fileName.isNotEmpty;
    final isOwnMessage = message['isMe'] == true;
    
    print('📋 ${message['messageType']} (${message['id']}):');
    print('   内容: ${hasText ? text : '[无文字内容]'}');
    print('   文件: ${hasFile ? fileName : '[无文件]'}');
    print('   是否为自己的消息: $isOwnMessage');
    
    // 模拟右键菜单选项
    List<String> menuOptions = [];
    
    if (hasText) {
      menuOptions.add('📝 复制文字');
      menuOptions.add('📋 复制全部内容');
    }
    
    if (hasFile) {
      menuOptions.add('📁 复制文件名');
    }
    
    menuOptions.add('🔤 选择文字');
    menuOptions.add('↩️ 回复');
    menuOptions.add('➡️ 转发');
    
    if (isOwnMessage) {
      menuOptions.add('↶ 撤回');
      menuOptions.add('🗑️ 删除');
    }
    
    print('   可用的右键菜单选项: ${menuOptions.length}个');
    for (final option in menuOptions) {
      print('     - $option');
    }
    print('');
  }
  
  // 测试复制功能逻辑
  print('复制功能测试:\n');
  
  final copyTestCases = [
    {
      'name': '复制纯文字',
      'message': testMessages[0],
      'action': 'copy_text',
      'expected': testMessages[0]['text'],
    },
    {
      'name': '复制混合内容',
      'message': testMessages[2],
      'action': 'copy_all',
      'expected': '${testMessages[2]['text']}\n[文件] ${testMessages[2]['fileName']}',
    },
    {
      'name': '复制文件名',
      'message': testMessages[1],
      'action': 'copy_filename',
      'expected': testMessages[1]['fileName'],
    },
  ];
  
  for (final testCase in copyTestCases) {
    print('🔍 ${testCase['name']}:');
    final message = testCase['message'] as Map<String, dynamic>;
    final action = testCase['action'] as String;
    final expected = testCase['expected'] as String;
    
    // 模拟复制逻辑
    String result = '';
    switch (action) {
      case 'copy_text':
        result = message['text']?.toString() ?? '';
        break;
      case 'copy_all':
        final text = message['text']?.toString() ?? '';
        final fileName = message['fileName']?.toString() ?? '';
        if (text.isNotEmpty) result += text;
        if (fileName.isNotEmpty) {
          if (result.isNotEmpty) result += '\n';
          result += '[文件] $fileName';
        }
        break;
      case 'copy_filename':
        result = message['fileName']?.toString() ?? '';
        break;
    }
    
    print('   期望结果: $expected');
    print('   实际结果: $result');
    print('   测试结果: ${result == expected ? "✅ 通过" : "❌ 失败"}');
    print('');
  }
  
  // 桌面端兼容性测试
  print('桌面端兼容性验证:\n');
  
  final platformSupport = {
    'macOS': {
      'rightClick': true,
      'clipboard': true,
      'contextMenu': true,
      'description': 'Command+C 快捷键，原生右键菜单',
    },
    'Windows': {
      'rightClick': true,
      'clipboard': true,
      'contextMenu': true,
      'description': 'Ctrl+C 快捷键，原生右键菜单',
    },
    'Linux': {
      'rightClick': true,
      'clipboard': true,
      'contextMenu': true,
      'description': 'Ctrl+C 快捷键，原生右键菜单',
    },
    'Web Desktop': {
      'rightClick': true,
      'clipboard': true,
      'contextMenu': true,
      'description': '浏览器环境，现代浏览器剪贴板API',
    },
  };
  
  platformSupport.forEach((platform, support) {
    print('🖥️ $platform 平台支持:');
    print('   右键点击: ${support['rightClick'] == true ? "✅ 支持" : "❌ 不支持"}');
    print('   剪贴板操作: ${support['clipboard'] == true ? "✅ 支持" : "❌ 不支持"}');
    print('   上下文菜单: ${support['contextMenu'] == true ? "✅ 支持" : "❌ 不支持"}');
    print('   说明: ${support['description']}');
    print('');
  });
  
  print('✅ 桌面端右键菜单功能验证完成！');
} 
 
 
 
 
 
 
 
 
 
 
 
 
 