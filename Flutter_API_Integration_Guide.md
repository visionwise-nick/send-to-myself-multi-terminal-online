# Flutter客户端API集成指南

## 概述

本指南说明如何修改现有的Flutter应用代码，以集成服务端API接口。新的API设计基于设备自动认证，与现有的设备注册机制完全一致，无需用户名密码登录。

**核心特点**：
- 设备自动注册认证（与现有机制一致）
- 基于设备的订阅管理
- 群组限制基于群组内**所有付费设备的最高等级**
- 付费设备离开群组时限制会相应降低
- 完全兼容现有的设备认证流程

**业务逻辑**：
- 免费版：2台设备
- 基础版：5台设备（¥9.9/月，¥99.9/年）
- 专业版：10台设备（¥19.9/月，¥199.9/年）
- 企业版：无限台设备（¥39.9/月，¥399.9/年）

群组最大设备数 = MAX(群组内所有付费设备的订阅等级)

主要涉及以下文件的修改：

- `lib/services/subscription_service.dart` - 订阅服务类
- `lib/providers/subscription_provider.dart` - 订阅状态管理
- `lib/providers/group_provider.dart` - 群组管理
- `lib/main.dart` - 应用初始化

## 1. 添加依赖包

首先在`pubspec.yaml`中添加HTTP客户端依赖：

```yaml
dependencies:
  http: ^1.1.0
  dio: ^5.3.2  # 可选：更强大的HTTP客户端
  connectivity_plus: ^5.0.1  # 网络状态检查
```

## 2. 扩展现有的API客户端

无需创建新的API客户端，直接扩展现有的`DeviceAuthService`来支持订阅API：

修改`lib/services/device_auth_service.dart`：

```dart
// 在现有的DeviceAuthService类中添加订阅相关方法

class DeviceAuthService {
  // ... 现有方法保持不变 ...
  
  // 🔥 新增：获取设备订阅状态
  Future<Map<String, dynamic>> getDeviceSubscriptionStatus() async {
    try {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception('未登录，无法获取订阅状态');
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/subscription/device/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('获取订阅状态失败: ${response.body}');
      }
    } catch (e) {
      print('获取订阅状态失败: $e');
      rethrow;
    }
  }
  
  // 🔥 新增：验证购买
  Future<Map<String, dynamic>> verifyPurchase({
    required String platform,
    required String receipt,
    required String productId,
    required String transactionId,
  }) async {
    try {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception('未登录，无法验证购买');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/subscription/device/verify-purchase'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'platform': platform,
          'receipt': receipt,
          'productId': productId,
          'transactionId': transactionId,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('验证购买失败: ${response.body}');
      }
    } catch (e) {
      print('验证购买失败: $e');
      rethrow;
    }
  }
  
  // 🔥 新增：恢复购买
  Future<Map<String, dynamic>> restorePurchases({
    required String platform,
    required String receipt,
  }) async {
    try {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception('未登录，无法恢复购买');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/subscription/device/restore'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'platform': platform,
          'receipt': receipt,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('恢复购买失败: ${response.body}');
      }
    } catch (e) {
      print('恢复购买失败: $e');
      rethrow;
    }
  }
  
  // 🔥 新增：检查群组限制
  Future<Map<String, dynamic>> checkGroupLimit({
    required String groupId,
    required String action,
    String? targetDeviceId,
  }) async {
    try {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception('未登录，无法检查群组限制');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/group/check-limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'groupId': groupId,
          'action': action,
          if (targetDeviceId != null) 'targetDeviceId': targetDeviceId,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // 超出限制时返回错误信息
        final errorData = jsonDecode(response.body);
        return errorData;
      }
    } catch (e) {
      print('检查群组限制失败: $e');
      rethrow;
    }
  }
  
  // 🔥 新增：获取群组统计
  Future<Map<String, dynamic>> getGroupStats(String groupId) async {
    try {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception('未登录，无法获取群组统计');
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/group/$groupId/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('获取群组统计失败: ${response.body}');
      }
    } catch (e) {
      print('获取群组统计失败: $e');
      rethrow;
    }
  }
  
  // 🔥 新增：获取产品列表
  Future<Map<String, dynamic>> getSubscriptionProducts({String? platform}) async {
    try {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception('未登录，无法获取产品列表');
      }
      
      String url = '$_baseUrl/products/subscriptions';
      if (platform != null) {
        url += '?platform=$platform';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('获取产品列表失败: ${response.body}');
      }
    } catch (e) {
      print('获取产品列表失败: $e');
      rethrow;
    }
  }
}
```

## 3. 无需额外认证服务

