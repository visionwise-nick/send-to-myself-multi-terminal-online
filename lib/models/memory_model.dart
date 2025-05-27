import 'dart:convert';

/// 记忆类型枚举
enum MemoryType {
  text('text', '文本笔记'),
  password('password', '账号密码'),
  financial('financial', '记账'),
  schedule('schedule', '日程提醒'),
  todo('todo', '待办事项'),
  url('url', 'URL链接'),
  image('image', '图片'),
  video('video', '视频'),
  document('document', '文档');

  const MemoryType(this.value, this.displayName);
  
  final String value;
  final String displayName;

  static MemoryType fromString(String value) {
    return MemoryType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MemoryType.text,
    );
  }
  
  /// 获取显示的图标
  String get iconEmoji {
    switch (this) {
      case MemoryType.text:
        return '📝';
      case MemoryType.password:
        return '🔐';
      case MemoryType.financial:
        return '💰';
      case MemoryType.schedule:
        return '📅';
      case MemoryType.todo:
        return '✅';
      case MemoryType.url:
        return '🔗';
      case MemoryType.image:
        return '🖼️';
      case MemoryType.video:
        return '🎬';
      case MemoryType.document:
        return '📄';
    }
  }
}

/// 记忆数据模型
class Memory {
  final String id;
  final String title;
  final String content;
  final MemoryType type;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  
  // 文件相关字段
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  
  // 特定类型的结构化数据
  final Map<String, dynamic>? data;

  Memory({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.data,
  });

  /// 从JSON创建Memory对象
  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: MemoryType.fromString(json['type'] ?? 'text'),
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      userId: json['userId'] ?? '',
      fileUrl: json['fileUrl'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      data: json['data'],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.value,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileSize != null) 'fileSize': fileSize,
      if (mimeType != null) 'mimeType': mimeType,
      if (data != null) 'data': data,
    };
  }

  /// 创建副本
  Memory copyWith({
    String? id,
    String? title,
    String? content,
    MemoryType? type,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? mimeType,
    Map<String, dynamic>? data,
  }) {
    return Memory(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      data: data ?? this.data,
    );
  }

  /// 是否是文件类型记忆
  bool get isFileMemory => fileUrl != null;

  /// 获取格式化的文件大小
  String get formattedFileSize {
    if (fileSize == null) return '';
    
    final size = fileSize!;
    if (size < 1024) {
      return '${size}B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)}KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  // 类型特定的getter方法
  
  /// 账号密码类型的数据
  Map<String, String>? get passwordData {
    if (type != MemoryType.password || data == null) return null;
    return {
      'username': data!['username'] ?? '',
      'password': data!['password'] ?? '',
      'website': data!['website'] ?? '',
      'notes': data!['notes'] ?? '',
    };
  }

  /// 记账类型的数据
  Map<String, dynamic>? get financialData {
    if (type != MemoryType.financial || data == null) return null;
    return {
      'amount': data!['amount'] ?? 0.0,
      'isIncome': data!['isIncome'] ?? false,
      'category': data!['category'] ?? '',
      'date': data!['date'] ?? DateTime.now().toIso8601String(),
      'notes': data!['notes'] ?? '',
    };
  }

  /// 日程类型的数据
  Map<String, dynamic>? get scheduleData {
    if (type != MemoryType.schedule || data == null) return null;
    return {
      'startTime': data!['startTime'] ?? DateTime.now().toIso8601String(),
      'endTime': data!['endTime'],
      'location': data!['location'] ?? '',
      'description': data!['description'] ?? '',
      'reminder': data!['reminder'] ?? 15, // 提前分钟数
    };
  }

  /// 待办类型的数据
  Map<String, dynamic>? get todoData {
    if (type != MemoryType.todo || data == null) return null;
    return {
      'isCompleted': data!['isCompleted'] ?? false,
      'priority': data!['priority'] ?? 'medium', // low, medium, high
      'dueDate': data!['dueDate'],
      'description': data!['description'] ?? '',
    };
  }

  /// URL类型的数据
  Map<String, String>? get urlData {
    if (type != MemoryType.url || data == null) return null;
    return {
      'url': data!['url'] ?? '',
      'description': data!['description'] ?? '',
      'favicon': data!['favicon'] ?? '',
    };
  }

  @override
  String toString() {
    return 'Memory(id: $id, title: $title, type: ${type.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Memory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 群组记忆统计模型
class GroupMemoryStats {
  final String groupId;
  final String groupName;
  final int totalDevices;
  final Map<String, DeviceMemoryStats> deviceStats;

  GroupMemoryStats({
    required this.groupId,
    required this.groupName,
    required this.totalDevices,
    required this.deviceStats,
  });

  factory GroupMemoryStats.fromJson(Map<String, dynamic> json) {
    final memoryStats = json['memoryStats'] as Map<String, dynamic>? ?? {};
    final deviceStats = <String, DeviceMemoryStats>{};
    
    memoryStats.forEach((deviceId, stats) {
      deviceStats[deviceId] = DeviceMemoryStats.fromJson(stats);
    });

    return GroupMemoryStats(
      groupId: json['groupId'] ?? '',
      groupName: json['groupName'] ?? '',
      totalDevices: json['totalDevices'] ?? 0,
      deviceStats: deviceStats,
    );
  }
}

/// 设备记忆统计模型
class DeviceMemoryStats {
  final String deviceName;
  final int totalMemories;
  final int receivedFromGroup;
  final int sharedToGroup;

  DeviceMemoryStats({
    required this.deviceName,
    required this.totalMemories,
    required this.receivedFromGroup,
    required this.sharedToGroup,
  });

  factory DeviceMemoryStats.fromJson(Map<String, dynamic> json) {
    return DeviceMemoryStats(
      deviceName: json['deviceName'] ?? '',
      totalMemories: json['totalMemories'] ?? 0,
      receivedFromGroup: json['receivedFromGroup'] ?? 0,
      sharedToGroup: json['sharedToGroup'] ?? 0,
    );
  }
} 