class AppConfig {
  // ✅ 使用正确的URL
  static const String API_BASE_URL = 'https://sendtomyself-api-adecumh2za-uc.a.run.app';
  static const String WEBSOCKET_URL = 'https://sendtomyself-api-adecumh2za-uc.a.run.app';
  static const String WEBSOCKET_PATH = '/ws';
  
  // WebSocket配置
  static const int CONNECT_TIMEOUT = 15000; // 15秒连接超时
  static const int PING_INTERVAL = 25000;   // 25秒ping间隔
  static const int PING_TIMEOUT = 60000;    // 60秒ping超时
  static const int MAX_RECONNECT_ATTEMPTS = 8; // 最大重连次数
  
  // 网络检查配置
  static const int NETWORK_CHECK_TIMEOUT = 8000; // 8秒网络检查超时
  static const int DNS_CHECK_TIMEOUT = 10000;    // 10秒DNS检查超时
  
  // 重连延迟配置
  static const List<int> RECONNECT_DELAYS = [3, 6, 12, 25, 50, 120, 300, 600]; // 秒
  
  // 心跳配置
  static const int HEARTBEAT_INTERVAL = 30000; // 30秒心跳间隔
  static const int CONNECTION_HEALTH_CHECK = 120000; // 2分钟连接健康检查
  
  // 网络监控配置
  static const int NETWORK_MONITOR_INTERVAL = 120000; // 2分钟网络监控间隔
  
  // 开发模式
  static const bool DEBUG_WEBSOCKET = true;
} 