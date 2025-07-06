// 订阅计划枚举
enum SubscriptionPlan {
  free,        // 免费版 - 2人群组
  basic,       // 基础版 - 5人群组  
  pro,         // 专业版 - 10人群组
  enterprise,  // 企业版 - 无限人群组
}

// 订阅状态枚举
enum SubscriptionStatus {
  active,      // 订阅生效
  expired,     // 订阅过期
  cancelled,   // 订阅取消
  pending,     // 订阅待处理
  none,        // 无订阅
}

// 货币类型枚举
enum CurrencyType {
  usd,  // 美元
  cny,  // 人民币
  eur,  // 欧元
  jpy,  // 日元
  gbp,  // 英镑
  krw,  // 韩元
}

// 价格信息类
class PriceInfo {
  final double monthlyPrice;
  final double yearlyPrice;
  final CurrencyType currency;
  final String currencySymbol;
  final String currencyCode;

  const PriceInfo({
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.currency,
    required this.currencySymbol,
    required this.currencyCode,
  });
}

// 订阅计划配置
class SubscriptionPlanConfig {
  final SubscriptionPlan plan;
  final String nameKey;  // 本地化key
  final String descriptionKey;  // 本地化key
  final int maxGroupMembers;
  final String productIdMonthly;
  final String productIdYearly;
  final List<String> featureKeys;  // 本地化key列表
  final Map<CurrencyType, PriceInfo> prices;

  const SubscriptionPlanConfig({
    required this.plan,
    required this.nameKey,
    required this.descriptionKey,
    required this.maxGroupMembers,
    required this.productIdMonthly,
    required this.productIdYearly,
    required this.featureKeys,
    required this.prices,
  });

  // 根据货币类型获取价格信息
  PriceInfo getPriceInfo(CurrencyType currency) {
    return prices[currency] ?? prices[CurrencyType.usd]!;
  }

