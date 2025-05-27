import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class MemoryService {
  static const String baseUrl = 'https://sendtomyself-api-adecumh2za-uc.a.run.app';
  final Dio _dio = Dio();

  MemoryService() {
    _initializeDio();
  }

  void _initializeDio() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.baseUrl = baseUrl;
    
    // 添加拦截器来确保每次请求都有最新的token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final currentPrefs = await SharedPreferences.getInstance();
        final currentToken = currentPrefs.getString('auth_token');
        if (currentToken != null) {
          options.headers['Authorization'] = 'Bearer $currentToken';
        }
        handler.next(options);
      },
    ));
  }

  // =================== 记忆基础操作 ===================

  /// 创建记忆
  Future<Map<String, dynamic>> createMemory({
    required String title,
    required String content,
    required String type,
    String? groupId,
    List<String>? tags,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post(
        '/api/memory',
        data: {
          'title': title,
          'content': content,
          'type': type,
          if (groupId != null) 'groupId': groupId,
          if (tags != null) 'tags': tags,
          if (data != null) 'data': data,
        },
      );
      return response.data;
    } catch (e) {
      print('创建记忆失败: $e');
      throw _handleError(e);
    }
  }

  /// 创建文件记忆
  Future<Map<String, dynamic>> createFileMemory({
    required String title,
    required File file,
    String? description,
    String? groupId,
    List<String>? tags,
    Map<String, dynamic>? data,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'file': await MultipartFile.fromFile(file.path),
        if (description != null) 'description': description,
        if (groupId != null) 'groupId': groupId,
        if (tags != null) 'tags': jsonEncode(tags),
        if (data != null) 'data': jsonEncode(data),
      });

      final response = await _dio.post(
        '/api/memory/file',
        data: formData,
      );
      return response.data;
    } catch (e) {
      print('创建文件记忆失败: $e');
      throw _handleError(e);
    }
  }

  /// 获取记忆列表
  Future<Map<String, dynamic>> getMemories({
    int limit = 20,
    int offset = 0,
    String? groupId,
    String? type,
    String? search,
    List<String>? tags,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      
      if (groupId != null) queryParameters['groupId'] = groupId;
      if (type != null) queryParameters['type'] = type;
      if (search != null) queryParameters['search'] = search;
      if (tags != null) queryParameters['tags'] = tags.join(',');

      final response = await _dio.get(
        '/api/memory',
        queryParameters: queryParameters,
      );
      return response.data;
    } catch (e) {
      print('获取记忆列表失败: $e');
      throw _handleError(e);
    }
  }

  /// 获取记忆详情
  Future<Map<String, dynamic>> getMemory(String memoryId) async {
    try {
      final response = await _dio.get('/api/memory/$memoryId');
      return response.data;
    } catch (e) {
      print('获取记忆详情失败: $e');
      throw _handleError(e);
    }
  }

  /// 更新记忆
  Future<Map<String, dynamic>> updateMemory({
    required String memoryId,
    String? title,
    String? content,
    List<String>? tags,
    Map<String, dynamic>? data,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (tags != null) updateData['tags'] = tags;
      if (data != null) updateData['data'] = data;

      final response = await _dio.put('/api/memory/$memoryId', data: updateData);
      return response.data;
    } catch (e) {
      print('更新记忆失败: $e');
      throw _handleError(e);
    }
  }

  /// 删除记忆
  Future<Map<String, dynamic>> deleteMemory(String memoryId) async {
    try {
      final response = await _dio.delete('/api/memory/$memoryId');
      return response.data;
    } catch (e) {
      print('删除记忆失败: $e');
      throw _handleError(e);
    }
  }

  // =================== 搜索功能 ===================

  /// 搜索记忆
  Future<Map<String, dynamic>> searchMemories({
    required String query,
    int limit = 20,
    int offset = 0,
    String? type,
    List<String>? tags,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'q': query,
        'limit': limit,
        'offset': offset,
      };
      
      if (type != null) queryParameters['type'] = type;
      if (tags != null) queryParameters['tags'] = tags.join(',');

      final response = await _dio.get(
        '/api/memory/search',
        queryParameters: queryParameters,
      );
      return response.data;
    } catch (e) {
      print('搜索记忆失败: $e');
      throw _handleError(e);
    }
  }

  // =================== 错误处理 ===================

  String _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          return '网络连接超时，请检查网络';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['message'];
          
          switch (statusCode) {
            case 400:
              return message ?? '请求参数错误';
            case 401:
              return '认证失败，请重新登录';
            case 403:
              return '权限不足';
            case 404:
              return '记忆不存在';
            case 500:
              return '服务器内部错误';
            default:
              return message ?? '请求失败';
          }
        case DioExceptionType.unknown:
          return '网络连接失败，请检查网络';
        default:
          return error.message ?? '未知错误';
      }
    }
    return error.toString();
  }
} 