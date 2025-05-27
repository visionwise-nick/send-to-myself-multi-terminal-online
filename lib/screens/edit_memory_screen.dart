import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memory_model.dart';
import '../providers/memory_provider.dart';
import '../theme/app_theme.dart';
import '../services/ai_service.dart';

class EditMemoryScreen extends StatefulWidget {
  final Memory memory;

  const EditMemoryScreen({
    super.key,
    required this.memory,
  });

  @override
  State<EditMemoryScreen> createState() => _EditMemoryScreenState();
}

class _EditMemoryScreenState extends State<EditMemoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final AIService _aiService = AIService();
  
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  
  // 特定类型的控制器
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _websiteController;
  late TextEditingController _notesController;
  late TextEditingController _amountController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _urlController;
  late TextEditingController _urlDescriptionController;
  
  // 特定类型的状态
  String _transactionType = 'expense';
  String _category = '';
  DateTime _selectedDate = DateTime.now();
  DateTime _startTime = DateTime.now();
  DateTime? _endTime;
  int _reminderMinutes = 15;
  String _priority = 'medium';
  DateTime? _dueDate;
  bool _isCompleted = false;
  
  List<String> _tags = [];
  bool _isUpdating = false;
  bool _isGeneratingTags = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadMemoryData();
  }

  void _initializeControllers() {
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _websiteController = TextEditingController();
    _notesController = TextEditingController();
    _amountController = TextEditingController();
    _locationController = TextEditingController();
    _descriptionController = TextEditingController();
    _urlController = TextEditingController();
    _urlDescriptionController = TextEditingController();
  }

  void _loadMemoryData() {
    _titleController.text = widget.memory.title;
    _contentController.text = widget.memory.content;
    _tags = List<String>.from(widget.memory.tags);
    
    // 根据类型加载特定数据
    switch (widget.memory.type) {
      case MemoryType.password:
        final data = widget.memory.passwordData;
        if (data != null) {
          _usernameController.text = data['username'] ?? '';
          _passwordController.text = data['password'] ?? '';
          _websiteController.text = data['website'] ?? '';
          _notesController.text = data['notes'] ?? '';
        }
        break;
        
      case MemoryType.financial:
        final data = widget.memory.financialData;
        if (data != null) {
          _amountController.text = (data['amount'] ?? 0.0).toString();
          _transactionType = (data['isIncome'] ?? false) ? 'income' : 'expense';
          _category = data['category'] ?? '';
          if (data['date'] != null) {
            _selectedDate = DateTime.parse(data['date']);
          }
          _contentController.text = data['notes'] ?? '';
        }
        break;
        
      case MemoryType.schedule:
        final data = widget.memory.scheduleData;
        if (data != null) {
          if (data['startTime'] != null) {
            _startTime = DateTime.parse(data['startTime']);
          }
          if (data['endTime'] != null) {
            _endTime = DateTime.parse(data['endTime']);
          }
          _locationController.text = data['location'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _reminderMinutes = data['reminder'] ?? 15;
        }
        break;
        
      case MemoryType.todo:
        final data = widget.memory.todoData;
        if (data != null) {
          _isCompleted = data['isCompleted'] ?? false;
          _priority = data['priority'] ?? 'medium';
          if (data['dueDate'] != null) {
            _dueDate = DateTime.parse(data['dueDate']);
          }
          _descriptionController.text = data['description'] ?? '';
        }
        break;
        
      case MemoryType.url:
        final data = widget.memory.urlData;
        if (data != null) {
          _urlController.text = data['url'] ?? '';
          _urlDescriptionController.text = data['description'] ?? '';
        }
        break;
        
      default:
        break;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _urlDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          '编辑${widget.memory.type.displayName}',
          style: AppTheme.titleStyle.copyWith(
            fontWeight: AppTheme.fontWeightMedium,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.textSecondaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isUpdating ? null : _updateMemory,
            child: Text(
              '保存',
              style: AppTheme.bodyStyle.copyWith(
                color: _isUpdating ? AppTheme.textTertiaryColor : AppTheme.primaryColor,
                fontWeight: AppTheme.fontWeightMedium,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              _buildTextField(
                controller: _titleController,
                label: '标题',
                hint: '输入标题',
                required: true,
              ),
              
              SizedBox(height: 16),
              
              // 根据类型显示不同的编辑表单
              _buildTypeSpecificForm(),
              
              SizedBox(height: 24),
              
              // 标签编辑
              _buildTagsSection(),
              
              SizedBox(height: 24),
              
              // 保存按钮
              _buildSaveButton(),
              
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSpecificForm() {
    switch (widget.memory.type) {
      case MemoryType.password:
        return _buildPasswordForm();
      case MemoryType.financial:
        return _buildFinancialForm();
      case MemoryType.schedule:
        return _buildScheduleForm();
      case MemoryType.todo:
        return _buildTodoForm();
      case MemoryType.url:
        return _buildUrlForm();
      default:
        return _buildTextForm();
    }
  }

  Widget _buildTextForm() {
    return _buildTextField(
      controller: _contentController,
      label: '内容',
      hint: '输入内容',
      maxLines: 8,
      required: true,
    );
  }

  Widget _buildPasswordForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _websiteController,
          label: '网站地址',
          hint: 'https://...',
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _usernameController,
          label: '用户名/邮箱',
          hint: '登录账号',
          required: true,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: '密码',
          hint: '登录密码',
          obscureText: true,
          required: true,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _notesController,
          label: '备注',
          hint: '其他信息',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildFinancialForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _amountController,
                label: '金额',
                hint: '0.00',
                keyboardType: TextInputType.number,
                required: true,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildDropdown(
                label: '类型',
                value: _transactionType,
                items: [
                  DropdownMenuItem(value: 'expense', child: Text('支出')),
                  DropdownMenuItem(value: 'income', child: Text('收入')),
                ],
                onChanged: (value) => setState(() => _transactionType = value!),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: TextEditingController(text: _category),
          label: '分类',
          hint: '如：餐饮、交通',
          onChanged: (value) => _category = value,
        ),
        SizedBox(height: 16),
        _buildDatePicker(
          label: '日期',
          date: _selectedDate,
          onChanged: (date) => setState(() => _selectedDate = date),
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _contentController,
          label: '备注',
          hint: '详细说明',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildScheduleForm() {
    return Column(
      children: [
        _buildDateTimePicker(
          label: '开始时间',
          dateTime: _startTime,
          onChanged: (dateTime) => setState(() => _startTime = dateTime),
        ),
        SizedBox(height: 16),
        _buildDateTimePicker(
          label: '结束时间（可选）',
          dateTime: _endTime,
          onChanged: (dateTime) => setState(() => _endTime = dateTime),
          allowNull: true,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _locationController,
          label: '地点',
          hint: '会议室、餐厅等',
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _descriptionController,
          label: '详情',
          hint: '会议内容、注意事项',
          maxLines: 3,
        ),
        SizedBox(height: 16),
        _buildDropdown(
          label: '提前提醒',
          value: _reminderMinutes,
          items: [
            DropdownMenuItem(value: 0, child: Text('不提醒')),
            DropdownMenuItem(value: 5, child: Text('5分钟前')),
            DropdownMenuItem(value: 15, child: Text('15分钟前')),
            DropdownMenuItem(value: 30, child: Text('30分钟前')),
            DropdownMenuItem(value: 60, child: Text('1小时前')),
          ],
          onChanged: (value) => setState(() => _reminderMinutes = value!),
        ),
      ],
    );
  }

  Widget _buildTodoForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _contentController,
          label: '详细描述',
          hint: '具体要求、注意事项',
          maxLines: 4,
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                label: '优先级',
                value: _priority,
                items: [
                  DropdownMenuItem(value: 'low', child: Text('低')),
                  DropdownMenuItem(value: 'medium', child: Text('中')),
                  DropdownMenuItem(value: 'high', child: Text('高')),
                ],
                onChanged: (value) => setState(() => _priority = value!),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Checkbox(
                    value: _isCompleted,
                    onChanged: (value) => setState(() => _isCompleted = value ?? false),
                    activeColor: AppTheme.primaryColor,
                  ),
                  Text('已完成', style: AppTheme.bodyStyle),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildDatePicker(
          label: '截止日期（可选）',
          date: _dueDate,
          onChanged: (date) => setState(() => _dueDate = date),
          allowNull: true,
        ),
      ],
    );
  }

  Widget _buildUrlForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _urlController,
          label: 'URL链接',
          hint: 'https://...',
          required: true,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _urlDescriptionController,
          label: '描述',
          hint: '这个链接的用途或内容',
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '标签',
              style: AppTheme.bodyStyle.copyWith(
                fontWeight: AppTheme.fontWeightMedium,
              ),
            ),
            Spacer(),
            TextButton.icon(
              onPressed: _isGeneratingTags ? null : _generateTagsFromContent,
              icon: _isGeneratingTags 
                ? SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.auto_awesome, size: 16),
              label: Text(
                _isGeneratingTags ? '生成中...' : 'AI生成',
                style: AppTheme.captionStyle,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._tags.map((tag) => _buildTagChip(tag)),
            _buildAddTagChip(),
          ],
        ),
      ],
    );
  }

  Widget _buildTagChip(String tag) {
    return Chip(
      label: Text(tag, style: AppTheme.smallStyle),
      deleteIcon: Icon(Icons.close, size: 14),
      onDeleted: () {
        setState(() {
          _tags.remove(tag);
        });
      },
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      deleteIconColor: AppTheme.textSecondaryColor,
    );
  }

  Widget _buildAddTagChip() {
    return ActionChip(
      label: Text('添加标签', style: AppTheme.smallStyle),
      avatar: Icon(Icons.add, size: 14),
      onPressed: _showAddTagDialog,
      backgroundColor: AppTheme.surfaceColor,
    );
  }

  void _showAddTagDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: Text('添加标签', style: AppTheme.titleStyle),
        content: TextField(
          controller: controller,
          style: AppTheme.bodyStyle,
          decoration: InputDecoration(
            hintText: '输入标签名称',
            hintStyle: AppTheme.bodyStyle.copyWith(
              color: AppTheme.textTertiaryColor,
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty && !_tags.contains(value.trim())) {
              setState(() {
                _tags.add(value.trim());
              });
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: AppTheme.bodyStyle),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty && !_tags.contains(value)) {
                setState(() {
                  _tags.add(value);
                });
              }
              Navigator.pop(context);
            },
            child: Text(
              '添加',
              style: AppTheme.bodyStyle.copyWith(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateTagsFromContent() async {
    final content = _getContentForTags();
    if (content.isEmpty) return;
    
    setState(() {
      _isGeneratingTags = true;
    });
    
    try {
      final newTags = await _aiService.generateTags(content);
      setState(() {
        // 只添加不重复的标签
        for (final tag in newTags) {
          if (!_tags.contains(tag)) {
            _tags.add(tag);
          }
        }
      });
      
      if (newTags.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI生成了${newTags.length}个新标签')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成标签失败: $e')),
      );
    } finally {
      setState(() {
        _isGeneratingTags = false;
      });
    }
  }

  String _getContentForTags() {
    final parts = <String>[];
    parts.add(_titleController.text);
    if (_contentController.text.isNotEmpty) {
      parts.add(_contentController.text);
    }
    return parts.join(' ');
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    bool obscureText = false,
    bool required = false,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: AppTheme.fontWeightMedium,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: AppTheme.bodyStyle,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.bodyStyle.copyWith(
              color: AppTheme.textTertiaryColor,
            ),
            filled: true,
            fillColor: AppTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
            ),
            contentPadding: EdgeInsets.all(12),
          ),
          validator: required ? (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入$label';
            }
            return null;
          } : null,
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: AppTheme.fontWeightMedium,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: AppTheme.bodyStyle,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
            ),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required Function(DateTime) onChanged,
    bool allowNull = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: AppTheme.fontWeightMedium,
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: AppTheme.textSecondaryColor),
                SizedBox(width: 8),
                Text(
                  date != null 
                    ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                    : '选择日期',
                  style: AppTheme.bodyStyle.copyWith(
                    color: date != null ? AppTheme.textPrimaryColor : AppTheme.textTertiaryColor,
                  ),
                ),
                if (allowNull && date != null) ...[
                  Spacer(),
                  GestureDetector(
                    onTap: () => onChanged(DateTime.now()),
                    child: Icon(Icons.clear, size: 20, color: AppTheme.textSecondaryColor),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime? dateTime,
    required Function(DateTime) onChanged,
    bool allowNull = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: AppTheme.fontWeightMedium,
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: dateTime ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(dateTime ?? DateTime.now()),
              );
              if (time != null) {
                onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
              }
            }
          },
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 20, color: AppTheme.textSecondaryColor),
                SizedBox(width: 8),
                Text(
                  dateTime != null 
                    ? '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'
                    : '选择时间',
                  style: AppTheme.bodyStyle.copyWith(
                    color: dateTime != null ? AppTheme.textPrimaryColor : AppTheme.textTertiaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isUpdating ? null : _updateMemory,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isUpdating
            ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : Text(
                '保存',
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: AppTheme.fontWeightMedium,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _updateMemory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final data = _buildTypeSpecificData();

      final success = await context.read<MemoryProvider>().updateMemory(
        memoryId: widget.memory.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: _tags,
        data: data,
      );

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新成功')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新失败: $e')),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Map<String, dynamic>? _buildTypeSpecificData() {
    switch (widget.memory.type) {
      case MemoryType.password:
        return {
          'username': _usernameController.text.trim(),
          'password': _passwordController.text.trim(),
          'website': _websiteController.text.trim(),
          'notes': _notesController.text.trim(),
        };
      case MemoryType.financial:
        return {
          'amount': double.tryParse(_amountController.text) ?? 0.0,
          'isIncome': _transactionType == 'income',
          'category': _category,
          'date': _selectedDate.toIso8601String(),
          'notes': _contentController.text.trim(),
        };
      case MemoryType.schedule:
        return {
          'startTime': _startTime.toIso8601String(),
          'endTime': _endTime?.toIso8601String(),
          'location': _locationController.text.trim(),
          'description': _descriptionController.text.trim(),
          'reminder': _reminderMinutes,
        };
      case MemoryType.todo:
        return {
          'isCompleted': _isCompleted,
          'priority': _priority,
          'dueDate': _dueDate?.toIso8601String(),
          'description': _contentController.text.trim(),
        };
      case MemoryType.url:
        return {
          'url': _urlController.text.trim(),
          'description': _urlDescriptionController.text.trim(),
          'favicon': '', // TODO: 获取favicon
        };
      default:
        return null;
    }
  }
} 