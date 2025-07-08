// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'Send To Myself';

  @override
  String get appDescription =>
      'Cross-device file sharing and message memory assistant';

  @override
  String get commonSection => '';

  @override
  String get navigation => 'Navigation';

  @override
  String get chat => 'Chat';

  @override
  String get memory => 'Memory';

  @override
  String get noGroupsMessage => 'No groups yet';

  @override
  String get noGroupsHint => 'Click the button above to create or join a group';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Info';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Close';

  @override
  String get open => 'Open';

  @override
  String get share => 'Share';

  @override
  String get copy => 'Copy';

  @override
  String get paste => 'Paste';

  @override
  String get cut => 'Cut';

  @override
  String get selectAll => 'Select All';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sort';

  @override
  String get settings => 'Settings';

  @override
  String get help => 'Help';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get update => 'Update';

  @override
  String get download => 'Download';

  @override
  String get upload => 'Upload';

  @override
  String get send => 'Send';

  @override
  String get receive => 'Receive';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get connecting => 'Connecting';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get retry_connection => 'Retry Connection';

  @override
  String get authSection => '';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get logout => 'Logout';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerSubtitle => 'Sign up to get started';

  @override
  String get registerDevice => 'Register Device';

  @override
  String get registering => 'Registering...';

  @override
  String get deviceRegistration => 'Device Registration';

  @override
  String get deviceRegistrationSuccess => 'Device registered successfully';

  @override
  String get deviceRegistrationFailed => 'Device registration failed';

  @override
  String get loginSuccess => 'Login successful';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get logoutSuccess => 'Logout successful';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get navigationSection => '';

  @override
  String get home => 'Home';

  @override
  String get messages => 'Messages';

  @override
  String get files => 'Files';

  @override
  String get memories => 'Memories';

  @override
  String get groups => 'Groups';

  @override
  String get sectionmessages => '';

  @override
  String get newMessage => 'New Message';

  @override
  String get onlyMyself => 'Only myself';

  @override
  String devicesCount(int count) {
    return '$count devices';
  }

  @override
  String get clickToStartGroupChat => 'Click to start group chat';

  @override
  String get sendToMyself => 'Send to myself';

  @override
  String get clickToStartChat => 'Click to start chat';

  @override
  String get unknownDevice => 'Unknown Device';

  @override
  String get unknownType => 'Unknown type';

  @override
  String get myself => 'Me';

  @override
  String get noConversations => 'No conversations';

  @override
  String get joinGroupToStartChat => 'Join a device group to start chatting';

  @override
  String get pleaseSelectGroup => 'Please select a group first';

  @override
  String get clickGroupSelectorHint =>
      'Click the group selector at the top to select or create a group';

  @override
  String get sendMessage => 'Send Message';

  @override
  String get messageHint => 'Type your message...';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get messagesSent => 'Messages sent';

  @override
  String get messagesReceived => 'Messages received';

  @override
  String get messageDelivered => 'Delivered';

  @override
  String get messageFailed => 'Failed';

  @override
  String get messagePending => 'Pending';

  @override
  String get copyMessage => 'Copy Message';

  @override
  String get deleteMessage => 'Delete Message';

  @override
  String get replyMessage => 'Reply';

  @override
  String get forwardMessage => 'Forward';

  @override
  String get selectMessages => 'Select Messages';

  @override
  String selectedMessages(int count) {
    return '$count selected';
  }

  @override
  String get deleteSelectedMessages => 'Delete Selected Messages';

  @override
  String get deleteMessageConfirm =>
      'Are you sure you want to delete this message?';

  @override
  String deleteMessagesConfirm(int count) {
    return 'Are you sure you want to delete $count messages?';
  }

  @override
  String get sectionfiles => '';

  @override
  String get selectFile => 'Select File';

  @override
  String get selectFiles => 'Select Files';

  @override
  String get selectImage => 'Select Image';

  @override
  String get selectVideo => 'Select Video';

  @override
  String get selectDocument => 'Select Document';

  @override
  String get noFiles => 'No files';

  @override
  String get fileName => 'File Name';

  @override
  String get fileSize => 'File Size';

  @override
  String get fileType => 'File Type';

  @override
  String get fileDate => 'Date';

  @override
  String get uploadFile => 'Upload File';

  @override
  String get downloadFile => 'Download File';

  @override
  String get openFile => 'Open File';

  @override
  String get shareFile => 'Share File';

  @override
  String get deleteFile => 'Delete File';

  @override
  String uploadProgress(int progress) {
    return 'Uploading... $progress%';
  }

  @override
  String downloadProgress(int progress) {
    return 'Downloading... $progress%';
  }

  @override
  String get uploadSuccess => 'Upload successful';

  @override
  String get downloadSuccess => 'Download successful';

  @override
  String get uploadFailed => 'Upload failed';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get fileTooLarge => 'File is too large';

  @override
  String get unsupportedFileType => 'Unsupported file type';

  @override
  String get saveToGallery => 'Save to Gallery';

  @override
  String get saveToLocal => 'Save to Local';

  @override
  String get openFileLocation => 'Open File Location';

  @override
  String get sectionmemories => '';

  @override
  String get createMemory => 'Create Memory';

  @override
  String get editMemory => 'Edit Memory';

  @override
  String get deleteMemory => 'Delete Memory';

  @override
  String get memoryTitle => 'Title';

  @override
  String get memoryContent => 'Content';

  @override
  String get memoryCategory => 'Category';

  @override
  String get memoryTags => 'Tags';

  @override
  String get memoryDate => 'Date';

  @override
  String get memoryLocation => 'Location';

  @override
  String get memoryPriority => 'Priority';

  @override
  String get memoryStatus => 'Status';

  @override
  String get noMemories => 'No memories yet';

  @override
  String get searchMemories => 'Search memories...';

  @override
  String get filterByCategory => 'Filter by category';

  @override
  String get sortByDate => 'Sort by date';

  @override
  String get sortByPriority => 'Sort by priority';

  @override
  String get memoryCategories => 'Categories';

  @override
  String get personalMemory => 'Personal';

  @override
  String get workMemory => 'Work';

  @override
  String get lifeMemory => 'Life';

  @override
  String get studyMemory => 'Study';

  @override
  String get travelMemory => 'Travel';

  @override
  String get otherMemory => 'Other';

  @override
  String get memoryPriorityHigh => 'High';

  @override
  String get memoryPriorityMedium => 'Medium';

  @override
  String get memoryPriorityLow => 'Low';

  @override
  String get memoryStatusActive => 'Active';

  @override
  String get memoryStatusCompleted => 'Completed';

  @override
  String get memoryStatusArchived => 'Archived';

  @override
  String get sectiongroups => '';

  @override
  String get createGroup => 'Create Group';

  @override
  String get joinGroup => 'Join Group';

  @override
  String get leaveGroup => 'Leave Group';

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String get groupName => 'Group Name';

  @override
  String get groupNameHint => 'Please enter group name';

  @override
  String get groupDescription => 'Group Description';

  @override
  String get groupDescriptionHint => 'Please enter group description';

  @override
  String get groupDescriptionOptional => 'Group Description (Optional)';

  @override
  String get groupMembers => 'Members';

  @override
  String get groupSettings => 'Group Settings';

  @override
  String get noGroups => 'No groups';

  @override
  String get groupCode => 'Group Code';

  @override
  String get scanQRCode => 'Scan QR Code';

  @override
  String get generateQRCode => 'Generate QR Code';

  @override
  String get joinGroupByCode => 'Join by Code';

  @override
  String get joinGroupByQR => 'Join by QR Code';

  @override
  String get groupJoinSuccess => 'Joined group successfully';

  @override
  String get groupJoinFailed => 'Failed to join group';

  @override
  String get groupLeaveSuccess => 'Left group successfully';

  @override
  String get groupLeaveFailed => 'Failed to leave group';

  @override
  String get groupLeaveConfirm => 'Are you sure you want to leave this group?';

  @override
  String get groupDeleteConfirm =>
      'Are you sure you want to delete this group?';

  @override
  String get groupCreated => 'Group created successfully';

  @override
  String get groupCreateFailed => 'Failed to create group';

  @override
  String get invalidGroupCode => 'Invalid group code';

  @override
  String get groupNotFound => 'Group not found';

  @override
  String get alreadyInGroup => 'Already in this group';

  @override
  String get groupFull => 'Group is full';

  @override
  String get renameGroup => 'Rename Group';

  @override
  String get newGroupName => 'New Group Name';

  @override
  String get enterNewGroupName => 'Enter new group name';

  @override
  String get renamingGroup => 'Renaming group...';

  @override
  String get groupRenameSuccess => 'Group renamed successfully';

  @override
  String get groupRenameFailed => 'Failed to rename group';

  @override
  String get renameFailed => 'Rename failed';

  @override
  String get loadGroupInfoFailed => 'Failed to load group information';

  @override
  String get groupManagement => 'Group Management';

  @override
  String get membersList => 'Members List';

  @override
  String get groupInfo => 'Group Information';

  @override
  String get sectiondevices => '';

  @override
  String get deviceName => 'Device Name';

  @override
  String get deviceType => 'Device Type';

  @override
  String get deviceStatus => 'Status';

  @override
  String get deviceLastSeen => 'Last Seen';

  @override
  String get connectedDevices => 'Connected Devices';

  @override
  String get availableDevices => 'Available Devices';

  @override
  String get noDevices => 'No devices';

  @override
  String get connectDevice => 'Connect Device';

  @override
  String get disconnectDevice => 'Disconnect Device';

  @override
  String get removeDevice => 'Remove Device';

  @override
  String get deviceConnected => 'Device connected';

  @override
  String get deviceDisconnected => 'Device disconnected';

  @override
  String get deviceRemoved => 'Device removed';

  @override
  String get deviceNotFound => 'Device not found';

  @override
  String get deviceConnectionFailed => 'Failed to connect device';

  @override
  String get sectionsync => '';

  @override
  String get sync => 'Sync';

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncComplete => 'Sync complete';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get autoSync => 'Auto Sync';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get lastSync => 'Last Sync';

  @override
  String get syncSettings => 'Sync Settings';

  @override
  String get syncMessages => 'Sync Messages';

  @override
  String get syncFiles => 'Sync Files';

  @override
  String get syncMemories => 'Sync Memories';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get onlineMode => 'Online Mode';

  @override
  String get sectionqr => '';

  @override
  String get qrCodeTitle => 'QR Code';

  @override
  String get scanQR => 'Scan QR';

  @override
  String get generateQR => 'Generate QR';

  @override
  String get qrCodeGenerated => 'QR Code generated';

  @override
  String get qrCodeScanned => 'QR Code scanned';

  @override
  String get qrScanFailed => 'QR scan failed';

  @override
  String get invalidQRCode => 'Invalid QR code';

  @override
  String get qrPermissionDenied => 'Camera permission denied';

  @override
  String get qrCameraError => 'Camera error';

  @override
  String get manualInput => 'Manual Input';

  @override
  String get flashlight => 'Flashlight';

  @override
  String get enterJoinCode => 'Enter Join Code';

  @override
  String get joinCodeHint => '8-digit join code';

  @override
  String get joinGroupSuccess => 'Successfully joined group!';

  @override
  String get joinGroupFailed => 'Failed to join group';

  @override
  String get joinFailed => 'Join failed';

  @override
  String get joiningGroup => 'Joining group...';

  @override
  String get placeQRInFrame => 'Place QR code within the frame to scan';

  @override
  String get deviceJoinCode => 'Device Join Code';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get generatingJoinCode => 'Generating join code...';

  @override
  String get generateFailed => 'Generation failed';

  @override
  String get noGroupInfo => 'No available group information';

  @override
  String get join => 'Join';

  @override
  String get sectionnetwork => '';

  @override
  String get networkStatus => 'Network Status';

  @override
  String get networkConnected => 'Connected';

  @override
  String get networkDisconnected => 'Disconnected';

  @override
  String get networkError => 'Network Error';

  @override
  String get connectionTimeout => 'Connection timeout';

  @override
  String get serverError => 'Server error';

  @override
  String get clientError => 'Client error';

  @override
  String get networkDebug => 'Network Debug';

  @override
  String get checkConnection => 'Check Connection';

  @override
  String get reconnecting => 'Reconnecting...';

  @override
  String get reconnected => 'Reconnected';

  @override
  String get connectionLost => 'Connection lost';

  @override
  String get sectionnotifications => '';

  @override
  String get notifications => 'Notifications';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get disableNotifications => 'Disable Notifications';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get newMessageNotification => 'New message';

  @override
  String get fileUploadNotification => 'File upload complete';

  @override
  String get fileDownloadNotification => 'File download complete';

  @override
  String get syncCompleteNotification => 'Sync complete';

  @override
  String get deviceConnectedNotification => 'Device connected';

  @override
  String get deviceDisconnectedNotification => 'Device disconnected';

  @override
  String get sectiontime => '';

  @override
  String get now => 'Now';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This week';

  @override
  String get lastWeek => 'Last week';

  @override
  String get thisMonth => 'This month';

  @override
  String get lastMonth => 'Last month';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get sectionerrors => '';

  @override
  String get errorGeneral => 'An error occurred';

  @override
  String get errorNetwork => 'Network error';

  @override
  String get errorTimeout => 'Request timeout';

  @override
  String get errorServerUnavailable => 'Server unavailable';

  @override
  String get errorUnauthorized => 'Unauthorized access';

  @override
  String get errorForbidden => 'Access forbidden';

  @override
  String get errorNotFound => 'Resource not found';

  @override
  String get errorInternalServer => 'Internal server error';

  @override
  String get errorBadRequest => 'Bad request';

  @override
  String get errorTooManyRequests => 'Too many requests';

  @override
  String get errorServiceUnavailable => 'Service unavailable';

  @override
  String get errorUnknown => 'Unknown error';

  @override
  String get errorRetry => 'Please try again';

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
  String get permissionRequired => 'Permission Required';

  @override
  String get permissionDenied => 'Permission Denied';

  @override
  String get permissionCamera => 'Camera permission is required';

  @override
  String get permissionStorage => 'Storage permission is required';

  @override
  String get permissionNotification => 'Notification permission is required';

  @override
  String get permissionLocation => 'Location permission is required';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get sectionsettings => '';

  @override
  String get deviceInfo => 'Device Information';

  @override
  String get deviceId => 'Device ID';

  @override
  String get platform => 'Platform';

  @override
  String get unknown => 'Unknown';

  @override
  String get appTheme => 'App Theme';

  @override
  String get defaultTheme => 'Default';

  @override
  String get enabled => 'Enabled';

  @override
  String get aboutApp => 'About App';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get featureComingSoon =>
      'This feature is coming soon, please stay tuned!';

  @override
  String get logoutConfirmTitle => 'Logout';

  @override
  String get logoutConfirmMessage =>
      'Are you sure you want to logout from this device?';

  @override
  String get sectionmemory => '';

  @override
  String memoriesCount(int count) {
    return 'Saved $count memories';
  }

  @override
  String get noMemoriesDesc => 'Start creating your first memory';

  @override
  String get viewMemory => 'View Memory';

  @override
  String get quickAdd => 'Quick Add';

  @override
  String get addMemoryFromText => 'Add from Text';

  @override
  String get addMemoryFromImage => 'Add from Image';

  @override
  String get addMemoryFromFile => 'Add from File';

  @override
  String get sectionjoingroup => '';

  @override
  String get scanMode => 'Scan Mode';

  @override
  String get inputMode => 'Input Mode';

  @override
  String get cameraInitFailed => 'Camera initialization failed';

  @override
  String get cameraNotAvailable =>
      'Camera not available, switched to manual input mode';

  @override
  String get desktopCameraTip =>
      'Desktop mode recommends manual input, camera scanning may be unstable';

  @override
  String get enterGroupCode => 'Enter Group Code';

  @override
  String get groupCodePlaceholder => 'Enter 8-digit group code';

  @override
  String get invalidCode => 'Invalid code';

  @override
  String get codeRequired => 'Code is required';

  @override
  String get processing => 'Processing...';

  @override
  String get switchToScan => 'Switch to Scan Mode';

  @override
  String get switchToInput => 'Switch to Input Mode';

  @override
  String get cameraUnavailable => 'Camera unavailable';

  @override
  String get checkCameraPermissions =>
      'Please check camera permission settings';

  @override
  String get desktopInputModeRecommended =>
      'Desktop mode recommends using the \"Enter Invite Code\" mode below';

  @override
  String get cameraStartupFailed => 'Camera startup failed';

  @override
  String get startingCamera => 'Starting camera...';

  @override
  String get placeQRInScanFrame => 'Place QR code within the scan frame';

  @override
  String get switchToInputModeOrCheckPermissions =>
      'Please switch to input mode or check camera permissions';

  @override
  String get enterInviteCodeHint =>
      'Please enter group invite code (4-20 digits)';

  @override
  String get inviteCodePlaceholder => 'Invite code';

  @override
  String get clickToJoinGroup => 'Click to join group';

  @override
  String get selectGroup => 'Select Group';

  @override
  String get createGroupFailed => 'Failed to create group';

  @override
  String get pleaseEnterGroupName => 'Please enter group name';

  @override
  String groupCreatedSuccessfully(Object name) {
    return 'Group \"$name\" created successfully';
  }

  @override
  String get title => 'Title';

  @override
  String get content => 'Content';

  @override
  String get writeYourThoughts => 'Write your thoughts...';

  @override
  String get enterNoteTitle => 'Enter note title';

  @override
  String get websiteAppName => 'Website/App Name';

  @override
  String get websiteAppNameHint => 'e.g.: WeChat, Taobao';

  @override
  String get websiteAddress => 'Website Address';

  @override
  String get websiteAddressHint => 'https://...';

  @override
  String get usernameEmail => 'Username/Email';

  @override
  String get loginAccount => 'Login Account';

  @override
  String get password => 'Password';

  @override
  String get loginPassword => 'Login Password';

  @override
  String get sectionchat => '';

  @override
  String get sendFailed => 'Send failed';

  @override
  String get maxAllowed => 'Maximum allowed';

  @override
  String get selectFileFailed => 'Select file failed';

  @override
  String get pasteFailed => 'Paste failed';

  @override
  String get fileProcessingFailed => 'File processing failed';

  @override
  String sharedTextMessages(Object count) {
    return 'Shared $count text messages';
  }

  @override
  String sharedFiles(Object count) {
    return 'Shared $count files';
  }

  @override
  String batchShareFailed(String error) {
    return 'Batch share failed: $error';
  }

  @override
  String copiedMessages(Object count) {
    return 'Copied $count messages to clipboard';
  }

  @override
  String messagesAddedToInput(Object count) {
    return '$count message contents added to input box';
  }

  @override
  String favoriteMessages(Object count, Object total) {
    return 'Favorited $count/$total messages';
  }

  @override
  String recalledMessages(Object count) {
    return 'Recalled $count messages';
  }

  @override
  String get batchRecallFailed => 'Batch recall failed';

  @override
  String deletedMessages(Object count) {
    return 'Deleted $count messages';
  }

  @override
  String get batchDeleteFailed => 'Batch delete failed';

  @override
  String get debugInfo => 'Debug Info';

  @override
  String get permanentStorageDir => 'Permanent Storage Directory';

  @override
  String get storageUsage => 'Storage Usage:';

  @override
  String get chatData => 'Chat Data';

  @override
  String get memoryData => 'Memory Data';

  @override
  String get userData => 'User Data';

  @override
  String get fileCache => 'File Cache';

  @override
  String get total => 'Total';

  @override
  String get fileCacheStats => 'File Cache Stats:';

  @override
  String get totalFiles => 'Total Files';

  @override
  String get validFiles => 'Valid Files';

  @override
  String get invalidFiles => 'Invalid Files';

  @override
  String get deduplicationDiagnostics => 'Deduplication Diagnostics:';

  @override
  String get processedMessageIds => 'Processed Message IDs';

  @override
  String get timestampRecords => 'Timestamp Records';

  @override
  String get uiMessages => 'UI Messages';

  @override
  String get websocketConnection => 'WebSocket Connection';

  @override
  String get lastMessageReceived => 'Last Message Received';

  @override
  String get forceClearDedupRecords =>
      'Force clear dedup records and restart WebSocket listening';

  @override
  String get clearDedupRecords => 'Clear Dedup Records';

  @override
  String get getDebugInfoFailed => 'Failed to get debug info';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get textCopiedToClipboard => 'Text copied to clipboard';

  @override
  String get canDragSelectText =>
      'You can directly drag to select text content';

  @override
  String get allContentCopied => 'All content copied to clipboard';

  @override
  String get messageRecalled => 'Message recalled';

  @override
  String get recallFailed => 'Recall failed';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String get messageAddedToInput => 'Message content added to input box';

  @override
  String get addedToFavorites => 'Added to favorites';

  @override
  String get favoriteFailed => 'Favorite failed';

  @override
  String get removedFromFavorites => 'Removed from favorites';

  @override
  String get unfavoriteFailed => 'Failed to remove from favorites';

  @override
  String get confirmDeleteMessage =>
      'Are you sure you want to delete this message?';

  @override
  String get jumpedToOriginalMessage => 'Jumped to original message';

  @override
  String get originalMessageNotExists =>
      'Original message does not exist or has been deleted';

  @override
  String get fileInfoIncomplete => 'File information incomplete';

  @override
  String get featureOnlyMobile => 'This feature is only available on mobile';

  @override
  String get fileNotExistsDownloading => 'File does not exist, downloading...';

  @override
  String get fileDownloadFailedCannotSave =>
      'File download failed, cannot save';

  @override
  String get sectionnetworkdebug => '';

  @override
  String get networkDiagnosticTool => 'Network Diagnostic Tool';

  @override
  String get clearLogs => 'Clear Logs';

  @override
  String get copyLogs => 'Copy Logs';

  @override
  String get connectionStatus => 'Connection Status';

  @override
  String get connectionDetails => 'Connection Details';

  @override
  String get networkTest => 'Network Test';

  @override
  String get testWebSocket => 'Test WebSocket';

  @override
  String get forceReconnect => 'Force Reconnect';

  @override
  String get pingTest => 'Ping Test';

  @override
  String get diagnosticLogs => 'Diagnostic Logs';

  @override
  String recordsCount(int count) {
    return '$count records';
  }

  @override
  String get startingNetworkDiagnostic => 'Starting network diagnostic test...';

  @override
  String get testingBasicConnectivity => 'Testing basic connectivity...';

  @override
  String get testingDnsResolution => 'Testing DNS resolution...';

  @override
  String get testingServerConnectivity => 'Testing server connectivity...';

  @override
  String get networkDiagnosticComplete => 'Network diagnostic test complete';

  @override
  String get testingConnection => 'Testing connection';

  @override
  String get connectionSuccessful => 'Connection successful';

  @override
  String get connectionFailed => 'Connection Failed';

  @override
  String get connectionStatusChanged => 'Connection status changed';

  @override
  String get networkStatusChanged => 'Network status changed';

  @override
  String get errorOccurred => 'Error occurred';

  @override
  String get messageReceived => 'Message received';

  @override
  String get sectionsplash => '';

  @override
  String get appSlogan => 'Cross-device file sharing and sync';

  @override
  String get myFiles => 'My Files';

  @override
  String get filesFeatureComingSoon => 'File feature coming soon';

  @override
  String get stayTuned => 'Stay tuned';

  @override
  String get sectiondevicegroups => '';

  @override
  String get noDeviceGroups => 'No device groups yet';

  @override
  String get scanQRToJoin => 'Use other devices to scan QR code to join';

  @override
  String get myDeviceGroups => 'My Device Groups';

  @override
  String get unnamedGroup => 'Unnamed Group';

  @override
  String deviceCount(int count) {
    return '$count devices';
  }

  @override
  String get youAreOwner => 'You are the owner';

  @override
  String get member => 'Member';

  @override
  String get createdOn => 'Created on';

  @override
  String get unknownDate => 'Unknown';

  @override
  String get sectiondebug => '';

  @override
  String get batchDelete => 'Batch Delete';

  @override
  String confirmBatchDelete(int count) {
    return 'Are you sure you want to delete the selected $count messages? This action cannot be undone.';
  }

  @override
  String batchDeleteSuccess(int count) {
    return 'Deleted $count messages';
  }

  @override
  String batchDeleteFailedWithError(String error) {
    return 'Batch delete failed: $error';
  }

  @override
  String get deleteMessageTitle => 'Delete Message';

  @override
  String get confirmDeleteSingleMessage =>
      'Are you sure you want to delete this message? This action cannot be undone.';

  @override
  String deleteFailedWithError(String error) {
    return 'Delete failed: $error';
  }

  @override
  String recallFailedWithError(String error) {
    return 'Recall failed: $error';
  }

  @override
  String get startConversation => 'Start conversation';

  @override
  String get sendMessageOrFileToStart =>
      'Send a message or file to start chatting';

  @override
  String get debugInfoTitle => 'Debug Info';

  @override
  String get permanentStorageDirectory => 'Permanent Storage Directory:';

  @override
  String get memoryDeleteTitle => 'Delete Memory';

  @override
  String confirmDeleteMemory(String title) {
    return 'Are you sure you want to delete \"$title\"? This action cannot be undone.';
  }

  @override
  String get deleteMemorySuccess => 'Delete successful';

  @override
  String get deleteMemoryFailed => 'Delete failed';

  @override
  String memorySavedWithAI(int count) {
    return 'Memory saved, AI generated title and $count tags';
  }

  @override
  String saveFailedWithError(String error) {
    return 'Save failed: $error';
  }

  @override
  String get deleteTooltip => 'Delete';

  @override
  String get sectionsnackbar => '';

  @override
  String sharedTextMessagesCount(int count) {
    return 'Shared $count text messages';
  }

  @override
  String sharedFilesAndText(int fileCount, int textCount) {
    return 'Shared $fileCount files and $textCount text messages';
  }

  @override
  String andTextMessages(int count) {
    return ' and $count text messages';
  }

  @override
  String batchShareFailedWithError(String error) {
    return 'Batch share failed: $error';
  }

  @override
  String copiedMessagesToClipboard(int count) {
    return 'Copied $count messages to clipboard';
  }

  @override
  String messagesAddedToInputBox(int count) {
    return '$count message contents added to input box';
  }

  @override
  String favoritedMessagesCount(int successCount, int totalCount) {
    return 'Favorited $successCount/$totalCount messages';
  }

  @override
  String recalledMessagesCount(int count) {
    return 'Recalled $count messages';
  }

  @override
  String batchRecallFailedWithError(String error) {
    return 'Batch recall failed: $error';
  }

  @override
  String get forceClearedDedupRecords =>
      'Force cleared dedup records and restarted WebSocket listening';

  @override
  String getDebugInfoFailedWithError(String error) {
    return 'Failed to get debug info: $error';
  }

  @override
  String get textCanBeDragSelected =>
      'You can directly drag to select text content';

  @override
  String get allContentCopiedToClipboard => 'All content copied to clipboard';

  @override
  String get messageContentAddedToInput => 'Message content added to input box';

  @override
  String get featureOnlyAvailableOnMobile =>
      'This feature is only available on mobile';

  @override
  String fileDownloadFailedWithError(String error) {
    return 'File download failed: $error';
  }

  @override
  String get fileUrlNotExistsCannotDownload =>
      'File URL does not exist, cannot download';

  @override
  String get fileLocationOpened => 'File location opened';

  @override
  String get filePathCopiedToClipboard => 'File path copied to clipboard';

  @override
  String get fileLinkCopiedToClipboard => 'File link copied to clipboard';

  @override
  String get sectionmisc => '';

  @override
  String get sectionauth => '';

  @override
  String get loggingOut => 'Logging out...';

  @override
  String get logoutSuccessMessage => 'Successfully logged out';

  @override
  String get logoutError => 'Error occurred during logout';

  @override
  String logoutFailedWithError(String error) {
    return 'Logout failed: $error';
  }

  @override
  String get loginStatusInvalid => 'Login status has expired';

  @override
  String get logoutFailedTitle => 'Logout Failed';

  @override
  String get logoutFailedContent =>
      'Logout failed, you can choose to force logout or retry.';

  @override
  String get forceLogout => 'Force Logout';

  @override
  String get sectiongroup => '';

  @override
  String get createNewGroup => 'Create New Group';

  @override
  String groupCreatedSuccess(String name) {
    return 'Group \"$name\" created successfully';
  }

  @override
  String get create => 'Create';

  @override
  String get sectionconnection => '';

  @override
  String onlineStatus(int online, int total) {
    return '$online/$total online';
  }

  @override
  String get networkNormal => 'Network Normal';

  @override
  String get networkLimited => 'Network Limited';

  @override
  String get networkUnavailable => 'Network Unavailable';

  @override
  String get checking => 'Checking';

  @override
  String get sendFileFailed => 'Send file failed';

  @override
  String get noFilesToSend => 'No files to send';

  @override
  String get batchRecall => 'Batch Recall';

  @override
  String get recall => 'Recall';

  @override
  String get clearDeduplicationRecords => 'Clear deduplication records';

  @override
  String get cancelUpload => 'Cancel Upload';

  @override
  String get cancelDownload => 'Cancel Download';

  @override
  String confirmCancelTransfer(String action) {
    return 'Are you sure you want to cancel $action this file?';
  }

  @override
  String get continueTransfer => 'Continue Transfer';

  @override
  String get confirmCancel => 'Confirm cancel';

  @override
  String transferCancelled(String action) {
    return '$action cancelled';
  }

  @override
  String get preparingDownload => 'Preparing download';

  @override
  String fileNotExists(int index) {
    return 'File $index does not exist';
  }

  @override
  String get file => 'File';

  @override
  String get fileDownloadFailed => 'File download failed';

  @override
  String get fileNotExistsOrExpired => 'File does not exist or has expired';

  @override
  String get noPermissionToDownload => 'No permission to download this file';

  @override
  String get imageFile => 'Image file';

  @override
  String get videoFile => 'Video file';

  @override
  String get documentFile => 'Document file';

  @override
  String get audioFile => 'Audio file';

  @override
  String get selectFileType => 'Select file type';

  @override
  String get selectFileTypeMultiple =>
      'Select file type (multiple files can be sent directly)';

  @override
  String get image => 'Image';

  @override
  String get video => 'Video';

  @override
  String get document => 'Document';

  @override
  String get audio => 'Audio';

  @override
  String get canDragToSelectText => 'You can drag to select text content';

  @override
  String get recallMessage => 'Recall message';

  @override
  String get addToFavoritesFailed => 'Failed to add to favorites';

  @override
  String get removeFromFavoritesFailed => 'Failed to remove from favorites';

  @override
  String get jumpedToOriginal => 'Jumped to original message';

  @override
  String get gallery => 'Gallery';

  @override
  String get documents => 'Documents';

  @override
  String get saveFailed => 'Save failed';

  @override
  String get textShared => 'Text shared';

  @override
  String get fileNotAvailableAndNoTextToShare =>
      'File not available and no text content to share';

  @override
  String get messageRecalledText => '[This message has been recalled]';

  @override
  String get cannotOpenFileLocation => 'Cannot open file location';

  @override
  String get copyFilePathFailed => 'Failed to copy file path';

  @override
  String get copyFileLinkFailed => 'Failed to copy file link';

  @override
  String get desktopVideoNoValidSource => 'Desktop: No valid video source';

  @override
  String get mobileVideoNoValidSource => 'Mobile: No valid video source';

  @override
  String get desktopVideo => 'Desktop video';

  @override
  String get sectionchatui => '';

  @override
  String get continuedTransfer => 'Continue transfer';

  @override
  String get sectionchatmessages => '';

  @override
  String get batchRecallReason => 'Batch recall';

  @override
  String get batchDeleteReason => 'Batch delete';

  @override
  String get confirmCancelUpload =>
      'Are you sure you want to cancel uploading this file?';

  @override
  String get confirmCancelDownload =>
      'Are you sure you want to cancel downloading this file?';

  @override
  String get uploadCancelled => 'Upload cancelled';

  @override
  String get downloadCancelled => 'Download cancelled';

  @override
  String get favoritesFailed => 'Failed to add to favorites';

  @override
  String get fileUnavailableNoText =>
      'File unavailable and no text content to share';

  @override
  String get filePathCopied => 'File path copied to clipboard';

  @override
  String get fileLinkCopied => 'File link copied to clipboard';

  @override
  String get saveButton => 'Save';

  @override
  String get titleLabel => 'Title';

  @override
  String get titleHint => 'Enter title';

  @override
  String get contentLabel => 'Content';

  @override
  String get note => 'Note';

  @override
  String get otherInfo => 'Other Information';

  @override
  String get expenseItem => 'Expense Item';

  @override
  String get amount => 'Amount';

  @override
  String get type => 'Type';

  @override
  String get expense => 'Expense';

  @override
  String get income => 'Income';

  @override
  String get category => 'Category';

  @override
  String get date => 'Date';

  @override
  String get detailedDescription => 'Detailed Description';

  @override
  String get scheduleTitle => 'Schedule Title';

  @override
  String get startTime => 'Start Time';

  @override
  String get location => 'Location';

  @override
  String get details => 'Details';

  @override
  String get advanceReminder => 'Advance Reminder';

  @override
  String get noReminder => 'No reminder';

  @override
  String get task => 'Task';

  @override
  String get whatToDo => 'What to do';

  @override
  String get detailedTaskDescription => 'Detailed Description';

  @override
  String get priority => 'Priority';

  @override
  String get low => 'Low';

  @override
  String get medium => 'Medium';

  @override
  String get high => 'High';

  @override
  String get websiteOrLinkName => 'Website or link name';

  @override
  String get linkPurpose => 'The purpose or content of this link';

  @override
  String get fileDescription => 'File description';

  @override
  String get fileExplanation => 'File explanation';

  @override
  String get selectDate => 'Select Date';

  @override
  String get selectTime => 'Select Time';

  @override
  String get clickToSelectFile => 'Click to select file';

  @override
  String get addAccountPassword => 'Add Account Password';

  @override
  String get recordExpense => 'Record Expense';

  @override
  String get createSchedule => 'Create Schedule';

  @override
  String get addTodo => 'Add Todo';

  @override
  String get saveLink => 'Save Link';

  @override
  String get saveImage => 'Save Image';

  @override
  String get saveVideo => 'Save Video';

  @override
  String get saveDocument => 'Save Document';

  @override
  String get writeNote => 'Write Note';

  @override
  String get pleaseSelectFile => 'Please select file';

  @override
  String get saveSuccess => 'Save successful';

  @override
  String get sectioninput => '';

  @override
  String get inputMessageHintDesktop =>
      'Enter message or drag files...(Enter to send)';

  @override
  String get inputMessageHintMobile => 'Enter message or drag files...';

  @override
  String get addDescriptionText => 'Add description text...(Enter to send)';

  @override
  String get sectionmenu => '';

  @override
  String get sideMenu => 'Side Menu';

  @override
  String get appSettings => 'App Settings';

  @override
  String get networkDiagnostics => 'Network Diagnostics';

  @override
  String get currentDevice => 'Current Device';

  @override
  String get systemInfo => 'System Information';

  @override
  String get noGroup => 'No Group';

  @override
  String get sectionpriority => '';

  @override
  String get highPriority => 'High Priority';

  @override
  String get mediumPriority => 'Medium Priority';

  @override
  String get lowPriority => 'Low Priority';

  @override
  String get justNow => 'Just now';

  @override
  String get sectionaccount => '';

  @override
  String accountInfo(String username, String website) {
    return 'Account: $username • Website: $website';
  }

  @override
  String get sectionforms => '';

  @override
  String get loginAccountHint => 'Login account';

  @override
  String get passwordHint => 'Login password';

  @override
  String get notesLabel => 'Notes';

  @override
  String get otherInfoHint => 'Other information';

  @override
  String get expenseItemHint => 'e.g.: Lunch, Shopping';

  @override
  String get amountHint => '0.00';

  @override
  String get typeLabel => 'Type';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categoryHint => 'e.g.: Food, Transportation';

  @override
  String get dateLabel => 'Date';

  @override
  String get detailsHint => 'Detailed description';

  @override
  String get scheduleTitleHint => 'Meeting, appointment, etc.';

  @override
  String get startTimeLabel => 'Start Time';

  @override
  String get endTimeOptional => 'End Time (Optional)';

  @override
  String get locationLabel => 'Location';

  @override
  String get locationHint => 'Meeting room, restaurant, etc.';

  @override
  String get detailsLabel => 'Details';

  @override
  String get meetingDetailsHint => 'Meeting content, notes';

  @override
  String get minutes5Before => '5 minutes before';

  @override
  String get minutes15Before => '15 minutes before';

  @override
  String get minutes30Before => '30 minutes before';

  @override
  String get hour1Before => '1 hour before';

  @override
  String get taskLabel => 'Task';

  @override
  String get taskRequirementsHint => 'Specific requirements, notes';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get dueDateOptional => 'Due Date (Optional)';

  @override
  String get websiteLinkName => 'Website or link name';

  @override
  String get urlLink => 'URL Link';

  @override
  String get sectionshare => '';

  @override
  String get confirmShare => 'Confirm Share';

  @override
  String get textSent => 'Text sent';

  @override
  String get fileSent => 'File sent';

  @override
  String filesSent(int count) {
    return '$count files sent';
  }

  @override
  String get sectionmissing => '';

  @override
  String get sectionmemoryforms => '';

  @override
  String get usernameEmailLabel => 'Username/Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get expenseItemLabel => 'Expense Item';

  @override
  String get amountLabel => 'Amount';

  @override
  String get notesHint => 'Detailed description';

  @override
  String get scheduleTitleLabel => 'Schedule Title';

  @override
  String get endTimeOptionalLabel => 'End Time (Optional)';

  @override
  String get advanceReminderLabel => 'Advance Reminder';

  @override
  String get whatToDoHint => 'What to do';

  @override
  String get detailedDescriptionLabel => 'Detailed Description';

  @override
  String get dueDateOptionalLabel => 'Due Date (Optional)';

  @override
  String get urlLinkLabel => 'URL Link';

  @override
  String get linkDescriptionLabel => 'Description';

  @override
  String get linkPurposeHint => 'The purpose or content of this link';

  @override
  String get fileLabel => 'File *';

  @override
  String pleaseEnter(String field) {
    return 'Please enter $field';
  }

  @override
  String get completed => 'Completed';

  @override
  String get addTag => 'Add Tag';

  @override
  String get addTagLabel => 'Add Tag';

  @override
  String get enterTagName => 'Enter tag name';

  @override
  String get aiGenerate => 'AI Generate';

  @override
  String get generating => 'Generating...';

  @override
  String aiGeneratedTags(int count) {
    return 'AI generated $count new tags';
  }

  @override
  String generateTagsFailed(String error) {
    return 'Generate tags failed: $error';
  }

  @override
  String get updateSuccess => 'Update successful';

  @override
  String updateFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String editMemoryType(String type) {
    return 'Edit $type';
  }

  @override
  String get enterTitle => 'Enter title';

  @override
  String get enterContent => 'Enter content';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get processingShareContent => 'Processing shared content...';

  @override
  String get shareSuccess => '✅ Share successful!';

  @override
  String get shareFailed => '❌ Share failed';

  @override
  String get shareException => '❌ Share exception';

  @override
  String get allContentSentToGroup =>
      'All content has been sent to current group';

  @override
  String get pleaseTryAgainLater => 'Please try again later';

  @override
  String processingError(String error) {
    return 'Processing error: $error';
  }

  @override
  String get allFilesSentComplete => 'All files sent successfully';

  @override
  String get partialFilesSentComplete => 'Some files sent successfully';

  @override
  String get allFilesSendFailed => 'All files failed to send';

  @override
  String get fileSentSuccess => 'File sent successfully!';

  @override
  String textSharedCount(int count) {
    return 'Shared $count text messages';
  }

  @override
  String get messageShare => 'Send To Myself - Message Share';

  @override
  String fileShared(String fileName) {
    return 'File $fileName has been shared';
  }

  @override
  String get fileUnavailableSharedText =>
      'File unavailable, shared text content instead';

  @override
  String get resolvingServerDomain => '🔍 Resolving server domain...';

  @override
  String serverDnsSuccess(String address) {
    return '✅ Server DNS resolution successful: $address';
  }

  @override
  String get serverDnsFailed => '❌ Server DNS resolution failed: no result';

  @override
  String serverDnsError(String error) {
    return '❌ Server DNS resolution failed: $error';
  }

  @override
  String get testingServerConnection => '🔍 Testing server connection...';

  @override
  String get serverConnectionSuccess => '✅ Server connection successful';

  @override
  String serverConnectionFailed(String error) {
    return '❌ Server connection failed: $error';
  }

  @override
  String get startingWebSocketTest =>
      '🧪 Starting WebSocket connection test...';

  @override
  String currentConnectionStatus(String status) {
    return '📊 Current connection status: $status';
  }

  @override
  String get sendingTestPing => '📡 Sending test ping...';

  @override
  String get webSocketNotConnected =>
      '⚠️ WebSocket not connected, unable to send test message';

  @override
  String get executingForceReconnect => '🔄 Executing force reconnect...';

  @override
  String get stopPingTest => '⏹️ Stop Ping test';

  @override
  String get startPingTest => '🏓 Start Ping test (every 5 seconds)';

  @override
  String get sendingPing => '🏓 Sending test ping';

  @override
  String get connectionDisconnectedPausePing =>
      '⚠️ Connection disconnected, pausing ping test';

  @override
  String get logCleared => '🧹 Log cleared';

  @override
  String get logCopiedToClipboard => 'Log copied to clipboard';

  @override
  String get noResult => 'no result';

  @override
  String get sectionwidgets => '';

  @override
  String get logoutErrorMessage => 'Error occurred during logout';

  @override
  String get loginStatusExpired => 'Login status has expired';

  @override
  String get logoutFailedMessage =>
      'Logout failed, you can choose to force logout or retry.';

  @override
  String get preparingToSendFiles => 'Preparing to send files...';

  @override
  String sendingFileCount(int current) {
    return 'Sending file $current...';
  }

  @override
  String sendingFileProgress(int current, String sizeMB) {
    return 'Sending file $current (${sizeMB}MB)';
  }

  @override
  String retryingSendFile(int current) {
    return 'Retrying to send file $current';
  }

  @override
  String fileSendSuccess(int current) {
    return '✅ File $current sent successfully';
  }

  @override
  String filesCompleted(int success, int total) {
    return 'Completed $success/$total files';
  }

  @override
  String get waitingForServerProcessing => 'Waiting for server processing...';

  @override
  String get ensureFileFullyUploaded => 'Ensuring file is fully uploaded';

  @override
  String fileSendFailed(int current) {
    return '❌ File $current failed to send';
  }

  @override
  String maxRetriesReached(String fileName, int maxRetries) {
    return '$fileName failed after $maxRetries retries';
  }

  @override
  String fileSendException(int current) {
    return '❌ File $current send exception';
  }

  @override
  String sendErrorMessage(String fileName, String error) {
    return '$fileName error during send: $error';
  }

  @override
  String fileDataIncomplete(int current) {
    return '❌ File $current data exception';
  }

  @override
  String get fileInfoIncompleteMessage => 'File information incomplete';

  @override
  String allFilesSentToGroup(int count) {
    return 'Sent $count files to current group';
  }

  @override
  String successCountFiles(int success, int total) {
    return 'Success: $success/$total files';
  }

  @override
  String get noFilesToSendError => '❌ No files to send';

  @override
  String get shareDataEmpty => 'Share data is empty';

  @override
  String get sendingFile => 'Sending file...';

  @override
  String fileUploadFailed(String fileName) {
    return '$fileName upload failed';
  }

  @override
  String fileSentToGroup(String fileName) {
    return '$fileName sent to group';
  }

  @override
  String get unsupportedShareType => '❌ Unsupported share type';

  @override
  String get cannotHandleContentType => 'Cannot handle this content type';

  @override
  String get textSendSuccess => '✅ Text sent successfully!';

  @override
  String get contentSentToGroup => 'Content sent to group';

  @override
  String get textSendFailed => '❌ Text send failed';

  @override
  String get unknownFileName => 'Unknown file name';

  @override
  String filePathInvalid(String fileName) {
    return '$fileName invalid file path';
  }

  @override
  String retryAttempt(int retry, String fileName) {
    return 'Retry $retry - $fileName';
  }

  @override
  String get monthlyPlan => 'Monthly';

  @override
  String get yearlyPlan => 'Yearly';

  @override
  String pricePerMonth(String currencySymbol, String price) {
    return '$currencySymbol$price/month';
  }

  @override
  String pricePerYear(String currencySymbol, String price) {
    return '$currencySymbol$price/year';
  }

  @override
  String get freePlan => 'Free';

  @override
  String get freePlanDescription => 'For personal use';

  @override
  String get basicPlan => 'Basic';

  @override
  String get basicPlanDescription => 'For small teams';

  @override
  String get proPlan => 'Pro';

  @override
  String get proPlanDescription => 'For teams';

  @override
  String get enterprisePlan => 'Enterprise';

  @override
  String get enterprisePlanDescription => 'For large enterprises';

  @override
  String get feature2DeviceGroup => '2 device groups';

  @override
  String get featureBasicFileTransfer => 'Basic file transfer';

  @override
  String get featureTextMessage => 'Text messages';

  @override
  String get featureImageTransfer => 'Image transfer';

  @override
  String get feature5DeviceGroup => '5 device groups';

  @override
  String get featureUnlimitedFileTransfer => 'Unlimited file transfer';

  @override
  String get featureVideoTransfer => 'Video transfer';

  @override
  String get featureMemoryFunction => 'Memory function';

  @override
  String get featurePrioritySupport => 'Priority support';

  @override
  String get feature10DeviceGroup => '10 device groups';

  @override
  String get featureAdvancedMemory => 'Advanced memory';

  @override
  String get featureDataSyncBackup => 'Data sync & backup';

  @override
  String get featureDedicatedSupport => 'Dedicated support';

  @override
  String get featureTeamManagement => 'Team management';

  @override
  String get featureUnlimitedDeviceGroup => 'Unlimited device groups';

  @override
  String get featureAdvancedAnalytics => 'Advanced analytics';

  @override
  String get featureCustomIntegration => 'Custom integration';

  @override
  String get subscriptionPricingTitle => 'Subscription Pricing';

  @override
  String get subscriptionPricingSubtitle =>
      'Choose the plan that\'s right for you';

  @override
  String get popularPlan => 'Popular';

  @override
  String get mostPopular => 'Most Popular';

  @override
  String get recommended => 'Recommended';

  @override
  String get yearlyDiscount => 'Yearly discount';

  @override
  String savePercentage(int percentage) {
    return 'Save $percentage%';
  }

  @override
  String get priceVariesByRegion => 'Subscription prices may vary by region';

  @override
  String get pricingNote => 'Prices are automatically adjusted for your region';

  @override
  String get currencyDisclaimer => 'Prices shown in local currency';

  @override
  String get subscribeTo => 'Subscribe to';

  @override
  String get subscriptionStatus => 'Subscription Status';

  @override
  String get currentPlan => 'Current Plan';

  @override
  String get upgradeToUnlock => 'Upgrade to unlock more features';

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get subscriptionTerms =>
      'By subscribing, you agree to our Terms of Service and Privacy Policy';

  @override
  String get purchaseSuccess => 'Purchase successful!';

  @override
  String get purchaseFailed => 'Purchase failed';

  @override
  String get purchaseRestored => 'Purchase restored';

  @override
  String get noSubscriptionFound => 'No subscription found';

  @override
  String get subscriptionExpired => 'Subscription expired';

  @override
  String get subscriptionActive => 'Subscription active';

  @override
  String get subscriptionCancelled => 'Subscription cancelled';

  @override
  String get subscriptionPending => 'Subscription pending';

  @override
  String get deviceLimitReached => 'Device limit reached';

  @override
  String get upgradeRequired => 'Upgrade required';

  @override
  String get upgradeToAddMore => 'Upgrade to add more devices';

  @override
  String freeTrialDaysLeft(int days) {
    return '$days days left in free trial';
  }

  @override
  String get sectionscanqr => '';

  @override
  String get scanDeviceJoinOtherDevices => 'Let other devices scan to join';

  @override
  String get groupPrefix => 'Group: ';

  @override
  String get joinCode => 'Join Code';

  @override
  String get qrCodeGenerationFailed => 'QR code generation failed';

  @override
  String get otherDevicesCanScanQRDescription =>
      'Other devices can scan this QR code or manually enter the join code to join your device group';

  @override
  String get cameraUnavailableSwitchedToInput =>
      'Camera unavailable, switched to manual input mode';

  @override
  String get desktopCameraUnstableTip =>
      'Desktop camera scanning may be unstable, manual input mode is recommended';

  @override
  String get joinGroupSuccessExclamation => 'Successfully joined group!';

  @override
  String get joinGroupFailedGeneric => 'Failed to join group';

  @override
  String get pleaseEnterInviteCode => 'Please enter invite code';

  @override
  String get inviteCodeLengthError =>
      'Invite code must be 4-20 characters long';

  @override
  String operationFailed(String error) {
    return 'Operation failed: $error';
  }

  @override
  String get generateDeviceJoinCode => 'Generate device join code';

  @override
  String get scanQRToJoinDeviceGroup =>
      'Scan QR code to join this device group';

  @override
  String get subscriptionManagement => 'Subscription Management';

  @override
  String get currentSubscription => 'Current Subscription';

  @override
  String supportXDeviceGroups(String count) {
    return 'Supports $count device groups';
  }

  @override
  String get versionNumber => 'Version';

  @override
  String get expired => 'Expired';

  @override
  String get justActive => 'Just active';

  @override
  String expiresInMinutes(int minutes) {
    return 'Expires in $minutes minutes';
  }

  @override
  String expiresInHoursAndMinutes(int hours, int minutes) {
    return 'Expires in ${hours}h ${minutes}m';
  }

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String monthDay(int month, int day) {
    return '$month/$day';
  }

  @override
  String yearMonthDay(int month, int day, int year) {
    return '$month/$day/$year';
  }

  @override
  String get deviceInformation => 'Device Information';

  @override
  String get applicationName => 'Application Name';

  @override
  String get applicationDescription => 'Application Description';

  @override
  String get appDescriptionText =>
      'Cross-device file sharing and message memory assistant';

  @override
  String get logoutCurrentDeviceDescription => 'Log out of current device';

  @override
  String get confirmLogoutTitle => 'Confirm Logout';

  @override
  String get confirmLogoutContent =>
      'Are you sure you want to log out of the current device?';
}
