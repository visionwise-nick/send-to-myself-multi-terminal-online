import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/device_auth_service.dart';
import '../services/websocket_service.dart';

class AuthProvider with ChangeNotifier {
  final DeviceAuthService _authService = DeviceAuthService();
  final WebSocketService _websocketService = WebSocketService();
  
  Map<String, dynamic>? _deviceInfo;
  List<dynamic>? _groups;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _profile;
  
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get deviceInfo => _deviceInfo;
  Map<String, dynamic>? get profile => _profile;
  List<dynamic>? get groups => _groups;
  
  AuthProvider() {
    _initialize();
    _initWebSocket();
    _websocketService.onDeviceStatusChange.listen(_handleDeviceStatusChange);
    _websocketService.onLogout.listen(_handleLogoutEvent);
  }
  
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _isLoggedIn = await _authService.isLoggedIn();
      
      if (_isLoggedIn) {
        // 获取设备信息
        _deviceInfo = await _authService.getDeviceInfo();
        
        // 获取设备资料
        final profileData = await _authService.getProfile();
        if (profileData['success'] == true) {
          _profile = profileData['device'];
          _groups = profileData['groups'];
        }
        
        // 连接WebSocket
        await _websocketService.connect();
      }
    } catch (e) {
      print('初始化失败: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> _initWebSocket() async {
    try {
      await _websocketService.connect();
      print('WebSocket连接成功初始化');
    } catch (e) {
      print('WebSocket初始化失败: $e');
    }
  }
  
  void _handleDeviceStatusChange(Map<String, dynamic> data) {
    print('收到设备状态变化: $data');
    
    if (data['type'] == 'device_status') {
      final action = data['action'];
      
      if (action == 'joined') {
        // 设备加入群组，立即刷新资料
        print('设备加入群组，立即刷新资料');
        refreshProfile();
      } else if (action == 'left') {
        // 设备离开群组，立即刷新资料
        print('设备离开群组，立即刷新资料');
        refreshProfile();
      } else if (action == 'status_changed') {
        // 设备在线状态变化，更新设备状态
        print('设备在线状态变化');
        if (data.containsKey('device') && data.containsKey('online')) {
          _updateDeviceStatus(data['device'], data['online']);
        }
      }
    } else if (data['type'] == 'online_devices') {
      // 更新所有在线设备
      print('收到在线设备列表');
      if (data.containsKey('devices') && data['devices'] is List) {
        _updateOnlineDevices(data['devices']);
      }
    } else if (data['type'] == 'device_status_update') {
      // 处理device_status_update消息中的设备状态列表
      print('收到设备状态批量更新');
      if (data.containsKey('device_statuses') && data['device_statuses'] is List) {
        _updateDeviceStatuses(data['device_statuses']);
      }
    } else if (data['type'] == 'group_devices_status') {
      // 处理group_devices_status消息中的设备状态
      print('收到群组设备状态更新');
      if (data.containsKey('devices') && data['devices'] is List) {
        _updateGroupDevices(data['groupId'], data['devices']);
      }
    }
  }
  
  void _updateDeviceStatus(Map<String, dynamic> deviceData, bool isOnline) {
    if (_groups == null || deviceData == null || deviceData['id'] == null) return;
    
    print('更新设备状态: id=${deviceData['id']}, 在线状态=$isOnline');
    bool updated = false;
    
    for (final group in _groups!) {
      if (group['devices'] != null && group['devices'] is List) {
        for (final device in group['devices']) {
          if (device['id'] == deviceData['id']) {
            // 使用传入的真实在线状态
            device['isOnline'] = isOnline;
            print('设备${device['name']}(${device['id']})状态更新为${isOnline ? "在线" : "离线"}');
            updated = true;
          }
        }
      }
    }
    
    if (updated) {
      print('设备状态已更新，通知UI刷新');
      notifyListeners();
    }
  }
  
  void _updateOnlineDevices(List<dynamic> onlineDevices) {
    if (_groups == null) return;
    
    print('收到在线设备列表: ${onlineDevices.length}个设备');
    
    // 创建在线设备ID集合，方便查询
    final onlineDeviceIds = Set<String>.from(
      onlineDevices.map((device) => device['id']?.toString() ?? '')
    );
    
    print('在线设备ID集合: $onlineDeviceIds');
    
    bool updated = false;
    
    // 更新所有设备的在线状态
    for (final group in _groups!) {
      if (group['devices'] != null && group['devices'] is List) {
        for (final device in group['devices']) {
          final deviceId = device['id']?.toString() ?? '';
          final shouldBeOnline = onlineDeviceIds.contains(deviceId);
          
          // 只有当状态确实发生变化时才更新
          if (device['isOnline'] != shouldBeOnline) {
            device['isOnline'] = shouldBeOnline;
            print('设备${device['name']}(${device['id']})状态更新为${shouldBeOnline ? "在线" : "离线"}');
            updated = true;
          }
        }
      }
    }
    
    if (updated) {
      print('批量设备状态已更新，通知UI刷新');
      notifyListeners();
    }
  }
  
  // 注册设备
  Future<void> registerDevice() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _authService.registerDevice();
      if (result['success'] == true) {
        _isLoggedIn = true;
        _deviceInfo = await _authService.getDeviceInfo();
        _profile = result['device'];
        _groups = [result['group']];
        
        // 连接WebSocket
        await _websocketService.connect();
      }
    } catch (e) {
      print('注册失败: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // 创建群组加入码
  Future<Map<String, dynamic>> createJoinCode(String groupId) async {
    try {
      return await _authService.createJoinCode(groupId);
    } catch (e) {
      print('创建加入码失败: $e');
      rethrow;
    }
  }
  
  // 通过加入码加入群组
  Future<Map<String, dynamic>> joinGroup(String joinCode) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _authService.joinGroup(joinCode);
      if (result['success'] == true) {
        // 刷新资料
        await refreshProfile();
      }
      return result;
    } catch (e) {
      print('加入群组失败: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 生成加入二维码
  Future<Map<String, dynamic>> generateQRCode() async {
    try {
      print('正在生成二维码...');
      final result = await _authService.generateQrcode();
      print('生成二维码结果: $result');
      return result;
    } catch (e) {
      print('生成二维码失败: $e');
      rethrow;
    }
  }
  
  // 离开群组
  Future<bool> leaveGroup(String groupId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _authService.leaveGroup(groupId);
      if (result['success'] == true) {
        // 刷新资料
        await refreshProfile();
        return true;
      }
      return false;
    } catch (e) {
      print('离开群组失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 刷新设备资料
  Future<void> refreshProfile() async {
    print('========== 开始刷新设备资料 ==========');
    try {
      final profileData = await _authService.getProfile();
      
      // 更新本地状态
      _deviceInfo = profileData['device'];
      _groups = List<Map<String, dynamic>>.from(profileData['groups'] ?? []);
      
      print('获取到${_groups?.length ?? 0}个群组');
      
      // 处理设备列表，根据真实数据设置在线状态
      for (final group in _groups!) {
        if (group['devices'] != null && group['devices'] is List) {
          print('群组${group['name']}有${group['devices'].length}个设备');
          for (final device in group['devices']) {
            // 标记当前设备
            final bool isCurrentDevice = (_deviceInfo?['id'] != null && device['id'] == _deviceInfo?['id']);
            device['isCurrentDevice'] = isCurrentDevice;
            
            // 根据设备的真实状态判断在线状态
            bool isOnline = false;
            
            if (isCurrentDevice) {
              // 当前设备始终在线
              isOnline = true;
              print('当前设备: ${device['name']}(${device['id']}) - 在线');
            } else {
              // 其他设备根据服务器数据判断
              if (device['is_logged_out'] == true) {
                isOnline = false;
                print('设备${device['name']}(${device['id']}) - 已登出');
              } else if (device['is_online'] == true) {
                // 服务器说在线，优先相信服务器状态
                isOnline = true;
                print('设备${device['name']}(${device['id']}) - 在线 (服务器状态)');
              } else {
                // 服务器明确说离线
                isOnline = false;
                print('设备${device['name']}(${device['id']}) - 离线 (服务器状态)');
              }
            }
            
            device['isOnline'] = isOnline;
          }
        }
      }
      
      // 获取最新的在线设备状态
      WebSocketService().refreshDeviceStatus();
      
      print('设备资料刷新成功');
      notifyListeners();
    } catch (e) {
      print('刷新设备资料失败: $e');
    } finally {
      print('========== 结束刷新设备资料 ==========');
    }
  }
  
  // 获取群组设备列表
  Future<List<dynamic>> getGroupDevices(String groupId) async {
    try {
      final result = await _authService.getGroupDevices(groupId);
      if (result['success'] == true) {
        return result['devices'];
      }
      return [];
    } catch (e) {
      print('获取群组设备失败: $e');
      return [];
    }
  }
  
  // 处理登出事件
  void _handleLogoutEvent(Map<String, dynamic> data) {
    print('收到登出事件: $data');
    
    final eventType = data['type'];
    final message = data['message'] ?? '设备已登出';
    
    switch (eventType) {
      case 'logout_notification':
        print('收到登出通知: $message');
        _performLogoutCleanup(showMessage: true, message: message);
        break;
      case 'forced_disconnect':
        print('被强制断开连接: $message');
        _performLogoutCleanup(showMessage: true, message: message);
        break;
      case 'reconnect_blocked':
        print('重连被阻止: $message');
        _performLogoutCleanup(showMessage: true, message: message);
        break;
    }
  }
  
  // 登出
  Future<bool> logout({bool showProgress = true}) async {
    if (showProgress) {
      _isLoading = true;
      notifyListeners();
    }
    
    try {
      print('开始执行登出流程...');
      
      // 调用登出API
      final result = await _authService.logout();
      
      if (result['success'] == true) {
        print('登出API调用成功: ${result['message']}');
      } else {
        print('登出API调用失败: ${result['message']}');
      }
      
      // 无论API是否成功，都执行本地清理
      await _performLogoutCleanup(showMessage: false);
      
      return true;
      
    } catch (e) {
      print('登出过程中发生错误: $e');
      
      // 即使出错也要执行清理
      await _performLogoutCleanup(showMessage: false);
      
      return false;
    } finally {
      if (showProgress) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
  
  // 执行登出清理
  Future<void> _performLogoutCleanup({bool showMessage = false, String? message}) async {
    try {
      print('开始执行登出清理...');
      
      // 断开WebSocket连接
      _websocketService.disconnect();
      
      // 清除应用状态
      _isLoggedIn = false;
      _profile = null;
      _groups = null;
      _deviceInfo = null;
      
      // 清除本地存储
      await _authService.performLogoutCleanup();
      
      print('登出清理完成');
      
      // 通知UI更新
      notifyListeners();
      
      if (showMessage && message != null) {
        print('登出消息: $message');
        // 这里可以显示登出提示消息
        // 由于这是Provider，不直接处理UI，让调用方处理
      }
      
    } catch (e) {
      print('登出清理失败: $e');
    }
  }
  
  // 处理device_status_update消息中的设备状态列表
  void _updateDeviceStatuses(List<dynamic> deviceStatuses) {
    if (_groups == null) return;
    
    print('批量更新设备状态: ${deviceStatuses.length}个设备');
    bool updated = false;
    
    // 创建设备状态映射
    final Map<String, bool> deviceStatusMap = {};
    for (final statusData in deviceStatuses) {
      if (statusData is Map && statusData['id'] != null) {
        // 根据真实的状态数据判断在线状态
        bool isOnline = false;
        
        if (statusData['is_logged_out'] == true) {
          isOnline = false;
        } else if (statusData['is_online'] == true) {
          // 服务器说在线，优先相信服务器状态
          isOnline = true;
        } else {
          // 服务器明确说离线
          isOnline = false;
        }
        
        deviceStatusMap[statusData['id']] = isOnline;
      }
    }
    
    // 更新所有群组中的设备状态
    for (final group in _groups!) {
      if (group['devices'] != null && group['devices'] is List) {
        for (final device in group['devices']) {
          final deviceId = device['id'];
          if (deviceId != null && deviceStatusMap.containsKey(deviceId)) {
            final newStatus = deviceStatusMap[deviceId]!;
            if (device['isOnline'] != newStatus) {
              device['isOnline'] = newStatus;
              print('设备${device['name']}(${device['id']})状态更新为${newStatus ? "在线" : "离线"}');
              updated = true;
            }
          }
        }
      }
    }
    
    if (updated) {
      print('批量设备状态已更新，通知UI刷新');
      notifyListeners();
    }
  }
  
  // 更新来自group_devices_status的设备状态
  void _updateGroupDevices(String groupId, List<dynamic> devices) {
    if (_groups == null) return;
    
    print('更新群组设备状态: 群组ID=$groupId, ${devices.length}个设备');
    bool updated = false;
    
    // 找到对应的群组
    for (final group in _groups!) {
      if (group['id'] == groupId && group['devices'] != null) {
        // 为群组中的每个设备更新状态
        for (final groupDevice in group['devices']) {
          // 在传入的设备列表中查找对应设备
          for (final newDeviceData in devices) {
            if (newDeviceData is Map && 
                groupDevice['id'] == newDeviceData['id']) {
              
              // 根据新设备数据判断在线状态
              bool isOnline = false;
              
              if (newDeviceData['is_logged_out'] == true) {
                isOnline = false;
              } else if (newDeviceData['is_online'] == true) {
                // 服务器说在线，优先相信服务器状态
                isOnline = true;
              } else {
                // 服务器明确说离线
                isOnline = false;
              }
              
              // 只有状态变化时才更新
              if (groupDevice['isOnline'] != isOnline) {
                groupDevice['isOnline'] = isOnline;
                print('群组设备${groupDevice['name']}(${groupDevice['id']})状态更新为${isOnline ? "在线" : "离线"}');
                updated = true;
              }
              
              break;
            }
          }
        }
        
        print('群组${group['name']}设备列表已更新，共${group['devices'].length}台设备');
        break;
      }
    }
    
    if (updated) {
      print('群组设备状态已更新，通知UI刷新');
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _websocketService.dispose();
    super.dispose();
  }
} 