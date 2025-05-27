import 'package:flutter/material.dart';
import '../models/memory_model.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';

class MemoryCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MemoryCard({
    super.key,
    required this.memory,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.borderColor, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：类型图标、标题、操作按钮
              Row(
                children: [
                  // 类型图标
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getModernIcon(memory.type),
                      size: 18,
                      color: _getTypeColor(),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 标题
                  Expanded(
                    child: Text(
                      memory.title,
                      style: AppTheme.bodyStyle.copyWith(
                        fontWeight: AppTheme.fontWeightMedium,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // 更多操作按钮
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16, color: AppTheme.textSecondaryColor),
                            SizedBox(width: 8),
                            Text('编辑', style: AppTheme.bodyStyle),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: AppTheme.errorColor),
                            SizedBox(width: 8),
                            Text('删除', style: AppTheme.bodyStyle.copyWith(color: AppTheme.errorColor)),
                          ],
                        ),
                      ),
                    ],
                    icon: Icon(Icons.more_vert, size: 16, color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 内容预览
              if (memory.content.isNotEmpty)
                Text(
                  memory.content,
                  style: AppTheme.captionStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              
              // 特定类型的内容展示
              _buildTypeSpecificContent(),
              
              const SizedBox(height: 12),
              
              // 底部：时间和标签
              Row(
                children: [
                  // 时间
                  Text(
                    _formatTime(memory.updatedAt),
                    style: AppTheme.smallStyle,
                  ),
                  
                  const Spacer(),
                  
                  // 标签
                  if (memory.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 4,
                      children: memory.tags.take(2).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          tag,
                          style: AppTheme.smallStyle.copyWith(
                            color: AppTheme.primaryColor,
                            fontSize: 10,
                          ),
                        ),
                      )).toList(),
                    ),
                    SizedBox(width: 8),
                  ],
                  
                  // 类型标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      memory.type.displayName,
                      style: AppTheme.smallStyle.copyWith(
                        color: _getTypeColor(),
                        fontWeight: AppTheme.fontWeightMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSpecificContent() {
    switch (memory.type) {
      case MemoryType.password:
        final data = memory.passwordData;
        if (data != null) {
          return Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '账号: ${data['username']} • 网站: ${data['website']}',
              style: AppTheme.smallStyle.copyWith(
                color: _getTypeColor(),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
        break;
      
      case MemoryType.financial:
        final data = memory.financialData;
        if (data != null) {
          final amount = data['amount'] as double;
          final isIncome = data['isIncome'] as bool;
          return Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '${isIncome ? '+' : '-'}¥${amount.toStringAsFixed(2)}',
              style: AppTheme.bodyStyle.copyWith(
                color: isIncome ? Color(0xFF30D158) : Color(0xFFFF453A),
                fontWeight: AppTheme.fontWeightMedium,
              ),
            ),
          );
        }
        break;
      
      case MemoryType.schedule:
        final data = memory.scheduleData;
        if (data != null) {
          final startTime = DateTime.parse(data['startTime']);
          return Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '${startTime.month}-${startTime.day} ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
              style: AppTheme.smallStyle.copyWith(
                color: _getTypeColor(),
                fontWeight: AppTheme.fontWeightMedium,
              ),
            ),
          );
        }
        break;
      
      case MemoryType.todo:
        final data = memory.todoData;
        if (data != null) {
          final isCompleted = data['isCompleted'] as bool;
          final priority = data['priority'] as String;
          return Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 12,
                  color: isCompleted ? Color(0xFF30D158) : AppTheme.textTertiaryColor,
                ),
                SizedBox(width: 4),
                Text(
                  _getPriorityText(priority),
                  style: AppTheme.smallStyle.copyWith(
                    color: _getPriorityColor(priority),
                    fontWeight: AppTheme.fontWeightMedium,
                  ),
                ),
              ],
            ),
          );
        }
        break;
      
      case MemoryType.url:
        final data = memory.urlData;
        if (data != null) {
          return Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              data['url'] ?? '',
              style: AppTheme.smallStyle.copyWith(
                color: _getTypeColor(),
                decoration: TextDecoration.underline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
        break;
      
      default:
        break;
    }
    
    return SizedBox.shrink();
  }

  IconData _getModernIcon(MemoryType type) {
    switch (type) {
      case MemoryType.text:
        return Icons.notes;
      case MemoryType.password:
        return Icons.security;
      case MemoryType.financial:
        return Icons.account_balance_wallet;
      case MemoryType.schedule:
        return Icons.event;
      case MemoryType.todo:
        return Icons.task_alt;
      case MemoryType.url:
        return Icons.link;
      case MemoryType.image:
        return Icons.photo_library;
      case MemoryType.video:
        return Icons.videocam;
      case MemoryType.document:
        return Icons.description;
    }
  }

  Color _getTypeColor() {
    switch (memory.type) {
      case MemoryType.text:
        return Color(0xFF007AFF);
      case MemoryType.password:
        return Color(0xFFFF453A);
      case MemoryType.financial:
        return Color(0xFF30D158);
      case MemoryType.schedule:
        return Color(0xFFBF5AF2);
      case MemoryType.todo:
        return Color(0xFFFF9F0A);
      case MemoryType.url:
        return Color(0xFF64D2FF);
      case MemoryType.image:
        return Color(0xFFFF375F);
      case MemoryType.video:
        return Color(0xFF5856D6);
      case MemoryType.document:
        return Color(0xFF8E8E93);
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high':
        return '高优先级';
      case 'medium':
        return '中优先级';
      case 'low':
        return '低优先级';
      default:
        return '';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Color(0xFFFF453A);
      case 'medium':
        return Color(0xFFFF9F0A);
      case 'low':
        return Color(0xFF30D158);
      default:
        return AppTheme.textTertiaryColor;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays < 1) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.month}-${dateTime.day}';
    }
  }
} 