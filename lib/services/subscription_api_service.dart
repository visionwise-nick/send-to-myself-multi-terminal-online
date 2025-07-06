import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription_model.dart';
import '../config/debug_config.dart';

class SubscriptionApiService {
  static const String _baseUrl = 'https://sendtomyself-api-adecumh2za-uc.a.run.app/api';
  static const String _subscriptionEndpoint = '/subscription';
  
  static final SubscriptionApiService _instance = SubscriptionApiService._internal();
  factory SubscriptionApiService() => _instance;
  SubscriptionApiService._internal();

  // 获取认证headers
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userId = prefs.getString('user_id');
    
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
      'x-user-id': userId ?? '',
    };
  }

  // 获取所有订阅计划
  Future<List<Map<String, dynamic>>> getAllPlans({String? currency, String? region}) async {
    try {
      final headers = await _getHeaders();
      var url = '$_baseUrl$_subscriptionEndpoint/plans';
      
      final params = <String, String>{};
      if (currency != null) params['currency'] = currency;
      if (region != null) params['region'] = region;
      
      if (params.isNotEmpty) {
        url += '?${Uri(queryParameters: params).query}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']['plans']);
      } else {
        throw Exception('获取订阅计划失败: ${response.statusCode}');
      }
    } catch (e) {
      DebugConfig.errorPrint('获取订阅计划异常: $e');
      rethrow;
    }
  }

  // 获取特定计划信息
  Future<Map<String, dynamic>> getPlanInfo(String plan, {String? currency}) async {
    try {
      final headers = await _getHeaders();
      var url = '$_baseUrl$_subscriptionEndpoint/plans/$plan';
      
      if (currency != null) {
        url += '?currency=$currency';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('获取计划信息失败: ${response.statusCode}');
      }
    } catch (e) {
      DebugConfig.errorPrint('获取计划信息异常: $e');
      rethrow;
    }
  }

  // 获取用户订阅状态
  Future<Map<String, dynamic>> getUserSubscription() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl$_subscriptionEndpoint/status'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('获取订阅状态失败: ${response.statusCode}');
      }
    } catch (e) {
      DebugConfig.errorPrint('获取订阅状态异常: $e');
      rethrow;
    }
  }

  // 同步购买信息到后端
  Future<Map<String, dynamic>> syncPurchase({
    required String plan,
    required String billing,
    required String currency,
    required String productId,
    required String transactionId,
    required double price,
    String? receipt,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'plan': plan,
        'billing': billing,
        'currency': currency,
        'paymentData': {
          'paymentMethod': 'app_store',
          'productId': productId,
          'transactionId': transactionId,
          'price': price,
          'receipt': receipt,
          'platform': 'ios_android',
          'timestamp': DateTime.now().toIso8601String(),
        },
      };
      
      final response = await http.post(
        Uri.parse('$_baseUrl$_subscriptionEndpoint/purchase'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('同步购买信息失败: ${response.statusCode}');
      }
    } catch (e) {
      DebugConfig.errorPrint('同步购买信息异常: $e');
      rethrow;
    }
  }

  // 取消订阅
  Future<Map<String, dynamic>> cancelSubscription() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl$_subscriptionEndpoint/cancel'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('取消订阅失败: ${response.statusCode}');
      }
    } catch (e) {
      DebugConfig.errorPrint('取消订阅异常: $e');
      rethrow;
    }
  }

  // 验证订阅状态
  Future<Map<String, dynamic>> validateSubscription() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl$_subscriptionEndpoint/validate'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('验证订阅状态失败: ${response.statusCode}');
      }
    } catch (e) {
      DebugConfig.errorPrint('验证订阅状态异常: $e');
      rethrow;
    }
  }

  // 获取支付历史
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl$_subscriptionEndpoint/payments'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']['payments']);
      } else {
        throw Exception('获取支付历史失败: ${response.statusCode}');
      }
    } catch (e) {
      DebugConfig.errorPrint('获取支付历史异常: $e');
      rethrow;
    }
  }

  // 检测货币类型
  Future<String> detectCurrency() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl$_subscriptionEndpoint/detect-currency'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['currency'];
      } else {
        throw Exception('检测货币失败: ${response.statusCode}');
      }
    } catch (e) {
      DebugConfig.errorPrint('检测货币异常: $e');
      return 'USD'; // 默认返回美元
    }
  }
} 