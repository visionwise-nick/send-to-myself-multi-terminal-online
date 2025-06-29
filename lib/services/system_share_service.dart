import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../config/debug_config.dart';

class SystemShareService {
  static final SystemShareService _instance = SystemShareService._internal();
  factory SystemShareService() => _instance;
  SystemShareService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _isShareIntent = false;
  bool _silentShareMode = false;
  
  // 分享内容回调
  Function(SharedContent)? onSharedContentReceived;
  
  // 初始化系统分享服务
  Future<void> initialize() async {
    try {
      print('🔗 初始化系统分享服务...');
      
      // 监听app链接
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          print('📥 收到app链接: $uri');
          _handleAppLink(uri);
        },
        onError: (err) {
          print('❌ App链接错误: $err');
        },
      );
      
      // 延迟处理，确保UI已经初始化
      await Future.delayed(Duration(milliseconds: 500));
      
      // 检查初始链接（当应用从分享启动时）
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        print('📥 收到初始app链接: $initialUri');
        _handleAppLink(initialUri);
      }
      
      // 处理Android Intent（使用MethodChannel）
      if (!kIsWeb && Platform.isAndroid) {
        // 检查是否为分享Intent
        _isShareIntent = await _checkIsShareIntent();
        print('🔍 是否为分享Intent: $_isShareIntent');
        
        // 延迟处理Android Intent，确保应用UI完全加载
        await Future.delayed(Duration(milliseconds: 1000));
        await handleAndroidIntent();
      }
      
      print('✅ 系统分享服务初始化完成');
    } catch (e) {
      print('❌ 系统分享服务初始化失败: $e');
    }
  }
  
  // 检查是否为分享Intent
  Future<bool> _checkIsShareIntent() async {
    try {
      const platform = MethodChannel('com.example.send_to_myself/share');
      final bool? isShare = await platform.invokeMethod('isShareIntent');
      final result = isShare ?? false;
      
      // 🔥 新增：如果是分享Intent，自动启用静默模式
      if (result) {
        setSilentShareMode(true);
      }
      
      return result;
    } catch (e) {
      print('❌ 检查分享Intent失败: $e');
      return false;
    }
  }
  
  // 获取是否为分享Intent
  bool get isShareIntent => _isShareIntent;
  bool get isSilentShareMode => _silentShareMode;
  
  // 设置静默分享模式
  void setSilentShareMode(bool enabled) {
    _silentShareMode = enabled;
    print('🔧 静默分享模式: ${enabled ? '开启' : '关闭'}');
  }
  
  // 处理app链接
  void _handleAppLink(Uri uri) {
    try {
      print('🔍 解析app链接: $uri');
      
      if (uri.scheme == 'sendtomyself') {
        final queryParams = uri.queryParameters;
        
        if (queryParams.containsKey('text')) {
          // 处理文本分享
          final text = queryParams['text']!;
          final sharedContent = SharedContent(
            type: SharedContentType.text,
            text: text,
          );
          _notifySharedContent(sharedContent);
        } else if (queryParams.containsKey('url')) {
          // 处理URL分享
          final url = queryParams['url']!;
          final sharedContent = SharedContent(
            type: SharedContentType.text,
            text: url,
          );
          _notifySharedContent(sharedContent);
        }
      }
    } catch (e) {
      print('❌ 处理app链接失败: $e');
    }
  }
  
  // 处理Android Intent
  Future<void> handleAndroidIntent() async {
    try {
      const platform = MethodChannel('com.example.send_to_myself/share');
      
      // 获取分享的内容
      final Map<dynamic, dynamic>? sharedData = await platform.invokeMethod('getSharedData');
      
      if (sharedData != null) {
        print('📥 收到Android分享数据: $sharedData');
        await _processSharedData(sharedData);
      }
    } catch (e) {
      print('❌ 处理Android Intent失败: $e');
    }
  }
  
  // 处理分享数据
  Future<void> _processSharedData(Map<dynamic, dynamic> data) async {
    try {
      final String? type = data['type']?.toString();
      
      if (type == null) return;
      
      if (type.startsWith('text/')) {
        // 处理文本内容
        final String? text = data['text']?.toString();
        if (text != null && text.isNotEmpty) {
          final sharedContent = SharedContent(
            type: SharedContentType.text,
            text: text,
          );
          _notifySharedContent(sharedContent);
        }
      } else if (type.startsWith('image/') || type.startsWith('video/') || type.startsWith('audio/') || type.startsWith('application/')) {
        // 处理文件内容
        final String? filePath = data['path']?.toString();
        final String? fileName = data['name']?.toString();
        
        if (filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            // 复制文件到应用目录
            final String copiedFilePath = await _copySharedFile(file, fileName);
            
            final sharedContent = SharedContent(
              type: _getContentTypeFromMime(type),
              filePath: copiedFilePath,
              fileName: fileName ?? path.basename(filePath),
              mimeType: type,
            );
            _notifySharedContent(sharedContent);
          }
        }
      } else if (data['files'] != null && data['files'] is List) {
        // 处理多个文件
        final List<dynamic> files = data['files'];
        final List<SharedFile> sharedFiles = [];
        
        for (final fileData in files) {
          if (fileData is Map) {
            final String? filePath = fileData['path']?.toString();
            final String? fileName = fileData['name']?.toString();
            final String? mimeType = fileData['type']?.toString();
            
            if (filePath != null) {
              final file = File(filePath);
              if (await file.exists()) {
                final String copiedFilePath = await _copySharedFile(file, fileName);
                sharedFiles.add(SharedFile(
                  path: copiedFilePath,
                  name: fileName ?? path.basename(filePath),
                  mimeType: mimeType,
                ));
              }
            }
          }
        }
        
        if (sharedFiles.isNotEmpty) {
          final sharedContent = SharedContent(
            type: SharedContentType.files,
            files: sharedFiles,
          );
          _notifySharedContent(sharedContent);
        }
      }
    } catch (e) {
      print('❌ 处理分享数据失败: $e');
    }
  }
  
  // 复制分享的文件到应用目录
  Future<String> _copySharedFile(File sourceFile, String? fileName) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory sharedDir = Directory(path.join(appDir.path, 'shared_files'));
      
      // 确保目录存在
      if (!await sharedDir.exists()) {
        await sharedDir.create(recursive: true);
      }
      
      // 生成唯一文件名
      final String originalName = fileName ?? path.basename(sourceFile.path);
      final String extension = path.extension(originalName);
      final String baseName = path.basenameWithoutExtension(originalName);
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String uniqueName = '${baseName}_$timestamp$extension';
      
      final File targetFile = File(path.join(sharedDir.path, uniqueName));
      
      // 复制文件
      await sourceFile.copy(targetFile.path);
      
              DebugConfig.debugPrint('文件已复制: ${sourceFile.path} -> ${targetFile.path}', module: 'FILE');
      return targetFile.path;
    } catch (e) {
              DebugConfig.errorPrint('复制分享文件失败: $e', module: 'FILE');
      rethrow;
    }
  }
  
  // 根据MIME类型确定内容类型
  SharedContentType _getContentTypeFromMime(String mimeType) {
    if (mimeType.startsWith('text/')) {
      return SharedContentType.text;
    } else if (mimeType.startsWith('image/')) {
      return SharedContentType.image;
    } else if (mimeType.startsWith('video/')) {
      return SharedContentType.video;
    } else if (mimeType.startsWith('audio/')) {
      return SharedContentType.audio;
    } else {
      return SharedContentType.file;
    }
  }
  
  // 通知分享内容
  void _notifySharedContent(SharedContent content) {
    print('📢 通知分享内容: ${content.type}');
    onSharedContentReceived?.call(content);
    
    // 处理完分享内容后清除原生数据
    _clearNativeSharedData();
  }
  
  // 完成分享处理
  Future<void> finishShareProcess() async {
    try {
      if (!kIsWeb && Platform.isAndroid && _isShareIntent) {
        const platform = MethodChannel('com.example.send_to_myself/share');
        await platform.invokeMethod('finishShare');
        print('✅ 已请求完成分享');
      }
    } catch (e) {
      print('❌ 完成分享处理失败: $e');
    }
  }
  
  // 清除原生分享数据
  Future<void> _clearNativeSharedData() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        const platform = MethodChannel('com.example.send_to_myself/share');
        await platform.invokeMethod('clearSharedData');
        print('✅ 已清除原生分享数据');
      }
    } catch (e) {
      print('❌ 清除原生分享数据失败: $e');
    }
  }
  
  // 清理资源
  void dispose() {
    _linkSubscription?.cancel();
  }
}

// 分享内容类型枚举
enum SharedContentType {
  text,
  image,
  video,
  audio,
  file,
  files,
}

// 分享内容数据类
class SharedContent {
  final SharedContentType type;
  final String? text;
  final String? filePath;
  final String? fileName;
  final String? mimeType;
  final List<SharedFile>? files;
  
  SharedContent({
    required this.type,
    this.text,
    this.filePath,
    this.fileName,
    this.mimeType,
    this.files,
  });
  
  @override
  String toString() {
    return 'SharedContent{type: $type, text: $text, filePath: $filePath, fileName: $fileName, mimeType: $mimeType, files: ${files?.length}}';
  }
}

// 分享文件数据类
class SharedFile {
  final String path;
  final String name;
  final String? mimeType;
  
  SharedFile({
    required this.path,
    required this.name,
    this.mimeType,
  });
  
  @override
  String toString() {
    return 'SharedFile{path: $path, name: $name, mimeType: $mimeType}';
  }
} 