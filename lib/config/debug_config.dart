class DebugConfig {
  // 是否启用调试模式 - 完全关闭
  static const bool isDebugMode = false; 
  
  // 🔥 全局静默模式 - 屏蔽所有print输出
  static const bool enableGlobalSilentMode = true;

  // 各个模块的调试开关 - 全部关闭
  static const bool enableWebSocketDebug = false;
  static const bool enableMessageDebug = false;    // 🔥 关闭消息获取调试
  static const bool enableFileDebug = false;
  static const bool enableSyncDebug = false;
  static const bool enableNetworkDebug = false;
  static const bool enableUIDebug = false;
  
  // 🔥 仅保留复制粘贴相关的调试
  static const bool enableCopyPasteDebug = true;   
  
  // 🔥 仅保留错误输出
  static const bool enableErrorDebug = true;
  static const bool enableWarningDebug = false;    // 🔥 关闭警告
  
  // 调试输出函数
  static void debugPrint(String message, {String module = 'GENERAL'}) {
    // 🔥 关闭所有模块调试输出
    switch (module) {
      case 'COPY_PASTE':
        if (enableCopyPasteDebug) {
          print('[COPY/PASTE] $message');
        }
        break;
      case 'MESSAGE':
        // 🔥 完全关闭消息调试
        break;
      case 'WEBSOCKET':
      case 'FILE':
      case 'SYNC':
      case 'NETWORK':
      case 'UI':
      case 'APP':
        // 🔥 关闭所有其他模块
        break;
      default:
        // 默认也不输出
        break;
    }
  }
  
  // 🔥 复制粘贴专用调试函数
  static void copyPasteDebug(String message) {
    if (enableCopyPasteDebug) {
      print('[COPY/PASTE] $message');
    }
  }
  
  // 🔥 错误信息输出（始终显示）
  static void errorPrint(String message) {
    if (enableErrorDebug) {
      print('[ERROR] $message');
    }
  }
  
  // 🔥 警告信息输出
  static void warningPrint(String message) {
    if (enableWarningDebug) {
      print('[WARNING] $message');
    }
  }

  // 🔥 全局print控制函数
  static void globalPrint(String message) {
    if (enableGlobalSilentMode) {
      // 在静默模式下，只允许复制粘贴和错误信息
      if (message.contains('[COPY/PASTE]') || message.contains('[ERROR]')) {
        // 使用系统原始print
        // ignore: avoid_print
        print(message);
      }
      // 其他所有调试信息都被静默
    } else {
      // 非静默模式下正常输出
      // ignore: avoid_print  
      print(message);
    }
  }
} 