import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription_model.dart';
import '../theme/app_theme.dart';
import '../utils/localization_helper.dart';
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
    final provider = Provider.of<SubscriptionProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
      slivers: [
        SliverAppBar(
            title: Text(l10n.subscriptionPricingTitle),
            backgroundColor: Colors.transparent,
            elevation: 0,
          pinned: true,
          ),
        SliverToBoxAdapter(
      child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  const SizedBox(height: 16),
                  Text(
                    l10n.subscriptionPricingSubtitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  if (provider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (provider.error != null)
                    _buildErrorWidget(provider.error!, l10n)
                  else
                    ...provider.availablePlans.map((plan) => _buildPlanCard(
                        plan,
                        provider.currentSubscription.id == plan.id,
                        provider,
                        l10n)),
                  const SizedBox(height: 24),
                  _buildRestoreButton(provider, l10n),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      l10n.priceVariesByRegion,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    SubscriptionProduct product,
    bool isCurrent,
    SubscriptionProvider provider,
    AppLocalizations l10n,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _handlePurchase(product.id, provider),
        borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                  Row(
                    children: [
                      Icon(
                        isCurrent
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isCurrent
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isCurrent
                                  ? AppTheme.primaryColor
                                  : Theme.of(context).textTheme.bodyLarge!.color,
                            ),
                          ),
                          if (product.isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                l10n.mostPopular,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (product.id != 'free') ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          product.price,
                        style: const TextStyle(
                          fontSize: 24,
                            fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  ]
              ],
            ),
            const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              ...product.features.map((featureKey) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                    const Icon(Icons.check,
                        color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getLocalizedFeatureText(featureKey, l10n),
                        style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            )),
              if (product.id != 'free' && !isCurrent) ...[
              const SizedBox(height: 16),
                _buildPurchaseButtons(product, provider, l10n),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseButtons(
    SubscriptionProduct product,
    SubscriptionProvider provider,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _handlePurchase(product.id, provider),
            style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: AppTheme.primaryColor),
          ),
          child: Text(product.price),
        ),
      ],
    );
  }

  Widget _buildRestoreButton(
      SubscriptionProvider provider, AppLocalizations l10n) {
    return Center(
        child: TextButton(
        onPressed: () => provider.restorePurchases(),
          child: Text(
            l10n.restorePurchases,
          style: const TextStyle(
              color: AppTheme.primaryColor,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  void _handlePurchase(String productId, SubscriptionProvider provider) async {
      final success = await provider.purchaseProduct(productId);
    if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationHelper.of(context).purchaseSuccess)),
        );
    } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationHelper.of(context).purchaseFailed)),
      );
    }
  }

  // Helper
  String _getLocalizedPlanName(SubscriptionPlan plan, AppLocalizations l10n) {
    switch (plan) {
      case SubscriptionPlan.free:
        return l10n.freePlan;
      case SubscriptionPlan.basic:
        return l10n.basicPlan;
      case SubscriptionPlan.pro:
        return l10n.proPlan;
      default:
        return '';
    }
  }

  String _getLocalizedPlanDescription(
      SubscriptionPlan plan, AppLocalizations l10n) {
    switch (plan) {
      case SubscriptionPlan.free:
        return l10n.freePlanDescription;
      case SubscriptionPlan.basic:
        return l10n.basicPlanDescription;
      case SubscriptionPlan.pro:
        return l10n.proPlanDescription;
      default:
        return '';
    }
  }

  String _getLocalizedFeatureText(String featureKey, AppLocalizations l10n) {
    switch (featureKey) {
      case '2_device_group':
        return l10n.feature2DeviceGroup;
      case 'basic_file_transfer':
        return l10n.featureBasicFileTransfer;
      case 'text_message':
        return l10n.featureTextMessage;
      case 'image_transfer':
        return l10n.featureImageTransfer;
      case '5_device_group':
        return l10n.feature5DeviceGroup;
      case 'unlimited_file_transfer':
        return l10n.featureUnlimitedFileTransfer;
      case 'video_transfer':
        return l10n.featureVideoTransfer;
      default:
        return featureKey;
    }
  }

  String _formatPrice(Map<String, dynamic> priceInfo, bool isYearly) {
    final price = priceInfo[isYearly ? 'yearlyPrice' : 'monthlyPrice'] ?? 'N/A';
    final currencySymbol = priceInfo['currencySymbol'] ?? '';
    return '$currencySymbol$price/${isYearly ? 'yr' : 'mo'}';
  }

  Widget _buildErrorWidget(String error, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '初始化订阅服务失败:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.orange.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '应用尚未在应用商店上架，无法获取真实产品信息。\n当前显示模拟订阅计划用于开发测试。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.orange.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 