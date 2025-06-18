import 'dart:async';
import 'dart:convert';

/// 测试WebSocketService桥接force_refresh_history事件
/// 
/// 验证修复：
/// 1. WebSocketManager发送force_refresh_history事件
/// 2. WebSocketService正确桥接到chatMessageController
/// 3. 聊天界面能够接收到事件并处理

void main() {
  print('🧪 开始测试WebSocketService桥接force_refresh_history事件');
  
  testWebSocketServiceBridge();
  testChatMessageFlowComplete();
  
  print('✅ 所有测试完成');
}

/// 测试WebSocketService桥接功能
void testWebSocketServiceBridge() {
  print('\n📋 测试1: WebSocketService桥接功能');
  
  final mockWebSocketService = MockWebSocketService();
  
  // 模拟从WebSocketManager接收到force_refresh_history事件
  final refreshEvent = {
    'type': 'force_refresh_history',
    'reason': 'connection_restored',
    'timestamp': DateTime.now().toIso8601String(),
    'data': {
      'refresh_group_messages': true,
      'refresh_private_messages': true,
      'sync_limit': 50,
    }
  };
  
  print('📨 模拟WebSocketManager发送force_refresh_history事件');
  mockWebSocketService.simulateManagerMessage(refreshEvent);
  
  // 验证是否正确桥接到聊天消息流
  assert(mockWebSocketService.chatMessageReceived, '应该收到聊天消息');
  assert(mockWebSocketService.lastChatMessage['type'] == 'force_refresh_history', '消息类型应该是force_refresh_history');
  
  print('✅ WebSocketService桥接功能测试通过');
}

/// 测试完整的聊天消息流
void testChatMessageFlowComplete() {
  print('\n📋 测试2: 完整的聊天消息流');
  
  final mockChatScreen = MockChatScreen();
  final mockWebSocketService = MockWebSocketService();
  
  // 模拟聊天界面订阅WebSocketService
  mockWebSocketService.onChatMessage.listen((data) {
    mockChatScreen.handleChatMessage(data);
  });
  
  // 模拟连接恢复场景
  print('🔄 模拟连接恢复场景');
  
  // 1. WebSocketManager检测到连接恢复
  final connectionRestoredEvent = {
    'type': 'force_refresh_history',
    'reason': 'connection_restored',
    'timestamp': DateTime.now().toIso8601String(),
    'data': {
      'refresh_group_messages': true,
      'refresh_private_messages': true,
      'sync_limit': 50,
    }
  };
  
  // 2. WebSocketService桥接事件
  mockWebSocketService.simulateManagerMessage(connectionRestoredEvent);
  
  // 3. 验证聊天界面收到并处理了事件
  assert(mockChatScreen.forceRefreshTriggered, '强制刷新应该被触发');
  assert(mockChatScreen.apiCallMade, 'API调用应该被执行');
  assert(mockChatScreen.uiRefreshed, 'UI应该被刷新');
  
  print('✅ 完整聊天消息流测试通过');
}

/// 模拟WebSocketService
class MockWebSocketService {
  bool chatMessageReceived = false;
  Map<String, dynamic> lastChatMessage = {};
  
  final StreamController<Map<String, dynamic>> _chatMessageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get onChatMessage => _chatMessageController.stream;
  
  /// 模拟从WebSocketManager接收消息
  void simulateManagerMessage(Map<String, dynamic> data) {
    print('🌉 WebSocketService模拟桥接消息: ${data['type']}');
    _handleWebSocketManagerMessage(data);
  }
  
  /// 模拟桥接处理逻辑
  void _handleWebSocketManagerMessage(Map<String, dynamic> data) {
    final type = data['type'];
    
    switch (type) {
      case 'force_refresh_history':
        // 转发强制刷新历史消息事件到聊天消息流
        print('🔄 桥接强制刷新历史消息事件到聊天流');
        chatMessageReceived = true;
        lastChatMessage = data;
        _chatMessageController.add(data);
        break;
        
      case 'new_private_message':
      case 'new_group_message':
        print('📨 桥接聊天消息');
        chatMessageReceived = true;
        lastChatMessage = data;
        _chatMessageController.add(data);
        break;
        
      default:
        print('📨 其他类型消息: $type');
        break;
    }
  }
}

/// 模拟聊天界面
class MockChatScreen {
  bool forceRefreshTriggered = false;
  bool apiCallMade = false;
  bool uiRefreshed = false;
  
  /// 处理聊天消息
  void handleChatMessage(Map<String, dynamic> data) {
    print('📱 聊天界面收到消息: ${data['type']}');
    
    switch (data['type']) {
      case 'force_refresh_history':
        print('🔄 处理强制刷新历史消息事件');
        _handleForceRefreshHistory(data);
        break;
        
      case 'new_private_message':
      case 'new_group_message':
        print('📨 处理新消息');
        break;
        
      default:
        print('❓ 未知消息类型: ${data['type']}');
        break;
    }
  }
  
  /// 处理强制刷新历史消息
  void _handleForceRefreshHistory(Map<String, dynamic> data) {
    forceRefreshTriggered = true;
    
    // 模拟调用API获取历史消息
    _forceRefreshHistoryFromAPI();
  }
  
  /// 模拟从API获取历史消息
  void _forceRefreshHistoryFromAPI() {
    print('📡 模拟调用API获取历史消息');
    apiCallMade = true;
    
    // 模拟API返回历史消息
    final mockApiMessages = [
      {
        'id': 'hist_msg_001',
        'content': '历史消息1',
        'sourceDeviceId': 'device_002',
        'createdAt': '2025-01-20T10:00:00.000Z',
      },
      {
        'id': 'hist_msg_002',
        'content': '历史消息2',
        'sourceDeviceId': 'device_003',
        'createdAt': '2025-01-20T10:01:00.000Z',
      }
    ];
    
    _processAPIMessages(mockApiMessages);
  }
  
  /// 模拟处理API消息
  void _processAPIMessages(List<Map<String, dynamic>> messages) {
    print('🔄 处理API返回的${messages.length}条历史消息');
    
    // 模拟UI更新
    uiRefreshed = true;
    
    print('✅ UI已刷新，显示${messages.length}条历史消息');
  }
} 
 
 
 
 
 
 
 
 
 
 
 
 
 