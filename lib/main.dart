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
import 'services/enhanced_sync_manager.dart';
import 'services/group_switch_sync_service.dart';
// import 'services/push_notification_service.dart';  // 暂时注释以解决iOS构建问题
import 'dart:async';
import 'package:context_menus/context_menus.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:io';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔥 修复：立即启动应用UI，将初始化工作移到后台
  runApp(
    // 提供认证状态和群组状态
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => GroupProvider()..initialize(),
        ),
        ChangeNotifierProvider(create: (context) => MemoryProvider()),
        // 提供增强同步管理器
        Provider<EnhancedSyncManager>(create: (_) => EnhancedSyncManager()),
        // 🔥 新增：提供群组切换同步服务
        Provider<GroupSwitchSyncService>(create: (_) => GroupSwitchSyncService()),
        // 🔥 新增：提供WebSocket管理器
        Provider<WebSocketManager>(create: (_) => WebSocketManager()),
        // 🔥 新增：提供推送通知服务（暂时注释以解决iOS构建问题）
        // Provider<PushNotificationService>.value(value: pushNotificationService),
      ],
      child: const MyApp(),
    ),
  );
  
  // 🔥 修复：在后台执行初始化工作，不阻塞UI
  _performBackgroundInitialization();
}

// 🔥 新增：后台初始化方法
Future<void> _performBackgroundInitialization() async {
  try {
    print('🚀 开始后台初始化服务...');
    
    // 初始化设备认证服务和WebSocket服务
    final authService = DeviceAuthService();
    final wsService = WebSocketService();
    final wsManager = WebSocketManager();
    
    // 初始化本地存储服务和增强同步管理器
    final localStorage = LocalStorageService();
    final enhancedSyncManager = EnhancedSyncManager();
    final groupSwitchService = GroupSwitchSyncService();
    // final pushNotificationService = PushNotificationService();  // 暂时注释
    
    // 获取设备信息
    print('📱 获取设备信息...');
    final deviceInfo = await authService.getDeviceInfo();
    print('当前设备UUID: ${deviceInfo['deviceId']}');
    
    // 检查是否已登录
    final isLoggedIn = await authService.isLoggedIn();
    
    if (!isLoggedIn) {
      // 如果未登录，自动注册设备
      print('📝 未检测到登录状态，注册设备...');
      final result = await authService.registerDevice();
      print('✅ 设备注册成功，服务器ID: ${result['device']['id']}');
    } else {
      print('✅ 设备已登录，跳过注册');
    }
    
    // 获取认证信息
    final token = await authService.getAuthToken();
    final serverDeviceId = await authService.getServerDeviceId();
    
    if (token != null && serverDeviceId != null) {
      // 🔥 初始化推送通知服务（暂时注释以解决iOS构建问题）
      /*
      try {
        print('🔔 初始化推送通知服务...');
        final pushInitSuccess = await pushNotificationService.initialize();
        if (pushInitSuccess) {
          print('✅ 推送通知服务初始化成功');
        } else {
          print('⚠️ 推送通知服务初始化失败，但应用可继续运行');
        }
      } catch (e) {
        print('❌ 推送通知服务初始化出错: $e');
      }
      */
      
      // 初始化增强同步管理器
      try {
        print('🔄 初始化增强同步管理器...');
        await enhancedSyncManager.initialize();
        print('✅ 增强同步管理器初始化完成');
      } catch (e) {
        print('❌ 增强同步管理器初始化失败: $e');
      }
      
      // 初始化新的WebSocket管理器
      try {
        print('🌐 初始化WebSocket管理器...');
        final success = await wsManager.initialize(
          deviceId: serverDeviceId,
          token: token,
        );
        if (success) {
          print('✅ WebSocket管理器连接成功');
          
          // 🔥 新增：监听WebSocket状态变化并触发同步
          // 使用定时器检查连接状态，而不是监听流
          Timer.periodic(Duration(seconds: 5), (timer) {
            if (wsManager.isConnected) {
              // 连接成功时执行一次应用恢复同步
              wsManager.performAppResumeSync();
              wsManager.requestUnreadCounts();
              timer.cancel(); // 只执行一次
            }
          });
          
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

      // 执行增强的应用启动离线消息同步
      try {
        print('📥 开始增强应用启动离线消息同步...');
        final syncResult = await enhancedSyncManager.performAppStartupSync();
        if (syncResult.success) {
          print('✅ 增强离线消息同步完成: 获取${syncResult.totalFetched}条，处理${syncResult.totalProcessed}条消息');
          print('🔄 同步阶段: ${syncResult.phases.join(', ')}');
          
          if (syncResult.totalFetched > 0) {
            wsManager.requestUnreadCounts();
          }
        } else {
          print('⚠️ 增强离线消息同步失败: ${syncResult.error}');
        }
      } catch (e) {
        print('❌ 增强离线消息同步出错: $e');
      }
    } else {
      print('⚠️ 缺少认证信息，跳过WebSocket初始化和消息同步');
    }

    // 执行数据维护
    print('🧹 开始执行应用启动维护...');
    await localStorage.cleanupOldData();
    final storageInfo = await localStorage.getStorageInfo();
    print('💾 存储使用情况: ${storageInfo['totalSize']} bytes');
    print('✅ 应用启动维护完成');
    
    print('🎉 后台初始化完成');
  } catch (e) {
    print('❌ 后台初始化失败: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime? _lastPausedTime;
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 🔥 新增：初始化分享接收功能
    _initializeShareReceiving();
  }
  
  // 🔥 新增：初始化分享接收功能
  void _initializeShareReceiving() async {
    try {
      // 处理应用冷启动时的分享数据（文件和文字都通过getInitialMedia处理）
      final initialSharedData = await ReceiveSharingIntent.instance.getInitialMedia();
      if (initialSharedData.isNotEmpty) {
        print('🎯 检测到应用启动时的分享数据: ${initialSharedData.length}个项目');
        _handleSharedData(initialSharedData, isInitial: true);
        
        // 告诉库我们已经处理完意图
        ReceiveSharingIntent.instance.reset();
      }
      
      // 监听运行时的分享数据（文件和文字都通过getMediaStream处理）
      _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
        (List<SharedMediaFile> value) {
          print('🎯 接收到分享数据: ${value.length}个项目');
          _handleSharedData(value, isInitial: false);
        },
        onError: (error) {
          print('❌ 接收分享数据出错: $error');
        },
      );
      
      print('✅ 分享接收功能初始化完成');
    } catch (e) {
      print('❌ 分享接收功能初始化失败: $e');
    }
  }
  
  // 🔥 新增：处理分享的数据（文件和文字）
  void _handleSharedData(List<SharedMediaFile> sharedData, {required bool isInitial}) {
    if (sharedData.isEmpty) return;
    
    // 延迟处理以确保应用完全初始化
    Future.delayed(Duration(seconds: isInitial ? 2 : 0), () {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // 检查是否已登录
        if (!authProvider.isLoggedIn) {
          print('⚠️ 用户未登录，无法处理分享数据');
          return;
        }
        
        // 导航到聊天界面
        _navigateToChat();
        
        // 处理分享的数据
        for (final sharedFile in sharedData) {
          // 检查是否有文字消息（文字分享通过message字段）
          final message = sharedFile.message;
          if (message != null && message.isNotEmpty) {
            print('📤 准备发送分享文字: $message');
            _sendSharedTextToChat(message);
          }
          
          // 检查是否有文件路径（文件分享通过path字段）
          final filePath = sharedFile.path;
          if (filePath != null && filePath.isNotEmpty) {
            print('📤 准备发送分享文件: $filePath');
            _sendSharedFileToChat(sharedFile);
          }
        }
        
      } catch (e) {
        print('❌ 处理分享数据失败: $e');
      }
    });
  }
  
  // 🔥 新增：导航到聊天界面
  void _navigateToChat() {
    // 确保导航到主页并切换到聊天标签
    GoRouter.of(context).go('/');
  }
  
  // 🔥 新增：发送分享的文件到聊天
  void _sendSharedFileToChat(SharedMediaFile sharedFile) {
    print('📤 准备发送分享文件: ${sharedFile.path}');
    
    // TODO: 实现发送到聊天的逻辑
    // 可以通过EventBus或Provider状态管理来实现
    // 这里可以将文件信息存储到全局状态，然后在聊天界面监听并处理
  }
  
  // 🔥 新增：发送分享的文字到聊天
  void _sendSharedTextToChat(String text) {
    print('📤 准备发送分享文字: $text');
    
    // TODO: 实现发送到聊天的逻辑
    // 可以通过EventBus或Provider状态管理来实现
    // 这里可以将文字存储到全局状态，然后在聊天界面监听并处理
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _intentDataStreamSubscription.cancel(); // 🔥 取消分享数据监听
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // 🔥 应用从后台恢复时记录日志
        print('📱 应用从后台恢复');
        break;
      case AppLifecycleState.paused:
        // 应用进入后台时保存状态
        _lastPausedTime = DateTime.now();
        print('📱 应用进入后台');
        break;
      case AppLifecycleState.detached:
        // 应用即将终止时保存状态
        print('📱 应用即将终止');
        break;
      case AppLifecycleState.hidden:
        // 应用隐藏时的处理
        print('📱 应用已隐藏');
        break;
      case AppLifecycleState.inactive:
        // 应用失去焦点时的处理
        print('📱 应用失去焦点');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContextMenuOverlay(
      child: MaterialApp.router(
        title: 'Send To Myself',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.createRouter(context),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