由于我们使用现有的`DeviceAuthService`，它已经处理了设备自动注册和认证，无需创建额外的认证服务。现有的认证流程完全满足需求：

- 设备自动注册：`DeviceAuthService.registerDevice()`
- 获取认证状态：`DeviceAuthService.isLoggedIn()`
- 获取认证令牌：`DeviceAuthService.getAuthToken()`
- 设备登出：`DeviceAuthService.logout()`

这确保了与现有应用的完全兼容。

## 4. 修改SubscriptionService

修改`lib/services/subscription_service.dart`：

```dart
import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'device_auth_service.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final DeviceAuthService _deviceAuthService = DeviceAuthService();
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  SubscriptionInfo _subscriptionInfo = SubscriptionInfo(
    plan: SubscriptionPlan.free,
    status: SubscriptionStatus.none,
  );
  
  // 购买状态流控制器
  final StreamController<SubscriptionInfo> _subscriptionController = 
      StreamController<SubscriptionInfo>.broadcast();
  
  Stream<SubscriptionInfo> get subscriptionStream => 
      _subscriptionController.stream;
  
  SubscriptionInfo get subscriptionInfo => _subscriptionInfo;
  
  // 初始化服务
  Future<void> initialize() async {
    // 确保设备已认证（使用现有的认证机制）
    if (!await _deviceAuthService.isLoggedIn()) {
      await _deviceAuthService.registerDevice();
    }
    
    // 监听购买状态变化
    _subscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        print('购买流监听错误: $error');
      },
    );
    
    // 从服务器同步订阅状态
    await syncSubscriptionStatus();
  }
  
  // 同步服务器订阅状态
  Future<void> syncSubscriptionStatus() async {
    try {
      final response = await _deviceAuthService.getDeviceSubscriptionStatus();
      final subscriptionData = response['data']['subscription'];
      
      if (subscriptionData != null) {
        _subscriptionInfo = SubscriptionInfo.fromJson(subscriptionData);
      } else {
        _subscriptionInfo = SubscriptionInfo(
          plan: SubscriptionPlan.free,
          status: SubscriptionStatus.none,
        );
      }
      
      _subscriptionController.add(_subscriptionInfo);
    } catch (e) {
      print('同步订阅状态失败: $e');
      // 如果网络失败，尝试从本地加载
      await _loadLocalSubscriptionInfo();
    }
  }
  
  // 处理购买更新
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _handlePendingPurchase(purchase);
          break;
        case PurchaseStatus.purchased:
          _handlePurchasedPurchase(purchase);
          break;
        case PurchaseStatus.error:
          _handleErrorPurchase(purchase);
          break;
        case PurchaseStatus.restored:
          _handleRestoredPurchase(purchase);
          break;
        case PurchaseStatus.canceled:
          _handleCanceledPurchase(purchase);
          break;
      }
    }
  }
  
  // 处理已购买的商品
  Future<void> _handlePurchasedPurchase(PurchaseDetails purchase) async {
    try {
      // 发送到服务器验证
      final response = await _deviceAuthService.verifyPurchase(
        platform: Platform.isIOS ? 'ios' : 'android',
        receipt: purchase.verificationData.serverVerificationData,
        productId: purchase.productID,
        transactionId: purchase.purchaseID ?? '',
      );
      
      if (response['data']['verified'] == true) {
        // 更新本地订阅信息
        final subscriptionData = response['data']['subscription'];
        _subscriptionInfo = SubscriptionInfo.fromJson(subscriptionData);
        _subscriptionController.add(_subscriptionInfo);
        
        // 保存到本地
        await _saveLocalSubscriptionInfo();
      }
    } catch (e) {
      print('购买验证失败: $e');
    } finally {
      // 完成购买
      await _inAppPurchase.completePurchase(purchase);
    }
  }
  
  // 恢复购买
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      
      // 同时调用服务器恢复接口
      final response = await _deviceAuthService.restorePurchases(
        platform: Platform.isIOS ? 'ios' : 'android',
        receipt: '', // 在实际实现中需要获取receipt
      );
      
      final subscriptions = response['data']['subscriptions'] as List;
      if (subscriptions.isNotEmpty) {
        _subscriptionInfo = SubscriptionInfo.fromJson(subscriptions.first);
        _subscriptionController.add(_subscriptionInfo);
        await _saveLocalSubscriptionInfo();
      }
    } catch (e) {
      print('恢复购买失败: $e');
    }
  }
  
  // 检查群组成员限制
  Future<Map<String, dynamic>> checkGroupMemberLimit(String groupId, String action, {String? targetDeviceId}) async {
    try {
      final response = await _deviceAuthService.checkGroupLimit(
        groupId: groupId,
        action: action,
        targetDeviceId: targetDeviceId,
      );
      
      return {
        'allowed': response['data']['allowed'] ?? false,
        'currentCount': response['data']['currentCount'] ?? 0,
        'maxCount': response['data']['maxCount'] ?? 2,
        'isUnlimited': response['data']['effectiveSubscription']?['isUnlimited'] ?? false,
        'reason': response['data']['reason'] ?? '',
        'upgradeRequired': response['data']['upgradeRequired'] ?? false,
        'suggestedPlan': response['data']['suggestedPlan'],
        'paidDevices': response['data']['paidDevices'] ?? [],
      };
    } catch (e) {
      print('检查群组限制失败: $e');
      // 网络失败时使用本地检查
      return {
        'allowed': _checkLocalGroupLimit(),
        'currentCount': 0,
        'maxCount': 2,
        'isUnlimited': false,
        'reason': '网络错误，使用本地检查',
        'upgradeRequired': false,
        'suggestedPlan': null,
        'paidDevices': [],
      };
    }
  }
  
  // 获取群组统计信息
  Future<Map<String, dynamic>?> getGroupStats(String groupId) async {
    try {
      final response = await _deviceAuthService.getGroupStats(groupId);
      return response['data'];
    } catch (e) {
      print('获取群组统计失败: $e');
      return null;
    }
  }
  
  // 购买订阅
  Future<bool> purchaseSubscription(String productId) async {
    try {
      // 先查询产品信息
      final productDetailsResponse = await _inAppPurchase.queryProductDetails({productId});
      
      if (productDetailsResponse.productDetails.isEmpty) {
        throw Exception('产品不存在: $productId');
      }
      
      final productDetails = productDetailsResponse.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: productDetails);
      
      // 发起购买
      final result = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      return result;
    } catch (e) {
      print('购买失败: $e');
      return false;
    }
  }
  
  // 获取产品列表
  Future<List<Map<String, dynamic>>> getSubscriptionProducts() async {
    try {
      final response = await _deviceAuthService.getSubscriptionProducts(
        platform: Platform.isIOS ? 'ios' : 'android',
      );
      
      return List<Map<String, dynamic>>.from(response['data']['products'] ?? []);
    } catch (e) {
      print('获取产品列表失败: $e');
      return [];
    }
  }
  
  // 本地方法保持不变...
  Future<void> _saveLocalSubscriptionInfo() async {
    // 实现本地保存逻辑
  }
  
  Future<void> _loadLocalSubscriptionInfo() async {
    // 实现本地加载逻辑
  }
  
  bool _checkLocalGroupLimit() {
    // 实现本地限制检查逻辑
    return _subscriptionInfo.plan.maxDevices > 2; // 简化检查
  }
  
  // 其他处理方法...
  void _handlePendingPurchase(PurchaseDetails purchase) {
    print('购买待处理: ${purchase.productID}');
  }
  
  void _handleErrorPurchase(PurchaseDetails purchase) {
    print('购买错误: ${purchase.error}');
  }
  
  void _handleRestoredPurchase(PurchaseDetails purchase) {
    print('购买已恢复: ${purchase.productID}');
  }
  
  void _handleCanceledPurchase(PurchaseDetails purchase) {
    print('购买已取消: ${purchase.productID}');
  }
  
  // 释放资源
  void dispose() {
    _subscription.cancel();
    _subscriptionController.close();
  }
}
```

