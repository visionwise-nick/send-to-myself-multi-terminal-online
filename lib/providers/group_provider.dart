import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/group_service.dart';
import '../services/websocket_service.dart';
import '../services/websocket_manager.dart';
import '../services/device_auth_service.dart';

class GroupProvider extends ChangeNotifier {
  final GroupService _groupService = GroupService();
  final WebSocketService _websocketService = WebSocketService();
  final WebSocketManager _wsManager = WebSocketManager();
  final DeviceAuthService _authService = DeviceAuthService();
  
  List<Map<String, dynamic>>? _groups;
  Map<String, dynamic>? _currentGroup;
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _groupChangeSubscription;
  StreamSubscription? _deviceStatusSubscription;
  StreamSubscription? _wsManagerMessageSubscription;
  
  // Getters
  List<Map<String, dynamic>>? get groups => _groups;
  Map<String, dynamic>? get currentGroup => _currentGroup;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasGroups => _groups != null && _groups!.isNotEmpty;
  
  // 初始化群组数据
  Future<void> initialize() async {
    await loadGroups();
    await _loadCurrentGroup();
    _subscribeToGroupChanges();
  }
  
  // 订阅群组变化通知
  void _subscribeToGroupChanges() {
    _groupChangeSubscription = _websocketService.onGroupChange.listen((data) {
      _handleGroupChangeNotification(data);
    });
    
    // 同时监听设备状态变化
    _deviceStatusSubscription = _websocketService.onDeviceStatusChange.listen((data) {
      _handleDeviceStatusUpdate(data);
    });
    
    // 监听新的WebSocket管理器消息
    _wsManagerMessageSubscription = _wsManager.onMessageReceived.listen((data) {
      _handleWebSocketManagerMessage(data);
    });
  }
  
  // 处理WebSocket管理器的消息
  void _handleWebSocketManagerMessage(Map<String, dynamic> data) {
    final type = data['type'];
    print('📩 GroupProvider收到WebSocket管理器消息: $type');
    
    switch (type) {
      case 'group_devices_status':
        _handleGroupDevicesStatusFromManager(data);
        break;
      case 'online_devices':
        _handleOnlineDevicesFromManager(data);
        break;
      case 'device_status_update':
        _handleDeviceStatusUpdateFromManager(data);
        break;
    }
  }
  
  // 处理来自WebSocket管理器的群组设备状态
  void _handleGroupDevicesStatusFromManager(Map<String, dynamic> data) {
    if (data.containsKey('devices') && data.containsKey('groupId')) {
      final groupId = data['groupId'];
      final devices = List<Map<String, dynamic>>.from(data['devices']);
      
      print('📊 收到群组设备状态更新: 群组=$groupId, 设备数=${devices.length}');
      
      // 更新当前群组的设备状态
      if (_currentGroup != null && _currentGroup!['id'] == groupId) {
        _currentGroup!['devices'] = devices;
        notifyListeners();
        print('✅ 当前群组设备状态已更新');
      }
      
      // 更新群组列表中对应群组的设备状态
      if (_groups != null) {
        for (var group in _groups!) {
          if (group['id'] == groupId) {
            group['devices'] = devices;
            break;
          }
        }
      }
    }
  }
  
  // 处理来自WebSocket管理器的在线设备列表
  void _handleOnlineDevicesFromManager(Map<String, dynamic> data) {
    if (data.containsKey('devices')) {
      final devices = List<Map<String, dynamic>>.from(data['devices']);
      print('📱 收到在线设备列表更新: ${devices.length}台设备');
      
      // 创建在线设备ID到状态的映射
      final Map<String, bool> onlineStatusMap = {};
      for (var device in devices) {
        onlineStatusMap[device['id']] = device['isOnline'] == true || device['is_online'] == true;
      }
      
      // 更新当前群组中设备的在线状态
      if (_currentGroup != null && _currentGroup!['devices'] != null) {
        bool hasChanges = false;
        for (var device in _currentGroup!['devices']) {
          final deviceId = device['id'];
          if (onlineStatusMap.containsKey(deviceId)) {
            final newStatus = onlineStatusMap[deviceId]!;
            final currentStatus = device['isOnline'] == true || device['is_online'] == true;
            
            if (currentStatus != newStatus) {
              device['isOnline'] = newStatus;
              device['is_online'] = newStatus;
              hasChanges = true;
              print('🔄 设备${device['name']}(${deviceId})状态: ${currentStatus ? "在线" : "离线"} -> ${newStatus ? "在线" : "离线"}');
            }
          }
        }
        
        if (hasChanges) {
          notifyListeners();
          print('✅ 设备在线状态已更新');
        }
      }
    }
  }
  
