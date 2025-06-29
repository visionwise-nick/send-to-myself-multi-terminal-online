import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/debug_config.dart';

class MessageActionsService {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://sendtomyself-api-adecumh2za-uc.a.run.app';

  MessageActionsService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  // 获取JWT Token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // 获取请求头
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 单个消息撤回
  Future<Map<String, dynamic>> revokeMessage({
    required String messageId,
    String? reason,
  }) async {
    try {
      // 验证消息ID
      if (messageId.isEmpty) {
        return {
          'success': false,
          'error': '消息ID为空',
        };
      }

      print('🔄 准备撤回消息: $messageId');
      
      final headers = await _getHeaders();
      print('🔄 请求头: $headers');
      
      final requestData = <String, dynamic>{};
      if (reason != null) {
        requestData['reason'] = reason;
      }
      
      print('🔄 请求URL: $_baseUrl/api/messages/$messageId/revoke');
      print('🔄 请求数据: $requestData');
      
      final response = await _dio.post(
        '/api/messages/$messageId/revoke',
        data: requestData,
        options: Options(headers: headers),
      );

      print('✅ 撤回消息成功: ${response.data}');
      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      print('❌ 撤回消息失败: $e');
      String errorMessage = '撤回失败';
      
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          errorMessage = '消息不存在或已被删除';
        } else if (e.response?.statusCode == 401) {
          errorMessage = '未授权，请重新登录';
        } else if (e.response?.statusCode == 403) {
          errorMessage = '无权限撤回此消息';
        } else if (e.response?.data != null) {
          errorMessage = e.response!.data['message'] ?? e.response!.data.toString();
        } else {
          errorMessage = e.message ?? '网络错误';
        }
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    }
  }

  // 单个消息删除
  Future<Map<String, dynamic>> deleteMessage({
    required String messageId,
    bool force = false,
  }) async {
    try {
      // 验证消息ID
      if (messageId.isEmpty) {
        return {
          'success': false,
          'error': '消息ID为空',
        };
      }

      print('🗑️ 准备删除消息: $messageId');
      
      final headers = await _getHeaders();
      print('🗑️ 请求头: $headers');
      
      final queryParams = {
        'force': force.toString(),
      };
      
      print('🗑️ 请求URL: $_baseUrl/api/messages/$messageId');
      print('🗑️ 查询参数: $queryParams');
      
      final response = await _dio.delete(
        '/api/messages/$messageId',
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      print('✅ 删除消息成功: ${response.data}');
      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      print('❌ 删除消息失败: $e');
      String errorMessage = '删除失败';
      
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          errorMessage = '消息不存在或已被删除';
        } else if (e.response?.statusCode == 401) {
          errorMessage = '未授权，请重新登录';
        } else if (e.response?.statusCode == 403) {
          errorMessage = '无权限删除此消息';
        } else if (e.response?.data != null) {
          errorMessage = e.response!.data['message'] ?? e.response!.data.toString();
        } else {
          errorMessage = e.message ?? '网络错误';
        }
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    }
  }

  // 批量消息撤回
  Future<Map<String, dynamic>> batchRevokeMessages({
    required List<String> messageIds,
    String? reason,
  }) async {
    try {
      if (messageIds.length > 50) {
        return {
          'success': false,
          'error': '一次最多只能撤回50条消息',
        };
      }

      final headers = await _getHeaders();
      
      final response = await _dio.post(
        '/api/messages/batch/revoke',
        data: {
          'messageIds': messageIds,
          if (reason != null) 'reason': reason,
        },
        options: Options(headers: headers),
      );

      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      print('批量撤回消息失败: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // 批量消息删除
  Future<Map<String, dynamic>> batchDeleteMessages({
    required List<String> messageIds,
    String? reason,
  }) async {
    try {
      if (messageIds.length > 100) {
        return {
          'success': false,
          'error': '一次最多只能删除100条消息',
        };
      }

      final headers = await _getHeaders();
      
      final response = await _dio.post(
        '/api/messages/batch/delete',
        data: {
          'messageIds': messageIds,
          if (reason != null) 'reason': reason,
        },
        options: Options(headers: headers),
      );

      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      print('批量删除消息失败: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // 复制消息内容到剪贴板
  Future<bool> copyMessageText(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (e) {
      DebugConfig.copyPasteDebug('复制文本失败: $e');
      return false;
    }
  }

  // 收藏消息（保存到本地存储）
  Future<bool> favoriteMessage(Map<String, dynamic> message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesList = prefs.getStringList('favorite_messages') ?? [];
      
      final favoriteMessage = {
        'id': message['id'],
        'text': message['text'],
        'fileType': message['fileType'],
        'fileName': message['fileName'],
        'fileUrl': message['fileUrl'],
        'timestamp': message['timestamp'],
        'sourceDeviceId': message['sourceDeviceId'],
        'favoriteTime': DateTime.now().toIso8601String(),
      };
      
      favoritesList.add(jsonEncode(favoriteMessage));
      await prefs.setStringList('favorite_messages', favoritesList);
      
      return true;
    } catch (e) {
      print('收藏消息失败: $e');
      return false;
    }
  }

  // 取消收藏消息
  Future<bool> unfavoriteMessage(String messageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesList = prefs.getStringList('favorite_messages') ?? [];
      
      favoritesList.removeWhere((favoriteStr) {
        try {
          final favorite = jsonDecode(favoriteStr);
          return favorite['id'] == messageId;
        } catch (e) {
          return false;
        }
      });
      
      await prefs.setStringList('favorite_messages', favoritesList);
      return true;
    } catch (e) {
      print('取消收藏失败: $e');
      return false;
    }
  }

  // 检查消息是否已收藏
  Future<bool> isMessageFavorited(String messageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesList = prefs.getStringList('favorite_messages') ?? [];
      
      return favoritesList.any((favoriteStr) {
        try {
          final favorite = jsonDecode(favoriteStr);
          return favorite['id'] == messageId;
        } catch (e) {
          return false;
        }
      });
    } catch (e) {
      print('检查收藏状态失败: $e');
      return false;
    }
  }

  // 获取收藏的消息列表
  Future<List<Map<String, dynamic>>> getFavoriteMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesList = prefs.getStringList('favorite_messages') ?? [];
      
      final favorites = <Map<String, dynamic>>[];
      for (final favoriteStr in favoritesList) {
        try {
          final favorite = jsonDecode(favoriteStr);
          favorites.add(Map<String, dynamic>.from(favorite));
        } catch (e) {
          print('解析收藏消息失败: $e');
        }
      }
      
      // 按收藏时间倒序排列
      favorites.sort((a, b) {
        try {
          final timeA = DateTime.parse(a['favoriteTime'] ?? '');
          final timeB = DateTime.parse(b['favoriteTime'] ?? '');
          return timeB.compareTo(timeA);
        } catch (e) {
          return 0;
        }
      });
      
      return favorites;
    } catch (e) {
      print('获取收藏消息失败: $e');
      return [];
    }
  }

  // 转发消息（返回格式化的文本）
  String formatMessageForForward(Map<String, dynamic> message) {
    final text = message['text'] ?? '';
    final fileName = message['fileName'];
    final timestamp = message['timestamp'];
    
    String forwardContent = '';
    
    if (fileName != null) {
      forwardContent += '📎 文件: $fileName\n';
    }
    
    if (text.isNotEmpty) {
      forwardContent += text;
    }
    
    if (timestamp != null) {
      try {
        final time = DateTime.parse(timestamp);
        forwardContent += '\n\n--- 转发于 ${time.toLocal().toString().substring(0, 19)} ---';
      } catch (e) {
        forwardContent += '\n\n--- 转发消息 ---';
      }
    }
    
    return forwardContent;
  }

  // 测试API连接和认证状态
  Future<Map<String, dynamic>> testApiConnection() async {
    try {
      final headers = await _getHeaders();
      print('🧪 测试API连接...');
      print('🧪 基础URL: $_baseUrl');
      print('🧪 请求头: $headers');
      
      // 测试一个简单的API端点
      final response = await _dio.get(
        '/api/health',
        options: Options(headers: headers),
      );

      return {
        'success': true,
        'data': response.data,
        'statusCode': response.statusCode,
      };
    } catch (e) {
      print('🧪 API连接测试失败: $e');
      
      String errorMessage = 'API连接失败';
      int? statusCode;
      
      if (e is DioException) {
        statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          errorMessage = '认证失败，请重新登录';
        } else if (statusCode == 404) {
          errorMessage = 'API端点不存在';
        } else if (e.response?.data != null) {
          errorMessage = e.response!.data.toString();
        } else {
          errorMessage = e.message ?? '网络错误';
        }
      }
      
      return {
        'success': false,
        'error': errorMessage,
        'statusCode': statusCode,
      };
    }
  }
} 