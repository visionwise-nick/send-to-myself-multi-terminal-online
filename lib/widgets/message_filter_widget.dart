import 'package:flutter/material.dart';
import '../utils/localization_helper.dart';

enum MessageFilterType {
  all,
  text,
  image,
  video,
  file,
  document,
}

enum MessageSenderType {
  all,
  me,
  others,
}

class MessageFilter {
  final MessageFilterType type;
  final MessageSenderType sender;
  final DateTime? startDate;
  final DateTime? endDate;
  final String searchKeyword;

  MessageFilter({
    this.type = MessageFilterType.all,
    this.sender = MessageSenderType.all,
    this.startDate,
    this.endDate,
    this.searchKeyword = '',
  });

  MessageFilter copyWith({
    MessageFilterType? type,
    MessageSenderType? sender,
    DateTime? startDate,
    DateTime? endDate,
    String? searchKeyword,
    bool clearDates = false,
  }) {
    return MessageFilter(
      type: type ?? this.type,
      sender: sender ?? this.sender,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      searchKeyword: searchKeyword ?? this.searchKeyword,
    );
  }

  bool get hasActiveFilters {
    return type != MessageFilterType.all ||
           sender != MessageSenderType.all ||
           startDate != null ||
           endDate != null ||
           searchKeyword.isNotEmpty;
  }

  // 🔥 新增：从参数创建筛选器
  factory MessageFilter.fromParams(Map<String, dynamic> params) {
    return MessageFilter(
      type: MessageFilterType.values[params['type'] ?? 0],
      sender: MessageSenderType.values[params['sender'] ?? 0],
      startDate: params['startDate'] != null ? DateTime.parse(params['startDate']) : null,
      endDate: params['endDate'] != null ? DateTime.parse(params['endDate']) : null,
      searchKeyword: params['searchKeyword'] ?? '',
    );
  }

  // 🔥 新增：转换为参数
  Map<String, dynamic> toParams() {
    return {
      'type': type.index,
      'sender': sender.index,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'searchKeyword': searchKeyword,
    };
  }

  bool matchesMessage(Map<String, dynamic> message) {
    // 检查消息类型筛选
    if (type != MessageFilterType.all) {
      final messageType = _getMessageType(message);
      if (messageType != type) return false;
    }

    // 检查发送者筛选
    if (sender != MessageSenderType.all) {
      final isMe = message['isMe'] == true;
      if (sender == MessageSenderType.me && !isMe) return false;
      if (sender == MessageSenderType.others && isMe) return false;
    }

    // 检查日期筛选
    if (startDate != null || endDate != null) {
      final timestamp = message['timestamp']?.toString();
      if (timestamp != null) {
        try {
          final messageDate = DateTime.parse(timestamp);
          if (startDate != null && messageDate.isBefore(startDate!)) return false;
          if (endDate != null && messageDate.isAfter(endDate!.add(Duration(days: 1)))) return false;
        } catch (e) {
          // 如果时间戳解析失败，跳过日期筛选
        }
      }
    }

    // 检查关键词搜索
    if (searchKeyword.isNotEmpty) {
      final text = message['text']?.toString() ?? '';
      final fileName = message['fileName']?.toString() ?? '';
      final searchText = '$text $fileName'.toLowerCase();
      if (!searchText.contains(searchKeyword.toLowerCase())) return false;
    }

    return true;
  }

  MessageFilterType _getMessageType(Map<String, dynamic> message) {
    final fileType = message['fileType']?.toString();
    if (fileType == null) return MessageFilterType.text;

    switch (fileType) {
      case 'image':
        return MessageFilterType.image;
      case 'video':
        return MessageFilterType.video;
      case 'document':
        return MessageFilterType.document;
      default:
        return MessageFilterType.file;
    }
  }
}

class MessageFilterWidget extends StatefulWidget {
  final MessageFilter currentFilter;
  final Function(MessageFilter) onFilterChanged;
  final VoidCallback? onClose;

