import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription_model.dart';
import '../config/debug_config.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // 监听器
  final StreamController<SubscriptionInfo> _subscriptionController = 
      StreamController<SubscriptionInfo>.broadcast();
  
  // 当前订阅信息
  SubscriptionInfo _currentSubscription = SubscriptionInfo.createFreeSubscription();
  
  // 可用的产品
  List<ProductDetails> _products = [];
  
  // 服务是否已初始化
  bool _isInitialized = false;

  // 当前货币类型
  CurrencyType _currentCurrency = CurrencyType.usd;

  // Getters
  SubscriptionInfo get currentSubscription => _currentSubscription;
  Stream<SubscriptionInfo> get subscriptionStream => _subscriptionController.stream;
  List<ProductDetails> get products => _products;
  bool get isInitialized => _isInitialized;
  CurrencyType get currentCurrency => _currentCurrency;

  // 初始化服务
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    DebugConfig.debugPrint('初始化订阅服务...', module: 'SUBSCRIPTION');
    
    try {
      // 检查应用内购买是否可用
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        DebugConfig.warningPrint('应用内购买不可用');
        return;
      }

      // 检测当前地区和货币
      await _detectCurrentCurrency();

      // 加载本地订阅信息
      await _loadLocalSubscriptionInfo();

      // 获取产品信息
      await _loadProducts();

      // 监听购买更新
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdated,
        onError: (error) {
          DebugConfig.errorPrint('购买流错误: $error');
        },
      );

      // 恢复之前的购买
      await _restorePurchases();

      _isInitialized = true;
      DebugConfig.debugPrint('订阅服务初始化完成', module: 'SUBSCRIPTION');
    } catch (e) {
      DebugConfig.errorPrint('订阅服务初始化失败: $e');
    }
  }

  // 检测当前货币
  Future<void> _detectCurrentCurrency() async {
    try {
      // 获取设备地区码
      String? countryCode;
      
      if (Platform.isIOS) {
        // iOS获取地区码
        countryCode = await _getIOSCountryCode();
      } else if (Platform.isAndroid) {
        // Android获取地区码
        countryCode = await _getAndroidCountryCode();
      }
      
      if (countryCode != null) {
        _currentCurrency = SubscriptionPlanConfig.getDefaultCurrency(countryCode);
        DebugConfig.debugPrint('检测到地区: $countryCode, 货币: $_currentCurrency', module: 'SUBSCRIPTION');
      } else {
        _currentCurrency = CurrencyType.usd;
        DebugConfig.debugPrint('无法检测地区，使用默认货币: $_currentCurrency', module: 'SUBSCRIPTION');
      }
    } catch (e) {
      DebugConfig.errorPrint('检测货币失败: $e');
      _currentCurrency = CurrencyType.usd;
    }
  }

  // 获取iOS地区码
  Future<String?> _getIOSCountryCode() async {
    try {
      const platform = MethodChannel('com.example.send_to_myself/locale');
      final String? countryCode = await platform.invokeMethod('getCountryCode');
      return countryCode;
    } catch (e) {
      // 如果无法获取，尝试从SKPaymentQueue获取
      if (Platform.isIOS) {
        try {
          final SKPaymentQueueWrapper paymentQueue = SKPaymentQueueWrapper();
          final List<SKPaymentTransactionWrapper> transactions = await paymentQueue.transactions();
          if (transactions.isNotEmpty) {
            // 从交易记录中获取地区信息（如果有的话）
            return null;
          }
        } catch (e) {
          DebugConfig.errorPrint('获取iOS地区码失败: $e');
        }
      }
      return null;
    }
  }

  // 获取Android地区码
  Future<String?> _getAndroidCountryCode() async {
    try {
      const platform = MethodChannel('com.example.send_to_myself/locale');
      final String? countryCode = await platform.invokeMethod('getCountryCode');
      return countryCode;
    } catch (e) {
      DebugConfig.errorPrint('获取Android地区码失败: $e');
      return null;
    }
  }

  // 加载产品信息
  Future<void> _loadProducts() async {
    try {
      final Set<String> productIds = {};
      
      // 添加所有订阅产品ID
      for (final config in SubscriptionPlanConfig.allPlans) {
        if (config.productIdMonthly.isNotEmpty) {
          productIds.add(config.productIdMonthly);
        }
        if (config.productIdYearly.isNotEmpty) {
          productIds.add(config.productIdYearly);
        }
      }

      if (productIds.isEmpty) {
        DebugConfig.warningPrint('没有找到产品ID');
        return;
      }

      DebugConfig.debugPrint('加载产品信息: $productIds', module: 'SUBSCRIPTION');

      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.error != null) {
        DebugConfig.errorPrint('查询产品信息失败: ${response.error}');
        return;
      }

      _products = response.productDetails;
      DebugConfig.debugPrint('成功加载 ${_products.length} 个产品', module: 'SUBSCRIPTION');
      
      for (final product in _products) {
        DebugConfig.debugPrint('产品: ${product.id} - ${product.title} - ${product.price}', module: 'SUBSCRIPTION');
      }
    } catch (e) {
      DebugConfig.errorPrint('加载产品信息异常: $e');
    }
  }

  // 处理购买更新
  void _onPurchaseUpdated(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      DebugConfig.debugPrint('购买更新: ${purchase.productID} - ${purchase.status}', module: 'SUBSCRIPTION');
      
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _handlePendingPurchase(purchase);
          break;
        case PurchaseStatus.purchased:
          _handleSuccessfulPurchase(purchase);
          break;
        case PurchaseStatus.error:
          _handleFailedPurchase(purchase);
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

  // 处理待处理购买
  void _handlePendingPurchase(PurchaseDetails purchase) {
    DebugConfig.debugPrint('购买待处理: ${purchase.productID}', module: 'SUBSCRIPTION');
    // 可以在这里显示加载指示器
  }

  // 处理成功购买
  void _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    DebugConfig.debugPrint('购买成功: ${purchase.productID}', module: 'SUBSCRIPTION');
    
    try {
      // 验证购买
      if (await _verifyPurchase(purchase)) {
        // 更新订阅信息
        await _updateSubscriptionFromPurchase(purchase);
        
        // 完成购买
        await _inAppPurchase.completePurchase(purchase);
        
        DebugConfig.debugPrint('购买处理完成: ${purchase.productID}', module: 'SUBSCRIPTION');
      } else {
        DebugConfig.errorPrint('购买验证失败: ${purchase.productID}');
      }
    } catch (e) {
      DebugConfig.errorPrint('处理成功购买异常: $e');
    }
  }

  // 处理失败购买
  void _handleFailedPurchase(PurchaseDetails purchase) {
    DebugConfig.errorPrint('购买失败: ${purchase.productID} - ${purchase.error}');
  }

  // 处理恢复购买
  void _handleRestoredPurchase(PurchaseDetails purchase) async {
    DebugConfig.debugPrint('恢复购买: ${purchase.productID}', module: 'SUBSCRIPTION');
    
    try {
      if (await _verifyPurchase(purchase)) {
        await _updateSubscriptionFromPurchase(purchase);
        await _inAppPurchase.completePurchase(purchase);
        DebugConfig.debugPrint('恢复购买处理完成: ${purchase.productID}', module: 'SUBSCRIPTION');
      }
    } catch (e) {
      DebugConfig.errorPrint('处理恢复购买异常: $e');
    }
  }

  // 处理取消购买
  void _handleCanceledPurchase(PurchaseDetails purchase) {
    DebugConfig.debugPrint('购买取消: ${purchase.productID}', module: 'SUBSCRIPTION');
  }

  // 验证购买
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // 在生产环境中，这里应该向服务器验证购买
    // 现在暂时返回true
    return true;
  }

  // 从购买信息更新订阅
  Future<void> _updateSubscriptionFromPurchase(PurchaseDetails purchase) async {
    try {
      final config = SubscriptionPlanConfig.getPlanConfigByProductId(purchase.productID);
      if (config == null) {
        DebugConfig.errorPrint('未找到产品配置: ${purchase.productID}');
        return;
      }

      final isYearly = purchase.productID == config.productIdYearly;
      final now = DateTime.now();
      final endDate = isYearly ? now.add(const Duration(days: 365)) : now.add(const Duration(days: 30));

      // 获取当前货币的价格信息
      final priceInfo = config.getPriceInfo(_currentCurrency);
      
      final subscription = SubscriptionInfo(
        plan: config.plan,
        status: SubscriptionStatus.active,
        startDate: now,
        endDate: endDate,
        isYearly: isYearly,
        productId: purchase.productID,
        transactionId: purchase.purchaseID,
        price: isYearly ? priceInfo.yearlyPrice : priceInfo.monthlyPrice,
        currency: priceInfo.currencyCode,
      );

      await _updateSubscription(subscription);
      DebugConfig.debugPrint('订阅信息已更新: ${config.plan.name} (${isYearly ? '年付' : '月付'})', module: 'SUBSCRIPTION');
    } catch (e) {
      DebugConfig.errorPrint('更新订阅信息异常: $e');
    }
  }

  // 购买产品
  Future<bool> purchaseProduct(String productId) async {
    try {
      DebugConfig.debugPrint('开始购买产品: $productId', module: 'SUBSCRIPTION');
      
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('产品不存在: $productId'),
      );

      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      
      final bool result = await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      
      DebugConfig.debugPrint('购买请求结果: $result', module: 'SUBSCRIPTION');
      return result;
    } catch (e) {
      DebugConfig.errorPrint('购买产品异常: $e');
      return false;
    }
  }

  // 恢复购买
  Future<void> _restorePurchases() async {
    try {
      DebugConfig.debugPrint('恢复购买...', module: 'SUBSCRIPTION');
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      DebugConfig.errorPrint('恢复购买异常: $e');
    }
  }

  // 公开恢复购买方法
  Future<void> restorePurchases() async {
    await _restorePurchases();
  }

  // 更新订阅信息
  Future<void> _updateSubscription(SubscriptionInfo subscription) async {
    _currentSubscription = subscription;
    await _saveLocalSubscriptionInfo();
    _subscriptionController.add(subscription);
  }

  // 保存本地订阅信息
  Future<void> _saveLocalSubscriptionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subscription_info', jsonEncode(_currentSubscription.toJson()));
      DebugConfig.debugPrint('订阅信息已保存到本地', module: 'SUBSCRIPTION');
    } catch (e) {
      DebugConfig.errorPrint('保存订阅信息失败: $e');
    }
  }

  // 加载本地订阅信息
  Future<void> _loadLocalSubscriptionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? subscriptionJson = prefs.getString('subscription_info');
      
      if (subscriptionJson != null) {
        final Map<String, dynamic> json = jsonDecode(subscriptionJson);
        _currentSubscription = SubscriptionInfo.fromJson(json);
        DebugConfig.debugPrint('从本地加载订阅信息: ${_currentSubscription.plan.name}', module: 'SUBSCRIPTION');
      } else {
        DebugConfig.debugPrint('本地无订阅信息，使用免费版', module: 'SUBSCRIPTION');
      }
    } catch (e) {
      DebugConfig.errorPrint('加载本地订阅信息失败: $e');
      _currentSubscription = SubscriptionInfo.createFreeSubscription();
    }
  }

  // 检查订阅是否过期
  Future<void> checkSubscriptionExpiry() async {
    if (_currentSubscription.isExpired) {
      DebugConfig.debugPrint('订阅已过期，切换到免费版', module: 'SUBSCRIPTION');
      await _updateSubscription(SubscriptionInfo.createFreeSubscription());
    }
  }

  // 获取可用的购买选项
  List<PurchaseOption> getPurchaseOptions() {
    final List<PurchaseOption> options = [];
    
    for (final config in SubscriptionPlanConfig.allPlans) {
      if (config.plan == SubscriptionPlan.free) continue;
      
      final priceInfo = config.getPriceInfo(_currentCurrency);
      
      // 月付选项
      final monthlyProduct = _products.firstWhere(
        (p) => p.id == config.productIdMonthly,
        orElse: () => ProductDetails(
          id: config.productIdMonthly,
          title: '${config.plan.name} 月付',
          description: '${config.plan.name} 月付订阅',
          price: '${priceInfo.currencySymbol}${priceInfo.monthlyPrice.toStringAsFixed(2)}',
          rawPrice: priceInfo.monthlyPrice,
          currencyCode: priceInfo.currencyCode,
        ),
      );
      
      options.add(PurchaseOption.create(
        plan: config.plan,
        isYearly: false,
        currencyType: _currentCurrency,
        title: monthlyProduct.title,
        description: monthlyProduct.description,
      ));
      
      // 年付选项
      final yearlyProduct = _products.firstWhere(
        (p) => p.id == config.productIdYearly,
        orElse: () => ProductDetails(
          id: config.productIdYearly,
          title: '${config.plan.name} 年付',
          description: '${config.plan.name} 年付订阅',
          price: '${priceInfo.currencySymbol}${priceInfo.yearlyPrice.toStringAsFixed(2)}',
          rawPrice: priceInfo.yearlyPrice,
          currencyCode: priceInfo.currencyCode,
        ),
      );
      
      options.add(PurchaseOption.create(
        plan: config.plan,
        isYearly: true,
        currencyType: _currentCurrency,
        title: yearlyProduct.title,
        description: yearlyProduct.description,
      ));
    }
    
    return options;
  }

  // 检查群组人数是否超出限制
  bool isGroupMemberLimitExceeded(int memberCount) {
    return memberCount > _currentSubscription.maxGroupMembers;
  }

  // 获取群组成员上限
  int getGroupMemberLimit() {
    return _currentSubscription.maxGroupMembers;
  }

  // 检查是否可以添加更多成员
  bool canAddMoreMembers(int currentMemberCount) {
    return currentMemberCount < _currentSubscription.maxGroupMembers;
  }

  // 释放资源
  void dispose() {
    _subscription.cancel();
    _subscriptionController.close();
  }
} 