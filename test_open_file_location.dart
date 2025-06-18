import 'dart:io';
import 'dart:math' as math;

// 🔥 测试桌面端打开文件位置功能
void main() async {
  print('=== 🔧 桌面端打开文件位置功能测试 ===\n');
  
  // 测试1：文件位置检测功能
  await testFileLocationDetection();
  
  // 测试2：跨平台命令测试
  await testCrossPlatformCommands();
  
  // 测试3：右键菜单选项测试
  await testContextMenuOptions();
  
  print('\n=== ✅ 所有测试完成 ===');
}

// 测试文件位置检测功能
Future<void> testFileLocationDetection() async {
  print('1️⃣ 测试文件位置检测功能...\n');
  
  // 模拟不同类型的文件消息
  final List<Map<String, dynamic>> testMessages = [
    {
      'id': 'msg_file_001',
      'text': '这是一个图片文件',
      'fileName': 'screenshot.png',
      'filePath': '/Users/test/Documents/screenshot.png',
      'messageType': '有效文件路径消息',
    },
    {
      'id': 'msg_file_002',
      'text': '',
      'fileName': 'document.pdf',
      'filePath': '', // 空路径
      'messageType': '空文件路径消息',
    },
    {
      'id': 'msg_file_003',
      'text': '视频文件',
      'fileName': 'video.mp4',
      'filePath': '/invalid/path/video.mp4', // 无效路径
      'messageType': '无效文件路径消息',
    },
    {
      'id': 'msg_text_001',
      'text': '这是纯文本消息',
      'fileName': null,
      'filePath': null,
      'messageType': '纯文本消息',
    },
    {
      'id': 'msg_file_004',
      'text': '下载的文件',
      'fileName': 'app.zip',
      'filePath': '/Users/test/Downloads/app.zip',
      'messageType': '下载文件消息',
    },
  ];
  
  print('文件位置检测结果:\n');
  
  for (final message in testMessages) {
    final text = message['text']?.toString() ?? '';
    final fileName = message['fileName']?.toString() ?? '';
    final filePath = message['filePath']?.toString() ?? '';
    final hasText = text.isNotEmpty;
    final hasFile = fileName.isNotEmpty;
    
    // 模拟文件存在性检查（实际代码中使用 File(filePath).exists()）
    final fileExists = filePath.isNotEmpty && !filePath.contains('/invalid/');
    final hasLocalFile = hasFile && filePath.isNotEmpty && fileExists;
    
    print('📋 ${message['messageType']} (${message['id']}):');
    print('   文字内容: ${hasText ? text : '[无文字]'}');
    print('   文件名: ${hasFile ? fileName : '[无文件]'}');
    print('   文件路径: ${filePath.isNotEmpty ? filePath : '[无路径]'}');
    print('   文件存在: ${fileExists ? "✅" : "❌"}');
    print('   显示"打开文件位置": ${hasLocalFile ? "✅ 显示" : "❌ 不显示"}');
    
    if (hasLocalFile) {
      print('   🔍 文件详情:');
      print('     - 文件夹: ${_getParentDirectory(filePath)}');
      print('     - 文件大小: ${_getFileSize(filePath)}');
      print('     - 文件类型: ${_getFileExtension(fileName)}');
    }
    print('');
  }
  
  // 统计结果
  int totalMessages = testMessages.length;
  int fileMessages = testMessages.where((msg) => 
    (msg['fileName']?.toString() ?? '').isNotEmpty).length;
  int validFileMessages = testMessages.where((msg) {
    final fileName = msg['fileName']?.toString() ?? '';
    final filePath = msg['filePath']?.toString() ?? '';
    final fileExists = filePath.isNotEmpty && !filePath.contains('/invalid/');
    return fileName.isNotEmpty && filePath.isNotEmpty && fileExists;
  }).length;
  
  print('统计结果:');
  print('  总消息数: $totalMessages 条');
  print('  文件消息数: $fileMessages 条');
  print('  有效文件消息数: $validFileMessages 条');
  print('  "打开文件位置"显示率: ${(validFileMessages / totalMessages * 100).toStringAsFixed(1)}%');
  
  print('─' * 50);
}

