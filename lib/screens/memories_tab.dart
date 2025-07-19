import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/memory_provider.dart';
import '../providers/group_provider.dart';
import '../models/memory_model.dart';
import '../theme/app_theme.dart';
import '../widgets/memory_card.dart';
import '../services/ai_service.dart';
import '../utils/localization_helper.dart';
import 'create_memory_screen.dart';
import 'edit_memory_screen.dart';

class MemoriesTab extends StatefulWidget {
  const MemoriesTab({super.key});

  @override
  State<MemoriesTab> createState() => _MemoriesTabState();
}

class _MemoriesTabState extends State<MemoriesTab> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final AIService _aiService = AIService();

  @override
  void initState() {
    super.initState();
    
    // 初始化记忆数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProvider = context.read<GroupProvider>();
      final currentGroupId = groupProvider.currentGroup?['id'];
      
      context.read<MemoryProvider>().initialize(groupId: currentGroupId);
      
      // 监听群组变化
      groupProvider.addListener(_onGroupChanged);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    
    // 移除群组变化监听
    try {
      context.read<GroupProvider>().removeListener(_onGroupChanged);
    } catch (e) {
      // 忽略disposed错误
    }
    
    super.dispose();
  }

  void _onGroupChanged() {
    // 群组切换时重新加载记忆
    if (mounted) {
      final groupProvider = context.read<GroupProvider>();
      final currentGroupId = groupProvider.currentGroup?['id'];
      
      context.read<MemoryProvider>().setCurrentGroupId(currentGroupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // 顶部区域
          _buildHeader(),
          
          // 记忆列表
          Expanded(
            child: _buildMemoriesList(),
          ),
        ],
      ),
      
      // 添加记忆按钮
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickAddOptions,
        backgroundColor: AppTheme.primaryColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 统计信息
          Consumer<MemoryProvider>(
            builder: (context, memoryProvider, child) {
              return Text(
                LocalizationHelper.of(context).memoriesCount(memoryProvider.totalMemories),
                style: AppTheme.captionStyle.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              );
            },
          ),
          
          SizedBox(height: 12),
          
          // 搜索栏
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: TextField(
              controller: _searchController,
              style: AppTheme.bodyStyle,
              decoration: InputDecoration(
                hintText: LocalizationHelper.of(context).searchMemories,
                hintStyle: AppTheme.bodyStyle.copyWith(color: AppTheme.textTertiaryColor),
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondaryColor, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (query) {
                context.read<MemoryProvider>().setSearchQuery(query);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoriesList() {
    return Consumer<MemoryProvider>(
      builder: (context, memoryProvider, child) {
        if (memoryProvider.isLoading && memoryProvider.memories.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 2,
            ),
          );
        }
        
        if (memoryProvider.memories.isEmpty) {
          return _buildEmptyState();
        }
        
        // 按日期分组记忆
        final groupedMemories = _groupMemoriesByDate(memoryProvider.memories);
        
        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(16),
          itemCount: groupedMemories.length,
          itemBuilder: (context, index) {
            final dateGroup = groupedMemories[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 日期标题
                if (index == 0 || groupedMemories[index-1]['date'] != dateGroup['date'])
                  Padding(
                    padding: EdgeInsets.only(bottom: 12, top: index == 0 ? 0 : 20),
                    child: Text(
                      dateGroup['date'],
                      style: AppTheme.captionStyle.copyWith(
                        fontWeight: AppTheme.fontWeightMedium,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                
                // 该日期的记忆列表
                ...dateGroup['memories'].map<Widget>((memory) => 
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: MemoryCard(
                      memory: memory,
                      onTap: () => _openMemory(memory),
                      onEdit: () => _editMemory(memory),
                      onDelete: () => _deleteMemory(memory),
                    ),
                  ),
                ).toList(),
              ],
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _groupMemoriesByDate(List<Memory> memories) {
    final Map<String, List<Memory>> grouped = {};
    final now = DateTime.now();
    
    for (final memory in memories) {
      final date = memory.updatedAt;
      String dateKey;
      
      if (_isSameDay(date, now)) {
        dateKey = LocalizationHelper.of(context).today;
      } else if (_isSameDay(date, now.subtract(Duration(days: 1)))) {
        dateKey = LocalizationHelper.of(context).yesterday;
      } else if (date.isAfter(now.subtract(Duration(days: 7)))) {
        final weekdays = [
          '', 
          LocalizationHelper.of(context).monday, 
          LocalizationHelper.of(context).tuesday, 
          LocalizationHelper.of(context).wednesday, 
          LocalizationHelper.of(context).thursday, 
          LocalizationHelper.of(context).friday, 
          LocalizationHelper.of(context).saturday, 
          LocalizationHelper.of(context).sunday
        ];
        dateKey = weekdays[date.weekday];
      } else {
        dateKey = LocalizationHelper.of(context).dateFormat(date.month, date.day);
      }
      
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(memory);
    }
    
    // 按时间倒序排列
    final sortedKeys = grouped.keys.toList();
    final today = LocalizationHelper.of(context).today;
    final yesterday = LocalizationHelper.of(context).yesterday;
    final keyOrder = [
      today, 
      yesterday, 
      LocalizationHelper.of(context).sunday, 
      LocalizationHelper.of(context).saturday, 
      LocalizationHelper.of(context).friday, 
      LocalizationHelper.of(context).thursday, 
      LocalizationHelper.of(context).wednesday, 
      LocalizationHelper.of(context).tuesday, 
      LocalizationHelper.of(context).monday
    ];
    
    sortedKeys.sort((a, b) {
      final aIndex = keyOrder.indexOf(a);
      final bIndex = keyOrder.indexOf(b);
      
      if (aIndex != -1 && bIndex != -1) {
        return aIndex.compareTo(bIndex);
      }
      if (aIndex != -1) return -1;
      if (bIndex != -1) return 1;
      
      // 对于具体日期，按实际日期排序
      return b.compareTo(a);
    });
    
    return sortedKeys.map((key) => {
      'date': key,
      'memories': grouped[key]!,
    }).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.memory_outlined,
            size: 60,
            color: AppTheme.textTertiaryColor,
          ),
          SizedBox(height: 16),
          Text(
            LocalizationHelper.of(context).noMemories,
            style: AppTheme.titleStyle,
          ),
          SizedBox(height: 8),
          Text(
            LocalizationHelper.of(context).noMemoriesDesc,
            style: AppTheme.bodyStyle.copyWith(color: AppTheme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createMemory(context, MemoryType.text),
            icon: Icon(Icons.add, size: 18),
            label: Text(LocalizationHelper.of(context).createMemory),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocalizationHelper.of(context).quickAdd,
                style: AppTheme.titleStyle,
              ),
              SizedBox(height: 16),
              
              // 快速输入文字
              _buildQuickTextInput(),
              
              SizedBox(height: 20),
              
              // 快速添加选项
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildQuickOption(
                      icon: Icons.photo_library,
                      title: '照片/图片',
                      subtitle: '从相册选择或拍摄照片',
                      onTap: () => _quickAddFile(MemoryType.image),
                    ),
                    _buildQuickOption(
                      icon: Icons.videocam,
                      title: '视频',
                      subtitle: '录制或选择视频',
                      onTap: () => _quickAddFile(MemoryType.video),
                    ),
                    _buildQuickOption(
                      icon: Icons.description,
                      title: '文档',
                      subtitle: '添加PDF、Word等文档',
                      onTap: () => _quickAddFile(MemoryType.document),
                    ),
                    _buildQuickOption(
                      icon: Icons.mic,
                      title: '录音',
                      subtitle: '录制语音备忘',
                      onTap: () => _recordAudio(),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // 详细类型选择
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDetailedTypes();
                        },
                        child: Text(
                          '更多类型',
                          style: AppTheme.bodyStyle.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickTextInput() {
    final textController = TextEditingController();
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textController,
                style: AppTheme.bodyStyle,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '输入文字记忆内容...',
                  hintStyle: AppTheme.bodyStyle.copyWith(
                    color: AppTheme.textTertiaryColor,
                  ),
                  border: InputBorder.none,
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (textController.text.trim().isNotEmpty) {
                        Navigator.pop(context);
                        await _quickAddText(textController.text.trim());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      '保存',
                      style: AppTheme.captionStyle.copyWith(
                        color: Colors.white,
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

  Widget _buildQuickOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: AppTheme.fontWeightMedium,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTheme.captionStyle,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showDetailedTypes() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              '选择记忆类型',
              style: AppTheme.titleStyle.copyWith(
                fontWeight: AppTheme.fontWeightMedium,
              ),
            ),
            SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 20),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: MemoryType.values.map((type) => _buildTypeOption(type)).toList(),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(MemoryType type) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _createMemory(context, type);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getModernIcon(type),
              size: 24,
              color: _getTypeColor(type),
            ),
            SizedBox(height: 6),
            Text(
              type.displayName,
              style: AppTheme.captionStyle.copyWith(
                fontWeight: AppTheme.fontWeightMedium,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getModernIcon(MemoryType type) {
    switch (type) {
      case MemoryType.text:
        return Icons.notes;
      case MemoryType.password:
        return Icons.security;
      case MemoryType.financial:
        return Icons.account_balance_wallet;
      case MemoryType.schedule:
        return Icons.event;
      case MemoryType.todo:
        return Icons.task_alt;
      case MemoryType.url:
        return Icons.link;
      case MemoryType.image:
        return Icons.photo_library;
      case MemoryType.video:
        return Icons.videocam;
      case MemoryType.document:
        return Icons.description;
    }
  }

  Color _getTypeColor(MemoryType type) {
    switch (type) {
      case MemoryType.text:
        return Color(0xFF007AFF);
      case MemoryType.password:
        return Color(0xFFFF453A);
      case MemoryType.financial:
        return Color(0xFF30D158);
      case MemoryType.schedule:
        return Color(0xFFBF5AF2);
      case MemoryType.todo:
        return Color(0xFFFF9F0A);
      case MemoryType.url:
        return Color(0xFF64D2FF);
      case MemoryType.image:
        return Color(0xFFFF375F);
      case MemoryType.video:
        return Color(0xFF5856D6);
      case MemoryType.document:
        return Color(0xFF8E8E93);
    }
  }

  Future<void> _quickAddText(String content) async {
    try {
      // 使用AI生成标题和标签
      final title = await _aiService.generateTitle(content);
      final tags = await _aiService.generateTags(content);
      
      final memory = await context.read<MemoryProvider>().createMemory(
        title: title,
        content: content,
        type: MemoryType.text,
        tags: tags,
      );
      
      if (memory != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('记忆已保存，AI生成了标题和${tags.length}个标签')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  Future<void> _quickAddFile(MemoryType type) async {
    // TODO: 实现文件选择和上传
    print('快速添加文件: ${type.displayName}');
  }

  Future<void> _recordAudio() async {
    // TODO: 实现录音功能
    print('录音功能');
  }

  void _createMemory(BuildContext context, MemoryType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateMemoryScreen(type: type),
      ),
    );
  }

  void _openMemory(Memory memory) {
    // TODO: 实现记忆详情页面
    print('打开记忆: ${memory.title}');
  }

  void _editMemory(Memory memory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMemoryScreen(memory: memory),
      ),
    );
  }

  Future<void> _deleteMemory(Memory memory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationHelper.of(context).memoryDeleteTitle),
        content: Text(LocalizationHelper.of(context).confirmDeleteMemory),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(LocalizationHelper.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              LocalizationHelper.of(context).delete,
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context.read<MemoryProvider>().deleteMemory(memory.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? LocalizationHelper.of(context).deleteMemorySuccess 
              : LocalizationHelper.of(context).deleteMemoryFailed),
            backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
          ),
        );
      }
    }
  }
} 