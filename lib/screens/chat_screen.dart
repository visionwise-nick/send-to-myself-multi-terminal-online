import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../services/chat_service.dart';
import '../services/websocket_service.dart';
import '../services/local_storage_service.dart';
import '../services/message_actions_service.dart';
import '../widgets/message_action_menu.dart';
import '../widgets/multi_select_mode.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:open_filex/open_filex.dart';
import 'dart:math' as math;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';
import '../services/device_auth_service.dart';
import '../services/enhanced_sync_manager.dart'; // 🔥 新增导入
import 'package:provider/provider.dart'; // 🔥 新增导入
import 'package:gal/gal.dart'; // 🔥 新增：相册保存功能
import 'package:desktop_drop/desktop_drop.dart'; // 🔥 新增：桌面端拖拽支持
import 'package:cross_file/cross_file.dart'; // 🔥 新增：XFile支持
import 'package:super_clipboard/super_clipboard.dart'; // 🔥 新增：剪贴板文件支持（只在桌面端使用）

// 🔥 条件导入：只在非移动端导入 super_clipboard
import 'package:super_clipboard/super_clipboard.dart' if (dart.library.js) 'dart:html' show SystemClipboard, Formats;

// 🔥 新增：桌面端右键菜单支持
import 'package:context_menus/context_menus.dart';

import '../services/websocket_manager.dart' as ws_manager; // 🔥 修复：使用别名避免命名冲突

// 文件下载处理器类
class FileDownloadHandler {
  // 解析文件名的优先级处理
  static String parseFileName(Map<String, List<String>> responseHeaders) {
    // 方法1: 解析 Content-Disposition 中的 RFC 5987 编码
    List<String>? contentDispositionList = responseHeaders['content-disposition'];
    if (contentDispositionList != null && contentDispositionList.isNotEmpty) {
      String contentDisposition = contentDispositionList.first;
      
      // 查找 filename*=UTF-8''... 格式
      RegExp rfc5987Pattern = RegExp(r"filename\*=UTF-8''(.+)");
      RegExpMatch? match = rfc5987Pattern.firstMatch(contentDisposition);
      if (match != null) {
        try {
          return Uri.decodeComponent(match.group(1)!);
        } catch (e) {
          print('RFC 5987 解码失败: $e');
        }
      }
      
      // 备用: 解析普通 filename="..." 格式
      RegExp filenamePattern = RegExp(r'filename="([^"]+)"');
      RegExpMatch? filenameMatch = filenamePattern.firstMatch(contentDisposition);
      if (filenameMatch != null) {
        return filenameMatch.group(1)!;
      }
    }
    
    // 方法2: 解析 Base64 编码的原始文件名
    List<String>? base64FilenameList = responseHeaders['x-original-filename-base64'];
    if (base64FilenameList != null && base64FilenameList.isNotEmpty) {
      try {
        String base64Filename = base64FilenameList.first;
        List<int> bytes = base64Decode(base64Filename);
        return utf8.decode(bytes);
      } catch (e) {
        print('Base64 解码失败: $e');
      }
    }
    
    // 默认返回
    return 'downloaded_file';
  }
  
  // 处理重复文件名
  static Future<String> getUniqueFilePath(String originalPath) async {
    File file = File(originalPath);
    if (!await file.exists()) {
      return originalPath;
    }
    
    String dir = path.dirname(originalPath);
    String baseName = path.basenameWithoutExtension(originalPath);
    String extension = path.extension(originalPath);
    
    int counter = 1;
    String newPath;
    do {
      newPath = path.join(dir, '${baseName}_$counter$extension');
      counter++;
    } while (await File(newPath).exists());
    
    return newPath;
  }
  
  // 计算文件哈希用于去重
  static Future<String> calculateFileHash(File file) async {
    try {
      List<int> bytes = await file.readAsBytes();
      var digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      print('计算文件哈希失败: $e');
      return '';
    }
  }
  
