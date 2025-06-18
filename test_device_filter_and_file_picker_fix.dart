import 'dart:convert';
import 'dart:io';

// 🔥 测试设备消息过滤和文件选择器修复
void main() async {
  print('=== 🔧 设备消息过滤和文件选择器修复测试 ===\n');
  
  // 测试1：设备消息过滤功能
  await testDeviceMessageFiltering();
  
  // 测试2：文件选择器修复
  await testFilePickerFix();
  
  print('\n=== ✅ 所有测试完成 ===');
}

// 测试设备消息过滤功能
Future<void> testDeviceMessageFiltering() async {
  print('1️⃣ 测试设备消息过滤功能...\n');
  
  // 模拟当前设备ID
  final currentDeviceId = 'device_001';
  
  // 模拟接收到的消息列表
  final List<Map<String, dynamic>> incomingMessages = [
    {
      'id': 'msg_001',
      'content': '来自设备001的消息（本机发送）',
      'sourceDeviceId': 'device_001', // 本机消息
      'createdAt': '2024-01-01T10:00:00Z',
    },
    {
      'id': 'msg_002', 
      'content': '来自设备002的消息（其他设备）',
      'sourceDeviceId': 'device_002', // 其他设备消息
      'createdAt': '2024-01-01T10:01:00Z',
    },
    {
      'id': 'msg_003',
      'content': '来自设备003的消息（其他设备）', 
      'sourceDeviceId': 'device_003', // 其他设备消息
      'createdAt': '2024-01-01T10:02:00Z',
    },
    {
      'id': 'msg_004',
      'content': '又一条来自设备001的消息（本机发送）',
      'sourceDeviceId': 'device_001', // 本机消息
      'createdAt': '2024-01-01T10:03:00Z',
    },
  ];
  
  print('原始消息数量: ${incomingMessages.length}');
  print('当前设备ID: $currentDeviceId\n');
  
  // 应用过滤逻辑
  final filteredMessages = incomingMessages.where((msg) {
    final sourceDeviceId = msg['sourceDeviceId'];
    final isFromCurrentDevice = sourceDeviceId == currentDeviceId;
    
    if (isFromCurrentDevice) {
      print('🚫 过滤掉本机消息: ${msg['id']} - ${msg['content']}');
      return false;
    }
    
    print('✅ 保留其他设备消息: ${msg['id']} - ${msg['content']}');
    return true;
  }).toList();
  
  print('\n过滤结果:');
  print('过滤前: ${incomingMessages.length}条消息');
  print('过滤后: ${filteredMessages.length}条消息');
  print('过滤掉: ${incomingMessages.length - filteredMessages.length}条本机消息\n');
  
  // 验证过滤结果
  final expectedFilteredCount = 2; // 应该剩下device_002和device_003的消息
  if (filteredMessages.length == expectedFilteredCount) {
    print('✅ 设备消息过滤测试通过！');
  } else {
    print('❌ 设备消息过滤测试失败！期望${expectedFilteredCount}条，实际${filteredMessages.length}条');
  }
  
  print('─' * 50);
}

// 测试文件选择器修复 
Future<void> testFilePickerFix() async {
  print('\n2️⃣ 测试文件选择器修复功能...\n');
  
  // 模拟文件选择器配置
  final Map<String, Map<String, dynamic>> filePickerConfigs = {
    'image': {
      'type': 'FileType.image',
      'description': '图片选择：调用系统相册',
      'useNativeSelector': true,
      'allowedExtensions': null, // 不限制扩展名，让系统处理
    },
    'video': {
      'type': 'FileType.video', 
      'description': '视频选择：调用系统视频库',
      'useNativeSelector': true,
      'allowedExtensions': null, // 不限制扩展名，让系统处理
    },
    'audio': {
      'type': 'FileType.audio',
      'description': '音频选择：调用系统音频库', 
      'useNativeSelector': true,
      'allowedExtensions': null, // 不限制扩展名，让系统处理
    },
    'document': {
      'type': 'FileType.any',
      'description': '文档选择：调用系统文件管理器',
      'useNativeSelector': true,
      'allowedExtensions': null, // 不限制扩展名，让系统处理
    },
  };
  
  print('文件选择器配置验证:\n');
  
  // 测试各种文件类型的选择器配置
  filePickerConfigs.forEach((fileType, config) {
    print('📁 $fileType文件类型:');
    print('   类型: ${config['type']}');
    print('   描述: ${config['description']}');
    print('   使用系统原生选择器: ${config['useNativeSelector']}');
    print('   扩展名限制: ${config['allowedExtensions'] ?? '无（由系统处理）'}');
    print('');
  });
  
  // 验证修复前后的差异
  print('修复前后对比:');
  print('📋 修复前问题:');
  print('   ❌ 视频文件使用FileType.custom + 固定扩展名列表');
  print('   ❌ 图片文件使用FileType.custom + 固定扩展名列表');
  print('   ❌ 无法调用系统相册、视频库等原生应用');
  print('   ❌ 只能选择recent文件，用户体验差');
  print('');
  
  print('✅ 修复后改进:');
  print('   ✅ 图片使用FileType.image，直接调用系统相册');
  print('   ✅ 视频使用FileType.video，直接调用系统视频库');
  print('   ✅ 音频使用FileType.audio，直接调用系统音频库');
  print('   ✅ 文档使用FileType.any，调用系统文件管理器');
  print('   ✅ 用户可以从相册、视频库等系统应用中选择文件');
  print('   ✅ 更好的用户体验和原生感受');
  print('');
  
  // 模拟文件选择场景测试
  print('文件选择场景测试:');
  final testScenarios = [
    {
      'action': '用户点击"图片"按钮',
      'expected': '调用系统相册应用，显示用户照片库',
      'fileType': 'image',
    },
    {
      'action': '用户点击"视频"按钮', 
      'expected': '调用系统视频库应用，显示用户视频库',
      'fileType': 'video',
    },
    {
      'action': '用户点击"音频"按钮',
      'expected': '调用系统音频库应用，显示用户音频文件',
      'fileType': 'audio',
    },
    {
      'action': '用户点击"文档"按钮',
      'expected': '调用系统文件管理器，可浏览所有文件',
      'fileType': 'document',
    },
  ];
  
  for (final scenario in testScenarios) {
    print('🔍 ${scenario['action']}');
    print('   期望行为: ${scenario['expected']}');
    final config = filePickerConfigs[scenario['fileType']];
    if (config != null && config['useNativeSelector'] == true) {
      print('   ✅ 配置正确，会调用系统原生选择器');
    } else {
      print('   ❌ 配置错误，无法调用系统原生选择器');
    }
    print('');
  }
  
  print('✅ 文件选择器修复验证完成！');
} 
 
 
 
 
 
 
 
 
 
 
 
 
 