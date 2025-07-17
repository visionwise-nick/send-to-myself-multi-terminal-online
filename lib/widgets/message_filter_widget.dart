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

  // 🔥 新增：检查消息是否匹配筛选条件
  bool matchesMessage(Map<String, dynamic> message) {
    // 搜索关键词匹配
    if (searchKeyword.isNotEmpty) {
      final content = (message['text'] ?? '').toString().toLowerCase();
      final fileName = (message['fileName'] ?? '').toString().toLowerCase();
      final keyword = searchKeyword.toLowerCase();
      
      if (!content.contains(keyword) && !fileName.contains(keyword)) {
        return false;
      }
    }

    // 消息类型匹配
    if (type != MessageFilterType.all) {
      final messageType = message['fileType'];
      switch (type) {
        case MessageFilterType.text:
          if (messageType != null) return false;
          break;
        case MessageFilterType.image:
          if (messageType != 'image') return false;
          break;
        case MessageFilterType.video:
          if (messageType != 'video') return false;
          break;
        case MessageFilterType.file:
          if (messageType != 'file') return false;
          break;
        case MessageFilterType.document:
          if (messageType != 'document') return false;
          break;
        case MessageFilterType.all:
          break;
      }
    }

    // 发送者匹配
    if (sender != MessageSenderType.all) {
      final isMe = message['isMe'] == true;
      switch (sender) {
        case MessageSenderType.me:
          if (!isMe) return false;
          break;
        case MessageSenderType.others:
          if (isMe) return false;
          break;
        case MessageSenderType.all:
          break;
      }
    }

    // 日期范围匹配
    if (startDate != null || endDate != null) {
      final messageTime = DateTime.tryParse(message['timestamp'] ?? '');
      if (messageTime != null) {
        if (startDate != null && messageTime.isBefore(startDate!)) {
          return false;
        }
        if (endDate != null && messageTime.isAfter(endDate!)) {
          return false;
        }
      }
    }

    return true;
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
  void didUpdateWidget(MessageFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 🔥 修复：确保筛选状态正确同步
    if (oldWidget.currentFilter != widget.currentFilter) {
      setState(() {
        _filter = widget.currentFilter;
        _searchController.text = _filter.searchKeyword;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 修复：确保筛选面板有正确的约束和布局
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        minHeight: 400,
      ),
      child: SingleChildScrollView(
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
                  LocalizationHelper.of(context).messageFilter,
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
                hintText: LocalizationHelper.of(context).searchMessagesOrFiles,
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
              LocalizationHelper.of(context).messageType,
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
              LocalizationHelper.of(context).sender,
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
              LocalizationHelper.of(context).dateRange,
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
                          : LocalizationHelper.of(context).startDate,
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
                          : LocalizationHelper.of(context).endDate,
                    ),
                  ),
                ),
                if (_filter.startDate != null || _filter.endDate != null)
                  IconButton(
                    onPressed: () => _updateFilter(clearDates: true),
                    icon: const Icon(Icons.clear, size: 20),
                    tooltip: LocalizationHelper.of(context).clearDate,
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
                    label: Text(LocalizationHelper.of(context).clearAll),
                  ),
                const Spacer(),
                Text(
                  _filter.hasActiveFilters 
                      ? LocalizationHelper.of(context).filterActive 
                      : LocalizationHelper.of(context).noFilterConditions,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _filter.hasActiveFilters 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 🔥 新增：确认和取消按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // 取消筛选，恢复到原始状态
                      setState(() {
                        _filter = widget.currentFilter;
                        _searchController.text = _filter.searchKeyword;
                      });
                      widget.onClose?.call();
                    },
                    child: Text(LocalizationHelper.of(context).cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // 确认筛选，应用当前筛选条件
                      widget.onFilterChanged(_filter);
                      widget.onClose?.call();
                    },
                    child: Text(LocalizationHelper.of(context).confirm),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(MessageFilterType type) {
    switch (type) {
      case MessageFilterType.all:
        return LocalizationHelper.of(context).all;
      case MessageFilterType.text:
        return LocalizationHelper.of(context).text;
      case MessageFilterType.image:
        return LocalizationHelper.of(context).image;
      case MessageFilterType.video:
        return LocalizationHelper.of(context).video;
      case MessageFilterType.file:
        return LocalizationHelper.of(context).file;
      case MessageFilterType.document:
        return LocalizationHelper.of(context).document;
    }
  }

  String _getSenderLabel(MessageSenderType sender) {
    switch (sender) {
      case MessageSenderType.all:
        return LocalizationHelper.of(context).all;
      case MessageSenderType.me:
        return LocalizationHelper.of(context).sentByMe;
      case MessageSenderType.others:
        return LocalizationHelper.of(context).sentByOthers;
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
    // 🔥 修复：确保状态更新时UI正确重建
    if (mounted) {
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
    }
    // 🔥 移除实时应用筛选，改为只在确认时应用
    // widget.onFilterChanged(_filter);
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