  // 获取计划名称（简化版，用于调试和显示）
  String get name {
    switch (plan) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.basic:
        return 'Basic';
      case SubscriptionPlan.pro:
        return 'Pro';
      case SubscriptionPlan.enterprise:
        return 'Enterprise';
    }
  }

  // 价格定义
  static const Map<CurrencyType, PriceInfo> _freePrices = {
    CurrencyType.usd: PriceInfo(
      monthlyPrice: 0,
      yearlyPrice: 0,
      currency: CurrencyType.usd,
      currencySymbol: '\$',
      currencyCode: 'USD',
    ),
    CurrencyType.cny: PriceInfo(
      monthlyPrice: 0,
      yearlyPrice: 0,
      currency: CurrencyType.cny,
      currencySymbol: '¥',
      currencyCode: 'CNY',
    ),
    CurrencyType.eur: PriceInfo(
      monthlyPrice: 0,
      yearlyPrice: 0,
      currency: CurrencyType.eur,
      currencySymbol: '€',
      currencyCode: 'EUR',
    ),
    CurrencyType.jpy: PriceInfo(
      monthlyPrice: 0,
      yearlyPrice: 0,
      currency: CurrencyType.jpy,
      currencySymbol: '¥',
      currencyCode: 'JPY',
    ),
    CurrencyType.gbp: PriceInfo(
      monthlyPrice: 0,
      yearlyPrice: 0,
      currency: CurrencyType.gbp,
      currencySymbol: '£',
      currencyCode: 'GBP',
    ),
    CurrencyType.krw: PriceInfo(
      monthlyPrice: 0,
      yearlyPrice: 0,
      currency: CurrencyType.krw,
      currencySymbol: '₩',
      currencyCode: 'KRW',
    ),
  };

  static const Map<CurrencyType, PriceInfo> _basicPrices = {
    CurrencyType.usd: PriceInfo(
      monthlyPrice: 1.99,
      yearlyPrice: 19.99,
      currency: CurrencyType.usd,
      currencySymbol: '\$',
      currencyCode: 'USD',
    ),
    CurrencyType.cny: PriceInfo(
      monthlyPrice: 9.9,
      yearlyPrice: 99.9,
      currency: CurrencyType.cny,
      currencySymbol: '¥',
      currencyCode: 'CNY',
    ),
    CurrencyType.eur: PriceInfo(
      monthlyPrice: 1.99,
      yearlyPrice: 19.99,
      currency: CurrencyType.eur,
      currencySymbol: '€',
      currencyCode: 'EUR',
    ),
    CurrencyType.jpy: PriceInfo(
      monthlyPrice: 290,
      yearlyPrice: 2900,
      currency: CurrencyType.jpy,
      currencySymbol: '¥',
      currencyCode: 'JPY',
    ),
    CurrencyType.gbp: PriceInfo(
      monthlyPrice: 1.79,
      yearlyPrice: 17.99,
      currency: CurrencyType.gbp,
      currencySymbol: '£',
      currencyCode: 'GBP',
    ),
    CurrencyType.krw: PriceInfo(
      monthlyPrice: 2600,
      yearlyPrice: 26000,
      currency: CurrencyType.krw,
      currencySymbol: '₩',
      currencyCode: 'KRW',
    ),
  };

  static const Map<CurrencyType, PriceInfo> _proPrices = {
    CurrencyType.usd: PriceInfo(
      monthlyPrice: 4.99,
      yearlyPrice: 49.99,
      currency: CurrencyType.usd,
      currencySymbol: '\$',
      currencyCode: 'USD',
    ),
    CurrencyType.cny: PriceInfo(
      monthlyPrice: 19.9,
      yearlyPrice: 199.9,
      currency: CurrencyType.cny,
      currencySymbol: '¥',
      currencyCode: 'CNY',
    ),
    CurrencyType.eur: PriceInfo(
      monthlyPrice: 4.99,
      yearlyPrice: 49.99,
      currency: CurrencyType.eur,
      currencySymbol: '€',
      currencyCode: 'EUR',
    ),
    CurrencyType.jpy: PriceInfo(
      monthlyPrice: 750,
      yearlyPrice: 7500,
      currency: CurrencyType.jpy,
      currencySymbol: '¥',
      currencyCode: 'JPY',
    ),
    CurrencyType.gbp: PriceInfo(
      monthlyPrice: 4.49,
      yearlyPrice: 44.99,
      currency: CurrencyType.gbp,
      currencySymbol: '£',
      currencyCode: 'GBP',
    ),
    CurrencyType.krw: PriceInfo(
      monthlyPrice: 6500,
      yearlyPrice: 65000,
      currency: CurrencyType.krw,
      currencySymbol: '₩',
      currencyCode: 'KRW',
    ),
  };

  static const Map<CurrencyType, PriceInfo> _enterprisePrices = {
    CurrencyType.usd: PriceInfo(
      monthlyPrice: 9.99,
      yearlyPrice: 99.99,
      currency: CurrencyType.usd,
      currencySymbol: '\$',
      currencyCode: 'USD',
    ),
    CurrencyType.cny: PriceInfo(
      monthlyPrice: 39.9,
      yearlyPrice: 399.9,
      currency: CurrencyType.cny,
      currencySymbol: '¥',
      currencyCode: 'CNY',
    ),
    CurrencyType.eur: PriceInfo(
      monthlyPrice: 9.99,
      yearlyPrice: 99.99,
      currency: CurrencyType.eur,
      currencySymbol: '€',
      currencyCode: 'EUR',
    ),
    CurrencyType.jpy: PriceInfo(
      monthlyPrice: 1500,
      yearlyPrice: 15000,
      currency: CurrencyType.jpy,
      currencySymbol: '¥',
      currencyCode: 'JPY',
    ),
    CurrencyType.gbp: PriceInfo(
      monthlyPrice: 8.99,
      yearlyPrice: 89.99,
      currency: CurrencyType.gbp,
      currencySymbol: '£',
      currencyCode: 'GBP',
    ),
    CurrencyType.krw: PriceInfo(
      monthlyPrice: 13000,
      yearlyPrice: 130000,
      currency: CurrencyType.krw,
      currencySymbol: '₩',
      currencyCode: 'KRW',
    ),
  };

  static const List<SubscriptionPlanConfig> allPlans = [
    SubscriptionPlanConfig(
      plan: SubscriptionPlan.free,
      nameKey: 'freePlan',
      descriptionKey: 'freePlanDescription',
      maxGroupMembers: 2,
      productIdMonthly: '',
      productIdYearly: '',
      featureKeys: [
        'feature2DeviceGroup',
        'featureBasicFileTransfer',
        'featureTextMessage',
        'featureImageTransfer',
      ],
      prices: _freePrices,
    ),
    SubscriptionPlanConfig(
      plan: SubscriptionPlan.basic,
      nameKey: 'basicPlan',
      descriptionKey: 'basicPlanDescription',
      maxGroupMembers: 5,
      productIdMonthly: 'send_to_myself_basic_monthly',
      productIdYearly: 'send_to_myself_basic_yearly',
      featureKeys: [
        'feature5DeviceGroup',
        'featureUnlimitedFileTransfer',
        'featureVideoTransfer',
        'featureMemoryFunction',
        'featurePrioritySupport',
      ],
      prices: _basicPrices,
    ),
    SubscriptionPlanConfig(
      plan: SubscriptionPlan.pro,
      nameKey: 'proPlan',
      descriptionKey: 'proPlanDescription',
      maxGroupMembers: 10,
      productIdMonthly: 'send_to_myself_pro_monthly',
      productIdYearly: 'send_to_myself_pro_yearly',
      featureKeys: [
        'feature10DeviceGroup',
        'featureUnlimitedFileTransfer',
        'featureAdvancedMemory',
        'featureDataSyncBackup',
        'featureDedicatedSupport',
        'featureTeamManagement',
      ],
      prices: _proPrices,
    ),
    SubscriptionPlanConfig(
      plan: SubscriptionPlan.enterprise,
      nameKey: 'enterprisePlan',
      descriptionKey: 'enterprisePlanDescription',
      maxGroupMembers: -1, // -1 表示无限制
      productIdMonthly: 'send_to_myself_enterprise_monthly',
      productIdYearly: 'send_to_myself_enterprise_yearly',
      featureKeys: [
        'featureUnlimitedDeviceGroup',
        'featureUnlimitedFileTransfer',
        'featureAdvancedMemory',
        'featureDataSyncBackup',
        'featureDedicatedSupport',
        'featureTeamManagement',
        'featureAdvancedAnalytics',
        'featureCustomIntegration',
      ],
      prices: _enterprisePrices,
    ),
  ];

  // 根据计划类型获取配置
  static SubscriptionPlanConfig getPlanConfig(SubscriptionPlan plan) {
    return allPlans.firstWhere((config) => config.plan == plan);
  }

  // 根据产品ID获取配置
  static SubscriptionPlanConfig? getPlanConfigByProductId(String productId) {
    for (final config in allPlans) {
      if (config.productIdMonthly == productId || config.productIdYearly == productId) {
        return config;
      }
    }
    return null;
  }

  // 根据地区获取默认货币
  static CurrencyType getDefaultCurrency(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'CN':
      case 'HK':
      case 'MO':
      case 'TW':
        return CurrencyType.cny;
      case 'US':
      case 'CA':
      case 'MX':
        return CurrencyType.usd;
      case 'DE':
      case 'FR':
      case 'IT':
      case 'ES':
      case 'NL':
      case 'BE':
      case 'AT':
      case 'PT':
      case 'FI':
      case 'IE':
      case 'GR':
      case 'LU':
      case 'MT':
      case 'CY':
      case 'SK':
      case 'SI':
      case 'EE':
      case 'LV':
      case 'LT':
        return CurrencyType.eur;
      case 'JP':
        return CurrencyType.jpy;
      case 'GB':
        return CurrencyType.gbp;
      case 'KR':
        return CurrencyType.krw;
      default:
        return CurrencyType.usd;
    }
  }
}