  // 处理来自WebSocket管理器的设备状态更新
  void _handleDeviceStatusUpdateFromManager(Map<String, dynamic> data) {
    print('🔄 收到设备状态更新: $data');
    // 可以根据需要处理特定的设备状态更新
  }
  
  // 处理群组变化通知
  void _handleGroupChangeNotification(Map<String, dynamic> data) {
    final type = data['type'];
    print('收到群组变化通知: $type');
    
    switch (type) {
      case 'device_joined_group':
        _handleDeviceJoinedGroup(data);
        break;
      case 'device_left_group':
        _handleDeviceLeftGroup(data);
        break;
      case 'removed_from_group':
        _handleRemovedFromGroup(data);
        break;
      case 'group_ownership_changed':
        _handleGroupOwnershipChanged(data);
        break;
      case 'group_renamed':
        _handleGroupRenamed(data);
        break;
      case 'device_renamed':
        _handleDeviceRenamed(data);
        break;
      case 'group_deleted':
        _handleGroupDeleted(data);
        break;
    }
  }
  
  // 处理设备加入群组通知
  void _handleDeviceJoinedGroup(Map<String, dynamic> data) {
    print('处理设备加入群组通知');
    // 重新加载群组列表
    loadGroups();
  }
  
  // 处理设备离开群组通知
  void _handleDeviceLeftGroup(Map<String, dynamic> data) {
    print('处理设备离开群组通知');
    // 重新加载群组列表
    loadGroups();
  }
  
  // 处理被移除出群组通知
  void _handleRemovedFromGroup(Map<String, dynamic> data) {
    final group = data['group'];
    print('被移除出群组: ${group?['name']}');
    
    // 如果被移除的是当前群组，切换到其他群组
    if (_currentGroup != null && _currentGroup!['id'] == group?['id']) {
      _currentGroup = null;
    }
    
    // 重新加载群组列表
    loadGroups();
    
    // 显示通知
    _error = '您已被移除出群组"${group?['name']}"';
    notifyListeners();
  }
  
  // 处理群组所有权变更通知
  void _handleGroupOwnershipChanged(Map<String, dynamic> data) {
    final group = data['group'];
    final newOwner = data['newOwner'];
    print('群组所有权变更: ${group?['name']} -> ${newOwner?['name']}');
    
    // 重新加载群组列表以获取最新状态
    loadGroups();
  }
  
  // 处理群组重命名通知
  void _handleGroupRenamed(Map<String, dynamic> data) {
    final groupId = data['groupId'];
    final newName = data['newName'];
    print('群组重命名: $groupId -> $newName');
    
    // 更新本地群组名称
    if (_groups != null) {
      for (final group in _groups!) {
        if (group['id'] == groupId) {
          group['name'] = newName;
          break;
        }
      }
    }
    
    // 如果是当前群组，也更新当前群组信息
    if (_currentGroup != null && _currentGroup!['id'] == groupId) {
      _currentGroup!['name'] = newName;
    }
    
    notifyListeners();
  }
  
  // 处理设备重命名通知
  void _handleDeviceRenamed(Map<String, dynamic> data) {
    print('设备重命名通知');
    // 重新加载群组列表以获取最新的设备名称
    loadGroups();
  }
  
  // 处理群组删除通知
  void _handleGroupDeleted(Map<String, dynamic> data) {
    final groupId = data['groupId'];
    final groupName = data['groupName'];
    print('群组已删除: $groupName');
    
    // 如果删除的是当前群组，清除当前群组
    if (_currentGroup != null && _currentGroup!['id'] == groupId) {
      _currentGroup = null;
    }
    
    // 从群组列表中移除
    if (_groups != null) {
      _groups!.removeWhere((group) => group['id'] == groupId);
    }
    
    // 显示通知
    _error = '群组"$groupName"已被删除';
    notifyListeners();
  }
  
