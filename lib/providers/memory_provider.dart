import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/memory_model.dart';
import '../services/memory_service.dart';
import '../services/local_storage_service.dart';

class MemoryProvider extends ChangeNotifier {
  final MemoryService _memoryService = MemoryService();
  final LocalStorageService _localStorage = LocalStorageService();
  
  // 状态数据
  List<Memory> _memories = [];
  bool _isLoading = false;
  String? _error;
  String? _currentGroupId;
  
  // 筛选条件
  MemoryType? _selectedType;
  String _searchQuery = '';
  List<String> _selectedTags = [];
  
  // 本地缓存
  static const String _cacheKeyPrefix = 'memories_cache_';
  static const String _lastSyncKey = 'last_sync_time_';
  
  // Getters
  List<Memory> get memories => _memories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  MemoryType? get selectedType => _selectedType;
  String get searchQuery => _searchQuery;
  List<String> get selectedTags => _selectedTags;
  
  // 统计信息
  int get totalMemories => _memories.length;
  Map<MemoryType, int> get memoriesByType {
    final result = <MemoryType, int>{};
    for (final memory in _memories) {
      result[memory.type] = (result[memory.type] ?? 0) + 1;
    }
    return result;
  }
  
  // =================== 初始化 ===================
  
  /// 初始化记忆数据
  Future<void> initialize({String? groupId}) async {
    _currentGroupId = groupId;
    await _loadFromCache();
    await loadMemories();
  }
  
  // =================== 记忆基础操作 ===================
  