// 订阅信息模型
class SubscriptionInfo {
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isYearly;
  final String? productId;
  final String? transactionId;
  final double? price;
  final String? currency;

  const SubscriptionInfo({
    required this.plan,
    required this.status,
    this.startDate,
    this.endDate,
    required this.isYearly,
    this.productId,
    this.transactionId,
    this.price,
    this.currency,
  });

  // 是否是活跃订阅
  bool get isActive => status == SubscriptionStatus.active;

  // 是否过期
  bool get isExpired => endDate != null && DateTime.now().isAfter(endDate!);

  // 剩余天数
  int get remainingDays {
    if (endDate == null) return 0;
    final now = DateTime.now();
    if (now.isAfter(endDate!)) return 0;
    return endDate!.difference(now).inDays;
  }

  // 获取群组成员上限
  int get maxGroupMembers {
    return SubscriptionPlanConfig.getPlanConfig(plan).maxGroupMembers;
  }

  // 从JSON创建
  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      plan: SubscriptionPlan.values.firstWhere(
        (p) => p.name == json['plan'],
        orElse: () => SubscriptionPlan.free,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SubscriptionStatus.none,
      ),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isYearly: json['isYearly'] ?? false,
      productId: json['productId'],
      transactionId: json['transactionId'],
      price: json['price']?.toDouble(),
      currency: json['currency'],
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'plan': plan.name,
      'status': status.name,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isYearly': isYearly,
      'productId': productId,
      'transactionId': transactionId,
      'price': price,
      'currency': currency,
    };
  }

  // 创建副本
  SubscriptionInfo copyWith({
    SubscriptionPlan? plan,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool? isYearly,
    String? productId,
    String? transactionId,
    double? price,
    String? currency,
  }) {
    return SubscriptionInfo(
      plan: plan ?? this.plan,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isYearly: isYearly ?? this.isYearly,
      productId: productId ?? this.productId,
      transactionId: transactionId ?? this.transactionId,
      price: price ?? this.price,
      currency: currency ?? this.currency,
    );
  }

  // 创建免费版订阅
  static SubscriptionInfo createFreeSubscription() {
    return const SubscriptionInfo(
      plan: SubscriptionPlan.free,
      status: SubscriptionStatus.active,
      isYearly: false,
    );
  }
}

