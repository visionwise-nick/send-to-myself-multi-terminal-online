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
      print('解析时间失败: $e, 原始时间: $dateTimeStr');
      return null;
    }
  }
  
  /// 格式化日期 (YYYY-MM-DD)
  static String formatDate(dynamic date) {
    if (date == null) return '未知';
    
    final localTime = parseToLocal(date.toString());
    if (localTime == null) return '未知';
    
    return '${localTime.year}-${localTime.month.toString().padLeft(2, '0')}-${localTime.day.toString().padLeft(2, '0')}';
  }
  
  /// 格式化日期时间 (YYYY-MM-DD HH:mm)
  static String formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '未知';
    
    final localTime = parseToLocal(dateTime.toString());
    if (localTime == null) return '未知';
    
    return '${localTime.year}-${localTime.month.toString().padLeft(2, '0')}-${localTime.day.toString().padLeft(2, '0')} '
        '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  }
  
  /// 格式化相对时间 (例如: 5分钟前, 2小时前)
  static String formatRelativeTime(dynamic dateTime) {
    if (dateTime == null) return '';
    
    final localTime = parseToLocal(dateTime.toString());
    if (localTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(localTime);
    
    if (difference.inMinutes < 1) {
      return '刚刚活跃';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      // 超过一周显示具体日期
      return '${localTime.month}月${localTime.day}日';
    }
  }
  
  /// 格式化过期时间 (用于二维码过期显示)
  static String formatExpirationTime(String? expiresAt) {
    if (expiresAt == null) return '未知';
    
    final localTime = parseToLocal(expiresAt);
    if (localTime == null) return '未知';
    
    final now = DateTime.now();
    final difference = localTime.difference(now);
    
    if (difference.inMinutes > 0) {
      if (difference.inHours > 0) {
        return '${difference.inHours}小时${difference.inMinutes % 60}分钟后过期';
      } else {
        return '${difference.inMinutes}分钟后过期';
      }
    } else {
      return '已过期';
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
} 