  /// 加载记忆列表
  Future<void> loadMemories({bool refresh = false}) async {
    if (refresh) {
      _memories.clear();
    }
    
    if (_isLoading) return;
    
    // 如果不是强制刷新且不需要同步，则直接返回缓存数据
    if (!refresh && !await _needsSync() && _memories.isNotEmpty) {
      print('使用缓存数据，无需同步');
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _memoryService.getMemories(
        limit: 100,
        groupId: _currentGroupId,
        type: _selectedType?.value,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        tags: _selectedTags.isNotEmpty ? _selectedTags : null,
      );
      
      final newMemories = (result['memories'] as List)
          .map((json) => Memory.fromJson(json))
          .toList();
      
      _memories = newMemories;
      
      // 保存到缓存
      await _saveToCache();
      
      print('从服务器加载了${_memories.length}条记忆');
      
    } catch (e) {
      _error = e.toString();
      print('加载记忆失败: $e');
      
      // 如果网络失败，尝试使用缓存
      if (_memories.isEmpty) {
        await _loadFromCache();
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  /// 创建记忆
  Future<Memory?> createMemory({
    required String title,
    required String content,
    required MemoryType type,
    List<String>? tags,
    Map<String, dynamic>? data,
  }) async {
    try {
      _error = null;
      
      final result = await _memoryService.createMemory(
        title: title,
        content: content,
        type: type.value,
        groupId: _currentGroupId,
        tags: tags,
        data: data,
      );
      
      final memory = Memory.fromJson(result);
      _memories.insert(0, memory);
      
      // 立即保存到缓存
      await _saveToCache();
      
      notifyListeners();
      return memory;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      print('创建记忆失败: $e');
      return null;
    }
  }
  
  /// 创建文件记忆
  Future<Memory?> createFileMemory({
    required String title,
    required File file,
    String? description,
    List<String>? tags,
    Map<String, dynamic>? data,
  }) async {
    try {
      _error = null;
      
      final result = await _memoryService.createFileMemory(
        title: title,
        file: file,
        description: description,
        groupId: _currentGroupId,
        tags: tags,
        data: data,
      );
      
      final memory = Memory.fromJson(result);
      _memories.insert(0, memory);
      
      // 立即保存到缓存
      await _saveToCache();
      
      notifyListeners();
      return memory;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      print('创建文件记忆失败: $e');
      return null;
    }
  }
  
  /// 更新记忆
  Future<bool> updateMemory({
    required String memoryId,
    String? title,
    String? content,
    List<String>? tags,
    Map<String, dynamic>? data,
  }) async {
    try {
      _error = null;
      
      final result = await _memoryService.updateMemory(
        memoryId: memoryId,
        title: title,
        content: content,
        tags: tags,
        data: data,
      );
      
      // 更新本地记忆
      final index = _memories.indexWhere((m) => m.id == memoryId);
      if (index != -1) {
        _memories[index] = Memory.fromJson(result);
        
        // 立即保存到缓存
        await _saveToCache();
        
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      print('更新记忆失败: $e');
      return false;
    }
  }
  
  /// 删除记忆
  Future<bool> deleteMemory(String memoryId) async {
    try {
      _error = null;
      
      await _memoryService.deleteMemory(memoryId);
      
      // 从本地列表移除
      _memories.removeWhere((m) => m.id == memoryId);
      
      // 立即保存到缓存
      await _saveToCache();
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      print('删除记忆失败: $e');
      return false;
    }
  }
  
  // =================== 搜索和筛选 ===================
  
  /// 设置类型筛选
  void setSelectedType(MemoryType? type) {
    if (_selectedType != type) {
      _selectedType = type;
      loadMemories(refresh: true);
    }
  }
  
  /// 设置搜索查询
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      loadMemories(refresh: true);
    }
  }
  
  /// 添加标签筛选
  void addTagFilter(String tag) {
    if (!_selectedTags.contains(tag)) {
      _selectedTags.add(tag);
      loadMemories(refresh: true);
    }
  }
  
  /// 移除标签筛选
  void removeTagFilter(String tag) {
    if (_selectedTags.remove(tag)) {
      loadMemories(refresh: true);
    }
  }
  
  /// 清除所有筛选
  void clearFilters() {
    _selectedType = null;
    _searchQuery = '';
    _selectedTags.clear();
    loadMemories(refresh: true);
  }
  
  /// 搜索记忆
  Future<List<Memory>> searchMemories(String query) async {
    try {
      final result = await _memoryService.searchMemories(
        query: query,
        limit: 50,
      );
      
      return (result['memories'] as List)
          .map((json) => Memory.fromJson(json))
          .toList();
    } catch (e) {
      print('搜索记忆失败: $e');
      return [];
    }
  }
  
  // =================== 其他功能 ===================
  
  /// 清除错误信息
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// 刷新所有数据
  Future<void> refreshAll() async {
    await loadMemories(refresh: true);
  }
  
  /// 根据ID获取记忆
  Memory? getMemoryById(String id) {
    try {
      return _memories.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// 根据类型获取记忆
  List<Memory> getMemoriesByType(MemoryType type) {
    return _memories.where((m) => m.type == type).toList();
  }
  
  /// 获取最近记忆
  List<Memory> getRecentMemories([int limit = 10]) {
    final sortedMemories = [..._memories];
    sortedMemories.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sortedMemories.take(limit).toList();
  }

  // =================== 本地缓存相关 ===================

  /// 设置当前群组ID
  void setCurrentGroupId(String? groupId) {
    if (_currentGroupId != groupId) {
      _currentGroupId = groupId;
      _memories.clear();
      initialize(groupId: groupId);
    }
  }

  /// 从本地缓存加载记忆
  Future<void> _loadFromCache() async {
    if (_currentGroupId == null) return;
    
    try {
      final memoriesJson = await _localStorage.loadMemories(_currentGroupId!);
      _memories = memoriesJson.map((json) => Memory.fromJson(json)).toList();
      print('从持久化存储加载了${_memories.length}条记忆');
      notifyListeners();
    } catch (e) {
      print('从持久化存储加载记忆失败: $e');
      
      // 尝试从旧版本存储加载
      try {
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = _getCacheKey();
        final cachedData = prefs.getString(cacheKey);
        
        if (cachedData != null) {
          final jsonList = jsonDecode(cachedData) as List;
          _memories = jsonList.map((json) => Memory.fromJson(json)).toList();
          print('从旧版存储迁移了${_memories.length}条记忆');
          
          // 迁移到新存储
          final memoriesJson = _memories.map((memory) => memory.toJson()).toList();
          await _localStorage.saveMemories(_currentGroupId!, memoriesJson);
          
          notifyListeners();
        }
      } catch (legacyError) {
        print('旧版存储迁移失败: $legacyError');
      }
    }
  }

  /// 保存记忆到本地缓存
  Future<void> _saveToCache() async {
    if (_currentGroupId == null) return;
    
    try {
      final memoriesJson = _memories.map((memory) => memory.toJson()).toList();
      await _localStorage.saveMemories(_currentGroupId!, memoriesJson);
      
      // 更新最后同步时间到SharedPreferences（用于同步逻辑）
      final prefs = await SharedPreferences.getInstance();
      final syncKey = _getSyncTimeKey();
      await prefs.setString(syncKey, DateTime.now().toIso8601String());
      
      print('已保存${_memories.length}条记忆到持久化存储');
    } catch (e) {
      print('保存到持久化存储失败: $e');
      
      // 如果新存储失败，尝试保存到SharedPreferences作为后备
      try {
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = _getCacheKey();
        final jsonList = _memories.map((memory) => memory.toJson()).toList();
        await prefs.setString(cacheKey, jsonEncode(jsonList));
        
        // 更新最后同步时间
        final syncKey = _getSyncTimeKey();
        await prefs.setString(syncKey, DateTime.now().toIso8601String());
        
        print('已保存${_memories.length}条记忆到SharedPreferences备份');
      } catch (backupError) {
        print('备份保存也失败: $backupError');
      }
    }
  }

  /// 获取缓存键
  String _getCacheKey() {
    return '$_cacheKeyPrefix${_currentGroupId ?? 'default'}';
  }

  /// 获取同步时间键
  String _getSyncTimeKey() {
    return '$_lastSyncKey${_currentGroupId ?? 'default'}';
  }

  /// 检查是否需要同步
  Future<bool> _needsSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncKey = _getSyncTimeKey();
      final lastSyncStr = prefs.getString(syncKey);
      
      if (lastSyncStr == null) return true;
      
      final lastSync = DateTime.parse(lastSyncStr);
      final now = DateTime.now();
      
      // 如果距离上次同步超过5分钟，则需要同步
      return now.difference(lastSync).inMinutes > 5;
    } catch (e) {
      return true; // 出错时强制同步
    }
  }
} 