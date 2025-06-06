import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// 离线消息同步服务
/// 专门处理应用启动时的离线消息同步和群组历史消息获取
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final String _baseUrl = "https://sendtomyself-api-adecumh2za-uc.a.run.app/api";
  
  /// 获取认证头部
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final serverDeviceData = prefs.getString('server_device_data');
    
    if (token == null) {
      throw Exception('未找到认证令牌，请先进行设备注册');
    }
    
    String? deviceId;
    if (serverDeviceData != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(serverDeviceData);
        deviceId = data['id'];
      } catch (e) {
        print('解析设备ID失败: $e');
      }
    }
    
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    
    if (deviceId != null) {
      headers['X-Device-Id'] = deviceId;
    }
    
    return headers;
  }

  /// 获取服务器分配的设备ID
  Future<String?> _getServerDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? serverDeviceData = prefs.getString('server_device_data');
    if (serverDeviceData != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(serverDeviceData);
        return data['id'];
      } catch (e) {
        print('解析服务器设备ID失败: $e');
      }
    }
    return null;
  }

  /// 群组历史消息同步接口
  /// 专为离线同步优化的群组历史消息获取接口
  Future<GroupHistoryResult> syncGroupHistory({
    required String groupId,
    int limit = 50,
    String? lastMessageId,
    DateTime? fromTime,
    DateTime? toTime,
    bool includeDeleted = false,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      // 构建查询参数
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      
      if (lastMessageId != null) {
        queryParams['lastMessageId'] = lastMessageId;
      }
      
      if (fromTime != null) {
        queryParams['fromTime'] = fromTime.toIso8601String();
      }
      
      if (toTime != null) {
        queryParams['toTime'] = toTime.toIso8601String();
      }
      
      if (includeDeleted) {
        queryParams['includeDeleted'] = 'true';
      }
      
      final uri = Uri.parse('$_baseUrl/messages/group/$groupId/history')
          .replace(queryParameters: queryParams);
      
      debugPrint('群组历史消息同步请求: $uri');
      
      final response = await http.get(uri, headers: headers);
      
      debugPrint('群组历史消息同步响应状态码: ${response.statusCode}');
      debugPrint('群组历史消息同步响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          return GroupHistoryResult.fromJson(responseData['data']);
        } else {
          throw Exception('服务器返回错误: ${responseData['message'] ?? '未知错误'}');
        }
      } else {
        throw Exception('HTTP请求失败: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('群组历史消息同步失败: $e');
      rethrow;
    }
  }

  /// 设备离线消息同步接口
  /// 获取设备离线期间错过的所有消息
  Future<OfflineMessagesResult> syncOfflineMessages({
    required DateTime fromTime,
    int limit = 100,
  }) async {
    try {
      final deviceId = await _getServerDeviceId();
      if (deviceId == null) {
        throw Exception('无法获取设备ID，请先进行设备注册');
      }
      
      final headers = await _getAuthHeaders();
      
      // 构建查询参数
      final queryParams = <String, String>{
        'fromTime': fromTime.toIso8601String(),
        'limit': limit.toString(),
      };
      
      final uri = Uri.parse('$_baseUrl/messages/sync/offline/$deviceId')
          .replace(queryParameters: queryParams);
      
      debugPrint('离线消息同步请求: $uri');
      
      final response = await http.get(uri, headers: headers);
      
      debugPrint('离线消息同步响应状态码: ${response.statusCode}');
      debugPrint('离线消息同步响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          return OfflineMessagesResult.fromJson(responseData['data']);
        } else {
          throw Exception('服务器返回错误: ${responseData['message'] ?? '未知错误'}');
        }
      } else {
        throw Exception('HTTP请求失败: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('离线消息同步失败: $e');
      rethrow;
    }
  }

  /// 应用启动时的完整离线同步
  /// 这是推荐的集成方式，在应用启动时调用
  Future<AppStartupSyncResult> performStartupSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取上次在线时间
      final lastOnlineTimeStr = prefs.getString('last_online_time');
      DateTime lastOnlineTime;
      
      if (lastOnlineTimeStr != null) {
        lastOnlineTime = DateTime.parse(lastOnlineTimeStr);
      } else {
        // 如果没有记录，默认同步最近24小时的消息
        lastOnlineTime = DateTime.now().subtract(const Duration(hours: 24));
      }
      
      debugPrint('开始应用启动同步，上次在线时间: $lastOnlineTime');
      
      // 执行离线消息同步
      final offlineResult = await syncOfflineMessages(
        fromTime: lastOnlineTime,
        limit: 200, // 启动时可以获取更多消息
      );
      
      // 更新最后在线时间
      final now = DateTime.now();
      await prefs.setString('last_online_time', now.toIso8601String());
      
      debugPrint('应用启动同步完成，同步了 ${offlineResult.syncInfo.returned} 条消息');
      
      return AppStartupSyncResult(
        offlineMessages: offlineResult,
        syncedAt: now,
        success: true,
      );
      
    } catch (e) {
      debugPrint('应用启动同步失败: $e');
      return AppStartupSyncResult(
        offlineMessages: null,
        syncedAt: DateTime.now(),
        success: false,
        error: e.toString(),
      );
    }
  }

  /// 保存最后在线时间（应用进入后台时调用）
  Future<void> saveLastOnlineTime([DateTime? time]) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = time ?? DateTime.now();
    await prefs.setString('last_online_time', timestamp.toIso8601String());
    debugPrint('已保存最后在线时间: $timestamp');
  }

  /// 获取最后在线时间
  Future<DateTime?> getLastOnlineTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOnlineTimeStr = prefs.getString('last_online_time');
    if (lastOnlineTimeStr != null) {
      return DateTime.parse(lastOnlineTimeStr);
    }
    return null;
  }

  /// 批量获取多个群组的历史消息
  Future<Map<String, GroupHistoryResult>> syncMultipleGroupsHistory({
    required List<String> groupIds,
    DateTime? fromTime,
    int limitPerGroup = 50,
  }) async {
    final results = <String, GroupHistoryResult>{};
    
    // 并发获取多个群组的历史消息
    final futures = groupIds.map((groupId) async {
      try {
        final result = await syncGroupHistory(
          groupId: groupId,
          fromTime: fromTime,
          limit: limitPerGroup,
        );
        return MapEntry(groupId, result);
      } catch (e) {
        debugPrint('群组 $groupId 历史消息同步失败: $e');
        return null;
      }
    });
    
    final completed = await Future.wait(futures);
    
    for (final entry in completed) {
      if (entry != null) {
        results[entry.key] = entry.value;
      }
    }
    
    debugPrint('批量群组历史同步完成，成功同步 ${results.length}/${groupIds.length} 个群组');
    return results;
  }
}