  // 加载群组列表
  Future<void> loadGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _groupService.getGroups();
      if (response['success'] == true) {
        _groups = List<Map<String, dynamic>>.from(response['groups'] ?? []);
        print('加载了${_groups?.length ?? 0}个群组');
        
        // 尝试恢复上次选择的群组，如果没有则设置第一个群组为当前群组
        if (_currentGroup == null && _groups != null && _groups!.isNotEmpty) {
          await _loadCurrentGroup();
          // 如果仍然没有当前群组，设置第一个群组为当前群组
          if (_currentGroup == null) {
            await setCurrentGroup(_groups!.first);
          }
        }
      } else {
        _error = response['message'] ?? '加载群组失败';
      }
    } catch (e) {
      _error = '加载群组失败: $e';
      print(_error);
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // 创建新群组
  Future<bool> createGroup(String groupName, {String? description}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _groupService.createGroup(groupName, description: description);
      if (response['success'] == true) {
        // 重新加载群组列表
        await loadGroups();
        
        // 设置新创建的群组为当前群组
        final newGroup = response['group'];
        if (newGroup != null) {
          await setCurrentGroup(newGroup);
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? '创建群组失败';
      }
    } catch (e) {
      _error = '创建群组失败: $e';
      print(_error);
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  // 生成邀请码
  Future<Map<String, dynamic>?> generateInviteCode({int expiryHours = 24}) async {
    if (_currentGroup == null) {
      _error = '请先选择一个群组';
      notifyListeners();
      return null;
    }
    
    try {
      final response = await _groupService.generateInviteCode(
        _currentGroup!['id'],
        expiryHours: expiryHours,
      );
      
      if (response['success'] == true) {
        return response;
      } else {
        _error = response['message'] ?? '生成邀请码失败';
        notifyListeners();
      }
    } catch (e) {
      _error = '生成邀请码失败: $e';
      print(_error);
      notifyListeners();
    }
    
    return null;
  }
  
  // 通过加入码加入群组
  Future<bool> joinGroup(String joinCode, {String? groupId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _authService.joinGroup(joinCode);
      
      print('加入群组响应: $response');
      
      if (response['success'] == true) {
        // 重新加载群组列表
        await loadGroups();
        
        // 设置加入的群组为当前群组
        final joinedGroup = response['group'];
        if (joinedGroup != null) {
          await setCurrentGroup(joinedGroup);
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? '加入群组失败';
        print('加入群组失败: $_error');
      }
    } catch (e) {
      _error = '加入群组失败: $e';
      print(_error);
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  // 设置当前群组
  Future<void> setCurrentGroup(Map<String, dynamic> group) async {
    _currentGroup = group;
    await _saveCurrentGroup();
    print('切换到群组: ${group['name']} (${group['id']})');
    notifyListeners();
  }
  
  // 获取群组设备列表
  Future<List<Map<String, dynamic>>?> getGroupDevices(String groupId) async {
    try {
      final response = await _groupService.getGroupDevices(groupId);
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['devices'] ?? []);
      }
    } catch (e) {
      print('获取群组设备失败: $e');
    }
    return null;
  }
  
  // 解析二维码
  Map<String, dynamic>? parseQRCode(String qrData) {
    return _groupService.parseQRCodeData(qrData);
  }
  
  // 清除错误信息
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // 保存当前群组到本地存储
  Future<void> _saveCurrentGroup() async {
    if (_currentGroup != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_group_id', _currentGroup!['id']);
    }
  }
  
  // 从本地存储加载当前群组
  Future<void> _loadCurrentGroup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentGroupId = prefs.getString('current_group_id');
      
      if (currentGroupId != null && _groups != null) {
        final group = _groups!.firstWhere(
          (g) => g['id'] == currentGroupId,
          orElse: () => _groups!.isNotEmpty ? _groups!.first : {},
        );
        
        if (group.isNotEmpty) {
          _currentGroup = group;
          print('恢复当前群组: ${group['name']} (${group['id']})');
        }
      }
    } catch (e) {
      print('加载当前群组失败: $e');
    }
  }
  
  // 获取群组详情
  Future<Map<String, dynamic>?> getGroupDetails(String groupId) async {
    try {
      final response = await _groupService.getGroupDetails(groupId);
      if (response['success'] == true) {
        return response['group'];
      }
    } catch (e) {
      print('获取群组详情失败: $e');
      _error = '获取群组详情失败: $e';
      notifyListeners();
    }
    return null;
  }
  
  // 获取群组成员列表
  Future<List<Map<String, dynamic>>?> getGroupMembers(String groupId) async {
    try {
      final response = await _groupService.getGroupMembers(groupId);
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['devices'] ?? []);
      }
    } catch (e) {
      print('获取群组成员失败: $e');
      _error = '获取群组成员失败: $e';
      notifyListeners();
    }
    return null;
  }
  
  // 群组重命名
  Future<bool> renameGroup(String groupId, String newName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _groupService.renameGroup(groupId, newName);
      if (response['success'] == true) {
        // 重新加载群组列表
        await loadGroups();
        
        // 如果重命名的是当前群组，更新当前群组信息
        if (_currentGroup != null && _currentGroup!['id'] == groupId) {
          _currentGroup!['name'] = newName;
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? '重命名群组失败';
      }
    } catch (e) {
      _error = '重命名群组失败: $e';
      print(_error);
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  // 退出群组
  Future<bool> leaveGroup(String groupId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _groupService.leaveGroup(groupId);
      if (response['success'] == true) {
        // 重新加载群组列表
        await loadGroups();
        
        // 如果退出的是当前群组，切换到第一个群组
        if (_currentGroup != null && _currentGroup!['id'] == groupId) {
          if (_groups != null && _groups!.isNotEmpty) {
            await setCurrentGroup(_groups!.first);
          } else {
            _currentGroup = null;
          }
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? '退出群组失败';
      }
    } catch (e) {
      _error = '退出群组失败: $e';
      print(_error);
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  // 移除设备
  Future<bool> removeDevice(String groupId, String targetDeviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _groupService.removeDevice(groupId, targetDeviceId);
      if (response['success'] == true) {
        // 重新加载群组列表
        await loadGroups();
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? '移除设备失败';
      }
    } catch (e) {
      _error = '移除设备失败: $e';
      print(_error);
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  // 设备重命名
  Future<bool> renameDevice(String newName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _groupService.renameDevice(newName);
      if (response['success'] == true) {
        // 重新加载群组列表以获取更新的设备信息
        await loadGroups();
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? '设备重命名失败';
      }
    } catch (e) {
      _error = '设备重命名失败: $e';
      print(_error);
    }
    
    _isLoading = false;
    notifyListeners();
    return false;
  }
  
  // 刷新当前群组信息
  Future<void> refreshCurrentGroup() async {
    if (_currentGroup != null) {
      await loadGroups();
      
      // 更新当前群组信息
      if (_groups != null) {
        final updatedGroup = _groups!.firstWhere(
          (g) => g['id'] == _currentGroup!['id'],
          orElse: () => _currentGroup!,
        );
        _currentGroup = updatedGroup;
        notifyListeners();
      }
    }
  }
  
  // 处理设备状态更新
  void _handleDeviceStatusUpdate(Map<String, dynamic> data) {
    final type = data['type'];
    print('收到设备状态更新: $type');
    
    switch (type) {
      case 'group_devices_status':
        _handleGroupDevicesStatusUpdate(data);
        break;
      case 'online_devices':
        _handleOnlineDevicesUpdate(data);
        break;
      default:
        print('未知的设备状态更新类型: $type');
        break;
    }
  }
  
  // 处理群组设备状态更新
  void _handleGroupDevicesStatusUpdate(Map<String, dynamic> data) {
    final groupId = data['groupId'];
    final devices = data['devices'] as List<dynamic>?;
    
    if (groupId == null || devices == null) return;
    
    print('更新群组设备状态: 群组ID=$groupId, ${devices.length}台设备');
    
    bool needsUpdate = false;
    
    // 更新当前群组的设备状态
    if (_currentGroup != null && _currentGroup!['id'] == groupId) {
      // 深度比较设备状态是否真的发生了变化
      final currentDevices = _currentGroup!['devices'] as List<dynamic>?;
      if (currentDevices == null || _hasDeviceStatusChanged(currentDevices, devices)) {
        _currentGroup!['devices'] = List<Map<String, dynamic>>.from(
          devices.map((device) => Map<String, dynamic>.from(device))
        );
        needsUpdate = true;
        print('当前群组设备状态已更新');
      }
    }
    
    // 同时更新群组列表中的设备状态
    if (_groups != null) {
      for (final group in _groups!) {
        if (group['id'] == groupId) {
          final currentDevices = group['devices'] as List<dynamic>?;
          if (currentDevices == null || _hasDeviceStatusChanged(currentDevices, devices)) {
            group['devices'] = List<Map<String, dynamic>>.from(
              devices.map((device) => Map<String, dynamic>.from(device))
            );
            needsUpdate = true;
          }
          break;
        }
      }
    }
    
    // 只有状态确实发生变化时才通知UI更新
    if (needsUpdate) {
      print('群组设备状态发生变化，通知UI更新');
      notifyListeners();
      
      // 设备状态更新后，通知WebSocket服务
      _websocketService.notifyDeviceActivityChange();
    }
  }
  
  // 检查设备状态是否发生变化
  bool _hasDeviceStatusChanged(List<dynamic> currentDevices, List<dynamic> newDevices) {
    if (currentDevices.length != newDevices.length) return true;
    
    // 创建设备ID到状态的映射
    final currentStatusMap = <String, bool>{};
    for (final device in currentDevices) {
      if (device is Map && device['id'] != null) {
        currentStatusMap[device['id']] = device['isOnline'] == true;
      }
    }
    
    // 检查新设备状态是否有变化
    for (final device in newDevices) {
      if (device is Map && device['id'] != null) {
        final deviceId = device['id'];
        final newStatus = device['isOnline'] == true;
        
        if (!currentStatusMap.containsKey(deviceId) || currentStatusMap[deviceId] != newStatus) {
          print('设备状态变化检测: $deviceId 从 ${currentStatusMap[deviceId]} 变为 $newStatus');
          return true;
        }
      }
    }
    
    return false;
  }
  
  // 处理在线设备列表更新
  void _handleOnlineDevicesUpdate(Map<String, dynamic> data) {
    final devices = data['devices'] as List<dynamic>?;
    if (devices == null) return;
    
    print('更新在线设备列表: ${devices.length}台设备');
    
    bool needsUpdate = false;
    
    // 创建在线设备状态映射
    final onlineStatusMap = <String, bool>{};
    for (final device in devices) {
      if (device is Map && device['id'] != null) {
        onlineStatusMap[device['id']] = device['isOnline'] == true;
      }
    }
    
    // 更新所有群组中对应设备的在线状态
    if (_groups != null) {
      for (final group in _groups!) {
        final groupDevices = group['devices'] as List<dynamic>?;
        if (groupDevices != null) {
          for (final groupDevice in groupDevices) {
            if (groupDevice is Map<String, dynamic> && groupDevice['id'] != null) {
              final deviceId = groupDevice['id'];
              final currentStatus = groupDevice['isOnline'] == true;
              final newStatus = onlineStatusMap[deviceId] ?? false;
              
              // 只有状态真的发生变化时才更新
              if (currentStatus != newStatus) {
                groupDevice['isOnline'] = newStatus;
                groupDevice['is_online'] = newStatus;
                needsUpdate = true;
                print('设备${groupDevice['name']}(${deviceId})状态: ${currentStatus ? "在线" : "离线"} -> ${newStatus ? "在线" : "离线"}');
              }
            }
          }
        }
      }
    }
    
    // 更新当前群组设备状态
    if (_currentGroup != null) {
      final currentGroupDevices = _currentGroup!['devices'] as List<dynamic>?;
      if (currentGroupDevices != null) {
        for (final groupDevice in currentGroupDevices) {
          if (groupDevice is Map<String, dynamic> && groupDevice['id'] != null) {
            final deviceId = groupDevice['id'];
            final currentStatus = groupDevice['isOnline'] == true;
            final newStatus = onlineStatusMap[deviceId] ?? false;
            
            // 只有状态真的发生变化时才更新
            if (currentStatus != newStatus) {
              groupDevice['isOnline'] = newStatus;
              groupDevice['is_online'] = newStatus;
              needsUpdate = true;
              print('当前群组设备${groupDevice['name']}(${deviceId})状态: ${currentStatus ? "在线" : "离线"} -> ${newStatus ? "在线" : "离线"}');
            }
          }
        }
      }
    }
    
    // 只有状态确实发生变化时才通知UI更新
    if (needsUpdate) {
      print('在线设备状态发生变化，通知UI更新');
      notifyListeners();
    }
  }
  
  // 🔥 新增：获取在线设备数量
  int get onlineDevicesCount {
    if (_currentGroup == null) return 0;
    
    final devices = List<Map<String, dynamic>>.from(_currentGroup!['devices'] ?? []);
    int count = 0;
    
    for (var device in devices) {
      bool isOnline = false;
      
      if (device['is_logged_out'] == true || device['isLoggedOut'] == true) {
        isOnline = false;
      } else if (device['isOnline'] == true || device['is_online'] == true) {
        isOnline = true;
      }
      
      if (isOnline) {
        count++;
      }
    }
    
    return count;
  }
  
  // 🔥 新增：获取总设备数量
  int get totalDevicesCount {
    if (_currentGroup == null) return 0;
    
    final devices = List<Map<String, dynamic>>.from(_currentGroup!['devices'] ?? []);
    return devices.length;
  }

  @override
  void dispose() {
    _groupChangeSubscription?.cancel();
    _deviceStatusSubscription?.cancel();
    _wsManagerMessageSubscription?.cancel();
    super.dispose();
  }
} 