import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ReplyMessageWidget extends StatelessWidget {
  final Map<String, dynamic> replyToMessage;
  final VoidCallback onCancel;

  const ReplyMessageWidget({
    super.key,
    required this.replyToMessage,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: AppTheme.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          // 回复图标
          Icon(
            Icons.reply_rounded,
            color: AppTheme.primaryColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          
          // 回复内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 回复对象
                Text(
                  '回复 ${_getMessageSender()}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                
                // 被回复的消息内容
                _buildReplyContent(),
              ],
            ),
          ),
          
          // 取消按钮
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                color: Colors.grey[600],
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMessageSender() {
    final isMe = replyToMessage['isMe'] == true;
    if (isMe) {
      return '自己';
    } else {
      return replyToMessage['senderName']?.toString() ?? '对方';
    }
  }

  Widget _buildReplyContent() {
    final text = replyToMessage['text']?.toString() ?? '';
    final fileName = replyToMessage['fileName']?.toString() ?? '';
    final fileType = replyToMessage['fileType']?.toString() ?? '';
    
    // 如果有文件
    if (fileName.isNotEmpty) {
      return Row(
        children: [
          // 文件图标
          Icon(
            _getFileIcon(fileType),
            color: Colors.grey[600],
            size: 16,
          ),
          const SizedBox(width: 4),
          
          // 文件名（截断显示）
          Expanded(
            child: Text(
              fileName.length > 20 ? '${fileName.substring(0, 20)}...' : fileName,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    
    // 如果有文字内容
    if (text.isNotEmpty) {
      return Text(
        text.length > 50 ? '${text.substring(0, 50)}...' : text,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 13,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    // 默认显示
    return Text(
      '[消息]',
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 13,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'image':
        return Icons.image_rounded;
      case 'video':
        return Icons.videocam_rounded;
      case 'audio':
        return Icons.audiotrack_rounded;
      case 'document':
        return Icons.description_rounded;
      default:
        return Icons.attach_file_rounded;
    }
  }
} 