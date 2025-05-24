import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/device_group_screen.dart';
import '../screens/qr_scan_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
  
  // 初始化路由
  static GoRouter createRouter(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) {
        final bool isLoggedIn = authProvider.isLoggedIn;
        final bool isLoading = authProvider.isLoading;
        final bool isSplashRoute = state.matchedLocation == '/';
        final bool isLoginRoute = state.matchedLocation == '/login';
        
        // 如果正在加载，允许显示启动页
        if (isLoading) return null;
        
        // 如果未登录，重定向到登录页面
        if (!isLoggedIn) {
          return isLoginRoute ? null : '/login';
        }
        
        // 如果已登录，且在启动页或登录页，则重定向到主页
        if (isLoggedIn && (isSplashRoute || isLoginRoute)) {
          return '/home';
        }
        
        // 其他情况不重定向
        return null;
      },
      routes: [
        // 启动页
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        // 登录/注册页
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        // 主界面
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => const HomeScreen(),
          routes: [
            // 主页
            GoRoute(
              path: '/home',
              builder: (context, state) => const SizedBox(), // 空白占位符
              routes: [
                // 群组设备管理
                GoRoute(
                  path: 'device-group/:groupId',
                  builder: (context, state) {
                    final groupId = state.pathParameters['groupId'] as String;
                    return DeviceGroupScreen(groupId: groupId);
                  },
                ),
                // 扫描二维码页面
                GoRoute(
                  path: 'scan',
                  builder: (context, state) {
                    print('构建扫码页面');
                    return const QrScanScreen();
                  },
                ),
              ],
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('路径错误: ${state.matchedLocation}'),
        ),
      ),
    );
  }
} 