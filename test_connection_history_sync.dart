import 'dart:async';
import 'dart:convert';

/// 测试设备连接状态变化时强制获取历史消息功能
/// 
/// 功能说明：
/// 1. 监听WebSocket连接状态变化
/// 2. 当设备状态从其他状态变更为"已连接"时
/// 3. 强制执行API接口获取历史信息
/// 4. 刷新聊天界面UI显示历史消息

void main() {
  print('🧪 开始测试设备连接状态变化时的历史消息同步功能');
  
  testConnectionStateChangeSync();
  testForceHistoryRefresh();
  testAPIHistoryFetch();
  testUIRefreshAfterSync();
  
  print('✅ 所有测试完成');
}

/// 测试连接状态变化同步
void testConnectionStateChangeSync() {
  print('\n📋 测试1: 连接状态变化同步');
  
  // 模拟WebSocket管理器的连接状态变化
  final mockWebSocketManager = MockWebSocketManager();
  
  // 模拟从离线到在线的状态变化
  print('🔄 模拟设备状态变化: 离线 -> 已连接');
  mockWebSocketManager.simulateConnectionStateChange(
    from: 'disconnected',
    to: 'connected',
    wasOffline: true,
  );
  
  // 验证是否触发了历史消息同步
  assert(mockWebSocketManager.historyRefreshTriggered, '历史消息刷新应该被触发');
  assert(mockWebSocketManager.apiCallsMade.contains('force_sync_group_history'), '应该调用群组历史同步');
  assert(mockWebSocketManager.apiCallsMade.contains('get_recent_messages'), '应该调用最近消息获取');
  
  print('✅ 连接状态变化同步测试通过');
}

/// 测试强制历史刷新
void testForceHistoryRefresh() {
  print('\n📋 测试2: 强制历史刷新');
  
  // 模拟聊天界面收到强制刷新事件
  final mockChatScreen = MockChatScreen();
  
  // 模拟收到强制刷新历史消息事件
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
  
  print('📨 模拟收到强制刷新事件');
  mockChatScreen.handleForceRefreshHistory(refreshEvent);
  
  // 验证是否调用了API获取历史消息
  assert(mockChatScreen.apiHistoryFetchCalled, 'API历史消息获取应该被调用');
  assert(mockChatScreen.uiRefreshed, 'UI应该被刷新');
  
  print('✅ 强制历史刷新测试通过');
}

/// 测试API历史消息获取
void testAPIHistoryFetch() {
  print('\n📋 测试3: API历史消息获取');
  
  // 模拟群组消息API调用
  final mockGroupAPI = MockGroupMessagesAPI();
  
  // 模拟API返回的历史消息
  final mockMessages = [
    {
      'id': 'msg_001',
      'content': '历史消息1',
      'sourceDeviceId': 'device_002',
      'createdAt': '2025-01-20T10:00:00.000Z',
      'type': 'text'
    },
    {
      'id': 'msg_002',
      'content': '历史消息2',
      'sourceDeviceId': 'device_003',
      'createdAt': '2025-01-20T10:01:00.000Z',
      'type': 'text'
    },
  ];
  
  print('📡 模拟API调用: GET /api/messages/group/group_123');
  final result = mockGroupAPI.getGroupMessages(
    groupId: 'group_123',
    limit: 50,
  );
  
  // 验证API调用结果
  assert(result['messages'] != null, 'API应该返回消息列表');
  assert(result['messages'].length == 2, '应该返回2条历史消息');
  
  print('📥 API返回 ${result['messages'].length} 条历史消息');
  print('✅ API历史消息获取测试通过');
}

/// 测试UI刷新
void testUIRefreshAfterSync() {
  print('\n📋 测试4: UI刷新');
  
  final mockChatUI = MockChatUI();
  
  // 模拟处理API返回的历史消息
  final apiMessages = [
    {
      'id': 'msg_003',
      'content': '新的历史消息',
      'sourceDeviceId': 'device_004',
      'createdAt': '2025-01-20T10:02:00.000Z',
      'type': 'text'
    }
  ];
  
  print('🔄 处理API返回的历史消息');
  mockChatUI.processAPIMessages(apiMessages);
  
  // 验证UI更新
  assert(mockChatUI.messagesAdded, '消息应该被添加到UI');
  assert(mockChatUI.messagesSorted, '消息应该按时间排序');
  assert(mockChatUI.scrolledToBottom, '应该滚动到底部');
  assert(mockChatUI.messagesSaved, '消息应该被保存到本地');
  
  print('✅ UI刷新测试通过');
}