// 测试跨平台命令
Future<void> testCrossPlatformCommands() async {
  print('\n2️⃣ 测试跨平台打开文件位置命令...\n');
  
  final testFilePath = '/Users/test/Documents/example.pdf';
  
  // 不同平台的命令配置
  final Map<String, Map<String, dynamic>> platformCommands = {
    'macOS': {
      'command': 'open',
      'args': ['-R', testFilePath],
      'description': '使用 Finder 显示并选中文件',
      'supported': true,
    },
    'Windows': {
      'command': 'explorer',
      'args': ['/select,', testFilePath.replaceAll('/', '\\')],
      'description': '使用资源管理器选中文件',
      'supported': true,
    },
    'Linux': {
      'command': 'xdg-open',
      'args': [_getParentDirectory(testFilePath)],
      'description': '使用默认文件管理器打开父目录',
      'supported': true,
    },
    'Web': {
      'command': '显示对话框',
      'args': ['显示文件路径信息'],
      'description': '在对话框中显示文件路径',
      'supported': true,
    },
  };
  
  print('跨平台命令配置:\n');
  
  platformCommands.forEach((platform, config) {
    print('🖥️ $platform 平台:');
    print('   命令: ${config['command']}');
    print('   参数: ${config['args'].join(' ')}');
    print('   说明: ${config['description']}');
    print('   支持状态: ${config['supported'] ? "✅ 支持" : "❌ 不支持"}');
    
    // 模拟命令执行结果
    if (config['supported'] == true) {
      print('   预期效果: ');
      switch (platform) {
        case 'macOS':
          print('     - 打开 Finder');
          print('     - 定位到文件并高亮选中');
          print('     - 显示文件在文件夹中的位置');
          break;
        case 'Windows':
          print('     - 打开资源管理器');
          print('     - 导航到文件所在目录');
          print('     - 选中目标文件');
          break;
        case 'Linux':
          print('     - 打开默认文件管理器');
          print('     - 显示文件所在目录');
          print('     - 用户可手动查找文件');
          break;
        case 'Web':
          print('     - 显示文件路径对话框');
          print('     - 用户可复制文件路径');
          print('     - 提供文件路径信息');
          break;
      }
    }
    print('');
  });
  
  // 错误处理测试
  print('错误处理场景:\n');
  
  final errorScenarios = [
    {
      'scenario': '文件路径为空',
      'expected': '显示"文件路径无效"提示',
      'handling': '提前检查，不执行命令',
    },
    {
      'scenario': '文件不存在',
      'expected': '显示"文件不存在"提示',
      'handling': '检查文件存在性，不执行命令',
    },
    {
      'scenario': '命令执行失败',
      'expected': '显示具体错误信息',
      'handling': 'try-catch 捕获异常',
    },
    {
      'scenario': '权限不足',
      'expected': '显示权限错误提示',
      'handling': '系统级错误处理',
    },
  ];
  
  for (final scenario in errorScenarios) {
    print('❌ ${scenario['scenario']}:');
    print('   预期结果: ${scenario['expected']}');
    print('   处理方式: ${scenario['handling']}');
    print('');
  }
  
  print('✅ 跨平台命令测试完成！');
  print('─' * 50);
}

