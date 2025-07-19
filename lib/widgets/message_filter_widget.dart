import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../utils/localization_helper.dart';

enum MessageFilterType {
  all,
  text,
  image,
  video,
  document,
}

class MessageFilter extends Equatable {
  final MessageFilterType type;
  final String searchKeyword;

  const MessageFilter({
    this.type = MessageFilterType.all,
    this.searchKeyword = '',
  });

  MessageFilter copyWith({
    MessageFilterType? type,
    String? searchKeyword,
  }) {
    return MessageFilter(
      type: type ?? this.type,
      searchKeyword: searchKeyword ?? this.searchKeyword,
    );
  }

  bool get hasActiveFilters {
    return type != MessageFilterType.all || searchKeyword.isNotEmpty;
  }

  // 🔥 新增：从参数创建筛选器
  factory MessageFilter.fromParams(Map<String, dynamic> params) {
    return MessageFilter(
      type: MessageFilterType.values[params['type'] ?? 0],
      searchKeyword: params['searchKeyword'] ?? '',
    );
  }

  // 🔥 新增：转换为参数
  Map<String, dynamic> toParams() {
    return {
      'type': type.index,
      'searchKeyword': searchKeyword,
    };
  }

  bool matchesMessage(Map<String, dynamic> message) {
    // 检查消息类型筛选
    if (type != MessageFilterType.all) {
      final messageType = _getMessageType(message);
      if (messageType != type) return false;
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
        // 所有其他文件类型都视为“文档”
        return MessageFilterType.document;
    }
  }

  @override
  List<Object?> get props => [type, searchKeyword];
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
    // 关键修复：确保初始状态正确反映传入的筛选器
    _filter = widget.currentFilter;
    _searchController.text = _filter.searchKeyword;
  }

  @override
  void didUpdateWidget(MessageFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 关键修复：仅当外部筛选器实际发生变化时才更新内部状态
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
  
  // 🔥 新增：获取激活的筛选条件数量
  int _getActiveFilterCount() {
    int count = 0;
    if (_filter.type != MessageFilterType.all) count++;
    if (_filter.searchKeyword.isNotEmpty) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          
          // 🔥 新增：筛选状态提示
          if (_filter.hasActiveFilters)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '当前正在筛选消息，已设置 ${_getActiveFilterCount()} 个筛选条件',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
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

          // 操作按钮
          Row(
            children: [
              const Spacer(),
              Text(
                _filter.hasActiveFilters 
                    ? '已设置筛选条件' 
                    : '未设置筛选条件',
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
      case MessageFilterType.document:
        return LocalizationHelper.of(context).document;
    }
  }

  void _updateFilter({
    MessageFilterType? type,
    String? searchKeyword,
  }) {
    setState(() {
      _filter = _filter.copyWith(
        type: type,
        searchKeyword: searchKeyword,
      );
    });
    // 🔥 移除实时应用筛选，改为只在确认时应用
    // widget.onFilterChanged(_filter);
  }
} 