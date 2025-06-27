import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_theme.dart';
import '../utils/localization_helper.dart';
import 'dart:convert';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> with TickerProviderStateMixin {
  bool _isJoining = false;
  final MobileScannerController _scannerController = MobileScannerController();
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isJoining) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        final code = barcode.rawValue!.trim();
        
        try {
          final Map<String, dynamic> data = jsonDecode(code);
          // 检查是否是群组邀请二维码
          if (data['type'] == 'sendtomyself_group_join' && 
              data.containsKey('joinCode') && 
              data['joinCode'] != null) {
            final joinCode = data['joinCode'].toString();
            if (joinCode.length == 8) {
              _joinGroup(joinCode);
              break;
            }
          }
        } catch (e) {
          // 如果不是JSON格式，检查是否是8位加入码
          if (code.length == 8) {
            _joinGroup(code);
            break;
          }
        }
      }
    }
  }

  Future<void> _joinGroup(String code) async {
    if (_isJoining) return;

    setState(() {
      _isJoining = true;
    });

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final result = await groupProvider.joinGroup(code);

      if (mounted) {
        Navigator.of(context).pop();
        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationHelper.of(context).joinGroupSuccess),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final errorMessage = groupProvider.error ?? LocalizationHelper.of(context).joinGroupFailed;
          print('加入群组失败: $errorMessage');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('加入群组异常: $e');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationHelper.of(context).joinFailed}: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  void _showManualInputDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(LocalizationHelper.of(context).enterJoinCode),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: LocalizationHelper.of(context).joinCodeHint,
            counterText: '',
          ),
          maxLength: 8,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            letterSpacing: 4,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationHelper.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final code = controller.text.trim();
              if (code.length == 8) {
                Navigator.pop(context);
                _joinGroup(code);
              }
            },
            child: Text(LocalizationHelper.of(context).join),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(LocalizationHelper.of(context).scanQRCode),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_rounded),
            onPressed: _showManualInputDialog,
            tooltip: LocalizationHelper.of(context).manualInput,
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _scannerController.torchState,
              builder: (context, state, child) {
                return Icon(
                  state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _scannerController.toggleTorch(),
            tooltip: LocalizationHelper.of(context).flashlight,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 扫描器
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          
          // 扫描框和动画
          Center(
            child: Container(
              width: 250,
              height: 250,
              child: Stack(
                children: [
                  // 扫描框
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                  
                  // 扫描线动画
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _scanAnimation.value * 220,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.primaryColor,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // 四个角的装饰
                  ...List.generate(4, (index) {
                    final isTop = index < 2;
                    final isLeft = index % 2 == 0;
                    
                    return Positioned(
                      top: isTop ? -2 : null,
                      bottom: !isTop ? -2 : null,
                      left: isLeft ? -2 : null,
                      right: !isLeft ? -2 : null,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            top: isTop
                                ? BorderSide(color: AppTheme.primaryColor, width: 4)
                                : BorderSide.none,
                            bottom: !isTop
                                ? BorderSide(color: AppTheme.primaryColor, width: 4)
                                : BorderSide.none,
                            left: isLeft
                                ? BorderSide(color: AppTheme.primaryColor, width: 4)
                                : BorderSide.none,
                            right: !isLeft
                                ? BorderSide(color: AppTheme.primaryColor, width: 4)
                                : BorderSide.none,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          
          // 提示文本
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  LocalizationHelper.of(context).placeQRInFrame,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          
          // 加载层
          if (_isJoining)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocalizationHelper.of(context).joiningGroup,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 