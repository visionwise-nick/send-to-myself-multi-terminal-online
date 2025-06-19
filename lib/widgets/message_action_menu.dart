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
  reply,
  select,
  saveToLocal, // 新增：保存到本地（移动端文件消息）
  shareToSystem, // 🔥 新增：分享到系统应用
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
    
    // 转发
    actions.add(_buildActionItem(
      icon: Icons.share_rounded,
      label: '转发',
      onTap: () => onAction(MessageAction.forward),
    ));
    
    // 收藏/取消收藏
    actions.add(_buildActionItem(
      icon: isFavorited ? Icons.star : Icons.star_border_rounded,
      label: isFavorited ? '取消收藏' : '收藏',
      onTap: () => onAction(isFavorited ? MessageAction.unfavorite : MessageAction.favorite),
    ));
    
    // 回复
    actions.add(_buildActionItem(
      icon: Icons.reply_rounded,
      label: '回复',
      onTap: () => onAction(MessageAction.reply),
    ));
    
    // 多选
    actions.add(_buildActionItem(
      icon: Icons.checklist_rounded,
      label: '多选',
      onTap: () => onAction(MessageAction.select),
    ));
    
    // 危险操作分隔符
    if (isOwnMessage) {
      actions.add(Container(
        height: 0.5,
        margin: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.grey[200],
      ));
      
      // 撤回
      actions.add(_buildActionItem(
        icon: Icons.undo_rounded,
        label: '撤回',
        textColor: Colors.orange[600],
        onTap: () => onAction(MessageAction.revoke),
      ));
      
      // 删除
      actions.add(_buildActionItem(
        icon: Icons.delete_rounded,
        label: '删除',
        textColor: Colors.red[600],
        onTap: () => onAction(MessageAction.delete),
      ));
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