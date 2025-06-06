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

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化设备认证服务和WebSocket服务
  final authService = DeviceAuthService();
  final wsService = WebSocketService();
  final wsManager = WebSocketManager();
  
  // 初始化本地存储服务和增强同步管理器
  final localStorage = LocalStorageService();
  final enhancedSyncManager = EnhancedSyncManager();
  final groupSwitchService = GroupSwitchSyncService();
  // final pushNotificationService = PushNotificationService();  // 暂时注释
  
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
        print('🚀 初始化增强同步管理器...');
        await enhancedSyncManager.initialize();
        print('✅ 增强同步管理器初始化完成');
      } catch (e) {
        print('❌ 增强同步管理器初始化失败: $e');
      }
      
      // 初始化新的WebSocket管理器
      try {
        print('🚀 初始化WebSocket管理器...');
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
        print('📱 开始增强应用启动离线消息同步...');
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
        // 提供增强同步管理器
        Provider<EnhancedSyncManager>.value(value: enhancedSyncManager),
        // 🔥 新增：提供群组切换同步服务
        Provider<GroupSwitchSyncService>.value(value: groupSwitchService),
        // 🔥 新增：提供WebSocket管理器
        Provider<WebSocketManager>.value(value: wsManager),
        // 🔥 新增：提供推送通知服务（暂时注释以解决iOS构建问题）
        // Provider<PushNotificationService>.value(value: pushNotificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final EnhancedSyncManager _enhancedSyncManager;
  late final GroupSwitchSyncService _groupSwitchService;
  late final WebSocketManager _wsManager;
  DateTime? _lastPausedTime;
  AppLifecycleState? _lastState;
  bool _wasReallyInBackground = false;
  Timer? _backgroundTimer;
  int _lifecycleChangeCount = 0;
  DateTime? _lastLifecycleChange;
  bool _isFileOperationInProgress = false;
  Timer? _fileOperationResetTimer;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enhancedSyncManager = Provider.of<EnhancedSyncManager>(context, listen: false);
    _groupSwitchService = Provider.of<GroupSwitchSyncService>(context, listen: false);
    _wsManager = Provider.of<WebSocketManager>(context, listen: false);
    
    _groupSwitchService.onGroupSwitch.listen((event) {
      print('📢 群组切换事件: ${event.toString()}');
      
      if (event.newGroupId.isNotEmpty) {
        _wsManager.syncGroupMessages(event.newGroupId);
      }
      
      if (event.hasSyncResult && event.syncResult!.totalFetched > 0) {
        _showGroupSwitchNotification(event);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundTimer?.cancel();
    _fileOperationResetTimer?.cancel();
    _enhancedSyncManager.dispose();
    _groupSwitchService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final now = DateTime.now();
    _lifecycleChangeCount++;
    
    // 检测频繁状态变化（可能是假场景）
    final isFrequentChange = _lastLifecycleChange != null && 
        now.difference(_lastLifecycleChange!).inSeconds < 2;
    
    print('📱 生命周期状态变化: $_lastState -> $state (第$_lifecycleChangeCount次，频繁变化: $isFrequentChange)');
    
    // 如果是频繁变化或生命周期变化太多，直接跳过
    if ((isFrequentChange && _lifecycleChangeCount > 1) || _lifecycleChangeCount > 5) {
      print('🚫 检测到频繁生命周期变化，完全跳过处理 (第$_lifecycleChangeCount次)');
      _lastState = state;
      _lastLifecycleChange = now;
      return;
    }
    
    switch (state) {
      case AppLifecycleState.resumed:
        _backgroundTimer?.cancel();
        
        // 超级严格的后台恢复检测（基本禁用短时间同步）
        final timeSinceLastChange = _lastLifecycleChange != null 
            ? now.difference(_lastLifecycleChange!) 
            : Duration.zero;
        
        final timeSinceLastPause = _lastPausedTime != null 
            ? now.difference(_lastPausedTime!) 
            : Duration.zero;
            
        final timeSinceLastSync = _lastSyncTime != null 
            ? now.difference(_lastSyncTime!) 
            : Duration(hours: 1); // 默认认为很久没同步过
            
        // 必须满足以下所有条件才执行同步：
        // 1. 真正在后台过
        // 2. 距离上次状态变化超过30秒（大幅增加）
        // 3. 不是频繁变化场景
        // 4. 距离最后暂停时间超过5分钟（真正的长时间后台）
        // 5. 不在文件操作进行中
        // 6. 距离上次同步超过10分钟（避免频繁同步）
        final shouldSync = _wasReallyInBackground && 
            timeSinceLastChange.inSeconds > 30 && 
            !isFrequentChange &&
            timeSinceLastPause.inMinutes > 5 &&
            !_isFileOperationInProgress &&
            timeSinceLastSync.inMinutes > 10;
            
        if (shouldSync) {
          print('🔄 确认真正从长时间后台恢复，执行同步 (暂停${timeSinceLastPause.inMinutes}分钟)');
          _lastSyncTime = now;
          _performAppResumedSync();
          _wasReallyInBackground = false;
          _lifecycleChangeCount = 0; // 重置计数
        } else {
          print('📱 跳过同步 - 不满足超严格条件');
          print('   在后台:$_wasReallyInBackground, 状态间隔:${timeSinceLastChange.inSeconds}s');
          print('   暂停时长:${timeSinceLastPause.inMinutes}分钟, 频繁变化:$isFrequentChange');
          print('   文件操作中:$_isFileOperationInProgress, 上次同步:${timeSinceLastSync.inMinutes}分钟前');
        }
        break;
        
      case AppLifecycleState.paused:
        // 检测是否可能是文件操作（快速的状态变化）
        final quickChange = _lastLifecycleChange != null && 
            now.difference(_lastLifecycleChange!).inSeconds < 1;
        if (quickChange) {
          _isFileOperationInProgress = true;
          _fileOperationResetTimer?.cancel();
          _fileOperationResetTimer = Timer(Duration(seconds: 15), () {
            _isFileOperationInProgress = false;
            print('📱 文件操作标志已重置');
          });
          print('📱 检测到可能的文件操作，设置标志');
        }
        
        // 设置很长的定时器，基本只对真正的后台生效
        _backgroundTimer?.cancel();
        _backgroundTimer = Timer(Duration(minutes: 2), () {
          // 二次确认：2分钟后仍未恢复才认为真正后台
          if (_lastState == AppLifecycleState.paused && !_isFileOperationInProgress) {
            _wasReallyInBackground = true;
            _lastPausedTime = now; // 记录真正进入后台的时间
            print('📱 确认真正进入后台（2分钟延迟确认）');
            _performAppPausedActions();
          } else {
            print('📱 状态已变化或检测到文件操作，取消后台确认');
          }
        });
        break;
        
      case AppLifecycleState.hidden:
        // 应用被隐藏的情况更保守处理
        print('📱 应用已隐藏（保守处理）');
        // 不立即设置后台标志，等待paused状态
        break;
        
      case AppLifecycleState.inactive:
        // 完全忽略inactive状态，因为这通常是临时的
        print('📱 应用失去焦点（忽略，通常是临时的）');
        break;
        
      case AppLifecycleState.detached:
        _backgroundTimer?.cancel();
        _performAppDetachedActions();
        break;
    }
    
    _lastState = state;
    _lastLifecycleChange = now;
    
    // 清理旧的变化计数
    if (_lifecycleChangeCount > 10) {
      _lifecycleChangeCount = 0;
    }
  }

  /// 应用从后台恢复时的处理
  Future<void> _performAppResumedSync() async {
    try {
      print('📱 应用恢复 - 开始强制重连和同步...');
      
      // 计算暂停时长
      final pauseDuration = _lastPausedTime != null 
          ? DateTime.now().difference(_lastPausedTime!)
          : const Duration(minutes: 1);
          
      print('⏱️ 应用暂停了 ${pauseDuration.inMinutes} 分钟');
      
      // 🔥 关键修复1：强制检查并重连WebSocket
      await _forceReconnectWebSocket();
      
      // 🔥 关键修复2：等待连接稳定后再同步
      await Future.delayed(Duration(seconds: 3));
      
      // 🔥 立即强制刷新UI - 确保加载当前数据
      _enhancedSyncManager.forceRefreshAllUI();
      print('🔄 已触发立即UI刷新');
      
      // 执行增强的后台恢复同步
      final result = await _enhancedSyncManager.performBackgroundResumeSync();
      
      if (result.success && result.totalFetched > 0) {
        print('✅ 增强恢复同步完成: ${result.totalFetched} 条新消息');
        print('🔄 同步阶段: ${result.phases.join(', ')}');
        
        // 只有获取到足够多的消息才显示通知（减少频繁提示）
        if (result.totalFetched >= 3) {
          _showSyncNotification(result, pauseDuration);
        } else {
          print('📱 新消息数量较少，跳过通知显示');
        }
        
        // 🔥 关键修复：强制多次UI刷新确保显示最新消息
        _enhancedSyncManager.forceRefreshAllUI();
        
        // 延迟再次刷新，确保所有异步操作完成
        Timer(Duration(seconds: 1), () {
          _enhancedSyncManager.forceRefreshAllUI();
          print('🔄 执行延迟UI刷新');
        });
        
        _wsManager.requestUnreadCounts();
        
      } else if (result.success) {
        print('✅ 增强恢复同步完成: 无新消息');
        // 即使没有新消息也刷新UI，可能有本地消息需要显示
        _enhancedSyncManager.forceRefreshAllUI();
      } else {
        print('❌ 增强恢复同步失败: ${result.error}');
        
        // 🔥 同步失败时也要刷新UI，显示现有消息
        _enhancedSyncManager.forceRefreshAllUI();
        
        print('🔄 尝试强制重连WebSocket...');
        await _wsManager.forceReconnectAndSync();
      }
    } catch (e) {
      print('❌ 增强恢复同步出错: $e');
      // 出错时也要刷新UI
      _enhancedSyncManager.forceRefreshAllUI();
    }
  }

  /// 🔥 新增：强制重连WebSocket
  Future<void> _forceReconnectWebSocket() async {
    try {
      print('🔄 开始强制重连WebSocket...');
      
      // 检查WebSocketManager连接状态
      if (!_wsManager.isConnected) {
        print('📡 WebSocketManager未连接，执行重连...');
        
        // 获取认证信息
        final authService = DeviceAuthService();
        final token = await authService.getAuthToken();
        final serverDeviceId = await authService.getServerDeviceId();
        
        if (token != null && serverDeviceId != null) {
          // 强制重新初始化WebSocket连接
          final success = await _wsManager.initialize(
            deviceId: serverDeviceId,
            token: token,
          );
          
          if (success) {
            print('✅ WebSocketManager强制重连成功');
            
            // 立即执行应用恢复同步
            _wsManager.performAppResumeSync();
            
            // 延迟2秒后请求未读消息数量
            Timer(Duration(seconds: 2), () {
              _wsManager.requestUnreadCounts();
            });
          } else {
            print('❌ WebSocketManager强制重连失败');
          }
        } else {
          print('⚠️ 缺少认证信息，无法重连WebSocket');
        }
      } else {
        print('✅ WebSocketManager已连接，执行应用恢复同步');
        _wsManager.performAppResumeSync();
        _wsManager.requestUnreadCounts();
      }
      
      // 同时检查传统WebSocket服务
      final wsService = WebSocketService();
      if (!wsService.isConnected) {
        print('🔄 传统WebSocket未连接，尝试重连...');
        try {
          await wsService.reconnect();
          print('✅ 传统WebSocket重连成功');
        } catch (e) {
          print('❌ 传统WebSocket重连失败: $e');
        }
      }
      
    } catch (e) {
      print('❌ 强制重连WebSocket失败: $e');
    }
  }

  /// 应用进入后台时的处理
  Future<void> _performAppPausedActions() async {
    try {
      _lastPausedTime = DateTime.now();
      print('📱 应用进入后台: $_lastPausedTime');
      
      // 调用增强同步管理器的后台处理
      await _enhancedSyncManager.onAppPaused();
      
      print('✅ 应用后台状态保存完成');
    } catch (e) {
      print('❌ 应用后台处理失败: $e');
    }
  }

  /// 应用即将终止时的处理
  Future<void> _performAppDetachedActions() async {
    try {
      print('📱 应用即将终止 - 保存最终状态');
      
      // 保存应用最后状态
      await _enhancedSyncManager.onAppPaused();
      
      print('✅ 应用终止状态保存完成');
    } catch (e) {
      print('❌ 应用终止处理失败: $e');
    }
  }

  /// 显示同步通知
  void _showSyncNotification(EnhancedSyncResult result, Duration pauseDuration) {
    // 获取当前上下文中的ScaffoldMessenger
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null && result.totalFetched > 0) {
      String message;
      
      if (pauseDuration.inHours > 1) {
        message = '离开期间收到 ${result.totalFetched} 条消息';
      } else if (pauseDuration.inMinutes > 10) {
        message = '收到 ${result.totalFetched} 条新消息';
      } else {
        message = '同步了 ${result.totalFetched} 条消息';
      }
      
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.sync, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(message),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green[600],
          action: result.totalFetched > 5 ? SnackBarAction(
            label: '查看',
            textColor: Colors.white,
            onPressed: () {
              // 可以导航到消息页面
              print('用户点击查看新消息');
            },
          ) : null,
        ),
      );
    }
  }

  /// 🔥 新增：显示群组切换通知
  void _showGroupSwitchNotification(GroupSwitchEvent event) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null && event.syncResult != null) {
      final result = event.syncResult!;
      
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.group, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('群组同步: ${result.totalFetched} 条新消息'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.blue[600],
        ),
      );
    }
  }

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
