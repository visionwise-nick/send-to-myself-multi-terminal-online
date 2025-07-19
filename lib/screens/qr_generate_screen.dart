import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../providers/group_provider.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../utils/localization_helper.dart';

class QrGenerateScreen extends StatefulWidget {
  final Map<String, dynamic>? group;
  
  const QrGenerateScreen({super.key, this.group});

  @override
  State<QrGenerateScreen> createState() => _QrGenerateScreenState();
}

class _QrGenerateScreenState extends State<QrGenerateScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _result;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _generateQRCode();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _generateQRCode() async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      
      // 🔥 修复：使用传入的群组或当前群组
      Map<String, dynamic>? targetGroup;
      if (widget.group != null) {
        targetGroup = widget.group;
        print('🔧 使用传入的群组: ${targetGroup!['name']}');
      } else {
        targetGroup = groupProvider.currentGroup;
        print('🔧 使用当前群组: ${targetGroup?['name']}');
      }
      
      if (targetGroup == null) {
        throw Exception(LocalizationHelper.of(context).noGroupInfo);
      }
      
      // 🔥 修复：如果传入了特定群组，先设置为当前群组
      if (widget.group != null && groupProvider.currentGroup?['id'] != targetGroup['id']) {
        print('🔧 临时切换当前群组以生成二维码: ${targetGroup['name']}');
        await groupProvider.setCurrentGroup(targetGroup);
      }
      
      // 为指定群组生成邀请码
      final result = await groupProvider.generateInviteCode();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _result = result;
        });

        if (result != null && result['success'] == true) {
          _animationController.forward();
        } else {
          setState(() {
            _errorMessage = result?['message'] ?? LocalizationHelper.of(context).generateFailed;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  String _formatDateTime(String? dateTimeStr) {
                    return TimeUtils.formatExpirationTime(dateTimeStr, context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(LocalizationHelper.of(context).deviceJoinCode),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isLoading && _result != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _result = null;
                  _errorMessage = '';
                });
                _generateQRCode();
              },
              tooltip: LocalizationHelper.of(context).regenerate,
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading 
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty 
            ? _buildErrorState()
            : _buildSuccessState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            LocalizationHelper.of(context).generatingJoinCode,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              LocalizationHelper.of(context).generateFailed,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = '';
                });
                _generateQRCode();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(LocalizationHelper.of(context).retry),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    final joinCode = _result?['joinCode']?.toString() ?? '';
    final groupName = _result?['groupName']?.toString() ?? '';
    final expiresAt = _result?['expiresAt']?.toString() ?? '';
    final groupId = _result?['groupId']?.toString() ?? '';
    final inviterDeviceId = _result?['inviterDeviceId']?.toString() ?? '';
    
    final qrData = {
      'type': 'sendtomyself_group_join',
      'version': '1.0',
      'groupId': groupId,
      'groupName': groupName,
      'joinCode': joinCode,
      'inviterDeviceId': inviterDeviceId,
      'expiresAt': expiresAt,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    final qrDataString = jsonEncode(qrData);
    print('生成的二维码数据: $qrDataString');
    print('加入码长度: ${joinCode.length}');
    print('加入码内容: $joinCode');
    print('邀请者设备ID: $inviterDeviceId');

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // 标题区域
            Text(
              LocalizationHelper.of(context).scanDeviceJoinOtherDevices,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            if (groupName.isNotEmpty)
              Text(
                '${LocalizationHelper.of(context).groupPrefix}$groupName',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            
            const SizedBox(height: 40),
            
            // 二维码容器
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '${LocalizationHelper.of(context).joinGroup}: $groupName',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${LocalizationHelper.of(context).expiresIn} ${_formatDateTime(expiresAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // 二维码
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: QrImageView(
                        data: qrDataString,
                        version: QrVersions.auto,
                        size: 220,
                        gapless: false,
                        embeddedImage: const AssetImage('assets/images/logo.png'),
                        embeddedImageStyle: const QrEmbeddedImageStyle(
                          size: Size(40, 40),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 加入码
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  Text(
                    LocalizationHelper.of(context).joinCode,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        joinCode,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: joinCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(LocalizationHelper.of(context).copied),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 