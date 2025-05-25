import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GroupService {
  final String _baseUrl = "https://sendtomyself-api-adecumh2za-uc.a.run.app/api";
  
  // 获取认证头部
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final serverDeviceData = prefs.getString('server_device_data');
    
    if (token == null) {
      throw Exception('未找到认证令牌');
    }
    
    String? deviceId;
    if (serverDeviceData != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(serverDeviceData);
        deviceId = data['id'];
      } catch (e) {
        print('解析设备ID失败: $e');
      }
    }
    
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    
    if (deviceId != null) {
      headers['X-Device-Id'] = deviceId;
    }
    
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
      );
      
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
      );
      
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
      );
      
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
      
      final requestBody = {
        'joinCode': joinCode,
        if (groupId != null) 'groupId': groupId,
      };
      
      print('加入群组请求: $requestBody');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/device-auth/join-group'),
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      print('加入群组响应状态码: ${response.statusCode}');
      print('加入群组响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('加入群组失败: ${response.body}');
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
      );
      
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
      );
      
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
      );
      
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
  
  // 群组重命名
  Future<Map<String, dynamic>> renameGroup(String groupId, String newName) async {
    try {
      final headers = await _getAuthHeaders();
      
      final requestBody = {
        'groupId': groupId,
        'newName': newName,
      };
      
      print('群组重命名请求: $requestBody');
      
      final response = await http.put(
        Uri.parse('$_baseUrl/device-auth/rename-group'),
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      print('群组重命名响应状态码: ${response.statusCode}');
      print('群组重命名响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('群组重命名失败: ${response.body}');
      }
    } catch (e) {
      print('群组重命名失败: $e');
      rethrow;
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
      );
      
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
      );
      
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
      );
      
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
} 