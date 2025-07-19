import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/subscription_service.dart';
import '../models/subscription_model.dart';
import '../config/debug_config.dart';

class SubscriptionProduct {
  final String id;
  final String name;
  final String description;
  final String price;
  final bool isCurrent;
  final List<String> features;

  SubscriptionProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isCurrent,
    required this.features,
  });
}

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  // 当前订阅信息
  SubscriptionInfo _currentSubscription = SubscriptionInfo.createFreeSubscription();
  
  // 可用的购买选项
  List<PurchaseOption> _purchaseOptions = [];
  
  // 加载状态
  bool _isLoading = false;
  
  // 购买状态
  bool _isPurchasing = false;
  
  // 错误信息
  String? _error;
  
  // 流监听器
  StreamSubscription<SubscriptionInfo>? _subscriptionStreamSubscription;
  
  // Getters
  SubscriptionInfo get currentSubscription => _currentSubscription;
  List<PurchaseOption> get purchaseOptions => _purchaseOptions;
  bool get isLoading => _isLoading;
  bool get isPurchasing => _isPurchasing;
  String? get error => _error;
  
  // 订阅状态相关
  bool get isSubscribed => _currentSubscription.plan != SubscriptionPlan.free;
  bool get isActiveSubscription => _currentSubscription.isActive;
  String get currentPlanName => SubscriptionPlanConfig.getPlanConfig(_currentSubscription.plan).name;
  int get maxGroupMembers => _currentSubscription.maxGroupMembers;
  
  // 🔥 新增：可用的订阅计划
  List<SubscriptionProduct> get availablePlans {
    // 示例数据，需要从你的订阅服务中获取
    return [
      SubscriptionProduct(
        id: 'basic_monthly',
        name: '基础版',
        description: '适合个人和小团队',
        price: '¥30/月',
        isCurrent: _currentSubscription.plan == SubscriptionPlan.basic,
        features: ['5台设备', '基础文件传输', '消息记忆'],
      ),
      SubscriptionProduct(
        id: 'pro_monthly',
        name: '专业版',
        description: '适合重度用户和企业',
        price: '¥60/月',
        isCurrent: _currentSubscription.plan == SubscriptionPlan.pro,
        features: ['10台设备', '无限制文件传输', '高级消息记忆', '数据同步备份'],
      ),
    ];
  }
  
  // 初始化
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();
    
    try {
      DebugConfig.debugPrint('初始化订阅Provider...', module: 'SUBSCRIPTION');
      
      // 初始化订阅服务
      await _subscriptionService.initialize();
      
      // 获取当前订阅信息
      _currentSubscription = _subscriptionService.currentSubscription;
      
      // 获取购买选项
      _purchaseOptions = _subscriptionService.getPurchaseOptions();
      
      // 监听订阅状态变化
      _subscriptionStreamSubscription = _subscriptionService.subscriptionStream.listen(
        (subscription) {
          _currentSubscription = subscription;
          notifyListeners();
          DebugConfig.debugPrint('订阅状态已更新: ${subscription.plan.name}', module: 'SUBSCRIPTION');
        },
        onError: (error) {
          _setError('订阅状态更新失败: $error');
          DebugConfig.errorPrint('订阅状态更新失败: $error');
        },
      );
      
      // 检查订阅是否过期
      await _subscriptionService.checkSubscriptionExpiry();
      
      DebugConfig.debugPrint('订阅Provider初始化完成', module: 'SUBSCRIPTION');
    } catch (e) {
      _setError('初始化订阅服务失败: $e');
      DebugConfig.errorPrint('初始化订阅服务失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // 购买产品
  Future<bool> purchaseProduct(String productId) async {
    if (_isPurchasing) {
      DebugConfig.warningPrint('正在购买中，请勿重复操作');
      return false;
    }
    
    _setPurchasing(true);
    _clearError();
    
    try {
      DebugConfig.debugPrint('开始购买产品: $productId', module: 'SUBSCRIPTION');
      
      final bool success = await _subscriptionService.purchaseProduct(productId);
      
      if (success) {
        DebugConfig.debugPrint('购买请求成功发送', module: 'SUBSCRIPTION');
        // 购买结果会通过流监听器自动更新
        return true;
      } else {
        _setError('购买失败');
        return false;
      }
    } catch (e) {
      _setError('购买异常: $e');
      DebugConfig.errorPrint('购买异常: $e');
      return false;
    } finally {
      _setPurchasing(false);
    }
  }
  
  // 恢复购买
  Future<void> restorePurchases() async {
    if (_isLoading) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      DebugConfig.debugPrint('恢复购买...', module: 'SUBSCRIPTION');
      await _subscriptionService.restorePurchases();
      DebugConfig.debugPrint('恢复购买请求已发送', module: 'SUBSCRIPTION');
    } catch (e) {
      _setError('恢复购买失败: $e');
      DebugConfig.errorPrint('恢复购买失败: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // 检查群组人数限制
  bool isGroupMemberLimitExceeded(int memberCount) {
    return _subscriptionService.isGroupMemberLimitExceeded(memberCount);
  }
  
  // 检查是否可以添加更多成员
  bool canAddMoreMembers(int currentMemberCount) {
    return _subscriptionService.canAddMoreMembers(currentMemberCount);
  }
  
  // 获取群组成员上限
  int getGroupMemberLimit() {
    return _subscriptionService.getGroupMemberLimit();
  }
  
  // 获取订阅计划配置
  SubscriptionPlanConfig getCurrentPlanConfig() {
    return SubscriptionPlanConfig.getPlanConfig(_currentSubscription.plan);
  }
  
  // 获取所有计划配置
  List<SubscriptionPlanConfig> getAllPlans() {
    return SubscriptionPlanConfig.allPlans;
  }
  
  // 获取推荐计划（基于当前使用情况）
  SubscriptionPlan getRecommendedPlan(int currentGroupMemberCount) {
    if (currentGroupMemberCount <= 2) {
      return SubscriptionPlan.free;
    } else if (currentGroupMemberCount <= 5) {
      return SubscriptionPlan.basic;
    } else {
      return SubscriptionPlan.pro;
    }
  }
  
  // 检查是否需要升级订阅
  bool needsUpgrade(int requiredMemberCount) {
    return requiredMemberCount > _currentSubscription.maxGroupMembers;
  }
  
  // 获取升级建议
  String getUpgradeSuggestion(int requiredMemberCount) {
    if (requiredMemberCount <= 2) {
      return '当前免费版已满足需求';
    } else if (requiredMemberCount <= 5) {
      return '建议升级到基础版以支持5台设备';
    } else if (requiredMemberCount <= 10) {
      return '建议升级到专业版以支持10台设备';
    } else {
      return '设备数量超出当前支持范围';
    }
  }
  
  // 刷新购买选项
  Future<void> refreshPurchaseOptions() async {
    try {
      _purchaseOptions = _subscriptionService.getPurchaseOptions();
      notifyListeners();
      DebugConfig.debugPrint('购买选项已刷新', module: 'SUBSCRIPTION');
    } catch (e) {
      _setError('刷新购买选项失败: $e');
      DebugConfig.errorPrint('刷新购买选项失败: $e');
    }
  }
  
  // 检查订阅过期
  Future<void> checkSubscriptionExpiry() async {
    try {
      await _subscriptionService.checkSubscriptionExpiry();
      _currentSubscription = _subscriptionService.currentSubscription;
      notifyListeners();
    } catch (e) {
      DebugConfig.errorPrint('检查订阅过期状态失败: $e');
    }
  }
  
  // 获取订阅状态文本
  String getSubscriptionStatusText() {
    switch (_currentSubscription.status) {
      case SubscriptionStatus.active:
        if (_currentSubscription.plan == SubscriptionPlan.free) {
          return '免费版';
        } else {
          final remainingDays = _currentSubscription.remainingDays;
          return '${currentPlanName} - ${remainingDays}天剩余';
        }
      case SubscriptionStatus.expired:
        return '订阅已过期';
      case SubscriptionStatus.cancelled:
        return '订阅已取消';
      case SubscriptionStatus.pending:
        return '订阅处理中';
      case SubscriptionStatus.none:
        return '未订阅';
    }
  }
  
  // 获取订阅状态颜色
  Color getSubscriptionStatusColor() {
    switch (_currentSubscription.status) {
      case SubscriptionStatus.active:
        return _currentSubscription.plan == SubscriptionPlan.free 
            ? Colors.grey 
            : Colors.green;
      case SubscriptionStatus.expired:
        return Colors.red;
      case SubscriptionStatus.cancelled:
        return Colors.orange;
      case SubscriptionStatus.pending:
        return Colors.blue;
      case SubscriptionStatus.none:
        return Colors.grey;
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
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _subscriptionStreamSubscription?.cancel();
    _subscriptionService.dispose();
    super.dispose();
  }
} 