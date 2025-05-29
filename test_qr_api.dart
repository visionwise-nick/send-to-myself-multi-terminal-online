import 'dart:convert';
import 'dart:io';

// 测试二维码生成和加入群组的API调用
void main() async {
  print('🔥 测试二维码加入群组功能');
  
  // 模拟API响应数据
  final generateQRResponse = {
    'success': true,
    'message': '已为群组"我的设备群组"生成邀请码',
    'groupId': 'group-id-12345',
    'groupName': '我的设备群组',
    'joinCode': 'A1B2C3D4',
    'expiresAt': DateTime.now().add(Duration(minutes: 10)).toIso8601String(),
    'expiryMinutes': 10,
    'qrCodeDataURL': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...',
    'inviterDeviceId': 'device-id-67890',
    'securityNote': '邀请码10分钟内有效，一次性使用'
  };
  
  print('✅ 模拟生成邀请码响应:');
  print(jsonEncode(generateQRResponse));
  
  // 按照API文档构造二维码数据
  final qrData = {
    'type': 'sendtomyself_group_join',
    'version': '1.0',
    'groupId': generateQRResponse['groupId'],
    'groupName': generateQRResponse['groupName'],
    'joinCode': generateQRResponse['joinCode'],
    'inviterDeviceId': generateQRResponse['inviterDeviceId'],
    'expiresAt': generateQRResponse['expiresAt'],
    'createdAt': DateTime.now().toIso8601String(),
  };
  
  final qrDataString = jsonEncode(qrData);
  print('✅ 生成的二维码数据:');
  print(qrDataString);
  
  // 测试二维码解析
  print('\n🔥 测试二维码解析');
  try {
    final parsed = jsonDecode(qrDataString);
    
    // 验证格式
    bool isValid = parsed['type'] == 'sendtomyself_group_join' && 
                   parsed['version'] == '1.0' &&
                   parsed.containsKey('groupId') &&
                   parsed.containsKey('joinCode') && 
                   parsed.containsKey('expiresAt') &&
                   parsed['joinCode'] != null;
    
    if (isValid) {
      print('✅ 二维码格式验证通过');
      
      // 检查过期时间
      final expiresAt = DateTime.parse(parsed['expiresAt']);
      if (DateTime.now().isBefore(expiresAt)) {
        print('✅ 二维码未过期');
      } else {
        print('❌ 二维码已过期');
      }
      
      final joinCode = parsed['joinCode'].toString();
      final groupId = parsed['groupId'].toString();
      
      // 验证加入码长度
      if (joinCode.length >= 4 && joinCode.length <= 20) {
        print('✅ 加入码长度验证通过: ${joinCode.length}位');
        
        // 模拟加入群组请求
        final joinRequest = {
          'joinCode': joinCode,
          'groupId': groupId, // 可选的额外验证
        };
        
        print('✅ 加入群组请求数据:');
        print(jsonEncode(joinRequest));
      } else {
        print('❌ 加入码长度验证失败: ${joinCode.length}位');
      }
    } else {
      print('❌ 二维码格式验证失败');
    }
  } catch (e) {
    print('❌ 二维码解析失败: $e');
  }
  
  // 测试不同长度的加入码
  print('\n🔥 测试不同长度的加入码');
  final testCodes = ['ABC', 'ABCD', 'A1B2C3D4', '1234567890123456', '123456789012345678901'];
  
  for (final code in testCodes) {
    final isValid = code.length >= 4 && code.length <= 20;
    final status = isValid ? '✅' : '❌';
    print('$status ${code.length}位加入码: $code');
  }
  
  print('\n🎉 测试完成！');
} 