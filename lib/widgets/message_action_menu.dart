import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';

enum MessageAction {
  copy,
  revoke,
  delete,
  forward,
  favorite,
  unfavorite,
  select,
  saveToLocal, // 新增：保存到本地（移动端文件消息）
  shareToSystem, // 🔥 新增：分享到系统应用
  openFileLocation, // 🔥 新增：打开文件位置（桌面端）
}

class MessageActionMenu extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isOwnMessage;
  final bool isFavorited;
  final Function(MessageAction) onAction;
  final VoidCallback? onDismiss;

  const MessageActionMenu({
    super.key,
    required this.message,
    required this.isOwnMessage,
    required this.isFavorited,
    required this.onAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部指示器
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // 操作按钮列表
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: _buildActionItems(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionItems(BuildContext context) {
    final actions = <Widget>[];
    
    // 检查是否是移动端
    final isMobile = _isMobile(context);
    // 检查是否是文件消息
    final hasFile = message['fileType'] != null && 
                   message['fileName'] != null && 
                   message['fileName'].toString().isNotEmpty;
    
    // 复制
    if (message['text'] != null && message['text'].toString().isNotEmpty) {
      actions.add(_buildActionItem(
        icon: Icons.copy_rounded,
        label: '复制',
        onTap: () => onAction(MessageAction.copy),
      ));
    }
    
    // 保存到本地（仅移动端文件消息显示）
    if (isMobile && hasFile) {
      actions.add(_buildActionItem(
        icon: Icons.download_rounded,
        label: '保存到本地',
        onTap: () => onAction(MessageAction.saveToLocal),
        textColor: Colors.blue[600],
      ));
    }
    
    // 🔥 分享到系统应用（文件消息或有文字内容的消息）
    if (hasFile || (message['text'] != null && message['text'].toString().isNotEmpty)) {
      actions.add(_buildActionItem(
        icon: Icons.ios_share_rounded,
        label: '分享',
        onTap: () => onAction(MessageAction.shareToSystem),
        textColor: Colors.green[600],
      ));
    }
    
    // 🔥 移动端：移除转发、收藏功能
    // 桌面端：根据需要显示不同的菜单
    if (!isMobile) {
      // 桌面端菜单：仅保留"打开文件位置"、"删除"和"回复"
      if (hasFile) {
        actions.add(_buildActionItem(
          icon: Icons.folder_open_rounded,
          label: '打开文件位置',
          onTap: () => onAction(MessageAction.openFileLocation),
          textColor: Colors.blue[600],
        ));
      }
      
      // 桌面端回复功能已移除
      
      // 桌面端删除
      actions.add(_buildActionItem(
        icon: Icons.delete_rounded,
        label: '删除',
        textColor: Colors.red[600],
        onTap: () => onAction(MessageAction.delete),
      ));
    } else {
      // 移动端菜单：移除回复功能，保留多选
      
      actions.add(_buildActionItem(
        icon: Icons.checklist_rounded,
        label: '多选',
        onTap: () => onAction(MessageAction.select),
      ));
      
      // 移动端：移除撤回功能，只保留删除（如果是自己的消息）
      if (isOwnMessage) {
        actions.add(Container(
          height: 0.5,
          margin: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.grey[200],
        ));
        
        actions.add(_buildActionItem(
          icon: Icons.delete_rounded,
          label: '删除',
          textColor: Colors.red[600],
          onTap: () => onAction(MessageAction.delete),
        ));
      }
    }
    
    return actions;
  }

  // 检查是否是移动端
  bool _isMobile(BuildContext context) {
    if (kIsWeb) {
      return MediaQuery.of(context).size.width < 800;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
           defaultTargetPlatform == TargetPlatform.iOS;
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    final color = textColor ?? Colors.grey[700];
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 显示消息操作菜单的函数
Future<MessageAction?> showMessageActionMenu({
  required BuildContext context,
  required Map<String, dynamic> message,
  required bool isOwnMessage,
  required bool isFavorited,
}) async {
  return await showModalBottomSheet<MessageAction>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.4),
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: MessageActionMenu(
          message: message,
          isOwnMessage: isOwnMessage,
          isFavorited: isFavorited,
          onAction: (action) {
            Navigator.of(context).pop(action);
          },
          onDismiss: () {
            Navigator.of(context).pop();
          },
        ),
      );
    },
  );
} 