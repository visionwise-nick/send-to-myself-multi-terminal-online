// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '发给我自己';

  @override
  String get appDescription => '跨设备文件共享和消息记忆助手';

  @override
  String get commonSection => '';

  @override
  String get navigation => '导航';

  @override
  String get chat => '聊天';

  @override
  String get memory => '记忆';

  @override
  String get noGroupsMessage => '暂无群组';

  @override
  String get noGroupsHint => '点击上方按钮创建或加入群组';

  @override
  String get confirm => '确认';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get save => '保存';

  @override
  String get back => '返回';

  @override
  String get next => '下一步';

  @override
  String get done => '完成';

  @override
  String get retry => '重试';

  @override
  String get refresh => '刷新';

  @override
  String get loading => '加载中...';

  @override
  String get error => '错误';

  @override
  String get success => '成功';

  @override
  String get warning => '警告';

  @override
  String get info => '信息';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get ok => '确定';

  @override
  String get close => '关闭';

  @override
  String get open => '打开';

  @override
  String get share => '分享';

  @override
  String get copy => '复制';

  @override
  String get paste => '粘贴';

  @override
  String get cut => '剪切';

  @override
  String get selectAll => '全选';

  @override
  String get search => '搜索';

  @override
  String get filter => '筛选';

  @override
  String get sort => '排序';

  @override
  String get settings => '设置';

  @override
  String get help => '帮助';

  @override
  String get about => '关于';

  @override
  String get version => '版本 1.0.0';

  @override
  String get update => '更新';

  @override
  String get download => '下载';

  @override
  String get upload => '上传';

  @override
  String get send => '发送';

  @override
  String get receive => '接收';

  @override
  String get connect => '连接';

  @override
  String get disconnect => '断开';

  @override
  String get online => '在线';

  @override
  String get offline => '离线';

  @override
  String get connecting => '连接中';

  @override
  String get connected => '已连接';

  @override
  String get disconnected => '已断开';

  @override
  String get retry_connection => '重试连接';

  @override
  String get authSection => '';

  @override
  String get login => '登录';

  @override
  String get register => '注册';

  @override
  String get logout => '退出';

  @override
  String get loginTitle => '欢迎回来';

  @override
  String get loginSubtitle => '登录以继续';

  @override
  String get registerTitle => '创建账户';

  @override
  String get registerSubtitle => '注册开始使用';

  @override
  String get registerDevice => '注册设备';

  @override
  String get registering => '注册中...';

  @override
  String get deviceRegistration => '设备注册';

  @override
  String get deviceRegistrationSuccess => '设备注册成功';

  @override
  String get deviceRegistrationFailed => '设备注册失败';

  @override
  String get loginSuccess => '登录成功';

  @override
  String get loginFailed => '登录失败';

  @override
  String get logoutSuccess => '退出成功';

  @override
  String get logoutConfirm => '确定要退出吗？';

  @override
  String get navigationSection => '';

  @override
  String get home => '首页';

  @override
  String get messages => '消息';

  @override
  String get files => '文件';

  @override
  String get memories => '记忆';

  @override
  String get groups => '群组';

  @override
  String get sectionmessages => '';

  @override
  String get newMessage => '新消息';

  @override
  String get onlyMyself => '仅有自己';

  @override
  String devicesCount(int count) {
    return '$count台设备';
  }

  @override
  String get clickToStartGroupChat => '点击开始群聊';

  @override
  String get sendToMyself => '给自己发消息';

  @override
  String get clickToStartChat => '点击开始聊天';

  @override
  String get unknownDevice => '未知设备';

  @override
  String get unknownType => '未知类型';

  @override
  String get myself => '我';

  @override
  String get noConversations => '暂无对话';

  @override
  String get joinGroupToStartChat => '加入设备群组后即可开始聊天';

  @override
  String get pleaseSelectGroup => '请选择群组';

  @override
  String get clickGroupSelectorHint => '点击顶部群组选择器来选择或创建群组';

  @override
  String get sendMessage => '发送消息';

  @override
  String get messageHint => '输入您的消息...';

  @override
  String get noMessages => '暂无消息';

  @override
  String get messagesSent => '已发送消息';

  @override
  String get messagesReceived => '已接收消息';

  @override
  String get messageDelivered => '已送达';

  @override
  String get messageFailed => '发送失败';

  @override
  String get messagePending => '等待中';

  @override
  String get copyMessage => '复制消息';

  @override
  String get deleteMessage => '删除消息';

  @override
  String get replyMessage => '回复';

  @override
  String get forwardMessage => '转发';

  @override
  String get selectMessages => '选择消息';

  @override
  String selectedMessages(int count) {
    return '已选择 $count 条';
  }

  @override
  String get deleteSelectedMessages => '删除选中消息';

  @override
  String get deleteMessageConfirm => '确定要删除此消息吗？';

  @override
  String deleteMessagesConfirm(int count) {
    return '确定要删除 $count 条消息吗？';
  }

  @override
  String get sectionfiles => '';

  @override
  String get selectFile => '选择文件';

  @override
  String get selectFiles => '选择文件';

  @override
  String get selectImage => '选择图片';

  @override
  String get selectVideo => '选择视频';

  @override
  String get selectDocument => '选择文档';

  @override
  String get noFiles => '暂无文件';

  @override
  String get fileName => '文件名';

  @override
  String get fileSize => '文件大小';

  @override
  String get fileType => '文件类型';

  @override
  String get fileDate => '日期';

  @override
  String get uploadFile => '上传文件';

  @override
  String get downloadFile => '下载文件';

  @override
  String get openFile => '打开文件';

  @override
  String get shareFile => '分享文件';

  @override
  String get deleteFile => '删除文件';

  @override
  String uploadProgress(int progress) {
    return '上传中... $progress%';
  }

  @override
  String downloadProgress(int progress) {
    return '下载中... $progress%';
  }

  @override
  String get uploadSuccess => '上传成功';

  @override
  String get downloadSuccess => '下载成功';

  @override
  String get uploadFailed => '上传失败';

  @override
  String get downloadFailed => '下载失败';

  @override
  String get fileTooLarge => '文件过大';

  @override
  String get unsupportedFileType => '不支持的文件类型';

  @override
  String get saveToGallery => '保存到相册';

  @override
  String get saveToLocal => '保存到本地';

  @override
  String get openFileLocation => '打开文件位置';

  @override
  String get sectionmemories => '';

  @override
  String get createMemory => '创建记忆';

  @override
  String get editMemory => '编辑记忆';

  @override
  String get deleteMemory => '删除记忆';

  @override
  String get memoryTitle => '标题';

  @override
  String get memoryContent => '内容';

  @override
  String get memoryCategory => '分类';

  @override
  String get memoryTags => '标签';

  @override
  String get memoryDate => '日期';

  @override
  String get memoryLocation => '位置';

  @override
  String get memoryPriority => '优先级';

  @override
  String get memoryStatus => '状态';

  @override
  String get noMemories => '暂无记忆';

  @override
  String get searchMemories => '搜索记忆内容、标签...';

  @override
  String get filterByCategory => '按分类筛选';

  @override
  String get sortByDate => '按日期排序';

  @override
  String get sortByPriority => '按优先级排序';

  @override
  String get memoryCategories => '分类';

  @override
  String get personalMemory => '个人';

  @override
  String get workMemory => '工作';

  @override
  String get lifeMemory => '生活';

  @override
  String get studyMemory => '学习';

  @override
  String get travelMemory => '旅行';

  @override
  String get otherMemory => '其他';

  @override
  String get memoryPriorityHigh => '高';

  @override
  String get memoryPriorityMedium => '中';

  @override
  String get memoryPriorityLow => '低';

  @override
  String get memoryStatusActive => '活跃';

  @override
  String get memoryStatusCompleted => '已完成';

  @override
  String get memoryStatusArchived => '已归档';

  @override
  String get sectiongroups => '';

  @override
  String get createGroup => '创建群组';

  @override
  String get joinGroup => '加入群组';

  @override
  String get leaveGroup => '离开群组';

  @override
  String get deleteGroup => '删除群组';

  @override
  String get groupName => '群组名称';

  @override
  String get groupNameHint => '请输入群组名称';

  @override
  String get groupDescription => '群组描述';

  @override
  String get groupDescriptionHint => '请输入群组描述';

  @override
  String get groupDescriptionOptional => '群组描述（可选）';

  @override
  String get groupMembers => '成员';

  @override
  String get groupSettings => '群组设置';

  @override
  String get noGroups => '暂无群组';

  @override
  String get groupCode => '群组代码';

  @override
  String get scanQRCode => '扫描二维码';

  @override
  String get generateQRCode => '生成二维码';

  @override
  String get joinGroupByCode => '通过代码加入';

  @override
  String get joinGroupByQR => '通过二维码加入';

  @override
  String get groupJoinSuccess => '成功加入群组';

  @override
  String get groupJoinFailed => '加入群组失败';

  @override
  String get groupLeaveSuccess => '成功离开群组';

  @override
  String get groupLeaveFailed => '离开群组失败';

  @override
  String get groupLeaveConfirm => '确定要离开此群组吗？';

  @override
  String get groupDeleteConfirm => '确定要删除此群组吗？';

  @override
  String get groupCreated => '群组创建成功';

  @override
  String get groupCreateFailed => '群组创建失败';

  @override
  String get invalidGroupCode => '无效的群组代码';

  @override
  String get groupNotFound => '未找到群组';

  @override
  String get alreadyInGroup => '已在此群组中';

  @override
  String get groupFull => '群组已满';

  @override
  String get renameGroup => '重命名群组';

  @override
  String get newGroupName => '新群组名称';

  @override
  String get enterNewGroupName => '请输入新的群组名称';

  @override
  String get renamingGroup => '正在重命名群组...';

  @override
  String get groupRenameSuccess => '群组重命名成功';

  @override
  String get groupRenameFailed => '群组重命名失败';

  @override
  String get renameFailed => '重命名失败';

  @override
  String get loadGroupInfoFailed => '加载群组信息失败';

  @override
  String get groupManagement => '群组管理';

  @override
  String get membersList => '成员列表';

  @override
  String get groupInfo => '群组信息';

  @override
  String get sectiondevices => '';

  @override
  String get deviceName => '设备名称';

  @override
  String get deviceType => '设备类型';

  @override
  String get deviceStatus => '状态';

  @override
  String get deviceLastSeen => '最后在线';

  @override
  String get connectedDevices => '已连接设备';

  @override
  String get availableDevices => '可用设备';

  @override
  String get noDevices => '暂无设备';

  @override
  String get connectDevice => '连接设备';

  @override
  String get disconnectDevice => '断开设备';

  @override
  String get removeDevice => '移除设备';

  @override
  String get deviceConnected => '设备已连接';

  @override
  String get deviceDisconnected => '设备已断开';

  @override
  String get deviceRemoved => '设备已移除';

  @override
  String get deviceNotFound => '未找到设备';

  @override
  String get deviceConnectionFailed => '设备连接失败';

  @override
  String get sectionsync => '';

  @override
  String get sync => '同步';

  @override
  String get syncing => '同步中...';

  @override
  String get syncComplete => '同步完成';

  @override
  String get syncFailed => '同步失败';

  @override
  String get autoSync => '自动同步';

  @override
  String get syncNow => '立即同步';

  @override
  String get lastSync => '上次同步';

  @override
  String get syncSettings => '同步设置';

  @override
  String get syncMessages => '同步消息';

  @override
  String get syncFiles => '同步文件';

  @override
  String get syncMemories => '同步记忆';

  @override
  String get offlineMode => '离线模式';

  @override
  String get onlineMode => '在线模式';

  @override
  String get sectionqr => '';

  @override
  String get qrCodeTitle => '二维码';

  @override
  String get scanQR => '扫描二维码';

  @override
  String get generateQR => '生成二维码';

  @override
  String get qrCodeGenerated => '二维码已生成';

  @override
  String get qrCodeScanned => '二维码已扫描';

  @override
  String get qrScanFailed => '二维码扫描失败';

  @override
  String get invalidQRCode => '无效的二维码';

  @override
  String get qrPermissionDenied => '相机权限被拒绝';

  @override
  String get qrCameraError => '相机错误';

  @override
  String get manualInput => '手动输入';

  @override
  String get flashlight => '闪光灯';

  @override
  String get enterJoinCode => '输入加入码';

  @override
  String get joinCodeHint => '8位加入码';

  @override
  String get joinGroupSuccess => '成功加入群组！';

  @override
  String get joinGroupFailed => '加入群组失败';

  @override
  String get joinFailed => '加入失败';

  @override
  String get joiningGroup => '正在加入群组...';

  @override
  String get placeQRInFrame => '将二维码置于框内进行扫描';

  @override
  String get deviceJoinCode => '设备加入码';

  @override
  String get regenerate => '重新生成';

  @override
  String get generatingJoinCode => '正在生成加入码...';

  @override
  String get generateFailed => '生成失败';

  @override
  String get noGroupInfo => '没有可用的群组信息';

  @override
  String get join => '加入';

  @override
  String get sectionnetwork => '';

  @override
  String get networkStatus => '网络状态';

  @override
  String get networkConnected => '已连接';

  @override
  String get networkDisconnected => '已断开';

  @override
  String get networkError => '网络错误';

  @override
  String get connectionTimeout => '连接超时';

  @override
  String get serverError => '服务器错误';

  @override
  String get clientError => '客户端错误';

  @override
  String get networkDebug => '网络调试';

  @override
  String get checkConnection => '检查连接';

  @override
  String get reconnecting => '重新连接中...';

  @override
  String get reconnected => '已重新连接';

  @override
  String get connectionLost => '连接丢失';

  @override
  String get sectionnotifications => '';

  @override
  String get notifications => '通知';

  @override
  String get enableNotifications => '启用通知';

  @override
  String get disableNotifications => '禁用通知';

  @override
  String get notificationSettings => '通知设置';

  @override
  String get newMessageNotification => '新消息';

  @override
  String get fileUploadNotification => '文件上传完成';

  @override
  String get fileDownloadNotification => '文件下载完成';

  @override
  String get syncCompleteNotification => '同步完成';

  @override
  String get deviceConnectedNotification => '设备已连接';

  @override
  String get deviceDisconnectedNotification => '设备已断开';

  @override
  String get sectiontime => '';

  @override
  String get now => '现在';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get thisWeek => '本周';

  @override
  String get lastWeek => '上周';

  @override
  String get thisMonth => '本月';

  @override
  String get lastMonth => '上月';

  @override
  String minutesAgo(int minutes) {
    return '$minutes分钟前';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours小时前';
  }

  @override
  String daysAgo(int days) {
    return '$days天前';
  }

  @override
  String get sectionerrors => '';

  @override
  String get errorGeneral => '发生错误';

  @override
  String get errorNetwork => '网络错误';

  @override
  String get errorTimeout => '请求超时';

  @override
  String get errorServerUnavailable => '服务器不可用';

  @override
  String get errorUnauthorized => '未授权访问';

  @override
  String get errorForbidden => '访问被禁止';

  @override
  String get errorNotFound => '资源未找到';

  @override
  String get errorInternalServer => '内部服务器错误';

  @override
  String get errorBadRequest => '错误请求';

  @override
  String get errorTooManyRequests => '请求过多';

  @override
  String get errorServiceUnavailable => '服务不可用';

  @override
  String get errorUnknown => '未知错误';

  @override
  String get errorRetry => '请重试';

  @override
  String get sectionfile_sizes => '';

  @override
  String get bytes => 'B';

  @override
  String get kilobytes => 'KB';

  @override
  String get megabytes => 'MB';

  @override
  String get gigabytes => 'GB';

  @override
  String get terabytes => 'TB';

  @override
  String get sectionpermissions => '';

  @override
  String get permissionRequired => '需要权限';

  @override
  String get permissionDenied => '权限被拒绝';

  @override
  String get permissionCamera => '需要相机权限';

  @override
  String get permissionStorage => '需要存储权限';

  @override
  String get permissionNotification => '需要通知权限';

  @override
  String get permissionLocation => '需要位置权限';

  @override
  String get grantPermission => '授予权限';

  @override
  String get openSettings => '打开设置';

  @override
  String get sectionsettings => '';

  @override
  String get deviceInfo => '设备信息';

  @override
  String get deviceId => '设备ID';

  @override
  String get platform => '平台';

  @override
  String get unknown => '未知';

  @override
  String get appTheme => '应用主题';

  @override
  String get defaultTheme => '默认';

  @override
  String get enabled => '开启';

  @override
  String get aboutApp => '关于应用';

  @override
  String get comingSoon => '敬请期待';

  @override
  String get featureComingSoon => '该功能即将上线，敬请期待！';

  @override
  String get logoutConfirmTitle => '退出登录';

  @override
  String get logoutConfirmMessage => '确定要退出当前设备的登录状态吗？';

  @override
  String get sectionmemory => '';

  @override
  String memoriesCount(int count) {
    return '已收藏 $count 条记忆';
  }

  @override
  String get noMemoriesDesc => '开始创建你的第一条记忆吧';

  @override
  String get viewMemory => '查看记忆';

  @override
  String get quickAdd => '快速添加';

  @override
  String get addMemoryFromText => '从文本添加';

  @override
  String get addMemoryFromImage => '从图片添加';

  @override
  String get addMemoryFromFile => '从文件添加';

  @override
  String get sectionjoingroup => '';

  @override
  String get scanMode => '扫描模式';

  @override
  String get inputMode => '输入模式';

  @override
  String get cameraInitFailed => '摄像头初始化失败';

  @override
  String get cameraNotAvailable => '摄像头不可用，已切换到手动输入模式';

  @override
  String get desktopCameraTip => '桌面端建议使用手动输入模式，摄像头扫描可能不稳定';

  @override
  String get enterGroupCode => '输入群组代码';

  @override
  String get groupCodePlaceholder => '请输入8位群组代码';

  @override
  String get invalidCode => '无效代码';

  @override
  String get codeRequired => '请输入代码';

  @override
  String get processing => '处理中...';

  @override
  String get switchToScan => '切换到扫描模式';

  @override
  String get switchToInput => '切换到输入模式';

  @override
  String get sectionnetworkdebug => '';

  @override
  String get networkDiagnosticTool => '网络诊断工具';

  @override
  String get clearLogs => '清除日志';

  @override
  String get copyLogs => '复制日志';

  @override
  String get connectionStatus => '连接状态';

  @override
  String get connectionDetails => '连接详情';

  @override
  String get networkTest => '网络检测';

  @override
  String get testWebSocket => '测试WebSocket';

  @override
  String get forceReconnect => '强制重连';

  @override
  String get pingTest => 'Ping测试';

  @override
  String get diagnosticLogs => '诊断日志';

  @override
  String recordsCount(int count) {
    return '$count 条记录';
  }

  @override
  String get startingNetworkDiagnostic => '开始网络诊断测试...';

  @override
  String get testingBasicConnectivity => '测试基本网络连接...';

  @override
  String get testingDnsResolution => '测试DNS解析...';

  @override
  String get testingServerConnectivity => '测试服务器连通性...';

  @override
  String get networkDiagnosticComplete => '网络诊断测试完成';

  @override
  String get testingConnection => '测试连接';

  @override
  String get connectionSuccessful => '连接成功';

  @override
  String get connectionFailed => '连接失败';

  @override
  String get connectionStatusChanged => '连接状态变化';

  @override
  String get networkStatusChanged => '网络状态变化';

  @override
  String get errorOccurred => '错误';

  @override
  String get messageReceived => '收到消息';

  @override
  String get sectionsplash => '';

  @override
  String get appSlogan => '跨设备文件共享和同步';
}
