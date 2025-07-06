import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../utils/localization_helper.dart';
import 'qr_generate_screen.dart';
import 'subscription_screen.dart';

class GroupManagementScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  
  const GroupManagementScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> 
    with TickerProviderStateMixin {
  List<Map<String, dynamic>>? _members;
  Map<String, dynamic>? _groupDetails;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // 🔥 新增：可变的群组数据
  late Map<String, dynamic> _currentGroupData;
  
  @override
  void initState() {
    super.initState();
    // 🔥 初始化可变的群组数据
    _currentGroupData = Map<String, dynamic>.from(widget.group);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _loadGroupDetails();
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadGroupDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      
      // 获取群组详情
      final groupDetails = await groupProvider.getGroupDetails(_currentGroupData['id']);
      
      // 获取群组成员
      final members = await groupProvider.getGroupMembers(_currentGroupData['id']);
      
      if (mounted) {
        setState(() {
          _groupDetails = groupDetails;
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final l10n = LocalizationHelper.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.loadGroupInfoFailed}: $e')),
        );
      }
    }
  }
  
  void _showRenameGroupDialog() {
    final controller = TextEditingController(text: _currentGroupData['name']);
    final l10n = LocalizationHelper.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameGroup),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.groupName,
            hintText: l10n.enterNewGroupName,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                final l10n = LocalizationHelper.of(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.groupNameHint)),
                );
                return;
              }
              
              Navigator.pop(context); // 关闭重命名对话框
              
              // 🔥 修复：添加try-catch确保加载对话框总是被关闭
              BuildContext? dialogContext;
              
              try {
                print('🔥 UI: 准备显示加载对话框...');
                
                // 显示加载提示并保存context
                final l10n = LocalizationHelper.of(context);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    dialogContext = context; // 保存对话框context
                    return AlertDialog(
                      content: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text(l10n.renamingGroup),
                        ],
                      ),
                    );
                  },
                );
                print('🔥 UI: 加载对话框已显示');
                
                print('🔥 UI: 调用GroupProvider.renameGroup...');
                final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                final success = await groupProvider.renameGroup(_currentGroupData['id'], newName);
                print('🔥 UI: GroupProvider.renameGroup返回: $success');
                
                // 🔥 关键修复：安全关闭对话框
                if (dialogContext != null && mounted) {
                  Navigator.of(dialogContext!).pop();
                  print('🔥 UI: 加载对话框已关闭');
                  
                  if (success) {
                    print('🔥 UI: 显示成功提示');
                    // 🔥 新增：更新本地群组数据
                    setState(() {
                      _currentGroupData['name'] = newName;
                    });
                    print('🔥 UI: 本地群组名称已更新为: $newName');
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.groupRenameSuccess),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    print('🔥 UI: 显示失败提示');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.groupRenameFailed),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                print('🔥 UI: 捕获异常: $e');
                
                // 🔥 安全关闭对话框：使用保存的context
                if (dialogContext != null) {
                  try {
                    Navigator.of(dialogContext!).pop();
                    print('🔥 UI: 异常处理 - 加载对话框已关闭');
                  } catch (navError) {
                    print('🔥 UI: Navigator操作失败: $navError');
                  }
                }
                
                if (mounted) {
                  final l10n = LocalizationHelper.of(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.renameFailed}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
  
  void _showLeaveGroupDialog() {
    final l10n = LocalizationHelper.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveGroup),
        content: Text(l10n.groupLeaveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLeaveGroup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.leaveGroup),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performLeaveGroup() async {
    // 显示加载状态
    setState(() {
      _isLoading = true;
    });
    
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final success = await groupProvider.leaveGroup(_currentGroupData['id']);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (success) {
          Navigator.pop(context); // 返回上一页
          final l10n = LocalizationHelper.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.groupLeaveSuccess),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final l10n = LocalizationHelper.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(groupProvider.error ?? l10n.groupLeaveFailed),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final l10n = LocalizationHelper.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.groupLeaveFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showRemoveDeviceDialog(Map<String, dynamic> device) {
    final l10n = LocalizationHelper.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeDevice),
        content: Text('${LocalizationHelper.of(context).removeDevice}「${device['name'] ?? LocalizationHelper.of(context).unknownDevice}」?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performRemoveDevice(device);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.removeDevice),
          ),
        ],
      ),
    );
  }
  
  Future<void> _performRemoveDevice(Map<String, dynamic> device) async {
    // 显示加载状态
    setState(() {
      _isLoading = true;
    });
    
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final success = await groupProvider.removeDevice(
        _currentGroupData['id'], 
        device['deviceId'] ?? device['id']
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (success) {
          final l10n = LocalizationHelper.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationHelper.of(context).deviceRemoved),
              backgroundColor: Colors.green,
            ),
          );
          // 立即刷新页面
          await _loadGroupDetails();
        } else {
          final l10n = LocalizationHelper.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(groupProvider.error ?? LocalizationHelper.of(context).error),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final l10n = LocalizationHelper.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationHelper.of(context).error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showRenameDeviceDialog() {
    final controller = TextEditingController();
    final l10n = LocalizationHelper.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deviceName),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.deviceName,
            hintText: l10n.deviceName,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.deviceName)),
                );
                return;
              }
              
              Navigator.pop(context); // 关闭重命名对话框
              
              // 🔥 修复：添加try-catch确保加载对话框总是被关闭
              BuildContext? dialogContext;
              
              try {
                // 显示加载提示并保存context
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    dialogContext = context;
                    return AlertDialog(
                      content: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text(l10n.loading),
                        ],
                      ),
                    );
                  },
                );
                
                final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                final success = await groupProvider.renameDevice(newName);
                
                // 🔥 关键修复：安全关闭对话框
                if (dialogContext != null && mounted) {
                  Navigator.of(dialogContext!).pop();
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.success),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.error),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                // 🔥 安全关闭对话框：使用保存的context
                if (dialogContext != null) {
                  try {
                    Navigator.of(dialogContext!).pop();
                  } catch (navError) {
                    print('🔥 设备重命名Navigator操作失败: $navError');
                  }
                }
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.error}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
  
  void _showQrGenerate() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const QrGenerateScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_currentGroupData['name'] ?? LocalizationHelper.of(context).groupManagement),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _loadGroupDetails,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGroupInfoCard(),
                      const SizedBox(height: 20),
                      _buildMembersSection(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  
  Widget _buildGroupInfoCard() {
    final group = _groupDetails ?? _currentGroupData;
    final deviceCount = group['deviceCount'] ?? (_members?.length ?? 0);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.group,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group['name'] ?? LocalizationHelper.of(context).unnamedGroup,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (group['description'] != null && group['description'].isNotEmpty)
                      Text(
                        group['description'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Consumer<SubscriptionProvider>(
                  builder: (context, subscriptionProvider, child) {
                    final maxMembers = subscriptionProvider.maxGroupMembers;
                    return _buildInfoItem(
                  icon: Icons.people,
                  label: LocalizationHelper.of(context).groupMembers,
                      value: '$deviceCount / $maxMembers ${LocalizationHelper.of(context).deviceName}',
                    );
                  },
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.schedule,
                  label: LocalizationHelper.of(context).createdOn,
                  value: TimeUtils.formatDateTime(group['createdAt']),
                ),
              ),
            ],
          ),
          
          // 🔥 新增：订阅限制提示
          Consumer<SubscriptionProvider>(
            builder: (context, subscriptionProvider, child) {
              final groupProvider = Provider.of<GroupProvider>(context, listen: false);
              final groupId = _currentGroupData['id'];
              final currentCount = groupProvider.getGroupMemberCount(groupId);
              final maxMembers = subscriptionProvider.maxGroupMembers;
              
              if (currentCount >= maxMembers && maxMembers < 10) {
                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '群组人数已达上限。升级订阅以支持更多设备。',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showUpgradeDialog(subscriptionProvider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '升级',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          const SizedBox(height: 20),
          
          // 操作按钮
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showRenameGroupDialog,
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(LocalizationHelper.of(context).renameGroup),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showQrGenerate,
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: Text(LocalizationHelper.of(context).generateQRCode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMembersSection() {
    if (_members == null || _members!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: AppTheme.textTertiaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                LocalizationHelper.of(context).noDevices,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${LocalizationHelper.of(context).groupMembers} (${_members!.length})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _members!.length,
          itemBuilder: (context, index) {
            final member = _members![index];
            return _buildMemberCard(member, index);
          },
        ),
      ],
    );
  }
  
  Widget _buildMemberCard(Map<String, dynamic> member, int index) {
    final isMe = member['isMe'] == true;
    final isOnline = member['status'] == 'online';
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + index * 50),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showMemberOptions(member),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isMe 
                          ? AppTheme.primaryColor.withOpacity(0.3)
                          : AppTheme.borderColor,
                        width: isMe ? 2 : 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.shadowColor,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // 头像
                        Stack(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isMe 
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : AppTheme.onlineColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  _getDeviceEmoji(member['type']),
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            
                            // 在线状态指示器
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: isOnline ? AppTheme.onlineColor : AppTheme.offlineColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.cardColor, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // 设备信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      member['name'] ?? LocalizationHelper.of(context).unknownDevice,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  
                                  if (isMe)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        LocalizationHelper.of(context).myself,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              
                              const SizedBox(height: 4),
                              
                              Text(
                                '${member['platform']} ${member['model']}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                              
                              const SizedBox(height: 2),
                              
                                            Text(
                '${LocalizationHelper.of(context).deviceConnected} ${TimeUtils.formatDateTime(member['joinedAt'])}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiaryColor,
                ),
              ),
                            ],
                          ),
                        ),
                        
                        // 操作按钮
                        IconButton(
                          onPressed: () => _showMemberOptions(member),
                          icon: const Icon(Icons.more_vert),
                          color: AppTheme.textTertiaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _showMemberOptions(Map<String, dynamic> member) {
    final isMe = member['isMe'] == true;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child:               Column(
                children: [
                  Text(
                    member['name'] ?? LocalizationHelper.of(context).unknownDevice,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 如果是自己的设备，显示重命名选项
                  if (isMe)
                    ListTile(
                      leading: const Icon(Icons.edit, color: Colors.blue),
                      title: Text(LocalizationHelper.of(context).deviceName),
                      onTap: () {
                        Navigator.pop(context);
                        _showRenameDeviceDialog();
                      },
                    ),
                  
                  // 所有设备都显示移除选项
                  ListTile(
                    leading: const Icon(Icons.remove_circle, color: Colors.red),
                    title: Text(
                      LocalizationHelper.of(context).removeDevice,
                      style: const TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showRemoveDeviceDialog(member);
                    },
                  ),
                ],
              ),
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
  
  String _getDeviceEmoji(String? deviceType) {
    switch (deviceType?.toLowerCase()) {
      case 'mobile':
        return '📱';
      case 'desktop':
        return '💻';
      case 'tablet':
        return '📟';
      case 'web':
        return '🌐';
      default:
        return '📱';
    }
  }
  
  // 🔥 新增：显示升级对话框
  void _showUpgradeDialog(SubscriptionProvider subscriptionProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.workspace_premium,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            const Text('升级订阅'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前群组人数已达上限',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '升级订阅计划以解锁更多设备群组功能：',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• 基础版：支持5台设备\n• 专业版：支持10台设备',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ),
              );
            },
            child: Text('查看订阅'),
          ),
        ],
      ),
    );
  }
} 