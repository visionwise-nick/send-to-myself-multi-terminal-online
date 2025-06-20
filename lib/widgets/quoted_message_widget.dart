import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuotedMessageWidget extends StatelessWidget {
  final Map<String, dynamic> quotedMessage;
  final bool isMe;
  final VoidCallback? onTap; // 🔥 新增：点击回调

  const QuotedMessageWidget({
    super.key,
    required this.quotedMessage,
    required this.isMe,
    this.onTap, // 🔥 新增：点击回调
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe 
          ? Colors.white.withOpacity(0.2)
          : Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white.withOpacity(0.6) : AppTheme.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 被回复者信息
          Text(
            _getQuotedSender(),
            style: TextStyle(
              color: isMe 
                ? Colors.white.withOpacity(0.8)
                : AppTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          
          // 被回复的消息内容
          _buildQuotedContent(),
        ],
      ),
      ),
    );
  }

  String _getQuotedSender() {
    final isQuotedMe = quotedMessage['isMe'] == true;
    if (isQuotedMe) {
      return '你';
    } else {
      return quotedMessage['senderName']?.toString() ?? '对方';
    }
  }

  Widget _buildQuotedContent() {
    final text = quotedMessage['text']?.toString() ?? '';
    final fileName = quotedMessage['fileName']?.toString() ?? '';
    final fileType = quotedMessage['fileType']?.toString() ?? '';
    
    // 如果有文件
    if (fileName.isNotEmpty) {
      return Row(
        children: [
          // 文件图标
          Icon(
            _getFileIcon(fileType),
            color: isMe 
              ? Colors.white.withOpacity(0.7)
              : Colors.grey[600],
            size: 14,
          ),
          const SizedBox(width: 4),
          
          // 文件名（截断显示）
          Expanded(
            child: Text(
              fileName.length > 30 ? '${fileName.substring(0, 30)}...' : fileName,
              style: TextStyle(
                color: isMe 
                  ? Colors.white.withOpacity(0.8)
                  : Colors.grey[700],
                fontSize: 12,
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
        text.length > 80 ? '${text.substring(0, 80)}...' : text,
        style: TextStyle(
          color: isMe 
            ? Colors.white.withOpacity(0.8)
            : Colors.grey[700],
          fontSize: 12,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    // 默认显示
    return Text(
      '[消息]',
      style: TextStyle(
        color: isMe 
          ? Colors.white.withOpacity(0.6)
          : Colors.grey[500],
        fontSize: 12,
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