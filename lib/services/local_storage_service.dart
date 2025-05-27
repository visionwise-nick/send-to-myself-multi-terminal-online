import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

/// 本地存储服务
/// 使用应用支持目录存储重要数据，确保应用更新后数据不丢失
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _chatDataDir = 'chat_data';
  static const String _memoryDataDir = 'memory_data';
  static const String _userDataDir = 'user_data';
  static const String _filesCacheDir = 'files_cache'; // 永久文件缓存目录
  static const String _fileMappingFile = 'file_mapping.json'; // 文件映射表
  
  /// 获取应用支持目录（应用更新后路径不变）
  Future<Directory> get _permanentDirectory async {
    try {
      // 优先使用 Application Support 目录（iOS/macOS应用更新后路径不变）
      final appSupportDir = await getApplicationSupportDirectory();
      return appSupportDir;
    } catch (e) {
      print('获取Application Support目录失败，使用Documents目录: $e');
      // 备用：使用Documents目录
      return await getApplicationDocumentsDirectory();
    }
  }

  /// 确保目录存在
  Future<Directory> _ensureDirectoryExists(String path) async {
    final baseDir = await _permanentDirectory;
    final directory = Directory('${baseDir.path}/$path');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      print('创建目录: ${directory.path}');
    }
    return directory;
  }

  /// 复制文件到永久目录（发送和接收时都调用）
  Future<String?> copyFileToPermanentStorage(String sourceFilePath, String fileName, {String? fileUrl}) async {
    try {
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) {
        print('源文件不存在: $sourceFilePath');
        return null;
      }

      final directory = await _ensureDirectoryExists(_filesCacheDir);
      
      // 生成唯一的文件名，避免冲突
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(fileName);
      final baseName = path.basenameWithoutExtension(fileName);
      final uniqueFileName = '${baseName}_$timestamp$extension';
      
      final targetFile = File('${directory.path}/$uniqueFileName');
      
      // 复制文件
      await sourceFile.copy(targetFile.path);
      
      final fileSize = await targetFile.length();
      
      // 更新文件映射表
      if (fileUrl != null) {
        await _updateFileMapping(fileUrl, targetFile.path, fileName, fileSize);
      }
      
      print('文件已复制到永久存储: $fileName -> ${targetFile.path}');
      return targetFile.path;
    } catch (e) {
      print('复制文件到永久存储失败: $e');
      return null;
    }
  }

  // =================== 聊天数据存储 ===================

  /// 保存聊天消息到持久化存储
  Future<void> saveChatMessages(String conversationId, List<Map<String, dynamic>> messages) async {
    try {
      final directory = await _ensureDirectoryExists(_chatDataDir);
      final file = File('${directory.path}/chat_$conversationId.json');
      
      // 备份数据到SharedPreferences（双重保险）
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backup_chat_$conversationId', jsonEncode(messages));
      
      // 保存到永久目录
      await file.writeAsString(jsonEncode(messages));
      print('聊天消息已保存到永久存储: ${file.path}');
    } catch (e) {
      print('保存聊天消息失败: $e');
      // 尝试仅保存到SharedPreferences作为后备
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('chat_messages_$conversationId', jsonEncode(messages));
      } catch (backupError) {
        print('备份保存也失败: $backupError');
      }
    }
  }

  /// 从持久化存储加载聊天消息
  Future<List<Map<String, dynamic>>> loadChatMessages(String conversationId) async {
    try {
      // 首先尝试从永久目录读取
      final directory = await _ensureDirectoryExists(_chatDataDir);
      final file = File('${directory.path}/chat_$conversationId.json');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final messages = jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
        print('从永久存储加载了${messages.length}条聊天消息');
        return messages;
      }
      
      // 如果永久目录没有，尝试从SharedPreferences读取
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString('backup_chat_$conversationId');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final messages = jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
        print('从SharedPreferences备份加载了${messages.length}条聊天消息');
        
        // 迁移到永久目录
        await saveChatMessages(conversationId, messages);
        return messages;
      }
      
      // 兼容旧版本数据
      jsonString = prefs.getString('chat_messages_$conversationId');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final messages = jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
        print('从旧版存储迁移了${messages.length}条聊天消息');
        
        // 迁移到新存储
        await saveChatMessages(conversationId, messages);
        return messages;
      }
      
    } catch (e) {
      print('加载聊天消息失败: $e');
    }
    
    return [];
  }

  /// 删除指定对话的聊天数据
  Future<void> deleteChatMessages(String conversationId) async {
    try {
      final directory = await _ensureDirectoryExists(_chatDataDir);
      final file = File('${directory.path}/chat_$conversationId.json');
      
      if (await file.exists()) {
        await file.delete();
      }
      
      // 同时删除SharedPreferences中的备份
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('backup_chat_$conversationId');
      await prefs.remove('chat_messages_$conversationId');
      
      print('已删除对话数据: $conversationId');
    } catch (e) {
      print('删除聊天数据失败: $e');
    }
  }

  // =================== 文件缓存管理 ===================

  /// 保存文件到永久缓存
  Future<String?> saveFileToCache(String fileUrl, List<int> fileData, String fileName) async {
    try {
      final directory = await _ensureDirectoryExists(_filesCacheDir);
      
      // 生成唯一的文件名，避免冲突
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(fileName);
      final baseName = path.basenameWithoutExtension(fileName);
      final uniqueFileName = '${baseName}_$timestamp$extension';
      
      final file = File('${directory.path}/$uniqueFileName');
      await file.writeAsBytes(fileData);
      
      // 更新文件映射表
      await _updateFileMapping(fileUrl, file.path, fileName, fileData.length);
      
      print('文件已保存到永久缓存: $fileName -> ${file.path}');
      return file.path;
    } catch (e) {
      print('保存文件到缓存失败: $e');
      return null;
    }
  }

  /// 从缓存获取文件路径
  Future<String?> getFileFromCache(String fileUrl) async {
    try {
      final mapping = await _loadFileMapping();
      final fileInfo = mapping[fileUrl];
      
      if (fileInfo != null) {
        final filePath = fileInfo['path'] as String;
        if (await File(filePath).exists()) {
          print('从永久缓存找到文件: $fileUrl -> $filePath');
          return filePath;
        } else {
          // 文件不存在，清理映射
          print('缓存文件不存在，清理映射: $filePath');
          await _removeFileMapping(fileUrl);
        }
      }
    } catch (e) {
      print('从缓存获取文件失败: $e');
    }
    return null;
  }

  /// 更新文件映射表
  Future<void> _updateFileMapping(String fileUrl, String filePath, String fileName, int fileSize) async {
    try {
      final directory = await _ensureDirectoryExists(_filesCacheDir);
      final mappingFile = File('${directory.path}/$_fileMappingFile');
      
      Map<String, dynamic> mapping = {};
      if (await mappingFile.exists()) {
        final content = await mappingFile.readAsString();
        mapping = jsonDecode(content);
      }
      
      mapping[fileUrl] = {
        'path': filePath,
        'fileName': fileName,
        'fileSize': fileSize,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      
      await mappingFile.writeAsString(jsonEncode(mapping));
      print('文件映射表已更新: $fileUrl');
    } catch (e) {
      print('更新文件映射表失败: $e');
    }
  }

  /// 加载文件映射表
  Future<Map<String, dynamic>> _loadFileMapping() async {
    try {
      final directory = await _ensureDirectoryExists(_filesCacheDir);
      final mappingFile = File('${directory.path}/$_fileMappingFile');
      
      if (await mappingFile.exists()) {
        final content = await mappingFile.readAsString();
        return jsonDecode(content);
      }
    } catch (e) {
      print('加载文件映射表失败: $e');
    }
    return {};
  }

  /// 从映射表移除文件
  Future<void> _removeFileMapping(String fileUrl) async {
    try {
      final directory = await _ensureDirectoryExists(_filesCacheDir);
      final mappingFile = File('${directory.path}/$_fileMappingFile');
      
      if (await mappingFile.exists()) {
        final content = await mappingFile.readAsString();
        final mapping = jsonDecode(content);
        
        // 删除关联的文件
        if (mapping[fileUrl] != null && mapping[fileUrl]['path'] != null) {
          final filePath = mapping[fileUrl]['path'] as String;
          try {
            await File(filePath).delete();
            print('删除文件: $filePath');
          } catch (e) {
            print('删除文件失败: $filePath, $e');
          }
        }
        
        mapping.remove(fileUrl);
        await mappingFile.writeAsString(jsonEncode(mapping));
        print('从映射表移除文件: $fileUrl');
      }
    } catch (e) {
      print('移除文件映射失败: $e');
    }
  }

  /// 清理过期的文件缓存
  Future<void> cleanupFileCache({int maxDays = 30}) async {
    try {
      final directory = await _ensureDirectoryExists(_filesCacheDir);
      final mapping = await _loadFileMapping();
      final cutoffDate = DateTime.now().subtract(Duration(days: maxDays));
      
      final toRemove = <String>[];
      
      for (final entry in mapping.entries) {
        final fileUrl = entry.key;
        final fileInfo = entry.value;
        
        try {
          final cachedAt = DateTime.parse(fileInfo['cachedAt']);
          final filePath = fileInfo['path'];
          
          if (cachedAt.isBefore(cutoffDate) || !await File(filePath).exists()) {
            // 删除过期或不存在的文件
            try {
              await File(filePath).delete();
            } catch (e) {
              print('删除文件失败: $filePath, $e');
            }
            toRemove.add(fileUrl);
          }
        } catch (e) {
          print('处理文件缓存项失败: $fileUrl, $e');
          toRemove.add(fileUrl);
        }
      }
      
      // 更新映射表
      if (toRemove.isNotEmpty) {
        for (final url in toRemove) {
          mapping.remove(url);
        }
        
        final mappingFile = File('${directory.path}/$_fileMappingFile');
        await mappingFile.writeAsString(jsonEncode(mapping));
        print('清理了${toRemove.length}个过期文件缓存');
      }
    } catch (e) {
      print('清理文件缓存失败: $e');
    }
  }

  /// 获取文件缓存信息
  Future<Map<String, dynamic>> getFileCacheInfo() async {
    try {
      final directory = await _ensureDirectoryExists(_filesCacheDir);
      final mapping = await _loadFileMapping();
      
      int totalFiles = 0;
      int totalSize = 0;
      int validFiles = 0;
      
      for (final fileInfo in mapping.values) {
        totalFiles++;
        final filePath = fileInfo['path'];
        final fileSize = fileInfo['fileSize'] ?? 0;
        
        if (await File(filePath).exists()) {
          validFiles++;
          totalSize += fileSize as int;
        }
      }
      
      return {
        'totalFiles': totalFiles,
        'validFiles': validFiles,
        'totalSize': totalSize,
        'invalidFiles': totalFiles - validFiles,
      };
    } catch (e) {
      print('获取文件缓存信息失败: $e');
      return {'totalFiles': 0, 'validFiles': 0, 'totalSize': 0, 'invalidFiles': 0};
    }
  }

  // =================== 记忆数据存储 ===================

  /// 保存记忆数据到持久化存储
  Future<void> saveMemories(String groupId, List<Map<String, dynamic>> memories) async {
    try {
      final directory = await _ensureDirectoryExists(_memoryDataDir);
      final file = File('${directory.path}/memories_$groupId.json');
      
      // 备份数据到SharedPreferences（双重保险）
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backup_memories_$groupId', jsonEncode(memories));
      
      // 保存到永久目录
      await file.writeAsString(jsonEncode(memories));
      print('记忆数据已保存到永久存储: ${file.path}');
    } catch (e) {
      print('保存记忆数据失败: $e');
      // 尝试仅保存到SharedPreferences作为后备
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('memories_cache_$groupId', jsonEncode(memories));
      } catch (backupError) {
        print('备份保存也失败: $backupError');
      }
    }
  }

  /// 从持久化存储加载记忆数据
  Future<List<Map<String, dynamic>>> loadMemories(String groupId) async {
    try {
      // 首先尝试从永久目录读取
      final directory = await _ensureDirectoryExists(_memoryDataDir);
      final file = File('${directory.path}/memories_$groupId.json');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final memories = jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
        print('从永久存储加载了${memories.length}条记忆');
        return memories;
      }
      
      // 如果永久目录没有，尝试从SharedPreferences读取
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString('backup_memories_$groupId');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final memories = jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
        print('从SharedPreferences备份加载了${memories.length}条记忆');
        
        // 迁移到永久目录
        await saveMemories(groupId, memories);
        return memories;
      }
      
      // 兼容旧版本数据
      jsonString = prefs.getString('memories_cache_$groupId');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final memories = jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
        print('从旧版存储迁移了${memories.length}条记忆');
        
        // 迁移到新存储
        await saveMemories(groupId, memories);
        return memories;
      }
      
    } catch (e) {
      print('加载记忆数据失败: $e');
    }
    
    return [];
  }

  // =================== 用户数据存储 ===================

  /// 保存用户设置和其他重要数据
  Future<void> saveUserData(String key, Map<String, dynamic> data) async {
    try {
      final directory = await _ensureDirectoryExists(_userDataDir);
      final file = File('${directory.path}/$key.json');
      
      // 双重保险：同时保存到SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('backup_$key', jsonEncode(data));
      
      // 保存到永久目录
      await file.writeAsString(jsonEncode(data));
      print('用户数据已保存: $key');
    } catch (e) {
      print('保存用户数据失败: $e');
      // 尝试仅保存到SharedPreferences作为后备
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, jsonEncode(data));
      } catch (backupError) {
        print('备份保存也失败: $backupError');
      }
    }
  }

  /// 加载用户数据
  Future<Map<String, dynamic>?> loadUserData(String key) async {
    try {
      // 首先尝试从永久目录读取
      final directory = await _ensureDirectoryExists(_userDataDir);
      final file = File('${directory.path}/$key.json');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final data = Map<String, dynamic>.from(jsonDecode(jsonString));
        print('从永久存储加载用户数据: $key');
        return data;
      }
      
      // 如果永久目录没有，尝试从SharedPreferences读取
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString('backup_$key');
      if (jsonString != null) {
        final data = Map<String, dynamic>.from(jsonDecode(jsonString));
        print('从SharedPreferences备份加载用户数据: $key');
        
        // 迁移到永久目录
        await saveUserData(key, data);
        return data;
      }
      
      // 兼容旧版本数据
      jsonString = prefs.getString(key);
      if (jsonString != null) {
        final data = Map<String, dynamic>.from(jsonDecode(jsonString));
        print('从旧版存储迁移用户数据: $key');
        
        // 迁移到新存储
        await saveUserData(key, data);
        return data;
      }
      
    } catch (e) {
      print('加载用户数据失败: $e');
    }
    
    return null;
  }

  // =================== 清理和维护 ===================

  /// 清理过期或无效的数据文件
  Future<void> cleanupOldData() async {
    try {
      final baseDir = await _permanentDirectory;
      final chatDir = Directory('${baseDir.path}/$_chatDataDir');
      final memoryDir = Directory('${baseDir.path}/$_memoryDataDir');
      
      // 检查文件大小，清理过大的文件（超过100MB的单个文件）
      final maxFileSize = 100 * 1024 * 1024; // 100MB
      
      if (await chatDir.exists()) {
        final chatFiles = chatDir.listSync();
        for (final file in chatFiles) {
          if (file is File) {
            final fileSize = await file.length();
            if (fileSize > maxFileSize) {
              print('删除过大的聊天文件: ${file.path} (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB)');
              await file.delete();
            }
          }
        }
      }
      
      if (await memoryDir.exists()) {
        final memoryFiles = memoryDir.listSync();
        for (final file in memoryFiles) {
          if (file is File) {
            final fileSize = await file.length();
            if (fileSize > maxFileSize) {
              print('删除过大的记忆文件: ${file.path} (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB)');
              await file.delete();
            }
          }
        }
      }
      
      // 清理文件缓存
      await cleanupFileCache();
      
    } catch (e) {
      print('清理数据失败: $e');
    }
  }

  /// 获取存储使用情况
  Future<Map<String, int>> getStorageInfo() async {
    try {
      final baseDir = await _permanentDirectory;
      int chatSize = 0;
      int memorySize = 0;
      int userDataSize = 0;
      int fileCacheSize = 0;
      
      // 计算聊天数据大小
      final chatDir = Directory('${baseDir.path}/$_chatDataDir');
      if (await chatDir.exists()) {
        final chatFiles = chatDir.listSync();
        for (final file in chatFiles) {
          if (file is File) {
            chatSize += await file.length();
          }
        }
      }
      
      // 计算记忆数据大小
      final memoryDir = Directory('${baseDir.path}/$_memoryDataDir');
      if (await memoryDir.exists()) {
        final memoryFiles = memoryDir.listSync();
        for (final file in memoryFiles) {
          if (file is File) {
            memorySize += await file.length();
          }
        }
      }
      
      // 计算用户数据大小
      final userDir = Directory('${baseDir.path}/$_userDataDir');
      if (await userDir.exists()) {
        final userFiles = userDir.listSync();
        for (final file in userFiles) {
          if (file is File) {
            userDataSize += await file.length();
          }
        }
      }
      
      // 计算文件缓存大小
      final fileCacheDir = Directory('${baseDir.path}/$_filesCacheDir');
      if (await fileCacheDir.exists()) {
        final cacheFiles = fileCacheDir.listSync();
        for (final file in cacheFiles) {
          if (file is File) {
            fileCacheSize += await file.length();
          }
        }
      }
      
      return {
        'chatSize': chatSize,
        'memorySize': memorySize,
        'userDataSize': userDataSize,
        'fileCacheSize': fileCacheSize,
        'totalSize': chatSize + memorySize + userDataSize + fileCacheSize,
      };
      
    } catch (e) {
      print('获取存储信息失败: $e');
      return {'chatSize': 0, 'memorySize': 0, 'userDataSize': 0, 'fileCacheSize': 0, 'totalSize': 0};
    }
  }

  /// 保存文件映射表
  Future<void> _saveFileMapping(Map<String, String> mapping) async {
    try {
      final directory = await _ensureDirectoryExists(_filesCacheDir);
      final mappingFile = File(path.join(directory.path, _fileMappingFile));
      
      final jsonContent = json.encode(mapping);
      await mappingFile.writeAsString(jsonContent);
    } catch (e) {
      print('保存文件映射失败: $e');
    }
  }

  /// 获取文件映射表
  Future<Map<String, String>> getFileMapping() async {
    try {
      final directory = await _ensureDirectoryExists(_filesCacheDir);
      final mappingFile = File(path.join(directory.path, _fileMappingFile));
      
      if (!await mappingFile.exists()) {
        return <String, String>{};
      }
      
      final content = await mappingFile.readAsString();
      final Map<String, dynamic> mappingData = json.decode(content);
      
      // 验证文件是否存在，清理无效映射
      final validMapping = <String, String>{};
      for (final entry in mappingData.entries) {
        final url = entry.key;
        // 处理新的文件映射格式（包含文件信息）和旧格式（直接路径）
        String? filePath;
        if (entry.value is Map) {
          filePath = (entry.value as Map)['path'] as String?;
        } else if (entry.value is String) {
          filePath = entry.value as String;
        }
        
        if (filePath != null && await File(filePath).exists()) {
          validMapping[url] = filePath;
        }
      }
      
      // 如果有无效映射被清理，更新映射文件
      if (validMapping.length < mappingData.length) {
        await _saveFileMapping(validMapping);
      }
      
      return validMapping;
    } catch (e) {
      print('获取文件映射失败: $e');
      return <String, String>{};
    }
  }
  
  /// 迁移旧存储路径的文件到新的永久目录
  Future<void> migrateOldFiles() async {
    try {
      print('开始迁移旧文件到永久存储...');
      
      // 尝试获取旧的Documents目录
      final oldDocumentsDir = await getApplicationDocumentsDirectory();
      final oldFilesCacheDir = Directory('${oldDocumentsDir.path}/$_filesCacheDir');
      
      // 获取新的永久目录
      final newPermanentDir = await _permanentDirectory;
      final newFilesCacheDir = await _ensureDirectoryExists(_filesCacheDir);
      
      // 如果旧目录存在且不等于新目录，进行迁移
      if (await oldFilesCacheDir.exists() && oldFilesCacheDir.path != newFilesCacheDir.path) {
        print('发现旧文件目录，开始迁移: ${oldFilesCacheDir.path} -> ${newFilesCacheDir.path}');
        
        final oldFiles = oldFilesCacheDir.listSync();
        int migratedCount = 0;
        
        for (final entity in oldFiles) {
          if (entity is File) {
            final fileName = path.basename(entity.path);
            final newFilePath = '${newFilesCacheDir.path}/$fileName';
            
            try {
              // 如果新位置不存在该文件，则复制
              if (!await File(newFilePath).exists()) {
                await entity.copy(newFilePath);
                migratedCount++;
                print('迁移文件: $fileName');
              }
            } catch (e) {
              print('迁移文件失败: $fileName, $e');
            }
          }
        }
        
        print('文件迁移完成，共迁移${migratedCount}个文件');
        
        // 迁移完成后可以选择删除旧目录（谨慎操作）
        // await oldFilesCacheDir.delete(recursive: true);
      }
      
    } catch (e) {
      print('迁移旧文件失败: $e');
    }
  }
  
  /// 获取永久存储目录路径（用于调试）
  Future<String> getPermanentStoragePath() async {
    final dir = await _permanentDirectory;
    return dir.path;
  }
} 