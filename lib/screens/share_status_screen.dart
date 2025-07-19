import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/background_share_service.dart';
import '../services/device_auth_service.dart';
import '../services/local_storage_service.dart';
import '../utils/localization_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  
  // 🔥 新增：APP启动状态相关
  bool _isAppReady = false;
  int _initializationAttempts = 0;
  static const int _maxInitializationAttempts = 10;
  static const Duration _initializationCheckInterval = Duration(seconds: 1);
  
  // 本地化文本缓存
  String _processingText = '';
  String _shareSuccessfulText = '';
  String _shareFailedText = '';
  String _shareExceptionText = '';
  String _contentSentText = '';
  String _tryAgainText = '';
  String _processingErrorText = '';
  String _waitingForAppText = '';
  bool _localizedTextsInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    
    // 🔥 新增：开始APP启动状态检查
    _checkAppReadyStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_localizedTextsInitialized) {
      _initializeLocalizedTexts();
      _localizedTextsInitialized = true;
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
    _waitingForAppText = l10n.waitingForApp;
    
    // 🔥 修改：设置初始状态为等待APP启动
    setState(() {
      _status = _waitingForAppText;
      _detail = l10n.waitingForApp;
    });
  }

  // 🔥 新增：检查APP启动状态
  Future<void> _checkAppReadyStatus() async {
    final l10n = LocalizationHelper.of(context);
    print('🔍 开始检查APP启动状态...');
    
    while (!_isAppReady && _initializationAttempts < _maxInitializationAttempts) {
      _initializationAttempts++;
      
      try {
        // 检查关键服务是否已初始化
        final isReady = await _checkCriticalServicesReady();
        
        if (isReady) {
          print('✅ APP关键服务已就绪，开始处理分享');
          _isAppReady = true;
          
          // 等待额外的稳定时间
          await Future.delayed(Duration(milliseconds: 500));
          
          // 开始处理分享
          if (mounted) {
            _listenToShareStatus();
          }
          return;
        } else {
          print('⏳ APP服务未就绪，等待中... (尝试 $_initializationAttempts/$_maxInitializationAttempts)');
          
          // 更新状态显示
          if (mounted) {
            setState(() {
              _status = _waitingForAppText;
              _detail = '${_waitingForAppText} ($_initializationAttempts/$_maxInitializationAttempts)';
            });
          }
          
          // 等待下一次检查
          await Future.delayed(_initializationCheckInterval);
        }
      } catch (e) {
        print('❌ 检查APP状态时出错: $e');
        await Future.delayed(_initializationCheckInterval);
      }
    }
    
    // 如果达到最大尝试次数仍未就绪，尝试强制处理分享
    if (!_isAppReady) {
      print('⚠️ 达到最大等待时间，强制开始处理分享');
      if (mounted) {
        final l10n = LocalizationHelper.of(context);
        setState(() {
          _status = l10n.appSlowToStart;
          _detail = l10n.tryAgainIfFailed;
        });
        
        // 强制等待更长时间后开始处理
        await Future.delayed(Duration(seconds: 2));
        _listenToShareStatus();
      }
    }
  }

  // 🔥 新增：检查关键服务是否就绪
  Future<bool> _checkCriticalServicesReady() async {
    try {
      // 1. 检查SharedPreferences是否可用
      final prefs = await SharedPreferences.getInstance();
      
      // 2. 检查认证服务是否就绪
      final authService = DeviceAuthService();
      final token = await authService.getAuthToken();
      final serverDeviceId = await authService.getServerDeviceId();
      
      if (token == null || serverDeviceId == null) {
        print('⚠️ 认证信息不完整');
        return false;
      }
      
      // 3. 检查当前群组是否可用
      final currentGroupId = prefs.getString('current_group_id');
      if (currentGroupId == null) {
        print('⚠️ 没有当前群组');
        return false;
      }
      
      // 4. 检查本地存储服务是否可用
      final localStorage = LocalStorageService();
      // 尝试简单操作测试服务是否就绪
      await localStorage.getStorageInfo();
      
      print('✅ 关键服务检查通过');
      return true;
      
    } catch (e) {
      print('❌ 关键服务检查失败: $e');
      return false;
    }
  }

  void _listenToShareStatus() {
    // 实际处理分享逻辑
    _processShare();
  }
  
  Future<void> _processShare() async {
    try {
      final l10n = LocalizationHelper.of(context);
      // 🔥 新增：开始处理前的最后检查
      if (mounted) {
        setState(() {
          _status = _processingText;
          _detail = l10n.processingShare;
        });
      }
      
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
  void dispose() {
    _animationController.dispose();
    _closeTimer?.cancel();
    super.dispose();
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