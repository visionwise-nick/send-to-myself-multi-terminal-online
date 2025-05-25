import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_theme.dart';
import '../screens/group_management_screen.dart';
import '../screens/qr_scan_screen.dart';
import '../screens/qr_generate_screen.dart';
import '../screens/join_group_screen.dart';

class GroupSelector extends StatelessWidget {
  const GroupSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        final currentGroup = groupProvider.currentGroup;
        final groups = groupProvider.groups;
        
        if (currentGroup == null) {
          return _buildNoGroupWidget(context);
        }
        
        return Row(
          children: [
            // 群组选择器主体
            Flexible(
              child: GestureDetector(
                onTap: () => _showGroupSelector(context, groupProvider),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showGroupSelector(context, groupProvider),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          // 群组图标 - 简化
                          Icon(
                            Icons.group,
                            size: 16, // 减小图标
                            color: AppTheme.primaryColor,
                          ),
                          
                          const SizedBox(width: 6), // 减小间距
                          
                          // 群组名称和二维码按钮
                          Expanded(
                            child: Row(
                              children: [
                                // 群组名称
                                Flexible(
                                  child: Text(
                                    currentGroup['name'] ?? '未命名群组',
                                    style: AppTheme.titleStyle.copyWith(
                                      color: AppTheme.primaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                
                                const SizedBox(width: 6), // 二维码和群组名的间距
                                
                                // 二维码入口 - 紧挨着群组名
                                GestureDetector(
                                  onTap: () => _showQrGenerate(context, currentGroup),
                                  child: Container(
                                    width: 20, // 进一步减小
                                    height: 20,
                                    child: Icon(
                                      Icons.qr_code,
                                      color: AppTheme.textSecondaryColor,
                                      size: 14, // 减小图标
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // 下拉箭头 - 替换重复的二维码按钮
            Icon(
              Icons.expand_more,
              size: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildNoGroupWidget(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showGroupSelector(context, Provider.of<GroupProvider>(context, listen: false)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '点击加入群组',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeTitle,
                      fontWeight: AppTheme.fontWeightMedium,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  void _showGroupSelector(BuildContext context, GroupProvider groupProvider) {
    final groups = groupProvider.groups;
    if (groups == null || groups.isEmpty) {
      _showGroupManagement(context, null);
      return;
    }
    
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
            // 顶部指示器
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // 标题栏
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    '选择群组',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showGroupManagement(context, groupProvider.currentGroup),
                    icon: const Icon(Icons.settings),
                    tooltip: '群组管理',
                  ),
                ],
              ),
            ),
            
            // 群组列表
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final isSelected = group['id'] == groupProvider.currentGroup?['id'];
                  
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? AppTheme.primaryColor 
                          : AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.group,
                        color: isSelected ? Colors.white : AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      group['name'] ?? '未命名群组',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      '${group['deviceCount'] ?? 0} 台设备',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    trailing: isSelected 
                      ? Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryColor,
                        )
                      : null,
                    onTap: () {
                      if (!isSelected) {
                        groupProvider.setCurrentGroup(group);
                      }
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            
            // 底部按钮区域
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCreateGroupDialog(context);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('创建群组'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showJoinGroupOptions(context);
                      },
                      icon: const Icon(Icons.group_add),
                      label: const Text('加入群组'),
                    ),
                  ),
                ],
              ),
            ),
            
            // 底部安全区域
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
  
  void _showGroupManagement(BuildContext context, Map<String, dynamic>? currentGroup) {
    if (currentGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一个群组')),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupManagementScreen(group: currentGroup),
      ),
    );
  }
  
  void _showCreateGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建新群组'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '群组名称',
                hintText: '请输入群组名称',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '群组描述（可选）',
                hintText: '请输入群组描述',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入群组名称')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              final groupProvider = Provider.of<GroupProvider>(context, listen: false);
              final success = await groupProvider.createGroup(
                name,
                description: descriptionController.text.trim(),
              );
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('群组"$name"创建成功')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(groupProvider.error ?? '创建群组失败')),
                );
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
  
  void _showJoinGroupOptions(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const JoinGroupScreen(),
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
  

  

      
    void _showQrGenerate(BuildContext context, Map<String, dynamic> group) {
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
    
    void _showQrScan(BuildContext context) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const QrScanScreen(),
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
} 