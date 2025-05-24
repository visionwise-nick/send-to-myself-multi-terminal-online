import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LogoutDialog {
  // 显示登出确认对话框
  static Future<void> showLogoutConfirmDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          '退出登录',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '确定要退出登录吗？',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '取消',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              '确定',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true && context.mounted) {
      await _performLogoutWithProgress(context);
    }
  }
  
  // 显示登出进度对话框并执行登出
  static Future<void> _performLogoutWithProgress(BuildContext context) async {
    // 显示进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 16),
            const Text(
              '正在退出登录...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
    
    try {
      // 执行登出
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.logout(showProgress: false);
      
      // 关闭进度对话框
      if (context.mounted) {
        Navigator.of(context).pop();
        
        if (success) {
          _showLogoutSuccessMessage(context, '已成功退出登录');
        } else {
          _showLogoutErrorMessage(context, '退出登录时发生错误');
        }
      }
      
    } catch (e) {
      // 关闭进度对话框
      if (context.mounted) {
        Navigator.of(context).pop();
        _showLogoutErrorMessage(context, '退出登录失败: $e');
      }
    }
  }
  
  // 显示登出成功消息
  static void _showLogoutSuccessMessage(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.onlineColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  // 显示登出错误消息
  static void _showLogoutErrorMessage(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  // 显示被动登出提示（来自其他设备或服务端）
  static void showLogoutNotification(BuildContext context, String message) {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('登录状态已失效'),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 可以在这里跳转到登录页面
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }
} 