import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/background_share_service.dart';
import '../utils/localization_helper.dart';

class ShareStatusScreen extends StatefulWidget {
  const ShareStatusScreen({super.key});

  @override
  State<ShareStatusScreen> createState() => _ShareStatusScreenState();
}

class _ShareStatusScreenState extends State<ShareStatusScreen> 
    with SingleTickerProviderStateMixin {
  
  String _status = '';
  String _detail = '';
  bool _isSuccess = false;
  bool _isComplete = false;
  late AnimationController _animationController;
  Timer? _closeTimer;
  
  // 本地化文本缓存
  String _processingText = '';
  String _shareSuccessfulText = '';
  String _shareFailedText = '';
  String _shareExceptionText = '';
  String _contentSentText = '';
  String _tryAgainText = '';
  String _processingErrorText = '';
  bool _localizedTextsInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_localizedTextsInitialized) {
      _initializeLocalizedTexts();
      _localizedTextsInitialized = true;
      // 初始化本地化文本后开始处理分享
      _listenToShareStatus();
    }
  }

  void _initializeLocalizedTexts() {
    final l10n = LocalizationHelper.of(context);
    _processingText = l10n.preparingToSendFiles;
    _shareSuccessfulText = l10n.shareSuccess;
    _shareFailedText = l10n.shareFailed;
    _shareExceptionText = l10n.shareException;
    _contentSentText = l10n.contentSentToGroup;
    _tryAgainText = l10n.pleaseTryAgainLater;
    _processingErrorText = l10n.processing;
    
    // 设置初始状态
    setState(() {
      _status = _processingText;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _closeTimer?.cancel();
    super.dispose();
  }

  void _listenToShareStatus() {
    // 实际处理分享逻辑
    _processShare();
  }
  
  Future<void> _processShare() async {
    try {
      // 开始处理分享
      final success = await BackgroundShareService.handleShareIntent(
        onProgressUpdate: (status, detail) {
          if (mounted) {
            setState(() {
              _status = status;
              _detail = detail;
              
              // 只有在真正完成时才标记为完成（检查特定的完成信息）
              // 排除单个文件成功的状态（例如"第1个文件发送成功"），只有总体完成时才关闭
              if ((status.contains('所有文件发送完成') || status.contains('部分文件发送完成') || 
                   status.contains('所有文件发送失败') || status.contains('分享失败') ||
                   status.contains('All files sent') || status.contains('files sent to') ||
                   status.contains('Text sent successfully') || status.contains('Share failed') ||
                   (status.contains('文件发送成功！') && !status.contains('第') && !status.contains('个文件发送成功'))) &&
                  !status.contains('等待服务器处理') && !status.contains('Waiting for server')) {
                _isComplete = true;
                _isSuccess = status.contains('✅') && (status.contains('所有文件发送完成') || 
                             status.contains('All files sent') || status.contains('Text sent successfully') ||
                             (status.contains('文件发送成功！') && !status.contains('第')));
                _animationController.stop();
                
                // 分享完成后，给用户足够时间查看结果，延长到5秒
                _closeTimer = Timer(Duration(milliseconds: 5000), () {
                  _finishShare();
                });
              }
            });
          }
        },
      );
      
      // 如果没有通过回调更新状态，手动更新最终状态
      if (mounted && !_isComplete) {
        setState(() {
          _status = success ? _shareSuccessfulText : _shareFailedText;
          _detail = success ? _contentSentText : _tryAgainText;
          _isSuccess = success;
          _isComplete = true;
        });
        _animationController.stop();
        
        _closeTimer = Timer(Duration(milliseconds: 5000), () {
          _finishShare();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = _shareExceptionText;
          _detail = '${_processingErrorText}: $e';
          _isSuccess = false;
          _isComplete = true;
        });
        _animationController.stop();
        
        _closeTimer = Timer(Duration(milliseconds: 5000), () {
          _finishShare();
        });
      }
    }
  }

  Future<void> _finishShare() async {
    try {
      const platform = MethodChannel('com.example.send_to_myself/share');
      await platform.invokeMethod('finishShare');
    } catch (e) {
      print('Failed to close application: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 状态图标
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(bottom: 24),
              child: _isComplete
                  ? Icon(
                      _isSuccess ? Icons.check_circle : Icons.error_outline,
                      size: 80,
                      color: _isSuccess ? Colors.green : Colors.red,
                    )
                  : AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _animationController.value * 2 * 3.14159,
                          child: Icon(
                            Icons.sync,
                            size: 80,
                            color: Colors.blue,
                          ),
                        );
                      },
                    ),
            ),
            
            // 状态文本
            Text(
              _status,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (_detail.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _detail,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            const SizedBox(height: 40),
            
            // Send To Myself 标识
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.share,
                  size: 20,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Send To Myself',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 