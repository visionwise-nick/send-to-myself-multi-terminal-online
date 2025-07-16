import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/logout_dialog.dart';
import 'subscription_screen.dart';
import 'package:send_to_myself/l10n/generated/app_localizations.dart';

const String _logoutConfirmation = '退出当前设备';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSubscriptionSection(context),
            const SizedBox(height: 16),
            _buildDeviceInfoSection(context),
            const SizedBox(height: 16),
            _buildAboutSection(context),
            const SizedBox(height: 16),
            _buildLogoutSection(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.subscriptionManagement,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          Consumer<SubscriptionProvider>(
            builder: (context, subscriptionProvider, child) {
              final subscription = subscriptionProvider.currentSubscription;
              
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: subscriptionProvider.getSubscriptionStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.card_membership,
                        color: subscriptionProvider.getSubscriptionStatusColor(),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      l10n.currentSubscription,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    subtitle: Text(
                      subscriptionProvider.getSubscriptionStatusText(),
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.textTertiaryColor,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionScreen(),
                        ),
                      );
                    },
                  ),
                  if (subscription.plan.name != 'free') ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.devices,
                            color: AppTheme.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '支持 ${subscription.maxGroupMembers} 台设备群组',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.deviceInfo,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final deviceInfo = authProvider.deviceInfo;
              
              return Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.device_hub,
                    title: l10n.deviceName,
                    subtitle: deviceInfo?['name'] ?? l10n.unknownDevice,
                  ),
                  _buildInfoTile(
                    icon: Icons.phone_android,
                    title: l10n.deviceType,
                    subtitle: '${deviceInfo?['platform'] ?? l10n.unknown} ${deviceInfo?['model'] ?? ''}',
                  ),
                  _buildInfoTile(
                    icon: Icons.fingerprint,
                    title: l10n.deviceId,
                    subtitle: deviceInfo?['deviceId']?.substring(0, 8) ?? l10n.unknown,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '关于应用',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          _buildInfoTile(
            icon: Icons.apps,
            title: '应用名称',
            subtitle: 'Send To Myself',
          ),
          _buildInfoTile(
            icon: Icons.info,
            title: '版本号',
            subtitle: '1.1.0',
          ),
          _buildInfoTile(
            icon: Icons.description,
            title: '应用描述',
            subtitle: '跨设备文件共享和消息记忆助手',
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.logout,
            color: Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          l10n.logout,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.red,
          ),
        ),
        subtitle: const Text(
          _logoutConfirmation,
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        onTap: () {
          LogoutDialog.showLogoutConfirmDialog(context);
        },
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.textSecondaryColor,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textSecondaryColor,
        ),
      ),
    );
  }
} 