// 测试右键菜单选项
Future<void> testContextMenuOptions() async {
  print('\n3️⃣ 测试右键菜单选项...\n');
  
  // 模拟不同情况下的右键菜单
  final List<Map<String, dynamic>> menuTestCases = [
    {
      'name': '纯文本消息',
      'hasText': true,
      'hasFile': false,
      'hasLocalFile': false,
      'isOwnMessage': false,
    },
    {
      'name': '纯文件消息（本地文件存在）',
      'hasText': false,
      'hasFile': true,
      'hasLocalFile': true,
      'isOwnMessage': false,
    },
    {
      'name': '混合消息（本地文件存在）',
      'hasText': true,
      'hasFile': true,
      'hasLocalFile': true,
      'isOwnMessage': false,
    },
    {
      'name': '文件消息（本地文件不存在）',
      'hasText': false,
      'hasFile': true,
      'hasLocalFile': false,
      'isOwnMessage': false,
    },
    {
      'name': '自己的文件消息（本地文件存在）',
      'hasText': true,
      'hasFile': true,
      'hasLocalFile': true,
      'isOwnMessage': true,
    },
  ];
  
  print('右键菜单选项测试:\n');
  
  for (final testCase in menuTestCases) {
    final hasText = testCase['hasText'] as bool;
    final hasFile = testCase['hasFile'] as bool;
    final hasLocalFile = testCase['hasLocalFile'] as bool;
    final isOwnMessage = testCase['isOwnMessage'] as bool;
    
    print('📋 ${testCase['name']}:');
    
    // 构建菜单选项列表
    List<String> menuOptions = [];
    
    if (hasText) {
      menuOptions.add('📝 复制文字');
      menuOptions.add('📋 复制全部内容');
    }
    
    if (hasFile) {
      menuOptions.add('📁 复制文件名');
    }
    
    if (hasLocalFile) {
      menuOptions.add('🗂️ 打开文件位置'); // 新增功能
    }
    
    menuOptions.add('🔤 选择文字');
    menuOptions.add('↩️ 回复');
    menuOptions.add('➡️ 转发');
    
    if (isOwnMessage) {
      menuOptions.add('↶ 撤回');
      menuOptions.add('🗑️ 删除');
    }
    
    print('   可用选项 (${menuOptions.length}个):');
    for (final option in menuOptions) {
      print('     - $option');
    }
    
    // 重点关注"打开文件位置"选项
    if (hasLocalFile) {
      print('   🔍 "打开文件位置"功能:');
      print('     - 显示条件: 有文件 + 本地文件存在');
      print('     - 功能描述: 在文件管理器中定位并显示文件');
      print('     - 用户体验: 直接跳转到文件位置，便于后续操作');
    } else if (hasFile) {
      print('   ⚠️ "打开文件位置"不可用:');
      print('     - 原因: 本地文件不存在或路径无效');
      print('     - 替代方案: 可通过"复制文件名"查看文件信息');
    }
    
    print('');
  }
  
  // 功能优先级分析
  print('功能优先级分析:\n');
  
  final featurePriority = [
    {
      'feature': '复制文字',
      'priority': '高',
      'usage': '文本消息的基础功能',
      'target': '所有文本消息',
    },
    {
      'feature': '打开文件位置',
      'priority': '高',
      'usage': '文件管理的核心功能',
      'target': '本地文件消息',
    },
    {
      'feature': '复制文件名',
      'priority': '中',
      'usage': '文件信息获取',
      'target': '所有文件消息',
    },
    {
      'feature': '回复/转发',
      'priority': '中',
      'usage': '消息交互功能',
      'target': '所有消息',
    },
    {
      'feature': '撤回/删除',
      'priority': '低',
      'usage': '消息管理功能',
      'target': '自己的消息',
    },
  ];
  
  for (final feature in featurePriority) {
    print('${_getPriorityIcon(feature['priority'] as String)} ${feature['feature']}:');
    print('   优先级: ${feature['priority']}');
    print('   用途: ${feature['usage']}');
    print('   目标: ${feature['target']}');
    print('');
  }
  
  print('✅ 右键菜单选项测试完成！');
}

// 辅助函数
String _getParentDirectory(String filePath) {
  final parts = filePath.split('/');
  if (parts.length > 1) {
    return parts.sublist(0, parts.length - 1).join('/');
  }
  return '/';
}

String _getFileSize(String filePath) {
  // 模拟文件大小
  final random = math.Random();
  final sizeKB = random.nextInt(10000) + 1;
  if (sizeKB < 1024) {
    return '${sizeKB}KB';
  } else {
    return '${(sizeKB / 1024).toStringAsFixed(1)}MB';
  }
}

String _getFileExtension(String fileName) {
  final parts = fileName.split('.');
  if (parts.length > 1) {
    return parts.last.toUpperCase();
  }
  return 'Unknown';
}

String _getPriorityIcon(String priority) {
  switch (priority) {
    case '高':
      return '🔴';
    case '中':
      return '🟡';
    case '低':
      return '🟢';
    default:
      return '⚪';
  }
} 
 
 
 
 
 
 
 
 
 
 
 
 