## 5. 修改SubscriptionProvider

修改`lib/providers/subscription_provider.dart`：

```dart
import 'package:flutter/foundation.dart';
import '../services/subscription_service.dart';
import '../models/subscription_model.dart';

class SubscriptionProvider with ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  SubscriptionInfo _subscriptionInfo = SubscriptionInfo(
    plan: SubscriptionPlan.free,
    status: SubscriptionStatus.none,
  );
  
  bool _isLoading = false;
  bool _isPurchasing = false;
  String? _error;
  
  // Getters
  SubscriptionInfo get subscriptionInfo => _subscriptionInfo;
  bool get isLoading => _isLoading;
  bool get isPurchasing => _isPurchasing;
  String? get error => _error;
  
  // 初始化
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _subscriptionService.initialize();
      
      // 监听订阅状态变化
      _subscriptionService.subscriptionStream.listen((subscriptionInfo) {
        _subscriptionInfo = subscriptionInfo;
        notifyListeners();
      });
      
      _subscriptionInfo = _subscriptionService.subscriptionInfo;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  // 同步订阅状态
  Future<void> syncSubscriptionStatus() async {
    _setLoading(true);
    try {
      await _subscriptionService.syncSubscriptionStatus();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  // 购买订阅
  Future<bool> purchaseSubscription(String productId) async {
    _setPurchasing(true);
    try {
      final result = await _subscriptionService.purchaseSubscription(productId);
      _error = null;
      return result;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setPurchasing(false);
    }
  }
  
  // 恢复购买
  Future<void> restorePurchases() async {
    _setLoading(true);
    try {
      await _subscriptionService.restorePurchases();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  // 检查群组限制
  Future<bool> checkGroupMemberLimit(String groupId, String action, {String? targetUserId}) async {
    try {
      return await _subscriptionService.checkGroupMemberLimit(groupId, action, targetUserId: targetUserId);
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
  
  // 获取群组统计
  Future<Map<String, dynamic>?> getGroupStats(String groupId) async {
    try {
      return await _subscriptionService.getGroupStats(groupId);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }
  
  // 私有方法
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setPurchasing(bool purchasing) {
    _isPurchasing = purchasing;
    notifyListeners();
  }
  
  // 其他方法保持不变...
}
```

