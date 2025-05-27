import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/logout_dialog.dart';
import '../widgets/group_selector.dart';
import 'messages_tab.dart';
import 'memories_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // 监听群组变化，确保页面切换时整个应用状态刷新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      groupProvider.addListener(_onGroupChanged);
    });
  }

  @override
  void dispose() {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    groupProvider.removeListener(_onGroupChanged);
    _pageController.dispose();
    super.dispose();
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

  // 桌面端布局
  Widget _buildDesktopLayout(String deviceName) {
    return Row(
      children: [
        // 左侧边栏
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
              // 侧边栏顶部
              _buildDesktopSidebarHeader(deviceName),
              
              // 导航项
              _buildDesktopNavigation(),
              
              // 群组选择器
              Padding(
                padding: const EdgeInsets.all(16),
                child: GroupSelector(),
              ),
              
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

  // 移动端布局（原来的布局）
  Widget _buildMobileLayout(String deviceName) {
    return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // 现代化顶部栏
                _buildModernAppBar(deviceName),
                
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

  // 桌面端侧边栏头部
  Widget _buildDesktopSidebarHeader(String deviceName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
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
            ),
            child: const Icon(
              Icons.send_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send To Myself',
                  style: AppTheme.titleStyle,
                ),
                Text(
                  deviceName,
                  style: AppTheme.captionStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 桌面端导航
  Widget _buildDesktopNavigation() {
    return Column(
      children: [
        _buildDesktopNavItem(
          icon: Icons.chat_bubble_rounded,
          label: '聊天',
          index: 0,
        ),
        _buildDesktopNavItem(
          icon: Icons.psychology_rounded,
          label: '记忆',
          index: 1,
        ),
      ],
    );
  }

  Widget _buildDesktopNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected 
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
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
                const SizedBox(width: 10),
                Text(
                  label,
                  style: AppTheme.bodyStyle.copyWith(
                    fontWeight: isSelected ? AppTheme.fontWeightMedium : AppTheme.fontWeightNormal,
                    color: isSelected 
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 桌面端侧边栏底部
  Widget _buildDesktopSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 在线状态指示器
          Expanded(child: _buildOnlineIndicator()),
          
          const SizedBox(width: 8),
          
          // 退出登录按钮
          _buildIconButton(
            icon: Icons.logout_rounded,
            onTap: _showLogoutDialog,
          ),
        ],
      ),
    );
  }

  // 桌面端主内容区
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

  Widget _buildModernAppBar(String deviceName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 群组选择器
          Expanded(
            child: GroupSelector(),
          ),
          
          // 右侧按钮组
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 在线状态指示器
              _buildOnlineIndicator(),
              
              const SizedBox(width: 8),
              
              // 退出登录按钮
              _buildIconButton(
                icon: Icons.logout_rounded,
                onTap: _showLogoutDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineIndicator() {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        final currentGroup = groupProvider.currentGroup;
        
        if (currentGroup == null) {
          return const SizedBox.shrink(); // 没有群组时不显示
        }
        
        final devices = List<Map<String, dynamic>>.from(currentGroup['devices'] ?? []);
        final totalCount = devices.length;
        
        // 计算在线设备数
        int onlineCount = 0;
        for (var device in devices) {
          // 检查设备在线状态，根据日志分析使用正确的字段
          final isOnline = device['is_online'] == true || device['isOnline'] == true;
          final isLoggedOut = device['is_logged_out'] == true || device['isLoggedOut'] == true;
          
          if (!isLoggedOut && isOnline) {
            onlineCount++;
          }
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.onlineColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: onlineCount > 0 ? AppTheme.onlineColor : AppTheme.offlineColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$onlineCount/$totalCount在线',
                style: AppTheme.smallStyle.copyWith(
                  color: onlineCount > 0 ? AppTheme.onlineColor : AppTheme.offlineColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }
} 