  // 基于元数据生成文件标识
  static String generateFileMetadataKey(String fileName, int fileSize, DateTime? modifiedTime) {
    String timeStr = modifiedTime?.millisecondsSinceEpoch.toString() ?? '0';
    return '${fileName}_${fileSize}_$timeStr';
  }
}

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> conversation;

  const ChatScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  late AnimationController _animationController;
  late AnimationController _messageAnimationController;
  bool _isTyping = false;
  bool _isLoading = false;
  StreamSubscription? _chatMessageSubscription;
  final ChatService _chatService = ChatService();
  final WebSocketService _websocketService = WebSocketService();
  final LocalStorageService _localStorage = LocalStorageService();
  
  // 🔥 新增：EnhancedSyncManager的UI更新监听
  StreamSubscription? _syncUIUpdateSubscription;
  
  // 长按消息功能相关
  final MessageActionsService _messageActionsService = MessageActionsService();
  final MultiSelectController _multiSelectController = MultiSelectController();
  
  // 消息处理相关
  final Set<String> _processedMessageIds = <String>{}; // 防止重复处理
  bool _isInitialLoad = true;
  bool _hasScrolledToBottom = false; // 🔥 新增：标记是否已滚动到底部
  
  // 🔥 关键修复：添加消息ID清理机制，防止内存泄漏和阻止同步
  Timer? _messageIdCleanupTimer;
  final Map<String, DateTime> _messageIdTimestamps = <String, DateTime>{}; // 记录消息ID的处理时间
  static const int _maxProcessedMessageIds = 1000; // 最大保留的消息ID数量
  static const Duration _messageIdRetentionTime = Duration(hours: 2); // 消息ID保留时间2小时
  
  // 🔥 新增：WebSocket连接健康监控
  Timer? _connectionHealthTimer;
  DateTime? _lastMessageReceivedTime;
  bool _hasWebSocketIssue = false;
  
  // 文件下载相关 - 优化缓存策略
  final Dio _dio = Dio();
  // 使用LRU缓存，限制内存中的文件路径映射数量
  final Map<String, String> _downloadedFiles = <String, String>{}; // URL -> 本地路径
  final Set<String> _downloadingFiles = {}; // 正在下载的文件URL
  static const int _maxCacheSize = 100; // 最多缓存100个文件路径
  final List<String> _cacheAccessOrder = []; // LRU访问顺序
  
  // 文件去重相关
  final Map<String, String> _fileHashCache = {}; // 文件路径 -> 哈希值
  final Set<String> _seenFileHashes = {}; // 已见过的文件哈希
  final Map<String, String> _fileMetadataCache = {}; // 元数据标识 -> 文件路径
  
  // 文件缓存键前缀
  static const String _filePathCachePrefix = 'file_path_cache_';
  static const String _fileHashCachePrefix = 'file_hash_cache_';
  static const String _fileMetadataCachePrefix = 'file_metadata_cache_';

  // 🔥 新增：输入框文件预览功能
  final List<Map<String, dynamic>> _pendingFiles = []; // 待发送的文件列表
  bool _showFilePreview = false; // 是否显示文件预览

  // 判断是否为桌面端
  bool _isDesktop() {
    if (kIsWeb) {
      return MediaQuery.of(context).size.width >= 800;
    }
    return defaultTargetPlatform == TargetPlatform.macOS ||
           defaultTargetPlatform == TargetPlatform.windows ||
           defaultTargetPlatform == TargetPlatform.linux;
  }

  // 🔥 新增：WebSocket连接状态监听
  StreamSubscription? _connectionStateSubscription;
  
  // 🔥 新增：连接状态跟踪
  bool _isWebSocketConnected = false;
  bool _wasOfflineBeforeReconnect = false;
  DateTime? _lastDisconnectTime;
  
  @override
  void initState() {
    super.initState();
    // 移除_multiSelectController的重复赋值，它已经在声明时初始化
    _setupScrollListener();
    
    // 🔥 增强：启动WebSocket连接状态监听
    _setupWebSocketConnectionStateListener();
    
    // 🔥 修复：立即加载本地消息
    _loadLocalMessages();
    
    // 延迟执行后台任务，避免阻塞UI
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _subscribeToChatMessages();
        _syncLatestMessages();
        _startConnectionHealthCheck();
      }
    });
  }
  
  // 🔥 新增：设置WebSocket连接状态监听
  void _setupWebSocketConnectionStateListener() {
    // 🔥 修复：通过WebSocketManager实例直接访问连接状态流
    final wsManager = ws_manager.WebSocketManager();
    _connectionStateSubscription = wsManager.onConnectionStateChanged.listen((state) {
      if (!mounted) return;
      
      final isConnected = state == ws_manager.ConnectionState.connected;
      
      print('🔌 WebSocket连接状态变化: $state, 当前连接: $_isWebSocketConnected -> $isConnected');
      
      // 检测从断线到重连的状态变化
      if (!_isWebSocketConnected && isConnected) {
        // 从断线状态恢复到连接状态
        print('🔄 检测到WebSocket重连成功，开始执行离线消息同步...');
        _wasOfflineBeforeReconnect = true;
        _handleWebSocketReconnected();
      } else if (_isWebSocketConnected && !isConnected) {
        // 从连接状态变为断线状态
        print('⚠️ 检测到WebSocket断线，记录断线时间');
        _lastDisconnectTime = DateTime.now();
        _handleWebSocketDisconnected();
      }
      
      _isWebSocketConnected = isConnected;
      
      // 更新UI状态
      if (mounted) {
        setState(() {
          // 触发UI更新，显示连接状态
        });
      }
    });
  }
  
  // 🔥 新增：处理WebSocket重连成功
  Future<void> _handleWebSocketReconnected() async {
    print('✅ WebSocket重连成功，开始完整的离线消息同步...');
    
    try {
      // 显示重连成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('网络已恢复，正在同步消息...'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // 延迟1秒确保连接稳定后再同步
      await Future.delayed(Duration(seconds: 1));
      
      // 执行完整的消息同步流程
      await _performReconnectMessageSync();
      
      // 显示同步完成提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.sync, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('✅ 消息同步完成'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 1),
          ),
        );
      }
      
    } catch (e) {
      print('❌ WebSocket重连后消息同步失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('消息同步失败: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  // 🔥 新增：处理WebSocket断线
  void _handleWebSocketDisconnected() {
    print('⚠️ WebSocket连接断开');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('网络连接中断，正在尝试重连...'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  // 🔥 新增：执行重连后的消息同步
  Future<void> _performReconnectMessageSync() async {
    print('🔄 开始执行重连后的完整消息同步...');
    
    try {
      // 第1步：重新加载本地消息，更新UI
      print('📱 步骤1: 重新加载本地消息');
      await _loadLocalMessages();
      
      // 第2步：通过HTTP API获取最新消息
      print('🌐 步骤2: 通过HTTP API同步最新消息');
      await _syncLatestMessages();
      
      // 第3步：请求WebSocket同步离线期间的消息
      print('📡 步骤3: 请求WebSocket同步离线消息');
      await _requestOfflineMessageSync();
      
      // 第4步：强制刷新当前对话消息
      print('💬 步骤4: 强制刷新当前对话消息');
      await _forceRefreshCurrentConversation();
      
      // 第5步：请求服务器推送任何遗漏的消息
      print('🔔 步骤5: 请求服务器推送遗漏消息');
      _requestMissedMessages();
      
      print('✅ 重连后消息同步流程完成');
      
    } catch (e) {
      print('❌ 重连后消息同步失败: $e');
      rethrow;
    }
  }
  
  // 🔥 新增：请求离线消息同步
  Future<void> _requestOfflineMessageSync() async {
    if (!_websocketService.isConnected) {
      print('⚠️ WebSocket未连接，跳过离线消息同步');
      return;
    }
    
    try {
      final since = _lastDisconnectTime?.toIso8601String() ?? 
                   DateTime.now().subtract(Duration(hours: 1)).toIso8601String();
      
      print('📥 请求离线消息，断线时间: $since');
      
      // 请求离线期间的所有消息
      _websocketService.emit('get_offline_messages', {
        'timestamp': DateTime.now().toIso8601String(),
        'reason': 'reconnect_sync',
        'since': since,
        'include_files': true,
        'include_deleted': false,
        'limit': 200,
      });
      
      // 如果是群组对话，请求群组的历史消息
      if (widget.conversation['type'] == 'group') {
        final groupId = widget.conversation['groupData']?['id'];
        if (groupId != null) {
          _websocketService.emit('sync_group_messages', {
            'groupId': groupId,
            'timestamp': DateTime.now().toIso8601String(),
            'reason': 'reconnect_sync',
            'since': since,
            'limit': 100,
            'include_offline': true,
          });
        }
      } else {
        // 如果是私聊，请求私聊的历史消息
        final deviceId = widget.conversation['deviceData']?['id'];
        if (deviceId != null) {
          _websocketService.emit('sync_private_messages', {
            'targetDeviceId': deviceId,
            'timestamp': DateTime.now().toIso8601String(),
            'reason': 'reconnect_sync',
            'since': since,
            'limit': 100,
            'include_offline': true,
          });
        }
      }
      
      print('✅ 离线消息同步请求已发送');
      
    } catch (e) {
      print('❌ 请求离线消息同步失败: $e');
    }
  }
  
  // 🔥 新增：强制刷新当前对话消息
  Future<void> _forceRefreshCurrentConversation() async {
    try {
      print('💬 强制刷新当前对话消息...');
      
      List<Map<String, dynamic>> apiMessages = [];
      
      // 根据对话类型获取最新消息
      if (widget.conversation['type'] == 'group') {
        final groupId = widget.conversation['groupData']?['id'];
        if (groupId != null) {
          final result = await _chatService.getGroupMessages(groupId: groupId, limit: 100);
          if (result['messages'] != null) {
            apiMessages = List<Map<String, dynamic>>.from(result['messages']);
          }
        }
      } else {
        final deviceId = widget.conversation['deviceData']?['id'];
        if (deviceId != null) {
          final result = await _chatService.getPrivateMessages(targetDeviceId: deviceId, limit: 100);
          if (result['messages'] != null) {
            apiMessages = List<Map<String, dynamic>>.from(result['messages']);
          }
        }
      }
      
      if (apiMessages.isNotEmpty) {
        // 处理新获取的消息
        await _processServerMessages(apiMessages);
        print('✅ 当前对话消息刷新完成，获取到 ${apiMessages.length} 条消息');
      } else {
        print('📭 当前对话没有新消息');
      }
      
    } catch (e) {
      print('❌ 强制刷新当前对话消息失败: $e');
    }
  }
  
  // 🔥 新增：请求遗漏的消息
  void _requestMissedMessages() {
    if (!_websocketService.isConnected) return;
    
    try {
      print('🔔 请求服务器推送任何遗漏的消息...');
      
      // 请求当前对话的最新消息
      _websocketService.emit('get_recent_messages', {
        'conversationId': widget.conversation['id'],
        'limit': 50,
        'timestamp': DateTime.now().toIso8601String(),
        'reason': 'check_missed_messages'
      });
      
      // 强制同步所有对话
      _websocketService.emit('force_sync_all_conversations', {
        'timestamp': DateTime.now().toIso8601String(),
        'reason': 'reconnect_check_missed',
        'sync_limit': 50,
      });
      
      print('✅ 遗漏消息检查请求已发送');
      
    } catch (e) {
      print('❌ 请求遗漏消息失败: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _messageAnimationController.dispose();
    _chatMessageSubscription?.cancel();
    
    // 🔥 关键修复：清理新增的订阅和定时器
    _syncUIUpdateSubscription?.cancel();
    _messageIdCleanupTimer?.cancel();
    _connectionHealthTimer?.cancel();
    
    // 🔥 新增：清理WebSocket连接状态订阅
    _connectionStateSubscription?.cancel();
    
    super.dispose();
  }
  
  // 🔥 关键修复：启动消息ID清理定时器
  void _startMessageIdCleanup() {
    _messageIdCleanupTimer = Timer.periodic(Duration(minutes: 30), (_) {
      _cleanupOldProcessedMessageIds();
    });
  }
  
  // 🔥 关键修复：清理过期的消息ID
  void _cleanupOldProcessedMessageIds() {
    final now = DateTime.now();
    final expiredIds = <String>[];
    
    // 找出过期的消息ID
    _messageIdTimestamps.forEach((messageId, timestamp) {
      if (now.difference(timestamp) > _messageIdRetentionTime) {
        expiredIds.add(messageId);
      }
    });
    
    // 移除过期的消息ID
    for (final id in expiredIds) {
      _processedMessageIds.remove(id);
      _messageIdTimestamps.remove(id);
    }
    
    // 如果仍然超过最大数量，移除最老的
    if (_processedMessageIds.length > _maxProcessedMessageIds) {
      final sortedEntries = _messageIdTimestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      final toRemove = _processedMessageIds.length - _maxProcessedMessageIds;
      for (int i = 0; i < toRemove && i < sortedEntries.length; i++) {
        final id = sortedEntries[i].key;
        _processedMessageIds.remove(id);
        _messageIdTimestamps.remove(id);
      }
    }
    
    print('消息ID清理完成: 剩余${_processedMessageIds.length}个，清理${expiredIds.length}个过期ID');
  }
  
  // 🔥 新增：启动连接健康检查
  void _startConnectionHealthCheck() {
    _connectionHealthTimer = Timer.periodic(Duration(minutes: 2), (_) {
      _checkWebSocketHealth();
    });
  }
  
  // 🔥 新增：检查WebSocket连接健康状态
  void _checkWebSocketHealth() {
    final now = DateTime.now();
    
    // 检查最后接收消息的时间
    if (_lastMessageReceivedTime != null) {
      final timeSinceLastMessage = now.difference(_lastMessageReceivedTime!);
      
      // 如果超过5分钟没收到任何消息，可能有问题
      if (timeSinceLastMessage.inMinutes >= 5) {
        print('⚠️ WebSocket可能有问题：${timeSinceLastMessage.inMinutes}分钟未收到消息');
        _hasWebSocketIssue = true;
        
        // 尝试重新建立连接
        _attemptWebSocketRecovery();
      } else {
        _hasWebSocketIssue = false;
      }
    }
    
    // 🔥 新增：检测到重连后立即同步历史消息
    if (_websocketService.isConnected && _hasWebSocketIssue) {
      print('🔄 检测到WebSocket重连，立即执行历史消息同步...');
      _hasWebSocketIssue = false;
      _performWebSocketReconnectSync();
    }
  }
  
  // 🔥 修复：简化WebSocket恢复逻辑，避免重复重连
  void _attemptWebSocketRecovery() {
    print('🔄 尝试恢复WebSocket连接...');
    
    // 重新订阅消息
    _chatMessageSubscription?.cancel();
    _subscribeToChatMessages();
    
    // 🔥 修复：不再主动触发重连，让WebSocketManager自己处理
    // 只负责在连接可用时执行同步
    if (_websocketService.isConnected) {
      print('🔄 WebSocket已连接，执行恢复后同步...');
      _performWebSocketReconnectSync();
    } else {
      print('⚠️ WebSocket未连接，等待WebSocketManager自动重连后再同步');
      // 不再手动调用connect()，避免与WebSocketManager的重连逻辑冲突
    }
  }



  // 🔥 WebSocket重连后的完整登录流程同步
  Future<void> _performWebSocketReconnectSync() async {
    print('🔄 WebSocket重连后开始完整登录流程同步...');
    
    try {
      // 🔥 步骤1：立即重新加载本地消息，刷新UI（就像首次登录）
      print('📱 步骤1：重新加载本地消息...');
      await _loadLocalMessages();
      
      // 🔥 步骤2：等待UI更新后，开始完整的后台同步
      await Future.delayed(Duration(milliseconds: 500));
      
      // 🔥 步骤3：使用HTTP API拉取最新消息（完全模拟首次登录的拉取逻辑）
      print('🌐 步骤3：通过HTTP API同步最新消息（模拟首次登录）...');
      await _syncLatestMessages();
      
      // 🔥 步骤4：等待HTTP同步完成后，再进行WebSocket实时同步
      await Future.delayed(Duration(milliseconds: 1000));
      
      // 🔥 步骤5：通过WebSocket请求完整的实时同步（就像首次登录后的实时同步）
      print('📡 步骤5：请求WebSocket完整实时同步...');
      _requestWebSocketCompleteSync();
      
      // 🔥 步骤6：刷新设备状态和在线列表
      print('📱 步骤6：刷新设备状态...');
      _websocketService.refreshDeviceStatus();
      
      // 🔥 步骤7：强制刷新整个聊天界面
      print('🔄 步骤7：强制刷新聊天界面...');
      await _forceRefreshChatMessages();
      
      print('✅ WebSocket重连后完整登录流程同步完成');
      
    } catch (e) {
      print('❌ WebSocket重连后完整登录流程同步失败: $e');
    }
  }

  // 🔥 新增：请求WebSocket完整同步（模拟首次登录后的同步）
  void _requestWebSocketCompleteSync() {
    if (_websocketService.isConnected) {
      print('📡 开始WebSocket完整同步请求...');
      
      // 请求当前对话的最新消息
      if (widget.conversation['type'] == 'group') {
        final groupId = widget.conversation['groupData']?['id'];
        if (groupId != null) {
          _websocketService.emit('sync_group_messages', {
            'groupId': groupId,
            'limit': 100, // 增加限制，模拟首次登录
            'timestamp': DateTime.now().toIso8601String(),
            'reason': 'login_sync_reconnect',
            'include_offline': true,
          });
        }
      } else {
        final deviceId = widget.conversation['deviceData']?['id'];
        if (deviceId != null) {
          _websocketService.emit('sync_private_messages', {
            'targetDeviceId': deviceId,
            'limit': 100, // 增加限制，模拟首次登录
            'timestamp': DateTime.now().toIso8601String(),
            'reason': 'login_sync_reconnect',
            'include_offline': true,
          });
        }
      }
      
      // 请求所有离线期间的消息
      _websocketService.emit('get_offline_messages', {
        'timestamp': DateTime.now().toIso8601String(),
        'reason': 'login_sync_reconnect',
        'include_files': true,
        'include_deleted': false,
        'limit': 200, // 增加限制，模拟首次登录
      });
      
      // 请求所有对话的同步
      _websocketService.emit('force_sync_all_conversations', {
        'timestamp': DateTime.now().toIso8601String(),
        'reason': 'login_sync_reconnect',
        'sync_limit': 100,
      });
      
      print('✅ WebSocket完整同步请求已发送');
    }
  }
  
  // 🔥 新增：强制刷新聊天消息
  Future<void> _forceRefreshChatMessages() async {
    print('🔄 强制刷新聊天消息...');
    
    try {
      // 重新从本地存储加载消息
      await _refreshMessagesFromStorage();
      
      // 强制重新构建UI
      if (mounted) {
        setState(() {
          // 触发UI重建
        });
        
        // 🔥 修复：移除强制刷新后的自动滚动，保持用户当前阅读位置
        // await Future.delayed(Duration(milliseconds: 300));
        // _scrollToBottom();
      }
      
      print('✅ 聊天消息强制刷新完成');
    } catch (e) {
      print('❌ 强制刷新聊天消息失败: $e');
    }
  }

  // 订阅聊天消息
  void _subscribeToChatMessages() {
    _chatMessageSubscription = _websocketService.onChatMessage.listen((data) {
      if (mounted) {
        print('收到聊天消息: ${data['type']}, 数据: $data');
        switch (data['type']) {
          case 'new_private_message':
            print('处理新的私聊消息');
            _handleIncomingMessage(data, false);
            break;
          case 'new_group_message':
            print('处理新的群组消息');
            _handleIncomingMessage(data, true);
            break;
          case 'recent_messages': // 🔥 新增：处理最近消息
            print('处理最近消息同步');
            _handleRecentMessages(data);
            break;
          case 'offline_messages': // 🔥 新增：处理离线消息
            print('处理离线消息同步');
            _handleOfflineMessages(data);
            break;
          case 'group_messages_synced': // 🔥 新增：处理群组消息同步
            print('处理群组消息同步');
            _handleGroupMessagesSynced(data);
            break;
          case 'private_messages_synced': // 🔥 新增：处理私聊消息同步
            print('处理私聊消息同步');
            _handlePrivateMessagesSynced(data);
            break;
          case 'sync_group_messages_response': // 🔥 新增：处理群组消息同步响应
            print('处理群组消息同步响应');
            _handleSyncGroupMessagesResponse(data);
            break;
          case 'sync_private_messages_response': // 🔥 新增：处理私聊消息同步响应
            print('处理私聊消息同步响应');
            _handleSyncPrivateMessagesResponse(data);
            break;
          case 'message_sent_confirmation':
          case 'group_message_sent_confirmation':
            print('处理消息发送确认');
            _handleMessageSentConfirmation(data);
            break;
          case 'message_status_updated':
            print('处理消息状态更新');
            _handleMessageStatusUpdate(data);
            break;
          default:
            print('未知的聊天消息类型: ${data['type']}');
            break;
        }
      }
    });
  }

  // 统一处理接收到的消息
  void _handleIncomingMessage(Map<String, dynamic> data, bool isGroupMessage) {
    final message = data['message'];
    if (message == null) return;

    // 🔥 关键修复：更新最后收到消息的时间
    _lastMessageReceivedTime = DateTime.now();

    final messageId = message['id'];
    if (messageId == null) {
      print('消息ID为空，跳过处理');
      return;
    }

    // 🔥 统一去重机制：仅检查消息ID是否已处理
    if (_processedMessageIds.contains(messageId)) {
      print('消息ID已处理过，跳过: $messageId');
      return;
    }
    
    // 🔥 立即标记消息ID已处理
    _processedMessageIds.add(messageId);
    _messageIdTimestamps[messageId] = DateTime.now();
    
    print('开始处理新消息: ID=$messageId, 群组消息=$isGroupMessage');

    // 检查是否是当前对话的消息
    if (!_isMessageForCurrentConversation(message, isGroupMessage)) {
      print('消息不属于当前对话，跳过: $messageId');
      return;
    }

    // 获取消息相关信息
    final content = message['content'];
    final fileName = message['fileName'];
    final fileUrl = message['fileUrl'];
    final fileSize = message['fileSize'];
    
    // 判断是否是文件消息
    final isFileMessage = fileUrl != null || fileName != null;
    
    print('收到消息: ID=$messageId, 文件消息=$isFileMessage, 内容=${content ?? fileName}');
    
    // 添加消息到界面（去除所有额外的重复检查）
    _addMessageToChat(message, false);
    
    // 发送已接收回执
    _websocketService.sendMessageReceived(messageId);
    
    print('成功处理消息: $messageId, 类型: ${isFileMessage ? "文件" : "文本"}');
  }

  // 检查消息是否属于当前对话
  bool _isMessageForCurrentConversation(Map<String, dynamic> message, bool isGroupMessage) {
    if (isGroupMessage) {
      // 群组消息
      if (widget.conversation['type'] != 'group') return false;
      final groupId = message['groupId'];
      final conversationGroupId = widget.conversation['groupData']?['id'];
      return groupId == conversationGroupId;
    } else {
      // 私聊消息
      if (widget.conversation['type'] == 'group') return false;
      final sourceDeviceId = message['sourceDeviceId'];
      final targetDeviceId = message['targetDeviceId'];
      final conversationDeviceId = widget.conversation['deviceData']?['id'];
      return sourceDeviceId == conversationDeviceId || targetDeviceId == conversationDeviceId;
    }
  }

  // 处理新的私聊消息 (已合并到_handleIncomingMessage)
  void _handleNewPrivateMessage(Map<String, dynamic> data) {
    // 这个方法已被_handleIncomingMessage替代
  }

  // 处理新的群组消息 (已合并到_handleIncomingMessage)
  void _handleNewGroupMessage(Map<String, dynamic> data) {
    // 这个方法已被_handleIncomingMessage替代
  }

  // 处理消息发送确认
  void _handleMessageSentConfirmation(Map<String, dynamic> data) {
    final messageId = data['messageId'];
    if (messageId == null) return;

    // 更新对应消息的状态
    setState(() {
      final index = _messages.indexWhere((msg) => msg['id'] == messageId);
      if (index != -1) {
        _messages[index]['status'] = 'sent';
      }
    });
  }

  // 处理消息状态更新
  void _handleMessageStatusUpdate(Map<String, dynamic> data) {
    final messageId = data['messageId'];
    final status = data['status'];
    if (messageId == null || status == null) return;

    // 更新对应消息的状态
    setState(() {
      final index = _messages.indexWhere((msg) => msg['id'] == messageId);
      if (index != -1) {
        _messages[index]['status'] = status;
      }
    });
  }

  // 🔥 新增：处理最近消息同步
  void _handleRecentMessages(Map<String, dynamic> data) {
    final messages = data['messages'] as List<dynamic>?;
    if (messages == null || messages.isEmpty) {
      print('最近消息同步：无消息');
      return;
    }
    
    print('📥 收到最近消息同步: ${messages.length}条');
    _processSyncedMessages(messages, 'recent_messages');
  }

  // 🔥 新增：处理离线消息同步
  void _handleOfflineMessages(Map<String, dynamic> data) {
    final messages = data['messages'] as List<dynamic>?;
    if (messages == null || messages.isEmpty) {
      print('离线消息同步：无消息');
      return;
    }
    
    print('📥 收到离线消息同步: ${messages.length}条');
    _processSyncedMessages(messages, 'offline_messages');
  }

  // 🔥 新增：处理群组消息同步
  void _handleGroupMessagesSynced(Map<String, dynamic> data) {
    final messages = data['messages'] as List<dynamic>?;
    if (messages == null || messages.isEmpty) {
      print('群组消息同步：无消息');
      return;
    }
    
    print('📥 收到群组消息同步: ${messages.length}条');
    _processSyncedMessages(messages, 'group_messages_synced');
  }

  // 🔥 新增：处理私聊消息同步
  void _handlePrivateMessagesSynced(Map<String, dynamic> data) {
    final messages = data['messages'] as List<dynamic>?;
    if (messages == null || messages.isEmpty) {
      print('私聊消息同步：无消息');
      return;
    }
    
    print('📥 收到私聊消息同步: ${messages.length}条');
    _processSyncedMessages(messages, 'private_messages_synced');
  }

  // 🔥 新增：处理群组消息同步响应
  void _handleSyncGroupMessagesResponse(Map<String, dynamic> data) {
    final messages = data['messages'] as List<dynamic>?;
    if (messages == null || messages.isEmpty) {
      print('群组消息同步响应：无消息');
      return;
    }
    
    print('📥 收到群组消息同步响应: ${messages.length}条');
    _processSyncedMessages(messages, 'sync_group_messages_response');
  }

  // 🔥 新增：处理私聊消息同步响应
  void _handleSyncPrivateMessagesResponse(Map<String, dynamic> data) {
    final messages = data['messages'] as List<dynamic>?;
    if (messages == null || messages.isEmpty) {
      print('私聊消息同步响应：无消息');
      return;
    }
    
    print('📥 收到私聊消息同步响应: ${messages.length}条');
    _processSyncedMessages(messages, 'sync_private_messages_response');
  }

  // 🔥 新增：统一处理同步消息
  Future<void> _processSyncedMessages(List<dynamic> messages, String syncType) async {
    print('🔄 开始处理同步消息: $syncType, 数量: ${messages.length}');
    
    final prefs = await SharedPreferences.getInstance();
    final serverDeviceData = prefs.getString('server_device_data');
    String? currentDeviceId;
    if (serverDeviceData != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(serverDeviceData);
        currentDeviceId = data['id'];
      } catch (e) {
        print('解析设备ID失败: $e');
      }
    }

    final List<Map<String, dynamic>> newMessages = [];
    
    for (final msgData in messages) {
      final message = Map<String, dynamic>.from(msgData);
      final messageId = message['id']?.toString();
      
      if (messageId == null) continue;
      
      // 🔥 关键：过滤掉本机发送的消息
      final sourceDeviceId = message['sourceDeviceId'];
      if (sourceDeviceId == currentDeviceId) {
        print('🚫 跳过本机发送的消息: $messageId');
        continue;
      }
      
      // 检查是否已存在
      if (_localMessageIds.contains(messageId)) {
        print('🎯 消息已存在于本地: $messageId');
        continue;
      }
      
      // 检查当前显示列表
      final existsInDisplay = _messages.any((localMsg) => localMsg['id']?.toString() == messageId);
      if (existsInDisplay) {
        print('🎯 消息已在显示列表: $messageId');
        continue;
      }
      
      // 转换消息格式
      final convertedMessage = {
        'id': messageId,
        'text': message['content'],
        'fileType': (message['fileUrl'] != null || message['fileName'] != null) ? _getFileType(message['fileName']) : null,
        'fileName': message['fileName'],
        'fileUrl': message['fileUrl'],
        'fileSize': message['fileSize'],
        'timestamp': _normalizeTimestamp(message['createdAt'] ?? DateTime.now().toUtc().toIso8601String()),
        'isMe': false, // 已过滤本机消息，这些都是其他设备的
        'status': message['status'] ?? 'sent',
        'sourceDeviceId': message['sourceDeviceId'],
      };
      
      newMessages.add(convertedMessage);
      _localMessageIds.add(messageId);
    }
    
    if (newMessages.isNotEmpty && mounted) {
      print('✅ 同步到${newMessages.length}条新消息，更新UI');
      
      setState(() {
        _messages.addAll(newMessages);
        _messages.sort((a, b) {
          try {
            final timeA = DateTime.parse(a['timestamp']);
            final timeB = DateTime.parse(b['timestamp']);
            return timeA.compareTo(timeB);
          } catch (e) {
            return 0;
          }
        });
      });
      
      // 为新消息自动下载文件
      for (final message in newMessages) {
        if (message['fileUrl'] != null && !message['isMe']) {
          _autoDownloadFile(message);
        }
      }
      
      // 保存到本地
      await _saveMessages();
      // 🔥 修复：移除WebSocket同步后的自动滚动，避免打断用户阅读
      // _scrollToBottom();
      
      print('🎉 WebSocket同步完成: 新增${newMessages.length}条消息 ($syncType)');
    } else {
      print('📋 WebSocket同步完成: 无新消息 ($syncType)');
    }
  }

  // 添加消息到聊天界面
  void _addMessageToChat(Map<String, dynamic> message, bool isMe) {
    final messageId = message['id'];
    if (messageId == null) return;

    // 检查消息是否已存在（额外的安全检查）
    final existingIndex = _messages.indexWhere((msg) => msg['id'] == messageId);
    if (existingIndex != -1) {
      print('消息已存在于界面中，跳过添加: $messageId');
      return;
    }

    final prefs = SharedPreferences.getInstance();
    prefs.then((prefs) async {
      // 获取当前设备ID
      final serverDeviceData = prefs.getString('server_device_data');
      String? currentDeviceId;
      if (serverDeviceData != null) {
        try {
          final Map<String, dynamic> data = jsonDecode(serverDeviceData);
          currentDeviceId = data['id'];
        } catch (e) {
          print('解析设备ID失败: $e');
        }
      }

      // 根据消息来源判断是否是我发的
      final actualIsMe = isMe || (message['sourceDeviceId'] == currentDeviceId);

      final chatMessage = {
        'id': message['id'],
        'text': message['content'],
        'fileType': (message['fileUrl'] != null || message['fileName'] != null) ? _getFileType(message['fileName']) : null,
        'fileName': message['fileName'],
        'fileUrl': message['fileUrl'],
        'fileSize': message['fileSize'],
        'timestamp': _normalizeTimestamp(message['createdAt'] ?? DateTime.now().toUtc().toIso8601String()),
        'isMe': actualIsMe,
        'status': message['status'] ?? 'sent',
        'sourceDeviceId': message['sourceDeviceId'],
      };

      // 立即更新UI
      if (mounted) {
        setState(() {
          _messages.add(chatMessage);
          // 按时间排序 - 使用安全的时间比较
          _messages.sort((a, b) {
            try {
              final timeA = DateTime.parse(a['timestamp']);
              final timeB = DateTime.parse(b['timestamp']);
              return timeA.compareTo(timeB);
            } catch (e) {
              print('消息时间排序失败: $e');
              return 0; // 如果时间解析失败，保持原顺序
            }
          });
        });

        // 如果是文件消息且不是自己发的，自动下载文件
        if (chatMessage['fileUrl'] != null && !actualIsMe) {
          _autoDownloadFile(chatMessage);
        }

        // 保存到本地存储（异步，不阻塞UI）
        _saveMessages().then((_) {
          print('消息已保存到本地: $messageId');
        }).catchError((e) {
          print('保存消息失败: $e');
        });

        // 🔥 修复：移除接收新消息后的自动滚动，避免打断用户阅读历史消息
        // _scrollToBottom();
        
        print('消息已添加到界面: $messageId, isMe: $actualIsMe');
      }
    });
  }

  // 根据文件名获取文件类型
  String _getFileType(String? fileName) {
    if (fileName == null) return 'other';
    
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return 'image';
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'webm':
        return 'video';
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
      case 'ppt':
      case 'pptx':
      case 'txt':
        return 'document';
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
      case 'm4a':
        return 'audio';
      default:
        return 'other';
    }
  }

  // 加载聊天消息
  Future<void> _loadMessages() async {
    if (!_isInitialLoad) return; // 避免重复加载
    
    setState(() {
      _isLoading = true;
    });

    try {
      // 🔥 步骤1：优先从本地快速加载，并立即显示
      await _loadLocalMessages();
      
      // 🔥 步骤2：确保UI立即更新，让用户先看到本地消息
      if (mounted) {
      setState(() {
        _isLoading = false;
        _isInitialLoad = false; // 标记初始加载完成
      });
      
        print('✅ 本地消息优先显示完成: ${_messages.length}条');
        // 🔥 修复：使用新的滚动机制，避免与build方法中的滚动冲突
        // _scrollToBottom(); // 已被新的滚动机制替代

        // 🔥 步骤3：等待500ms让UI稳定，再开始后台同步
        await Future.delayed(Duration(milliseconds: 500));
      }

      // 🔥 步骤4：后台同步最新消息（在本地消息显示后）
      print('🔄 开始后台同步，检查新消息...');
      await _syncLatestMessages();
      
    } catch (e) {
      print('加载消息失败: $e');
      setState(() {
        _isLoading = false;
        _isInitialLoad = false;
      });
    }
  }

  // 同步最新消息（后台执行）
  Future<void> _syncLatestMessages() async {
    print('开始后台同步消息...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取当前设备ID
      final serverDeviceData = prefs.getString('server_device_data');
      String? currentDeviceId;
      if (serverDeviceData != null) {
        try {
          final Map<String, dynamic> data = jsonDecode(serverDeviceData);
          currentDeviceId = data['id'];
        } catch (e) {
          print('解析设备ID失败: $e');
        }
      }

      List<Map<String, dynamic>> apiMessages = [];

      // 根据对话类型获取消息
      if (widget.conversation['type'] == 'group') {
        final groupId = widget.conversation['groupData']?['id'];
        if (groupId != null) {
          final result = await _chatService.getGroupMessages(groupId: groupId, limit: 50);
          if (result['messages'] != null) {
            apiMessages = List<Map<String, dynamic>>.from(result['messages']);
          }
        }
      } else {
        final deviceId = widget.conversation['deviceData']?['id'];
        if (deviceId != null) {
          final result = await _chatService.getPrivateMessages(targetDeviceId: deviceId, limit: 50);
          if (result['messages'] != null) {
            apiMessages = List<Map<String, dynamic>>.from(result['messages']);
          }
        }
      }

      // 🔥 关键修复：先过滤掉本机发送的消息，再转换格式
      print('🔍 同步前过滤：总消息${apiMessages.length}条，当前设备ID: $currentDeviceId');
      
      final List<Map<String, dynamic>> filteredApiMessages = apiMessages.where((msg) {
        final sourceDeviceId = msg['sourceDeviceId'];
        final isFromCurrentDevice = sourceDeviceId == currentDeviceId;
        
        if (isFromCurrentDevice) {
          print('🚫 过滤掉本机发送的消息: ${msg['id']} (${msg['content']?.substring(0, math.min(20, msg['content']?.length ?? 0)) ?? 'file'}...)');
          return false; // 排除本机发送的消息
        }
        
        return true; // 保留其他设备发送的消息
      }).toList();
      
      print('🔍 过滤后剩余：${filteredApiMessages.length}条消息需要同步');
      
      // 转换过滤后的API消息格式为本地格式
      final List<Map<String, dynamic>> convertedMessages = filteredApiMessages.map((msg) {
        final isMe = false; // 已经过滤掉本机消息，这里都是其他设备的消息
        return {
          'id': msg['id'],
          'text': msg['content'],
          'fileType': (msg['fileUrl'] != null || msg['fileName'] != null) ? _getFileType(msg['fileName']) : null,
          'fileName': msg['fileName'],
          'fileUrl': msg['fileUrl'],
          'fileSize': msg['fileSize'],
          'timestamp': _normalizeTimestamp(msg['createdAt'] ?? DateTime.now().toUtc().toIso8601String()),
          'isMe': isMe,
          'status': msg['status'] ?? 'sent',
          'sourceDeviceId': msg['sourceDeviceId'],
        };
      }).toList();

      // 按时间排序
      convertedMessages.sort((a, b) {
        try {
          final timeA = DateTime.parse(a['timestamp']);
          final timeB = DateTime.parse(b['timestamp']);
          return timeA.compareTo(timeB);
        } catch (e) {
          print('消息时间排序失败: $e');
          return 0;
        }
      });

      // 🔥 简化的去重逻辑：由于已经过滤掉本机消息，主要检查ID重复即可
      final List<Map<String, dynamic>> newMessages = [];
      
      for (final serverMsg in convertedMessages) {
        final serverId = serverMsg['id'].toString();
        
        // 🔥 统一的消息ID去重检查：只检查消息ID是否已存在
        if (_localMessageIds.contains(serverId)) {
          print('🎯 消息ID已存在于本地，跳过: $serverId');
          continue;
        }
        
        // 🔥 检查当前显示列表
        final existsById = _messages.any((localMsg) => localMsg['id'].toString() == serverId);
        if (existsById) {
          print('🎯 消息ID已在显示列表，跳过: $serverId');
          continue;
        }
        
        // 🔥 检查WebSocket实时消息去重
        if (_processedMessageIds.contains(serverId)) {
          print('🎯 消息ID在实时处理中已存在，跳过: $serverId');
          continue;
        }
            
        // 通过ID检查，添加到新消息列表
        newMessages.add(serverMsg);
        // 🔥 标记消息ID已处理
        _processedMessageIds.add(serverId);
        _messageIdTimestamps[serverId] = DateTime.now();
        _localMessageIds.add(serverId);
      }

      if (newMessages.isNotEmpty && mounted) {
        print('✅ 发现${newMessages.length}条其他设备的新消息，添加到界面');
        
        setState(() {
          _messages.addAll(newMessages);
          _messages.sort((a, b) {
            try {
              final timeA = DateTime.parse(a['timestamp']);
              final timeB = DateTime.parse(b['timestamp']);
              return timeA.compareTo(timeB);
            } catch (e) {
              print('消息时间排序失败: $e');
              return 0; // 如果时间解析失败，保持原顺序
            }
          });
        });
        
        // 为新消息自动下载文件
        for (final message in newMessages) {
          if (message['fileUrl'] != null && !message['isMe']) {
            _autoDownloadFile(message);
          }
        }
        
        // 保存更新后的消息到本地
        await _saveMessages();
        // 🔥 修复：移除后台同步后的自动滚动，避免打断用户阅读
        // _scrollToBottom();
        
        print('🎉 后台同步成功：新增${newMessages.length}条来自其他设备的消息');
      } else {
        final filteredCount = apiMessages.length - filteredApiMessages.length;
        final duplicateCount = convertedMessages.length - newMessages.length;
        print('📋 后台同步完成：过滤${filteredCount}条本机消息，${duplicateCount}条重复消息，无新消息需要显示');
      }
    } catch (e) {
      print('同步最新消息失败: $e');
    }
  }

  // 🔥 本地消息ID集合，用于后台同步时的精确去重
  final Set<String> _localMessageIds = {};

  // 加载本地缓存消息
  Future<void> _loadLocalMessages() async {
    final chatId = widget.conversation['id'];
    
    try {
      final messages = await _localStorage.loadChatMessages(chatId);
      if (mounted) {
        // 🔥 重要：清空并重建本地消息ID集合
        _localMessageIds.clear();
        for (final msg in messages) {
          if (msg['id'] != null) {
            _localMessageIds.add(msg['id'].toString());
          }
        }
        print('🔥 本地消息ID集合已建立: ${_localMessageIds.length}条');
        
        // 获取当前的永久存储路径
        final currentPermanentPath = await _localStorage.getPermanentStoragePath();
        final currentCacheDir = path.join(currentPermanentPath, 'files_cache');
        
        // 添加详细的调试日志
        print('=== 本地消息加载详情 ===');
        print('总消息数: ${messages.length}');
        print('当前缓存目录: $currentCacheDir');
        
        int textCount = 0;
        int fileCount = 0;
        int fixedCount = 0;
        int imageCount = 0;
        int videoCount = 0;
        int otherFileCount = 0;
        
        for (int i = 0; i < messages.length; i++) {
          final msg = messages[i];
          final hasFile = msg['fileType'] != null || msg['fileUrl'] != null || msg['fileName'] != null;
          
          if (hasFile) {
            fileCount++;
            final fileType = msg['fileType'];
            
            // 关键修复：检查是否有localFilePath，如果有就设置到filePath
            if (msg['localFilePath'] != null) {
              msg['filePath'] = msg['localFilePath'];
              print('设置本地文件路径: ${msg['fileName']} -> ${msg['localFilePath']}');
            }
            
            // 新增：检查并修复过期的文件路径
            if (msg['filePath'] != null) {
              final filePath = msg['filePath'] as String;
              final fileName = msg['fileName'] as String?;
              
              // 检查文件是否存在
              if (!await File(filePath).exists() && fileName != null) {
                // 尝试在当前缓存目录中查找文件
                final currentFilePath = path.join(currentCacheDir, fileName);
                if (await File(currentFilePath).exists()) {
                  print('🔧 修复文件路径: $fileName');
                  print('   旧路径: $filePath');
                  print('   新路径: $currentFilePath');
                  msg['filePath'] = currentFilePath;
                  fixedCount++;
                } else {
                  // 尝试查找带时间戳后缀的文件
                  final cacheDir = Directory(currentCacheDir);
                  if (await cacheDir.exists()) {
                    final files = await cacheDir.list().where((file) => file is File).toList();
                    for (final file in files) {
                      final existingFileName = path.basename(file.path);
                      if (existingFileName.contains(fileName.split('.').first)) {
                        print('🔧 修复文件路径(模糊匹配): $fileName -> $existingFileName');
                        msg['filePath'] = file.path;
                        fixedCount++;
                        break;
                      }
                    }
                  }
                }
              }
            }
            
            switch (fileType) {
              case 'image':
                imageCount++;
                break;
              case 'video':
                videoCount++;
                break;
              default:
                otherFileCount++;
                break;
            }
            print('文件消息 ${i+1}: ID=${msg['id']}, fileName=${msg['fileName']}, fileType=${msg['fileType']}, fileUrl=${msg['fileUrl']}, filePath=${msg['filePath']}');
          } else {
            textCount++;
            print('文本消息 ${i+1}: ID=${msg['id']}, text=${msg['text']?.substring(0, math.min(20, msg['text']?.length ?? 0))}...');
          }
        }
        
        print('文本消息: $textCount 条');
        print('文件消息: $fileCount 条 (图片: $imageCount, 视频: $videoCount, 其他: $otherFileCount)');
        print('修复的文件路径: $fixedCount 条');
        print('=== 本地消息加载详情结束 ===');
        
        setState(() {
          _messages = messages;
        });
        
        // 如果有文件路径被修复，保存更新
        if (fixedCount > 0) {
          print('保存修复后的消息到本地存储...');
          await _saveMessages();
        }
        
        // 🔥 修复：消息加载完成后，确保能滚动到底部
        print('📱 本地消息加载完成，消息数量: ${_messages.length}');
        if (_messages.isNotEmpty && !_hasScrolledToBottom) {
          // 延迟一点确保setState完成
          Future.delayed(Duration(milliseconds: 100), () {
            if (mounted && !_hasScrolledToBottom) {
              print('🔄 消息加载完成后执行滚动');
              _hasScrolledToBottom = true;
              _scrollToBottomWithRetry();
            }
          });
        }
      }
    } catch (e) {
      print('加载本地消息失败: $e');
      // 如果新存储失败，尝试旧版本兼容
      try {
        final prefs = await SharedPreferences.getInstance();
        final messagesJson = prefs.getString('chat_messages_$chatId') ?? '[]';
        final List<dynamic> messagesList = json.decode(messagesJson);
        if (mounted) {
          setState(() {
            _messages = messagesList.map((msg) => Map<String, dynamic>.from(msg)).toList();
          });
          
          // 🔥 修复：兼容模式消息加载完成后，确保能滚动到底部
          print('📱 兼容模式消息加载完成，消息数量: ${_messages.length}');
          if (_messages.isNotEmpty && !_hasScrolledToBottom) {
            // 延迟一点确保setState完成
            Future.delayed(Duration(milliseconds: 100), () {
              if (mounted && !_hasScrolledToBottom) {
                print('🔄 兼容模式消息加载完成后执行滚动');
                _hasScrolledToBottom = true;
                _scrollToBottomWithRetry();
              }
            });
          }
          
          // 迁移到新存储
          await _localStorage.saveChatMessages(chatId, _messages);
        }
      } catch (legacyError) {
        print('兼容旧版本存储也失败: $legacyError');
      }
    }
  }

  // 🔥 新增：带重试机制的滚动到底部方法
  Future<void> _scrollToBottomWithRetry({int maxRetries = 6}) async {
    print('🔄 开始滚动到底部，消息数量: ${_messages.length}');
    
    for (int i = 0; i < maxRetries; i++) {
      try {
        if (!mounted) {
          print('❌ Widget已卸载，停止滚动尝试');
          return;
        }
        
        // 等待时间逐渐增加，确保ListView完全构建
        final delayMs = [50, 150, 300, 500, 800, 1200][i];
        await Future.delayed(Duration(milliseconds: delayMs));
        
        if (_scrollController.hasClients && mounted) {
          final maxScrollExtent = _scrollController.position.maxScrollExtent;
          final viewportDimension = _scrollController.position.viewportDimension;
          print('📏 ScrollController - 最大滚动: $maxScrollExtent, 视口高度: $viewportDimension (尝试 ${i + 1}/$maxRetries)');
          
          // 如果没有可滚动的内容，说明内容还没有加载完成或者消息不够填满屏幕
          if (maxScrollExtent <= 0) {
            if (i < maxRetries - 1) {
              print('⏳ 内容还未完全加载或消息不够填满屏幕，等待下次尝试...');
              continue;
            } else {
              print('ℹ️ 消息不够填满屏幕，无需滚动');
              return;
            }
          }
          
          // 🔥 修复：使用animateTo而不是jumpTo，确保滚动到真正的底部
          await _scrollController.animateTo(
            maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          
          print('✅ 成功滚动到底部 (尝试 ${i + 1}/$maxRetries，位置: $maxScrollExtent)');
          
          // 验证是否真的滚动到了底部
          await Future.delayed(Duration(milliseconds: 100));
          if (_scrollController.hasClients) {
            final currentPosition = _scrollController.position.pixels;
            final actualMaxExtent = _scrollController.position.maxScrollExtent;
            final isAtBottom = (currentPosition >= actualMaxExtent - 10); // 允许10像素误差
            print('🔍 滚动验证 - 当前位置: $currentPosition, 最大位置: $actualMaxExtent, 是否在底部: $isAtBottom');
            
            if (isAtBottom) {
              print('✅ 确认已滚动到底部');
              return; // 真正成功
            } else if (i < maxRetries - 1) {
              print('⚠️ 未能滚动到底部，继续重试...');
              continue;
            }
          }
          
          return; // 成功后退出
        } else {
          print('❌ ScrollController未绑定或Widget已卸载 (尝试 ${i + 1}/$maxRetries)');
        }
      } catch (e) {
        print('❌ 滚动到底部失败 (尝试 ${i + 1}/$maxRetries): $e');
        if (i == maxRetries - 1) {
          print('⚠️ 达到最大重试次数，滚动到底部失败');
        }
      }
    }
  }

  // 保存聊天消息到本地
  Future<void> _saveMessages() async {
    final chatId = widget.conversation['id'];
    try {
      await _localStorage.saveChatMessages(chatId, _messages);
    } catch (e) {
      print('保存消息到持久化存储失败: $e');
      // 如果新存储失败，尝试保存到SharedPreferences作为后备
      try {
        final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_messages_$chatId', json.encode(_messages));
        print('已保存到SharedPreferences备份');
      } catch (backupError) {
        print('备份保存也失败: $backupError');
      }
    }
  }

  // 发送文本消息
  Future<void> _sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 生成消息ID和时间戳 - 使用UTC时间确保与服务器一致
    final messageId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final timestamp = DateTime.now().toUtc().toIso8601String();

    // 获取当前设备ID
    final prefs = await SharedPreferences.getInstance();
    final serverDeviceData = prefs.getString('server_device_data');
    String? currentDeviceId;
    if (serverDeviceData != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(serverDeviceData);
        currentDeviceId = data['id'];
      } catch (e) {
        print('解析设备ID失败: $e');
      }
    }

    // 立即显示自己的消息
    final myMessage = {
      'id': messageId,
      'text': text,
      'timestamp': timestamp,
      'isMe': true,
      'status': 'sending',
      'sourceDeviceId': currentDeviceId,
    };

    // 立即添加到界面并显示
    setState(() {
      _messages.add(myMessage);
      _messageController.clear();
      _isTyping = false;
    });
    
    // 立即保存并滚动，确保用户能看到消息
    await _saveMessages();
    _smoothScrollToBottom(); // 发送新消息时使用平滑滚动
    
    print('消息已立即添加到界面: $text, ID: $messageId');

    try {
      Map<String, dynamic>? apiResult;
      
      if (widget.conversation['type'] == 'group') {
        // 发送群组消息
        final groupId = widget.conversation['groupData']?['id'];
        if (groupId != null) {
          apiResult = await _chatService.sendGroupMessage(
            groupId: groupId,
            content: text,
          );
        }
      } else {
        // 发送私聊消息
        final deviceId = widget.conversation['deviceData']?['id'];
        if (deviceId != null) {
          apiResult = await _chatService.sendPrivateMessage(
            targetDeviceId: deviceId,
            content: text,
          );
        }
      }

      // 更新消息状态为已发送，但保持消息在界面中
      if (apiResult != null && mounted) {
        setState(() {
          final index = _messages.indexWhere((msg) => msg['id'] == messageId);
          if (index != -1) {
            _messages[index]['status'] = 'sent';
            // 如果API返回了真实的消息ID，更新它并标记为已处理
            if (apiResult!['messageId'] != null) {
              final realMessageId = apiResult['messageId'];
              _messages[index]['id'] = realMessageId;
              // 🔥 关键修复：记录真实消息ID的时间戳
              _processedMessageIds.add(realMessageId.toString());
              _messageIdTimestamps[realMessageId.toString()] = DateTime.now();
              print('消息ID更新并标记为已处理: $messageId -> $realMessageId');
            }
          }
        });
        await _saveMessages();
        print('消息发送成功并保持显示: $text');
      }
    } catch (e) {
      print('发送消息失败: $e');
      // 发送失败时，更新消息状态但不移除
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((msg) => msg['id'] == messageId);
          if (index != -1) {
            _messages[index]['status'] = 'failed';
          }
        });
        await _saveMessages();
      }
      
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // 发送文件消息
  Future<void> _sendFileMessage(File file, String fileName, String fileType) async {
    // 🔥 新增：检查文件大小限制（100MB）
    const int maxFileSize = 100 * 1024 * 1024; // 100MB
    final fileSize = await file.length();
    
    if (fileSize > maxFileSize) {
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      print('发送文件失败：文件大小超过限制 - ${fileSizeMB}MB > 100MB');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('文件太大无法发送\n文件大小: ${fileSizeMB}MB\n最大允许: 100MB'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return; // 阻止发送
    }
    
    // 立即复制文件到永久存储
    String? permanentFilePath;
    try {
      permanentFilePath = await _localStorage.copyFileToPermanentStorage(
        file.path, 
        fileName
      );
      print('文件已复制到永久存储: $fileName -> $permanentFilePath');
    } catch (e) {
      print('复制文件到永久存储失败: $e');
      // 如果复制失败，仍然继续发送，但使用原始路径
      permanentFilePath = file.path;
    }
    
    // 创建文件消息对象，包含进度信息
    final fileMessage = {
      'id': 'temp_file_${DateTime.now().millisecondsSinceEpoch}',
      'text': '', // 文件消息可能包含文字说明
      'fileType': _getFileType(fileName),
      'fileName': fileName,
      'filePath': permanentFilePath, // 使用永久存储路径
      'fileSize': await file.length(),
      'timestamp': DateTime.now().toUtc().toIso8601String(), // 使用UTC时间
      'isMe': true,
      'status': 'uploading', // 上传中状态
      'uploadProgress': 0.0, // 上传进度
      'isTemporary': true,
    };

    setState(() {
      _messages.add(fileMessage);
    });
    await _saveMessages();
    _smoothScrollToBottom(); // 发送文件时使用平滑滚动
    
    print('文件消息已立即添加到界面: $fileName, ID: ${fileMessage['id']}');

    try {
      Map<String, dynamic>? apiResult;
      
      if (widget.conversation['type'] == 'group') {
        // 发送群组文件
        final groupId = widget.conversation['groupData']?['id'];
        if (groupId != null) {
          // 🔥 改进的模拟上传进度，增加速度和ETA计算
          _simulateEnhancedUploadProgress(fileMessage['id'] as String, fileSize);
          
          apiResult = await _chatService.sendGroupFile(
            groupId: groupId,
            file: file,
            fileName: fileName,
            fileType: fileType,
          );
          
          // 更新临时消息为已发送状态，并更新完整的API返回信息
          if (apiResult != null && mounted) {
            // 先处理文件URL映射更新（异步操作）
            String? fileUrl;
            if (apiResult['fileUrl'] != null) {
              fileUrl = apiResult['fileUrl'] as String;
              if (permanentFilePath != null) {
                try {
                  await _localStorage.copyFileToPermanentStorage(
                    permanentFilePath, 
                    fileName, 
                    fileUrl: fileUrl
                  );
                } catch (e) {
                  print('更新文件URL映射失败: $e');
                }
              }
            }
            
            // 然后更新UI状态（同步操作）
            setState(() {
              final index = _messages.indexWhere((msg) => msg['id'] == fileMessage['id']);
              if (index != -1) {
                // 完整更新消息信息
                _messages[index]['status'] = 'sent';
                _messages[index]['isTemporary'] = false;
                if (apiResult!['messageId'] != null) {
                  _messages[index]['id'] = apiResult['messageId'];
                  _processedMessageIds.add(apiResult['messageId'].toString());
                  _messageIdTimestamps[apiResult['messageId'].toString()] = DateTime.now();
                }
                if (fileUrl != null) {
                  _messages[index]['fileUrl'] = fileUrl;
                }
                if (apiResult['fileName'] != null) {
                  _messages[index]['fileName'] = apiResult['fileName'];
                }
                if (apiResult['fileSize'] != null) {
                  _messages[index]['fileSize'] = apiResult['fileSize'];
                }
              }
            });
            await _saveMessages();
            print('文件发送成功: $fileName');
          }
        }
      } else {
        // 发送私聊文件
        final deviceId = widget.conversation['deviceData']?['id'];
        if (deviceId != null) {
          // 🔥 改进的模拟上传进度，增加速度和ETA计算
          _simulateEnhancedUploadProgress(fileMessage['id'] as String, fileSize);
          
          apiResult = await _chatService.sendPrivateFile(
            targetDeviceId: deviceId,
            file: file,
            fileName: fileName,
            fileType: fileType,
          );
          
          // 更新临时消息为已发送状态，并更新完整的API返回信息
          if (apiResult != null && mounted) {
            // 先处理文件URL映射更新（异步操作）
            String? fileUrl;
            if (apiResult['fileUrl'] != null) {
              fileUrl = apiResult['fileUrl'] as String;
              if (permanentFilePath != null) {
                try {
                  await _localStorage.copyFileToPermanentStorage(
                    permanentFilePath, 
                    fileName, 
                    fileUrl: fileUrl
                  );
                } catch (e) {
                  print('更新文件URL映射失败: $e');
                }
              }
            }
            
            // 然后更新UI状态（同步操作）
            setState(() {
              final index = _messages.indexWhere((msg) => msg['id'] == fileMessage['id']);
              if (index != -1) {
                // 完整更新消息信息
                _messages[index]['status'] = 'sent';
                _messages[index]['isTemporary'] = false;
                if (apiResult!['messageId'] != null) {
                  _messages[index]['id'] = apiResult['messageId'];
                  _processedMessageIds.add(apiResult['messageId'].toString());
                  _messageIdTimestamps[apiResult['messageId'].toString()] = DateTime.now();
                }
                if (fileUrl != null) {
                  _messages[index]['fileUrl'] = fileUrl;
                }
                if (apiResult['fileName'] != null) {
                  _messages[index]['fileName'] = apiResult['fileName'];
                }
                if (apiResult['fileSize'] != null) {
                  _messages[index]['fileSize'] = apiResult['fileSize'];
                }
              }
            });
            await _saveMessages();
            print('文件发送成功: $fileName');
          }
        }
      }
    } catch (e) {
      print('发送文件失败: $e');
      // 发送失败时，更新临时消息状态
      setState(() {
        final index = _messages.indexWhere((msg) => msg['id'] == fileMessage['id']);
        if (index != -1) {
          _messages[index]['status'] = 'failed';
          _messages[index]['isTemporary'] = false;
        }
      });
      await _saveMessages();
      
      // 🔥 优化：根据文件大小和错误类型提供更详细的错误提示
      String errorMessage = '发送文件失败';
      if (e.toString().contains('timeout')) {
        if (fileSize > 50 * 1024 * 1024) {
          errorMessage = '大文件上传超时，请检查网络连接并重试\n文件大小: ${_formatFileSize(fileSize)}';
        } else {
          errorMessage = '文件上传超时，请检查网络连接';
        }
      } else if (e.toString().contains('413')) {
        errorMessage = '文件太大，服务器拒绝处理\n请选择小于100MB的文件';
      } else if (e.toString().contains('network')) {
        errorMessage = '网络连接错误，请检查网络设置';
      } else {
        errorMessage = '发送文件失败: ${e.toString().length > 50 ? e.toString().substring(0, 50) + '...' : e.toString()}';
      }
      
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 5), // 增加显示时间，让用户有时间阅读
          action: fileSize <= 100 * 1024 * 1024 ? SnackBarAction(
            label: '重试',
            textColor: Colors.white,
            onPressed: () => _sendFileMessage(file, fileName, fileType),
          ) : null,
        ),
      );
    }
  }

  // 🔥 新增：增强的模拟上传进度
  Future<void> _simulateEnhancedUploadProgress(String messageId, int? fileSize) async {
    if (!mounted) return;
    
    final totalBytes = fileSize ?? 1024 * 1024; // 默认1MB
    final startTime = DateTime.now();
    var lastUpdateTime = startTime;
    var lastUploadedBytes = 0;
    
    // 模拟网络速度变化 (100KB/s - 2MB/s)
    final baseSpeedKBps = 500 + (math.Random().nextDouble() * 1500);
    
    for (int i = 0; i <= 100; i += 2) {
      if (!mounted) break;
      
      final progress = i / 100.0;
      final uploadedBytes = (totalBytes * progress).toInt();
      final currentTime = DateTime.now();
      
      // 计算传输速度
      final timeDiff = currentTime.difference(lastUpdateTime).inMilliseconds;
      double speedKBps = baseSpeedKBps;
      
      if (timeDiff > 0 && i > 0) {
        final bytesDiff = uploadedBytes - lastUploadedBytes;
        speedKBps = (bytesDiff / timeDiff) * 1000 / 1024; // 转换为KB/s
        
        // 计算预计剩余时间
        final remainingBytes = totalBytes - uploadedBytes;
        final etaSeconds = speedKBps > 0 ? (remainingBytes / 1024 / speedKBps).round() : null;
        
        setState(() {
          final index = _messages.indexWhere((msg) => msg['id'] == messageId);
          if (index != -1) {
            _messages[index]['uploadProgress'] = progress;
            _messages[index]['transferSpeed'] = speedKBps;
            _messages[index]['eta'] = etaSeconds;
          }
        });
        
        lastUpdateTime = currentTime;
        lastUploadedBytes = uploadedBytes;
      }
      
      // 可变延迟，模拟真实网络条件
      final delay = 150 + (math.Random().nextInt(100));
      await Future.delayed(Duration(milliseconds: delay));
    }
    
    // 上传完成，清除进度信息
    if (mounted) {
      setState(() {
        final index = _messages.indexWhere((msg) => msg['id'] == messageId);
        if (index != -1) {
          _messages[index]['uploadProgress'] = 1.0;
          _messages[index]['transferSpeed'] = 0.0;
          _messages[index]['eta'] = null;
        }
      });
    }
  }

  // 模拟上传进度（保留旧方法以兼容）
  Future<void> _simulateUploadProgress(String messageId) async {
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((msg) => msg['id'] == messageId);
          if (index != -1) {
            _messages[index]['uploadProgress'] = i / 100.0;
          }
        });
      }
    }
  }

  // 滚动到底部
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        try {
          // 立即跳转到底部，避免动画效果
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } catch (e) {
          print('滚动到底部失败: $e');
        }
      }
    });
  }
  
  // 平滑滚动到底部（用于发送新消息时）
  void _smoothScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        try {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), // 减少动画时间
          curve: Curves.easeOut,
        );
        } catch (e) {
          print('平滑滚动失败: $e');
        }
      }
    });
  }

  // 选择文件
  Future<void> _selectFile(FileType type) async {
    Navigator.pop(context);
    
    try {
      // 🔥 移动端支持多选文件
      final bool allowMultiple = !_isDesktop(); // 移动端允许多选，桌面端单选（因为有拖拽功能）
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type,
        allowMultiple: allowMultiple,
      );

      if (result != null && result.files.isNotEmpty) {
        // 🔥 处理多个选中的文件
        int processedCount = 0;
        int errorCount = 0;
        
        for (final fileData in result.files) {
          if (fileData.path == null) {
            errorCount++;
            continue;
          }
          
          final file = File(fileData.path!);
          final fileName = fileData.name;
          
          // 🔥 检查文件大小限制（100MB）
          const int maxFileSize = 100 * 1024 * 1024; // 100MB
          final fileSize = fileData.size;
          
          if (fileSize > maxFileSize) {
            // 文件超过100MB，显示错误提示但继续处理其他文件
            final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('文件 $fileName 太大无法发送\n文件大小: ${fileSizeMB}MB\n最大允许: 100MB'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            errorCount++;
            continue;
          }
          
          // 🔥 修改：移动端多选文件直接发送，无需预览步骤
          final fileType = _getMimeType(fileName);
          await _sendFileMessage(file, fileName, fileType);
          processedCount++;
          
          // 添加短暂延迟避免发送过快
          if (allowMultiple && processedCount < result.files.length) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
        }
        
        // 🔥 显示处理结果
        if (result.files.length > 1 && mounted) {
          final successMessage = processedCount > 0 
            ? '已发送 $processedCount 个文件'
            : '没有文件可以发送';
          
          final statusMessage = errorCount > 0
            ? '$successMessage (${errorCount}个文件有问题)'
            : successMessage;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(statusMessage),
              backgroundColor: processedCount > 0 ? Colors.green : Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('选择文件失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('选择文件失败: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // 获取MIME类型
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGroup = widget.conversation['type'] == 'group';
    final title = widget.conversation['title'];
    
    return ListenableBuilder(
      listenable: _multiSelectController,
      builder: (context, child) {
        // 🔥 桌面端拖拽支持
        Widget scaffoldWidget = Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          // 🔥 彻底移除AppBar - 完全沉浸式聊天界面
          body: Column(
            children: [
              // 消息列表
              Expanded(
                child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : _messages.isEmpty
                    ? _buildEmptyState()
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: _handleScrollNotification,
                          child: GestureDetector(
                            onPanUpdate: _handlePanUpdate,
                            onPanEnd: _handlePanEnd,
                            child: Stack(
                              children: [
                                Builder(
                                  builder: (context) {
                                    // 🔥 修复：确保ListView构建完成后滚动到底部
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted && _messages.isNotEmpty && !_hasScrolledToBottom) {
                                        print('🔄 执行首次滚动到底部，消息数量: ${_messages.length}');
                                        _hasScrolledToBottom = true; // 标记已经滚动过
                                        _scrollToBottomWithRetry();
                                      }
                                    });
                                    
                                    return ListView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      itemCount: _messages.length,
                                      itemBuilder: (context, index) {
                                        final message = _messages[index];
                                        return _buildMessageBubble(message);
                                      },
                                    );
                                  },
                                ),
                                // 🔥 简洁的下拉刷新指示器 - 只在刷新时显示
                                _buildPullToRefreshIndicator(),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
              
              // 多选模式工具栏
              if (_multiSelectController.isMultiSelectMode)
                _buildMultiSelectToolbar(),
              
              // 输入区域
              if (!_multiSelectController.isMultiSelectMode)
                _buildInputArea(),
                        ],
          ),
        );
        
        // 🔥 桌面端添加拖拽和粘贴支持
        if (_isDesktop()) {
          return DropTarget(
            onDragDone: (detail) async {
              print('🔥 拖拽文件到聊天界面: ${detail.files.length} 个文件');
              await _handleDroppedFiles(detail.files);
            },
            onDragEntered: (detail) {
              print('拖拽进入聊天界面');
            },
            onDragExited: (detail) {
              print('拖拽离开聊天界面');
            },
            child: Focus(
              onKey: (node, event) {
                // 🔥 处理桌面端粘贴 (Ctrl+V 或 Cmd+V)
                if (event is RawKeyDownEvent &&
                    ((defaultTargetPlatform == TargetPlatform.macOS && event.isMetaPressed) ||
                     (defaultTargetPlatform != TargetPlatform.macOS && event.isControlPressed)) &&
                    event.logicalKey == LogicalKeyboardKey.keyV) {
                  _handleClipboardPaste();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: scaffoldWidget,
            ),
          );
        }
        
        return scaffoldWidget;
      },
    );
  }

  // 🔥 新增：处理剪贴板粘贴（支持文本和文件）
  Future<void> _handleClipboardPaste() async {
    try {
      // 🔥 桌面端使用 super_clipboard，移动端使用传统API
      if (_isDesktop() && !kIsWeb) {
        await _handleDesktopClipboardPaste();
      } else {
        await _handleMobileClipboardPaste();
      }
    } catch (e) {
      print('❌ 剪贴板粘贴失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('粘贴失败: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // 🔥 桌面端剪贴板处理（使用 super_clipboard）
  Future<void> _handleDesktopClipboardPaste() async {
    try {
      final clipboard = SystemClipboard.instance;
      if (clipboard != null) {
        final reader = await clipboard.read();
        
        print('📋 检查桌面端剪贴板内容...');
        
        // 检查是否有文件URI
        if (reader.canProvide(Formats.fileUri)) {
          print('🔍 剪贴板包含文件，开始读取...');
          try {
            final fileUriData = await reader.readValue(Formats.fileUri);
            if (fileUriData != null) {
              print('📁 从剪贴板读取到文件URI: $fileUriData');
              
              // 处理文件URI字符串，可能是多个用换行分隔
              final String uriString = fileUriData.toString();
              final List<String> uriStrings = uriString.split('\n')
                  .where((uri) => uri.trim().isNotEmpty)
                  .toList();
              
              // 🔥 修复：处理多文件粘贴，确保所有文件都被处理
              int processedCount = 0;
              int errorCount = 0;
              
              for (final uriStr in uriStrings) {
                try {
                  final uri = Uri.parse(uriStr.trim());
                  String filePath;
                  
                  // 处理不同格式的URI
                  if (uri.scheme == 'file') {
                    filePath = uri.toFilePath();
                  } else if (uri.scheme.isEmpty) {
                    // 可能是相对路径
                    filePath = uriStr.trim();
                  } else {
                    print('❌ 不支持的URI格式: $uriStr');
                    errorCount++;
                    continue;
                  }
                  
                  final file = File(filePath);
                  
                  if (await file.exists()) {
                    final fileName = path.basename(filePath);
                    final fileSize = await file.length();
                    
                    print('📄 处理粘贴文件 ${processedCount + 1}/${uriStrings.length}: $fileName (${fileSize} 字节)');
                    
                    // 检查文件大小限制 (100MB)
                    if (fileSize > 100 * 1024 * 1024) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('文件 $fileName 太大，请选择小于100MB的文件'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      errorCount++;
                      continue;
                    }
                    
                    // 将文件添加到预览列表
                    await _addFileToPreview(file, fileName, fileSize);
                    processedCount++;
                  } else {
                    print('❌ 文件不存在: $filePath');
                    errorCount++;
                  }
                } catch (e) {
                  print('❌ 处理文件URI失败: $uriStr, 错误: $e');
                  errorCount++;
                  continue;
                }
              }
              
              // 🔥 新增：显示处理结果统计
              if (uriStrings.isNotEmpty && mounted) {
                final successMessage = processedCount > 0 
                  ? '已添加 $processedCount 个文件到预览'
                  : '没有文件可以添加';
                
                final statusMessage = errorCount > 0
                  ? '$successMessage (${errorCount}个文件有问题)'
                  : successMessage;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(statusMessage),
                    backgroundColor: processedCount > 0 ? Colors.green : Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
                
                // 🔥 修复：如果有文件被处理，则不继续处理文本
                if (processedCount > 0) {
                  return;
                }
              }
            }
          } catch (e) {
            print('❌ 读取剪贴板文件失败: $e');
          }
        }
        
        // 如果没有文件，尝试读取文本
        if (reader.canProvide(Formats.plainText)) {
          try {
            final text = await reader.readValue(Formats.plainText);
            if (text != null && text.isNotEmpty) {
              _messageController.text = _messageController.text + text;
              setState(() {
                _isTyping = _messageController.text.trim().isNotEmpty || _pendingFiles.isNotEmpty;
              });
              print('✅ 粘贴文本到输入框: ${text.length} 个字符');
              return;
            }
          } catch (e) {
            print('❌ 读取剪贴板文本失败: $e');
          }
        }
      }
      
      // 兜底：使用传统的剪贴板API
      await _handleMobileClipboardPaste();
      
    } catch (e) {
      print('❌ 桌面端剪贴板处理失败: $e');
      // 兜底到移动端处理
      await _handleMobileClipboardPaste();
    }
  }

  // 🔥 移动端剪贴板处理（传统API，只支持文本）
  Future<void> _handleMobileClipboardPaste() async {
    try {
      print('📋 检查移动端剪贴板内容...');
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.isNotEmpty) {
        _messageController.text = _messageController.text + data.text!;
        setState(() {
          _isTyping = _messageController.text.trim().isNotEmpty || _pendingFiles.isNotEmpty;
        });
        print('✅ 粘贴文本到输入框: ${data.text!.length} 个字符');
      }
    } catch (e) {
      print('❌ 移动端剪贴板处理失败: $e');
    }
  }

  // 🔥 新增：处理拖拽的文件（添加到输入框预览）
  Future<void> _handleDroppedFiles(List<XFile> files) async {
    if (files.isEmpty) return;
    
    try {
      for (final file in files) {
        print('📁 处理拖拽文件: ${file.name} (${file.path})');
        
        // 检查文件是否存在
        final fileObj = File(file.path);
        if (!await fileObj.exists()) {
          print('❌ 文件不存在: ${file.path}');
          continue;
        }
        
        // 获取文件大小
        final fileStat = await fileObj.stat();
        final fileSize = fileStat.size;
        
        // 检查文件大小限制 (100MB)
        if (fileSize > 100 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('文件 ${file.name} 太大，请选择小于100MB的文件'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          continue;
        }
        
        // 🔥 将文件添加到预览列表
        await _addFileToPreview(fileObj, file.name, fileSize);
      }
    } catch (e) {
      print('❌ 拖拽文件处理失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('文件处理失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔥 新增：将文件添加到预览列表
  Future<void> _addFileToPreview(File file, String fileName, int fileSize) async {
    final fileType = _getFileType(fileName);
    
    final fileInfo = {
      'file': file,
      'name': fileName,
      'size': fileSize,
      'type': fileType,
      'path': file.path,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    
    // 如果是图片，生成缩略图
    if (fileType == 'image') {
      try {
        final bytes = await file.readAsBytes();
        fileInfo['thumbnail'] = bytes;
      } catch (e) {
        print('❌ 生成图片缩略图失败: $e');
      }
    }
    
    setState(() {
      _pendingFiles.add(fileInfo);
      _showFilePreview = true;
      _isTyping = _messageController.text.trim().isNotEmpty || _pendingFiles.isNotEmpty;
    });
    
    print('✅ 文件已添加到预览: $fileName');
  }

  // 🔥 新增：从预览列表移除文件
  void _removeFileFromPreview(String fileId) {
    setState(() {
      _pendingFiles.removeWhere((file) => file['id'] == fileId);
      _showFilePreview = _pendingFiles.isNotEmpty;
      _isTyping = _messageController.text.trim().isNotEmpty || _pendingFiles.isNotEmpty;
    });
  }

  // 🔥 新增：发送带文件的消息
  Future<void> _sendMessageWithFiles() async {
    final text = _messageController.text.trim();
    final files = List<Map<String, dynamic>>.from(_pendingFiles);
    
    if (text.isEmpty && files.isEmpty) return;
    
    try {
      // 清空输入框和预览
      setState(() {
        _messageController.clear();
        _pendingFiles.clear();
        _showFilePreview = false;
        _isTyping = false;
      });
      
      // 如果有文本，先发送文本消息
      if (text.isNotEmpty) {
        await _sendTextMessage(text);
      }
      
      // 发送所有文件
      for (final fileInfo in files) {
        final file = fileInfo['file'] as File;
        final fileName = fileInfo['name'] as String;
        final fileType = fileInfo['type'] as String;
        
        await _sendFileMessage(file, fileName, fileType);
        await Future.delayed(const Duration(milliseconds: 100)); // 避免发送过快
      }
      
      print('✅ 已发送消息和 ${files.length} 个文件');
    } catch (e) {
      print('❌ 发送带文件消息失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  // 构建多选模式工具栏
  Widget _buildMultiSelectToolbar() {
    final selectedMessages = _multiSelectController.selectedMessages;
    final selectedMessageObjects = _messages
        .where((msg) => selectedMessages.contains(msg['id']?.toString() ?? ''))
        .toList();
    
    final hasTextMessages = selectedMessageObjects
        .any((msg) => msg['text'] != null && msg['text'].toString().isNotEmpty);
    final hasOwnMessages = selectedMessageObjects
        .any((msg) => msg['isMe'] == true);
    
    return MultiSelectMode(
      selectedCount: _multiSelectController.selectedCount,
      onCancel: () => _multiSelectController.exitMultiSelectMode(),
      hasTextMessages: hasTextMessages,
      hasOwnMessages: hasOwnMessages,
      onCopy: hasTextMessages ? () => _batchCopyMessages(selectedMessageObjects) : null,
      onForward: () => _batchForwardMessages(selectedMessageObjects),
      onFavorite: () => _batchFavoriteMessages(selectedMessageObjects),
      onRevoke: hasOwnMessages ? () => _batchRevokeMessages(selectedMessages.toList()) : null,
      onDelete: hasOwnMessages ? () => _batchDeleteMessages(selectedMessages.toList()) : null,
    );
  }
  
  // 批量复制消息
  Future<void> _batchCopyMessages(List<Map<String, dynamic>> messages) async {
    final textMessages = messages
        .where((msg) => msg['text'] != null && msg['text'].toString().isNotEmpty)
        .map((msg) => msg['text'].toString())
        .join('\n\n');
    
    if (textMessages.isNotEmpty) {
      final success = await _messageActionsService.copyMessageText(textMessages);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已复制${messages.length}条消息到剪贴板')),
        );
        _multiSelectController.exitMultiSelectMode();
      }
    }
  }
  
  // 批量转发消息
  void _batchForwardMessages(List<Map<String, dynamic>> messages) {
    final forwardTexts = messages
        .map((msg) => _messageActionsService.formatMessageForForward(msg))
        .join('\n\n---\n\n');
    
    _messageController.text = forwardTexts;
    _multiSelectController.exitMultiSelectMode();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${messages.length}条消息内容已添加到输入框')),
      );
    }
  }
  
  // 批量收藏消息
  Future<void> _batchFavoriteMessages(List<Map<String, dynamic>> messages) async {
    int successCount = 0;
    
    for (final message in messages) {
      final success = await _messageActionsService.favoriteMessage(message);
      if (success) successCount++;
    }
    
    _multiSelectController.exitMultiSelectMode();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已收藏${successCount}/${messages.length}条消息')),
      );
    }
  }
  
  // 批量撤回消息
  Future<void> _batchRevokeMessages(List<String> messageIds) async {
    final confirmed = await _showConfirmDialog(
      title: '批量撤回',
      content: '确定要撤回选中的${messageIds.length}条消息吗？',
      confirmText: '撤回',
    );
    
    if (confirmed) {
      final result = await _messageActionsService.batchRevokeMessages(
        messageIds: messageIds,
        reason: '批量撤回',
      );
      
      _multiSelectController.exitMultiSelectMode();
      
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已撤回${messageIds.length}条消息')),
          );
          // 更新本地消息状态
          for (final messageId in messageIds) {
            _updateMessageAfterRevoke(messageId);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('批量撤回失败: ${result['error']}')),
          );
        }
      }
    }
  }
  
  // 批量删除消息
  Future<void> _batchDeleteMessages(List<String> messageIds) async {
    final confirmed = await _showConfirmDialog(
      title: '批量删除',
      content: '确定要删除选中的${messageIds.length}条消息吗？删除后无法恢复。',
      confirmText: '删除',
      isDestructive: true,
    );
    
    if (confirmed) {
      final result = await _messageActionsService.batchDeleteMessages(
        messageIds: messageIds,
        reason: '批量删除',
      );
      
      _multiSelectController.exitMultiSelectMode();
      
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已删除${messageIds.length}条消息')),
          );
          // 从本地移除消息
          setState(() {
            _messages.removeWhere((msg) => messageIds.contains(msg['id']?.toString()));
          });
          _saveMessages();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('批量删除失败: ${result['error']}')),
          );
        }
      }
    }
  }
  
  // 显示存储信息（调试功能）
  Future<void> _showStorageInfo() async {
    try {
      final permanentPath = await _localStorage.getPermanentStoragePath();
      final storageInfo = await _localStorage.getStorageInfo();
      final fileCacheInfo = await _localStorage.getFileCacheInfo();
      
      // 🔥 新增：获取去重诊断信息
      _debugDuplicationState(); // 输出到控制台
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('调试信息'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('永久存储目录:'),
                const SizedBox(height: 4),
                Text(permanentPath, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                const SizedBox(height: 16),
                Text('存储使用情况:'),
                const SizedBox(height: 8),
                Text('聊天数据: ${_formatBytes(storageInfo['chatSize'] ?? 0)}'),
                Text('记忆数据: ${_formatBytes(storageInfo['memorySize'] ?? 0)}'),
                Text('用户数据: ${_formatBytes(storageInfo['userDataSize'] ?? 0)}'),
                Text('文件缓存: ${_formatBytes(storageInfo['fileCacheSize'] ?? 0)}'),
                Text('总计: ${_formatBytes(storageInfo['totalSize'] ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text('文件缓存统计:'),
                const SizedBox(height: 8),
                Text('总文件数: ${fileCacheInfo['totalFiles']}'),
                Text('有效文件: ${fileCacheInfo['validFiles']}'),
                Text('无效文件: ${fileCacheInfo['invalidFiles']}'),
                const SizedBox(height: 16),
                // 🔥 新增：去重诊断信息
                Text('去重诊断:'),
                const SizedBox(height: 8),
                Text('已处理消息ID: ${_processedMessageIds.length}'),
                Text('时间戳记录: ${_messageIdTimestamps.length}'),
                Text('界面消息数: ${_messages.length}'),
                Text('WebSocket连接: ${_websocketService.isConnected ? "已连接" : "未连接"}'),
                if (_lastMessageReceivedTime != null) ...[
                  Text('最后收到消息: ${DateTime.now().difference(_lastMessageReceivedTime!).inMinutes}分钟前'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _forceClearDuplicationRecords();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已强制清理去重记录并重启WebSocket监听')),
                );
              },
              child: const Text('清理去重记录'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('显示调试信息失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取调试信息失败: $e')),
      );
    }
  }
  
  // 格式化字节数
  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48, // 减小图标容器
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12), // 减小圆角
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 20, // 减小图标
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12), // 减少间距
          Text(
            '开始对话',
            style: AppTheme.bodyStyle, // 使用更小的字体
            ),
          const SizedBox(height: 4), // 减少间距
          Text(
            '发送消息或文件来开始聊天',
            style: AppTheme.captionStyle.copyWith(
              fontSize: 10, // 进一步减小说明文字
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['isMe'] == true;
    final hasFile = message['fileType'] != null;
    final messageId = message['id']?.toString() ?? '';
    
    // 添加调试日志
    if (message['fileUrl'] != null || message['fileName'] != null) {
      print('构建消息气泡: ID=${message['id']}, fileName=${message['fileName']}, fileType=${message['fileType']}, hasFile=$hasFile, fileUrl=${message['fileUrl']}');
    }
    
    return ListenableBuilder(
      listenable: _multiSelectController,
      builder: (context, child) {
        final isSelected = _multiSelectController.isSelected(messageId);
        final isMultiSelectMode = _multiSelectController.isMultiSelectMode;
        
        return GestureDetector(
          onTap: () {
            if (isMultiSelectMode) {
              // 多选模式下点击切换选中状态
              _multiSelectController.toggleMessage(messageId);
            }
          },
          onLongPress: () {
            if (isMultiSelectMode) {
              // 已在多选模式，切换选中状态
              _multiSelectController.toggleMessage(messageId);
            } else {
              // 显示长按菜单
              _showMessageActionMenu(message, isMe);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 消息气泡
                Row(
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 多选模式下显示选择框
                    if (isMultiSelectMode) ...[
                      Container(
                        margin: EdgeInsets.only(
                          right: isMe ? 0 : 8,
                          left: isMe ? 8 : 0,
                        ),
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            _multiSelectController.toggleMessage(messageId);
                          },
                          activeColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                    
                    Flexible(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 
                            (isMultiSelectMode ? 0.65 : 0.75),
                        ),
                        padding: EdgeInsets.all(hasFile ? 6 : 10),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : (isMe 
                              ? (hasFile ? Colors.white : AppTheme.primaryColor) 
                              : Colors.white),
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                          ),
                          border: Border.all(
                            color: isSelected 
                              ? AppTheme.primaryColor.withOpacity(0.5)
                              : const Color(0xFFE5E7EB), 
                            width: isSelected ? 2 : 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 文件内容
                            if (hasFile) _buildFileContent(message, isMe),
                            
                            // 文本内容
                            if (message['text'] != null && message['text'].isNotEmpty) ...[
                              if (hasFile) const SizedBox(height: 6),
                              // 🔥 桌面端添加右键菜单和可选择性
                              _isDesktop()
                                ? ContextMenuRegion(
                                    contextMenu: GenericContextMenu(
                                      buttonConfigs: [
                                        ContextMenuButtonConfig(
                                          "复制文字",
                                          onPressed: () => _copyMessageText(message),
                                        ),
                                        ContextMenuButtonConfig(
                                          "选择全部文字",
                                          onPressed: () => _selectAllText(message),
                                        ),
                                        if (message['fileType'] != null) ...[
                                          ContextMenuButtonConfig(
                                            "复制全部内容",
                                            onPressed: () => _copyAllContent(message),
                                          ),
                                        ],
                                        ContextMenuButtonConfig(
                                          "回复",
                                          onPressed: () => _replyToMessage(message),
                                        ),
                                        ContextMenuButtonConfig(
                                          "转发",
                                          onPressed: () => _forwardMessage(message),
                                        ),
                                      ],
                                    ),
                                    child: SelectableText(
                                      message['text'],
                                      style: AppTheme.bodyStyle.copyWith(
                                        color: isMe 
                                          ? (hasFile ? AppTheme.textPrimaryColor : Colors.white)
                                          : AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                  )
                                : Text(
                                    message['text'],
                                    style: AppTheme.bodyStyle.copyWith(
                                      color: isMe 
                                        ? (hasFile ? AppTheme.textPrimaryColor : Colors.white)
                                        : AppTheme.textPrimaryColor,
                                    ),
                                  ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // 时间戳和状态
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (isMultiSelectMode && !isMe) 
                      const SizedBox(width: 40), // 为复选框留出空间
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          TimeUtils.formatChatDateTime(message['timestamp']),
                          style: AppTheme.smallStyle.copyWith(
                            fontSize: 9,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 3),
                          _buildMessageStatusIcon(message),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileContent(Map<String, dynamic> message, bool isMe) {
    final fileType = message['fileType'];
    final fileName = message['fileName'] ?? 'unknown_file';
    final fileSize = message['fileSize'];
    final filePath = message['filePath']; // 本地文件路径
    final fileUrl = message['fileUrl']; // 远程文件URL
    final uploadProgress = message['uploadProgress'] ?? 1.0;
    final downloadProgress = message['downloadProgress'];
    final status = message['status'] ?? 'sent';
    final transferSpeed = message['transferSpeed'] ?? 0.0; // KB/s
    final eta = message['eta']; // 预计剩余时间（秒）

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 修复：移除显眼的成功指示器覆盖层，只显示文件预览
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildFilePreview(fileType, filePath, fileUrl, isMe),
          ),
          
          // 🔥 新的上传进度UI
          if (status == 'uploading' && uploadProgress < 1.0)
            _buildTransferProgressWidget(
              isUpload: true,
              progress: uploadProgress,
              fileName: fileName,
              fileSize: fileSize,
              transferSpeed: transferSpeed,
              eta: eta,
              isMe: isMe,
              messageId: message['id'],
            ),
          
          // 🔥 新的下载进度UI
          if (downloadProgress != null && downloadProgress < 1.0)
            _buildTransferProgressWidget(
              isUpload: false,
              progress: downloadProgress,
              fileName: fileName,
              fileSize: fileSize,
              transferSpeed: transferSpeed,
              eta: eta,
              isMe: isMe,
              messageId: message['id'],
            ),
        ],
      ),
    );
  }

  // 🔥 新增：构建传输进度组件
  Widget _buildTransferProgressWidget({
    required bool isUpload,
    required double progress,
    required String fileName,
    required int? fileSize,
    required double transferSpeed,
    required int? eta,
    required bool isMe,
    required String messageId,
  }) {
    final progressPercent = (progress * 100).toInt();
    final transferType = isUpload ? '上传' : '下载';
    
    // 🔥 修复：改进颜色主题，确保文字可见性
    final primaryColor = isUpload 
      ? (isMe ? AppTheme.primaryColor : AppTheme.primaryColor)
      : const Color(0xFF3B82F6);
    
    final backgroundColor = const Color(0xFFF8FAFC);
    final borderColor = AppTheme.primaryColor.withOpacity(0.2);
    
    // 🔥 修复：确保文字颜色在所有背景下都可见
    final textColor = AppTheme.textPrimaryColor;
    final secondaryTextColor = AppTheme.textSecondaryColor;
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 改进：标题行设计
          Row(
            children: [
              // 传输图标（带动画和更好的视觉效果）
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnimatedRotation(
                  turns: progress * 2, // 随进度旋转
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    isUpload ? Icons.cloud_upload_rounded : Icons.cloud_download_rounded,
                    size: 18,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // 文件信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$transferType中',
                            style: TextStyle(
                              fontSize: 11,
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$progressPercent%',
                          style: TextStyle(
                            fontSize: 13,
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 取消按钮
              GestureDetector(
                onTap: () => _cancelTransfer(messageId, isUpload),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.red.shade600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 🔥 修复：改进的进度条，修复宽度计算
          LayoutBuilder(
            builder: (context, constraints) {
              final progressWidth = constraints.maxWidth * progress;
              
              return Stack(
                children: [
                  // 背景进度条
                  Container(
                    height: 8,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // 实际进度条（带动画）
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 8,
                    width: progressWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          // 🔥 改进：详细信息行设计
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 文件大小信息
              if (fileSize != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_formatFileSize((fileSize * progress).toInt())} / ${_formatFileSize(fileSize)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              
              // 传输速度和预计时间
              if (transferSpeed > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.speed_rounded,
                        size: 12,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTransferSpeed(transferSpeed),
                        style: TextStyle(
                          fontSize: 11,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (eta != null) ...[
                        Text(
                          ' • ${_formatETA(eta)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 🔥 新增：取消传输
  void _cancelTransfer(String messageId, bool isUpload) {
    // 显示确认对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isUpload ? '取消上传' : '取消下载'),
        content: Text('确定要${isUpload ? '取消上传' : '取消下载'}这个文件吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('继续传输'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performCancelTransfer(messageId, isUpload);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('确定取消'),
          ),
        ],
      ),
    );
  }

  // 🔥 新增：执行取消传输
  void _performCancelTransfer(String messageId, bool isUpload) {
    setState(() {
      final messageIndex = _messages.indexWhere((m) => m['id'] == messageId);
      if (messageIndex != -1) {
        if (isUpload) {
          _messages[messageIndex]['status'] = 'cancelled';
          _messages[messageIndex]['uploadProgress'] = 0.0;
        } else {
          _messages[messageIndex]['downloadProgress'] = null;
        }
      }
    });
    
    // 保存状态
    _saveMessages();
    
    // 显示取消提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${isUpload ? '上传' : '下载'}已取消'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 🔥 新增：格式化传输速度
  String _formatTransferSpeed(double speedKBps) {
    if (speedKBps < 1024) {
      return '${speedKBps.toStringAsFixed(1)} KB/s';
    } else {
      return '${(speedKBps / 1024).toStringAsFixed(1)} MB/s';
    }
  }

  // 🔥 新增：格式化预计剩余时间
  String _formatETA(int seconds) {
    if (seconds < 60) {
      return '${seconds}秒';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '${minutes}分钟';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}小时${minutes}分钟';
    }
  }

  // 构建文件预览 - 简化版本
  Widget _buildFilePreview(String? fileType, String? filePath, String? fileUrl, bool isMe) {
    // 🔥 简化：减少调试日志，保持代码简洁
    
    // 🔥 新增：检查是否正在下载
    if (fileUrl != null) {
      String fullUrl = fileUrl;
      if (fileUrl.startsWith('/api/')) {
        fullUrl = 'https://sendtomyself-api-adecumh2za-uc.a.run.app$fileUrl';
      }
      
      // 如果正在下载，显示下载中状态
      if (_downloadingFiles.contains(fullUrl)) {
        return _buildDownloadingPreview(fileType);
      }
    }
    
    // 1. 优先使用传入的本地文件路径
    if (filePath != null) {
      if (File(filePath).existsSync()) {
        return _buildActualFilePreview(fileType, filePath, fileUrl, isMe);
      }
    }
    
    // 2. 检查URL缓存
    if (fileUrl != null) {
      String fullUrl = fileUrl;
      if (fileUrl.startsWith('/api/')) {
        fullUrl = 'https://sendtomyself-api-adecumh2za-uc.a.run.app$fileUrl';
      }
      
      // 检查内存缓存
      final cachedPath = _getFromCache(fullUrl);
      if (cachedPath != null && File(cachedPath).existsSync()) {
        return _buildActualFilePreview(fileType, cachedPath, fileUrl, isMe);
      }
      
      // 异步检查持久化存储
      return FutureBuilder<String?>(
        future: _localStorage.getFileFromCache(fullUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingPreview();
          }
          
          final persistentPath = snapshot.data;
          if (persistentPath != null && File(persistentPath).existsSync()) {
            _addToCache(fullUrl, persistentPath);
            return _buildActualFilePreview(fileType, persistentPath, fileUrl, isMe);
          }
          
          // 🔥 修复：显示准备下载状态而不是"文件不存在"
          return _buildPrepareDownloadPreview(fileType);
        },
      );
    }
    
    return _buildFileNotFoundPreview(fileType, fileUrl);
  }

  // 🔥 新增：下载中预览
  Widget _buildDownloadingPreview(String? fileType) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '下载中...',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),

          ),
        ],
      ),
    );
  }

  // 🔥 新增：准备下载预览
  Widget _buildPrepareDownloadPreview(String? fileType) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileTypeIcon(fileType),
            size: 24,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 4),
          Text(
            '准备下载',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 加载中预览
  Widget _buildLoadingPreview() {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  // 文件未找到预览
  Widget _buildFileNotFoundPreview(String? fileType, String? fileUrl) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileTypeIcon(fileType),
            size: 24,
            color: const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 4),
          Text(
            '文件不存在',
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  // 实际构建文件预览的方法
  Widget _buildActualFilePreview(String? fileType, String? filePath, String? fileUrl, bool isMe) {
    Widget fileWidget = Container(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片和视频只显示预览，不显示额外信息
          if (fileType == 'image') 
            _buildSimpleImagePreview(filePath, fileUrl)
          else if (fileType == 'video')
            _buildSimpleVideoPreview(filePath, fileUrl)
          else
            // 其他文件类型显示简洁信息
            Container(
              padding: const EdgeInsets.all(8), // 减少内边距
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(6), // 减小圆角
                border: Border.all(
                  color: AppTheme.borderColor,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getFileTypeIcon(fileType),
                    size: 14, // 减小图标
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 6), // 减少间距
                  Flexible(
                    child: Text(
                      _getFileName(filePath, fileUrl) ?? '文件',
                      style: AppTheme.captionStyle.copyWith(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 10, // 减小文字
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    
    // 🔥 桌面端添加右键菜单和点击功能
    if (_isDesktop()) {
      return ContextMenuRegion(
        contextMenu: _buildFileContextMenu(filePath, fileUrl, fileType),
        child: GestureDetector(
          onTap: () => _openFile(filePath, fileUrl, fileType),
          child: fileWidget,
        ),
      );
    } else {
      // 移动端只有点击功能
      return GestureDetector(
        onTap: () => _openFile(filePath, fileUrl, fileType),
        child: fileWidget,
      );
    }
  }

  // 构建简单图片预览
  Widget _buildSimpleImagePreview(String? filePath, String? fileUrl) {
    Widget imageWidget;
    
    if (filePath != null && File(filePath).existsSync()) {
      imageWidget = Image.file(
        File(filePath),
        height: 80, // 减少高度
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (fileUrl != null) {
      imageWidget = Image.network(
        fileUrl,
        height: 80, // 减少高度
        width: double.infinity,
        fit: BoxFit.cover,
        headers: _dio.options.headers.map((key, value) => MapEntry(key, value.toString())), // 添加认证头
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 80, // 减少高度
            width: double.infinity,
            color: const Color(0xFFF3F4F6),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('图片加载失败: $error');
          return Container(
            height: 80, // 减少高度
            width: double.infinity,
            color: const Color(0xFFF3F4F6),
            child: const Icon(Icons.image_not_supported, size: 20), // 减小图标
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(4), // 减小圆角
      child: imageWidget,
    );
  }

  // 构建简单视频预览
  Widget _buildSimpleVideoPreview(String? filePath, String? fileUrl) {
          return Container(
      height: 80, // 减少高度
            width: double.infinity,
            decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4), // 减小圆角
              color: const Color(0xFF1F2937),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4), // 减小圆角
        child: _VideoGifPreview(
          videoPath: filePath,
          videoUrl: fileUrl,
              ),
            ),
          );
  }

  // 打开本地文件（简化版）
  Future<void> _openFile(String? filePath, String? fileUrl, String? fileType) async {
    try {
      String? pathToOpen;
      
      // 优先使用传入的本地路径
      if (filePath != null && File(filePath).existsSync()) {
        pathToOpen = filePath;
      } else if (fileUrl != null) {
        // 转换相对URL为绝对URL
        String fullUrl = fileUrl;
        if (fileUrl.startsWith('/api/')) {
          fullUrl = 'https://sendtomyself-api-adecumh2za-uc.a.run.app$fileUrl';
        }
        
        // 检查缓存中是否有文件
        if (_downloadedFiles.containsKey(fullUrl)) {
          final cachedPath = _downloadedFiles[fullUrl]!;
          if (File(cachedPath).existsSync()) {
            pathToOpen = cachedPath;
          }
        }
      }
      
      if (pathToOpen != null) {
        print('打开文件: $pathToOpen');
        final result = await OpenFilex.open(pathToOpen);
        print('文件打开结果: ${result.type}, ${result.message}');
        
        if (result.type != ResultType.done) {
          _showErrorMessage('无法打开文件: ${result.message}');
        }
      } else {
        _showErrorMessage('文件不存在或正在下载中，请稍后再试');
      }
    } catch (e) {
      print('打开文件失败: $e');
      _showErrorMessage('打开文件失败: $e');
    }
  }

  // 显示错误消息
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // 获取文件名
  String? _getFileName(String? filePath, String? fileUrl) {
    if (filePath != null) {
      return path.basename(filePath);
    }
    if (fileUrl != null) {
      return path.basename(fileUrl.split('?').first);
    }
    return null;
  }

  Widget _buildInputArea() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔥 文件预览区域
            if (_showFilePreview && _pendingFiles.isNotEmpty)
              _buildFilePreviewArea(),
            
            // 输入框区域
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  // 附件按钮
                  GestureDetector(
                    onTap: _showFileOptions,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 6),
                  
                  // 输入框
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: RawKeyboardListener(
                        focusNode: FocusNode(),
                        onKey: (RawKeyEvent event) {
                          if (!_isDesktop()) return;
                          
                          if (event is RawKeyDownEvent) {
                            final isEnterPressed = event.logicalKey == LogicalKeyboardKey.enter;
                            final isShiftPressed = event.isShiftPressed;
                            
                            if (isEnterPressed && !isShiftPressed) {
                              // 🔥 修改：发送带文件的消息
                              _sendMessageWithFiles();
                              return;
                            }
                          }
                        },
                        child: Focus(
                          onKey: (FocusNode node, RawKeyEvent event) {
                            if (_isDesktop() && event is RawKeyDownEvent) {
                              final isEnterPressed = event.logicalKey == LogicalKeyboardKey.enter;
                              final isShiftPressed = event.isShiftPressed;
                              
                              if (isEnterPressed && !isShiftPressed) {
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: _isDesktop() 
                                ? (_pendingFiles.isNotEmpty 
                                  ? '添加说明文字...(Enter发送)' 
                                  : '输入消息或拖拽文件...(Enter发送)')
                                : '输入消息或拖拽文件...',
                              hintStyle: AppTheme.bodyStyle.copyWith(
                                color: AppTheme.textTertiaryColor,
                                fontSize: _isDesktop() ? 13 : 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            style: AppTheme.bodyStyle,
                            maxLines: 4,
                            minLines: 1,
                            textInputAction: _isDesktop() ? TextInputAction.newline : TextInputAction.send,
                            onChanged: (text) {
                              setState(() {
                                _isTyping = text.trim().isNotEmpty || _pendingFiles.isNotEmpty;
                              });
                            },
                            onSubmitted: (text) {
                              if (!_isDesktop()) {
                                _sendMessageWithFiles();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 6),
                  
                  // 发送按钮
                  GestureDetector(
                    onTap: _sendMessageWithFiles,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _isTyping ? AppTheme.primaryColor : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.send,
                        size: 14,
                        color: _isTyping ? Colors.white : AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 新增：构建文件预览区域
  Widget _buildFilePreviewArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, size: 16, color: Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Text(
                    '待发送文件 (${_pendingFiles.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _pendingFiles.clear();
                        _showFilePreview = false;
                        _isTyping = _messageController.text.trim().isNotEmpty;
                      });
                    },
                    child: const Icon(Icons.close, size: 16, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            
            // 文件列表
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                itemCount: _pendingFiles.length,
                itemBuilder: (context, index) {
                  final fileInfo = _pendingFiles[index];
                  return _buildFilePreviewItem(fileInfo);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 新增：构建单个文件预览项
  Widget _buildFilePreviewItem(Map<String, dynamic> fileInfo) {
    final fileName = fileInfo['name'] as String;
    final fileSize = fileInfo['size'] as int;
    final fileType = fileInfo['type'] as String;
    final fileId = fileInfo['id'] as String;
    
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 文件预览/图标
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
                  ),
                  child: fileType == 'image' && fileInfo['thumbnail'] != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                        child: Image.memory(
                          fileInfo['thumbnail'] as Uint8List,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        _getFileTypeIcon(fileType),
                        size: 24,
                        color: const Color(0xFF6B7280),
                      ),
                ),
              ),
              
              // 文件信息
              Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatFileSize(fileSize),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // 删除按钮
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeFileFromPreview(fileId),
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildMessageStatusIcon(Map<String, dynamic> message) {
    final status = message['status'];
    final isTemporary = message['isTemporary'] == true;
    final uploadProgress = message['uploadProgress'] ?? 1.0;
    final downloadProgress = message['downloadProgress'];
    final hasFile = message['fileType'] != null;
    final isMe = message['isMe'] == true;
    
    if (isTemporary && status == 'sending') {
      return SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
        ),
      );
    } else if (status == 'uploading') {
      return SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
        ),
      );
    } else if (status == 'failed') {
      return Icon(
        Icons.error_outline,
        size: 10,
        color: Colors.red,
      );
    } else if (status == 'read') {
      return Icon(
        Icons.done_all,
        size: 10,
        color: Colors.green,
      );
    } else if (status == 'sent') {
      // 🔥 简化：统一使用简单的勾选图标，不区分文件类型
      // 遵循简洁、低调的设计原则
      if (hasFile) {
        // 文件消息：根据传输完成状态显示不同颜色的勾
        if ((isMe && uploadProgress >= 1.0) || (!isMe && downloadProgress == null)) {
          // 传输完成：绿色勾选
          return Icon(
            Icons.done,
            size: 10,
            color: Colors.green.withOpacity(0.8),
          );
        } else {
          // 传输中或未开始：普通勾选
          return Icon(
            Icons.done,
            size: 10,
            color: Colors.white.withOpacity(0.8),
          );
        }
      } else {
        // 普通文本消息：简单勾选
        return Icon(
          Icons.done,
          size: 10,
          color: Colors.white.withOpacity(0.8),
        );
      }
    }
    return const SizedBox();
  }

  // 自动下载文件（使用优化的缓存系统）
  Future<void> _autoDownloadFile(Map<String, dynamic> message) async {
    final fileUrl = message['fileUrl'];
    final fileName = message['fileName'];
    final fileSize = message['fileSize'];
    
    if (fileUrl == null || fileName == null) return;
    
    // 转换相对URL为绝对URL
    String fullUrl = fileUrl;
    if (fileUrl.startsWith('/api/')) {
      fullUrl = 'https://sendtomyself-api-adecumh2za-uc.a.run.app$fileUrl';
    }
    
    // 检查是否正在下载
    if (_downloadingFiles.contains(fullUrl)) {
      print('文件正在下载中，跳过: $fileName');
      return;
    }
    
    try {
      // 1. 检查内存缓存
      final memCachedPath = _getFromCache(fullUrl);
      if (memCachedPath != null && await File(memCachedPath).exists()) {
        print('从内存缓存找到文件: $fileName -> $memCachedPath');
        _updateMessageFilePath(message, memCachedPath);
        return;
      }
      
      // 2. 检查持久化缓存
      final persistentCachedPath = await _localStorage.getFileFromCache(fullUrl);
      if (persistentCachedPath != null && await File(persistentCachedPath).exists()) {
        print('从永久缓存找到文件: $fileName -> $persistentCachedPath');
        _addToCache(fullUrl, persistentCachedPath);
        _updateMessageFilePath(message, persistentCachedPath);
        return;
      }
      
      print('开始下载文件: $fileName (${fileSize ?? 'unknown'} bytes)');
      _downloadingFiles.add(fullUrl);
      
      // 🔥 新增：初始化下载进度跟踪
      final startTime = DateTime.now();
      var lastUpdateTime = startTime;
      var lastDownloadedBytes = 0;
      
      // 3. 带进度的文件下载
      final dio = Dio();
      final authService = DeviceAuthService();
      final token = await authService.getAuthToken();
      
      // 🔥 优化：为大文件下载配置更长的超时时间
      dio.options.connectTimeout = const Duration(seconds: 60);
      dio.options.receiveTimeout = const Duration(minutes: 15); // 大文件下载15分钟超时
      dio.options.sendTimeout = const Duration(minutes: 5);
      
      final response = await dio.get(
        fullUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
        onReceiveProgress: (receivedBytes, totalBytes) {
          // 🔥 新增：计算下载进度和速度
          if (totalBytes > 0 && mounted) {
            final progress = receivedBytes / totalBytes;
            final currentTime = DateTime.now();
            final timeDiff = currentTime.difference(lastUpdateTime).inMilliseconds;
            
            // 每500ms更新一次UI（避免过于频繁）
            if (timeDiff >= 500) {
              final bytesDiff = receivedBytes - lastDownloadedBytes;
              final speedBytesPerMs = bytesDiff / timeDiff;
              final speedKBps = speedBytesPerMs * 1000 / 1024; // 转换为KB/s
              
              // 计算预计剩余时间
              final remainingBytes = totalBytes - receivedBytes;
              final etaSeconds = speedKBps > 0 ? (remainingBytes / 1024 / speedKBps).round() : null;
              
              // 🔥 优化：大文件下载进度日志
              if (totalBytes > 50 * 1024 * 1024) { // 大于50MB的文件
                print('大文件下载进度: ${(progress * 100).toStringAsFixed(1)}% (${_formatFileSize(receivedBytes)}/${_formatFileSize(totalBytes)}) 速度: ${_formatTransferSpeed(speedKBps)}');
              }
              
              setState(() {
                final messageIndex = _messages.indexWhere((m) => m['id'] == message['id']);
                if (messageIndex != -1) {
                  _messages[messageIndex]['downloadProgress'] = progress;
                  _messages[messageIndex]['transferSpeed'] = speedKBps;
                  _messages[messageIndex]['eta'] = etaSeconds;
                }
              });
              
              lastUpdateTime = currentTime;
              lastDownloadedBytes = receivedBytes;
            }
          }
        },
      );
      
      if (response.statusCode == 200 && response.data != null) {
        // 🔥 新增：下载完成，清除进度信息
        setState(() {
          final messageIndex = _messages.indexWhere((m) => m['id'] == message['id']);
          if (messageIndex != -1) {
            _messages[messageIndex]['downloadProgress'] = null;
            _messages[messageIndex]['transferSpeed'] = 0.0;
            _messages[messageIndex]['eta'] = null;
          }
        });
        
        // 直接保存到永久存储
        final savedPath = await _localStorage.saveFileToCache(fullUrl, response.data as List<int>, fileName);
        
        if (savedPath != null) {
          print('文件下载并保存到永久存储完成: $fileName -> $savedPath');
          
          // 添加到内存缓存
          _addToCache(fullUrl, savedPath);
          
          // 更新消息文件路径
          _updateMessageFilePath(message, savedPath);
          
          // 保存消息更新
          await _saveMessages();
          
          // 🔥 移除：不再显示下载完成提示，保持界面简洁
          // 文件下载完成后直接显示，无需额外提示
        }
      } else {
        throw Exception('下载失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('文件下载失败: $fileName - $e');
      
      // 🔥 新增：下载失败处理
      if (mounted) {
        setState(() {
          final messageIndex = _messages.indexWhere((m) => m['id'] == message['id']);
          if (messageIndex != -1) {
            _messages[messageIndex]['downloadProgress'] = null;
            _messages[messageIndex]['transferSpeed'] = 0.0;
            _messages[messageIndex]['eta'] = null;
          }
        });
        
        // 🔥 优化：根据文件大小和错误类型提供更详细的错误提示
        String errorMessage = '文件下载失败';
        if (e.toString().contains('timeout')) {
          if (fileSize != null && fileSize > 50 * 1024 * 1024) {
            errorMessage = '大文件下载超时，请检查网络连接\n文件大小: ${_formatFileSize(fileSize)}\n建议在WiFi环境下重试';
          } else {
            errorMessage = '文件下载超时，请检查网络连接';
          }
        } else if (e.toString().contains('404')) {
          errorMessage = '文件不存在或已过期';
        } else if (e.toString().contains('403')) {
          errorMessage = '没有权限下载此文件';
        } else if (e.toString().contains('network')) {
          errorMessage = '网络连接错误，请检查网络设置';
        } else if (e.toString().contains('space') || e.toString().contains('storage')) {
          errorMessage = '设备存储空间不足，请清理空间后重试';
        } else {
          errorMessage = '文件下载失败: ${fileName}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5), // 增加显示时间
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '重试',
              textColor: Colors.white,
              onPressed: () => _autoDownloadFile(message),
            ),
          ),
        );
      }
    } finally {
      // 🔥 修复：确保下载完成后清除下载状态
      _downloadingFiles.remove(fullUrl);
      if (mounted) {
        setState(() {
          final messageIndex = _messages.indexWhere((m) => m['id'] == message['id']);
          if (messageIndex != -1) {
            _messages[messageIndex]['downloadProgress'] = null;
            _messages[messageIndex]['transferSpeed'] = 0.0;
            _messages[messageIndex]['eta'] = null;
          }
        });
      }
    }
  }
  
  // 更新消息中的文件路径
  void _updateMessageFilePath(Map<String, dynamic> message, String filePath) {
    setState(() {
      final messageIndex = _messages.indexWhere((m) => m['id'] == message['id']);
      if (messageIndex != -1) {
        _messages[messageIndex]['localFilePath'] = filePath;
      }
    });
  }

  // 时间戳标准化方法
  String _normalizeTimestamp(String timestamp) {
    try {
      // 解析时间戳，如果没有时区信息则当作UTC处理
      DateTime dateTime;
      if (timestamp.endsWith('Z') || timestamp.contains('+') || timestamp.contains('-', 10)) {
        // 已经包含时区信息
        dateTime = DateTime.parse(timestamp);
      } else {
        // 没有时区信息，当作UTC处理
        dateTime = DateTime.parse('${timestamp}Z');
      }
      
      // 统一返回UTC时间的ISO字符串
      return dateTime.toUtc().toIso8601String();
    } catch (e) {
      print('时间戳解析失败: $timestamp, 错误: $e');
      // 出错时返回当前UTC时间
      return DateTime.now().toUtc().toIso8601String();
    }
  }

  // 保存文件缓存映射
  Future<void> _saveFileCache(String url, String filePath) async {
    // 这个方法现在主要用于向后兼容
    _addToCache(url, filePath);
  }

  // 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // 获取文件类型颜色
  Color _getFileTypeColor(String? fileType) {
    switch (fileType) {
      case 'image':
        return const Color(0xFF10B981);
      case 'video':
        return const Color(0xFF3B82F6);
      case 'document':
        return const Color(0xFFF59E0B);
      case 'audio':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  // 获取文件类型显示名称
  String _getFileTypeDisplayName(String? fileType) {
    switch (fileType) {
      case 'image':
        return '图片文件';
      case 'video':
        return '视频文件';
      case 'document':
        return '文档文件';
      case 'audio':
        return '音频文件';
      default:
        return '文件';
    }
  }

  // 获取文件类型图标
  IconData _getFileTypeIcon(String? fileType) {
    switch (fileType) {
      case 'image':
        return Icons.image_rounded;
      case 'video':
        return Icons.videocam_rounded;
      case 'document':
        return Icons.description_rounded;
      case 'audio':
        return Icons.audiotrack_rounded;
      default:
        return Icons.attach_file_rounded;
    }
  }

  // 显示文件选择菜单 - 简洁设计
  void _showFileOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)), // 减小圆角
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6), // 减少间距
              width: 24, // 减小指示器
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 12), // 减少间距
            
            Text(
              _isDesktop() ? '选择文件类型' : '选择文件类型（多选直接发送）',
              style: AppTheme.bodyStyle.copyWith( // 使用更小的字体
                fontWeight: AppTheme.fontWeightMedium,
              ),
            ),
            
            const SizedBox(height: 12), // 减少间距
            
            // 简洁的文件选项列表
            _buildFileOption(Icons.image, '图片', () => _selectFile(FileType.image)),
            _buildFileOption(Icons.videocam, '视频', () => _selectFile(FileType.video)),
            _buildFileOption(Icons.description, '文档', () => _selectFile(FileType.any)),
            _buildFileOption(Icons.audiotrack, '音频', () => _selectFile(FileType.audio)),
            
            const SizedBox(height: 12), // 减少间距
          ],
        ),
      ),
    );
  }

  Widget _buildFileOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6B7280), size: 18), // 减小图标
      title: Text(
        title,
        style: AppTheme.bodyStyle.copyWith(fontSize: 12), // 减小字体
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // 减少内边距
    );
  }

  // 简化文件缓存加载
  Future<void> _loadFileCache() async {
    print('开始加载文件缓存映射...');
    
    try {
      final mapping = await _localStorage.getFileMapping();
      print('持久化映射总数: ${mapping.length}');
      
      int loadedCount = 0;
      for (final entry in mapping.entries) {
        final url = entry.key;
        final filePath = entry.value;
        
        if (loadedCount >= _maxCacheSize) break;
        
        if (await File(filePath).exists()) {
          _addToCache(url, filePath);
          loadedCount++;
        }
      }
      
      print('文件缓存加载完成，内存缓存: ${_downloadedFiles.length}个文件');
      
    } catch (e) {
      print('加载文件缓存失败: $e');
    }
  }

  // LRU缓存管理
  void _updateCacheAccess(String url) {
    _cacheAccessOrder.remove(url);
    _cacheAccessOrder.add(url);
    
    // 如果超过缓存大小限制，移除最老的缓存项
    while (_downloadedFiles.length > _maxCacheSize) {
      final oldestUrl = _cacheAccessOrder.removeAt(0);
      _downloadedFiles.remove(oldestUrl);
      print('移除过期缓存: $oldestUrl');
    }
  }
  
  void _addToCache(String url, String filePath) {
    _downloadedFiles[url] = filePath;
    _updateCacheAccess(url);
  }
  
  String? _getFromCache(String url) {
    final filePath = _downloadedFiles[url];
    if (filePath != null) {
      _updateCacheAccess(url);
      return filePath;
    }
    return null;
  }

  // 🔥 新增：去重诊断工具
  void _debugDuplicationState() {
    print('=== 去重诊断报告 ===');
    print('已处理消息ID数量: ${_processedMessageIds.length}');
    print('消息ID时间戳记录数量: ${_messageIdTimestamps.length}');
    print('当前界面消息数量: ${_messages.length}');
    
    final now = DateTime.now();
    int recentCount = 0;
    int oldCount = 0;
    
    _messageIdTimestamps.forEach((id, timestamp) {
      final age = now.difference(timestamp);
      if (age.inMinutes < 10) {
        recentCount++;
      } else if (age.inHours > 2) {
        oldCount++;
      }
    });
    
    print('最近10分钟处理的消息: $recentCount');
    print('超过2小时的旧消息ID: $oldCount');
    print('WebSocket连接状态: ${_websocketService.isConnected}');
    print('最后收到消息时间: $_lastMessageReceivedTime');
    
    if (_lastMessageReceivedTime != null) {
      final timeSinceLastMessage = now.difference(_lastMessageReceivedTime!);
      print('距离最后收到消息: ${timeSinceLastMessage.inMinutes}分钟');
      
      if (timeSinceLastMessage.inMinutes > 5) {
        print('⚠️ 警告：可能存在WebSocket同步问题');
      }
    }
    
    print('=== 诊断报告结束 ===');
  }
  
  // 🔥 新增：强制清理去重记录（诊断用）
  void _forceClearDuplicationRecords() {
    print('🧹 强制清理去重记录...');
    final oldSize = _processedMessageIds.length;
    
    _processedMessageIds.clear();
    _messageIdTimestamps.clear();
    
    print('已清理 $oldSize 个消息ID记录');
    
    // 重新启动WebSocket监听
    _chatMessageSubscription?.cancel();
    _subscribeToChatMessages();
    
    print('已重新启动WebSocket监听');
  }

  // 🔥 紧急诊断：实时WebSocket状态监控
  void _startEmergencyDiagnostics() {
    Timer.periodic(Duration(minutes: 5), (_) {
      if (mounted) {
        print('🔍 WebSocket状态诊断: 连接=${_websocketService.isConnected}, 最后收到消息=${_lastMessageReceivedTime}');
        
        // 如果长时间没收到消息，执行紧急恢复
      if (_lastMessageReceivedTime != null) {
        final timeSinceLastMessage = DateTime.now().difference(_lastMessageReceivedTime!);
          if (timeSinceLastMessage.inMinutes >= 10) {
            print('🚨 执行紧急WebSocket恢复');
          _emergencyWebSocketRecovery();
        }
        }
      }
    });
  }

  // 🔥 关键修复：监听EnhancedSyncManager的UI更新事件 - 增强版
  void _subscribeToSyncUIUpdates() {
    try {
      final enhancedSyncManager = Provider.of<EnhancedSyncManager>(context, listen: false);
      _syncUIUpdateSubscription = enhancedSyncManager.onUIUpdateRequired.listen((event) {
        if (mounted) {
          print('📢 收到同步UI更新事件: ${event.toString()}');
          
          switch (event.type) {
            case 'messages_updated':
            case 'sync_completed':
              _handleNormalSyncUpdate(event);
              break;
            case 'force_refresh_all':
            case 'force_global_refresh':
            case 'force_ui_refresh':
              _handleForceRefreshUpdate(event);
              break;
            default:
              _handleNormalSyncUpdate(event);
              break;
          }
        }
      });
      
      print('✅ 已订阅EnhancedSyncManager的UI更新事件');
    } catch (e) {
      print('❌ 订阅EnhancedSyncManager UI更新事件失败: $e');
    }
  }
  
  // 🔥 新增：处理普通同步更新
  void _handleNormalSyncUpdate(SyncUIUpdateEvent event) {
    final currentConversationId = widget.conversation['id'];
    final shouldRefresh = event.conversationId == null || 
                         event.conversationId == currentConversationId;
    
    if (shouldRefresh) {
      print('🔄 普通同步刷新: $currentConversationId');
      _refreshMessagesFromStorage();
      
      if (event.messageCount > 0) {
        _showSyncNotification(event);
    }
    }
  }
  
  // 🔥 新增：处理强制刷新更新
  void _handleForceRefreshUpdate(SyncUIUpdateEvent event) {
    print('🔄 强制全局刷新');
    _forceRefreshFromAllSources();
    
    if (event.messageCount > 0) {
      _showSyncNotification(event);
    }
  }
  
  // 🔥 关键修复：从本地存储刷新消息
  Future<void> _refreshMessagesFromStorage() async {
    try {
      print('🔄 从本地存储刷新消息...');
    
      final chatId = widget.conversation['id'];
      final refreshedMessages = await _localStorage.loadChatMessages(chatId);
      
      if (mounted && refreshedMessages.isNotEmpty) {
        // 检查是否有新消息
        final currentMessageIds = _messages.map((m) => m['id'].toString()).toSet();
        final refreshedMessageIds = refreshedMessages.map((m) => m['id'].toString()).toSet();
        final newMessageIds = refreshedMessageIds.difference(currentMessageIds);
        
        if (newMessageIds.isNotEmpty) {
          print('✅ 发现${newMessageIds.length}条新消息，更新UI');
          
          setState(() {
            _messages = refreshedMessages;
          });
          
          // 🔥 修复：移除刷新消息后的自动滚动，避免打断用户阅读
          // _scrollToBottom();
          
          // 为新的文件消息自动下载文件
          final newMessages = refreshedMessages.where((msg) => 
            newMessageIds.contains(msg['id'].toString())
          ).toList();
          
          for (final message in newMessages) {
            if (message['fileUrl'] != null && !message['isMe']) {
              _autoDownloadFile(message);
            }
          }
        } else {
          print('📄 没有发现新消息');
        }
      }
      } catch (e) {
      print('❌ 从本地存储刷新消息失败: $e');
      }
    }
    
  // 🔥 新增：强制从所有源刷新消息
  Future<void> _forceRefreshFromAllSources() async {
    print('🔄 强制从所有源刷新消息...');
    
    // 1. 清理过度累积的消息ID缓存
    if (_processedMessageIds.length > 100) {
      final oldSize = _processedMessageIds.length;
      _processedMessageIds.clear();
      _messageIdTimestamps.clear();
      print('🧹 清理了 $oldSize 个消息ID缓存');
    }
    
    // 2. 强制重新从本地存储加载（完全替换）
    try {
      final chatId = widget.conversation['id'];
      final allStoredMessages = await _localStorage.loadChatMessages(chatId);
      
      if (mounted) {
      setState(() {
          _messages.clear();
          _messages.addAll(allStoredMessages);
        _messages.sort((a, b) {
          try {
            final timeA = DateTime.parse(a['timestamp']);
            final timeB = DateTime.parse(b['timestamp']);
            return timeA.compareTo(timeB);
          } catch (e) {
            return 0;
          }
        });
      });
      
        print('✅ 强制重载了 ${allStoredMessages.length} 条消息');
        // 🔥 修复：移除强制刷新后的自动滚动，用户手动刷新时保持当前位置
        // _scrollToBottom();
      }
    } catch (e) {
      print('❌ 强制重载消息失败: $e');
    }
    
    // 3. 强制请求最新消息
    if (_websocketService.isConnected) {
      _websocketService.emit('get_recent_messages', {
        'conversationId': widget.conversation['id'],
        'limit': 50,
        'timestamp': DateTime.now().toIso8601String(),
        'reason': 'force_refresh'
      });
    }
    
    // 4. 重新订阅WebSocket
    _chatMessageSubscription?.cancel();
    _subscribeToChatMessages();
    
    print('✅ 强制刷新完成');
  }
  
  // 🔥 新增：显示同步通知
  void _showSyncNotification(SyncUIUpdateEvent event) {
    if (mounted && event.messageCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.sync, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('收到 ${event.messageCount} 条新消息'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green[600],
        ),
      );
        }
      }
      
  // 🔥 紧急WebSocket恢复
  void _emergencyWebSocketRecovery() {
    print('🚨 执行紧急WebSocket恢复...');
    
    // 1. 重新订阅消息流
    _chatMessageSubscription?.cancel();
    _subscribeToChatMessages();
    
    // 2. 强制刷新WebSocket状态
    _websocketService.refreshDeviceStatus();
    
    // 3. 手动请求最近消息
    _websocketService.emit('get_recent_messages', {
      'timestamp': DateTime.now().toIso8601String(),
      'reason': 'emergency_recovery',
      'limit': 20,
    });
    
    // 4. 清理部分旧的消息ID（防止过度累积）
    if (_processedMessageIds.length > 500) {
      print('🧹 清理过多的消息ID记录');
      final oldIds = _processedMessageIds.take(200).toList();
      _processedMessageIds.removeAll(oldIds);
      
      // 同时清理对应的时间戳
      oldIds.forEach((id) {
        _messageIdTimestamps.remove(id);
      });
    }
    
    print('✅ 紧急恢复完成');
    }
  


  // 显示消息操作菜单
  Future<void> _showMessageActionMenu(Map<String, dynamic> message, bool isOwnMessage) async {
    final messageId = message['id']?.toString() ?? '';
    final isFavorited = await _messageActionsService.isMessageFavorited(messageId);
    
    final action = await showMessageActionMenu(
      context: context,
      message: message,
      isOwnMessage: isOwnMessage,
      isFavorited: isFavorited,
    );
    
    if (action != null) {
      await _handleMessageAction(action, message);
    }
  }
  
  // 处理消息操作
  Future<void> _handleMessageAction(MessageAction action, Map<String, dynamic> message) async {
    final messageId = message['id']?.toString() ?? '';
    
    switch (action) {
      case MessageAction.copy:
        await _copyMessage(message);
        break;
      
      case MessageAction.revoke:
        await _revokeMessage(messageId);
        break;
      
      case MessageAction.delete:
        await _deleteMessage(messageId);
        break;
      
      case MessageAction.forward:
        _forwardMessage(message);
        break;
      
      case MessageAction.favorite:
        await _favoriteMessage(message);
        break;
      
      case MessageAction.unfavorite:
        await _unfavoriteMessage(messageId);
        break;
      
      case MessageAction.reply:
        _replyToMessage(message);
        break;
      
      case MessageAction.select:
        _enterMultiSelectMode(messageId);
        break;
      
      case MessageAction.saveToLocal:
        await _saveMessageToLocal(message);
        break;
    }
  }
  
  // 复制消息
  Future<void> _copyMessage(Map<String, dynamic> message) async {
    final text = message['text']?.toString() ?? '';
    if (text.isNotEmpty) {
      final success = await _messageActionsService.copyMessageText(text);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已复制到剪贴板')),
        );
      }
    }
  }
  
  // 🔥 新增：复制消息文字
  Future<void> _copyMessageText(Map<String, dynamic> message) async {
    final text = message['text']?.toString() ?? '';
    if (text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文字已复制到剪贴板')),
        );
      }
    }
  }

  // 🔥 新增：选择全部文字
  void _selectAllText(Map<String, dynamic> message) {
    // 这个方法可以触发文字选择，但在 SelectableText 中用户可以直接选择
    // 这里可以实现自动全选逻辑，或者显示提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('可以直接拖拽选择文字内容')),
      );
    }
  }

  // 🔥 新增：复制全部内容（文字+文件信息）
  Future<void> _copyAllContent(Map<String, dynamic> message) async {
    final text = message['text']?.toString() ?? '';
    final fileName = message['fileName']?.toString() ?? '';
    
    String fullContent = '';
    if (text.isNotEmpty) {
      fullContent += text;
    }
    if (fileName.isNotEmpty) {
      if (fullContent.isNotEmpty) fullContent += '\n';
      fullContent += '[文件] $fileName';
    }
    
    if (fullContent.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: fullContent));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('全部内容已复制到剪贴板')),
        );
      }
    }
  }
  
  // 撤回消息
  Future<void> _revokeMessage(String messageId) async {
    final confirmed = await _showConfirmDialog(
      title: '撤回消息',
      content: '确定要撤回这条消息吗？撤回后所有人都无法看到此消息。',
      confirmText: '撤回',
    );
    
    if (confirmed) {
      final result = await _messageActionsService.revokeMessage(messageId: messageId);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('消息已撤回')),
          );
          // 更新本地消息状态
          _updateMessageAfterRevoke(messageId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('撤回失败: ${result['error']}')),
          );
        }
      }
    }
  }
  
  // 删除消息
  Future<void> _deleteMessage(String messageId) async {
    final confirmed = await _showConfirmDialog(
      title: '删除消息',
      content: '确定要删除这条消息吗？删除后无法恢复。',
      confirmText: '删除',
      isDestructive: true,
    );
    
    if (confirmed) {
      final result = await _messageActionsService.deleteMessage(messageId: messageId);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('消息已删除')),
          );
          // 从本地消息列表中移除
          _removeMessageFromLocal(messageId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: ${result['error']}')),
          );
        }
      }
    }
  }
  
  // 转发消息
  void _forwardMessage(Map<String, dynamic> message) {
    final forwardText = _messageActionsService.formatMessageForForward(message);
    _messageController.text = forwardText;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('消息内容已添加到输入框')),
      );
    }
  }
  
  // 收藏消息
  Future<void> _favoriteMessage(Map<String, dynamic> message) async {
    final success = await _messageActionsService.favoriteMessage(message);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已添加到收藏')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('收藏失败')),
        );
      }
    }
  }
  
  // 取消收藏消息
  Future<void> _unfavoriteMessage(String messageId) async {
    final success = await _messageActionsService.unfavoriteMessage(messageId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已从收藏中移除')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('取消收藏失败')),
        );
      }
    }
  }
  
  // 回复消息
  void _replyToMessage(Map<String, dynamic> message) {
    final text = message['text']?.toString() ?? '';
    final fileName = message['fileName']?.toString() ?? '';
    
    String replyText = '';
    if (text.isNotEmpty) {
      replyText = '回复: $text\n\n';
    } else if (fileName.isNotEmpty) {
      replyText = '回复: [文件] $fileName\n\n';
    }
    
    _messageController.text = replyText;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('回复内容已添加到输入框')),
      );
    }
  }
  
  // 进入多选模式
  void _enterMultiSelectMode(String messageId) {
    _multiSelectController.enterMultiSelectMode();
    _multiSelectController.selectMessage(messageId);
  }

  // 保存消息到本地（移动端文件消息）
  Future<void> _saveMessageToLocal(Map<String, dynamic> message) async {
    final fileName = message['fileName']?.toString() ?? '';
    final fileUrl = message['fileUrl']?.toString();
    
    if (fileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('文件信息不完整')),
      );
      return;
    }
    
    // 检查是否是移动端
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
                    defaultTargetPlatform == TargetPlatform.iOS;
    
    if (!isMobile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('此功能仅在移动端可用')),
      );
      return;
    }
    
    // 🔥 修复：优先查找本地文件，如果不存在则先下载
    String? filePath = message['filePath']?.toString();
    
    // 检查本地文件是否存在
    if (filePath == null || !File(filePath).existsSync()) {
      // 尝试从缓存查找文件
      if (fileUrl != null) {
        String fullUrl = fileUrl;
        if (fileUrl.startsWith('/api/')) {
          fullUrl = 'https://sendtomyself-api-adecumh2za-uc.a.run.app$fileUrl';
        }
        
        // 检查内存缓存
        filePath = _getFromCache(fullUrl);
        if (filePath != null && File(filePath).existsSync()) {
          print('✅ 从内存缓存找到文件: $filePath');
        } else {
          // 检查持久化缓存
          filePath = await _localStorage.getFileFromCache(fullUrl);
          if (filePath != null && File(filePath).existsSync()) {
            print('✅ 从持久化缓存找到文件: $filePath');
            _addToCache(fullUrl, filePath);
          } else {
            // 文件不存在，先下载
            print('📥 文件不存在，开始下载: $fullUrl');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('文件不存在，正在下载...')),
            );
            
            try {
              filePath = await _downloadFileForSaving(fullUrl, fileName);
              if (filePath == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('文件下载失败，无法保存')),
                );
                return;
              }
              print('✅ 文件下载完成: $filePath');
            } catch (e) {
              print('❌ 文件下载失败: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('文件下载失败: $e')),
              );
              return;
            }
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件URL不存在，无法下载')),
        );
        return;
      }
    }
    
     try {
       // 根据文件类型判断保存方式
       final fileType = _getFileType(fileName);
       bool success = false;
       
       if (fileType == 'image' || fileType == 'video') {
         // 图片和视频保存到相册
         try {
           // 使用gal插件保存到系统相册
           if (fileType == 'image') {
             await Gal.putImage(filePath);
             print('✅ 图片已成功保存到系统相册: $fileName');
           } else if (fileType == 'video') {
             await Gal.putVideo(filePath);
             print('✅ 视频已成功保存到系统相册: $fileName');
           }
           success = true;
         } catch (galError) {
           print('❌ 保存到相册失败: $galError');
           // 备用方案：复制到文档目录
           try {
             final appDocDir = await getApplicationDocumentsDirectory();
             final saveDir = Directory('${appDocDir.path}/SavedMedia');
             if (!await saveDir.exists()) {
               await saveDir.create(recursive: true);
             }
             
             final timestamp = DateTime.now().millisecondsSinceEpoch;
             final extension = fileName.contains('.') ? fileName.split('.').last : '';
             final baseName = fileName.contains('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;
             final uniqueFileName = extension.isNotEmpty ? '${baseName}_$timestamp.$extension' : '${fileName}_$timestamp';
             
             final sourceFile = File(filePath);
             final targetPath = '${saveDir.path}/$uniqueFileName';
             await sourceFile.copy(targetPath);
             
             print('⚠️ 已保存到应用媒体目录（备用方案）: $targetPath');
             success = true;
           } catch (backupError) {
             print('❌ 备用方案也失败了: $backupError');
             success = false;
           }
         }
       } else {
         // 其他文件保存到文档目录
         try {
           final appDocDir = await getApplicationDocumentsDirectory();
           final saveDir = Directory('${appDocDir.path}/SavedFiles');
           if (!await saveDir.exists()) {
             await saveDir.create(recursive: true);
           }
           
           final timestamp = DateTime.now().millisecondsSinceEpoch;
           final extension = fileName.contains('.') ? fileName.split('.').last : '';
           final baseName = fileName.contains('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;
           final uniqueFileName = extension.isNotEmpty ? '${baseName}_$timestamp.$extension' : '${fileName}_$timestamp';
           
           final sourceFile = File(filePath);
           final targetPath = '${saveDir.path}/$uniqueFileName';
           await sourceFile.copy(targetPath);
           
           print('📁 文件已保存到文档目录: $targetPath');
           success = true;
         } catch (docError) {
           print('❌ 保存到文档目录失败: $docError');
           success = false;
         }
       }
       
       // 显示结果提示
       if (mounted) {
         if (success) {
           final location = (fileType == 'image' || fileType == 'video') ? '相册' : '文档';
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Row(
                 children: [
                   Icon(Icons.check_circle, color: Colors.white, size: 20),
                   const SizedBox(width: 8),
                   Text('已保存到$location'),
                 ],
               ),
               backgroundColor: Colors.green,
               duration: const Duration(seconds: 2),
             ),
           );
         } else {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Row(
                 children: [
                   Icon(Icons.error, color: Colors.white, size: 20),
                   SizedBox(width: 8),
                   Text('保存失败'),
                 ],
               ),
               backgroundColor: Colors.red,
               duration: Duration(seconds: 2),
             ),
           );
         }
       }
     } catch (e) {
      print('保存文件到本地失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // 显示确认对话框
  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive 
              ? TextButton.styleFrom(foregroundColor: AppTheme.errorColor)
              : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  
  // 撤回后更新消息状态
  void _updateMessageAfterRevoke(String messageId) {
    setState(() {
      final messageIndex = _messages.indexWhere((msg) => msg['id'].toString() == messageId);
      if (messageIndex != -1) {
        _messages[messageIndex]['text'] = '[此消息已被撤回]';
        _messages[messageIndex]['isRevoked'] = true;
      }
    });
    _saveMessages();
  }
  
  // 从本地移除消息
  void _removeMessageFromLocal(String messageId) {
    setState(() {
      _messages.removeWhere((msg) => msg['id'].toString() == messageId);
    });
    _saveMessages();
  }

  // 🔥 新增：构建文件右键菜单（桌面端）
  Widget _buildFileContextMenu(String? filePath, String? fileUrl, String? fileType) {
    return GenericContextMenu(
      buttonConfigs: [
        ContextMenuButtonConfig(
          "打开文件",
          onPressed: () => _openFile(filePath, fileUrl, fileType),
        ),
        if (filePath != null && File(filePath).existsSync()) ...[
          ContextMenuButtonConfig(
            "打开文件位置",
            onPressed: () => _openFileLocation(filePath),
          ),
          ContextMenuButtonConfig(
            "复制文件路径",
            onPressed: () => _copyFilePath(filePath),
          ),
        ],
        if (fileUrl != null) ...[
          ContextMenuButtonConfig(
            "复制文件链接",
            onPressed: () => _copyFileUrl(fileUrl),
          ),
        ],
      ],
    );
  }

  // 🔥 新增：打开文件位置
  Future<void> _openFileLocation(String filePath) async {
    try {
      if (_isDesktop()) {
        // 桌面端使用系统命令打开文件夹
        if (Platform.isMacOS) {
          await Process.run('open', ['-R', filePath]);
        } else if (Platform.isWindows) {
          await Process.run('explorer', ['/select,', filePath.replaceAll('/', '\\')]);
        } else if (Platform.isLinux) {
          // Linux上尝试使用文件管理器
          try {
            await Process.run('xdg-open', [path.dirname(filePath)]);
          } catch (e) {
            // 备选方案
            await Process.run('nautilus', [path.dirname(filePath)]);
          }
        }
        print('已打开文件位置: ${path.dirname(filePath)}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已打开文件位置')),
          );
        }
      }
    } catch (e) {
      print('打开文件位置失败: $e');
      _showErrorMessage('无法打开文件位置');
    }
  }

  // 🔥 新增：复制文件路径
  Future<void> _copyFilePath(String filePath) async {
    try {
      await Clipboard.setData(ClipboardData(text: filePath));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件路径已复制到剪贴板')),
        );
      }
    } catch (e) {
      print('复制文件路径失败: $e');
      _showErrorMessage('复制文件路径失败');
    }
  }

  // 🔥 新增：复制文件URL
  Future<void> _copyFileUrl(String fileUrl) async {
    try {
      String fullUrl = fileUrl;
      if (fileUrl.startsWith('/api/')) {
        fullUrl = 'https://sendtomyself-api-adecumh2za-uc.a.run.app$fileUrl';
      }
      await Clipboard.setData(ClipboardData(text: fullUrl));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件链接已复制到剪贴板')),
        );
      }
    } catch (e) {
      print('复制文件链接失败: $e');
      _showErrorMessage('复制文件链接失败');
    }
  }

  // 🔥 新增：为保存功能下载文件
  Future<String?> _downloadFileForSaving(String url, String fileName) async {
    try {
      // 创建临时消息对象进行下载
      final tempMessage = {
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'fileUrl': url,
        'fileName': fileName,
      };
      
      // 下载前检查缓存
      final cachedPath = await _localStorage.getFileFromCache(url);
      if (cachedPath != null && File(cachedPath).existsSync()) {
        return cachedPath;
      }
      
      // 使用自动下载逻辑
      await _autoDownloadFile(tempMessage);
      
      // 再次检查是否下载成功
      final downloadedPath = await _localStorage.getFileFromCache(url);
      return downloadedPath;
    } catch (e) {
      print('下载文件失败: $e');
      return null;
    }
  }

  // 🔥 新增：上拉刷新相关状态
  // 移除_isPullToRefreshActive变量，简化下拉刷新UI
  bool _isRefreshing = false; // 是否正在刷新
  double _refreshTriggerOffset = 80.0; // 触发刷新的拖拽距离
  double _currentPullOffset = 0.0; // 当前拖拽偏移
  bool _isAtBottom = false; // 是否在底部
  
  // 🔥 新增：滚动监听器设置
  void _setupScrollListener() {
    _scrollController.addListener(() {
      // 检测是否在底部（允许50px的容差）
      final isAtBottomNow = _scrollController.hasClients &&
          _scrollController.position.pixels >= 
          (_scrollController.position.maxScrollExtent - 50);
      
      if (_isAtBottom != isAtBottomNow) {
        setState(() {
          _isAtBottom = isAtBottomNow;
        });
      }
    });
  }
  
  // 🔥 新增：处理滚动通知 - 简化版本
  bool _handleScrollNotification(ScrollNotification notification) {
    // 简化滚动通知处理，无需额外状态管理
    return false;
  }
  
  // 🔥 简化：处理手势拖拽更新
  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isAtBottom || _isRefreshing) return;
    
    // 只处理向上拖拽（下拉刷新）
    if (details.delta.dy < 0) {
      _currentPullOffset = (_currentPullOffset - details.delta.dy).clamp(0.0, _refreshTriggerOffset * 2);
    }
  }
  
  // 🔥 简化：处理手势拖拽结束 - 直接触发刷新
  void _handlePanEnd(DragEndDetails details) {
    if (!_isAtBottom || _isRefreshing) return;
    
    // 如果拖拽距离超过触发阈值，直接执行刷新
    if (_currentPullOffset >= _refreshTriggerOffset) {
      _triggerPullToRefresh();
    }
    
    // 重置拖拽状态
    _currentPullOffset = 0.0;
  }
  
  // 🔥 简化：触发下拉刷新 - 直接开始刷新
  Future<void> _triggerPullToRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      print('🔄 用户触发下拉刷新...');
      
      // 重新获取服务器消息（模拟首次登录的加载逻辑）
      await _performPullToRefreshSync();
      
      // 显示成功反馈
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 消息已刷新'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      print('❌ 下拉刷新失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新失败: $e'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 延迟重置状态，让用户看到完成动画
      await Future.delayed(Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
  
  // 🔥 新增：执行上拉刷新同步
  Future<void> _performPullToRefreshSync() async {
    try {
      // 1. 强制重新从服务器获取消息
      if (widget.conversation['type'] == 'group') {
        final groupId = widget.conversation['groupData']?['id'];
        if (groupId != null) {
          final result = await _chatService.getGroupMessages(groupId: groupId, limit: 100);
          if (result['messages'] != null) {
            await _processServerMessages(List<Map<String, dynamic>>.from(result['messages']));
          }
        }
      } else {
        final deviceId = widget.conversation['deviceData']?['id'];
        if (deviceId != null) {
          final result = await _chatService.getPrivateMessages(targetDeviceId: deviceId, limit: 100);
          if (result['messages'] != null) {
            await _processServerMessages(List<Map<String, dynamic>>.from(result['messages']));
          }
        }
      }
      
      // 2. 触发WebSocket同步
      if (_websocketService.isConnected) {
        _websocketService.emit('get_recent_messages', {
          'conversationId': widget.conversation['id'],
          'limit': 100,
          'timestamp': DateTime.now().toIso8601String(),
          'reason': 'pull_to_refresh'
        });
      }
      
      // 3. 强制刷新本地存储的消息
      await _refreshMessagesFromStorage();
      
      print('✅ 上拉刷新同步完成');
      
    } catch (e) {
      print('❌ 上拉刷新同步失败: $e');
      rethrow;
    }
  }
  
  // 🔥 新增：处理服务器消息
  Future<void> _processServerMessages(List<Map<String, dynamic>> serverMessages) async {
    if (serverMessages.isEmpty) return;
    
    // 获取当前设备ID用于过滤
    final prefs = await SharedPreferences.getInstance();
    final serverDeviceData = prefs.getString('server_device_data');
    String? currentDeviceId;
    if (serverDeviceData != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(serverDeviceData);
        currentDeviceId = data['id'];
      } catch (e) {
        print('解析设备ID失败: $e');
      }
    }
    
    // 转换和过滤服务器消息
    List<Map<String, dynamic>> newMessages = [];
    final existingMessageIds = _messages.map((m) => m['id'].toString()).toSet();
    
    for (final serverMessage in serverMessages) {
      final messageId = serverMessage['id']?.toString();
      if (messageId == null || existingMessageIds.contains(messageId)) {
        continue; // 跳过重复消息
      }
      
      // 过滤本机发送的消息（避免重复显示）
      final sourceDeviceId = serverMessage['sourceDeviceId']?.toString();
      if (sourceDeviceId == currentDeviceId) {
        continue;
      }
      
      // 转换消息格式
      final convertedMessage = {
        'id': messageId,
        'text': serverMessage['content'] ?? serverMessage['text'],
        'fileType': serverMessage['fileName'] != null ? _getFileType(serverMessage['fileName']) : null,
        'fileName': serverMessage['fileName'],
        'fileUrl': serverMessage['fileUrl'],
        'fileSize': serverMessage['fileSize'],
        'timestamp': _normalizeTimestamp(serverMessage['createdAt'] ?? serverMessage['timestamp'] ?? DateTime.now().toUtc().toIso8601String()),
        'isMe': false,
        'status': 'sent',
        'sourceDeviceId': sourceDeviceId,
      };
      
      newMessages.add(convertedMessage);
    }
    
    // 更新UI
    if (newMessages.isNotEmpty && mounted) {
      setState(() {
        _messages.addAll(newMessages);
        _messages.sort((a, b) {
          try {
            final timeA = DateTime.parse(a['timestamp']);
            final timeB = DateTime.parse(b['timestamp']);
            return timeA.compareTo(timeB);
          } catch (e) {
            return 0;
          }
        });
      });
      
      // 保存到本地
      await _saveMessages();
      
      print('✅ 上拉刷新新增 ${newMessages.length} 条消息');
    }
  }
  
  // 🔥 新增：构建简洁的下拉刷新指示器
  Widget _buildPullToRefreshIndicator() {
    // 只在刷新时显示，使用简洁的圆形加载指示器
    if (!_isRefreshing) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

// 视频静态缩略图预览组件
class _VideoGifPreview extends StatefulWidget {
  final String? videoPath;
  final String? videoUrl;

  const _VideoGifPreview({
    super.key,
    this.videoPath,
    this.videoUrl,
  });

  @override
  State<_VideoGifPreview> createState() => _VideoGifPreviewState();
}

class _VideoGifPreviewState extends State<_VideoGifPreview> {
  Uint8List? _thumbnailData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _generateVideoThumbnail();
  }

  /// 桌面端智能缩略图生成 - 优先尝试第三方工具，备用美观预览
  Future<Uint8List?> _generateDesktopThumbnail(String videoPath) async {
    try {
      print('🔄 桌面端开始智能缩略图生成: $videoPath');
      
      // 策略1：尝试使用系统的快速查看功能（macOS/Windows）
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        try {
          print('🍎 尝试使用macOS qlmanage生成缩略图');
          final result = await Process.run('qlmanage', [
            '-t',
            '-s',
            '400',
            '-o',
            Directory.systemTemp.path,
            videoPath
          ]);
          
          if (result.exitCode == 0) {
            // 🔥 修复：qlmanage生成的文件名保留完整原文件名
            final originalFileName = videoPath.split('/').last;
            final thumbnailPath = '${Directory.systemTemp.path}/$originalFileName.png';
            final thumbnailFile = File(thumbnailPath);
            
            if (await thumbnailFile.exists()) {
              final thumbnailBytes = await thumbnailFile.readAsBytes();
              print('✅ macOS qlmanage缩略图生成成功! 大小: ${thumbnailBytes.length} bytes');
              
              // 清理临时文件
              try {
                await thumbnailFile.delete();
              } catch (e) {
                print('⚠️ 清理qlmanage临时文件失败: $e');
              }
              
              return thumbnailBytes;
            }
          }
        } catch (e) {
          print('⚠️ macOS qlmanage失败: $e');
        }
      }
      
      // 策略2：Windows缩略图生成
      if (defaultTargetPlatform == TargetPlatform.windows) {
        try {
          print('🪟 尝试使用Windows PowerShell生成缩略图');
          // Windows PowerShell可以生成缩略图
          final tempPath = '${Directory.systemTemp.path}\\video_thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final psScript = '''
Add-Type -AssemblyName System.Drawing
\$video = [System.Drawing.Image]::FromFile("$videoPath")
\$thumb = \$video.GetThumbnailImage(400, 300, \$null, [IntPtr]::Zero)
\$thumb.Save("$tempPath", [System.Drawing.Imaging.ImageFormat]::Jpeg)
\$video.Dispose()
\$thumb.Dispose()
''';
          
          final result = await Process.run('powershell', ['-Command', psScript]);
          
          if (result.exitCode == 0) {
            final thumbnailFile = File(tempPath);
            if (await thumbnailFile.exists()) {
              final thumbnailBytes = await thumbnailFile.readAsBytes();
              print('✅ Windows PowerShell缩略图生成成功! 大小: ${thumbnailBytes.length} bytes');
              
              try {
                await thumbnailFile.delete();
              } catch (e) {
                print('⚠️ 清理Windows临时文件失败: $e');
              }
              
              return thumbnailBytes;
            }
          }
        } catch (e) {
          print('⚠️ Windows PowerShell失败: $e');
        }
      }
      
      // 策略3：Linux使用ffmpegthumbnailer（如果可用）
      if (defaultTargetPlatform == TargetPlatform.linux) {
        try {
          print('🐧 尝试使用Linux ffmpegthumbnailer生成缩略图');
          final tempPath = '${Directory.systemTemp.path}/video_thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
          
          final result = await Process.run('ffmpegthumbnailer', [
            '-i', videoPath,
            '-o', tempPath,
            '-s', '400',
            '-t', '10%'
          ]);
          
          if (result.exitCode == 0) {
            final thumbnailFile = File(tempPath);
            if (await thumbnailFile.exists()) {
              final thumbnailBytes = await thumbnailFile.readAsBytes();
              print('✅ Linux ffmpegthumbnailer缩略图生成成功! 大小: ${thumbnailBytes.length} bytes');
              
              try {
                await thumbnailFile.delete();
              } catch (e) {
                print('⚠️ 清理Linux临时文件失败: $e');
              }
              
              return thumbnailBytes;
            }
          }
        } catch (e) {
          print('⚠️ Linux ffmpegthumbnailer失败: $e');
        }
      }
      
      print('💡 所有系统级缩略图工具都不可用，使用备用方案');
      return null;
      
    } catch (e) {
      print('❌ 桌面端缩略图生成异常: $e');
      return null;
    }
  }

  Future<void> _generateVideoThumbnail() async {
    print('🎬 === 开始视频缩略图生成 ===');
    print('📍 videoPath: ${widget.videoPath}');
    print('📍 videoUrl: ${widget.videoUrl}');
    print('📍 平台: ${defaultTargetPlatform}');
    
    if (widget.videoPath == null && widget.videoUrl == null) {
      print('❌ 无视频源，跳过生成');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }
    
    try {
      Uint8List? thumbnailData;
      final isDesktop = defaultTargetPlatform == TargetPlatform.macOS || 
                       defaultTargetPlatform == TargetPlatform.windows || 
                       defaultTargetPlatform == TargetPlatform.linux;
      
      print('🖥️ 是否桌面端: $isDesktop');
      
      if (isDesktop) {
        print('🖥️ 桌面端使用VideoPlayer生成视频缩略图');
        
        // 桌面端使用VideoPlayer
        String? videoSource = widget.videoPath ?? widget.videoUrl;
        if (videoSource == null) {
          throw Exception('桌面端无有效视频源');
        }
        
        // 验证本地文件
        if (widget.videoPath != null) {
          try {
            final localFile = File(widget.videoPath!);
            final exists = await localFile.exists();
            print('📁 桌面端本地文件检查: ${widget.videoPath}');
            print('📁 文件存在: $exists');
            
            if (exists) {
              final fileSize = await localFile.length();
              print('📁 文件大小: $fileSize bytes');
              
              if (fileSize > 0) {
                print('🔄 桌面端使用VideoPlayer生成本地文件缩略图...');
                
                try {
                  // 使用桌面端智能缩略图生成
                  thumbnailData = await _generateDesktopThumbnail(widget.videoPath!);
                  
                  if (thumbnailData != null && thumbnailData.isNotEmpty) {
                    print('✅ 桌面端VideoPlayer缩略图生成成功! 大小: ${thumbnailData.length} bytes');
                  }
                } catch (e) {
                  print('❌ 桌面端VideoPlayer缩略图生成失败: $e');
                }
              }
            }
          } catch (e) {
            print('❌ 桌面端文件检查失败: $e');
          }
        }
        
        // 桌面端如果本地文件失败，暂时不尝试网络URL
        final success = thumbnailData != null && thumbnailData.isNotEmpty;
        print('🎯 === 桌面端缩略图生成结果: ${success ? "成功" : "失败"} ===');
        
        if (mounted) {
          setState(() {
            _thumbnailData = thumbnailData;
            _isLoading = false;
            _hasError = !success;
          });
        }
        return;
      }
      
      // 移动端使用video_thumbnail插件
      print('📱 移动端使用video_thumbnail插件生成缩略图');
      
      String? videoSource = widget.videoPath ?? widget.videoUrl;
      if (videoSource == null) {
        throw Exception('移动端无有效视频源');
      }
      
      // 检查本地文件
      if (widget.videoPath != null) {
        try {
          final localFile = File(widget.videoPath!);
          final exists = await localFile.exists();
          print('📁 移动端本地文件检查: ${widget.videoPath}');
          print('📁 文件存在: $exists');
          
          if (exists) {
            final fileSize = await localFile.length();
            print('📁 文件大小: $fileSize bytes');
            
            if (fileSize > 0) {
              print('🔄 移动端使用本地文件生成缩略图...');
              
              try {
                thumbnailData = await VideoThumbnail.thumbnailData(
                  video: widget.videoPath!,
                  imageFormat: ImageFormat.JPEG,
                  timeMs: 1000,
                  maxWidth: 400,
                  maxHeight: 300,
                  quality: 85,
                ).timeout(const Duration(seconds: 15));
                
                if (thumbnailData != null && thumbnailData.isNotEmpty) {
                  print('✅ 移动端本地文件缩略图生成成功! 大小: ${thumbnailData.length} bytes');
                }
              } catch (e) {
                print('❌ 移动端本地文件缩略图生成失败: $e');
                
                // 尝试第一帧
                try {
                  thumbnailData = await VideoThumbnail.thumbnailData(
                    video: widget.videoPath!,
                    imageFormat: ImageFormat.JPEG,
                    timeMs: 0,
                    maxWidth: 300,
                    maxHeight: 200,
                    quality: 75,
                  ).timeout(const Duration(seconds: 10));
                  
                  if (thumbnailData != null && thumbnailData.isNotEmpty) {
                    print('✅ 移动端第一帧缩略图生成成功! 大小: ${thumbnailData.length} bytes');
                  }
                } catch (e2) {
                  print('❌ 移动端第一帧缩略图也失败: $e2');
                }
              }
            }
          }
        } catch (e) {
          print('❌ 移动端本地文件检查失败: $e');
        }
      }
      
      // 如果本地失败，尝试网络URL
      if ((thumbnailData == null || thumbnailData.isEmpty) && widget.videoUrl != null) {
        print('🔄 移动端尝试使用网络URL生成缩略图: ${widget.videoUrl}');
        
        try {
          thumbnailData = await VideoThumbnail.thumbnailData(
            video: widget.videoUrl!,
            imageFormat: ImageFormat.JPEG,
            timeMs: 0,
            maxWidth: 300,
            maxHeight: 200,
            quality: 70,
          ).timeout(const Duration(seconds: 15));
          
          if (thumbnailData != null && thumbnailData.isNotEmpty) {
            print('✅ 移动端网络URL缩略图生成成功! 大小: ${thumbnailData.length} bytes');
          }
        } catch (e) {
          print('❌ 移动端网络URL缩略图生成失败: $e');
        }
      }
      
      final success = thumbnailData != null && thumbnailData.isNotEmpty;
      print('🎯 === 移动端缩略图生成结果: ${success ? "成功" : "失败"} ===');
      
      if (mounted) {
        setState(() {
          _thumbnailData = thumbnailData;
          _isLoading = false;
          _hasError = !success;
        });
      }
    } catch (e) {
      print('❌ === 视频缩略图生成完全失败: $e ===');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: const Color(0xFF1F2937),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }
    
    // 有真实缩略图数据时显示（移动端）
    if (_thumbnailData != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // 高清缩略图
          Image.memory(
            _thumbnailData!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 100,
          ),
          
          // 播放按钮覆盖层
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ],
      );
    }
    
    // 桌面端或无缩略图但不是错误状态时显示默认预览
    if (!_hasError) {
      return _buildDefaultVideoPreview();
    }
    
    // 真正的错误状态
    return _buildErrorWidget();
  }
  
  Widget _buildDefaultVideoPreview() {
    final isDesktop = defaultTargetPlatform == TargetPlatform.macOS || 
                     defaultTargetPlatform == TargetPlatform.windows || 
                     defaultTargetPlatform == TargetPlatform.linux;
                     
    return Container(
      color: const Color(0xFF2D3748),
      child: Stack(
        children: [
          // 背景渐变
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4A5568),
                  const Color(0xFF2D3748),
                ],
              ),
            ),
          ),
          
          // 中心视频图标和播放按钮
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 视频图标
                Icon(
                  Icons.videocam,
                  color: Colors.white70,
                  size: 40,
                ),
                const SizedBox(height: 8),
                
                // 播放按钮
                Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 36,
                ),
                
                if (isDesktop) ...[
                  const SizedBox(height: 4),
                  Text(
                    '桌面端视频',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: const Color(0xFF374151),
      child: const Center(
        child: Icon(
          Icons.videocam_off,
          color: Colors.white54,
          size: 32,
        ),
      ),
    );
  }
}