## 6. 修改GroupProvider

修改`lib/providers/group_provider.dart`中的群组限制检查：

```dart
// 在GroupProvider中添加API调用
Future<GroupLimitCheckResult> checkCanAddMember(String groupId, String deviceId) async {
  try {
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final result = await subscriptionProvider.checkGroupMemberLimit(groupId, 'invite', targetDeviceId: deviceId);
    return GroupLimitCheckResult.fromJson(result);
  } catch (e) {
    print('检查群组限制失败: $e');
    return GroupLimitCheckResult(
      allowed: false,
      currentCount: 0,
      maxCount: 2,
      isUnlimited: false,
      reason: '检查失败: $e',
      upgradeRequired: false,
      paidDevices: [],
    );
  }
}

Future<GroupLimitCheckResult> checkCanJoinGroup(String groupId) async {
  try {
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final result = await subscriptionProvider.checkGroupMemberLimit(groupId, 'join');
    return GroupLimitCheckResult.fromJson(result);
  } catch (e) {
    print('检查群组限制失败: $e');
    return GroupLimitCheckResult(
      allowed: false,
      currentCount: 0,
      maxCount: 2,
      isUnlimited: false,
      reason: '检查失败: $e',
      upgradeRequired: false,
      paidDevices: [],
    );
  }
}

// 🔥 新增：显示群组设备数量信息的方法
String getGroupDeviceCountText(Map<String, dynamic> groupStats) {
  final memberCount = groupStats['memberCount'] ?? 0;
  final isUnlimited = groupStats['isUnlimited'] ?? false;
  
  if (isUnlimited) {
    return '$memberCount台设备（无限制）';
  }
  
  final maxMembers = groupStats['maxMembers'] ?? 2;
  return '$memberCount/$maxMembers台设备';
}
```

## 7. 修改main.dart

修改`lib/main.dart`中的初始化（与现有逻辑保持一致）：

```dart
// 无需修改现有的main.dart初始化逻辑
// 只需确保SubscriptionProvider在Provider树中正确初始化

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 保持现有的providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        // 🔥 添加新的SubscriptionProvider
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()..initialize()),
        // 其他现有providers保持不变...
      ],
      child: MaterialApp(
        // 现有app配置保持不变...
      ),
    );
  }
}
```

**关键变化**：
- 保持现有的设备认证初始化逻辑
- 只添加`SubscriptionProvider`到Provider树
- 不破坏现有的初始化流程

## 8. 更新订阅模型

需要更新现有的`lib/models/subscription_model.dart`以支持企业版：

