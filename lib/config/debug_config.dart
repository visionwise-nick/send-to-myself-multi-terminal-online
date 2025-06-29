class DebugConfig {
  // 是否启用调试模式
  static const bool isDebugMode = false; // 🔥 设置为 false 来屏蔽大部分调试输出
  
  // 各个模块的调试开关
  static const bool enableWebSocketDebug = false;  // WebSocket连接调试
  static const bool enableMessageDebug = false;    // 消息处理调试
  static const bool enableFileDebug = false;       // 文件操作调试
  static const bool enableSyncDebug = false;       // 同步相关调试
  static const bool enableNetworkDebug = false;    // 网络请求调试
  static const bool enableUIDebug = false;         // UI状态调试
  
  // 🔥 仅保留复制粘贴相关的调试
  static const bool enableCopyPasteDebug = true;   // 复制粘贴功能调试
  
  // 🔥 添加错误和警告输出（始终启用）
  static const bool enableErrorDebug = true;       // 错误信息
  static const bool enableWarningDebug = true;     // 警告信息
  
  // 调试输出函数
  static void debugPrint(String message, {String module = 'GENERAL'}) {
    if (!isDebugMode) return;
    
    switch (module) {
      case 'WEBSOCKET':
        if (enableWebSocketDebug) print('[WS] $message');
        break;
      case 'MESSAGE':
        if (enableMessageDebug) print('[MSG] $message');
        break;
      case 'FILE':
        if (enableFileDebug) print('[FILE] $message');
        break;
      case 'SYNC':
        if (enableSyncDebug) print('[SYNC] $message');
        break;
      case 'NETWORK':
        if (enableNetworkDebug) print('[NET] $message');
        break;
      case 'UI':
        if (enableUIDebug) print('[UI] $message');
        break;
      case 'COPY_PASTE':
        if (enableCopyPasteDebug) print('[COPY/PASTE] $message');
        break;
      case 'ERROR':
        if (enableErrorDebug) print('[ERROR] $message');
        break;
      case 'WARNING':
        if (enableWarningDebug) print('[WARNING] $message');
        break;
      default:
        print('[DEBUG] $message');
    }
  }
  
  // 错误输出（始终显示）
  static void errorPrint(String message, {String module = 'ERROR'}) {
    if (enableErrorDebug) print('[ERROR] $message');
  }
  
  // 警告输出（始终显示）
  static void warningPrint(String message, {String module = 'WARNING'}) {
    if (enableWarningDebug) print('[WARNING] $message');
  }
  
  // 复制粘贴专用调试输出
  static void copyPasteDebug(String message) {
    if (enableCopyPasteDebug) print('[COPY/PASTE] $message');
  }
} 