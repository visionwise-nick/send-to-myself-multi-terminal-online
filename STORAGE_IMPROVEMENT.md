# 文件存储系统改进 - 解决iOS/macOS应用更新后数据丢失问题

## 问题描述

原先的文件存储系统在iOS和macOS上存在一个严重问题：应用更新后，由于系统重新分配应用沙盒路径，导致之前保存的文件无法访问，造成数据丢失。虽然Android平台数据可以保留，但iOS和macOS平台的用户体验受到严重影响。

## 解决方案概述

我们实施了一套完整的永久存储解决方案，确保所有文件都保存在应用更新后路径不变的目录中，并实现了自动文件复制和迁移机制。

## 核心改进

### 1. 使用Application Support目录

**修改前**: 使用 `getApplicationDocumentsDirectory()`
```dart
Future<Directory> get _documentsDirectory async {
  return await getApplicationDocumentsDirectory();
}
```

**修改后**: 优先使用 `getApplicationSupportDirectory()`，备用Documents目录
```dart
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
```

### 2. 文件立即复制机制

#### 发送文件时复制
在用户发送文件时，立即将文件复制到永久存储目录：

```dart
// 立即复制文件到永久存储
String? permanentFilePath;
try {
  permanentFilePath = await _localStorage.copyFileToPermanentStorage(
    file.path, 
    fileName
  );
  print('文件已复制到永久存储: $fileName -> $permanentFilePath');
} catch (e) {
  print('复制文件到永久存储失败: $e');
  // 如果复制失败，仍然继续发送，但使用原始路径
  permanentFilePath = file.path;
}
```

#### 接收文件时直接存储
接收到的文件直接下载并保存到永久存储目录：

```dart
// 直接保存到永久存储
final savedPath = await _localStorage.saveFileToCache(fullUrl, response.data as List<int>, fileName);

if (savedPath != null) {
  print('文件下载并保存到永久存储完成: $fileName -> $savedPath');
  
  // 添加到内存缓存
  _addToCache(fullUrl, savedPath);
  
  // 更新消息文件路径
  _updateMessageFilePath(message, savedPath);
}
```

### 3. 旧文件自动迁移

#### 启动时迁移
应用启动时自动检查并迁移旧存储位置的文件：

```dart
// 启动时进行文件迁移
Future<void> _migrateOldFilesOnStartup() async {
  try {
    // 输出永久存储目录路径
    final permanentPath = await _localStorage.getPermanentStoragePath();
    print('=== 永久存储目录: $permanentPath ===');
    
    await _localStorage.migrateOldFiles();
    print('启动时文件迁移完成');
  } catch (e) {
    print('启动时文件迁移失败: $e');
  }
}
```

#### 迁移逻辑
```dart
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
    }
  } catch (e) {
    print('迁移旧文件失败: $e');
  }
}
```

### 4. 存储信息调试功能

添加了调试功能，用户可以长按聊天标题查看当前存储信息：

```dart
// 显示存储信息（调试功能）
Future<void> _showStorageInfo() async {
  try {
    final permanentPath = await _localStorage.getPermanentStoragePath();
    final storageInfo = await _localStorage.getStorageInfo();
    final fileCacheInfo = await _localStorage.getFileCacheInfo();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('存储信息'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('永久存储目录:'),
              const SizedBox(height: 4),
              Text(permanentPath, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
              const SizedBox(height: 16),
              Text('存储使用情况:'),
              const SizedBox(height: 8),
              Text('聊天数据: ${_formatBytes(storageInfo['chatSize'] ?? 0)}'),
              Text('记忆数据: ${_formatBytes(storageInfo['memorySize'] ?? 0)}'),
              Text('用户数据: ${_formatBytes(storageInfo['userDataSize'] ?? 0)}'),
              Text('文件缓存: ${_formatBytes(storageInfo['fileCacheSize'] ?? 0)}'),
              Text('总计: ${_formatBytes(storageInfo['totalSize'] ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('文件缓存统计:'),
              const SizedBox(height: 8),
              Text('总文件数: ${fileCacheInfo['totalFiles']}'),
              Text('有效文件: ${fileCacheInfo['validFiles']}'),
              Text('无效文件: ${fileCacheInfo['invalidFiles']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  } catch (e) {
    print('显示存储信息失败: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('获取存储信息失败: $e')),
    );
  }
}
```

## 目录结构

永久存储目录结构：
```
Application Support/
├── chat_data/          # 聊天消息数据
├── memory_data/        # AI记忆数据
├── user_data/          # 用户设置数据
└── files_cache/        # 文件缓存目录
    ├── file_mapping.json    # 文件URL到本地路径的映射表
    ├── image1_timestamp.jpg
    ├── video1_timestamp.mp4
    └── document1_timestamp.pdf
```

## 实现特点

### 1. 多重保障
- **主存储**: Application Support目录（永久）
- **备份存储**: SharedPreferences（兼容性）
- **容错机制**: 如果主存储失败，自动使用备份

### 2. 渐进式迁移
- 启动时自动检查旧文件
- 无感知迁移到新存储位置
- 保持向后兼容性

### 3. 智能缓存管理
- 内存缓存（快速访问）
- 永久缓存（跨会话持久）
- LRU缓存淘汰（内存优化）

### 4. 文件去重
- 基于文件哈希的内容去重
- 基于元数据的快速去重
- 防止重复下载和存储

## 测试验证

### 验证步骤
1. **发送文件测试**
   - 发送图片、视频、文档等不同类型文件
   - 检查文件是否立即复制到永久存储目录
   - 验证文件映射表是否正确更新

2. **接收文件测试**
   - 接收来自其他设备的文件
   - 验证文件直接下载到永久存储
   - 检查文件缓存和映射

3. **应用更新测试**
   - 记录当前存储目录路径
   - 模拟应用更新（重新安装）
   - 验证文件是否仍然可访问
   - 检查迁移机制是否正常工作

4. **存储信息验证**
   - 长按聊天标题查看存储信息
   - 验证路径和统计数据正确性
   - 检查各类数据的存储使用情况

### 预期结果
- ✅ iOS和macOS应用更新后文件不丢失
- ✅ 新发送的文件立即保存到永久位置
- ✅ 新接收的文件直接存储到永久位置
- ✅ 旧文件自动迁移到新位置
- ✅ 存储使用情况清晰可见

## 注意事项

1. **存储空间**: 文件会被复制存储，可能增加存储空间使用
2. **迁移时间**: 首次启动时如果有大量旧文件，迁移可能需要一些时间
3. **权限要求**: 确保应用有足够的存储权限
4. **清理机制**: 定期清理过期和无效的缓存文件

## 使用说明

### 对用户
- 文件存储现在是永久的，应用更新不会丢失
- 长按聊天标题可查看存储详情
- 首次更新后的启动可能稍慢（文件迁移）

### 对开发者
- 所有文件操作都通过LocalStorageService进行
- 使用copyFileToPermanentStorage()复制文件到永久存储
- 调用migrateOldFiles()进行旧文件迁移
- 通过getPermanentStoragePath()获取当前存储路径

这套解决方案彻底解决了iOS和macOS平台应用更新后文件丢失的问题，为用户提供了可靠的文件存储体验。 