```dart
enum SubscriptionPlan {
  free,
  basic,
  pro,
  enterprise, // 🔥 新增企业版
}

extension SubscriptionPlanExtension on SubscriptionPlan {
  int get maxDevices {
    switch (this) {
      case SubscriptionPlan.free:
        return 2;
      case SubscriptionPlan.basic:
        return 5;
      case SubscriptionPlan.pro:
        return 10;
      case SubscriptionPlan.enterprise:
        return -1; // 🔥 无限制用-1表示
    }
  }
  
  bool get isUnlimited => this == SubscriptionPlan.enterprise;
  
  String get displayName {
    switch (this) {
      case SubscriptionPlan.free:
        return '免费版';
      case SubscriptionPlan.basic:
        return '基础版';
      case SubscriptionPlan.pro:
        return '专业版';
      case SubscriptionPlan.enterprise:
        return '企业版'; // 🔥 新增企业版显示名称
    }
  }
  
  String get description {
    switch (this) {
      case SubscriptionPlan.free:
        return '支持2台设备';
      case SubscriptionPlan.basic:
        return '支持5台设备';
      case SubscriptionPlan.pro:
        return '支持10台设备';
      case SubscriptionPlan.enterprise:
        return '无限台设备'; // 🔥 新增企业版描述
    }
  }
}

// 🔥 新增群组限制检查结果模型
class GroupLimitCheckResult {
  final bool allowed;
  final int currentCount;
  final int maxCount;
  final bool isUnlimited;
  final String reason;
  final bool upgradeRequired;
  final SubscriptionPlan? suggestedPlan;
  final List<Map<String, dynamic>> paidDevices;
  
  GroupLimitCheckResult({
    required this.allowed,
    required this.currentCount,
    required this.maxCount,
    required this.isUnlimited,
    required this.reason,
    required this.upgradeRequired,
    this.suggestedPlan,
    required this.paidDevices,
  });
  
  factory GroupLimitCheckResult.fromJson(Map<String, dynamic> json) {
    return GroupLimitCheckResult(
      allowed: json['allowed'] ?? false,
      currentCount: json['currentCount'] ?? 0,
      maxCount: json['maxCount'] ?? 2,
      isUnlimited: json['isUnlimited'] ?? false,
      reason: json['reason'] ?? '',
      upgradeRequired: json['upgradeRequired'] ?? false,
      suggestedPlan: json['suggestedPlan'] != null 
          ? SubscriptionPlan.values.firstWhere(
              (e) => e.name == json['suggestedPlan'],
              orElse: () => SubscriptionPlan.basic,
            )
          : null,
      paidDevices: List<Map<String, dynamic>>.from(json['paidDevices'] ?? []),
    );
  }
  
  String get displayText {
    if (isUnlimited) {
      return '无限台设备';
    }
    return '$currentCount/$maxCount台设备';
  }
}
```

## 9. 错误处理和网络状态

添加网络状态检查和错误处理：

```dart
// 在需要的地方添加网络检查
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtils {
  static Future<bool> isConnected() async {
    final connectivity = await Connectivity().checkConnectivity();
    return connectivity != ConnectivityResult.none;
  }
  
  static Future<T> withNetworkCheck<T>(Future<T> Function() action) async {
    if (await isConnected()) {
      return await action();
    } else {
      throw Exception('网络连接不可用');
    }
  }
}
```

## 10. 配置和环境变量

创建`lib/config/app_config.dart`：

```dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.sendtomyself.com/v1',
  );
  
  static const bool isProduction = bool.fromEnvironment(
    'IS_PRODUCTION',
    defaultValue: false,
  );
  
  static const String appName = 'Send To Myself';
  static const String appVersion = '1.0.0';
}
```

## 11. 测试和调试

添加调试日志：

```dart
class Logger {
  static void d(String message) {
    if (!AppConfig.isProduction) {
      print('[DEBUG] $message');
    }
  }
  
  static void e(String message, [dynamic error]) {
    print('[ERROR] $message${error != null ? ': $error' : ''}');
  }
}
```

## 总结

完成以上修改后，Flutter应用将能够：

### ✅ 核心特性
1. **无缝设备认证** - 完全兼容现有的设备自动注册机制
2. **基于设备的订阅** - 订阅状态绑定到设备，无需用户账号
3. **群组所有者付费** - 群组限制基于群主设备的订阅状态
4. **服务器验证** - 所有购买都会发送到服务器进行验证
5. **跨设备同步** - 订阅状态在群组内所有设备间同步
6. **离线降级** - 网络失败时会降级到本地处理

### 🔄 与现有系统的兼容性
- **无需重构现有认证流程** - 继续使用`DeviceAuthService`
- **保持现有群组机制** - 群组创建和管理逻辑不变
- **扩展而非替换** - 在现有基础上添加订阅功能

### 🚀 实现的业务逻辑
- **免费版**：群组最多2台设备（现有逻辑）
- **基础版**：群组最多5台设备，任意设备购买后群组生效
- **专业版**：群组最多10台设备，任意设备购买后群组生效
- **企业版**：群组无限台设备，任意设备购买后群组生效

**关键变化**：
- 订阅效果影响设备所在的**所有群组**
- 群组限制基于群组内**最高等级的付费设备**
- 付费设备离开群组时，群组限制会重新计算

### 🔒 安全保障
- **购买凭证验证** - 防止客户端篡改
- **服务端限制强制** - 群组成员数量由服务器控制
- **设备绑定订阅** - 防止订阅滥用

这样就实现了与现有设备认证机制完全兼容的安全、可靠订阅功能，确保了付费功能的商业价值。 