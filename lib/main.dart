import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/group_provider.dart';
import 'providers/memory_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'services/websocket_service.dart';
import 'services/websocket_manager.dart';
import 'services/device_auth_service.dart';
import 'services/local_storage_service.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化设备认证服务和WebSocket服务
  final authService = DeviceAuthService();
  final wsService = WebSocketService();
  final wsManager = WebSocketManager();
  
  // 初始化本地存储服务并执行数据维护
  final localStorage = LocalStorageService();
  
  try {
    // 获取设备信息
    final deviceInfo = await authService.getDeviceInfo();
    print('当前设备UUID: ${deviceInfo['deviceId']}');
    
    // 检查是否已登录
    final isLoggedIn = await authService.isLoggedIn();
    
    if (!isLoggedIn) {
      // 如果未登录，自动注册设备
      print('未检测到登录状态，注册设备...');
      final result = await authService.registerDevice();
      print('设备注册成功，服务器ID: ${result['device']['id']}');
    } else {
      print('设备已登录，跳过注册');
    }
    
    // 获取认证信息
    final token = await authService.getAuthToken();
    final serverDeviceId = await authService.getServerDeviceId();
    
    if (token != null && serverDeviceId != null) {
      // 初始化新的WebSocket管理器
      try {
        print('🚀 初始化WebSocket管理器...');
        final success = await wsManager.initialize(
          deviceId: serverDeviceId,
          token: token,
        );
        if (success) {
          print('✅ WebSocket管理器连接成功');
        } else {
          print('❌ WebSocket管理器连接失败');
        }
      } catch (e) {
        print('❌ WebSocket管理器初始化失败: $e');
      }
      
      // 同时初始化旧的WebSocket服务（用于兼容性）
      try {
        print('🔄 初始化传统WebSocket服务...');
        await wsService.connect();
        print('✅ 传统WebSocket连接已初始化');
      } catch (e) {
        print('❌ 传统WebSocket连接失败: $e');
      }
    } else {
      print('⚠️ 缺少认证信息，跳过WebSocket初始化');
    }

    // 执行数据维护
    print('开始执行应用启动维护...');
    await localStorage.cleanupOldData();
    final storageInfo = await localStorage.getStorageInfo();
    print('存储使用情况: ${storageInfo['totalSize']} bytes');
    print('应用启动维护完成');
  } catch (e) {
    print('初始化失败: $e');
  }
  
  runApp(
    // 提供认证状态和群组状态
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => GroupProvider()..initialize(),
        ),
        ChangeNotifierProvider(create: (context) => MemoryProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 创建路由配置
    final GoRouter router = AppRouter.createRouter(context);

    return MaterialApp.router(
      title: 'Send To Myself',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
    );
  }
}
