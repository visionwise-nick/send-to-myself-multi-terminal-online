import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription_model.dart';
import '../theme/app_theme.dart';
import '../utils/localization_helper.dart';
import '../services/subscription_service.dart';
import '../l10n/generated/app_localizations.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Consumer<SubscriptionProvider>(
        builder: (context, subscriptionProvider, child) {
          if (subscriptionProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          return _buildSubscriptionContent(subscriptionProvider, l10n);
        },
      ),
    );
  }

  Widget _buildSubscriptionContent(SubscriptionProvider provider, AppLocalizations l10n) {
    return CustomScrollView(
      slivers: [
        // 自定义AppBar
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              l10n.subscriptionPricingTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF667eea),
                    Color(0xFF764ba2),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      Icons.workspace_premium,
                      size: 60,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.subscriptionPricingSubtitle,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // 当前订阅状态
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildCurrentSubscriptionCard(provider, l10n),
            ),
          ),
        ),
        
        // 订阅计划列表
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildSubscriptionPlans(provider, l10n),
            ),
          ),
        ),
        
        // 恢复购买按钮
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildRestorePurchasesButton(provider, l10n),
            ),
          ),
        ),
        
        // 底部说明
        SliverToBoxAdapter(
          child: _buildBottomInfo(l10n),
        ),
      ],
    );
  }

  Widget _buildCurrentSubscriptionCard(SubscriptionProvider provider, AppLocalizations l10n) {
    final currentSubscription = provider.currentSubscription;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: provider.getSubscriptionStatusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.currentPlan,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _getLocalizedPlanName(currentSubscription.plan, l10n),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getDeviceLimitText(provider.maxGroupMembers, l10n),
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            if (currentSubscription.plan != SubscriptionPlan.free && 
                currentSubscription.endDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '有效期至: ${_formatDate(currentSubscription.endDate!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionPlans(SubscriptionProvider provider, AppLocalizations l10n) {
    final allPlans = SubscriptionPlanConfig.allPlans;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.subscriptionPricingSubtitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ...allPlans.map((plan) => _buildPlanCard(plan, provider, l10n)),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlanConfig plan, SubscriptionProvider provider, AppLocalizations l10n) {
    final isCurrentPlan = provider.currentSubscription.plan == plan.plan;
    final subscriptionService = SubscriptionService();
    final currentCurrency = subscriptionService.currentCurrency;
    final priceInfo = plan.getPriceInfo(currentCurrency);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentPlan 
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getLocalizedPlanName(plan.plan, l10n),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          if (isCurrentPlan) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '当前',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (plan.plan == SubscriptionPlan.pro) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.mostPopular,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getLocalizedPlanDescription(plan.plan, l10n),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (plan.plan != SubscriptionPlan.free) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatPrice(priceInfo.monthlyPrice, priceInfo.currencySymbol),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        '/ ${l10n.monthlyPlan}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            
            // 功能列表
            ...plan.featureKeys.map((featureKey) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getLocalizedFeature(featureKey, l10n),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            )),
            
            if (plan.plan != SubscriptionPlan.free && !isCurrentPlan) ...[
              const SizedBox(height: 16),
              _buildPurchaseButtons(plan, provider, l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButtons(SubscriptionPlanConfig plan, SubscriptionProvider provider, AppLocalizations l10n) {
    final subscriptionService = SubscriptionService();
    final currentCurrency = subscriptionService.currentCurrency;
    final priceInfo = plan.getPriceInfo(currentCurrency);
    
    return Column(
      children: [
        // 月付按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: provider.isPurchasing
                ? null
                : () => _handlePurchase(plan.productIdMonthly, provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.monthlyPlan,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  _formatPrice(priceInfo.monthlyPrice, priceInfo.currencySymbol),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 年付按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: provider.isPurchasing
                ? null
                : () => _handlePurchase(plan.productIdYearly, provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.yearlyPlan,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _calculateYearlyDiscount(priceInfo),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatPrice(priceInfo.yearlyPrice, priceInfo.currencySymbol),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestorePurchasesButton(SubscriptionProvider provider, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: provider.isLoading
              ? null
              : () => provider.restorePurchases(),
          child: Text(
            l10n.restorePurchases,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfo(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '订阅说明',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildInfoItems(l10n),
        ],
      ),
    );
  }

  List<Widget> _buildInfoItems(AppLocalizations l10n) {
    final items = [
      '订阅将自动续期，可随时取消',
      '取消订阅后仍可使用至订阅期结束',
      l10n.priceVariesByRegion,
      '24小时内可在App Store/Google Play管理订阅',
    ];
    
    return items.map((item) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: 8),
            decoration: BoxDecoration(
              color: AppTheme.textSecondaryColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }

  Future<void> _handlePurchase(String productId, SubscriptionProvider provider) async {
    try {
      final success = await provider.purchaseProduct(productId);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.purchaseSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.purchaseFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatPrice(double price, String currencySymbol) {
    // 对于日元和韩元，不显示小数点
    if (currencySymbol == '¥' || currencySymbol == '₩') {
      return '${currencySymbol}${price.toStringAsFixed(0)}';
    }
    return '${currencySymbol}${price.toStringAsFixed(2)}';
  }

  String _calculateYearlyDiscount(PriceInfo priceInfo) {
    final monthlyTotal = priceInfo.monthlyPrice * 12;
    final yearlyPrice = priceInfo.yearlyPrice;
    final discount = ((monthlyTotal - yearlyPrice) / monthlyTotal * 100).round();
    return '节省 $discount%';
  }

  String _getLocalizedPlanName(SubscriptionPlan plan, AppLocalizations l10n) {
    switch (plan) {
      case SubscriptionPlan.free:
        return l10n.freePlan;
      case SubscriptionPlan.basic:
        return l10n.basicPlan;
      case SubscriptionPlan.pro:
        return l10n.proPlan;
      case SubscriptionPlan.enterprise:
        return l10n.enterprisePlan;
    }
  }

  String _getLocalizedPlanDescription(SubscriptionPlan plan, AppLocalizations l10n) {
    switch (plan) {
      case SubscriptionPlan.free:
        return l10n.freePlanDescription;
      case SubscriptionPlan.basic:
        return l10n.basicPlanDescription;
      case SubscriptionPlan.pro:
        return l10n.proPlanDescription;
      case SubscriptionPlan.enterprise:
        return l10n.enterprisePlanDescription;
    }
  }

  String _getLocalizedFeature(String featureKey, AppLocalizations l10n) {
    switch (featureKey) {
      case 'feature2DeviceGroup':
        return l10n.feature2DeviceGroup;
      case 'featureBasicFileTransfer':
        return l10n.featureBasicFileTransfer;
      case 'featureTextMessage':
        return l10n.featureTextMessage;
      case 'featureImageTransfer':
        return l10n.featureImageTransfer;
      case 'feature5DeviceGroup':
        return l10n.feature5DeviceGroup;
      case 'featureUnlimitedFileTransfer':
        return l10n.featureUnlimitedFileTransfer;
      case 'featureVideoTransfer':
        return l10n.featureVideoTransfer;
      case 'featureMemoryFunction':
        return l10n.featureMemoryFunction;
      case 'featurePrioritySupport':
        return l10n.featurePrioritySupport;
      case 'feature10DeviceGroup':
        return l10n.feature10DeviceGroup;
      case 'featureAdvancedMemory':
        return l10n.featureAdvancedMemory;
      case 'featureDataSyncBackup':
        return l10n.featureDataSyncBackup;
      case 'featureDedicatedSupport':
        return l10n.featureDedicatedSupport;
      case 'featureTeamManagement':
        return l10n.featureTeamManagement;
      case 'featureUnlimitedDeviceGroup':
        return l10n.featureUnlimitedDeviceGroup;
      case 'featureAdvancedAnalytics':
        return l10n.featureAdvancedAnalytics;
      case 'featureCustomIntegration':
        return l10n.featureCustomIntegration;
      default:
        return featureKey;
    }
  }

  String _getDeviceLimitText(int maxGroupMembers, AppLocalizations l10n) {
    if (maxGroupMembers == -1) {
      return '无限台设备群组';
    }
    return '最多可添加 $maxGroupMembers 台设备到群组';
  }
} 