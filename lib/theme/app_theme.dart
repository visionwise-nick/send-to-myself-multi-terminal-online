import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppTheme {
  // 主色调 - 玫红色系
  static const Color primaryColor = Color(0xFFEC445A); // 玫红色 (236, 68, 90)
  static const Color primaryLightColor = Color(0xFFFF6B84); // 浅玫红色
  static const Color primaryDarkColor = Color(0xFFD63651); // 深玫红色
  
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
  
  // 统一字体规范
  static const double fontSizeDisplay = 18.0;    // 大标题
  static const double fontSizeTitle = 15.0;      // 标题
  static const double fontSizeBody = 13.0;       // 正文
  static const double fontSizeCaption = 11.0;    // 说明文字
  static const double fontSizeSmall = 10.0;      // 小字

  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightNormal = FontWeight.w400;
  static const FontWeight fontWeightLight = FontWeight.w300;

  // 统一文本样式
  static const TextStyle displayStyle = TextStyle(
    fontSize: fontSizeDisplay,
    fontWeight: fontWeightMedium,
    color: textPrimaryColor,
    letterSpacing: -0.3,
  );

  static const TextStyle titleStyle = TextStyle(
    fontSize: fontSizeTitle,
    fontWeight: fontWeightMedium,
    color: textPrimaryColor,
    letterSpacing: -0.2,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: fontSizeBody,
    fontWeight: fontWeightNormal,
    color: textPrimaryColor,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: fontSizeCaption,
    fontWeight: fontWeightNormal,
    color: textSecondaryColor,
    letterSpacing: 0,
    height: 1.3,
  );

  static const TextStyle smallStyle = TextStyle(
    fontSize: fontSizeSmall,
    fontWeight: fontWeightNormal,
    color: textTertiaryColor,
    letterSpacing: 0,
  );
  
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
      
      // AppBar主题 - 紧凑设计
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
        ),
        toolbarHeight: 48, // 减小工具栏高度
      ),
      
      // 卡片主题
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      
      // 按钮主题 - 紧凑设计
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
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
      
      // 文本主题 - 精细化设计
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 24,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.3,
        ),
        headlineMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
        ),
        titleMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        titleSmall: TextStyle(
          color: textSecondaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        bodyLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          color: textSecondaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.3,
        ),
        bodySmall: TextStyle(
          color: textTertiaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.2,
        ),
        labelLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        labelSmall: TextStyle(
          color: textPrimaryColor,
          fontSize: 10,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
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