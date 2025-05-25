import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import 'qr_generate_screen.dart';

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
  
  @override
  void initState() {
    super.initState();
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
      final groupDetails = await groupProvider.getGroupDetails(widget.group['id']);
      
      // 获取群组成员
      final members = await groupProvider.getGroupMembers(widget.group['id']);
      
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载群组信息失败: $e')),
        );
      }
    }
  }
  
  void _showRenameGroupDialog() {
    final controller = TextEditingController(text: widget.group['name']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名群组'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '群组名称',
            hintText: '请输入新的群组名称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入群组名称')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              // 显示加载提示
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              final groupProvider = Provider.of<GroupProvider>(context, listen: false);
              final success = await groupProvider.renameGroup(widget.group['id'], newName);
              
              // 关闭加载提示
              Navigator.pop(context);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('群组已重命名为"$newName"'),
                    backgroundColor: Colors.green,
                  ),
                );
                // 立即刷新页面
                await _loadGroupDetails();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(groupProvider.error ?? '重命名失败'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出群组'),
        content: Text('确定要退出群组"${widget.group['name']}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // 显示加载提示
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              final groupProvider = Provider.of<GroupProvider>(context, listen: false);
              final success = await groupProvider.leaveGroup(widget.group['id']);
              
              // 关闭加载提示
              Navigator.pop(context);
              
              if (success) {
                Navigator.pop(context); // 返回上一页
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已退出群组'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(groupProvider.error ?? '退出失败'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
  
  void _showRemoveDeviceDialog(Map<String, dynamic> device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除设备'),
        content: Text('确定要将设备"${device['name']}"移除出群组吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // 显示加载提示
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              final groupProvider = Provider.of<GroupProvider>(context, listen: false);
              final success = await groupProvider.removeDevice(
                widget.group['id'], 
                device['deviceId'] ?? device['id']
              );
              
              // 关闭加载提示
              Navigator.pop(context);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已移除设备"${device['name']}"'),
                    backgroundColor: Colors.green,
                  ),
                );
                // 立即刷新页面
                await _loadGroupDetails();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(groupProvider.error ?? '移除失败'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('移除'),
          ),
        ],
      ),
    );
  }
  
  void _showRenameDeviceDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名设备'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '设备名称',
            hintText: '请输入新的设备名称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入设备名称')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              // 显示加载提示
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              final groupProvider = Provider.of<GroupProvider>(context, listen: false);
              final success = await groupProvider.renameDevice(newName);
              
              // 关闭加载提示
              Navigator.pop(context);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('设备已重命名为"$newName"'),
                    backgroundColor: Colors.green,
                  ),
                );
                // 立即刷新页面
                await _loadGroupDetails();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(groupProvider.error ?? '重命名失败'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('确定'),
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
        title: Text(widget.group['name'] ?? '群组管理'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'rename_group':
                  _showRenameGroupDialog();
                  break;
                case 'generate_qr':
                  _showQrGenerate();
                  break;
                case 'leave_group':
                  _showLeaveGroupDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename_group',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('重命名群组'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'generate_qr',
                child: ListTile(
                  leading: Icon(Icons.qr_code_2_rounded, color: Color(0xFF6366F1)),
                  title: Text('生成二维码', style: TextStyle(color: Color(0xFF6366F1))),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'leave_group',
                child: ListTile(
                  leading: Icon(Icons.exit_to_app, color: Colors.red),
                  title: Text('退出群组', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
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
    final group = _groupDetails ?? widget.group;
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
                      group['name'] ?? '未命名群组',
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
                child: _buildInfoItem(
                  icon: Icons.people,
                  label: '成员数量',
                  value: '$deviceCount 台设备',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.schedule,
                  label: '创建时间',
                  value: TimeUtils.formatDateTime(group['createdAt']),
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
                '暂无成员信息',
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
          '群组成员 (${_members!.length})',
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
    final isOwner = member['isOwner'] == true;
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
                  onTap: isMe ? null : () {
                    if (isOwner) return; // 不能操作群主
                    _showMemberOptions(member);
                  },
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
                                      member['name'] ?? '未知设备',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  
                                  if (isOwner)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '群主',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
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
                                        '我',
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
                                '加入于 ${TimeUtils.formatDateTime(member['joinedAt'])}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textTertiaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // 操作按钮
                        if (!isOwner) // 群主无法被操作，包括自己是群主的情况
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
              child: Column(
                children: [
                  Text(
                    member['name'] ?? '未知设备',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 如果是自己的设备，显示重命名选项
                  if (isMe)
                    ListTile(
                      leading: const Icon(Icons.edit, color: Colors.blue),
                      title: const Text('重命名设备'),
                      onTap: () {
                        Navigator.pop(context);
                        _showRenameDeviceDialog();
                      },
                    ),
                  
                  // 如果不是自己的设备，显示移除选项
                  if (!isMe)
                    ListTile(
                      leading: const Icon(Icons.remove_circle, color: Colors.red),
                      title: const Text('移除设备', style: TextStyle(color: Colors.red)),
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
} 