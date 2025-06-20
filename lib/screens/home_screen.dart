import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../services/websocket_service.dart';
import '../services/websocket_manager.dart';
import '../services/system_share_service.dart';
import '../services/chat_service.dart';
import '../widgets/connection_status_widget.dart';
import '../theme/app_theme.dart';
import '../widgets/logout_dialog.dart';

import 'messages_tab.dart';
import 'memories_tab.dart';
import 'join_group_screen.dart';
import 'qr_generate_screen.dart';
import 'group_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;
  late PageController _pageController;
  Timer? _statusSyncTimer;
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
    
    // 监听群组变化，确保页面切换时整个应用状态刷新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      groupProvider.addListener(_onGroupChanged);
      
      // 启动设备状态同步定时器
      _startStatusSyncTimer();
      
      // 🔥 新增：设置系统分享监听
      _setupSystemShareListener();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    groupProvider.removeListener(_onGroupChanged);
    _statusSyncTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
  
  // 开始定期状态同步定时器
  void _startStatusSyncTimer() {
    _statusSyncTimer?.cancel();
    
    // 🔥 优化：每5秒检查一次设备状态同步（原来20秒）
    _statusSyncTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      final websocketService = WebSocketService();
      if (websocketService.isConnected) {
        print('🔄 定期设备状态同步检查（5秒间隔）');
        websocketService.refreshDeviceStatus();
      }
    });
  }
  
  // 用户交互时触发状态同步
  void _onUserInteraction() {
    final websocketService = WebSocketService();
    if (websocketService.isConnected) {
      websocketService.notifyDeviceActivityChange();
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    print('🔄 应用生命周期变化: $state');
    
    if (state == AppLifecycleState.resumed) {
      // 🔥 关键修复：应用回到前台时完整恢复连接和状态
      print('📱 应用回到前台，开始恢复连接...');
      _handleAppResumed();
    } else if (state == AppLifecycleState.paused) {
      // 应用暂停时停止定时器但保持连接
      print('⏸️ 应用暂停，停止定时器');
      _statusSyncTimer?.cancel();
    } else if (state == AppLifecycleState.detached) {
      // 应用完全关闭时清理资源
      print('🚪 应用关闭，清理资源');
      _statusSyncTimer?.cancel();
    }
  }
  
  // 处理应用恢复到前台
  void _handleAppResumed() async {
    // 重启状态同步定时器
    _startStatusSyncTimer();
    
    // 🔥 新增：检查分享内容
    try {
      final systemShareService = Provider.of<SystemShareService>(context, listen: false);
      await systemShareService.handleAndroidIntent();
    } catch (e) {
      print('❌ 应用恢复时检查分享内容失败: $e');
    }
    
    // 检查并恢复WebSocket连接
    final websocketService = WebSocketService();
    if (!websocketService.isConnected) {
      print('🔄 WebSocket未连接，尝试重连...');
      try {
        await websocketService.reconnect();
        print('✅ WebSocket重连成功');
      } catch (e) {
        print('❌ WebSocket重连失败: $e');
      }
    }
    
    // 同时检查新的WebSocket管理器
    final wsManager = WebSocketManager();
    if (!wsManager.isConnected) {
      print('🔄 WebSocket管理器未连接，尝试重连...');
      try {
        await wsManager.reconnect();
        print('✅ WebSocket管理器重连成功');
      } catch (e) {
        print('❌ WebSocket管理器重连失败: $e');
      }
    }
    
    // 延迟2秒后强制刷新状态，确保连接稳定
    Timer(Duration(seconds: 2), () {
      _forceRefreshAllStates();
    });
    
    // 通知用户活跃状态
    _onUserInteraction();
  }
  
  // 强制刷新所有状态
  void _forceRefreshAllStates() {
    print('🔄 强制刷新所有状态...');
    
    // 刷新群组状态
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    groupProvider.refreshCurrentGroup();
    
    // 刷新WebSocket状态
    final websocketService = WebSocketService();
    if (websocketService.isConnected) {
      websocketService.refreshDeviceStatus();
    }
    
    print('✅ 状态刷新完成');
  }
  
  // 🔥 新增：设置系统分享监听
  void _setupSystemShareListener() {
    try {
      final systemShareService = Provider.of<SystemShareService>(context, listen: false);
      systemShareService.onSharedContentReceived = (SharedContent content) {
        _handleSharedContent(content);
      };
      print('✅ 系统分享监听器设置完成');
    } catch (e) {
      print('❌ 设置系统分享监听器失败: $e');
    }
  }
  
  // 🔥 新增：处理分享内容
  void _handleSharedContent(SharedContent content) async {
    try {
      print('📥 处理分享内容: ${content.type}');
      
      // 确保用户已登录
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isLoggedIn) {
        _showMessage('请先登录应用');
        return;
      }
      
      // 获取当前群组
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      var currentGroup = groupProvider.currentGroup;
      
      // 🔥 新增：如果没有当前群组，尝试加载群组并设置第一个
      if (currentGroup == null) {
        print('📥 当前没有选择群组，尝试加载群组列表...');
        await groupProvider.loadGroups();
        currentGroup = groupProvider.currentGroup;
        
        // 🔥 新增：如果加载后还是没有群组，等待更长时间重试
        if (currentGroup == null) {
          print('📥 第一次加载失败，等待2秒后重试...');
          await Future.delayed(Duration(seconds: 2));
          
          // 再次尝试加载群组
          await groupProvider.loadGroups();
          currentGroup = groupProvider.currentGroup;
          
          // 如果还是没有群组，提示用户
          if (currentGroup == null) {
            _showMessage('请先创建或加入一个群组');
            return;
          }
        }
      }
      
      // 🔥 修改：自动发送分享内容，不需要确认对话框
      print('🚀 自动发送分享内容到群组: ${currentGroup['name']}');
      await _sendSharedContent(content, currentGroup);
      
    } catch (e) {
      print('❌ 处理分享内容失败: $e');
      _showMessage('处理分享内容失败: $e');
    }
  }
  
  // 🔥 新增：显示分享确认对话框
  Future<bool?> _showShareConfirmDialog(SharedContent content, Map<String, dynamic> group) async {
    String contentPreview = '';
    String contentType = '';
    
    switch (content.type) {
      case SharedContentType.text:
        contentType = '文本';
               final textLength = content.text?.length ?? 0;
       contentPreview = textLength > 100 
           ? '${content.text!.substring(0, 100)}...' 
           : content.text ?? '';
        break;
      case SharedContentType.image:
        contentType = '图片';
        contentPreview = content.fileName ?? '未知图片';
        break;
      case SharedContentType.video:
        contentType = '视频';
        contentPreview = content.fileName ?? '未知视频';
        break;
      case SharedContentType.audio:
        contentType = '音频';
        contentPreview = content.fileName ?? '未知音频';
        break;
      case SharedContentType.file:
        contentType = '文件';
        contentPreview = content.fileName ?? '未知文件';
        break;
      case SharedContentType.files:
        contentType = '多个文件';
        contentPreview = '${content.files?.length ?? 0}个文件';
        break;
    }
    
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认分享'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('要将${contentType}分享到群组吗？'),
              const SizedBox(height: 8),
              Text('群组: ${group['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('内容: $contentPreview', 
                   style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('分享'),
            ),
          ],
        );
      },
    );
  }
  
  // 🔥 新增：发送分享内容
  Future<void> _sendSharedContent(SharedContent content, Map<String, dynamic> group) async {
    try {
      final shareService = Provider.of<SystemShareService>(context, listen: false);
      if (shareService.isSilentShareMode) {
        print('📤 静默模式：发送分享内容到群组 ${group['name']}');
      } else {
        _showMessage('正在发送...');
      }
      
      switch (content.type) {
        case SharedContentType.text:
          if (content.text != null && content.text!.isNotEmpty) {
            await _chatService.sendGroupMessage(
              groupId: group['id'],
              content: content.text!,
            );
            // 静默模式下不显示提示消息
            if (!shareService.isSilentShareMode) {
              _showMessage('文本已发送');
            }
          }
          break;
          
        case SharedContentType.image:
        case SharedContentType.video:
        case SharedContentType.audio:
        case SharedContentType.file:
          if (content.filePath != null) {
            await _chatService.sendGroupFile(
              groupId: group['id'],
              file: File(content.filePath!),
              fileName: content.fileName ?? 'shared_file',
              fileType: _getFileTypeFromPath(content.filePath!),
            );
            // 静默模式下不显示提示消息
            if (!shareService.isSilentShareMode) {
              _showMessage('文件已发送');
            }
          }
          break;
          
        case SharedContentType.files:
          if (content.files != null && content.files!.isNotEmpty) {
            for (final file in content.files!) {
              await _chatService.sendGroupFile(
                groupId: group['id'],
                file: File(file.path),
                fileName: file.name,
                fileType: _getFileTypeFromPath(file.path),
              );
            }
            // 静默模式下不显示提示消息
            if (!shareService.isSilentShareMode) {
              _showMessage('${content.files!.length}个文件已发送');
            }
          }
          break;
      }
      
      // 切换到消息页面
      if (_selectedIndex != 0) {
        setState(() {
          _selectedIndex = 0;
        });
        if (!_isDesktop()) {
          _pageController.animateToPage(0, 
              duration: const Duration(milliseconds: 300), 
              curve: Curves.easeInOut);
        }
      }
      
      // 🔥 新增：如果是分享Intent，完成分享后关闭应用
      final systemShareService = Provider.of<SystemShareService>(context, listen: false);
      if (systemShareService.isShareIntent) {
        // 静默模式下也要确保消息发送完成，给予足够时间
        final delayTime = systemShareService.isSilentShareMode ? 
          Duration(seconds: 2) : Duration(seconds: 1);
        print('⏰ 等待${delayTime.inSeconds}秒确保消息发送完成...');
        await Future.delayed(delayTime);
        print('✅ 发送等待完成，准备关闭应用');
        await systemShareService.finishShareProcess();
      }
      
    } catch (e) {
      print('❌ 发送分享内容失败: $e');
      _showMessage('发送失败: $e');
      
      // 即使发送失败，也要关闭分享Intent
      final systemShareService = Provider.of<SystemShareService>(context, listen: false);
      if (systemShareService.isShareIntent) {
        final delayTime = systemShareService.isSilentShareMode ? 
          Duration(milliseconds: 500) : Duration(seconds: 2);
        await Future.delayed(delayTime);
        await systemShareService.finishShareProcess();
      }
    }
  }
  
  // 🔥 新增：显示消息
  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  // 🔥 新增：从文件路径获取文件类型
  String _getFileTypeFromPath(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return 'image';
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'webm':
        return 'video';
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
      case 'm4a':
        return 'audio';
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
      case 'ppt':
      case 'pptx':
      case 'txt':
      case 'rtf':
        return 'document';
      default:
        return 'file';
    }
  }
  
  // 群组变化处理 - 通知页面数据可能已变化
  void _onGroupChanged() {
    if (mounted) {
      print('检测到群组变化');
      // 不需要强制重建，页面会通过 Consumer 自动响应变化
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (!_isDesktop()) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    }
    
    // 用户交互时触发状态同步
    _onUserInteraction();
  }

  void _showLogoutDialog() {
    LogoutDialog.showLogoutConfirmDialog(context);
  }

  // 判断是否为桌面端
  bool _isDesktop() {
    if (kIsWeb) {
      return MediaQuery.of(context).size.width >= 800;
    }
    return defaultTargetPlatform == TargetPlatform.macOS ||
           defaultTargetPlatform == TargetPlatform.windows ||
           defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final deviceInfo = authProvider.deviceInfo;
        final deviceName = deviceInfo?['name'] ?? 'Send To Myself';
        
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: _isDesktop() 
            ? _buildDesktopLayout(deviceName)
            : _buildMobileLayout(deviceName),
        );
      },
    );
  }

  // 🔥 重新设计：桌面端布局
  Widget _buildDesktopLayout(String deviceName) {
    return Row(
      children: [
        // 🔥 重新设计：左侧边栏
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(
                color: AppTheme.dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            children: [
              // 🔥 新增：带连接状态的标题栏
              _buildDesktopHeaderWithStatus(deviceName),
                    
              const SizedBox(height: 12),
                    
              // 🔥 重新设计：群组模块（平铺显示）
              _buildGroupSection(),
                        
              const SizedBox(height: 16),
              
              // 🔥 重新设计：导航模块（与群组并列）
              _buildNavigationSection(),
              
              const Spacer(),
              
              // 底部操作区
              _buildDesktopSidebarFooter(),
            ],
          ),
        ),
        
        // 主内容区
        Expanded(
          child: _buildDesktopMainContent(),
        ),
      ],
    );
  }

  // 🔥 新增：带连接状态的桌面端标题栏
  Widget _buildDesktopHeaderWithStatus(String deviceName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo和应用名称
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryColor, AppTheme.primaryDarkColor],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.send_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          
          // 应用信息和连接状态
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
              children: [
                Text(
                  'Send To Myself',
                  style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                    ),
                    const SizedBox(width: 8),
                    // 🔥 连接状态显示在标题栏，右边显示在线设备数
                    const ConnectionStatusWidget(showDeviceCount: true),
                  ],
                ),
                Text(
                  deviceName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 重新设计：群组模块（平铺显示）
  Widget _buildGroupSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 模块标题和操作按钮
          Row(
            children: [
              Text(
                '群组',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              // 创建群组按钮
              _buildActionButton(
                icon: Icons.add,
                tooltip: '创建群组',
                onTap: () => _showCreateGroupDialog(context),
              ),
              const SizedBox(width: 4),
              // 加入群组按钮
              _buildActionButton(
                icon: Icons.group_add,
                tooltip: '加入群组',
                onTap: () => _showJoinGroupOptions(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 群组列表和在线状态
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.dividerColor,
                width: 0.5,
              ),
            ),
            child: Consumer<GroupProvider>(
              builder: (context, groupProvider, child) {
                final groups = groupProvider.groups;
                final currentGroup = groupProvider.currentGroup;
                
                if (groups == null || groups.isEmpty) {
                  return _buildNoGroupsWidget();
                }
                
                return Column(
                  children: [
                    // 群组列表
                    ...groups.map((group) => _buildGroupItem(
                      group: group,
                      isSelected: group['id'] == currentGroup?['id'],
                      onTap: () {
                        if (group['id'] != currentGroup?['id']) {
                          groupProvider.setCurrentGroup(group);
                        }
                      },
                    )).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 构建单个群组项目
  Widget _buildGroupItem({
    required Map<String, dynamic> group,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // 增加间距
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12), // 🔥 增加圆角
          child: Container(
            width: double.infinity, // 🔥 确保容器占满宽度
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // 🔥 增加内边距，更宽松
            decoration: BoxDecoration(
              color: isSelected 
                ? AppTheme.primaryColor // 🔥 选中态改为玫红色底
                : Colors.transparent,
              borderRadius: BorderRadius.circular(12), // 🔥 增加圆角
              border: isSelected 
                ? null // 🔥 选中态不需要边框
                : Border.all(
                    color: Colors.transparent,
                    width: 1,
                  ),
            ),
            child: Row(
              children: [
                // 群组信息（扩展以占用更多空间）
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group['name'] ?? '未命名群组',
                        style: TextStyle(
                          fontSize: 15, // 🔥 稍微增大字体
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected 
                            ? Colors.white // 🔥 选中态改为白色字
                            : AppTheme.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4), // 🔥 增加行间距
                      // 🔥 替换为在线状态显示
                      Consumer<GroupProvider>(
                        builder: (context, groupProvider, child) {
                          return _buildGroupOnlineStatus(group['id'], groupProvider, isSelected);
                        },
                      ),
                    ],
                  ),
                ),
                
                // 群组操作按钮（阻止事件冒泡）
                if (isSelected) ...[
                  const SizedBox(width: 12), // 🔥 增加间距
                  GestureDetector(
                    onTap: () {
                      // 🔥 阻止事件冒泡到父级InkWell
                      _showQrGenerate(context, group);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6), // 🔥 增加padding
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2), // 🔥 白色半透明背景
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.qr_code,
                        size: 18, // 🔥 图标尺寸
                        color: Colors.white, // 🔥 白色图标
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      // 🔥 阻止事件冒泡到父级InkWell
                      _showGroupManagement(context, group);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6), // 🔥 增加padding
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2), // 🔥 白色半透明背景
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.settings,
                        size: 18, // 🔥 图标尺寸
                        color: Colors.white, // 🔥 白色图标
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 新增：构建群组在线状态显示
  Widget _buildGroupOnlineStatus(String? groupId, GroupProvider groupProvider, bool isSelected) {
    if (groupId == null) {
      return Text(
        '0/0 在线',
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.white.withOpacity(0.8) : AppTheme.textSecondaryColor, // 🔥 适配选中态
        ),
      );
    }

    // 获取该群组的设备列表
    final groups = groupProvider.groups;
    final targetGroup = groups?.firstWhere(
      (group) => group['id'] == groupId,
      orElse: () => <String, dynamic>{},
    );
    
    if (targetGroup == null || targetGroup.isEmpty) {
      return Text(
        '0/0 在线',
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.white.withOpacity(0.8) : AppTheme.textSecondaryColor, // 🔥 适配选中态
        ),
      );
    }

    final devices = List<Map<String, dynamic>>.from(targetGroup['devices'] ?? []);
    final totalCount = devices.length;
    
    // 计算在线设备数量（使用与_buildOnlineIndicator相同的逻辑）
    int onlineCount = 0;
    for (var device in devices) {
      bool isOnline = false;
      
      // 1. 特殊处理当前设备，当前设备始终在线
      if (device['isCurrentDevice'] == true) {
        isOnline = true;
      }
      // 2. 如果设备已登出，直接离线
      else if (device['is_logged_out'] == true || device['isLoggedOut'] == true) {
        isOnline = false;
      }
      // 3. 检查isOnline状态（优先）
      else if (device['isOnline'] == true) {
        isOnline = true;
      }
      // 4. 检查is_online状态（备用）
      else if (device['is_online'] == true) {
        isOnline = true;
      }
      // 5. 默认离线
      else {
        isOnline = false;
      }
      
      if (isOnline) {
        onlineCount++;
      }
    }

    return Row(
      children: [
        // 状态指示灯
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isSelected 
              ? (onlineCount > 0 ? Colors.white : Colors.white.withOpacity(0.6)) // 🔥 选中态使用白色
              : (onlineCount > 0 ? AppTheme.onlineColor : Colors.red.shade400),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$onlineCount/$totalCount 在线',
          style: TextStyle(
            fontSize: 11,
            color: isSelected 
              ? Colors.white.withOpacity(0.9) // 🔥 选中态使用白色
              : (onlineCount > 0 ? AppTheme.onlineColor : Colors.red.shade400),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    double size = 24,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: size * 0.7,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
      ),
    );
  }

  // 构建无群组提示
  Widget _buildNoGroupsWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.group_off,
            size: 32,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            '暂无群组',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '点击上方按钮创建或加入群组',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondaryColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 🔥 新增：导航模块（与群组并列）
  Widget _buildNavigationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 模块标题
          Text(
              '导航',
              style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          
          // 导航项目
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.dividerColor,
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                _buildNavigationItem(
            icon: Icons.chat_bubble_rounded,
            label: '聊天',
            index: 0,
          ),
                const SizedBox(height: 4),
                _buildNavigationItem(
            icon: Icons.psychology_rounded,
            label: '记忆',
            index: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 简化的导航项目（与群组模块样式一致）
  Widget _buildNavigationItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    
    return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected 
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                ? AppTheme.primaryColor.withOpacity(0.3)
                  : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
              Icon(
                icon,
                size: 18,
                    color: isSelected 
                      ? AppTheme.primaryColor
                  : AppTheme.textSecondaryColor,
                ),
              const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  fontSize: 13,
                    color: isSelected 
                      ? AppTheme.primaryColor
                    : AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  // 🔥 重新设计：移动端布局（左侧抽屉菜单）
  Widget _buildMobileLayout(String deviceName) {
    return Scaffold(
      // 左侧抽屉菜单
      drawer: _buildMobileDrawer(deviceName),
      body: SafeArea(
        child: Column(
          children: [
            // 🔥 简化的顶部栏（仅显示连接状态）
            _buildMobileAppBar(deviceName),
            
            // 主要内容区域
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // 禁用滑动
                onPageChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                children: [
                  MessagesTab(),
                  MemoriesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      // 移动端底部导航
      bottomNavigationBar: _buildMobileBottomNav(),
    );
  }

  // 🔥 新增：移动端抽屉菜单
  Widget _buildMobileDrawer(String deviceName) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // 抽屉头部
            Container(
              padding: const EdgeInsets.all(12), // 🔥 减小padding从20到12
      decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryColor, AppTheme.primaryDarkColor],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, // 🔥 减小图标容器从40到32
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8), // 🔥 减小圆角
                    ),
                    child: const Icon(
                      Icons.send_rounded, // 🔥 改回产品图标
                      size: 18, // 🔥 减小图标从24到18
        color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8), // 🔥 减小间距从12到8
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send To Myself', // 🔥 改回产品名称
                          style: TextStyle(
                            fontSize: 13, // 🔥 减小字体从16到13
                            fontWeight: FontWeight.w500, // 🔥 调整字重
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          deviceName,
                          style: TextStyle(
                            fontSize: 10, // 🔥 减小字体从12到10
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
          ),
                      ],
        ),
      ),
                ],
              ),
            ),
            
            // 抽屉内容
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
      child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                    // 群组模块
                    _buildDrawerSection(
                      title: '群组',
                      child: Consumer<GroupProvider>(
                        builder: (context, groupProvider, child) {
                          final groups = groupProvider.groups;
                          final currentGroup = groupProvider.currentGroup;
                          
                          if (groups == null || groups.isEmpty) {
                            return _buildNoGroupsWidget();
                          }
                          
                          return Column(
                            children: [
                              // 群组列表
                              ...groups.map((group) => _buildGroupItem(
                                group: group,
                                isSelected: group['id'] == currentGroup?['id'],
                                onTap: () {
                                  if (group['id'] != currentGroup?['id']) {
                                    groupProvider.setCurrentGroup(group);
                                  }
                                },
                              )).toList(),
                            ],
                          );
                        },
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // 退出登录
                    Container(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                          Navigator.pop(context);
                LogoutDialog.showLogoutConfirmDialog(context);
              },
              icon: Icon(
                Icons.logout,
                          size: 16,
                color: Colors.red.shade600,
              ),
              label: Text(
                '退出登录',
                style: TextStyle(
                  color: Colors.red.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          
                    const SizedBox(height: 16),
          
          // 版权信息
                    Center(
                      child: Text(
            '© 2024 Send To Myself',
            style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
              color: AppTheme.textSecondaryColor.withOpacity(0.6),
                        ),
            ),
          ),
        ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 抽屉模块构建器
  Widget _buildDrawerSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔥 标题栏与操作图标平行
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            // 🔥 创建群组图标
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _showCreateGroupDialog(context);
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 🔥 加入群组图标
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _showJoinGroupOptions(context);
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.group_add,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.dividerColor,
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ],
    );
    }

  // 🔥 简化的移动端顶部栏（仅显示连接状态和菜单）
  Widget _buildMobileAppBar(String deviceName) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        final currentGroup = groupProvider.currentGroup;
        final groupName = currentGroup?['name'] ?? '无群组';
        
    return Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 4), // 🔥 进一步压缩高度
      decoration: BoxDecoration(
            color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
              // 🔥 群组图标按钮（可点击打开抽屉）
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    padding: const EdgeInsets.all(6), // 🔥 减小padding
                    child: Icon(
                      Icons.group, // 🔥 改为群组图标
                      size: 16, // 🔥 减小图标尺寸
                      color: AppTheme.primaryColor, // 🔥 玫红色
                    ),
                  ),
                ),
          ),
          
              // 🔥 群组名称标题（可点击打开抽屉）
              GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6), // 🔥 减小垂直padding
                  child: Text(
                    groupName,
                    style: TextStyle(
                      fontSize: 13, // 🔥 稍微减小字体
                      fontWeight: FontWeight.w500, // 🔥 正常字重
                      color: AppTheme.primaryColor, // 🔥 玫红色
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              
              // 🔥 二维码按钮（左对齐，群组名称后20px）
              if (currentGroup != null) ...[
                const SizedBox(width: 16), // 🔥 减少间距到16px
                GestureDetector(
                  onTap: () => _showQrGenerate(context, currentGroup),
                  child: Container(
                    padding: const EdgeInsets.all(4), // 🔥 缩小padding从8到4
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1), // 🔥 背景色使其更明显
                      borderRadius: BorderRadius.circular(4), // 🔥 减小圆角
                    ),
                    child: Icon(
                      Icons.qr_code,
                      size: 16, // 🔥 减小图标尺寸从20到16
                      color: AppTheme.primaryColor, // 🔥 玫红色
                    ),
                  ),
              ),
            ],
              
              // 🔥 右对齐区域
              const Spacer(),
              
              // 🔥 连接状态显示在标题栏右侧，包含在线设备数
              Transform.scale(
                scale: 0.75, // 🔥 进一步缩小到75%
                child: const ConnectionStatusWidget(showDeviceCount: true),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildMobileBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.textSecondaryColor,
      elevation: 8,
      selectedFontSize: 10, // 减小选中字体
      unselectedFontSize: 9, // 减小未选中字体
      iconSize: 20, // 减小图标尺寸
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.chat), // 简化图标
          label: '聊天',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notes), // 简化图标
          label: '记忆',
        ),
      ],
    );
          }

  // 🔥 优化：桌面端主内容区
  Widget _buildDesktopMainContent() {
    switch (_selectedIndex) {
      case 0:
        return const MessagesTab();
      case 1:
        return const MemoriesTab();
      default:
        return const MessagesTab();
        }
  }

  // 🔥 桌面端底部操作区
  Widget _buildDesktopSidebarFooter() {
        return Container(
      padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppTheme.dividerColor,
            width: 0.5,
          ),
        ),
          ),
      child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // 退出登录按钮
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                LogoutDialog.showLogoutConfirmDialog(context);
              },
              icon: Icon(
                Icons.logout,
                size: 14,
                color: Colors.red.shade600,
              ),
              label: Text(
                '退出登录',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 版权信息
              Text(
            '© 2024 Send To Myself',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondaryColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
  }

  // 🔥 群组操作方法
  void _showCreateGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建新群组'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '群组名称',
                hintText: '请输入群组名称',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '群组描述（可选）',
                hintText: '请输入群组描述',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入群组名称')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              final groupProvider = Provider.of<GroupProvider>(context, listen: false);
              final success = await groupProvider.createGroup(
                name,
                description: descriptionController.text.trim(),
              );
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('群组"$name"创建成功')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(groupProvider.error ?? '创建群组失败')),
                );
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
  
  void _showJoinGroupOptions(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const JoinGroupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
  
  void _showQrGenerate(BuildContext context, Map<String, dynamic> group) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const QrGenerateScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
  
  void _showGroupManagement(BuildContext context, Map<String, dynamic>? currentGroup) {
    if (currentGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一个群组')),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupManagementScreen(group: currentGroup),
      ),
    );
  }
} 