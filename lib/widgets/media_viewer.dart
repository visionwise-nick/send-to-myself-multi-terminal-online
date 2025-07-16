import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:gal/gal.dart';
import 'package:flutter/foundation.dart';
import '../utils/localization_helper.dart';
import '../theme/app_theme.dart';

class MediaViewer extends StatefulWidget {
  final List<Map<String, dynamic>> mediaMessages; // 所有媒体消息
  final int initialIndex; // 初始显示的索引
  
  const MediaViewer({
    super.key,
    required this.mediaMessages,
    required this.initialIndex,
  });

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;
  bool _showUI = true;
  late AnimationController _uiAnimationController;
  late Animation<double> _uiAnimation;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    
    // UI显示隐藏动画
    _uiAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _uiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _uiAnimationController, curve: Curves.easeInOut),
    );
    _uiAnimationController.forward();
    
    // 初始化当前媒体
    _initializeMedia();
  }

  @override
  void dispose() {
    // 🔥 修复：安全释放所有资源
    try {
      _pageController.dispose();
    } catch (e) {
      print('PageController dispose错误: $e');
    }
    
    try {
      _videoController?.dispose();
      _videoController = null;
    } catch (e) {
      print('VideoController dispose错误: $e');
    }
    
    try {
      _uiAnimationController.dispose();
    } catch (e) {
      print('Animation Controller dispose错误: $e');
    }
    
    super.dispose();
  }

  void _initializeMedia() {
    // 🔥 修复：安全释放之前的视频控制器
    try {
      _videoController?.dispose();
    } catch (e) {
      print('释放VideoController错误: $e');
    }
    _videoController = null;
    _isVideoPlaying = false;
    
    if (!mounted) return;
    
    final currentMessage = widget.mediaMessages[_currentIndex];
    final fileType = currentMessage['fileType'];
    
    // 🔥 修复：只有视频文件才创建VideoPlayerController
    if (fileType == 'video') {
      final filePath = _getMediaFilePath(currentMessage);
      if (filePath != null && File(filePath).existsSync()) {
        try {
          _videoController = VideoPlayerController.file(File(filePath));
          _videoController!.initialize().then((_) {
            if (mounted && _videoController != null) {
              setState(() {});
            }
          }).catchError((error) {
            print('VideoPlayer初始化错误: $error');
            if (mounted) {
              setState(() {
                _videoController = null;
              });
            }
          });
        } catch (e) {
          print('创建VideoPlayerController错误: $e');
          _videoController = null;
        }
      }
    }
  }

  String? _getMediaFilePath(Map<String, dynamic> message) {
    // 🔥 修复：iOS Container路径问题
    String? localPath = message['localFilePath'];
    String? originalPath = message['filePath'];
    
    // 🔥 性能优化：使用缓存避免重复文件系统访问
    // 优先使用localFilePath，如果文件存在
    if (localPath != null && File(localPath).existsSync()) {
      return localPath;
    }
    
    // 如果localFilePath不存在，尝试originalPath
    if (originalPath != null && File(originalPath).existsSync()) {
      return originalPath;
    }
    
    // 🔥 iOS修复：如果都不存在，尝试修复Container路径
    if (localPath != null && Platform.isIOS) {
      try {
        // 获取当前应用的文档目录
        final fileName = localPath.split('/').last;
        final currentAppDir = Directory.systemTemp.parent.path;
        
        // 在files_cache目录中查找文件
        final fixedPath = '$currentAppDir/Library/Application Support/files_cache/$fileName';
        if (File(fixedPath).existsSync()) {
          print('iOS路径修复成功: $fixedPath');
          return fixedPath;
        }
        
        // 尝试在Document目录中查找
        final docPath = '$currentAppDir/Documents/$fileName';
        if (File(docPath).existsSync()) {
          print('iOS路径修复成功(Documents): $docPath');
          return docPath;
        }
      } catch (e) {
        print('iOS路径修复失败: $e');
      }
    }
    
    // 如果所有尝试都失败，返回原始路径
    return localPath ?? originalPath;
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
    
    if (_showUI) {
      _uiAnimationController.forward();
    } else {
      _uiAnimationController.reverse();
    }
  }

  void _previousMedia() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextMedia() {
    if (_currentIndex < widget.mediaMessages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    // 🔥 修复：安全的页面切换
    if (!mounted) return;
    
    setState(() {
      _currentIndex = index;
    });
    
    // 🔥 修复：延迟初始化媒体，避免竞争条件
    Future.microtask(() {
      if (mounted) {
        _initializeMedia();
      }
    });
  }

  void _showActionMenu() {
    final currentMessage = widget.mediaMessages[_currentIndex];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 手柄
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 菜单项
              ListTile(
                leading: Icon(Icons.save_alt, color: AppTheme.primaryColor),
                title: Text(LocalizationHelper.of(context).saveToLocal),
                onTap: () {
                  Navigator.pop(context);
                  _saveToLocal(currentMessage);
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: AppTheme.primaryColor),
                title: Text(LocalizationHelper.of(context).share),
                onTap: () {
                  Navigator.pop(context);
                  _shareToSystem(currentMessage);
                },
              ),
              if (currentMessage['fileType'] == 'image' || currentMessage['fileType'] == 'video')
                ListTile(
                  leading: Icon(Icons.photo_library, color: AppTheme.primaryColor),
                  title: Text(LocalizationHelper.of(context).saveToGallery),
                  onTap: () {
                    Navigator.pop(context);
                    _saveToGallery(currentMessage);
                  },
                ),
              
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveToLocal(Map<String, dynamic> message) async {
    final filePath = _getMediaFilePath(message);
    final fileName = message['fileName'] ?? 'unknown_file';
    
    if (filePath == null || !File(filePath).existsSync()) {
      _showSnackBar('文件不存在');
      return;
    }

    try {
      // 这里可以实现保存到本地的逻辑
      _showSnackBar('保存功能待实现');
    } catch (e) {
      _showSnackBar('保存失败: $e');
    }
  }

  Future<void> _shareToSystem(Map<String, dynamic> message) async {
    final filePath = _getMediaFilePath(message);
    
    if (filePath == null || !File(filePath).existsSync()) {
      _showSnackBar('文件不存在');
      return;
    }

    try {
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      _showSnackBar('分享失败: $e');
    }
  }

  Future<void> _saveToGallery(Map<String, dynamic> message) async {
    final filePath = _getMediaFilePath(message);
    
    if (filePath == null || !File(filePath).existsSync()) {
      _showSnackBar('文件不存在');
      return;
    }

    try {
      await Gal.putImage(filePath);
      _showSnackBar('已保存到相册');
    } catch (e) {
      _showSnackBar('保存到相册失败: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleUI,
        onLongPress: _showActionMenu,
        child: Stack(
          children: [
            // 主要内容区域
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.mediaMessages.length,
              itemBuilder: (context, index) {
                final message = widget.mediaMessages[index];
                final fileType = message['fileType'];
                
                if (fileType == 'image') {
                  return _buildImageViewer(message);
                } else if (fileType == 'video') {
                  return _buildVideoViewer(message);
                } else {
                  return _buildUnsupportedViewer(message);
                }
              },
            ),
            
            // 顶部UI
            AnimatedBuilder(
              animation: _uiAnimation,
              builder: (context, child) => Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _uiAnimation.value,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black54,
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            widget.mediaMessages[_currentIndex]['fileName'] ?? 'Media',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: _showActionMenu,
                          icon: Icon(Icons.more_vert, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // 底部UI
            AnimatedBuilder(
              animation: _uiAnimation,
              builder: (context, child) => Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _uiAnimation.value,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black54,
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _currentIndex > 0 ? _previousMedia : null,
                          icon: Icon(
                            Icons.skip_previous,
                            color: _currentIndex > 0 ? Colors.white : Colors.white54,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${_currentIndex + 1} / ${widget.mediaMessages.length}',
                            style: TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          onPressed: _currentIndex < widget.mediaMessages.length - 1 ? _nextMedia : null,
                          icon: Icon(
                            Icons.skip_next,
                            color: _currentIndex < widget.mediaMessages.length - 1 ? Colors.white : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageViewer(Map<String, dynamic> message) {
    final filePath = _getMediaFilePath(message);
    
    if (filePath == null || !File(filePath).existsSync()) {
      print('图片查看器错误 - 文件不存在: $filePath');
      return _buildErrorViewer('图片文件不存在');
    }

    return InteractiveViewer(
      maxScale: 5.0,
      minScale: 0.5,
      child: Center(
        child: Image.file(
          File(filePath),
          fit: BoxFit.contain, // 使用原始尺寸，适应屏幕
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  Widget _buildVideoViewer(Map<String, dynamic> message) {
    final filePath = _getMediaFilePath(message);
    
    if (filePath == null || !File(filePath).existsSync()) {
      print('视频查看器错误 - 文件不存在: $filePath');
      return _buildErrorViewer('视频文件不存在');
    }

    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          children: [
            // 🔥 修复：安全的视频播放器
            _videoController != null && _videoController!.value.isInitialized
                ? VideoPlayer(_videoController!)
                : Container(
                    color: Colors.black,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
            
            // 播放控制
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  // 🔥 修复：安全的视频播放控制
                  if (_videoController != null && _videoController!.value.isInitialized && mounted) {
                    setState(() {
                      try {
                        if (_videoController!.value.isPlaying) {
                          _videoController!.pause();
                          _isVideoPlaying = false;
                        } else {
                          _videoController!.play();
                          _isVideoPlaying = true;
                        }
                      } catch (e) {
                        print('视频播放控制错误: $e');
                      }
                    });
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: !_videoController!.value.isPlaying
                    ? Center(
                        child: Icon(
                          Icons.play_circle_filled,
                          color: Colors.white,
                          size: 64,
                        ),
                      )
                    : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupportedViewer(Map<String, dynamic> message) {
    return _buildErrorViewer('不支持的文件类型');
  }

  Widget _buildErrorViewer(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.white54,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            errorMessage,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
} 