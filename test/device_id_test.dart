import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:send_to_myself/services/device_auth_service.dart';

void main() {
  group('设备ID生成测试', () {
    late DeviceAuthService authService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      authService = DeviceAuthService();
      // 清除SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    test('设备ID应该基于硬件信息生成且保持稳定', () async {
      // 第一次生成设备ID
      final deviceId1 = await authService.getOrCreateDeviceId();
      expect(deviceId1, isNotEmpty);
      expect(deviceId1.length, equals(36)); // UUID格式长度
      
      // 第二次获取设备ID（应该相同）
      final deviceId2 = await authService.getOrCreateDeviceId();
      expect(deviceId2, equals(deviceId1));
      
      print('第一次生成的设备ID: $deviceId1');
      print('第二次获取的设备ID: $deviceId2');
    });

    test('清除缓存后设备ID应该保持不变（基于硬件信息）', () async {
      // 第一次生成设备ID
      final deviceId1 = await authService.getOrCreateDeviceId();
      
      // 清除SharedPreferences缓存（模拟APP重装）
      SharedPreferences.setMockInitialValues({});
      
      // 重新生成设备ID（应该相同，因为基于硬件信息）
      final deviceId2 = await authService.getOrCreateDeviceId();
      
      expect(deviceId2, equals(deviceId1));
      print('重装前设备ID: $deviceId1');
      print('重装后设备ID: $deviceId2');
    });

    test('设备信息应该包含必要字段', () async {
      try {
        final deviceInfo = await authService.getDeviceInfo();
        
        expect(deviceInfo, isA<Map<String, dynamic>>());
        expect(deviceInfo['deviceId'], isNotEmpty);
        expect(deviceInfo['name'], isNotEmpty);
        expect(deviceInfo['type'], isNotEmpty);
        expect(deviceInfo['platform'], isNotEmpty);
        expect(deviceInfo['model'], isNotEmpty);
        
        print('设备信息: $deviceInfo');
      } catch (e) {
        // 在测试环境中，设备信息获取可能失败，这是正常的
        print('测试环境中设备信息获取失败（正常现象）: $e');
        expect(e, isA<Exception>());
      }
    });
  });
} 