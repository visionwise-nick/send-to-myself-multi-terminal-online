import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/localization_helper.dart';

class MultiSelectMode extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback? onShareToSystem;
  final VoidCallback? onDelete;

  const MultiSelectMode({
    super.key,
    required this.selectedCount,
    required this.onCancel,
    this.onShareToSystem,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // 左侧：选中数量和取消按钮
              InkWell(
                onTap: onCancel,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.close,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        LocalizationHelper.of(context).selectedMessages(selectedCount),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // 右侧：操作按钮（只保留分享和删除）
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔥 分享按钮（分享到系统应用）
                  if (onShareToSystem != null)
                    _buildActionButton(
                      icon: Icons.ios_share_rounded,
                      onPressed: onShareToSystem!,
                      tooltip: LocalizationHelper.of(context).share,
                      color: Colors.green[600],
                    ),
                  
                  // 🔥 删除按钮
                  if (onDelete != null)
                    _buildActionButton(
                      icon: Icons.delete_rounded,
                      onPressed: onDelete!,
                      tooltip: LocalizationHelper.of(context).deleteTooltip,
                      color: Colors.red[600],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? color,
  }) {
    final buttonColor = color ?? Colors.grey[600];
    
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (color != null ? color.withOpacity(0.1) : Colors.grey[100]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: buttonColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// 消息多选状态管理类
class MultiSelectController extends ChangeNotifier {
  bool _isMultiSelectMode = false;
  final Set<String> _selectedMessages = {};

  bool get isMultiSelectMode => _isMultiSelectMode;
  Set<String> get selectedMessages => Set.from(_selectedMessages);
  int get selectedCount => _selectedMessages.length;

  void enterMultiSelectMode() {
    _isMultiSelectMode = true;
    notifyListeners();
  }

  void exitMultiSelectMode() {
    _isMultiSelectMode = false;
    _selectedMessages.clear();
    notifyListeners();
  }

  void toggleMessage(String messageId) {
    if (_selectedMessages.contains(messageId)) {
      _selectedMessages.remove(messageId);
    } else {
      _selectedMessages.add(messageId);
    }
    
    // 如果没有选中的消息，退出多选模式
    if (_selectedMessages.isEmpty) {
      exitMultiSelectMode();
    } else {
      notifyListeners();
    }
  }

  void selectMessage(String messageId) {
    _selectedMessages.add(messageId);
    notifyListeners();
  }

  void deselectMessage(String messageId) {
    _selectedMessages.remove(messageId);
    if (_selectedMessages.isEmpty) {
      exitMultiSelectMode();
    } else {
      notifyListeners();
    }
  }

  void selectAll(List<String> messageIds) {
    _selectedMessages.addAll(messageIds);
    notifyListeners();
  }

  void clearSelection() {
    _selectedMessages.clear();
    notifyListeners();
  }

  bool isSelected(String messageId) {
    return _selectedMessages.contains(messageId);
  }
} 