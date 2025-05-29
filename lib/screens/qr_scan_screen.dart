import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_theme.dart';
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
        print('扫描到二维码: $code');
        
        String? joinCode;
        String? groupId;
        
        try {
          // 🔥 按照API文档解析JSON格式的二维码
          final Map<String, dynamic> data = jsonDecode(code);
          print('解析JSON成功: $data');
          
          // 🔥 严格按照API文档验证二维码格式
          if (data['type'] == 'sendtomyself_group_join' && 
              data['version'] == '1.0' &&
              data.containsKey('groupId') &&
              data.containsKey('joinCode') && 
              data.containsKey('expiresAt') &&
              data['joinCode'] != null) {
            
            joinCode = data['joinCode'].toString();
            groupId = data['groupId']?.toString();
            
            // 🔥 检查二维码是否过期
            final expiresAt = data['expiresAt']?.toString();
            if (expiresAt != null) {
              try {
                final expireTime = DateTime.parse(expiresAt);
                if (DateTime.now().isAfter(expireTime)) {
                  print('二维码已过期: $expiresAt');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('邀请码已过期，请重新获取'),
                        backgroundColor: AppTheme.errorColor,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                  return;
                }
              } catch (e) {
                print('解析过期时间失败: $e');
              }
            }
            
            print('从JSON中提取加入码: $joinCode, 群组ID: $groupId');
          } else {
            print('二维码格式验证失败: 缺少必需字段或版本不匹配');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('无效的群组邀请二维码格式'),
                  backgroundColor: AppTheme.errorColor,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            return;
          }
        } catch (e) {
          print('JSON解析失败，尝试直接使用原始码: $e');
          // 🔥 如果不是JSON格式，直接使用原始码作为加入码（向后兼容）
          joinCode = code;
          print('直接使用原始码作为加入码: $joinCode');
        }
        
        // 🔥 验证加入码格式 - 根据后端要求支持4-20位
        if (joinCode != null && joinCode.isNotEmpty && joinCode.length >= 4 && joinCode.length <= 20) {
          print('准备加入群组，加入码: $joinCode, 群组ID: $groupId');
          _joinGroup(joinCode, groupId: groupId);
          break;
        } else {
          print('无效的加入码格式: $joinCode');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('无效的加入码格式，加入码长度应为4-20位'),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _joinGroup(String code, {String? groupId}) async {
    if (_isJoining) return;

    setState(() {
      _isJoining = true;
    });

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      
      // 🔥 传递groupId参数给加入方法进行额外验证
      final result = await groupProvider.joinGroup(code, groupId: groupId);

      if (mounted) {
        Navigator.of(context).pop();
        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('成功加入群组'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final errorMessage = groupProvider.error ?? '加入失败，请检查加入码';
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
            content: Text('加入失败: $e'),
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
        title: const Text('输入加入码'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '加入码（4-20位）',
            counterText: '',
          ),
          maxLength: 20,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = controller.text.trim();
              if (code.length >= 4 && code.length <= 20) {
                Navigator.pop(context);
                _joinGroup(code);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('加入码长度必须在4-20位之间'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('加入'),
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
        title: const Text('扫描二维码'),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_rounded),
            onPressed: _showManualInputDialog,
            tooltip: '手动输入',
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
            tooltip: '闪光灯',
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
                child: const Text(
                  '将二维码置于框内进行扫描',
                  style: TextStyle(
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
                    const Text(
                      '正在加入群组...',
                      style: TextStyle(
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