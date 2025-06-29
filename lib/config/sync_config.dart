class SyncConfig {
  // 🔥 同步频率优化 - 减少对云端的消息轰炸
  static const Duration heartbeatInterval = Duration(minutes: 2);        // 心跳间隔从30秒改为2分钟
  static const Duration reconnectDelay = Duration(seconds: 10);          // 重连延迟从3秒改为10秒
  static const Duration syncInterval = Duration(minutes: 5);             // 主动同步间隔从2分钟改为5分钟
  static const Duration messageReceiveTestInterval = Duration(minutes: 5); // 消息接收测试间隔从2分钟改为5分钟
  
  // 🔥 批量操作优化
  static const int maxBatchSize = 50;                    // 批量操作最大数量
  static const Duration batchDelay = Duration(milliseconds: 500); // 批量操作延迟
  
  // 🔥 重连策略优化
  static const int maxReconnectAttempts = 5;             // 最大重连次数从10次减少到5次
  static const Duration maxReconnectInterval = Duration(minutes: 5); // 最大重连间隔从30秒改为5分钟
  
  // 🔥 消息去重优化
  static const int maxProcessedMessageIds = 500;         // 减少内存中保存的消息ID数量
  static const Duration messageIdRetentionTime = Duration(hours: 1); // 消息ID保留时间从2小时减少到1小时
  
  // 🔥 网络状态检测优化
  static const Duration networkCheckInterval = Duration(minutes: 10); // 网络状态检测间隔从30秒改为10分钟
  static const Duration connectionHealthCheckInterval = Duration(minutes: 3); // 连接健康检查间隔从1分钟改为3分钟
  
  // 🔥 同步策略优化
  static const bool enableIncrementalSync = true;        // 启用增量同步
  static const bool enableSmartSync = true;              // 启用智能同步（根据活跃程度调整频率）
  static const bool enableBatchSync = true;              // 启用批量同步
  static const bool enableDeduplication = true;          // 启用消息去重
  
  // 🔥 性能优化
  static const int maxCacheSize = 50;                    // 最大缓存大小
  static const Duration cacheCleanupInterval = Duration(hours: 6); // 缓存清理间隔
  
  // 🔥 智能同步配置
  static const Map<String, Duration> adaptiveSyncIntervals = {
    'active': Duration(minutes: 1),       // 活跃时1分钟同步一次
    'normal': Duration(minutes: 5),       // 正常时5分钟同步一次
    'inactive': Duration(minutes: 15),    // 不活跃时15分钟同步一次
    'background': Duration(minutes: 30),  // 后台时30分钟同步一次
  };
  
  // 🔥 请求节流配置
  static const Map<String, Duration> requestThrottleIntervals = {
    'message_sync': Duration(seconds: 30),        // 消息同步请求最少间隔30秒
    'status_update': Duration(minutes: 2),        // 状态更新请求最少间隔2分钟
    'file_upload': Duration(seconds: 5),          // 文件上传请求最少间隔5秒
    'heartbeat': Duration(minutes: 1),            // 心跳请求最少间隔1分钟
  };
  
  // 获取当前同步模式对应的间隔
  static Duration getSyncInterval(String mode) {
    return adaptiveSyncIntervals[mode] ?? adaptiveSyncIntervals['normal']!;
  }
  
  // 获取请求节流间隔
  static Duration getThrottleInterval(String requestType) {
    return requestThrottleIntervals[requestType] ?? Duration(seconds: 1);
  }
  
  // 检查是否应该执行同步（基于智能策略）
  static bool shouldSync(String syncType, DateTime lastSyncTime, String userActivityLevel) {
    final now = DateTime.now();
    final timeSinceLastSync = now.difference(lastSyncTime);
    
    switch (syncType) {
      case 'message':
        final interval = getSyncInterval(userActivityLevel);
        return timeSinceLastSync >= interval;
      case 'status':
        return timeSinceLastSync >= Duration(minutes: 5);
      case 'heartbeat':
        return timeSinceLastSync >= heartbeatInterval;
      default:
        return timeSinceLastSync >= Duration(minutes: 1);
    }
  }
} 