/// 群组历史消息同步结果
class GroupHistoryResult {
  final String groupId;
  final String groupName;
  final List<Map<String, dynamic>> messages;
  final PaginationInfo pagination;
  final SyncInfo syncInfo;

  GroupHistoryResult({
    required this.groupId,
    required this.groupName,
    required this.messages,
    required this.pagination,
    required this.syncInfo,
  });

  factory GroupHistoryResult.fromJson(Map<String, dynamic> json) {
    return GroupHistoryResult(
      groupId: json['groupId'] ?? '',
      groupName: json['groupName'] ?? '',
      messages: List<Map<String, dynamic>>.from(json['messages'] ?? []),
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
      syncInfo: SyncInfo.fromJson(json['syncInfo'] ?? {}),
    );
  }
}

/// 离线消息同步结果
class OfflineMessagesResult {
  final String deviceId;
  final List<Map<String, dynamic>> messages;
  final OfflineSyncInfo syncInfo;

  OfflineMessagesResult({
    required this.deviceId,
    required this.messages,
    required this.syncInfo,
  });

  factory OfflineMessagesResult.fromJson(Map<String, dynamic> json) {
    return OfflineMessagesResult(
      deviceId: json['deviceId'] ?? '',
      messages: List<Map<String, dynamic>>.from(json['messages'] ?? []),
      syncInfo: OfflineSyncInfo.fromJson(json['syncInfo'] ?? {}),
    );
  }
}

/// 应用启动同步结果
class AppStartupSyncResult {
  final OfflineMessagesResult? offlineMessages;
  final DateTime syncedAt;
  final bool success;
  final String? error;

  AppStartupSyncResult({
    required this.offlineMessages,
    required this.syncedAt,
    required this.success,
    this.error,
  });
}

/// 分页信息
class PaginationInfo {
  final int total;
  final bool hasMore;
  final String? nextCursor;
  final int limit;

  PaginationInfo({
    required this.total,
    required this.hasMore,
    this.nextCursor,
    required this.limit,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      total: json['total'] ?? 0,
      hasMore: json['hasMore'] ?? false,
      nextCursor: json['nextCursor'],
      limit: json['limit'] ?? 50,
    );
  }
}

/// 同步信息
class SyncInfo {
  final DateTime syncedAt;
  final DateTime? fromTime;
  final DateTime? toTime;
  final bool includeDeleted;

  SyncInfo({
    required this.syncedAt,
    this.fromTime,
    this.toTime,
    required this.includeDeleted,
  });

  factory SyncInfo.fromJson(Map<String, dynamic> json) {
    return SyncInfo(
      syncedAt: DateTime.parse(json['syncedAt'] ?? DateTime.now().toIso8601String()),
      fromTime: json['fromTime'] != null ? DateTime.parse(json['fromTime']) : null,
      toTime: json['toTime'] != null ? DateTime.parse(json['toTime']) : null,
      includeDeleted: json['includeDeleted'] ?? false,
    );
  }
}

/// 离线同步信息
class OfflineSyncInfo {
  final int total;
  final int returned;
  final DateTime fromTime;
  final DateTime syncedAt;

  OfflineSyncInfo({
    required this.total,
    required this.returned,
    required this.fromTime,
    required this.syncedAt,
  });

  factory OfflineSyncInfo.fromJson(Map<String, dynamic> json) {
    return OfflineSyncInfo(
      total: json['total'] ?? 0,
      returned: json['returned'] ?? 0,
      fromTime: DateTime.parse(json['fromTime'] ?? DateTime.now().toIso8601String()),
      syncedAt: DateTime.parse(json['syncedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
} 