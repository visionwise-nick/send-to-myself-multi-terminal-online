import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../services/chat_service.dart';
import '../services/websocket_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:open_filex/open_filex.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:math' as math;

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
  
  // 消息处理相关
  final Set<String> _processedMessageIds = <String>{}; // 防止重复处理
  bool _isInitialLoad = true;
  
  // 文件下载相关
  final Dio _dio = Dio();
  final Map<String, String> _downloadedFiles = {}; // URL -> 本地路径
  final Set<String> _downloadingFiles = {}; // 正在下载的文件URL
  
  // 文件缓存键前缀
  static const String _filePathCachePrefix = 'file_path_cache_';

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
  }

  // 初始化Dio配置，添加认证头
  void _initializeDio() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
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
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _messageAnimationController.dispose();
    _chatMessageSubscription?.cancel();
    super.dispose();
  }

  // 订阅聊天消息
  void _subscribeToChatMessages() {
    _chatMessageSubscription = _websocketService.onChatMessage.listen((data) {
      if (mounted) {
        print('收到聊天消息: ${data['type']}');
        switch (data['type']) {
          case 'new_private_message':
            _handleIncomingMessage(data, false);
            break;
          case 'new_group_message':
            _handleIncomingMessage(data, true);
            break;
          case 'message_sent_confirmation':
          case 'group_message_sent_confirmation':
            _handleMessageSentConfirmation(data);
            break;
          case 'message_status_updated':
            _handleMessageStatusUpdate(data);
            break;
        }
      }
    });
  }

  // 统一处理接收到的消息
  void _handleIncomingMessage(Map<String, dynamic> data, bool isGroupMessage) {
    final message = data['message'];
    if (message == null) return;

    final messageId = message['id'];
    if (messageId == null || _processedMessageIds.contains(messageId)) {
      print('消息已处理过，跳过: $messageId');
      return; // 防止重复处理
    }

    // 检查是否是当前对话的消息
    if (!_isMessageForCurrentConversation(message, isGroupMessage)) {
      return;
    }

    // 额外检查：防止重复消息（检查内容和时间戳）
    final content = message['content'];
    final timestamp = message['createdAt'];
    final sourceDeviceId = message['sourceDeviceId'];
    final fileUrl = message['fileUrl'];
    final fileName = message['fileName'];
    
    // 检查是否存在相同内容、时间戳和发送者的消息
    final isDuplicate = _messages.any((existingMsg) {
      // 基本信息匹配
      final basicMatch = existingMsg['text'] == content &&
             existingMsg['timestamp'] == _normalizeTimestamp(timestamp ?? '') &&
             existingMsg['sourceDeviceId'] == sourceDeviceId;
      
      // 如果是文件消息，还要检查文件相关信息
      if (fileUrl != null || fileName != null) {
        final fileMatch = existingMsg['fileUrl'] == fileUrl || 
                         (existingMsg['fileName'] == fileName && fileName != null);
        return basicMatch || fileMatch;
      }
      
      return basicMatch;
    });
    
    if (isDuplicate) {
      print('发现重复消息，跳过添加: $content / $fileName');
      _processedMessageIds.add(messageId); // 仍然标记为已处理
      return;
    }

    // 标记消息已处理
    _processedMessageIds.add(messageId);
    
    // 添加消息到界面
    _addMessageToChat(message, false);
    
    // 发送已接收回执（只发送一次）
    _websocketService.sendMessageReceived(messageId);
    
    print('成功处理消息: $messageId');
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
        'fileType': message['type']?.contains('file') == true ? _getFileType(message['fileName']) : null,
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
      
      // 为本地加载的消息添加到已处理集合中，避免重复
      for (final message in _messages) {
        final messageId = message['id'];
        if (messageId != null) {
          _processedMessageIds.add(messageId.toString());
        }
      }
      
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
          'fileType': msg['type']?.contains('file') == true ? _getFileType(msg['fileName']) : null,
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

      // 只添加本地没有的新消息（严格去重）
      final Set<String> existingIds = _messages.map((msg) => msg['id'].toString()).toSet();
      final List<Map<String, dynamic>> newMessages = convertedMessages
          .where((msg) {
            final msgId = msg['id'].toString();
            final isNewId = !existingIds.contains(msgId) && !_processedMessageIds.contains(msgId);
            
            // 额外检查：防止内容重复的消息
            final isDuplicateContent = _messages.any((existingMsg) {
              return existingMsg['text'] == msg['text'] &&
                     existingMsg['timestamp'] == msg['timestamp'] &&
                     existingMsg['sourceDeviceId'] == msg['sourceDeviceId'];
            });
            
            return isNewId && !isDuplicateContent;
          })
          .toList();

      if (newMessages.isNotEmpty && mounted) {
        print('发现${newMessages.length}条新消息，添加到界面');
        
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
        
        // 标记新消息为已处理
        for (final message in newMessages) {
          _processedMessageIds.add(message['id'].toString());
          
          // 如果是文件消息且不是自己发的，立即下载
          if (message['fileUrl'] != null && !message['isMe']) {
            _autoDownloadFile(message);
          }
        }
        
        // 保存更新后的消息到本地
        await _saveMessages();
        _scrollToBottom();
        
        print('后台同步完成，新增${newMessages.length}条消息');
      } else {
        print('后台同步完成，无新消息');
      }
    } catch (e) {
      print('同步最新消息失败: $e');
    }
  }

  // 加载本地缓存消息
  Future<void> _loadLocalMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final chatId = widget.conversation['id'];
    final messagesJson = prefs.getString('chat_messages_$chatId') ?? '[]';
    
    try {
      final List<dynamic> messagesList = json.decode(messagesJson);
      setState(() {
        _messages = messagesList.map((msg) => Map<String, dynamic>.from(msg)).toList();
      });
      _scrollToBottom();
    } catch (e) {
      print('加载本地消息失败: $e');
    }
  }

  // 保存聊天消息到本地
  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final chatId = widget.conversation['id'];
    await prefs.setString('chat_messages_$chatId', json.encode(_messages));
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
    _scrollToBottom();
    
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
            // 如果API返回了真实的消息ID，更新它但不移除消息
            if (apiResult!['messageId'] != null) {
              final realMessageId = apiResult['messageId'];
              _messages[index]['id'] = realMessageId;
              _processedMessageIds.add(realMessageId.toString()); // 标记为已处理，避免重复
              print('消息ID更新: $messageId -> $realMessageId');
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
    // 创建文件消息对象，包含进度信息
    final fileMessage = {
      'id': 'temp_file_${DateTime.now().millisecondsSinceEpoch}',
      'text': '', // 文件消息可能包含文字说明
      'fileType': _getFileType(fileName),
      'fileName': fileName,
      'filePath': file.path,
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
    _scrollToBottom();
    
    print('文件消息已立即添加到界面: $fileName, ID: ${fileMessage['id']}');

    try {
      Map<String, dynamic>? apiResult;
      
      if (widget.conversation['type'] == 'group') {
        // 发送群组文件
        final groupId = widget.conversation['groupData']?['id'];
        if (groupId != null) {
          // 模拟上传进度
          await _simulateUploadProgress(fileMessage['id'] as String);
          
          apiResult = await _chatService.sendGroupFile(
            groupId: groupId,
            file: file,
            fileName: fileName,
            fileType: fileType,
          );
          
          // 更新临时消息为已发送状态，并更新完整的API返回信息
          if (apiResult != null && mounted) {
            setState(() {
              final index = _messages.indexWhere((msg) => msg['id'] == fileMessage['id']);
              if (index != -1) {
                // 完整更新消息信息
                _messages[index]['status'] = 'sent';
                _messages[index]['isTemporary'] = false;
                if (apiResult!['messageId'] != null) {
                  _messages[index]['id'] = apiResult['messageId'];
                  _processedMessageIds.add(apiResult['messageId'].toString());
                }
                if (apiResult['fileUrl'] != null) {
                  _messages[index]['fileUrl'] = apiResult['fileUrl'];
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
          // 模拟上传进度
          await _simulateUploadProgress(fileMessage['id'] as String);
          
          apiResult = await _chatService.sendPrivateFile(
            targetDeviceId: deviceId,
            file: file,
            fileName: fileName,
            fileType: fileType,
          );
          
          // 更新临时消息为已发送状态，并更新完整的API返回信息
          if (apiResult != null && mounted) {
            setState(() {
              final index = _messages.indexWhere((msg) => msg['id'] == fileMessage['id']);
              if (index != -1) {
                // 完整更新消息信息
                _messages[index]['status'] = 'sent';
                _messages[index]['isTemporary'] = false;
                if (apiResult!['messageId'] != null) {
                  _messages[index]['id'] = apiResult['messageId'];
                  _processedMessageIds.add(apiResult['messageId'].toString());
                }
                if (apiResult['fileUrl'] != null) {
                  _messages[index]['fileUrl'] = apiResult['fileUrl'];
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
      
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('发送文件失败: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // 模拟上传进度
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
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            // 现代化头像设计
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isGroup 
                    ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                    : [const Color(0xFF10B981), const Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  widget.conversation['avatar'] ?? (isGroup ? '👥' : '📱'),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  if (!isGroup && widget.conversation['isOnline'] == true)
                    Container(
                      margin: const EdgeInsets.only(top: 1),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Text(
                            '在线',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {
                // TODO: 显示聊天详情
              },
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6366F1),
                  ),
                )
              : _messages.isEmpty
                ? _buildEmptyState()
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_messages[index]);
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '开始对话',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '发送消息或文件来开始聊天',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['isMe'] == true;
    final hasFile = message['fileType'] != null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.all(hasFile ? 6 : 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF6366F1) : Colors.white,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe 
                      ? const Color(0xFF6366F1).withOpacity(0.2)
                      : Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文件内容
                  if (hasFile) _buildFileContent(message, isMe),
                  
                  // 文本内容
                  if (message['text'] != null && message['text'].isNotEmpty) ...[
                    if (hasFile) const SizedBox(height: 6),
                    Text(
                      message['text'],
                      style: TextStyle(
                        color: isMe ? Colors.white : const Color(0xFF1F2937),
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  
                  // 时间和状态
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        TimeUtils.formatTime(message['timestamp']),
                        style: TextStyle(
                          color: isMe 
                            ? Colors.white.withOpacity(0.7)
                            : const Color(0xFF9CA3AF),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildMessageStatusIcon(message),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ],
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
    final status = message['status'] ?? 'sent';

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文件预览区域
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildFilePreview(fileType, filePath, fileUrl, isMe),
          ),
          
          // 上传/下载进度条
          if (status == 'uploading' && uploadProgress < 1.0)
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_upload_rounded,
                        size: 14,
                        color: isMe ? Colors.white.withOpacity(0.8) : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '上传中 ${(uploadProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe ? Colors.white.withOpacity(0.8) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: uploadProgress,
                    backgroundColor: isMe ? Colors.white.withOpacity(0.3) : const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isMe ? Colors.white : const Color(0xFF6366F1),
                    ),
                    borderRadius: BorderRadius.circular(2),
                    minHeight: 3,
                  ),
                ],
              ),
            ),
          
          if (message['downloadProgress'] != null && message['downloadProgress'] < 1.0)
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.cloud_download_rounded,
                        size: 14,
                        color: Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '下载中 ${(message['downloadProgress'] * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: message['downloadProgress'],
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                    borderRadius: BorderRadius.circular(2),
                    minHeight: 3,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 构建文件预览 - 简洁实用设计
  Widget _buildFilePreview(String? fileType, String? filePath, String? fileUrl, bool isMe) {
    // 转换相对URL为绝对URL
    String? fullUrl = fileUrl;
    if (fileUrl != null && fileUrl.startsWith('/api/')) {
      fullUrl = 'https://sendtomyself-api-adecumh2za-uc.a.run.app$fileUrl';
    }

    // 优先使用本地文件路径
    String? actualFilePath = filePath;
    if (actualFilePath == null || !File(actualFilePath).existsSync()) {
      // 检查缓存中是否有文件
      if (fullUrl != null && _downloadedFiles.containsKey(fullUrl)) {
        final cachedPath = _downloadedFiles[fullUrl]!;
        if (File(cachedPath).existsSync()) {
          actualFilePath = cachedPath;
        }
      }
    }

    return GestureDetector(
      onTap: () => _openFile(actualFilePath, fullUrl, fileType),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片和视频只显示预览，不显示额外信息
            if (fileType == 'image') 
              _buildSimpleImagePreview(actualFilePath, fullUrl)
            else if (fileType == 'video')
              _buildSimpleVideoPreview(actualFilePath, fullUrl)
            else
              // 其他文件类型显示简洁信息
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMe ? Colors.white.withOpacity(0.15) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isMe ? Colors.white.withOpacity(0.3) : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFileTypeIcon(fileType),
                      size: 16,
                      color: isMe ? Colors.white.withOpacity(0.9) : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _getFileName(actualFilePath, fullUrl) ?? '文件',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: isMe ? Colors.white.withOpacity(0.9) : const Color(0xFF374151),
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
        height: 100,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (fileUrl != null) {
      imageWidget = Image.network(
        fileUrl,
        height: 100,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 100,
            width: double.infinity,
            color: const Color(0xFFF3F4F6),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 100,
            width: double.infinity,
            color: const Color(0xFFF3F4F6),
            child: const Icon(Icons.image_not_supported, size: 24),
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: imageWidget,
    );
  }

  // 构建简单视频预览
  Widget _buildSimpleVideoPreview(String? filePath, String? fileUrl) {
    return FutureBuilder<String?>(
      future: _generateVideoThumbnail(filePath, fileUrl),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          // 显示视频缩略图
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(snapshot.data!),
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // 播放按钮覆盖层
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          // 加载中或无缩略图时显示默认播放图标
          return Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_outline,
                size: 32,
                color: Colors.white,
              ),
            ),
          );
        }
      },
    );
  }

  // 生成视频缩略图
  Future<String?> _generateVideoThumbnail(String? filePath, String? fileUrl) async {
    try {
      String? videoPath;
      
      // 确定视频文件路径
      if (filePath != null && File(filePath).existsSync()) {
        videoPath = filePath;
      } else if (fileUrl != null) {
        // 检查缓存中是否有本地文件
        String fullUrl = fileUrl;
        if (fileUrl.startsWith('/api/')) {
          fullUrl = 'https://sendtomyself-api-adecumh2za-uc.a.run.app$fileUrl';
        }
        
        if (_downloadedFiles.containsKey(fullUrl)) {
          final cachedPath = _downloadedFiles[fullUrl]!;
          if (File(cachedPath).existsSync()) {
            videoPath = cachedPath;
          }
        }
      }
      
      if (videoPath == null) return null;
      
      // 生成缩略图缓存键
      final videoFileName = path.basename(videoPath);
      final thumbnailCacheKey = 'video_thumbnail_$videoFileName';
      
      // 检查是否已有缓存的缩略图
      final prefs = await SharedPreferences.getInstance();
      final cachedThumbnailPath = prefs.getString(thumbnailCacheKey);
      if (cachedThumbnailPath != null && File(cachedThumbnailPath).existsSync()) {
        return cachedThumbnailPath;
      }
      
      // 生成新的缩略图
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
      );
      
      // 缓存缩略图路径
      if (thumbnailPath != null) {
        await prefs.setString(thumbnailCacheKey, thumbnailPath);
      }
      
      return thumbnailPath;
    } catch (e) {
      print('生成视频缩略图失败: $e');
      return null;
    }
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
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 附件按钮 - 简化设计
            GestureDetector(
              onTap: _showFileOptions,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // 输入框 - 简化设计
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isTyping 
                      ? const Color(0xFF6366F1)
                      : const Color(0xFFD1D5DB),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: '输入消息...',
                    hintStyle: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  onChanged: (text) {
                    setState(() {
                      _isTyping = text.trim().isNotEmpty;
                    });
                  },
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      _sendTextMessage(text);
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // 发送按钮 - 简化设计
            GestureDetector(
              onTap: () {
                final text = _messageController.text.trim();
                if (text.isNotEmpty) {
                  _sendTextMessage(text);
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _isTyping ? const Color(0xFF6366F1) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.send_rounded,
                  size: 16,
                  color: _isTyping ? Colors.white : const Color(0xFF6B7280),
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
    
    if (isTemporary && status == 'sending') {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
        ),
      );
    } else if (status == 'uploading') {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
        ),
      );
    } else if (status == 'failed') {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.error_outline_rounded,
          size: 10,
          color: Colors.white,
        ),
      );
    } else if (status == 'read') {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.done_all_rounded,
          size: 10,
          color: Colors.white,
        ),
      );
    } else if (status == 'sent') {
      return Icon(
        Icons.done_rounded,
        size: 14,
        color: Colors.white.withOpacity(0.8),
      );
    }
    return const SizedBox();
  }

  // 自动下载文件
  Future<void> _autoDownloadFile(Map<String, dynamic> message) async {
    final fileUrl = message['fileUrl'];
    final fileName = message['fileName'];
    
    if (fileUrl == null || fileName == null) return;
    
    // 转换相对URL为绝对URL
    String fullUrl = fileUrl;
    if (fileUrl.startsWith('/api/')) {
      fullUrl = 'https://sendtomyself-api-adecumh2za-uc.a.run.app$fileUrl';
    }
    
    // 检查是否已经下载过
    if (_downloadedFiles.containsKey(fullUrl)) {
      final localPath = _downloadedFiles[fullUrl]!;
      if (File(localPath).existsSync()) {
        print('文件已存在，跳过下载: $fileName');
        return;
      } else {
        // 文件不存在了，从缓存中移除
        _downloadedFiles.remove(fullUrl);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('$_filePathCachePrefix$fullUrl');
      }
    }
    
    // 检查是否正在下载
    if (_downloadingFiles.contains(fullUrl)) {
      print('文件正在下载中，跳过: $fileName');
      return;
    }
    
    try {
      _downloadingFiles.add(fullUrl);
      print('开始下载文件: $fileName');
      
      // 获取下载目录
      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory(path.join(directory.path, 'downloads'));
      if (!downloadDir.existsSync()) {
        downloadDir.createSync(recursive: true);
      }
      
      // 生成唯一的文件名
      final fileExtension = path.extension(fileName);
      final baseName = path.basenameWithoutExtension(fileName);
      final uniqueFileName = '${baseName}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final localPath = path.join(downloadDir.path, uniqueFileName);
      
      // 下载文件
      await _dio.download(fullUrl, localPath);
      
      // 保存到持久化缓存
      await _saveFileCache(fullUrl, localPath);
      
      print('文件下载完成并缓存: $fileName -> $localPath');
    } catch (e) {
      print('文件下载失败: $fileName, 错误: $e');
    } finally {
      _downloadingFiles.remove(fullUrl);
    }
  }
  
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              '选择文件类型',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 简洁的文件选项列表
            _buildFileOption(Icons.image_rounded, '图片', () => _selectFile(FileType.image)),
            _buildFileOption(Icons.videocam_rounded, '视频', () => _selectFile(FileType.video)),
            _buildFileOption(Icons.description_rounded, '文档', () => _selectFile(FileType.any)),
            _buildFileOption(Icons.audiotrack_rounded, '音频', () => _selectFile(FileType.audio)),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFileOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6B7280)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1F2937),
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }

  // 加载文件缓存映射
  Future<void> _loadFileCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_filePathCachePrefix));
    
    for (final key in keys) {
      final url = key.substring(_filePathCachePrefix.length);
      final filePath = prefs.getString(key);
      if (filePath != null && File(filePath).existsSync()) {
        _downloadedFiles[url] = filePath;
      } else {
        // 清理无效的缓存
        await prefs.remove(key);
      }
    }
    print('已加载 ${_downloadedFiles.length} 个缓存文件');
  }

  // 保存文件缓存映射
  Future<void> _saveFileCache(String url, String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_filePathCachePrefix$url', filePath);
    _downloadedFiles[url] = filePath;
  }
} 