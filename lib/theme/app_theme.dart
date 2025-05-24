import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppTheme {
  // 主色调 - 现代化蓝色
  static const Color primaryColor = Color(0xFF2563EB); // 蓝色
  static const Color primaryLightColor = Color(0xFF3B82F6);
  static const Color primaryDarkColor = Color(0xFF1E40AF);
  
  // 背景色
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  
  // 状态色
  static const Color onlineColor = Color(0xFF10B981); // 现代绿色
  static const Color offlineColor = Color(0xFF6B7280); // 灰色
  static const Color errorColor = Color(0xFFEF4444); // 红色
  static const Color warningColor = Color(0xFFF59E0B); // 橙色
  static const Color successColor = Color(0xFF10B981); // 绿色
  
  // 文本颜色
  static const Color textPrimaryColor = Color(0xFF111827);
  static const Color textSecondaryColor = Color(0xFF6B7280);
  static const Color textTertiaryColor = Color(0xFF9CA3AF);
  
  // 边框和分割线
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFF3F4F6);
  
  // 阴影色
  static const Color shadowColor = Color(0x0A000000);
  
  // 创建主题数据
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: backgroundColor,
        background: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      
      // AppBar主题
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // 卡片主题
      cardTheme: CardTheme(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      
      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      
      // 导航栏主题
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: backgroundColor,
        elevation: 0,
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: primaryColor, size: 24);
          }
          return const IconThemeData(color: textSecondaryColor, size: 24);
        }),
      ),
      
      // 文本主题
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: textSecondaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: textSecondaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: textTertiaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  // 通用阴影
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: shadowColor,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  // 悬停阴影
  static List<BoxShadow> get hoverShadow => [
    BoxShadow(
      color: shadowColor.withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  // 判断屏幕是否为小屏幕
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 400;
  }
  
  // 获取适当的内边距
  static double getPadding(BuildContext context) {
    return isSmallScreen(context) ? 16.0 : 24.0;
  }
  
  // 应用是否处于桌面环境
  static bool isDesktop(BuildContext context) {
    return !isSmallScreen(context);
  }
  
  // 获取适合当前设备的内边距
  static double getPaddingForDevice(BuildContext context) {
    return isDesktop(context) ? 24.0 : 16.0;
  }
  
  // 获取深色主题
  static ThemeData darkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryLightColor,
        error: errorColor,
        background: Color.fromRGBO(30, 30, 35, 1.0),
        surface: Color.fromRGBO(45, 45, 50, 1.0),
      ),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Color.fromRGBO(30, 30, 35, 1.0),
      cardColor: Color.fromRGBO(45, 45, 50, 1.0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromRGBO(45, 45, 50, 1.0),
        foregroundColor: textPrimaryColor,
        elevation: 0,
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimaryColor),
        displayMedium: TextStyle(color: textPrimaryColor),
        displaySmall: TextStyle(color: textPrimaryColor),
        headlineLarge: TextStyle(color: textPrimaryColor),
        headlineMedium: TextStyle(color: textPrimaryColor),
        headlineSmall: TextStyle(color: textPrimaryColor),
        titleLarge: TextStyle(color: textPrimaryColor),
        titleMedium: TextStyle(color: textPrimaryColor),
        titleSmall: TextStyle(color: textSecondaryColor),
        bodyLarge: TextStyle(color: textPrimaryColor),
        bodyMedium: TextStyle(color: textSecondaryColor),
        bodySmall: TextStyle(color: textTertiaryColor),
        labelLarge: TextStyle(color: textPrimaryColor),
        labelMedium: TextStyle(color: textPrimaryColor),
        labelSmall: TextStyle(color: textPrimaryColor),
      ),
      iconTheme: const IconThemeData(
        color: textPrimaryColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Color.fromRGBO(55, 55, 60, 1.0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
} 