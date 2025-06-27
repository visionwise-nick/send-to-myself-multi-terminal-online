// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Send To Myself';

  @override
  String get appDescription => 'Cross-device file sharing and message memory assistant';

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
  String get deleteMessageConfirm => 'Are you sure you want to delete this message?';

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
  String get groupNameHint => 'Enter group name';

  @override
  String get groupDescription => 'Group Description';

  @override
  String get groupDescriptionHint => 'Enter group description';

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
  String get groupDeleteConfirm => 'Are you sure you want to delete this group?';

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
}
