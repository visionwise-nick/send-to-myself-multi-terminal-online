import 'package:flutter/material.dart';
import '../services/sync_manager.dart';

/// 同步状态显示组件
class SyncStatusWidget extends StatefulWidget {
  final SyncManager syncManager;
  final bool showDetails;
  final VoidCallback? onTap;

  const SyncStatusWidget({
    Key? key,
    required this.syncManager,
    this.showDetails = false,
    this.onTap,
  }) : super(key: key);

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  SyncStatus? _syncStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    try {
      final status = await widget.syncManager.getSyncStatus();
      if (mounted) {
        setState(() {
          _syncStatus = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_syncStatus == null) {
      return const SizedBox.shrink();
    }

    final status = _syncStatus!;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getStatusColor(status).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getStatusIcon(status),
              size: 14,
              color: _getStatusColor(status),
            ),
            const SizedBox(width: 4),
            Text(
              _getStatusText(status),
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(status),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.showDetails && status.lastOnlineTime != null) ...[
              const SizedBox(width: 4),
              Text(
                _formatTime(status.lastOnlineTime!),
                style: TextStyle(
                  fontSize: 10,
                  color: _getStatusColor(status).withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(SyncStatus status) {
    if (status.isSyncing) {
      return Colors.blue;
    }
    
    if (status.lastOnlineTime == null) {
      return Colors.orange;
    }
    
    final now = DateTime.now();
    final diff = now.difference(status.lastOnlineTime!);
    
    if (diff.inMinutes < 5) {
      return Colors.green;
    } else if (diff.inHours < 1) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getStatusIcon(SyncStatus status) {
    if (status.isSyncing) {
      return Icons.sync;
    }
    
    if (status.lastOnlineTime == null) {
      return Icons.sync_problem;
    }
    
    final now = DateTime.now();
    final diff = now.difference(status.lastOnlineTime!);
    
    if (diff.inMinutes < 5) {
      return Icons.cloud_done;
    } else if (diff.inHours < 1) {
      return Icons.cloud_sync;
    } else {
      return Icons.cloud_off;
    }
  }

  String _getStatusText(SyncStatus status) {
    if (status.isSyncing) {
      return '同步中';
    }
    
    if (status.lastOnlineTime == null) {
      return '未同步';
    }
    
    final now = DateTime.now();
    final diff = now.difference(status.lastOnlineTime!);
    
    if (diff.inMinutes < 1) {
      return '已同步';
    } else if (diff.inMinutes < 5) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else {
      return '${diff.inDays}天前';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}

/// 同步进度对话框
class SyncProgressDialog extends StatefulWidget {
  final SyncManager syncManager;

  const SyncProgressDialog({
    Key? key,
    required this.syncManager,
  }) : super(key: key);

  @override
  State<SyncProgressDialog> createState() => _SyncProgressDialogState();
}

class _SyncProgressDialogState extends State<SyncProgressDialog> {
  bool _isLoading = true;
  SyncResult? _result;
  String _statusText = '正在初始化同步...';

  @override
  void initState() {
    super.initState();
    _performSync();
  }

  Future<void> _performSync() async {
    try {
      setState(() {
        _statusText = '正在同步离线消息...';
      });

      final result = await widget.syncManager.performAppStartupSync();
      
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
          _statusText = result.success 
            ? '同步完成！获取到 ${result.totalFetched} 条消息'
            : '同步失败：${result.error}';
        });
      }

      // 自动关闭对话框
      if (result.success) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(result);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusText = '同步出错：$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.sync, color: Colors.blue),
          SizedBox(width: 8),
          Text('离线消息同步'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
          ] else if (_result != null) ...[
            Icon(
              _result!.success ? Icons.check_circle : Icons.error,
              color: _result!.success ? Colors.green : Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          if (_result != null && _result!.success) ...[
            const SizedBox(height: 8),
            Text(
              '处理了 ${_result!.totalProcessed} 条消息',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!_isLoading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(_result),
            child: const Text('确定'),
          ),
      ],
    );
  }
}

/// 同步状态监听器组件
class SyncStatusListener extends StatefulWidget {
  final SyncManager syncManager;
  final Widget child;
  final Function(SyncResult)? onSyncCompleted;
  final Function(String)? onSyncError;

  const SyncStatusListener({
    Key? key,
    required this.syncManager,
    required this.child,
    this.onSyncCompleted,
    this.onSyncError,
  }) : super(key: key);

  @override
  State<SyncStatusListener> createState() => _SyncStatusListenerState();
}

class _SyncStatusListenerState extends State<SyncStatusListener> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// 手动同步按钮
class ManualSyncButton extends StatefulWidget {
  final SyncManager syncManager;
  final String? groupId;
  final VoidCallback? onSyncStart;
  final Function(SyncResult)? onSyncCompleted;

  const ManualSyncButton({
    Key? key,
    required this.syncManager,
    this.groupId,
    this.onSyncStart,
    this.onSyncCompleted,
  }) : super(key: key);

  @override
  State<ManualSyncButton> createState() => _ManualSyncButtonState();
}

class _ManualSyncButtonState extends State<ManualSyncButton> {
  bool _isSyncing = false;

  Future<void> _performSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    widget.onSyncStart?.call();

    try {
      SyncResult result;
      
      if (widget.groupId != null) {
        // 同步特定群组
        result = await widget.syncManager.syncGroupHistory(
          groupId: widget.groupId!,
        );
      } else {
        // 同步所有离线消息
        result = await widget.syncManager.performIncrementalSync();
      }

      widget.onSyncCompleted?.call(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success 
                ? '同步完成！获取到 ${result.totalFetched} 条消息'
                : '同步失败：${result.error}',
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('同步出错：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isSyncing ? null : _performSync,
      icon: _isSyncing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync),
      tooltip: widget.groupId != null ? '同步群组消息' : '同步离线消息',
    );
  }
} 