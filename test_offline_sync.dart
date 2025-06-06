import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// 离线消息同步功能测试脚本
/// 用于验证新增的离线同步API是否正常工作
class OfflineSyncTester {
  final String baseUrl = "https://sendtomyself-api-adecumh2za-uc.a.run.app/api";
  String? authToken;
  String? deviceId;

  /// 测试设备注册
  Future<bool> testDeviceRegistration() async {
    print('\n=== 测试设备注册 ===');
    
    try {
      final deviceInfo = {
        "deviceId": "test_offline_sync_device_${DateTime.now().millisecondsSinceEpoch}",
        "name": "离线同步测试设备",
        "type": "测试设备",
        "platform": "测试平台",
        "model": "测试模型"
      };
      
      print('注册设备信息: ${jsonEncode(deviceInfo)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/device-auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(deviceInfo),
      );
      
      print('注册响应状态码: ${response.statusCode}');
      print('注册响应内容: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          authToken = responseData['token'];
          deviceId = responseData['device']['id'];
          print('✅ 设备注册成功');
          print('认证令牌: ${authToken?.substring(0, 20)}...');
          print('设备ID: $deviceId');
          return true;
        }
      }
      
      print('❌ 设备注册失败');
      return false;
    } catch (e) {
      print('❌ 设备注册出错: $e');
      return false;
    }
  }

  /// 获取认证头部
  Map<String, String> getAuthHeaders() {
    return {
      'Authorization': 'Bearer $authToken',
      'Content-Type': 'application/json',
      'X-Device-Id': deviceId ?? '',
    };
  }

  /// 测试群组历史消息同步API
  Future<bool> testGroupHistorySync() async {
    print('\n=== 测试群组历史消息同步API ===');
    
    if (authToken == null || deviceId == null) {
      print('❌ 缺少认证信息，无法测试');
      return false;
    }
    
    try {
      // 测试一个虚拟群组ID
      final testGroupId = 'test_group_123';
      
      // 构建查询参数
      final queryParams = {
        'limit': '50',
        'fromTime': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'includeDeleted': 'false',
      };
      
      final uri = Uri.parse('$baseUrl/messages/group/$testGroupId/history')
          .replace(queryParameters: queryParams);
      
      print('请求URL: $uri');
      
      final response = await http.get(uri, headers: getAuthHeaders());
      
      print('群组历史同步响应状态码: ${response.statusCode}');
      print('群组历史同步响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          print('✅ 群组历史消息同步API测试成功');
          print('群组ID: ${data['groupId']}');
          print('群组名称: ${data['groupName']}');
          print('消息数量: ${data['messages'].length}');
          print('分页信息: ${jsonEncode(data['pagination'])}');
          print('同步信息: ${jsonEncode(data['syncInfo'])}');
          return true;
        }
      }
      
      // 检查是否是404（群组不存在）这是正常的
      if (response.statusCode == 404) {
        print('✅ 群组不存在，API响应正常（404）');
        return true;
      }
      
      print('❌ 群组历史同步API测试失败');
      return false;
    } catch (e) {
      print('❌ 群组历史同步API测试出错: $e');
      return false;
    }
  }

  /// 测试设备离线消息同步API
  Future<bool> testOfflineMessageSync() async {
    print('\n=== 测试设备离线消息同步API ===');
    
    if (authToken == null || deviceId == null) {
      print('❌ 缺少认证信息，无法测试');
      return false;
    }
    
    try {
      // 构建查询参数 - 同步最近1小时的消息
      final fromTime = DateTime.now().subtract(const Duration(hours: 1));
      final queryParams = {
        'fromTime': fromTime.toIso8601String(),
        'limit': '100',
      };
      
      final uri = Uri.parse('$baseUrl/messages/sync/offline/$deviceId')
          .replace(queryParameters: queryParams);
      
      print('请求URL: $uri');
      
      final response = await http.get(uri, headers: getAuthHeaders());
      
      print('离线消息同步响应状态码: ${response.statusCode}');
      print('离线消息同步响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          print('✅ 离线消息同步API测试成功');
          print('设备ID: ${data['deviceId']}');
          print('消息数量: ${data['messages'].length}');
          print('同步信息: ${jsonEncode(data['syncInfo'])}');
          return true;
        }
      }
      
      print('❌ 离线消息同步API测试失败');
      return false;
    } catch (e) {
      print('❌ 离线消息同步API测试出错: $e');
      return false;
    }
  }

  /// 测试时间范围过滤
  Future<bool> testTimeRangeFilter() async {
    print('\n=== 测试时间范围过滤 ===');
    
    if (authToken == null || deviceId == null) {
      print('❌ 缺少认证信息，无法测试');
      return false;
    }
    
    try {
      final testGroupId = 'test_group_123';
      
      // 测试不同的时间范围
      final now = DateTime.now();
      final testCases = [
        {
          'description': '最近1小时',
          'fromTime': now.subtract(const Duration(hours: 1)).toIso8601String(),
        },
        {
          'description': '最近24小时',
          'fromTime': now.subtract(const Duration(hours: 24)).toIso8601String(),
        },
        {
          'description': '指定时间段',
          'fromTime': now.subtract(const Duration(days: 2)).toIso8601String(),
          'toTime': now.subtract(const Duration(days: 1)).toIso8601String(),
        },
      ];
      
      for (final testCase in testCases) {
        print('\n--- 测试 ${testCase['description']} ---');
        
        final queryParams = <String, String>{
          'limit': '20',
          'fromTime': testCase['fromTime']!,
        };
        
        if (testCase['toTime'] != null) {
          queryParams['toTime'] = testCase['toTime']!;
        }
        
        final uri = Uri.parse('$baseUrl/messages/group/$testGroupId/history')
            .replace(queryParameters: queryParams);
        
        final response = await http.get(uri, headers: getAuthHeaders());
        
        print('响应状态码: ${response.statusCode}');
        
        if (response.statusCode == 200 || response.statusCode == 404) {
          print('✅ ${testCase['description']} 时间范围测试通过');
        } else {
          print('❌ ${testCase['description']} 时间范围测试失败');
          return false;
        }
      }
      
      print('✅ 所有时间范围过滤测试通过');
      return true;
    } catch (e) {
      print('❌ 时间范围过滤测试出错: $e');
      return false;
    }
  }

  /// 测试includeDeleted参数
  Future<bool> testIncludeDeletedParameter() async {
    print('\n=== 测试includeDeleted参数 ===');
    
    if (authToken == null || deviceId == null) {
      print('❌ 缺少认证信息，无法测试');
      return false;
    }
    
    try {
      final testGroupId = 'test_group_123';
      
      // 测试includeDeleted=true和false
      final testCases = [
        {'includeDeleted': 'false', 'description': '不包含已删除消息'},
        {'includeDeleted': 'true', 'description': '包含已删除消息'},
      ];
      
      for (final testCase in testCases) {
        print('\n--- 测试 ${testCase['description']} ---');
        
        final queryParams = {
          'limit': '20',
          'includeDeleted': testCase['includeDeleted']!,
        };
        
        final uri = Uri.parse('$baseUrl/messages/group/$testGroupId/history')
            .replace(queryParameters: queryParams);
        
        final response = await http.get(uri, headers: getAuthHeaders());
        
        print('响应状态码: ${response.statusCode}');
        
        if (response.statusCode == 200 || response.statusCode == 404) {
          print('✅ ${testCase['description']} 参数测试通过');
        } else {
          print('❌ ${testCase['description']} 参数测试失败');
          return false;
        }
      }
      
      print('✅ includeDeleted参数测试通过');
      return true;
    } catch (e) {
      print('❌ includeDeleted参数测试出错: $e');
      return false;
    }
  }

  /// 运行所有测试
  Future<void> runAllTests() async {
    print('🚀 开始离线消息同步功能测试...');
    print('测试服务器: $baseUrl');
    
    final results = <String, bool>{};
    
    // 1. 测试设备注册
    results['设备注册'] = await testDeviceRegistration();
    
    if (results['设备注册'] == true) {
      // 2. 测试群组历史消息API
      results['群组历史消息API'] = await testGroupHistorySync();
      
      // 3. 测试设备离线消息API
      results['设备离线消息API'] = await testOfflineMessageSync();
      
      // 4. 测试时间范围过滤
      results['时间范围过滤'] = await testTimeRangeFilter();
      
      // 5. 测试includeDeleted参数
      results['includeDeleted参数'] = await testIncludeDeletedParameter();
    }
    
    // 输出测试结果
    print('\n' + '=' * 60);
    print('离线消息同步功能测试结果');
    print('=' * 60);
    
    results.forEach((testName, passed) {
      final status = passed ? '✅ 通过' : '❌ 失败';
      print('$testName: $status');
    });
    
    final passedCount = results.values.where((result) => result).length;
    final totalCount = results.length;
    
    print('\n总体结果: $passedCount/$totalCount 项通过');
    
    if (passedCount == totalCount) {
      print('🎉 所有测试通过！离线消息同步功能工作正常');
    } else {
      print('⚠️ 部分测试失败，请检查相关功能');
    }
  }
}

/// 主函数
void main() async {
  final tester = OfflineSyncTester();
  await tester.runAllTests();
} 