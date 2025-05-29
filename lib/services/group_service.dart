import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'device_auth_service.dart';

class GroupService {
  final String _baseUrl = "https://sendtomyself-api-adecumh2za-uc.a.run.app/api";
  final Duration _timeout = const Duration(seconds: 30);
  final DeviceAuthService _deviceAuthService = DeviceAuthService();
  
  // 🔥 修复：获取认证头部 - 按照API文档要求
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) {
      throw Exception('未找到认证令牌，请重新登录');
    }
    
    // 🔥 使用DeviceAuthService获取正确的设备ID
    String deviceId;
    try {
      deviceId = await _deviceAuthService.getOrCreateDeviceId();
    } catch (e) {
      print('获取设备ID失败: $e');
      throw Exception('获取设备ID失败，请重新启动应用');
    }
    
    print('🔧 认证头部信息: Token=${token.substring(0, 20)}..., DeviceId=$deviceId');
    
    // 🔥 按照API文档构造请求头
    final headers = {
      'Authorization': 'Bearer $token',
      'X-Device-Id': deviceId,
      'Content-Type': 'application/json',
    };
    
    return headers;
  }
  
  // 创建新群组
  Future<Map<String, dynamic>> createGroup(String groupName, {String? description}) async {
    try {
      final headers = await _getAuthHeaders();
      
      final requestBody = {
        'groupName': groupName,
        if (description != null && description.isNotEmpty) 'description': description,
      };
      
      print('创建群组请求: $requestBody');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/device-auth/create-group'),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(_timeout);
      
      print('创建群组响应状态码: ${response.statusCode}');
      print('创建群组响应内容: ${response.body}');
      
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('创建群组失败: ${response.body}');
      }
    } catch (e) {
      print('创建群组失败: $e');
      rethrow;
    }
  }
  
  // 获取设备所在的所有群组
  Future<Map<String, dynamic>> getGroups() async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/device-auth/groups'),
        headers: headers,
      ).timeout(_timeout);
      
      print('获取群组列表响应状态码: ${response.statusCode}');
      print('获取群组列表响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('获取群组列表失败: ${response.body}');
      }
    } catch (e) {
      print('获取群组列表失败: $e');
      rethrow;
    }
  }
  
  // 为指定群组生成邀请码和二维码
  Future<Map<String, dynamic>> generateInviteCode(String groupId, {int expiryHours = 24}) async {
    try {
      final headers = await _getAuthHeaders();
      
      final requestBody = {
        'groupId': groupId,
        'expiryHours': expiryHours,
      };
      
      print('生成邀请码请求: $requestBody');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/device-auth/generate-qrcode'),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(_timeout);
      
      print('生成邀请码响应状态码: ${response.statusCode}');
      print('生成邀请码响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('生成邀请码失败: ${response.body}');
      }
    } catch (e) {
      print('生成邀请码失败: $e');
      rethrow;
    }
  }
  
  // 通过加入码加入群组
  Future<Map<String, dynamic>> joinGroup(String joinCode, {String? groupId}) async {
    try {
      final headers = await _getAuthHeaders();
      
      // 🔥 重要修复：确保joinCode是纯字符串
      String actualJoinCode = joinCode;
      
      // 如果传入的是JSON格式，提取joinCode字段
      try {
        final jsonData = jsonDecode(joinCode);
        if (jsonData is Map<String, dynamic> && jsonData.containsKey('joinCode')) {
          actualJoinCode = jsonData['joinCode'].toString();
          print('从JSON中提取joinCode: $actualJoinCode');
          
          // 如果JSON中包含groupId且参数中没有指定，使用JSON中的groupId
          if (groupId == null && jsonData.containsKey('groupId')) {
            groupId = jsonData['groupId'].toString();
            print('从JSON中提取groupId: $groupId');
          }
        }
      } catch (e) {
        // 如果不是JSON格式，直接使用原始字符串
        print('joinCode不是JSON格式，直接使用: $actualJoinCode');
      }
      
      // 🔥 根据API文档构造请求体
      final requestBody = {
        'joinCode': actualJoinCode,
      };
      
      // 🔥 groupId是可选参数，用于额外验证
      if (groupId != null) {
        requestBody['groupId'] = groupId;
      }
      
      print('加入群组请求: $requestBody');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/device-auth/join-group'),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(_timeout);
      
      print('加入群组响应状态码: ${response.statusCode}');
      print('加入群组响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // 🔥 验证响应格式
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? '加入群组失败');
        }
      } else {
        // 🔥 根据文档处理不同的错误状态码
        String errorMessage;
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? _getDefaultErrorMessage(response.statusCode);
        } catch (_) {
          errorMessage = _getDefaultErrorMessage(response.statusCode);
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('加入群组失败: $e');
      rethrow;
    }
  }
  
  // 获取群组设备列表
  Future<Map<String, dynamic>> getGroupDevices(String groupId) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/device-auth/group-devices/$groupId'),
        headers: headers,
      ).timeout(_timeout);
      
      print('获取群组设备响应状态码: ${response.statusCode}');
      print('获取群组设备响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('获取群组设备失败: ${response.body}');
      }
    } catch (e) {
      print('获取群组设备失败: $e');
      rethrow;
    }
  }
  
  // 获取群组详情
  Future<Map<String, dynamic>> getGroupDetails(String groupId) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/device-auth/groups/$groupId'),
        headers: headers,
      ).timeout(_timeout);
      
      print('获取群组详情响应状态码: ${response.statusCode}');
      print('获取群组详情响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('获取群组详情失败: ${response.body}');
      }
    } catch (e) {
      print('获取群组详情失败: $e');
      rethrow;
    }
  }
  
  // 获取群组成员列表
  Future<Map<String, dynamic>> getGroupMembers(String groupId) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/device-auth/groups/$groupId/devices'),
        headers: headers,
      ).timeout(_timeout);
      
      print('获取群组成员响应状态码: ${response.statusCode}');
      print('获取群组成员响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('获取群组成员失败: ${response.body}');
      }
    } catch (e) {
      print('获取群组成员失败: $e');
      rethrow;
    }
  }
  
  // 🔥 修复：群组重命名 - 按照API文档实现
  Future<Map<String, dynamic>> renameGroup(String groupId, String newName) async {
    try {
      // 🔥 输入验证 - 按照API文档要求
      if (groupId.isEmpty) {
        throw Exception('群组ID不能为空');
      }
      
      final trimmedName = newName.trim();
      if (trimmedName.isEmpty) {
        throw Exception('群组名称不能为空');
      }
      
      if (trimmedName.length > 100) {
        throw Exception('群组名称不能超过100个字符');
      }
      
      final headers = await _getAuthHeaders();
      
      // 🔥 按照API文档构造请求体
      final requestBody = {
        'groupId': groupId,
        'newName': trimmedName,
      };
      
      print('🔧 群组重命名请求: $requestBody');
      
      final response = await http.put(
        Uri.parse('$_baseUrl/device-auth/rename-group'),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(_timeout);
      
      print('🔧 群组重命名响应状态码: ${response.statusCode}');
      print('🔧 群组重命名响应内容: ${response.body}');
      
      // 🔥 按照API文档处理响应
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // 验证成功响应格式
        if (data['success'] == true) {
          print('✅ 群组重命名成功: ${data['oldName']} → ${data['group']['name']}');
          return data;
        } else {
          throw Exception(data['message'] ?? '群组重命名失败');
        }
      } else {
        // 🔥 按照API文档处理错误状态码
        String errorMessage;
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? _getGroupRenameErrorMessage(response.statusCode);
        } catch (_) {
          errorMessage = _getGroupRenameErrorMessage(response.statusCode);
        }
        
        print('❌ 群组重命名失败: $errorMessage (状态码: ${response.statusCode})');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ 群组重命名异常: $e');
      rethrow;
    }
  }
  
  // 🔥 新增：群组重命名专用错误消息
  String _getGroupRenameErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return '群组ID或名称无效';
      case 401:
        return '登录已过期，请重新登录';
      case 403:
        return '您不在此群组中，无法重命名群组';
      case 404:
        return '群组不存在';
      case 500:
        return '服务器内部错误，请稍后重试';
      default:
        return '群组重命名失败，服务器错误: $statusCode';
    }
  }
  
  // 退出群组
  Future<Map<String, dynamic>> leaveGroup(String groupId) async {
    try {
      final headers = await _getAuthHeaders();
      
      final requestBody = {
        'groupId': groupId,
      };
      
      print('退出群组请求: $requestBody');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/device-auth/leave-group'),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(_timeout);
      
      print('退出群组响应状态码: ${response.statusCode}');
      print('退出群组响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('退出群组失败: ${response.body}');
      }
    } catch (e) {
      print('退出群组失败: $e');
      rethrow;
    }
  }
  
  // 移除设备
  Future<Map<String, dynamic>> removeDevice(String groupId, String targetDeviceId) async {
    try {
      final headers = await _getAuthHeaders();
      
      final requestBody = {
        'groupId': groupId,
        'targetDeviceId': targetDeviceId,
      };
      
      print('移除设备请求: $requestBody');
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/device-auth/remove-device'),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(_timeout);
      
      print('移除设备响应状态码: ${response.statusCode}');
      print('移除设备响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('移除设备失败: ${response.body}');
      }
    } catch (e) {
      print('移除设备失败: $e');
      rethrow;
    }
  }
  
  // 设备重命名
  Future<Map<String, dynamic>> renameDevice(String newName) async {
    try {
      final headers = await _getAuthHeaders();
      
      final requestBody = {
        'newName': newName,
      };
      
      print('设备重命名请求: $requestBody');
      
      final response = await http.put(
        Uri.parse('$_baseUrl/device-auth/rename-device'),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(_timeout);
      
      print('设备重命名响应状态码: ${response.statusCode}');
      print('设备重命名响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('设备重命名失败: ${response.body}');
      }
    } catch (e) {
      print('设备重命名失败: $e');
      rethrow;
    }
  }
  
  // 解析二维码数据
  Map<String, dynamic>? parseQRCodeData(String qrData) {
    try {
      final data = jsonDecode(qrData);
      
      // 验证二维码格式
      if (data['type'] == 'sendtomyself_group_join' && 
          data['version'] == '1.0' &&
          data['groupId'] != null &&
          data['joinCode'] != null &&
          data['expiresAt'] != null) {
        
        // 检查是否过期
        final expiresAt = DateTime.parse(data['expiresAt']);
        if (expiresAt.isAfter(DateTime.now())) {
          return data;
        } else {
          throw Exception('邀请码已过期');
        }
      } else {
        throw Exception('无效的二维码格式');
      }
    } catch (e) {
      print('解析二维码数据失败: $e');
      return null;
    }
  }
  
  // 🔥 新增：根据HTTP状态码返回默认错误消息
  String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        return '登录已过期，请重新登录';
      case 403:
        return '权限不足，只有群组成员才能生成邀请码';
      case 404:
        return '群组不存在或邀请码无效';
      case 409:
        return '您已在该群组中';
      case 429:
        return '操作过于频繁，请稍后再试';
      default:
        return '服务器错误: $statusCode';
    }
  }
} 