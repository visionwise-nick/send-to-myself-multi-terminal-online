import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../providers/group_provider.dart';

class MemoryTab extends StatefulWidget {
  const MemoryTab({super.key});

  @override
  State<MemoryTab> createState() => _MemoryTabState();
}

class _MemoryTabState extends State<MemoryTab> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  
  // 数据列表
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _passwords = [];
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _quickTexts = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _tabController = TabController(length: 4, vsync: this);
    
    _loadData();
    _animationController.forward();
    
    // 监听群组变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      groupProvider.addListener(_onGroupChanged);
    });
  }

  @override
  void dispose() {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    groupProvider.removeListener(_onGroupChanged);
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  // 群组变化处理
  void _onGroupChanged() {
    if (mounted) {
      _loadData();
    }
  }
  
  // 加载本地数据
  Future<void> _loadData() async {
    if (!mounted) return; // 检查widget是否还在树中
    
    final prefs = await SharedPreferences.getInstance();
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final currentGroup = groupProvider.currentGroup;
    
    // 如果没有选中群组，清空数据
    if (currentGroup == null) {
      setState(() {
        _notes = [];
        _passwords = [];
        _contacts = [];
        _quickTexts = [];
      });
      return;
    }
    
    // 根据群组ID加载数据
    final groupId = currentGroup['id'];
    setState(() {
      _notes = _parseDataList(prefs.getString('memory_notes_$groupId') ?? '[]');
      _passwords = _parseDataList(prefs.getString('memory_passwords_$groupId') ?? '[]');
      _contacts = _parseDataList(prefs.getString('memory_contacts_$groupId') ?? '[]');
      _quickTexts = _parseDataList(prefs.getString('memory_quick_texts_$groupId') ?? '[]');
    });
  }
  
  List<Map<String, dynamic>> _parseDataList(String jsonString) {
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      return [];
    }
  }
  
  // 保存数据到本地
  Future<void> _saveData() async {
    if (!mounted) return; // 检查widget是否还在树中
    
    final prefs = await SharedPreferences.getInstance();
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final currentGroup = groupProvider.currentGroup;
    
    if (currentGroup == null) return;
    
    // 根据群组ID保存数据
    final groupId = currentGroup['id'];
    await prefs.setString('memory_notes_$groupId', json.encode(_notes));
    await prefs.setString('memory_passwords_$groupId', json.encode(_passwords));
    await prefs.setString('memory_contacts_$groupId', json.encode(_contacts));
    await prefs.setString('memory_quick_texts_$groupId', json.encode(_quickTexts));
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // 顶部统计卡片
          _buildStatsCard(),
          
          // Tab栏
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondaryColor,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(icon: Icon(Icons.note_rounded, size: 18), text: '笔记'),
                Tab(icon: Icon(Icons.key_rounded, size: 18), text: '密码'),
                Tab(icon: Icon(Icons.contacts_rounded, size: 18), text: '联系人'),
                Tab(icon: Icon(Icons.flash_on_rounded, size: 18), text: '快捷文本'),
              ],
            ),
          ),
          
          // Tab内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotesTab(),
                _buildPasswordsTab(),
                _buildContactsTab(),
                _buildQuickTextsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsCard() {
    final totalItems = _notes.length + _passwords.length + _contacts.length + _quickTexts.length;
    final groupProvider = Provider.of<GroupProvider>(context);
    final currentGroup = groupProvider.currentGroup;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentGroup != null ? '${currentGroup['name']} 的记忆' : '我的记忆',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentGroup != null 
                    ? '已保存 $totalItems 项重要信息'
                    : '请选择群组查看记忆',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              currentGroup != null ? '群组存储' : '本地存储',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 笔记Tab
  Widget _buildNotesTab() {
    return _buildDataTab(
      data: _notes,
      emptyIcon: Icons.note_add_rounded,
      emptyTitle: '暂无笔记',
      emptySubtitle: '记录重要信息和想法',
      onAdd: () => _showNoteDialog(),
      itemBuilder: (item, index) => _buildNoteCard(item, index),
    );
  }
  
  // 密码Tab
  Widget _buildPasswordsTab() {
    return _buildDataTab(
      data: _passwords,
      emptyIcon: Icons.security_rounded,
      emptyTitle: '暂无密码',
      emptySubtitle: '安全存储您的账号密码',
      onAdd: () => _showPasswordDialog(),
      itemBuilder: (item, index) => _buildPasswordCard(item, index),
    );
  }
  
  // 联系人Tab
  Widget _buildContactsTab() {
    return _buildDataTab(
      data: _contacts,
      emptyIcon: Icons.person_add_rounded,
      emptyTitle: '暂无联系人',
      emptySubtitle: '保存重要联系人信息',
      onAdd: () => _showContactDialog(),
      itemBuilder: (item, index) => _buildContactCard(item, index),
    );
  }
  
  // 快捷文本Tab
  Widget _buildQuickTextsTab() {
    return _buildDataTab(
      data: _quickTexts,
      emptyIcon: Icons.text_snippet_rounded,
      emptyTitle: '暂无快捷文本',
      emptySubtitle: '保存常用文本和模板',
      onAdd: () => _showQuickTextDialog(),
      itemBuilder: (item, index) => _buildQuickTextCard(item, index),
    );
  }
  
  Widget _buildDataTab({
    required List<Map<String, dynamic>> data,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required VoidCallback onAdd,
    required Widget Function(Map<String, dynamic>, int) itemBuilder,
  }) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: AppTheme.textTertiaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiaryColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('添加'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // 添加按钮
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('添加新项'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        // 数据列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 200 + index * 50),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: itemBuilder(data[index], index),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  // 笔记卡片
  Widget _buildNoteCard(Map<String, dynamic> note, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showNoteDialog(note: note, index: index),
          onLongPress: () => _showDeleteDialog('笔记', () => _deleteItem(_notes, index)),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.note_rounded,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note['title'] ?? '无标题',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                                                      TimeUtils.formatRelativeTime(note['createdAt'], context),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiaryColor,
                      ),
                    ),
                  ],
                ),
                if (note['content'] != null && note['content'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    note['content'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // 密码卡片
  Widget _buildPasswordCard(Map<String, dynamic> password, int index) {
    bool _isPasswordVisible = false;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showPasswordDialog(password: password, index: index),
              onLongPress: () => _showDeleteDialog('密码', () => _deleteItem(_passwords, index)),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.security_rounded,
                          size: 18,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            password['site'] ?? '未知网站',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                            color: AppTheme.textTertiaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '账号: ',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textTertiaryColor,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            password['username'] ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '密码: ',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textTertiaryColor,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _isPasswordVisible 
                              ? (password['password'] ?? '') 
                              : '••••••••',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  // 联系人卡片
  Widget _buildContactCard(Map<String, dynamic> contact, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showContactDialog(contact: contact, index: index),
          onLongPress: () => _showDeleteDialog('联系人', () => _deleteItem(_contacts, index)),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact['name'] ?? '未知联系人',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (contact['phone'] != null && contact['phone'].isNotEmpty)
                        Text(
                          contact['phone'],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      if (contact['email'] != null && contact['email'].isNotEmpty)
                        Text(
                          contact['email'],
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // 快捷文本卡片
  Widget _buildQuickTextCard(Map<String, dynamic> quickText, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showQuickTextDialog(quickText: quickText, index: index),
          onLongPress: () => _showDeleteDialog('快捷文本', () => _deleteItem(_quickTexts, index)),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.flash_on_rounded,
                      size: 18,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        quickText['title'] ?? '无标题',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (quickText['content'] != null && quickText['content'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    quickText['content'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // 删除项目
  void _deleteItem(List<Map<String, dynamic>> list, int index) {
    setState(() {
      list.removeAt(index);
    });
    _saveData();
  }
  
  // 显示删除确认对话框
  void _showDeleteDialog(String itemType, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('删除$itemType'),
        content: Text('确定要删除这个$itemType吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
  
  // 显示笔记对话框
  void _showNoteDialog({Map<String, dynamic>? note, int? index}) {
    final titleController = TextEditingController(text: note?['title'] ?? '');
    final contentController = TextEditingController(text: note?['content'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(note == null ? '添加笔记' : '编辑笔记'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: '内容',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newNote = {
                'title': titleController.text,
                'content': contentController.text,
                'createdAt': note?['createdAt'] ?? DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
              };
              
              setState(() {
                if (index != null) {
                  _notes[index] = newNote;
                } else {
                  _notes.add(newNote);
                }
              });
              
              _saveData();
              Navigator.pop(context);
            },
            child: Text(note == null ? '添加' : '保存'),
          ),
        ],
      ),
    );
  }
  
  // 显示密码对话框
  void _showPasswordDialog({Map<String, dynamic>? password, int? index}) {
    final siteController = TextEditingController(text: password?['site'] ?? '');
    final usernameController = TextEditingController(text: password?['username'] ?? '');
    final passwordController = TextEditingController(text: password?['password'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(password == null ? '添加密码' : '编辑密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: siteController,
              decoration: const InputDecoration(
                labelText: '网站/应用',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: '用户名/邮箱',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPassword = {
                'site': siteController.text,
                'username': usernameController.text,
                'password': passwordController.text,
                'createdAt': password?['createdAt'] ?? DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
              };
              
              setState(() {
                if (index != null) {
                  _passwords[index] = newPassword;
                } else {
                  _passwords.add(newPassword);
                }
              });
              
              _saveData();
              Navigator.pop(context);
            },
            child: Text(password == null ? '添加' : '保存'),
          ),
        ],
      ),
    );
  }
  
  // 显示联系人对话框
  void _showContactDialog({Map<String, dynamic>? contact, int? index}) {
    final nameController = TextEditingController(text: contact?['name'] ?? '');
    final phoneController = TextEditingController(text: contact?['phone'] ?? '');
    final emailController = TextEditingController(text: contact?['email'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(contact == null ? '添加联系人' : '编辑联系人'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '姓名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: '电话',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: '邮箱',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newContact = {
                'name': nameController.text,
                'phone': phoneController.text,
                'email': emailController.text,
                'createdAt': contact?['createdAt'] ?? DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
              };
              
              setState(() {
                if (index != null) {
                  _contacts[index] = newContact;
                } else {
                  _contacts.add(newContact);
                }
              });
              
              _saveData();
              Navigator.pop(context);
            },
            child: Text(contact == null ? '添加' : '保存'),
          ),
        ],
      ),
    );
  }
  
  // 显示快捷文本对话框
  void _showQuickTextDialog({Map<String, dynamic>? quickText, int? index}) {
    final titleController = TextEditingController(text: quickText?['title'] ?? '');
    final contentController = TextEditingController(text: quickText?['content'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(quickText == null ? '添加快捷文本' : '编辑快捷文本'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: '文本内容',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQuickText = {
                'title': titleController.text,
                'content': contentController.text,
                'createdAt': quickText?['createdAt'] ?? DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
              };
              
              setState(() {
                if (index != null) {
                  _quickTexts[index] = newQuickText;
                } else {
                  _quickTexts.add(newQuickText);
                }
              });
              
              _saveData();
              Navigator.pop(context);
            },
            child: Text(quickText == null ? '添加' : '保存'),
          ),
        ],
      ),
    );
  }
} 