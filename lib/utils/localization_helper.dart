import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

/// 本地化帮助类
/// 提供便捷的方法来获取本地化字符串
class LocalizationHelper {
  /// 获取当前上下文的本地化对象
  static AppLocalizations of(BuildContext context) {
    return AppLocalizations.of(context)!;
  }

  /// 检查当前语言是否为中文
  static bool isChineseLocale(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'zh';
  }

  /// 检查当前语言是否为英文
  static bool isEnglishLocale(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'en';
  }

  /// 检查当前语言是否为从右到左的语言（如阿拉伯语、希伯来语）
  static bool isRTLLocale(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'ar' || 
           locale.languageCode == 'he' ||
           locale.languageCode == 'fa' ||
           locale.languageCode == 'ur';
  }

  /// 获取当前语言代码
  static String getCurrentLanguageCode(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode;
  }

  /// 获取当前本地化信息
  static Locale getCurrentLocale(BuildContext context) {
    return Localizations.localeOf(context);
  }

  /// 支持的语言列表
  static List<Locale> get supportedLocales => AppLocalizations.supportedLocales;

  /// 格式化文件大小（本地化）
  static String formatFileSize(BuildContext context, int bytes) {
    final l10n = of(context);
    
    if (bytes < 1024) {
      return '$bytes ${l10n.bytes}';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} ${l10n.kilobytes}';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ${l10n.megabytes}';
    } else if (bytes < 1024 * 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ${l10n.gigabytes}';
    } else {
      return '${(bytes / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(1)} ${l10n.terabytes}';
    }
  }

  /// 格式化时间（本地化）
  static String formatTimeAgo(BuildContext context, DateTime dateTime) {
    final l10n = of(context);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return l10n.now;
    } else if (difference.inHours < 1) {
      return l10n.minutesAgo(difference.inMinutes);
    } else if (difference.inDays < 1) {
      return l10n.hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else {
      // 对于超过一周的时间，直接显示日期
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }

  /// 获取语言显示名称
  static String getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      case 'es':
        return 'Español';
      case 'hi':
        return 'हिन्दी';
      case 'ar':
        return 'العربية';
      case 'pt':
        return 'Português';
      case 'bn':
        return 'বাংলা';
      case 'ru':
        return 'Русский';
      case 'ja':
        return '日本語';
      case 'de':
        return 'Deutsch';
      case 'ko':
        return '한국어';
      case 'fr':
        return 'Français';
      case 'tr':
        return 'Türkçe';
      case 'vi':
        return 'Tiếng Việt';
      case 'it':
        return 'Italiano';
      case 'th':
        return 'ไทย';
      case 'pl':
        return 'Polski';
      case 'uk':
        return 'Українська';
      case 'nl':
        return 'Nederlands';
      case 'sv':
        return 'Svenska';
      case 'da':
        return 'Dansk';
      case 'no':
        return 'Norsk';
      case 'fi':
        return 'Suomi';
      case 'he':
        return 'עברית';
      case 'id':
        return 'Bahasa Indonesia';
      case 'ms':
        return 'Bahasa Melayu';
      case 'cs':
        return 'Čeština';
      case 'hu':
        return 'Magyar';
      case 'ro':
        return 'Română';
      case 'sk':
        return 'Slovenčina';
      default:
        return languageCode.toUpperCase();
    }
  }

  /// 获取所有支持的语言信息
  static List<Map<String, String>> getSupportedLanguages() {
    return supportedLocales.map((locale) => {
      'code': locale.languageCode,
      'name': getLanguageDisplayName(locale.languageCode),
    }).toList();
  }
} 