  const MessageFilterWidget({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    this.onClose,
  });

  @override
  State<MessageFilterWidget> createState() => _MessageFilterWidgetState();
}

class _MessageFilterWidgetState extends State<MessageFilterWidget> {
  late MessageFilter _filter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
    _searchController.text = _filter.searchKeyword;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和关闭按钮
          Row(
            children: [
              const Icon(Icons.filter_list, size: 20),
              const SizedBox(width: 8),
              Text(
                '消息筛选',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (widget.onClose != null)
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 搜索框
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索消息内容或文件名...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _updateFilter(searchKeyword: '');
                      },
                      icon: const Icon(Icons.clear, size: 20),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) {
              _updateFilter(searchKeyword: value);
            },
          ),
          const SizedBox(height: 16),

          // 消息类型筛选
          Text(
            '消息类型',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: MessageFilterType.values.map((type) {
              return FilterChip(
                label: Text(_getTypeLabel(type)),
                selected: _filter.type == type,
                onSelected: (selected) {
                  if (selected) {
                    _updateFilter(type: type);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 发送者筛选
          Text(
            '发送者',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: MessageSenderType.values.map((sender) {
              return FilterChip(
                label: Text(_getSenderLabel(sender)),
                selected: _filter.sender == sender,
                onSelected: (selected) {
                  if (selected) {
                    _updateFilter(sender: sender);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 日期范围筛选
          Text(
            '日期范围',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _selectStartDate(),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _filter.startDate != null
                        ? '${_filter.startDate!.month}/${_filter.startDate!.day}'
                        : '开始日期',
                  ),
                ),
              ),
              const Text(' 至 '),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _selectEndDate(),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _filter.endDate != null
                        ? '${_filter.endDate!.month}/${_filter.endDate!.day}'
                        : '结束日期',
                  ),
                ),
              ),
              if (_filter.startDate != null || _filter.endDate != null)
                IconButton(
                  onPressed: () => _updateFilter(clearDates: true),
                  icon: const Icon(Icons.clear, size: 20),
                  tooltip: '清除日期',
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 操作按钮
          Row(
            children: [
              if (_filter.hasActiveFilters)
                TextButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('清除所有'),
                ),
              const Spacer(),
              Text(
                _filter.hasActiveFilters ? '筛选已激活' : '无筛选条件',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _filter.hasActiveFilters 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(MessageFilterType type) {
    switch (type) {
      case MessageFilterType.all:
        return '全部';
      case MessageFilterType.text:
        return '文本';
      case MessageFilterType.image:
        return '图片';
      case MessageFilterType.video:
        return '视频';
      case MessageFilterType.file:
        return '文件';
      case MessageFilterType.document:
        return '文档';
    }
  }

  String _getSenderLabel(MessageSenderType sender) {
    switch (sender) {
      case MessageSenderType.all:
        return '全部';
      case MessageSenderType.me:
        return '我发送的';
      case MessageSenderType.others:
        return '他人发送的';
    }
  }

  void _updateFilter({
    MessageFilterType? type,
    MessageSenderType? sender,
    DateTime? startDate,
    DateTime? endDate,
    String? searchKeyword,
    bool clearDates = false,
  }) {
    setState(() {
      _filter = _filter.copyWith(
        type: type,
        sender: sender,
        startDate: startDate,
        endDate: endDate,
        searchKeyword: searchKeyword,
        clearDates: clearDates,
      );
    });
    widget.onFilterChanged(_filter);
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _filter.startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      _updateFilter(startDate: date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _filter.endDate ?? DateTime.now(),
      firstDate: _filter.startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      _updateFilter(endDate: date);
    }
  }

  void _clearAllFilters() {
    _searchController.clear();
    _updateFilter(
      type: MessageFilterType.all,
      sender: MessageSenderType.all,
      searchKeyword: '',
      clearDates: true,
    );
  }
} 