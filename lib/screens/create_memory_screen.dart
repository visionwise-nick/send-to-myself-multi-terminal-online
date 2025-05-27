import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/memory_model.dart';
import '../providers/memory_provider.dart';
import '../theme/app_theme.dart';

class CreateMemoryScreen extends StatefulWidget {
  final MemoryType type;

  const CreateMemoryScreen({
    super.key,
    required this.type,
  });

  @override
  State<CreateMemoryScreen> createState() => _CreateMemoryScreenState();
}

class _CreateMemoryScreenState extends State<CreateMemoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  // 通用字段
  final List<String> _tags = [];
  bool _isCreating = false;
  
  // 账号密码专用字段
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();
  
  // 记账专用字段
  final _amountController = TextEditingController();
  String _transactionType = 'expense'; // income/expense
  String _category = '';
  DateTime _selectedDate = DateTime.now();
  
  // 日程专用字段
  DateTime _startTime = DateTime.now();
  DateTime? _endTime;
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _reminderMinutes = 15;
  
  // 待办专用字段
  String _priority = 'medium'; // low/medium/high
  DateTime? _dueDate;
  bool _isCompleted = false;
  
  // URL专用字段
  final _urlController = TextEditingController();
  final _urlDescriptionController = TextEditingController();
  
  // 文件相关
  File? _selectedFile;

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
          _getTypeTitle(),
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
            onPressed: _isCreating ? null : _createMemory,
            child: Text(
              '保存',
              style: AppTheme.bodyStyle.copyWith(
                color: _isCreating ? AppTheme.textTertiaryColor : AppTheme.primaryColor,
                fontWeight: AppTheme.fontWeightMedium,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: _buildTypeSpecificForm(),
      ),
    );
  }

  Widget _buildTypeSpecificForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _getFormContent(),
          SizedBox(height: 24),
          _buildSaveButton(),
          SizedBox(height: 50), // 底部安全间距
        ],
      ),
    );
  }

  Widget _getFormContent() {
    switch (widget.type) {
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
      case MemoryType.image:
      case MemoryType.video:
      case MemoryType.document:
        return _buildFileForm();
      default:
        return _buildTextForm();
    }
  }

  // 文本笔记表单
  Widget _buildTextForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _titleController,
          label: '标题',
          hint: '输入笔记标题',
          required: true,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _contentController,
          label: '内容',
          hint: '写下你的想法...',
          maxLines: 8,
          required: true,
        ),
      ],
    );
  }

  // 账号密码表单
  Widget _buildPasswordForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _titleController,
          label: '网站/应用名称',
          hint: '如：微信、淘宝',
          required: true,
        ),
        SizedBox(height: 16),
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

  // 记账表单
  Widget _buildFinancialForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _titleController,
          label: '消费项目',
          hint: '如：午餐、购物',
          required: true,
        ),
        SizedBox(height: 16),
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

  // 日程表单
  Widget _buildScheduleForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _titleController,
          label: '日程标题',
          hint: '会议、约会等',
          required: true,
        ),
        SizedBox(height: 16),
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

  // 待办表单
  Widget _buildTodoForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _titleController,
          label: '任务',
          hint: '要做什么',
          required: true,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _contentController,
          label: '详细描述',
          hint: '具体要求、注意事项',
          maxLines: 4,
        ),
        SizedBox(height: 16),
        _buildDropdown(
          label: '优先级',
          value: _priority,
          items: [
            DropdownMenuItem(value: 'low', child: Text('低')),
            DropdownMenuItem(value: 'medium', child: Text('中')),
            DropdownMenuItem(value: 'high', child: Text('高')),
          ],
          onChanged: (value) => setState(() => _priority = value!),
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

  // URL表单
  Widget _buildUrlForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _titleController,
          label: '标题',
          hint: '网站或链接名称',
          required: true,
        ),
        SizedBox(height: 16),
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

  // 文件表单
  Widget _buildFileForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _titleController,
          label: '标题',
          hint: '文件描述',
          required: true,
        ),
        SizedBox(height: 16),
        _buildFileUploader(),
        SizedBox(height: 16),
        _buildTextField(
          controller: _contentController,
          label: '描述',
          hint: '文件说明',
          maxLines: 4,
        ),
      ],
    );
  }

  // 通用输入框
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

  // 下拉选择框
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

  // 日期选择器
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

  // 日期时间选择器
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

  // 文件上传器
  Widget _buildFileUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '文件 *',
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: AppTheme.fontWeightMedium,
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedFile != null ? AppTheme.primaryColor : AppTheme.borderColor,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _selectedFile != null
                ? Row(
                    children: [
                      Icon(Icons.attach_file, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFile!.path.split('/').last,
                          style: AppTheme.bodyStyle.copyWith(
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedFile = null),
                        child: Icon(Icons.close, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Icon(Icons.cloud_upload, size: 32, color: AppTheme.textSecondaryColor),
                      SizedBox(height: 8),
                      Text('点击选择文件', style: AppTheme.bodyStyle.copyWith(
                        color: AppTheme.textTertiaryColor,
                      )),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // 保存按钮
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createMemory,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isCreating
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

  String _getTypeTitle() {
    switch (widget.type) {
      case MemoryType.password:
        return '添加账号密码';
      case MemoryType.financial:
        return '记一笔账';
      case MemoryType.schedule:
        return '创建日程';
      case MemoryType.todo:
        return '添加待办';
      case MemoryType.url:
        return '保存链接';
      case MemoryType.image:
        return '保存图片';
      case MemoryType.video:
        return '保存视频';
      case MemoryType.document:
        return '保存文档';
      default:
        return '写笔记';
    }
  }

  Future<void> _pickFile() async {
    // 实现文件选择逻辑
  }

  Future<void> _createMemory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isFileType() && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请选择文件')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      Memory? memory;
      Map<String, dynamic>? data = _buildTypeSpecificData();

      if (_isFileType() && _selectedFile != null) {
        memory = await context.read<MemoryProvider>().createFileMemory(
          title: _titleController.text.trim(),
          file: _selectedFile!,
          description: _contentController.text.trim(),
          data: data,
        );
      } else {
        memory = await context.read<MemoryProvider>().createMemory(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          type: widget.type,
          data: data,
        );
      }

      if (memory != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存成功')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  bool _isFileType() {
    return widget.type == MemoryType.image ||
           widget.type == MemoryType.video ||
           widget.type == MemoryType.document;
  }

  Map<String, dynamic>? _buildTypeSpecificData() {
    switch (widget.type) {
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