import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/localization_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  bool _isRegistering = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _registerDevice() async {
    setState(() {
      _isRegistering = true;
    });
    
    try {
      await Provider.of<AuthProvider>(context, listen: false).registerDevice();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationHelper.of(context).deviceRegistrationFailed}: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo动画
                    TweenAnimationBuilder<double>(
                      duration: const Duration(seconds: 2),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: Hero(
                            tag: 'app_logo',
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.devices_rounded,
                                size: 60,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // 应用名称
                    Text(
                      LocalizationHelper.of(context).appTitle,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 描述
                    Text(
                      LocalizationHelper.of(context).appDescription,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 80),
                    
                    // 开始使用按钮
                    Container(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isRegistering ? null : _registerDevice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          disabledBackgroundColor: Colors.white.withOpacity(0.6),
                          elevation: 0,
                          side: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isRegistering
                            ? Row(
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
                                  const SizedBox(width: 12),
                                  Text(
                                    LocalizationHelper.of(context).registering,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                LocalizationHelper.of(context).registerDevice,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 说明文本
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.borderColor,
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            LocalizationHelper.of(context).deviceRegistration,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondaryColor,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 