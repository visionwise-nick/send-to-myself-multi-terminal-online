import 'package:flutter/material.dart';
import 'localization_helper.dart';

class TimeUtils {
  /// 解析时间字符串并转换为本地时间
  static DateTime? parseToLocal(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return null;
    
    try {
      DateTime dateTime = DateTime.parse(dateTimeStr);
      
      // 如果没有时区信息，假设是UTC时间
      if (!dateTimeStr.contains('Z') && !dateTimeStr.contains('+') && !dateTimeStr.contains('-', 10)) {
        dateTime = DateTime.parse(dateTimeStr + 'Z');
      }
      
      return dateTime.toLocal();
    } catch (e) {
      return null;
    }
  }
  
  /// 格式化日期 (YYYY-MM-DD)
  static String formatDate(dynamic date, BuildContext context) {
    if (date == null) return LocalizationHelper.of(context).unknown;
    
    final localTime = parseToLocal(date.toString());
    if (localTime == null) return LocalizationHelper.of(context).unknown;
    
    return '${localTime.year}-${localTime.month.toString().padLeft(2, '0')}-${localTime.day.toString().padLeft(2, '0')}';
  }
  
  /// 格式化日期时间 (YYYY-MM-DD HH:mm)
  static String formatDateTime(dynamic dateTime, BuildContext context) {
    if (dateTime == null) return LocalizationHelper.of(context).unknown;
    
    final localTime = parseToLocal(dateTime.toString());
    if (localTime == null) return LocalizationHelper.of(context).unknown;
    
    return '${localTime.year}-${localTime.month.toString().padLeft(2, '0')}-${localTime.day.toString().padLeft(2, '0')} '
        '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  }
  
  /// 格式化相对时间 (例如: 5分钟前, 2小时前)
  static String formatRelativeTime(dynamic dateTime, BuildContext context) {
    if (dateTime == null) return '';
    
    final localTime = parseToLocal(dateTime.toString());
    if (localTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(localTime);
    
    if (difference.inMinutes < 1) {
      return LocalizationHelper.of(context).justActive;
    } else if (difference.inMinutes < 60) {
      return LocalizationHelper.of(context).minutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return LocalizationHelper.of(context).hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return LocalizationHelper.of(context).daysAgo(difference.inDays);
    } else {
      // 超过一周显示具体日期
      return LocalizationHelper.of(context).monthDay(localTime.month, localTime.day);
    }
  }
  
  /// 格式化过期时间 (用于二维码过期显示)
  static String formatExpirationTime(String? expiresAt, BuildContext context) {
    if (expiresAt == null) return LocalizationHelper.of(context).unknown;
    
    final localTime = parseToLocal(expiresAt);
    if (localTime == null) return LocalizationHelper.of(context).unknown;
    
    final now = DateTime.now();
    final difference = localTime.difference(now);
    
    if (difference.inMinutes > 0) {
      if (difference.inHours > 0) {
        return LocalizationHelper.of(context).expiresInHoursAndMinutes(difference.inHours, difference.inMinutes % 60);
      } else {
        return LocalizationHelper.of(context).expiresInMinutes(difference.inMinutes);
      }
    } else {
      return LocalizationHelper.of(context).expired;
    }
  }
  
  /// 检查时间是否过期
  static bool isExpired(String? expiresAt) {
    if (expiresAt == null) return true;
    
    final localTime = parseToLocal(expiresAt);
    if (localTime == null) return true;
    
    return DateTime.now().isAfter(localTime);
  }
  
  /// 格式化时间 (HH:MM)
  static String formatTime(dynamic time) {
    if (time == null) return '';
    
    final localTime = parseToLocal(time.toString());
    if (localTime == null) return '';
    
    return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  }
  
  /// 判断两个日期是否在同一天
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
  
  /// 格式化聊天消息的日期分组标题
  static String formatDateGroupTitle(dynamic dateTime, BuildContext context) {
    if (dateTime == null) return '';
    
    final localTime = parseToLocal(dateTime.toString());
    if (localTime == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(localTime.year, localTime.month, localTime.day);
    
    if (isSameDay(messageDate, today)) {
      return LocalizationHelper.of(context).today;
    } else if (isSameDay(messageDate, yesterday)) {
      return LocalizationHelper.of(context).yesterday;
    } else if (now.difference(messageDate).inDays < 7) {
      // 一周内显示星期几
      final weekdays = [
        LocalizationHelper.of(context).monday,
        LocalizationHelper.of(context).tuesday,
        LocalizationHelper.of(context).wednesday,
        LocalizationHelper.of(context).thursday,
        LocalizationHelper.of(context).friday,
        LocalizationHelper.of(context).saturday,
        LocalizationHelper.of(context).sunday
      ];
      return weekdays[localTime.weekday - 1];
    } else if (localTime.year == now.year) {
      // 同年显示月日
      return LocalizationHelper.of(context).monthDay(localTime.month, localTime.day);
    } else {
      // 不同年显示完整日期
      return LocalizationHelper.of(context).yearMonthDay(localTime.month, localTime.day, localTime.year);
    }
  }
  
  /// 格式化聊天消息的完整时间戳（日期+时间，用于消息气泡外）
  static String formatChatDateTime(dynamic dateTime) {
    if (dateTime == null) return '';
    
    final localTime = parseToLocal(dateTime.toString());
    if (localTime == null) return '';
    
    // 格式：05-25 16:30:24
    return '${localTime.month.toString().padLeft(2, '0')}-${localTime.day.toString().padLeft(2, '0')} '
           '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}:${localTime.second.toString().padLeft(2, '0')}';
  }
  
  /// 检查是否需要显示日期分组（两条消息间隔超过一定时间）
  static bool shouldShowDateGroup(DateTime? prevTime, DateTime currentTime) {
    if (prevTime == null) return true;
    
    // 如果不在同一天，需要显示日期分组
    if (!isSameDay(prevTime, currentTime)) {
      return true;
    }
    
    // 如果间隔超过2小时，也显示时间分组
    final difference = currentTime.difference(prevTime);
    return difference.inHours >= 2;
  }
} 