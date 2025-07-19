import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memory_model.dart';
import '../providers/memory_provider.dart';
import '../theme/app_theme.dart';
import '../services/ai_service.dart';
import '../utils/localization_helper.dart';

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
          LocalizationHelper.of(context).editMemory,
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
              LocalizationHelper.of(context).save,
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
                label: LocalizationHelper.of(context).title,
                hint: LocalizationHelper.of(context).enterTitle,
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
      label: LocalizationHelper.of(context).content,
      hint: LocalizationHelper.of(context).enterContent,
      maxLines: 8,
      required: true,
    );
  }

  Widget _buildPasswordForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _websiteController,
          label: LocalizationHelper.of(context).websiteAddress,
          hint: LocalizationHelper.of(context).https,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _usernameController,
          label: LocalizationHelper.of(context).usernameEmail,
          hint: LocalizationHelper.of(context).loginAccount,
          required: true,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: LocalizationHelper.of(context).password,
          hint: LocalizationHelper.of(context).loginPassword,
          obscureText: true,
          required: true,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _notesController,
          label: LocalizationHelper.of(context).notes,
          hint: LocalizationHelper.of(context).otherInformation,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildFinancialForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _titleController,
          label: LocalizationHelper.of(context).expenseItemLabel,
          hint: LocalizationHelper.of(context).expenseItemHint,
          required: true,
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _amountController,
                label: LocalizationHelper.of(context).amount,
                hint: LocalizationHelper.of(context).zeroZero,
                keyboardType: TextInputType.number,
                required: true,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildDropdown(
                label: LocalizationHelper.of(context).type,
                value: _transactionType,
                items: [
                  DropdownMenuItem(value: 'expense', child: Text(LocalizationHelper.of(context).expense)),
                  DropdownMenuItem(value: 'income', child: Text(LocalizationHelper.of(context).income)),
                ],
                onChanged: (value) => setState(() => _transactionType = value!),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: TextEditingController(text: _category),
          label: LocalizationHelper.of(context).category,
          hint: '${LocalizationHelper.of(context).eg}${LocalizationHelper.of(context).catering}、${LocalizationHelper.of(context).transportation}',
          onChanged: (value) => _category = value,
        ),
        SizedBox(height: 16),
        _buildDatePicker(
          label: LocalizationHelper.of(context).date,
          date: _selectedDate,
          onChanged: (date) => setState(() => _selectedDate = date),
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _contentController,
          label: LocalizationHelper.of(context).notes,
          hint: LocalizationHelper.of(context).detailedExplanation,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildScheduleForm() {
    return Column(
      children: [
        _buildDateTimePicker(
          label: LocalizationHelper.of(context).startTime,
          dateTime: _startTime,
          onChanged: (dateTime) => setState(() => _startTime = dateTime),
        ),
        SizedBox(height: 16),
        _buildDateTimePicker(
          label: LocalizationHelper.of(context).endTimeOptional,
          dateTime: _endTime,
          onChanged: (dateTime) => setState(() => _endTime = dateTime),
          allowNull: true,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _locationController,
          label: LocalizationHelper.of(context).location,
          hint: LocalizationHelper.of(context).conferenceRoomRestaurant,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _descriptionController,
          label: LocalizationHelper.of(context).details,
          hint: LocalizationHelper.of(context).meetingContentNotes,
          maxLines: 3,
        ),
        SizedBox(height: 16),
        _buildDropdown(
          label: LocalizationHelper.of(context).reminder,
          value: _reminderMinutes,
          items: [
            DropdownMenuItem(value: 0, child: Text(LocalizationHelper.of(context).noReminder)),
            DropdownMenuItem(value: 5, child: Text(LocalizationHelper.of(context).fiveMinutesBefore)),
            DropdownMenuItem(value: 15, child: Text(LocalizationHelper.of(context).fifteenMinutesBefore)),
            DropdownMenuItem(value: 30, child: Text(LocalizationHelper.of(context).thirtyMinutesBefore)),
            DropdownMenuItem(value: 60, child: Text(LocalizationHelper.of(context).oneHourBefore)),
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
          label: LocalizationHelper.of(context).detailedDescription,
          hint: LocalizationHelper.of(context).specificRequirementsNotes,
          maxLines: 4,
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                label: LocalizationHelper.of(context).priority,
                value: _priority,
                items: [
                  DropdownMenuItem(value: 'low', child: Text(LocalizationHelper.of(context).low)),
                  DropdownMenuItem(value: 'medium', child: Text(LocalizationHelper.of(context).medium)),
                  DropdownMenuItem(value: 'high', child: Text(LocalizationHelper.of(context).high)),
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
                  Text(LocalizationHelper.of(context).completed, style: AppTheme.bodyStyle),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildDatePicker(
          label: LocalizationHelper.of(context).dueDateOptional,
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
          label: LocalizationHelper.of(context).urlLink,
          hint: LocalizationHelper.of(context).https,
          required: true,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _urlDescriptionController,
          label: LocalizationHelper.of(context).description,
          hint: LocalizationHelper.of(context).purposeOrContent,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocalizationHelper.of(context).tags,
          style: Theme.of(context).textTheme.titleMedium,
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
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: TextEditingController(),
                label: '',
                hint: LocalizationHelper.of(context).addTag,
                onSubmitted: (tag) {
                  if (tag.isNotEmpty && !_tags.contains(tag)) {
                    setState(() {
                      _tags.add(tag);
                    });
                  }
                },
              ),
            ),
            SizedBox(width: 8),
            _isGeneratingTags
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
                    tooltip: LocalizationHelper.of(context).generateTags,
                    onPressed: _generateTags,
                  ),
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
      label: Text(LocalizationHelper.of(context).addTag, style: AppTheme.smallStyle),
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
        title: Text(LocalizationHelper.of(context).addTag, style: AppTheme.titleStyle),
        content: TextField(
          controller: controller,
          style: AppTheme.bodyStyle,
          decoration: InputDecoration(
            hintText: LocalizationHelper.of(context).enterTagName,
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
            child: Text(LocalizationHelper.of(context).cancel, style: AppTheme.bodyStyle),
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
              LocalizationHelper.of(context).add,
              style: AppTheme.bodyStyle.copyWith(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateTags() async {
    setState(() {
      _isGeneratingTags = true;
    });
    
    try {
      final content = '${_titleController.text} ${_contentController.text}';
      final tags = await _aiService.generateTags(content);
      
      setState(() {
        _tags = tags;
        _isGeneratingTags = false;
      });
    } catch (e) {
      setState(() {
        _isGeneratingTags = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${LocalizationHelper.of(context).generatingTags}: $e')),
      );
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
    Function(String)? onSubmitted,
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
          onFieldSubmitted: onSubmitted,
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
                    : LocalizationHelper.of(context).selectDate,
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
                    : LocalizationHelper.of(context).selectTime,
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
                LocalizationHelper.of(context).save,
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
          SnackBar(content: Text(LocalizationHelper.of(context).updateSuccess)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${LocalizationHelper.of(context).updateFailed}: $e')),
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