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
  String get disconnected => '未连接';

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
  String get pleaseSelectGroup => '请先选择一个群组';

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
  String get fileTooLarge => '文件太大无法发送';

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
  String get searchMemories => '搜索记忆...';

  @override
  String get filterByCategory => '按分类筛选';

  @override
  String get sortByDate => '按日期排序';

  @override
  String get sortByPriority => '按优先级排序';

  @override
  String get memoryCategories => '记忆分类';

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
  String get groupDescription => '群组描述（可选）';

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
  String get reconnecting => '重连中';

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
  String get cameraUnavailable => '摄像头不可用';

  @override
  String get checkCameraPermissions => '请检查摄像头权限设置';

  @override
  String get desktopInputModeRecommended => '桌面端建议使用下方的\"输入邀请码\"模式';

  @override
  String get cameraStartupFailed => '摄像头启动失败';

  @override
  String get startingCamera => '正在启动摄像头...';

  @override
  String get placeQRInScanFrame => '将二维码置于扫描框内';

  @override
  String get switchToInputModeOrCheckPermissions => '请切换到输入模式或检查摄像头权限';

  @override
  String get enterInviteCodeHint => '请输入群组邀请码（4-20位）';

  @override
  String get inviteCodePlaceholder => '邀请码';

  @override
  String get clickToJoinGroup => '点击加入群组';

  @override
  String get selectGroup => '选择群组';

  @override
  String get createGroupFailed => '创建群组失败';

  @override
  String get pleaseEnterGroupName => '请输入群组名称';

  @override
  String groupCreatedSuccessfully(Object name) {
    return 'Group \"$name\" created successfully';
  }

  @override
  String get title => '标题';

  @override
  String get content => '内容';

  @override
  String get writeYourThoughts => '写下你的想法...';

  @override
  String get enterNoteTitle => '输入笔记标题';

  @override
  String get websiteAppName => '网站/应用名称';

  @override
  String get websiteAppNameHint => '如：微信、淘宝';

  @override
  String get websiteAddress => '网站地址';

  @override
  String get websiteAddressHint => 'https://...';

  @override
  String get usernameEmail => '用户名/邮箱';

  @override
  String get loginAccount => '登录账号';

  @override
  String get password => '密码';

  @override
  String get loginPassword => '登录密码';

  @override
  String get sectionchat => '';

  @override
  String get sendFailed => '发送失败';

  @override
  String get maxAllowed => '最大允许';

  @override
  String get selectFileFailed => '选择文件失败';

  @override
  String get pasteFailed => '粘贴失败';

  @override
  String get fileProcessingFailed => '文件处理失败';

  @override
  String sharedTextMessages(Object count) {
    return '已分享$count条文本消息';
  }

  @override
  String sharedFiles(Object count) {
    return '已分享$count个文件';
  }

  @override
  String batchShareFailed(String error) {
    return '批量分享失败: $error';
  }

  @override
  String copiedMessages(Object count) {
    return '已复制$count条消息到剪贴板';
  }

  @override
  String messagesAddedToInput(Object count) {
    return '$count条消息内容已添加到输入框';
  }

  @override
  String favoriteMessages(Object count, Object total) {
    return '已收藏$count/$total条消息';
  }

  @override
  String recalledMessages(Object count) {
    return '已撤回$count条消息';
  }

  @override
  String get batchRecallFailed => '批量撤回失败';

  @override
  String deletedMessages(Object count) {
    return '已删除$count条消息';
  }

  @override
  String get batchDeleteFailed => '批量删除失败';

  @override
  String get debugInfo => '调试信息';

  @override
  String get permanentStorageDir => '永久存储目录';

  @override
  String get storageUsage => '存储使用情况:';

  @override
  String get chatData => '聊天数据';

  @override
  String get memoryData => '记忆数据';

  @override
  String get userData => '用户数据';

  @override
  String get fileCache => '文件缓存';

  @override
  String get total => '总计';

  @override
  String get fileCacheStats => '文件缓存统计:';

  @override
  String get totalFiles => '总文件数';

  @override
  String get validFiles => '有效文件';

  @override
  String get invalidFiles => '无效文件';

  @override
  String get deduplicationDiagnostics => '去重诊断:';

  @override
  String get processedMessageIds => '已处理消息ID';

  @override
  String get timestampRecords => '时间戳记录';

  @override
  String get uiMessages => '界面消息数';

  @override
  String get websocketConnection => 'WebSocket连接';

  @override
  String get lastMessageReceived => '最后收到消息';

  @override
  String get forceClearDedupRecords => '已强制清理去重记录并重启WebSocket监听';

  @override
  String get clearDedupRecords => '清理去重记录';

  @override
  String get getDebugInfoFailed => '获取调试信息失败';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get textCopiedToClipboard => '文字已复制到剪贴板';

  @override
  String get canDragSelectText => '可以直接拖拽选择文字内容';

  @override
  String get allContentCopied => '全部内容已复制到剪贴板';

  @override
  String get messageRecalled => '消息已撤回';

  @override
  String get recallFailed => '撤回失败';

  @override
  String get messageDeleted => '消息已删除';

  @override
  String get deleteFailed => '删除失败';

  @override
  String get messageAddedToInput => '消息内容已添加到输入框';

  @override
  String get addedToFavorites => '已添加到收藏';

  @override
  String get favoriteFailed => '收藏失败';

  @override
  String get removedFromFavorites => '已从收藏中移除';

  @override
  String get unfavoriteFailed => '取消收藏失败';

  @override
  String get confirmDeleteMessage => '确定要删除这条消息吗？';

  @override
  String get jumpedToOriginalMessage => '已跳转到原消息';

  @override
  String get originalMessageNotExists => '原消息不存在或已被删除';

  @override
  String get fileInfoIncomplete => '文件信息不完整';

  @override
  String get featureOnlyMobile => '此功能仅在移动端可用';

  @override
  String get fileNotExistsDownloading => '文件不存在，正在下载...';

  @override
  String get fileDownloadFailedCannotSave => '文件下载失败，无法保存';

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
  String get testingBasicConnectivity => '测试基本连接...';

  @override
  String get testingDnsResolution => '测试DNS解析...';

  @override
  String get testingServerConnectivity => '测试服务器连接...';

  @override
  String get networkDiagnosticComplete => '网络诊断测试完成';

  @override
  String get testingConnection => '测试连接';

  @override
  String get connectionSuccessful => '连接成功';

  @override
  String get connectionFailed => '连接失败';

  @override
  String get connectionStatusChanged => '连接状态改变';

  @override
  String get networkStatusChanged => '网络状态改变';

  @override
  String get errorOccurred => '发生错误';

  @override
  String get messageReceived => '收到消息';

  @override
  String get sectionsplash => '';

  @override
  String get appSlogan => '跨设备文件共享和同步';

  @override
  String get myFiles => '我的文件';

  @override
  String get filesFeatureComingSoon => '文件功能即将推出';

  @override
  String get stayTuned => '敬请期待';

  @override
  String get sectiondevicegroups => '';

  @override
  String get noDeviceGroups => '暂无设备群组';

  @override
  String get scanQRToJoin => '使用其他设备扫描二维码加入';

  @override
  String get myDeviceGroups => '我的设备群组';

  @override
  String get unnamedGroup => '未命名群组';

  @override
  String deviceCount(int count) {
    return '$count 台设备';
  }

  @override
  String get youAreOwner => '你是群主';

  @override
  String get member => '成员';

  @override
  String get createdOn => '创建于';

  @override
  String get unknownDate => '未知';

  @override
  String get sectiondebug => '';

  @override
  String get batchDelete => '批量删除';

  @override
  String confirmBatchDelete(int count) {
    return '确定要删除选中的$count条消息吗？删除后无法恢复。';
  }

  @override
  String batchDeleteSuccess(int count) {
    return '已删除$count条消息';
  }

  @override
  String batchDeleteFailedWithError(String error) {
    return '批量删除失败: $error';
  }

  @override
  String get deleteMessageTitle => '删除消息';

  @override
  String get confirmDeleteSingleMessage => '确定要删除这条消息吗？删除后无法恢复。';

  @override
  String deleteFailedWithError(String error) {
    return '删除失败: $error';
  }

  @override
  String recallFailedWithError(String error) {
    return '撤回失败: $error';
  }

  @override
  String get startConversation => '开始对话';

  @override
  String get sendMessageOrFileToStart => '发送消息或文件来开始聊天';

  @override
  String get debugInfoTitle => '调试信息';

  @override
  String get permanentStorageDirectory => '永久存储目录:';

  @override
  String get memoryDeleteTitle => '删除记忆';

  @override
  String confirmDeleteMemory(String title) {
    return '确定要删除\"$title\"吗？删除后无法恢复。';
  }

  @override
  String get deleteMemorySuccess => '删除成功';

  @override
  String get deleteMemoryFailed => '删除失败';

  @override
  String memorySavedWithAI(int count) {
    return '记忆已保存，AI生成了标题和$count个标签';
  }

  @override
  String saveFailedWithError(String error) {
    return '保存失败: $error';
  }

  @override
  String get deleteTooltip => '删除';

  @override
  String get sectionsnackbar => '';

  @override
  String sharedTextMessagesCount(int count) {
    return '已分享$count条文本消息';
  }

  @override
  String sharedFilesAndText(int fileCount, int textCount) {
    return '已分享$fileCount个文件和$textCount条文本';
  }

  @override
  String andTextMessages(int count) {
    return '和$count条文本';
  }

  @override
  String batchShareFailedWithError(String error) {
    return '批量分享失败: $error';
  }

  @override
  String copiedMessagesToClipboard(int count) {
    return '已复制$count条消息到剪贴板';
  }

  @override
  String messagesAddedToInputBox(int count) {
    return '$count条消息内容已添加到输入框';
  }

  @override
  String favoritedMessagesCount(int successCount, int totalCount) {
    return '已收藏$successCount/$totalCount条消息';
  }

  @override
  String recalledMessagesCount(int count) {
    return '已撤回$count条消息';
  }

  @override
  String batchRecallFailedWithError(String error) {
    return '批量撤回失败: $error';
  }

  @override
  String get forceClearedDedupRecords => '已强制清理去重记录并重启WebSocket监听';

  @override
  String getDebugInfoFailedWithError(String error) {
    return '获取调试信息失败: $error';
  }

  @override
  String get textCanBeDragSelected => '可以直接拖拽选择文字内容';

  @override
  String get allContentCopiedToClipboard => '全部内容已复制到剪贴板';

  @override
  String get messageContentAddedToInput => '消息内容已添加到输入框';

  @override
  String get featureOnlyAvailableOnMobile => '此功能仅在移动端可用';

  @override
  String fileDownloadFailedWithError(String error) {
    return '文件下载失败: $error';
  }

  @override
  String get fileUrlNotExistsCannotDownload => '文件URL不存在，无法下载';

  @override
  String get fileLocationOpened => '已打开文件位置';

  @override
  String get filePathCopiedToClipboard => '文件路径已复制到剪贴板';

  @override
  String get fileLinkCopiedToClipboard => '文件链接已复制到剪贴板';

  @override
  String get sectionmisc => '';

  @override
  String get sectionauth => '';

  @override
  String get loggingOut => '正在退出登录...';

  @override
  String get logoutSuccessMessage => '已成功退出登录';

  @override
  String get logoutError => '退出登录时发生错误';

  @override
  String logoutFailedWithError(String error) {
    return '退出登录失败: $error';
  }

  @override
  String get loginStatusInvalid => '登录状态已失效';

  @override
  String get logoutFailedTitle => '退出登录失败';

  @override
  String get logoutFailedContent => '退出登录失败，您可以选择强制退出或重试。';

  @override
  String get forceLogout => '强制退出';

  @override
  String get sectiongroup => '';

  @override
  String get createNewGroup => '创建新群组';

  @override
  String groupCreatedSuccess(String name) {
    return '群组\"$name\"创建成功';
  }

  @override
  String get create => '创建';

  @override
  String get sectionconnection => '';

  @override
  String onlineStatus(int online, int total) {
    return '$online/$total在线';
  }

  @override
  String get networkNormal => '网络正常';

  @override
  String get networkLimited => '网络受限';

  @override
  String get networkUnavailable => '网络不可用';

  @override
  String get checking => '检查中';

  @override
  String get sendFileFailed => '发送文件失败';

  @override
  String get noFilesToSend => '没有要发送的文件';

  @override
  String get batchRecall => '批量撤回';

  @override
  String get recall => '撤回';

  @override
  String get clearDeduplicationRecords => '清除去重记录';

  @override
  String get cancelUpload => '取消上传';

  @override
  String get cancelDownload => '取消下载';

  @override
  String confirmCancelTransfer(String action) {
    return '确定要$action这个文件吗？';
  }

  @override
  String get continueTransfer => '继续传输';

  @override
  String get confirmCancel => '确定取消';

  @override
  String transferCancelled(String action) {
    return '$action已取消';
  }

  @override
  String get preparingDownload => '准备下载';

  @override
  String fileNotExists(int index) {
    return '第$index个文件不存在';
  }

  @override
  String get file => '文件';

  @override
  String get fileDownloadFailed => '文件下载失败';

  @override
  String get fileNotExistsOrExpired => '文件不存在或已过期';

  @override
  String get noPermissionToDownload => '没有权限下载此文件';

  @override
  String get imageFile => '图片文件';

  @override
  String get videoFile => '视频文件';

  @override
  String get documentFile => '文档文件';

  @override
  String get audioFile => '音频文件';

  @override
  String get selectFileType => '选择文件类型';

  @override
  String get selectFileTypeMultiple => '选择文件类型（多选直接发送）';

  @override
  String get image => '图片';

  @override
  String get video => '视频';

  @override
  String get document => '文档';

  @override
  String get audio => '音频';

  @override
  String get canDragToSelectText => '可以直接拖拽选择文字内容';

  @override
  String get recallMessage => '撤回消息';

  @override
  String get addToFavoritesFailed => '收藏失败';

  @override
  String get removeFromFavoritesFailed => '取消收藏失败';

  @override
  String get jumpedToOriginal => '已跳转到原消息';

  @override
  String get gallery => '相册';

  @override
  String get documents => '文档';

  @override
  String get saveFailed => '保存失败';

  @override
  String get textShared => '文字已分享';

  @override
  String get fileNotAvailableAndNoTextToShare => '文件不可用且无文字内容可分享';

  @override
  String get messageRecalledText => '[此消息已被撤回]';

  @override
  String get cannotOpenFileLocation => '无法打开文件位置';

  @override
  String get copyFilePathFailed => '复制文件路径失败';

  @override
  String get copyFileLinkFailed => '复制文件链接失败';

  @override
  String get desktopVideoNoValidSource => '桌面端无有效视频源';

  @override
  String get mobileVideoNoValidSource => '移动端无有效视频源';

  @override
  String get desktopVideo => '桌面端视频';

  @override
  String get sectionchatui => '';

  @override
  String get continuedTransfer => '继续传输';

  @override
  String get sectionchatmessages => '';

  @override
  String get batchRecallReason => '批量撤回';

  @override
  String get batchDeleteReason => '批量删除';

  @override
  String get confirmCancelUpload => '确定要取消上传这个文件吗？';

  @override
  String get confirmCancelDownload => '确定要取消下载这个文件吗？';

  @override
  String get uploadCancelled => '上传已取消';

  @override
  String get downloadCancelled => '下载已取消';

  @override
  String get favoritesFailed => '收藏失败';

  @override
  String get fileUnavailableNoText => '文件不可用且无文字内容可分享';

  @override
  String get filePathCopied => '文件路径已复制到剪贴板';

  @override
  String get fileLinkCopied => '文件链接已复制到剪贴板';

  @override
  String get saveButton => '保存';

  @override
  String get titleLabel => '标题';

  @override
  String get titleHint => '输入标题';

  @override
  String get contentLabel => '内容';

  @override
  String get note => '备注';

  @override
  String get otherInfo => '其他信息';

  @override
  String get expenseItem => '消费项目';

  @override
  String get amount => '金额';

  @override
  String get type => '类型';

  @override
  String get expense => '支出';

  @override
  String get income => '收入';

  @override
  String get category => '分类';

  @override
  String get date => '日期';

  @override
  String get detailedDescription => '详细描述';

  @override
  String get scheduleTitle => '日程标题';

  @override
  String get startTime => '开始时间';

  @override
  String get location => '地点';

  @override
  String get details => '详情';

  @override
  String get advanceReminder => '提前提醒';

  @override
  String get noReminder => '不提醒';

  @override
  String get task => '任务';

  @override
  String get whatToDo => '要做什么';

  @override
  String get detailedTaskDescription => '详细描述';

  @override
  String get priority => '优先级';

  @override
  String get low => '低';

  @override
  String get medium => '中';

  @override
  String get high => '高';

  @override
  String get websiteOrLinkName => '网站或链接名称';

  @override
  String get linkPurpose => '这个链接的用途或内容';

  @override
  String get fileDescription => '文件描述';

  @override
  String get fileExplanation => '文件说明';

  @override
  String get selectDate => '选择日期';

  @override
  String get selectTime => '选择时间';

  @override
  String get clickToSelectFile => '点击选择文件';

  @override
  String get addAccountPassword => '添加账号密码';

  @override
  String get recordExpense => '记一笔账';

  @override
  String get createSchedule => '创建日程';

  @override
  String get addTodo => '添加待办';

  @override
  String get saveLink => '保存链接';

  @override
  String get saveImage => '保存图片';

  @override
  String get saveVideo => '保存视频';

  @override
  String get saveDocument => '保存文档';

  @override
  String get writeNote => '写笔记';

  @override
  String get pleaseSelectFile => '请选择文件';

  @override
  String get saveSuccess => '保存成功';

  @override
  String get sectioninput => '';

  @override
  String get inputMessageHintDesktop => '输入消息或拖拽文件...(Enter发送)';

  @override
  String get inputMessageHintMobile => '输入消息或拖拽文件...';

  @override
  String get addDescriptionText => '添加说明文字...(Enter发送)';

  @override
  String get sectionmenu => '';

  @override
  String get sideMenu => '侧边菜单';

  @override
  String get appSettings => '应用设置';

  @override
  String get networkDiagnostics => '网络诊断';

  @override
  String get currentDevice => '当前设备';

  @override
  String get systemInfo => '系统信息';

  @override
  String get noGroup => '无群组';

  @override
  String get sectionpriority => '';

  @override
  String get highPriority => '高优先级';

  @override
  String get mediumPriority => '中优先级';

  @override
  String get lowPriority => '低优先级';

  @override
  String get justNow => '刚刚';

  @override
  String get sectionaccount => '';

  @override
  String accountInfo(String username, String website) {
    return '账号: $username • 网站: $website';
  }

  @override
  String get sectionforms => '';

  @override
  String get loginAccountHint => '登录账号';

  @override
  String get passwordHint => '登录密码';

  @override
  String get notesLabel => '备注';

  @override
  String get otherInfoHint => '其他信息';

  @override
  String get expenseItemHint => '如：午餐、购物';

  @override
  String get amountHint => '0.00';

  @override
  String get typeLabel => '类型';

  @override
  String get categoryLabel => '分类';

  @override
  String get categoryHint => '如：餐饮、交通';

  @override
  String get dateLabel => '日期';

  @override
  String get detailsHint => '详细说明';

  @override
  String get scheduleTitleHint => '会议、约会等';

  @override
  String get startTimeLabel => '开始时间';

  @override
  String get endTimeOptional => '结束时间（可选）';

  @override
  String get locationLabel => '地点';

  @override
  String get locationHint => '会议室、餐厅等';

  @override
  String get detailsLabel => '详情';

  @override
  String get meetingDetailsHint => '会议内容、注意事项';

  @override
  String get minutes5Before => '5分钟前';

  @override
  String get minutes15Before => '15分钟前';

  @override
  String get minutes30Before => '30分钟前';

  @override
  String get hour1Before => '1小时前';

  @override
  String get taskLabel => '任务';

  @override
  String get taskRequirementsHint => '具体要求、注意事项';

  @override
  String get priorityLabel => '优先级';

  @override
  String get dueDateOptional => '截止日期（可选）';

  @override
  String get websiteLinkName => '网站或链接名称';

  @override
  String get urlLink => 'URL链接';

  @override
  String get sectionshare => '';

  @override
  String get confirmShare => '确认分享';

  @override
  String get textSent => '文本已发送';

  @override
  String get fileSent => '文件已发送';

  @override
  String filesSent(int count) {
    return '$count个文件已发送';
  }

  @override
  String get sectionmissing => '';

  @override
  String get sectionmemoryforms => '';

  @override
  String get usernameEmailLabel => '用户名/邮箱';

  @override
  String get passwordLabel => '密码';

  @override
  String get expenseItemLabel => '消费项目';

  @override
  String get amountLabel => '金额';

  @override
  String get notesHint => '详细说明';

  @override
  String get scheduleTitleLabel => '日程标题';

  @override
  String get endTimeOptionalLabel => '结束时间（可选）';

  @override
  String get advanceReminderLabel => '提前提醒';

  @override
  String get whatToDoHint => '要做什么';

  @override
  String get detailedDescriptionLabel => '详细描述';

  @override
  String get dueDateOptionalLabel => '截止日期（可选）';

  @override
  String get urlLinkLabel => 'URL链接';

  @override
  String get linkDescriptionLabel => '描述';

  @override
  String get linkPurposeHint => '这个链接的用途或内容';

  @override
  String get fileLabel => '文件 *';

  @override
  String pleaseEnter(String field) {
    return '请输入$field';
  }

  @override
  String get completed => '已完成';

  @override
  String get addTag => '添加标签';

  @override
  String get addTagLabel => '添加标签';

  @override
  String get enterTagName => '输入标签名称';

  @override
  String get aiGenerate => 'AI生成';

  @override
  String get generating => '生成中...';

  @override
  String aiGeneratedTags(int count) {
    return 'AI生成了$count个新标签';
  }

  @override
  String generateTagsFailed(String error) {
    return '生成标签失败: $error';
  }

  @override
  String get updateSuccess => '更新成功';

  @override
  String updateFailed(String error) {
    return '更新失败: $error';
  }

  @override
  String editMemoryType(String type) {
    return '编辑$type';
  }

  @override
  String get enterTitle => '输入标题';

  @override
  String get enterContent => '输入内容';

  @override
  String get tagsLabel => '标签';

  @override
  String get processingShareContent => '正在处理分享内容...';

  @override
  String get shareSuccess => '✅ 分享成功！';

  @override
  String get shareFailed => '❌ 分享失败';

  @override
  String get shareException => '❌ 分享异常';

  @override
  String get allContentSentToGroup => '所有内容已发送到当前群组';

  @override
  String get pleaseTryAgainLater => '请稍后重试';

  @override
  String processingError(String error) {
    return '处理出现错误: $error';
  }

  @override
  String get allFilesSentComplete => '所有文件发送完成';

  @override
  String get partialFilesSentComplete => '部分文件发送完成';

  @override
  String get allFilesSendFailed => '所有文件发送失败';

  @override
  String get fileSentSuccess => '文件发送成功！';

  @override
  String textSharedCount(int count) {
    return '已分享$count条文本消息';
  }

  @override
  String get messageShare => 'Send To Myself - 消息分享';

  @override
  String fileShared(String fileName) {
    return '文件 $fileName 已分享';
  }

  @override
  String get fileUnavailableSharedText => '文件不可用，已分享文字内容';

  @override
  String get resolvingServerDomain => '🔍 解析服务器域名...';

  @override
  String serverDnsSuccess(String address) {
    return '✅ 服务器DNS解析成功: $address';
  }

  @override
  String get serverDnsFailed => '❌ 服务器DNS解析失败: 无结果';

  @override
  String serverDnsError(String error) {
    return '❌ 服务器DNS解析失败: $error';
  }

  @override
  String get testingServerConnection => '🔍 测试服务器连接...';

  @override
  String get serverConnectionSuccess => '✅ 服务器连接成功';

  @override
  String serverConnectionFailed(String error) {
    return '❌ 服务器连接失败: $error';
  }

  @override
  String get startingWebSocketTest => '🧪 开始WebSocket连接测试...';

  @override
  String currentConnectionStatus(String status) {
    return '📊 当前连接状态: $status';
  }

  @override
  String get sendingTestPing => '📡 发送测试ping...';

  @override
  String get webSocketNotConnected => '⚠️ WebSocket未连接，无法发送测试消息';

  @override
  String get executingForceReconnect => '🔄 执行强制重连...';

  @override
  String get stopPingTest => '⏹️ 停止Ping测试';

  @override
  String get startPingTest => '🏓 开始Ping测试 (每5秒)';

  @override
  String get sendingPing => '🏓 发送测试ping';

  @override
  String get connectionDisconnectedPausePing => '⚠️ 连接断开，暂停ping测试';

  @override
  String get logCleared => '🧹 日志已清除';

  @override
  String get logCopiedToClipboard => '日志已复制到剪贴板';

  @override
  String get noResult => '无结果';

  @override
  String get sectionwidgets => '';

  @override
  String get logoutErrorMessage => '退出登录时发生错误';

  @override
  String get loginStatusExpired => '登录状态已失效';

  @override
  String get logoutFailedMessage => '退出登录失败，您可以选择强制退出或重试。';

  @override
  String get preparingToSendFiles => '准备发送文件...';

  @override
  String sendingFileCount(int current) {
    return '正在发送第$current个文件...';
  }

  @override
  String sendingFileProgress(int current, String sizeMB) {
    return '发送第$current个文件 (${sizeMB}MB)';
  }

  @override
  String retryingSendFile(int current) {
    return '重试发送第$current个文件';
  }

  @override
  String fileSendSuccess(int current) {
    return '✅ 第$current个文件发送成功';
  }

  @override
  String filesCompleted(int success, int total) {
    return '已完成 $success/$total 个文件';
  }

  @override
  String get waitingForServerProcessing => '等待服务器处理...';

  @override
  String get ensureFileFullyUploaded => '确保文件完全上传';

  @override
  String fileSendFailed(int current) {
    return '❌ 第$current个文件发送失败';
  }

  @override
  String maxRetriesReached(String fileName, int maxRetries) {
    return '$fileName 已重试$maxRetries次仍失败';
  }

  @override
  String fileSendException(int current) {
    return '❌ 第$current个文件发送异常';
  }

  @override
  String sendErrorMessage(String fileName, String error) {
    return '$fileName 发送时出现错误: $error';
  }

  @override
  String fileDataIncomplete(int current) {
    return '❌ 第$current个文件数据异常';
  }

  @override
  String get fileInfoIncompleteMessage => '文件信息不完整';

  @override
  String allFilesSentToGroup(int count) {
    return '共发送了$count个文件到当前群组';
  }

  @override
  String successCountFiles(int success, int total) {
    return '成功：$success/$total个文件';
  }

  @override
  String get noFilesToSendError => '❌ 没有文件可发送';

  @override
  String get shareDataEmpty => '分享数据为空';

  @override
  String get sendingFile => '发送文件...';

  @override
  String fileUploadFailed(String fileName) {
    return '$fileName 上传失败';
  }

  @override
  String fileSentToGroup(String fileName) {
    return '$fileName 已发送到群组';
  }

  @override
  String get unsupportedShareType => '❌ 不支持的分享类型';

  @override
  String get cannotHandleContentType => '无法处理此类型的内容';

  @override
  String get textSendSuccess => '✅ 文本发送成功！';

  @override
  String get contentSentToGroup => '内容已发送到群组';

  @override
  String get textSendFailed => '❌ 文本发送失败';

  @override
  String get unknownFileName => '未知文件名';

  @override
  String filePathInvalid(String fileName) {
    return '$fileName 文件路径无效';
  }

  @override
  String retryAttempt(int retry, String fileName) {
    return '第$retry次重试 - $fileName';
  }
}
