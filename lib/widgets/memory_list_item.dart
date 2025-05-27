import 'package:flutter/material.dart';
import '../models/memory_model.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';

class MemoryListItem extends StatelessWidget {
  final Memory memory;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MemoryListItem({
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：类型图标、标题、操作按钮
              Row(
                children: [
                  // 类型图标
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _getTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        memory.type.iconEmoji,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
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
              
              const SizedBox(height: 8),
              
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
              
              const SizedBox(height: 8),
              
              // 底部：时间和标签
              Row(
                children: [
                  // 时间
                  Text(
                    TimeUtils.formatRelativeTime(memory.updatedAt),
                    style: AppTheme.smallStyle,
                  ),
                  
                  const Spacer(),
                  
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
            padding: EdgeInsets.only(top: 4),
            child: Text(
              '账号: ${data['username']} • 网站: ${data['website']}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue.shade600,
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
            padding: EdgeInsets.only(top: 4),
            child: Text(
              '${isIncome ? '+' : '-'}¥${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: isIncome ? Colors.green.shade600 : Colors.red.shade600,
                fontWeight: FontWeight.w600,
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
            padding: EdgeInsets.only(top: 4),
            child: Text(
              '${startTime.month}-${startTime.day} ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.purple.shade600,
                fontWeight: FontWeight.w500,
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
            padding: EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 12,
                  color: isCompleted ? Colors.green : Colors.grey,
                ),
                SizedBox(width: 4),
                Text(
                  _getPriorityText(priority),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getPriorityColor(priority),
                    fontWeight: FontWeight.w500,
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
            padding: EdgeInsets.only(top: 4),
            child: Text(
              data['url'] ?? '',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue.shade600,
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

  Color _getTypeColor() {
    switch (memory.type) {
      case MemoryType.text:
        return Colors.blue;
      case MemoryType.password:
        return Colors.red;
      case MemoryType.financial:
        return Colors.green;
      case MemoryType.schedule:
        return Colors.purple;
      case MemoryType.todo:
        return Colors.orange;
      case MemoryType.url:
        return Colors.cyan;
      case MemoryType.image:
        return Colors.pink;
      case MemoryType.video:
        return Colors.indigo;
      case MemoryType.document:
        return Colors.grey;
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
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
} 