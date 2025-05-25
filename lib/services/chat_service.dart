import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
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
  
  // 获取服务器配置信息
  Future<Map<String, dynamic>> getServerConfig() async {
    try {
      final headers = await _getAuthHeaders();
      headers.remove('Content-Type'); // 不需要Content-Type
      
      final response = await http.get(
        Uri.parse('$_baseUrl/config'),
        headers: headers,
      );
      
      print('获取服务器配置响应状态码: ${response.statusCode}');
      print('获取服务器配置响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // 如果没有config接口，返回默认配置
        return {
          'maxFileSize': 50 * 1024 * 1024, // 默认50MB
          'allowedFileTypes': ['image', 'video', 'audio', 'document'],
        };
      }
    } catch (e) {
      print('获取服务器配置失败: $e');
      // 发生错误时返回默认配置
      return {
        'maxFileSize': 50 * 1024 * 1024, // 默认50MB
        'allowedFileTypes': ['image', 'video', 'audio', 'document'],
      };
    }
  }
  
  // 发送1v1文本消息
  Future<Map<String, dynamic>> sendPrivateMessage({
    required String targetDeviceId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      final requestBody = {
        'content': content,
        if (metadata != null) 'metadata': metadata,
      };
      
      print('发送1v1消息到: $targetDeviceId');
      print('消息内容: $content');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/messages/$targetDeviceId/text'),
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      print('发送1v1消息响应状态码: ${response.statusCode}');
      print('发送1v1消息响应内容: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('发送私聊消息失败: ${response.body}');
      }
    } catch (e) {
      print('发送1v1消息失败: $e');
      rethrow;
    }
  }
  
  // 发送1v1文件消息
  Future<Map<String, dynamic>> sendPrivateFile({
    required String targetDeviceId,
    required File file,
    required String fileName,
    required String fileType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
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
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/messages/$targetDeviceId/file'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      if (deviceId != null) {
        request.headers['X-Device-Id'] = deviceId;
      }
      
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      request.fields['fileName'] = fileName;
      request.fields['fileType'] = fileType;
      
      if (metadata != null) {
        request.fields['metadata'] = jsonEncode(metadata);
      }
      
      print('发送1v1文件到: $targetDeviceId');
      print('文件名: $fileName');
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('发送1v1文件响应状态码: ${response.statusCode}');
      print('发送1v1文件响应内容: $responseBody');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(responseBody);
      } else {
        throw Exception('发送私聊文件失败: $responseBody');
      }
    } catch (e) {
      print('发送1v1文件失败: $e');
      rethrow;
    }
  }
  
  // 获取1v1消息历史
  Future<Map<String, dynamic>> getPrivateMessages({
    required String targetDeviceId,
    int limit = 20,
    String? before,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      String url = '$_baseUrl/messages/$targetDeviceId?limit=$limit';
      if (before != null) {
        url += '&before=$before';
      }
      
      print('获取1v1消息历史: $targetDeviceId');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('获取1v1消息历史响应状态码: ${response.statusCode}');
      print('获取1v1消息历史响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('获取私聊消息历史失败: ${response.body}');
      }
    } catch (e) {
      print('获取1v1消息历史失败: $e');
      rethrow;
    }
  }
  
  // 发送群组文本消息
  Future<Map<String, dynamic>> sendGroupMessage({
    required String groupId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      final requestBody = {
        'content': content,
        if (metadata != null) 'metadata': metadata,
      };
      
      print('发送群组消息到: $groupId');
      print('消息内容: $content');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/messages/group/$groupId/text'),
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      print('发送群组消息响应状态码: ${response.statusCode}');
      print('发送群组消息响应内容: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('发送群组消息失败: ${response.body}');
      }
    } catch (e) {
      print('发送群组消息失败: $e');
      rethrow;
    }
  }
  
  // 发送群组文件消息
  Future<Map<String, dynamic>> sendGroupFile({
    required String groupId,
    required File file,
    required String fileName,
    required String fileType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
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
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/messages/group/$groupId/file'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      if (deviceId != null) {
        request.headers['X-Device-Id'] = deviceId;
      }
      
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      request.fields['fileName'] = fileName;
      request.fields['fileType'] = fileType;
      
      if (metadata != null) {
        request.fields['metadata'] = jsonEncode(metadata);
      }
      
      print('发送群组文件到: $groupId');
      print('文件名: $fileName');
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('发送群组文件响应状态码: ${response.statusCode}');
      print('发送群组文件响应内容: $responseBody');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(responseBody);
      } else {
        throw Exception('发送群组文件失败: $responseBody');
      }
    } catch (e) {
      print('发送群组文件失败: $e');
      rethrow;
    }
  }
  
  // 获取群组消息历史
  Future<Map<String, dynamic>> getGroupMessages({
    required String groupId,
    int limit = 20,
    String? before,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      String url = '$_baseUrl/messages/group/$groupId?limit=$limit';
      if (before != null) {
        url += '&before=$before';
      }
      
      print('获取群组消息历史: $groupId');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('获取群组消息历史响应状态码: ${response.statusCode}');
      print('获取群组消息历史响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('获取群组消息历史失败: ${response.body}');
      }
    } catch (e) {
      print('获取群组消息历史失败: $e');
      rethrow;
    }
  }
  
  // 获取群组文件列表
  Future<Map<String, dynamic>> getGroupFiles({
    required String groupId,
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/messages/group/$groupId/files?limit=$limit'),
        headers: headers,
      );
      
      print('获取群组文件列表响应状态码: ${response.statusCode}');
      print('获取群组文件列表响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('获取群组文件列表失败: ${response.body}');
      }
    } catch (e) {
      print('获取群组文件列表失败: $e');
      rethrow;
    }
  }
  
  // 下载文件
  Future<List<int>> downloadFile(String fileId) async {
    try {
      final headers = await _getAuthHeaders();
      headers.remove('Content-Type'); // 下载文件时不需要Content-Type
      
      final response = await http.get(
        Uri.parse('$_baseUrl/files/download/$fileId'),
        headers: headers,
      );
      
      print('下载文件响应状态码: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('下载文件失败: ${response.body}');
      }
    } catch (e) {
      print('下载文件失败: $e');
      rethrow;
    }
  }
  
  // 获取用户文件列表
  Future<Map<String, dynamic>> getUserFiles({
    int limit = 20,
    int offset = 0,
    String? type,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      String url = '$_baseUrl/files?limit=$limit&offset=$offset';
      if (type != null) {
        url += '&type=$type';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('获取用户文件列表响应状态码: ${response.statusCode}');
      print('获取用户文件列表响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('获取用户文件列表失败: ${response.body}');
      }
    } catch (e) {
      print('获取用户文件列表失败: $e');
      rethrow;
    }
  }
} 