// 购买选项
class PurchaseOption {
  final SubscriptionPlan plan;
  final bool isYearly;
  final String productId;
  final double price;
  final String currency;
  final String currencySymbol;
  final String title;
  final String description;

  const PurchaseOption({
    required this.plan,
    required this.isYearly,
    required this.productId,
    required this.price,
    required this.currency,
    required this.currencySymbol,
    required this.title,
    required this.description,
  });

  // 获取折扣信息（年付相对于月付）
  String get discountInfo {
    if (!isYearly) return '';
    
    final config = SubscriptionPlanConfig.getPlanConfig(plan);
    final currencyType = CurrencyType.values.firstWhere((c) => c.name == currency.toLowerCase());
    final priceInfo = config.getPriceInfo(currencyType);
    final monthlyTotal = priceInfo.monthlyPrice * 12;
    final yearlyPrice = priceInfo.yearlyPrice;
    final discount = ((monthlyTotal - yearlyPrice) / monthlyTotal * 100).round();
    
    return '节省 $discount%';
  }

  // 获取价格显示文本
  String get priceText {
    // 根据货币类型决定是否显示小数点
    final isJpyOrKrw = currency.toLowerCase() == 'jpy' || currency.toLowerCase() == 'krw';
    final formattedPrice = isJpyOrKrw ? price.toStringAsFixed(0) : price.toStringAsFixed(2);
    
    return isYearly ? '$currencySymbol$formattedPrice/年' : '$currencySymbol$formattedPrice/月';
  }

  // 创建购买选项
  static PurchaseOption create({
    required SubscriptionPlan plan,
    required bool isYearly,
    required CurrencyType currencyType,
    required String title,
    required String description,
  }) {
    final config = SubscriptionPlanConfig.getPlanConfig(plan);
    final priceInfo = config.getPriceInfo(currencyType);
    final price = isYearly ? priceInfo.yearlyPrice : priceInfo.monthlyPrice;
    final productId = isYearly ? config.productIdYearly : config.productIdMonthly;

    return PurchaseOption(
      plan: plan,
      isYearly: isYearly,
      productId: productId,
      price: price,
      currency: priceInfo.currencyCode,
      currencySymbol: priceInfo.currencySymbol,
      title: title,
      description: description,
    );
  }
} 