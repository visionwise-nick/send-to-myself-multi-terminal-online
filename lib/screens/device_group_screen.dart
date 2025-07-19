import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/localization_helper.dart';

class DeviceGroupScreen extends StatefulWidget {
  final String groupId;

  const DeviceGroupScreen({super.key, required this.groupId});

  @override
  State<DeviceGroupScreen> createState() => _DeviceGroupScreenState();
}

class _DeviceGroupScreenState extends State<DeviceGroupScreen> {
  bool _isLoading = false;
  bool _isQrCodeLoading = false;
  Map<String, dynamic>? _joinCodeData;
  List<dynamic>? _devices;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  // 加载群组设备列表
  Future<void> _loadDevices() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final devices = await authProvider.getGroupDevices(widget.groupId);
      
      if (mounted) {
        setState(() {
          _devices = devices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationHelper.of(context).loadDevicesFailed)),
        );
      }
    }
  }

  // 创建群组加入码
  Future<void> _createJoinCode() async {
    if (mounted) {
      setState(() {
        _isQrCodeLoading = true;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.createJoinCode(widget.groupId);
      
      if (mounted) {
        setState(() {
          _joinCodeData = result;
          _isQrCodeLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isQrCodeLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationHelper.of(context).createJoinCodeFailed)),
        );
      }
    }
  }

  // 离开群组
  Future<void> _leaveGroup() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.leaveGroup(widget.groupId);
      
      if (result && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationHelper.of(context).leaveGroupSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationHelper.of(context).leaveGroupFailed)),
        );
      }
    }
  }

  // 刷新群组信息
  Future<void> _refreshGroup() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshProfile();
      
      _loadDevices();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationHelper.of(context).groupInfoUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationHelper.of(context).refreshFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = AppTheme.isSmallScreen(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final groups = authProvider.groups;
    
    // 查找当前群组
    final currentGroup = groups?.firstWhere(
      (group) => group['id'] == widget.groupId,
      orElse: () => null,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: Text(currentGroup?['name'] ?? LocalizationHelper.of(context).deviceGroup),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: LocalizationHelper.of(context).refresh,
            onPressed: _refreshGroup,
          ),
          // 菜单按钮
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'leave') {
                _showLeaveGroupDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text(LocalizationHelper.of(context).leaveGroup, style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: EdgeInsets.all(AppTheme.getPadding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 群组信息卡片
                  if (currentGroup != null)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.devices,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentGroup['name'] ?? LocalizationHelper.of(context).unnamedGroup,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        LocalizationHelper.of(context).createdOn(_formatDate(currentGroup['createdAt'])),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    LocalizationHelper.of(context).deviceCount(_devices?.length ?? 0),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // 生成加入码按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isQrCodeLoading ? null : _createJoinCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code),
                      label: _isQrCodeLoading
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(LocalizationHelper.of(context).generating),
                              ],
                            )
                          : Text(LocalizationHelper.of(context).generateDeviceJoinCode),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 加入二维码显示
                  if (_joinCodeData != null)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              LocalizationHelper.of(context).scanQRToJoinDeviceGroup,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // 二维码
                            if (_joinCodeData?['qrCodeDataURL'] != null)
                              Image.network(
                                _joinCodeData!['qrCodeDataURL'],
                                width: 200,
                                height: 200,
                              )
                            else if (_joinCodeData?['code'] != null)
                              QrImageView(
                                data: _joinCodeData!['code'],
                                version: QrVersions.auto,
                                size: 200,
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                embeddedImage: const AssetImage('assets/app_icon.png'),
                                embeddedImageStyle: const QrEmbeddedImageStyle(
                                  size: Size(40, 40),
                                ),
                              ),
                            const SizedBox(height: 16),
                            // 加入码
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${LocalizationHelper.of(context).joinCode}: ${_joinCodeData!['code']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  tooltip: LocalizationHelper.of(context).copyJoinCode,
                                  onPressed: () {
                                    // 复制到剪贴板
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(LocalizationHelper.of(context).joinCodeCopied)),
                                    );
                                  },
                                ),
                              ],
                            ),
                            // 过期时间
                            Text(
                              LocalizationHelper.of(context).expiresAt(_formatDateTime(_joinCodeData!['expiresAt'])),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // 设备列表标题
                  Row(
                    children: [
                      Text(
                        LocalizationHelper.of(context).deviceList,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          LocalizationHelper.of(context).deviceCount(_devices?.length ?? 0),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 设备列表
                  Expanded(
                    child: _devices == null || _devices!.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.devices_other,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  LocalizationHelper.of(context).noDevicesToDisplay,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _devices!.length,
                            itemBuilder: (context, index) {
                              final device = _devices![index];
                              final isCurrentDevice = device['isCurrentDevice'] == true;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isCurrentDevice
                                          ? AppTheme.primaryColor.withOpacity(0.1)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _getDeviceIcon(device['type']),
                                        color: isCurrentDevice
                                            ? AppTheme.primaryColor
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          device['name'] ?? LocalizationHelper.of(context).unnamedDevice,
                                          style: TextStyle(
                                            fontWeight: isCurrentDevice
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isCurrentDevice)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            LocalizationHelper.of(context).currentDevice,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      if (device['isOwner'] == true)
                                        Container(
                                          margin: const EdgeInsets.only(left: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            LocalizationHelper.of(context).groupOwner,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    '${device['type'] ?? LocalizationHelper.of(context).unknownDevice} · ${device['platform'] ?? LocalizationHelper.of(context).unknownPlatform}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: device['isCurrentDevice'] != true && device['canRemove'] == true
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Colors.red,
                                          ),
                                          tooltip: LocalizationHelper.of(context).removeDevice,
                                          onPressed: () {
                                            _showRemoveDeviceDialog(device);
                                          },
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  // 显示离开群组确认对话框
  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationHelper.of(context).leaveGroup),
        content: Text(LocalizationHelper.of(context).confirmLeaveGroup),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(LocalizationHelper.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _leaveGroup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(LocalizationHelper.of(context).confirm),
          ),
        ],
      ),
    );
  }

  // 显示移除设备确认对话框
  void _showRemoveDeviceDialog(Map<String, dynamic> device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationHelper.of(context).removeDevice),
        content: Text('${LocalizationHelper.of(context).confirmRemoveDevice} "${device['name']}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(LocalizationHelper.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 移除设备的逻辑（本次未实现）
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(LocalizationHelper.of(context).removeDeviceFeatureComingSoon)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(LocalizationHelper.of(context).confirm),
          ),
        ],
      ),
    );
  }

  // 根据设备类型获取图标
  IconData _getDeviceIcon(String? type) {
    if (type == null) return Icons.devices;
    
    switch (type.toLowerCase()) {
      case 'iphone':
        return Icons.phone_iphone;
      case 'ipad':
        return Icons.tablet_mac;
      case 'android':
        return Icons.phone_android;
      case 'mac电脑':
        return Icons.laptop_mac;
      case 'windows电脑':
        return Icons.laptop_windows;
      case 'linux电脑':
        return Icons.computer;
      case 'web浏览器':
        return Icons.web;
      default:
        return Icons.devices;
    }
  }

  // 格式化日期
  String _formatDate(dynamic date) {
    if (date == null) return LocalizationHelper.of(context).unknown;
    
    try {
      if (date is String) {
        // 解析时间并转换为本地时间
        DateTime dateTime = DateTime.parse(date);
        if (!date.contains('Z') && !date.contains('+')) {
          // 如果没有时区信息，假设是UTC时间
          dateTime = DateTime.parse(date + 'Z');
        }
        final localTime = dateTime.toLocal();
        return '${localTime.year}-${localTime.month.toString().padLeft(2, '0')}-${localTime.day.toString().padLeft(2, '0')}';
      }
      
      return date.toString();
    } catch (e) {
      print('解析日期失败: $e, 原始日期: $date');
      return LocalizationHelper.of(context).unknown;
    }
  }

  // 格式化日期时间
  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return LocalizationHelper.of(context).unknown;
    
    try {
      if (dateTime is String) {
        // 解析时间并转换为本地时间
        DateTime dt = DateTime.parse(dateTime);
        if (!dateTime.contains('Z') && !dateTime.contains('+')) {
          dt = DateTime.parse(dateTime + 'Z');
        }
        final localTime = dt.toLocal();
        return '${localTime.year}-${localTime.month.toString().padLeft(2, '0')}-${localTime.day.toString().padLeft(2, '0')} ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
      }
      
      return dateTime.toString();
    } catch (e) {
      print('解析日期时间失败: $e, 原始时间: $dateTime');
      return LocalizationHelper.of(context).unknown;
    }
  }
} 