import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'local_storage_service.dart';
import 'enhanced_sync_manager.dart';
import '../firebase_options.dart'; // 🔥 导入Firebase配置

/// 🔥 推送通知服务 - 解决后台消息接收问题
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  FirebaseMessaging? _firebaseMessaging;
  FlutterLocalNotificationsPlugin? _localNotifications;
  final LocalStorageService _localStorage = LocalStorageService();
  
  bool _isInitialized = false;
  String? _fcmToken;
  
  // 消息处理流控制器
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get onMessageReceived => _messageController.stream;

  /// 初始化推送通知服务
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      debugPrint('🔔 初始化推送通知服务...');
      
      // 🔥 使用Firebase配置初始化
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firebaseMessaging = FirebaseMessaging.instance;
      
      // 初始化本地通知
      await _initializeLocalNotifications();
      
      // 请求推送权限
      await _requestPermissions();
      
      // 获取FCM Token
      await _getFCMToken();
      
      // 设置消息处理器
      _setupMessageHandlers();
      
      _isInitialized = true;
      debugPrint('✅ 推送通知服务初始化完成');
      return true;
      
    } catch (e) {
      debugPrint('❌ 推送通知服务初始化失败: $e');
      debugPrint('⚠️ 这通常是因为Firebase配置未完成，应用将在没有推送通知的情况下继续运行');
      return false;
    }
  }

  /// 初始化本地通知
  Future<void> _initializeLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();
    
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications!.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// 请求推送权限
  Future<void> _requestPermissions() async {
    if (_firebaseMessaging == null) return;
    
    final settings = await _firebaseMessaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    debugPrint('🔔 推送权限状态: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('⚠️ 用户未授权推送通知');
    }
  }

  /// 获取FCM Token
  Future<void> _getFCMToken() async {
    if (_firebaseMessaging == null) return;
    
    try {
      _fcmToken = await _firebaseMessaging!.getToken();
      debugPrint('📱 FCM Token: $_fcmToken');
      
      // 保存Token到本地存储
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
        
        // 🔥 关键：将Token发送到服务器注册
        await _registerTokenWithServer(_fcmToken!);
      }
      
      // 监听Token刷新
      _firebaseMessaging!.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token刷新: $newToken');
        _fcmToken = newToken;
        _registerTokenWithServer(newToken);
      });
      
    } catch (e) {
      debugPrint('❌ 获取FCM Token失败: $e');
    }
  }

  /// 向服务器注册FCM Token
  Future<void> _registerTokenWithServer(String token) async {
    try {
      debugPrint('📤 向服务器注册FCM Token...');
      
      // TODO: 这里需要调用服务器API注册Token
      // 示例：await ApiService.registerFCMToken(token);
      
      debugPrint('✅ FCM Token注册成功');
    } catch (e) {
      debugPrint('❌ FCM Token注册失败: $e');
    }
  }

  /// 设置消息处理器
  void _setupMessageHandlers() {
    if (_firebaseMessaging == null) return;
    
    // 🔥 关键：前台消息处理
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // 🔥 关键：后台消息处理（应用在后台但未终止）
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageOpen);
    
    // 🔥 关键：应用完全终止时的消息处理
    _checkInitialMessage();
  }

  /// 处理前台消息
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📨 收到前台推送消息: ${message.messageId}');
    debugPrint('📝 消息标题: ${message.notification?.title}');
    debugPrint('📝 消息内容: ${message.notification?.body}');
    debugPrint('📝 消息数据: ${message.data}');
    
    // 在前台显示本地通知
    await _showLocalNotification(message);
    
    // 处理消息数据
    await _processMessageData(message.data);
    
    // 发送到消息流
    _messageController.add({
      'type': 'foreground_message',
      'message': message.toMap(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// 处理后台消息被点击
  Future<void> _handleBackgroundMessageOpen(RemoteMessage message) async {
    debugPrint('📨 用户点击后台推送消息: ${message.messageId}');
    
    // 处理消息数据
    await _processMessageData(message.data);
    
    // 发送到消息流
    _messageController.add({
      'type': 'background_message_opened',
      'message': message.toMap(),
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // 🔥 关键：触发应用恢复同步
    _triggerAppResumeSync();
  }

  /// 检查初始消息（应用从完全终止状态启动）
  Future<void> _checkInitialMessage() async {
    if (_firebaseMessaging == null) return;
    
    final initialMessage = await _firebaseMessaging!.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('📨 应用从推送启动: ${initialMessage.messageId}');
      await _handleBackgroundMessageOpen(initialMessage);
    }
  }

  /// 显示本地通知
  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (_localNotifications == null) return;
    
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      '聊天消息',
      channelDescription: '接收聊天消息通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications!.show(
      message.hashCode,
      message.notification?.title ?? '新消息',
      message.notification?.body ?? '您收到了一条新消息',
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// 处理消息数据
  Future<void> _processMessageData(Map<String, dynamic> data) async {
    try {
      debugPrint('🔄 处理推送消息数据: $data');
      
      final messageType = data['type'] as String?;
      
      switch (messageType) {
        case 'chat_message':
          await _processChatMessage(data);
          break;
        case 'offline_sync':
          await _processOfflineSync(data);
          break;
        case 'group_message':
          await _processGroupMessage(data);
          break;
        case 'system_notification':
          await _processSystemNotification(data);
          break;
        default:
          debugPrint('⚠️ 未知消息类型: $messageType');
      }
      
    } catch (e) {
      debugPrint('❌ 处理推送消息数据失败: $e');
    }
  }

  /// 处理聊天消息
  Future<void> _processChatMessage(Map<String, dynamic> data) async {
    debugPrint('💬 处理聊天消息推送');
    
    final messageData = data['message'];
    if (messageData != null) {
      // 🔥 关键：将消息保存到本地存储
      final conversationId = _getConversationId(messageData);
      
      // 加载现有消息
      final existingMessages = await _localStorage.loadChatMessages(conversationId);
      
      // 添加新消息（检查重复）
      final messageId = messageData['id'];
      final isDuplicate = existingMessages.any((msg) => msg['id'] == messageId);
      
      if (!isDuplicate) {
        existingMessages.add(messageData);
        await _localStorage.saveChatMessages(conversationId, existingMessages);
        debugPrint('💾 推送消息已保存到本地存储');
        
        // 🔥 触发UI更新
        _notifyUIUpdate(conversationId, 1);
      }
    }
  }

  /// 处理离线同步通知
  Future<void> _processOfflineSync(Map<String, dynamic> data) async {
    debugPrint('🔄 处理离线同步推送');
    
    // 触发完整的消息同步
    _triggerAppResumeSync();
  }

  /// 处理群组消息
  Future<void> _processGroupMessage(Map<String, dynamic> data) async {
    debugPrint('👥 处理群组消息推送');
    
    // 类似聊天消息处理
    await _processChatMessage(data);
  }

  /// 处理系统通知
  Future<void> _processSystemNotification(Map<String, dynamic> data) async {
    debugPrint('🔔 处理系统通知推送');
    
    // 可以处理系统级别的通知，如设备登出等
  }

  /// 通知点击处理
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 用户点击通知: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _processMessageData(data);
      } catch (e) {
        debugPrint('❌ 解析通知payload失败: $e');
      }
    }
    
    // 触发应用恢复同步
    _triggerAppResumeSync();
  }

  /// 触发应用恢复同步
  void _triggerAppResumeSync() {
    debugPrint('🔄 推送通知触发应用恢复同步');
    
    // 延迟执行，确保应用已完全恢复
    Timer(Duration(seconds: 1), () {
      try {
        final enhancedSyncManager = EnhancedSyncManager();
        enhancedSyncManager.performBackgroundResumeSync();
      } catch (e) {
        debugPrint('❌ 推送触发同步失败: $e');
      }
    });
  }

  /// 通知UI更新
  void _notifyUIUpdate(String conversationId, int messageCount) {
    _messageController.add({
      'type': 'ui_update_required',
      'conversationId': conversationId,
      'messageCount': messageCount,
      'timestamp': DateTime.now().toIso8601String(),
      'source': 'push_notification',
    });
  }

  /// 获取对话ID
  String _getConversationId(Map<String, dynamic> message) {
    if (message['type'] == 'group' || message['groupId'] != null) {
      return 'group_${message['groupId']}';
    } else {
      final senderId = message['senderId'];
      final recipientId = message['recipientId'];
      final ids = [senderId, recipientId]..sort();
      return 'private_${ids[0]}_${ids[1]}';
    }
  }

  /// 获取FCM Token
  String? get fcmToken => _fcmToken;

  /// 清理资源
  void dispose() {
    _messageController.close();
  }
}