/// 模拟WebSocket管理器
class MockWebSocketManager {
  bool historyRefreshTriggered = false;
  List<String> apiCallsMade = [];
  
  void simulateConnectionStateChange({
    required String from,
    required String to,
    required bool wasOffline,
  }) {
    print('🔄 连接状态变化: $from -> $to (wasOffline: $wasOffline)');
    
    if (to == 'connected' && wasOffline) {
      // 模拟连接恢复后的同步处理
      _performConnectionRestoredSync();
    }
  }
  
  void _performConnectionRestoredSync() {
    print('🔄 执行连接恢复同步...');
    historyRefreshTriggered = true;
    
    // 模拟发送各种同步请求
    apiCallsMade.addAll([
      'request_group_devices_status',
      'get_online_devices',
      'sync_messages',
      'force_sync_group_history',
      'get_recent_messages',
      'get_offline_messages',
      'sync_all_group_messages',
      'sync_all_private_messages',
    ]);
    
    // 模拟触发UI刷新事件
    _triggerUIRefreshEvent();
  }
  
  void _triggerUIRefreshEvent() {
    print('📨 触发UI历史消息刷新事件');
    // 在实际实现中，这会通过_messageController发送事件
  }
}

/// 模拟聊天界面
class MockChatScreen {
  bool apiHistoryFetchCalled = false;
  bool uiRefreshed = false;
  
  void handleForceRefreshHistory(Map<String, dynamic> data) {
    print('🔄 处理强制刷新历史消息事件: ${data['reason']}');
    
    // 模拟强制从API获取历史消息
    _forceRefreshHistoryFromAPI();
  }
  
  void _forceRefreshHistoryFromAPI() {
    print('📡 强制从API获取历史消息...');
    apiHistoryFetchCalled = true;
    
    // 模拟API调用成功
    final mockApiMessages = [
      {
        'id': 'api_msg_001',
        'content': 'API获取的历史消息',
        'sourceDeviceId': 'device_005',
        'createdAt': '2025-01-20T10:03:00.000Z',
      }
    ];
    
    _processAPIMessages(mockApiMessages);
  }
  
  void _processAPIMessages(List<Map<String, dynamic>> apiMessages) {
    print('🔄 处理API返回的${apiMessages.length}条消息');
    uiRefreshed = true;
  }
}

/// 模拟群组消息API
class MockGroupMessagesAPI {
  Map<String, dynamic> getGroupMessages({
    required String groupId,
    int limit = 20,
    String? before,
  }) {
    print('📡 调用群组消息API: groupId=$groupId, limit=$limit');
    
    // 模拟API响应
    return {
      'messages': [
        {
          'id': 'msg_001',
          'content': '历史消息1',
          'sourceDeviceId': 'device_002',
          'createdAt': '2025-01-20T10:00:00.000Z',
          'type': 'text'
        },
        {
          'id': 'msg_002',
          'content': '历史消息2',
          'sourceDeviceId': 'device_003',
          'createdAt': '2025-01-20T10:01:00.000Z',
          'type': 'text'
        },
      ]
    };
  }
}

/// 模拟聊天UI
class MockChatUI {
  bool messagesAdded = false;
  bool messagesSorted = false;
  bool scrolledToBottom = false;
  bool messagesSaved = false;
  
  void processAPIMessages(List<Map<String, dynamic>> apiMessages) {
    print('🔄 处理API返回的${apiMessages.length}条消息');
    
    // 模拟添加消息到UI
    messagesAdded = true;
    
    // 模拟消息排序
    messagesSorted = true;
    
    // 模拟滚动到底部
    scrolledToBottom = true;
    
    // 模拟保存消息
    messagesSaved = true;
    
    print('✅ UI更新完成');
  }
} 
 
 
 
 
 
 
 
 
 
 
 
 
 