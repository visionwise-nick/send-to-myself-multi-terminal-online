import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'package:send_to_myself/l10n/generated/app_localizations.dart';

const String _copyright = '© 2023 Send To Myself';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final deviceInfo = authProvider.deviceInfo;
    final isSmallScreen = AppTheme.isSmallScreen(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: EdgeInsets.all(AppTheme.getPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settings,
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          
          // 设备信息卡片
          if (deviceInfo != null)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      l10n.deviceInfo,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 设备信息列表
                    _buildInfoRow(l10n.deviceName, deviceInfo['name'] ?? l10n.unknown),
                    _buildInfoRow(l10n.deviceType, deviceInfo['type'] ?? l10n.unknown),
                    _buildInfoRow(l10n.platform, deviceInfo['platform'] ?? l10n.unknown),
                    _buildInfoRow(l10n.deviceId, deviceInfo['deviceId'] ?? l10n.unknown),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // 设置列表
          Expanded(
            child: ListView(
              children: [
                // 应用主题设置（占位）
                _buildSettingItem(
                  context,
                  icon: Icons.color_lens,
                  title: l10n.appTheme,
                  subtitle: l10n.defaultTheme,
                  onTap: () {
                    _showComingSoonDialog(context);
                  },
                ),
                
                // 通知设置（占位）
                _buildSettingItem(
                  context,
                  icon: Icons.notifications,
                  title: l10n.notificationSettings,
                  subtitle: l10n.enabled,
                  onTap: () {
                    _showComingSoonDialog(context);
                  },
                ),
                
                // 关于信息（占位）
                _buildSettingItem(
                  context,
                  icon: Icons.info_outline,
                  title: l10n.aboutApp,
                  subtitle: l10n.version,
                  onTap: () {
                    _showComingSoonDialog(context);
                  },
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // 退出登录按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showLogoutDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: AppTheme.errorColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(l10n.logout),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 版权信息
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      _copyright,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建设置项
  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primaryColor,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
      ),
      onTap: onTap,
    );
  }
  
  // 显示功能即将上线对话框
  void _showComingSoonDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.comingSoon),
        content: Text(l10n.featureComingSoon),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
  
  // 显示退出登录确认对话框
  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
} 