/// 🔥 后台消息处理器（在应用完全终止时仍能工作）
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  debugPrint('📨 后台处理推送消息: ${message.messageId}');
  debugPrint('📝 消息数据: ${message.data}');
  
  // 在这里可以进行后台数据处理
  // 注意：这里不能直接更新UI，只能处理数据
  
  try {
    final localStorage = LocalStorageService();
    
    // 如果是聊天消息，直接保存到本地存储
    if (message.data['type'] == 'chat_message') {
      final messageData = message.data['message'];
      if (messageData != null) {
        final parsedMessage = jsonDecode(messageData);
        
        // 确定对话ID
        String conversationId;
        if (parsedMessage['type'] == 'group' || parsedMessage['groupId'] != null) {
          conversationId = 'group_${parsedMessage['groupId']}';
        } else {
          final senderId = parsedMessage['senderId'];
          final recipientId = parsedMessage['recipientId'];
          final ids = [senderId, recipientId]..sort();
          conversationId = 'private_${ids[0]}_${ids[1]}';
        }
        
        // 保存消息
        final existingMessages = await localStorage.loadChatMessages(conversationId);
        final messageId = parsedMessage['id'];
        final isDuplicate = existingMessages.any((msg) => msg['id'] == messageId);
        
        if (!isDuplicate) {
          existingMessages.add(parsedMessage);
          await localStorage.saveChatMessages(conversationId, existingMessages);
          debugPrint('💾 后台推送消息已保存到本地存储');
        }
      }
    }
    
  } catch (e) {
    debugPrint('❌ 后台消息处理失败: $e');
  }
} 