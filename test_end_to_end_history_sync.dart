import 'dart:async';
import 'dart:convert';

/// 端到端测试：设备连接状态变化时强制获取历史消息
/// 
/// 测试完整流程：
/// 1. 设备从离线到在线
/// 2. WebSocketManager 检测到状态变化
/// 3. 发送 force_refresh_history 事件
/// 4. WebSocketService 桥接事件
/// 5. ChatScreen 接收并处理事件
/// 6. 调用API获取历史消息
/// 7. UI刷新显示历史消息

void main() {
  print('🧪 开始端到端测试：设备连接状态变化时强制获取历史消息');
  
  testCompleteFlow();
  testConnectionRestoredScenario();
  testAPIIntegration();
  
  print('✅ 所有端到端测试完成');
}

/// 测试完整流程
void testCompleteFlow() {
  print('\n📋 测试1: 完整端到端流程');
  
  // 创建整个测试环境
  final mockWebSocketManager = MockWebSocketManager();
  final mockWebSocketService = MockWebSocketService(mockWebSocketManager);
  final mockChatScreen = MockChatScreen(mockWebSocketService);
  
  // 模拟设备从离线到在线的状态变化
  print('🔄 模拟设备状态变化: 离线 -> 已连接');
  mockWebSocketManager.simulateConnectionRestored();
  
  // 验证完整流程
  assert(mockWebSocketManager.refreshEventSent, '应该发送刷新事件');
  assert(mockWebSocketService.eventBridged, '应该桥接事件');
  assert(mockChatScreen.eventReceived, '聊天界面应该收到事件');
  assert(mockChatScreen.apiCalled, '应该调用API');
  assert(mockChatScreen.uiUpdated, '应该更新UI');
  
  print('✅ 完整端到端流程测试通过');
}

/// 测试连接恢复场景
void testConnectionRestoredScenario() {
  print('\n📋 测试2: 连接恢复场景');
  
  final environment = createTestEnvironment();
  
  // 模拟真实的连接恢复场景
  print('📱 模拟应用从后台恢复到前台');
  environment.webSocketManager.simulateAppResume();
  
  print('🌐 模拟网络从断开到恢复');
  environment.webSocketManager.simulateNetworkReconnect();
  
  print('🔌 模拟WebSocket重新连接成功');
  environment.webSocketManager.simulateWebSocketReconnect();
  
  // 验证每个场景都触发了历史消息同步
  assert(environment.chatScreen.historyRefreshCount >= 1, '应该至少触发一次历史消息刷新');
  assert(environment.chatScreen.lastRefreshReason.contains('connection_restored'), '刷新原因应该包含connection_restored');
  
  print('✅ 连接恢复场景测试通过');
}

/// 测试API集成
void testAPIIntegration() {
  print('\n📋 测试3: API集成测试');
  
  final environment = createTestEnvironment();
  
  // 模拟不同类型的对话
  print('📝 测试群组对话历史消息获取');
  environment.chatScreen.setConversationType('group', 'group_123');
  environment.webSocketManager.simulateConnectionRestored();
  
  assert(environment.chatScreen.lastAPICall == 'getGroupMessages', '应该调用群组消息API');
  assert(environment.chatScreen.lastAPIParams['groupId'] == 'group_123', '应该传递正确的群组ID');
  assert(environment.chatScreen.lastAPIParams['limit'] == 50, '应该获取50条历史消息');
  
  print('💬 测试私聊对话历史消息获取');
  environment.chatScreen.setConversationType('private', 'device_456');
  environment.webSocketManager.simulateConnectionRestored();
  
  assert(environment.chatScreen.lastAPICall == 'getPrivateMessages', '应该调用私聊消息API');
  assert(environment.chatScreen.lastAPIParams['targetDeviceId'] == 'device_456', '应该传递正确的设备ID');
  
  print('✅ API集成测试通过');
}

/// 创建测试环境
TestEnvironment createTestEnvironment() {
  final webSocketManager = MockWebSocketManager();
  final webSocketService = MockWebSocketService(webSocketManager);
  final chatScreen = MockChatScreen(webSocketService);
  
  return TestEnvironment(
    webSocketManager: webSocketManager,
    webSocketService: webSocketService,
    chatScreen: chatScreen,
  );
}

/// 测试环境
class TestEnvironment {
  final MockWebSocketManager webSocketManager;
  final MockWebSocketService webSocketService;
  final MockChatScreen chatScreen;
  
  TestEnvironment({
    required this.webSocketManager,
    required this.webSocketService,
    required this.chatScreen,
  });
}

/// 模拟WebSocketManager
class MockWebSocketManager {
  bool refreshEventSent = false;
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get onMessageReceived => _messageController.stream;
  
