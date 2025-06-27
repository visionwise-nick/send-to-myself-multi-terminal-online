import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/localization_helper.dart';

class DeviceGroupsTab extends StatelessWidget {
  const DeviceGroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final groups = authProvider.groups;
        final isLoading = authProvider.isLoading;
        final bool isSmallScreen = AppTheme.isSmallScreen(context);
        
        if (isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (groups == null || groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.devices_other,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  LocalizationHelper.of(context).noDeviceGroups,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LocalizationHelper.of(context).scanQRToJoin,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          );
        }
        
        return Padding(
          padding: EdgeInsets.all(AppTheme.getPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Text(
                      LocalizationHelper.of(context).myDeviceGroups,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${groups.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 设备群组列表
              Expanded(
                child: ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/home/device-group/${group['id']}',
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 群组名称和设备数量
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      group['name'] ?? LocalizationHelper.of(context).unnamedGroup,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      LocalizationHelper.of(context).deviceCount(group['deviceCount'] ?? 0),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // 分割线
                              Divider(color: Colors.grey.shade200),
                              
                              const SizedBox(height: 8),
                              
                              // 群组详情
                              Row(
                                children: [
                                  // 群组图标
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.device_hub,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 12),
                                  
                                  // 群组信息
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          group['isOwner'] == true 
                                              ? LocalizationHelper.of(context).youAreOwner
                                              : LocalizationHelper.of(context).member,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: group['isOwner'] == true
                                                ? AppTheme.primaryColor
                                                : Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${LocalizationHelper.of(context).createdOn}: ${_formatDate(group['createdAt'], LocalizationHelper.of(context).unknownDate)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // 按钮
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios, size: 18),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/home/device-group/${group['id']}',
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 格式化日期
  String _formatDate(dynamic date, String unknownText) {
    if (date == null) return unknownText;
    
    try {
      if (date is String) {
        // 解析时间并转换为本地时间
        DateTime dateTime = DateTime.parse(date);
        if (!date.contains('Z') && !date.contains('+')) {
          // 如果没有时区信息，假设是UTC时间
          dateTime = DateTime.parse(date + 'Z');
        }
        final localTime = dateTime.toLocal();
        return '${localTime.year}-${localTime.month.toString().padLeft(2, '0')}-${localTime.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      print('解析日期失败: $e, 原始日期: $date');
      return unknownText;
    }
    
    return unknownText;
  }
} 