# 离线消息同步功能实现

## 🎯 功能概述
当设备从离线状态恢复在线时，自动请求并下载离线期间错过的消息，确保消息同步的完整性。

## 🔧 实现架构

### 1. WebSocket管理层 (`websocket_manager.dart`)
- **连接状态追踪**: 新增 `_lastOnlineTime`、`_wasOffline` 标志
- **连接恢复检测**: 在 `_onConnectionSuccess()` 中检测是否从离线状态恢复
- **离线消息同步**: 新增 `_performOfflineMessageSync()` 方法

#### 关键实现
```dart
// 状态追踪
DateTime? _lastOnlineTime;
bool _wasOffline = false;

// 连接恢复时触发
void _onConnectionSuccess() {
  final wasOfflineBefore = _wasOffline;
  _wasOffline = false;
  _lastOnlineTime = DateTime.now();
  
  if (wasOfflineBefore) {
    Timer(Duration(seconds: 2), () {
      _performOfflineMessageSync();
    });
  }
}

// 离线消息同步
void _performOfflineMessageSync() {
  _socket?.emit('get_offline_messages', {
    'lastOnlineTime': _lastOnlineTime?.toIso8601String(),
    'timestamp': DateTime.now().toIso8601String(),
  });
}
```

#### 新增消息监听器
- `recent_messages` - 最近消息列表
- `offline_messages` - 离线消息列表  
- `group_messages_synced` - 群组消息同步
- `private_messages_synced` - 私聊消息同步

### 2. WebSocket服务层 (`websocket_service.dart`)
- **消息类型转发**: 将新的消息类型转发到聊天消息流
- **类型处理**: 识别和处理同步相关的消息类型

#### 新增消息转发
```dart
case 'recent_messages':
case 'offline_messages':
case 'group_messages_synced':
case 'private_messages_synced':
  _chatMessageController.add(data);
  break;
```

### 3. 聊天界面层 (`chat_screen.dart`)
- **消息处理**: 新增专门的同步消息处理方法
- **去重机制**: 确保同步消息不会重复显示
- **用户提示**: 显示离线消息恢复状态

#### 核心处理方法

##### `_handleOfflineMessages()` - 离线消息处理
```dart
void _handleOfflineMessages(Map<String, dynamic> data) {
  final offlineMessages = List<Map<String, dynamic>>.from(messages);
  
  // 显示恢复提示
  if (offlineMessages.isNotEmpty && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在恢复${offlineMessages.length}条离线消息...')),
    );
  }
  
  _processSyncMessages(offlineMessages, '离线消息同步');
}
```

##### `_processSyncMessages()` - 统一消息处理
```dart
void _processSyncMessages(List<Map<String, dynamic>> syncMessages, String syncType) async {
  // 消息格式转换
  final convertedMessages = syncMessages.map((msg) {
    final isMe = msg['sourceDeviceId'] == currentDeviceId;
    return {
      'id': msg['id'],
      'text': msg['content'],
      'fileType': _getFileType(msg['fileName']),
      // ... 其他字段转换
    };
  }).toList();
  
  // 去重处理
  final newMessages = convertedMessages.where((msg) {
    return !_messages.any((localMsg) => localMsg['id'] == msg['id']);
  }).toList();
  
  // 更新UI
  if (newMessages.isNotEmpty) {
    setState(() {
      _messages.addAll(newMessages);
      _messages.sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));
    });
    
    // 自动下载文件
    for (final message in newMessages) {
      if (message['fileUrl'] != null && !message['isMe']) {
        _autoDownloadFile(message);
      }
    }
  }
}
```

## 🚀 工作流程

### 设备离线场景
1. **连接断开**: WebSocket连接丢失
2. **状态标记**: `_wasOffline = true`
3. **消息堆积**: 服务器存储离线期间的消息

### 设备上线场景
1. **连接恢复**: WebSocket重新连接成功
2. **状态检测**: 检测到 `_wasOffline = true`
3. **延迟同步**: 等待2秒确保连接稳定
4. **请求离线消息**: 发送 `get_offline_messages` 事件
5. **服务器响应**: 返回离线期间的消息列表
6. **消息处理**: 转换格式、去重、更新UI
7. **文件下载**: 自动下载文件类型消息
8. **用户提示**: 显示恢复状态给用户

## 🔒 安全机制

### 去重保护
- **ID检查**: 基于消息ID进行严格去重
- **本地对比**: 与现有消息列表对比
- **实时保护**: 避免与WebSocket实时消息冲突

### 异常处理
- **数据验证**: 检查消息数据格式的完整性
- **网络容错**: 处理网络请求失败的情况
- **UI保护**: 确保界面状态的一致性

## 📊 性能优化

### 批量处理
- **统一转换**: 批量进行消息格式转换
- **批量更新**: 一次性更新UI状态
- **延迟执行**: 避免连接恢复时的资源竞争

### 内存管理
- **及时清理**: 处理完成后清理临时数据
- **增量更新**: 只添加真正的新消息
- **排序优化**: 高效的时间戳排序算法

## 🎨 用户体验

### 视觉反馈
- **恢复提示**: SnackBar显示恢复进度
- **自动滚动**: 新消息添加后自动滚动到底部
- **加载状态**: 清晰的加载和处理状态

### 无缝体验
- **后台处理**: 不阻塞用户操作
- **增量更新**: 渐进式添加消息
- **状态保持**: 保持聊天界面的状态连续性

## ✅ 测试场景

1. **网络中断恢复**: 模拟网络断开后重连
2. **应用重启**: 应用关闭后重新打开
3. **长时间离线**: 设备长时间离线后上线
4. **并发消息**: 离线期间有多条消息的情况
5. **文件消息**: 离线期间接收文件消息的处理

## 🔄 扩展性

### 支持的消息类型
- `recent_messages` - 最近消息同步
- `offline_messages` - 离线消息恢复  
- `group_messages_synced` - 群组消息同步
- `private_messages_synced` - 私聊消息同步

### 未来扩展
- **消息优先级**: 支持重要消息的优先同步
- **增量同步**: 基于时间戳的增量消息同步
- **压缩传输**: 大量消息的压缩传输优化 