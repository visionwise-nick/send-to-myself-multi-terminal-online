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
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:open_filex/open_filex.dart';
import 'dart:math' as math;
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../services/device_auth_service.dart';

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
  
  // 消息处理相关
  final Set<String> _processedMessageIds = <String>{}; // 防止重复处理
  bool _isInitialLoad = true;
  
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

  // 判断是否为桌面端
  bool _isDesktop() {
    if (kIsWeb) {
      return MediaQuery.of(context).size.width >= 800;
    }
    return defaultTargetPlatform == TargetPlatform.macOS ||
           defaultTargetPlatform == TargetPlatform.windows ||
           defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _messageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _initializeDio();
    _loadFileCache();
    _loadMessages();
    _subscribeToChatMessages();
    
    // 🔥 关键修复：启动消息ID清理定时器
    _startMessageIdCleanup();
    
    // 🔥 新增：启动连接健康检查
    _startConnectionHealthCheck();
    
    // 启动时进行文件迁移
    _migrateOldFilesOnStartup();
    
    // 🔥 紧急诊断：实时WebSocket状态监控
    _startEmergencyDiagnostics();
  }
  
  // 启动时迁移旧文件到永久存储
  Future<void> _migrateOldFilesOnStartup() async {
    try {
      // 输出永久存储目录路径
      final permanentPath = await _localStorage.getPermanentStoragePath();
      print('=== 永久存储目录: $permanentPath ===');
      
      await _localStorage.migrateOldFiles();
      print('启动时文件迁移完成');
    } catch (e) {
      print('启动时文件迁移失败: $e');
    }
  }

  // 初始化Dio配置，添加认证头
  void _initializeDio() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    
    _dio.options.headers['Content-Type'] = 'application/json';
    // 🔥 优化：增加大文件传输的超时时间
    _dio.options.connectTimeout = const Duration(seconds: 60); // 连接超时60秒
    _dio.options.receiveTimeout = const Duration(minutes: 10); // 接收超时10分钟，支持大文件
    _dio.options.sendTimeout = const Duration(minutes: 10); // 发送超时10分钟，支持大文件上传
    
    // 添加拦截器来确保每次请求都有最新的token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final currentPrefs = await SharedPreferences.getInstance();
        final currentToken = currentPrefs.getString('auth_token');
        if (currentToken != null) {
          options.headers['Authorization'] = 'Bearer $currentToken';
        }
        handler.next(options);
      },
      // 🔥 新增：添加响应拦截器，处理大文件下载的特殊情况
      onResponse: (response, handler) {
        // 记录大文件下载信息
        if (response.data is List<int> && (response.data as List<int>).length > 10 * 1024 * 1024) {
          print('大文件下载完成: ${(response.data as List<int>).length / (1024 * 1024)} MB');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        // 🔥 优化：大文件传输错误处理
        if (error.type == DioExceptionType.receiveTimeout) {
          print('大文件下载超时，建议检查网络连接');
        } else if (error.type == DioExceptionType.sendTimeout) {
          print('大文件上传超时，建议检查网络连接');
        }
        handler.next(error);
      },
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _messageAnimationController.dispose();
    _chatMessageSubscription?.cancel();
    
    // 🔥 关键修复：清理新增的定时器
    _messageIdCleanupTimer?.cancel();
    _connectionHealthTimer?.cancel();
    
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
  }
  
  // 🔥 新增：尝试WebSocket恢复
  void _attemptWebSocketRecovery() {
    print('🔄 尝试恢复WebSocket连接...');
    
    // 重新订阅消息
    _chatMessageSubscription?.cancel();
    _subscribeToChatMessages();
    
    // 通知WebSocket服务进行健康检查
    if (!_websocketService.isConnected) {
      print('🔄 WebSocket未连接，尝试重连...');
      _websocketService.connect().catchError((e) {
        print('WebSocket重连失败: $e');
      });
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

    // 🔥 关键修复：检查消息是否已处理，如果已处理则直接返回
    if (_processedMessageIds.contains(messageId)) {
      print('消息已处理过，跳过: $messageId');
      return; // 防止重复处理
    }
    
    // 🔥 关键修复：立即标记消息已处理并记录时间戳（只标记一次）
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
    
    // 如果是文件消息，记录日志即可
    if (isFileMessage && fileName != null) {
      print('接收文件消息: $fileName, 大小: ${fileSize ?? 0} bytes, ID: $messageId');
    } else if (!isFileMessage && content != null && content.trim().isNotEmpty) {
      // 如果是文本消息，进行基于内容的去重检查
      final sourceDeviceId = message['sourceDeviceId'];
      final messageTime = DateTime.tryParse(message['createdAt'] ?? '') ?? DateTime.now();
      
      // 检查是否已有相同内容和发送者的消息
      final duplicateTextMessage = _messages.any((existingMsg) {
        if (existingMsg['fileType'] != null) return false; // 不是文本消息
        if (existingMsg['text'] != content) return false; // 内容不同
        if (existingMsg['sourceDeviceId'] != sourceDeviceId) return false; // 发送者不同
        
        // 检查时间窗口（5秒内认为是重复）
        try {
          final existingTime = DateTime.parse(existingMsg['timestamp']);
          final timeDiff = (messageTime.millisecondsSinceEpoch - existingTime.millisecondsSinceEpoch).abs();
          return timeDiff < 5000; // 5秒内
        } catch (e) {
          print('文本消息时间比较失败: $e');
          return false; // 时间解析失败时不认为重复
        }
      });
    
      if (duplicateTextMessage) {
        print('发现重复文本消息（相同内容+发送者+5秒窗口），跳过添加: $content');
        // 🔥 关键修复：重复文本消息不需要移除ID标记，因为已经在开头标记了
        return;
      }
    }

    // 🔥 重要修复：移除重复的标记代码，避免重复添加到_processedMessageIds
    // 消息ID已经在方法开始时标记过了
    
    // 添加消息到界面
    _addMessageToChat(message, false);
    
    // 发送已接收回执（只发送一次）
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

        // 滚动到底部
        _scrollToBottom();
        
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
      // 优先从本地快速加载
      await _loadLocalMessages();
      
      // 注意：不要将本地消息ID添加到_processedMessageIds中
      // _processedMessageIds只用于防止实时WebSocket消息的重复处理
      // 本地消息同步应该通过直接对比消息ID来判断
      print('本地消息加载完成，不添加到_processedMessageIds以避免阻止同步');
      
      setState(() {
        _isLoading = false;
        _isInitialLoad = false; // 标记初始加载完成
      });
      
      print('本地消息加载完成: ${_messages.length}条');
      _scrollToBottom();

      // 后台同步最新消息（非阻塞）
      _syncLatestMessages();
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

      // 转换API消息格式为本地格式
      final List<Map<String, dynamic>> convertedMessages = apiMessages.map((msg) {
        final isMe = msg['sourceDeviceId'] == currentDeviceId;
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

      // 修复的去重逻辑：主要基于本地消息ID检查，而不是_processedMessageIds
      final List<Map<String, dynamic>> newMessages = [];
      
      for (final serverMsg in convertedMessages) {
        final serverId = serverMsg['id'].toString();
        
        // 首先检查是否已经存在相同ID的本地消息
        final existsById = _messages.any((localMsg) => localMsg['id'].toString() == serverId);
        if (existsById) {
          print('消息ID已存在于本地，跳过同步: $serverId');
          continue;
        }
        
        // 检查WebSocket实时消息去重（防止实时消息重复）
        if (_processedMessageIds.contains(serverId)) {
          print('消息ID在实时处理中已存在，跳过: $serverId');
          continue;
        }
            
        // 如果是文件消息，进行额外的文件去重检查
        if (serverMsg['fileType'] != null && serverMsg['fileName'] != null) {
          // 基于文件元数据的去重检查
          final metadataKey = FileDownloadHandler.generateFileMetadataKey(
            serverMsg['fileName'], 
            serverMsg['fileSize'] ?? 0, 
            DateTime.tryParse(serverMsg['timestamp'] ?? '') ?? DateTime.now()
          );
          
          // 检查是否已有相同元数据的文件消息
          final duplicateFileMessage = _messages.any((existingMsg) {
            if (existingMsg['fileType'] == null) return false; // 不是文件消息
            
            final existingMetadataKey = FileDownloadHandler.generateFileMetadataKey(
              existingMsg['fileName'] ?? '', 
              existingMsg['fileSize'] ?? 0, 
              DateTime.tryParse(existingMsg['timestamp'] ?? '') ?? DateTime.now()
            );
            
            return existingMetadataKey == metadataKey;
          });
          
          if (duplicateFileMessage) {
            print('发现重复文件消息（同步时，相同元数据），跳过添加: ${serverMsg['fileName']}');
            continue;
          }
          
          // 检查是否已有相同文件名和大小的消息（更宽松的检查）
          final similarFileMessage = _messages.any((existingMsg) {
            if (existingMsg['fileType'] == null) return false; // 不是文件消息
            
            return existingMsg['fileName'] == serverMsg['fileName'] && 
                   existingMsg['fileSize'] == serverMsg['fileSize'];
          });
          
          if (similarFileMessage) {
            print('发现相似文件消息（同步时，相同文件名和大小），跳过添加: ${serverMsg['fileName']} (${serverMsg['fileSize'] ?? 0} bytes)');
            continue;
          }
        }
        
        // 如果是文本消息，进行基于内容的去重检查
        if (serverMsg['fileType'] == null && serverMsg['text'] != null && serverMsg['text'].trim().isNotEmpty) {
          final content = serverMsg['text'];
          final sourceDeviceId = serverMsg['sourceDeviceId'];
          final messageTime = DateTime.tryParse(serverMsg['timestamp'] ?? '') ?? DateTime.now();
          
          // 检查是否已有相同内容和发送者的消息
          final duplicateTextMessage = _messages.any((existingMsg) {
            if (existingMsg['fileType'] != null) return false; // 不是文本消息
            if (existingMsg['text'] != content) return false; // 内容不同
            if (existingMsg['sourceDeviceId'] != sourceDeviceId) return false; // 发送者不同
            
            // 检查时间窗口（30秒内认为是重复，同步时更宽松）
            try {
              final existingTime = DateTime.parse(existingMsg['timestamp']);
              final timeDiff = (messageTime.millisecondsSinceEpoch - existingTime.millisecondsSinceEpoch).abs();
              return timeDiff < 30000; // 30秒内
            } catch (e) {
              print('文本消息时间比较失败: $e');
              return true; // 时间解析失败但内容和发送者相同，保守地认为是重复
            }
          });
          
          if (duplicateTextMessage) {
            print('发现重复文本消息（同步时，相同内容+发送者+时间窗口），跳过添加: $content');
            continue;
          }
        }
        
        // 通过检查，添加到新消息列表
        newMessages.add(serverMsg);
        // 🔥 关键修复：标记为已处理并记录时间戳，防止后续WebSocket实时消息重复
        _processedMessageIds.add(serverId);
        _messageIdTimestamps[serverId] = DateTime.now();
      }

      if (newMessages.isNotEmpty && mounted) {
        print('发现${newMessages.length}条真正的新消息，添加到界面');
        
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
        _scrollToBottom();
        
        print('后台同步完成，新增${newMessages.length}条消息');
      } else {
        print('后台同步完成，无新消息（已过滤掉${convertedMessages.length - newMessages.length}条重复消息）');
      }
    } catch (e) {
      print('同步最新消息失败: $e');
    }
  }

  // 加载本地缓存消息
  Future<void> _loadLocalMessages() async {
    final chatId = widget.conversation['id'];
    
    try {
      final messages = await _localStorage.loadChatMessages(chatId);
      if (mounted) {
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
        
        _scrollToBottom();
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
          _scrollToBottom();
          
          // 迁移到新存储
          await _localStorage.saveChatMessages(chatId, _messages);
        }
      } catch (legacyError) {
        print('兼容旧版本存储也失败: $legacyError');
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileType = _getMimeType(fileName);
        
        // 🔥 新增：检查文件大小限制（100MB）
        const int maxFileSize = 100 * 1024 * 1024; // 100MB
        final fileSize = await file.length();
        
        if (fileSize > maxFileSize) {
          // 文件超过100MB，显示错误提示
          final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
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
          return; // 阻止上传
        }
        
        await _sendFileMessage(file, fileName, fileType);
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
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // 🔥 移除AppBar，聊天页面不需要标题栏
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
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8), // 减少顶部和底部间距
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        
                        // 简化：不再显示日期分组，直接在每条消息显示完整时间
                        return _buildMessageBubble(message);
                      },
                    ),
                  ),
          ),
          
          // 输入区域
          _buildInputArea(),
        ],
      ),
    );
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
    
    // 添加调试日志
    if (message['fileUrl'] != null || message['fileName'] != null) {
      print('构建消息气泡: ID=${message['id']}, fileName=${message['fileName']}, fileType=${message['fileType']}, hasFile=$hasFile, fileUrl=${message['fileUrl']}');
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // 减少消息间距
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 消息气泡
          Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
                  padding: EdgeInsets.all(hasFile ? 6 : 10), // 减少内边距
              decoration: BoxDecoration(
                    color: isMe 
                      ? (hasFile ? Colors.white : AppTheme.primaryColor) 
                      : Colors.white,
                    borderRadius: BorderRadius.circular(16).copyWith( // 稍微减小圆角
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB), 
                      width: 0.5,
                    ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文件内容
                  if (hasFile) _buildFileContent(message, isMe),
                  
                      // 文本内容 - 统一字体
                  if (message['text'] != null && message['text'].isNotEmpty) ...[
                        if (hasFile) const SizedBox(height: 6), // 减少间距
                    Text(
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
          
          // 时间戳和状态 - 使用完整日期时间
          const SizedBox(height: 2), // 减少间距
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                    TimeUtils.formatChatDateTime(message['timestamp']), // 使用完整日期时间
                    style: AppTheme.smallStyle.copyWith(
                      fontSize: 9, // 进一步减小时间戳字体
                        ),
                      ),
                      if (isMe) ...[
                    const SizedBox(width: 3), // 减少间距
                        _buildMessageStatusIcon(message),
                      ],
                    ],
                  ),
                ],
          ),
        ],
      ),
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
    return GestureDetector(
      onTap: () => _openFile(filePath, fileUrl, fileType),
      child: Container(
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
      ),
    );
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
      padding: const EdgeInsets.all(8), // 减少内边距
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 附件按钮 - 极简设计
            GestureDetector(
              onTap: _showFileOptions,
              child: Container(
                width: 32, // 与发送按钮保持一致
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.add,
                  size: 14, // 减小图标
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            
            const SizedBox(width: 6), // 减少间距
            
            // 输入框 - 极简设计
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB), // 更浅的背景色
                  borderRadius: BorderRadius.circular(16), // 减小圆角
                ),
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (RawKeyEvent event) {
                    // 只在桌面端处理键盘事件
                    if (!_isDesktop()) return;
                    
                    if (event is RawKeyDownEvent) {
                      final isEnterPressed = event.logicalKey == LogicalKeyboardKey.enter;
                      final isShiftPressed = event.isShiftPressed;
                      
                      if (isEnterPressed && !isShiftPressed) {
                        // Enter键发送消息（桌面端）
                        final text = _messageController.text.trim();
                        if (text.isNotEmpty) {
                          _sendTextMessage(text);
                        }
                        // 阻止事件继续传播，防止TextField处理Enter键
                        return;
                      }
                      // Shift+Enter换行由TextField自动处理
                    }
                  },
                  child: Focus(
                    onKey: (FocusNode node, RawKeyEvent event) {
                      // 在桌面端拦截Enter键事件，防止TextField处理
                      if (_isDesktop() && event is RawKeyDownEvent) {
                        final isEnterPressed = event.logicalKey == LogicalKeyboardKey.enter;
                        final isShiftPressed = event.isShiftPressed;
                        
                        if (isEnterPressed && !isShiftPressed) {
                          // 返回KeyEventResult.handled表示事件已处理，阻止进一步传播
                          return KeyEventResult.handled;
                        }
                      }
                      // 其他情况让TextField正常处理
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _isDesktop() ? '输入消息... (Enter发送, Shift+Enter换行)' : '输入消息...',
                        hintStyle: AppTheme.bodyStyle.copyWith(
                          color: AppTheme.textTertiaryColor,
                          fontSize: _isDesktop() ? 13 : 14,
                        ),
                        border: InputBorder.none, // 去掉所有边框
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 减小内边距
                      ),
                      style: AppTheme.bodyStyle,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: _isDesktop() ? TextInputAction.newline : TextInputAction.send,
                      onChanged: (text) {
                        setState(() {
                          _isTyping = text.trim().isNotEmpty;
                        });
                      },
                      onSubmitted: (text) {
                        // 移动端：Enter键发送消息
                        if (!_isDesktop() && text.trim().isNotEmpty) {
                          _sendTextMessage(text.trim());
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 6), // 减少间距
            
            // 发送按钮 - 极简设计
            GestureDetector(
              onTap: () {
                final text = _messageController.text.trim();
                if (text.isNotEmpty) {
                  _sendTextMessage(text);
                }
              },
              child: Container(
                width: 32, // 再减小按钮
                height: 32,
                decoration: BoxDecoration(
                  color: _isTyping ? AppTheme.primaryColor : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.send,
                  size: 14, // 减小图标
                  color: _isTyping ? Colors.white : AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ],
        ),
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
      _downloadingFiles.remove(fullUrl);
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
              '选择文件类型',
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
    // 每30秒检查一次WebSocket状态和消息接收情况
    Timer.periodic(Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      print('🩺 === 紧急WebSocket诊断 ===');
      print('WebSocket连接状态: ${_websocketService.isConnected}');
      print('最后收到消息时间: $_lastMessageReceivedTime');
      print('已处理消息数量: ${_processedMessageIds.length}');
      print('界面消息数量: ${_messages.length}');
      
      if (_lastMessageReceivedTime != null) {
        final timeSinceLastMessage = DateTime.now().difference(_lastMessageReceivedTime!);
        print('距离最后消息: ${timeSinceLastMessage.inMinutes}分钟');
        
        // 如果超过2分钟没收到任何消息，进行恢复尝试
        if (timeSinceLastMessage.inMinutes >= 2) {
          print('⚠️ 消息接收异常，尝试恢复连接');
          _emergencyWebSocketRecovery();
        }
      } else {
        print('⚠️ 从未收到过消息，可能存在连接问题');
        _emergencyWebSocketRecovery();
      }
    });
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
  
  // 🔥 新增：处理最近消息同步
  void _handleRecentMessages(Map<String, dynamic> data) {
    print('📬 收到最近消息同步，开始处理...');
    final messages = data['data']?['messages'];
    if (messages == null || messages is! List) {
      print('最近消息数据格式错误');
      return;
    }
    
    _processSyncMessages(List<Map<String, dynamic>>.from(messages), '最近消息同步');
  }
  
  // 🔥 新增：处理离线消息同步
  void _handleOfflineMessages(Map<String, dynamic> data) {
    print('📥 收到离线消息同步，开始处理...');
    final messages = data['data']?['messages'];
    if (messages == null || messages is! List) {
      print('离线消息数据格式错误');
      return;
    }
    
    // 离线消息处理逻辑
    final offlineMessages = List<Map<String, dynamic>>.from(messages);
    print('📥 处理${offlineMessages.length}条离线消息');
    
    // 显示离线消息恢复提示
    if (offlineMessages.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('正在恢复${offlineMessages.length}条离线消息...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    _processSyncMessages(offlineMessages, '离线消息同步');
  }
  
  // 🔥 新增：处理群组消息同步
  void _handleGroupMessagesSynced(Map<String, dynamic> data) {
    print('📝 收到群组消息同步，开始处理...');
    
    // 仅处理当前群组的消息
    if (widget.conversation['type'] != 'group') {
      print('当前不是群组对话，忽略群组消息同步');
      return;
    }
    
    final messages = data['data']?['messages'];
    if (messages == null || messages is! List) {
      print('群组消息数据格式错误');
      return;
    }
    
    _processSyncMessages(List<Map<String, dynamic>>.from(messages), '群组消息同步');
  }
  
  // 🔥 新增：处理私聊消息同步
  void _handlePrivateMessagesSynced(Map<String, dynamic> data) {
    print('📝 收到私聊消息同步，开始处理...');
    
    // 仅处理当前私聊的消息
    if (widget.conversation['type'] == 'group') {
      print('当前不是私聊对话，忽略私聊消息同步');
      return;
    }
    
    final messages = data['data']?['messages'];
    if (messages == null || messages is! List) {
      print('私聊消息数据格式错误');
      return;
    }
    
    _processSyncMessages(List<Map<String, dynamic>>.from(messages), '私聊消息同步');
  }
  
  // 🔥 新增：统一处理同步消息的方法
  void _processSyncMessages(List<Map<String, dynamic>> syncMessages, String syncType) async {
    if (syncMessages.isEmpty) {
      print('$syncType: 无消息需要处理');
      return;
    }
    
    print('$syncType: 开始处理${syncMessages.length}条消息');
    
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
    
    // 转换消息格式（使用现有的转换逻辑）
    final convertedMessages = syncMessages.map((msg) {
      final isMe = msg['sourceDeviceId'] == currentDeviceId;
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
    
    // 过滤掉重复消息
    final newMessages = <Map<String, dynamic>>[];
    for (final msg in convertedMessages) {
      final msgId = msg['id'].toString();
      
      // 检查是否已存在
      final exists = _messages.any((localMsg) => localMsg['id'].toString() == msgId);
      if (!exists) {
        newMessages.add(msg);
      }
    }
    
    if (newMessages.isNotEmpty && mounted) {
      print('$syncType: 添加${newMessages.length}条新消息到界面');
      
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
      
      // 为文件消息自动下载文件
      for (final message in newMessages) {
        if (message['fileUrl'] != null && !message['isMe']) {
          _autoDownloadFile(message);
        }
      }
      
      // 保存消息
      _saveMessages();
      _scrollToBottom();
      
      print('$syncType: 完成，新增${newMessages.length}条消息');
    } else {
      print('$syncType: 无新消息需要添加');
    }
  }
}

// 视频静态缩略图预览组件
class _VideoGifPreview extends StatefulWidget {
  final String? videoPath;
  final String? videoUrl;

  const _VideoGifPreview({
    this.videoPath,
    this.videoUrl,
  });

  @override
  State<_VideoGifPreview> createState() => _VideoGifPreviewState();
}

class _VideoGifPreviewState extends State<_VideoGifPreview> {
  Uint8List? _thumbnailData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateVideoThumbnail();
  }

  Future<void> _generateVideoThumbnail() async {
    if (widget.videoPath == null && widget.videoUrl == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    try {
      String videoSource = widget.videoPath ?? widget.videoUrl!;
      Uint8List? thumbnailData;
      
      // 方案1: 优先尝试使用fc_native_video_thumbnail（支持桌面端）
      try {
        final plugin = FcNativeVideoThumbnail();
        
        // 创建临时文件路径用于保存缩略图
        final directory = await getApplicationDocumentsDirectory();
        final thumbnailDir = Directory(path.join(directory.path, 'thumbnails'));
        if (!thumbnailDir.existsSync()) {
          thumbnailDir.createSync(recursive: true);
        }
        
        final thumbnailPath = path.join(
          thumbnailDir.path, 
          'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg'
        );
        
        // 生成缩略图文件
        final success = await plugin.getVideoThumbnail(
          srcFile: videoSource,
          destFile: thumbnailPath,
          width: 400, // 高分辨率
          height: 300, // 高分辨率  
          format: 'jpeg',
          quality: 90, // 高质量
        );
        
        if (success) {
          // 读取生成的缩略图文件
          final thumbnailFile = File(thumbnailPath);
          if (thumbnailFile.existsSync()) {
            thumbnailData = await thumbnailFile.readAsBytes();
            
            // 清理临时文件
            try {
              await thumbnailFile.delete();
            } catch (e) {
              print('清理缩略图临时文件失败: $e');
            }
          }
        }
      } catch (e) {
        print('fc_native_video_thumbnail 失败，尝试备用方案: $e');
      }
      
      // 方案2: 如果fc_native_video_thumbnail失败，使用video_thumbnail（移动端）
      if (thumbnailData == null) {
        try {
          thumbnailData = await VideoThumbnail.thumbnailData(
            video: videoSource,
            imageFormat: ImageFormat.JPEG,
            timeMs: 1000, // 从第1秒开始截取
            maxWidth: 400, // 高分辨率
            maxHeight: 300, // 高分辨率
            quality: 90, // 高质量
          );
          print('使用video_thumbnail生成缩略图成功');
        } catch (e) {
          print('video_thumbnail 也失败了: $e');
        }
      } else {
        print('使用fc_native_video_thumbnail生成缩略图成功');
      }
      
      if (mounted && thumbnailData != null) {
        setState(() {
          _thumbnailData = thumbnailData;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('生成视频缩略图失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
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
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
            ),
          ),
        ),
      );
    }
    
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.05),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    // 如果缩略图生成失败，显示默认图标
    return Container(
      color: const Color(0xFF1F2937),
      child: const Center(
        child: Icon(
          Icons.play_circle_fill,
          size: 48,
          color: Colors.white70,
        ),
      ),
    );
  } 
}