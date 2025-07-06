import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart';
import '../providers/group_provider.dart';
import '../theme/app_theme.dart';
import '../utils/localization_helper.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> with TickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  bool _isScanMode = true; // true=扫描模式，false=输入模式
  bool _scannerInitialized = false;
  String? _scannerError;
  
  late AnimationController _animationController;
  late AnimationController _switchAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // 动画控制器
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _switchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    // 检查平台是否支持摄像头扫描
    if (_isScanMode && _isDesktop()) {
      // 在桌面端默认切换到输入模式，因为摄像头扫描可能有问题
      _isScanMode = false;
      print('检测到桌面端，默认使用输入模式');
    }
    
    // 初始化扫描器（如果需要）
    if (_isScanMode) {
      _initializeScanner();
    }
    
    _animationController.forward();
  }

  // 判断是否为桌面端
  bool _isDesktop() {
    if (kIsWeb) {
      return MediaQuery.of(context).size.width >= 800;
    }
    return defaultTargetPlatform == TargetPlatform.macOS ||
           defaultTargetPlatform == TargetPlatform.windows ||
           defaultTargetPlatform == TargetPlatform.linux;
  }

  void _initializeScanner() {
    try {
      print('正在初始化摄像头扫描器...');
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: [BarcodeFormat.qrCode],
      );
      _scannerInitialized = true;
      _scannerError = null;
      print('摄像头扫描器初始化成功');
    } catch (e) {
      print('摄像头扫描器初始化失败: $e');
      _scannerError = '摄像头初始化失败: $e';
      _scannerInitialized = false;
      
      // 如果扫描器初始化失败，自动切换到输入模式
      if (mounted) {
        setState(() {
          _isScanMode = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationHelper.of(context).cameraUnavailableSwitchedToInput),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _switchAnimationController.dispose();
    _scannerController?.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _switchMode() {
    // 如果要切换到扫描模式但在桌面端，显示提示
    if (!_isScanMode && _isDesktop()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationHelper.of(context).desktopCameraUnstableTip),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
    
    setState(() {
      _isScanMode = !_isScanMode;
      
      if (_isScanMode) {
        _initializeScanner();
      } else {
        _scannerController?.dispose();
        _scannerController = null;
        _scannerInitialized = false;
        _scannerError = null;
      }
    });

    _switchAnimationController.forward().then((_) {
      _switchAnimationController.reset();
    });
  }

  Future<void> _handleQrCode(String code) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final success = await groupProvider.joinGroup(code);
      
      if (mounted) {
        if (success) {
          // 成功提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(LocalizationHelper.of(context).joinGroupSuccessExclamation),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // 延迟返回，让用户看到成功提示
          await Future.delayed(const Duration(milliseconds: 1500));
          Navigator.pop(context);
        } else {
          // 失败提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(groupProvider.error ?? LocalizationHelper.of(context).joinGroupFailedGeneric),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationHelper.of(context).operationFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleManualInput() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationHelper.of(context).pleaseEnterInviteCode)),
      );
      return;
    }
    
    if (code.length < 4 || code.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationHelper.of(context).inviteCodeLengthError)),
      );
      return;
    }
    
    await _handleQrCode(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF374151),
              size: 16,
            ),
          ),
        ),
        title: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Text(
                LocalizationHelper.of(context).joinGroup,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
        centerTitle: true,
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 模式切换按钮
                _buildModeToggle(),
                
                const SizedBox(height: 24),
                
                // 主要内容区域
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _isScanMode ? _buildScanMode() : _buildInputMode(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isScanMode) _switchMode();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isScanMode ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isScanMode ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      color: _isScanMode ? Colors.white : const Color(0xFF64748B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      LocalizationHelper.of(context).scanQRCode,
                      style: TextStyle(
                        color: _isScanMode ? Colors.white : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isScanMode) _switchMode();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isScanMode ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: !_isScanMode ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.keyboard_rounded,
                      color: !_isScanMode ? Colors.white : const Color(0xFF64748B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      LocalizationHelper.of(context).enterGroupCode,
                      style: TextStyle(
                        color: !_isScanMode ? Colors.white : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanMode() {
    return Container(
      key: const ValueKey('scan_mode'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // 扫描区域
            Expanded(
              child: Stack(
                children: [
                  // 扫描器或错误显示
                  if (_scannerError != null)
                    // 显示错误状态
                    Container(
                      color: const Color(0xFFF8FAFC),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
              LocalizationHelper.of(context).cameraUnavailable,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                _isDesktop() 
                                  ? LocalizationHelper.of(context).desktopInputModeRecommended
                                  : LocalizationHelper.of(context).checkCameraPermissions,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isScanMode = false;
                                });
                              },
                              icon: const Icon(Icons.keyboard_rounded),
                              label: Text(LocalizationHelper.of(context).switchToInput),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_scannerController != null && _scannerInitialized)
                    // 显示扫描器
                    MobileScanner(
                      controller: _scannerController!,
                      onDetect: (capture) {
                        if (_isProcessing) return;
                        
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final code = barcodes.first.rawValue;
                          if (code != null && code.isNotEmpty) {
                            print('扫描到二维码: $code');
                            _handleQrCode(code);
                          }
                        }
                      },
                      onScannerStarted: (MobileScannerArguments? arguments) {
                        print('摄像头扫描器已启动');
                      },
                      errorBuilder: (context, error, child) {
                        print('摄像头扫描器错误: $error');
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _scannerError = error.toString();
                              _scannerInitialized = false;
                            });
                          }
                        });
                        return Container(
                          color: Colors.black,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  LocalizationHelper.of(context).cameraStartupFailed,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  else
                    // 显示加载状态
                    Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: Colors.white),
                            const SizedBox(height: 16),
                            Text(
                              LocalizationHelper.of(context).startingCamera,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // 扫描框（只在扫描器正常工作时显示）
                  if (_scannerController != null && _scannerInitialized && _scannerError == null)
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            // 四个角的装饰
                            ...List.generate(4, (index) {
                              final positions = [
                                {'top': -1.0, 'left': -1.0}, // 左上
                                {'top': -1.0, 'right': -1.0}, // 右上
                                {'bottom': -1.0, 'left': -1.0}, // 左下
                                {'bottom': -1.0, 'right': -1.0}, // 右下
                              ];
                              return Positioned(
                                top: positions[index]['top'],
                                left: positions[index]['left'],
                                right: positions[index]['right'],
                                bottom: positions[index]['bottom'],
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  
                  // 加载状态覆盖层
                  if (_isProcessing)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Colors.white),
                            const SizedBox(height: 16),
                            Text(
                              LocalizationHelper.of(context).joiningGroup,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // 提示文字
            Container(
              padding: const EdgeInsets.all(20),
              child: Text(
                _scannerError != null 
                  ? LocalizationHelper.of(context).switchToInputModeOrCheckPermissions
                  : LocalizationHelper.of(context).placeQRInScanFrame,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputMode() {
    return Container(
      key: const ValueKey('input_mode'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 图标
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.vpn_key_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            LocalizationHelper.of(context).enterGroupCode,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            LocalizationHelper.of(context).enterInviteCodeHint,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 输入框
          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: LocalizationHelper.of(context).inviteCodePlaceholder,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.normal,
                letterSpacing: 2,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              fillColor: const Color(0xFFF8FAFC),
              filled: true,
              counterText: '',
            ),
            maxLength: 20,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _handleManualInput(),
          ),
          
          const SizedBox(height: 24),
          
          // 加入按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleManualInput,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      LocalizationHelper.of(context).joinGroup,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          
          const Spacer(),
        ],
      ),
    );
  }
} 