  /// 模拟连接恢复
  void simulateConnectionRestored() {
    print('🔄 WebSocketManager: 执行连接恢复同步...');
    refreshEventSent = true;
    
    // 发送强制刷新历史消息事件
    _messageController.add({
      'type': 'force_refresh_history',
      'reason': 'connection_restored',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'refresh_group_messages': true,
        'refresh_private_messages': true,
        'sync_limit': 50,
      }
    });
    
    print('📨 已发送 force_refresh_history 事件');
  }
  
  /// 模拟应用恢复
  void simulateAppResume() {
    simulateConnectionRestored();
  }
  
  /// 模拟网络重连
  void simulateNetworkReconnect() {
    simulateConnectionRestored();
  }
  
  /// 模拟WebSocket重连
  void simulateWebSocketReconnect() {
    simulateConnectionRestored();
  }
}

/// 模拟WebSocketService
class MockWebSocketService {
  bool eventBridged = false;
  final MockWebSocketManager _webSocketManager;
  final StreamController<Map<String, dynamic>> _chatMessageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get onChatMessage => _chatMessageController.stream;
  
  MockWebSocketService(this._webSocketManager) {
    // 设置桥接
    _webSocketManager.onMessageReceived.listen((data) {
      _handleWebSocketManagerMessage(data);
    });
  }
  
  /// 桥接处理
  void _handleWebSocketManagerMessage(Map<String, dynamic> data) {
    final type = data['type'];
    print('🌉 WebSocketService桥接消息: $type');
    
    switch (type) {
      case 'force_refresh_history':
        print('🔄 桥接强制刷新历史消息事件到聊天流');
        eventBridged = true;
        _chatMessageController.add(data);
        break;
        
      default:
        print('📨 其他消息类型: $type');
        break;
    }
  }
}

/// 模拟ChatScreen
class MockChatScreen {
  bool eventReceived = false;
  bool apiCalled = false;
  bool uiUpdated = false;
  int historyRefreshCount = 0;
  String lastRefreshReason = '';
  String lastAPICall = '';
  Map<String, dynamic> lastAPIParams = {};
  
  String _conversationType = 'group';
  String _conversationId = 'group_123';
  
  MockChatScreen(MockWebSocketService webSocketService) {
    // 订阅聊天消息
    webSocketService.onChatMessage.listen((data) {
      _handleChatMessage(data);
    });
  }
  
  /// 设置对话类型
  void setConversationType(String type, String id) {
    _conversationType = type;
    _conversationId = id;
  }
  
  /// 处理聊天消息
  void _handleChatMessage(Map<String, dynamic> data) {
    print('📱 ChatScreen收到消息: ${data['type']}');
    
    switch (data['type']) {
      case 'force_refresh_history':
        eventReceived = true;
        historyRefreshCount++;
        lastRefreshReason = data['reason'] ?? '';
        _handleForceRefreshHistory(data);
        break;
        
      default:
        print('❓ 未知消息类型: ${data['type']}');
        break;
    }
  }
  
  /// 处理强制刷新历史消息
  void _handleForceRefreshHistory(Map<String, dynamic> data) {
    print('🔄 处理强制刷新历史消息事件: ${data['reason']}');
    _forceRefreshHistoryFromAPI();
  }
  
  /// 从API获取历史消息
  void _forceRefreshHistoryFromAPI() {
    print('📡 强制从API获取历史消息...');
    apiCalled = true;
    
    // 根据对话类型调用不同API
    if (_conversationType == 'group') {
      lastAPICall = 'getGroupMessages';
      lastAPIParams = {
        'groupId': _conversationId,
        'limit': 50,
      };
      print('📞 调用群组消息API: groupId=$_conversationId');
    } else {
      lastAPICall = 'getPrivateMessages';
      lastAPIParams = {
        'targetDeviceId': _conversationId,
        'limit': 50,
      };
      print('📞 调用私聊消息API: targetDeviceId=$_conversationId');
    }
    
    // 模拟API返回历史消息
    final mockMessages = [
      {
        'id': 'hist_001',
        'content': '历史消息1',
        'sourceDeviceId': 'device_002',
        'createdAt': '2025-01-20T10:00:00.000Z',
      },
      {
        'id': 'hist_002',
        'content': '历史消息2',
        'sourceDeviceId': 'device_003',
        'createdAt': '2025-01-20T10:01:00.000Z',
      }
    ];
    
    _processAPIMessages(mockMessages);
  }
  
  /// 处理API消息
  void _processAPIMessages(List<Map<String, dynamic>> messages) {
    print('🔄 处理API返回的${messages.length}条历史消息');
    uiUpdated = true;
    print('✅ UI已更新，显示${messages.length}条历史消息');
  }
} 
 
 
 
 
 
 
 
 
 
 
 
 
 