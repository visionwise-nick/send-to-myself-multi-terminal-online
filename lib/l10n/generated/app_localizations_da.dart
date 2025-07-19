// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

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
  String monthDay(int month, int day) {
    return '$month/$day';
  }

  @override
  String expiresInHoursAndMinutes(int hours, int minutes) {
    return 'Expires in ${hours}h ${minutes}m';
  }

  @override
  String expiresInMinutes(int minutes) {
    return 'Expires in ${minutes}m';
  }

  @override
  String get expired => 'Expired';

  @override
  String yearMonthDay(int year, int month, int day) {
    return '$year/$month/$day';
  }

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
  String get joinGroupSuccess => 'Joined group successfully';

  @override
  String get joinGroupFailed => 'Failed to join group';

  @override
  String get joinFailed => 'Join failed';

  @override
  String get enterJoinCode => 'Enter Join Code';

  @override
  String get joinCodeHint => '8-digit join code';

  @override
  String get join => 'Join';

  @override
  String get scanQRCode => 'Scan QR Code';

  @override
  String get manualInput => 'Manual Input';

  @override
  String get flashlight => 'Flashlight';

  @override
  String get appSlogan => 'Your personal file transfer assistant';

  @override
  String get myFiles => 'My Files';

  @override
  String get filesFeatureComingSoon => 'Files Feature Coming Soon';

  @override
  String get stayTuned => 'Stay tuned!';

  @override
  String get noDeviceGroups => 'No Device Groups';

  @override
  String get scanQRToJoin => 'Scan QR code to join a group';

  @override
  String get myDeviceGroups => 'My Device Groups';

  @override
  String get unnamedGroup => 'Unnamed Group';

  @override
  String deviceCount(Object count) {
    return '$count devices';
  }

  @override
  String get youAreOwner => 'You are the owner';

  @override
  String get member => 'Member';

  @override
  String createdOn(String date) {
    return 'Created on $date';
  }

  @override
  String get unknownDate => 'Unknown';

  @override
  String memoriesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Memories',
      one: '1 Memory',
      zero: 'No Memories',
    );
    return '$_temp0';
  }

  @override
  String get searchMemories => 'Search memories...';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

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
  String get noMemories => 'No memories yet';

  @override
  String get noMemoriesDesc => 'Create your first memory to get started!';

  @override
  String get createMemory => 'Create Memory';

  @override
  String get quickAdd => 'Quick Add';

  @override
  String get memoryDeleteTitle => 'Delete Memory';

  @override
  String get confirmDeleteMemory =>
      'Are you sure you want to delete this memory?';

  @override
  String get deleteMemorySuccess => 'Memory deleted successfully';

  @override
  String get deleteMemoryFailed => 'Failed to delete memory';

  @override
  String dateFormat(Object day, Object month) {
    return '$month/$day';
  }

  @override
  String get notes => 'Notes';

  @override
  String get passwords => 'Passwords';

  @override
  String get contacts => 'Contacts';

  @override
  String get quickTexts => 'Quick Texts';

  @override
  String get myMemory => 'My Memory';

  @override
  String groupMemory(Object groupName) {
    return '$groupName\'s Memory';
  }

  @override
  String totalItemsSaved(Object count) {
    return '$count items saved';
  }

  @override
  String get selectGroupToView => 'Select a group to view memories';

  @override
  String get groupStorage => 'Group Storage';

  @override
  String get localStory => 'Local Storage';

  @override
  String get noNotes => 'No Notes Yet';

  @override
  String get recordImportantInfo => 'Record important information and ideas';

  @override
  String get noPasswords => 'No Passwords Yet';

  @override
  String get securelyStore => 'Securely store your account passwords';

  @override
  String get noContacts => 'No Contacts Yet';

  @override
  String get saveImportantContacts => 'Save important contact information';

  @override
  String get noQuickTexts => 'No Quick Texts Yet';

  @override
  String get saveCommonTexts => 'Save common texts and templates';

  @override
  String get addNote => 'Add Note';

  @override
  String get editNote => 'Edit Note';

  @override
  String get title => 'Title';

  @override
  String get content => 'Content';

  @override
  String get add => 'Add';

  @override
  String get addPassword => 'Add Password';

  @override
  String get editPassword => 'Edit Password';

  @override
  String get site => 'Site/App';

  @override
  String get username => 'Username/Email';

  @override
  String get password => 'Password';

  @override
  String get addContact => 'Add Contact';

  @override
  String get editContact => 'Edit Contact';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get email => 'Email';

  @override
  String get addQuickText => 'Add Quick Text';

  @override
  String get editQuickText => 'Edit Quick Text';

  @override
  String get saveButton => 'Save';

  @override
  String get titleLabel => 'Title';

  @override
  String get titleHint => 'Enter a title for your memory';

  @override
  String get contentLabel => 'Content';

  @override
  String get writeYourThoughts => 'Write down your thoughts...';

  @override
  String get websiteAppName => 'Website/App Name';

  @override
  String get websiteAppNameHint => 'e.g., Google, Facebook';

  @override
  String get websiteAddress => 'Website Address';

  @override
  String get websiteAddressHint => 'e.g., https://www.google.com';

  @override
  String get usernameEmailLabel => 'Username/Email';

  @override
  String get loginAccountHint => 'Your login account';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Your login password';

  @override
  String get notesLabel => 'Notes';

  @override
  String get otherInfoHint => 'Other information, such as security questions';

  @override
  String get expenseItemLabel => 'Expense Item';

  @override
  String get expenseItemHint => 'e.g., Coffee, Lunch';

  @override
  String get amountLabel => 'Amount';

  @override
  String get amountHint => 'e.g., 25.50';

  @override
  String get typeLabel => 'Type';

  @override
  String get expense => 'Expense';

  @override
  String get income => 'Income';

  @override
  String get connectionStatusChanged => 'Connection status changed';

  @override
  String get networkStatusChanged => 'Network status changed';

  @override
  String get errorOccurred => 'Error occurred';

  @override
  String get messageReceived => 'Message received';

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
  String get preparingToSendFiles => 'Preparing to send files...';

  @override
  String get shareSuccess => 'Share Successful';

  @override
  String get shareFailed => 'Share Failed';

  @override
  String get shareException => 'Share Exception';

  @override
  String get contentSentToGroup => 'Content has been sent to the current group';

  @override
  String get pleaseTryAgainLater => 'Please try again later';

  @override
  String get processing => 'Processing';

  @override
  String get waitingForApp => 'Waiting for app to start...';

  @override
  String get appSlowToStart =>
      'App is slow to start, trying to process share...';

  @override
  String get tryAgainIfFailed => 'If it fails, please try sharing again';

  @override
  String get processingShare => 'Processing share...';

  @override
  String get subscriptionPricingTitle => 'Subscription & Pricing';

  @override
  String get subscriptionPricingSubtitle => 'Choose your plan';

  @override
  String get currentPlan => 'Current Plan';

  @override
  String validUntil(Object date) {
    return 'Valid until: $date';
  }

  @override
  String get mostPopular => 'Most Popular';

  @override
  String get monthlyPlan => 'Monthly Plan';

  @override
  String get yearlyPlan => 'Yearly Plan';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get priceVariesByRegion => 'Price may vary by region.';

  @override
  String get purchaseSuccess => 'Purchase Successful';

  @override
  String get purchaseFailed => 'Purchase Failed';

  @override
  String get freePlan => 'Free Plan';

  @override
  String deviceLimit(Object count) {
    return 'Up to $count devices';
  }

  @override
  String get chooseYourPlan => 'Choose Your Plan';

  @override
  String get basicPlan => 'Basic Plan';

  @override
  String get proPlan => 'Pro Plan';

  @override
  String get enterprisePlan => 'Enterprise Plan';

  @override
  String get freePlanDescription => 'For personal use';

  @override
  String get basicPlanDescription => 'For small teams';

  @override
  String get proPlanDescription => 'For growing businesses';

  @override
  String get enterprisePlanDescription => 'For large organizations';

  @override
  String get feature2DeviceGroup => 'Up to 2 devices in a group';

  @override
  String get featureBasicFileTransfer => 'Basic file transfer (up to 100MB)';

  @override
  String get featureTextMessage => 'Text messages';

  @override
  String get featureImageTransfer => 'Image transfer';

  @override
  String get feature5DeviceGroup => 'Up to 5 devices in a group';

  @override
  String get featureUnlimitedFileTransfer =>
      'Unlimited file transfer (up to 1GB)';

  @override
  String get featureVideoTransfer => 'Video transfer';

  @override
  String get cameraUnavailableSwitchedToInput =>
      'Camera unavailable, switched to input mode.';

  @override
  String get desktopCameraUnstableTip =>
      'Desktop camera scanning may be unstable, it is recommended to use input mode.';

  @override
  String get joinGroupSuccessExclamation => 'Joined group successfully!';

  @override
  String get joinGroupFailedGeneric => 'Failed to join group.';

  @override
  String operationFailed(Object error) {
    return 'Operation failed: $error';
  }

  @override
  String get pleaseEnterInviteCode => 'Please enter the invite code.';

  @override
  String get inviteCodeLengthError => 'Invite code length error.';

  @override
  String get loadDevicesFailed => 'Failed to load devices';

  @override
  String get createJoinCodeFailed => 'Failed to create join code';

  @override
  String get leaveGroupSuccess => 'Left group successfully';

  @override
  String get leaveGroupFailed => 'Failed to leave group';

  @override
  String get groupInfoUpdated => 'Group info updated';

  @override
  String get refreshFailed => 'Refresh failed';

  @override
  String get deviceGroup => 'Device Group';

  @override
  String get leaveGroup => 'Leave Group';

  @override
  String get generating => 'Generating...';

  @override
  String get generateDeviceJoinCode => 'Generate Device Join Code';

  @override
  String get scanQRToJoinDeviceGroup =>
      'Scan QR code to join this device group';

  @override
  String get joinCode => 'Join Code';

  @override
  String get copyJoinCode => 'Copy Join Code';

  @override
  String get joinCodeCopied => 'Join code copied to clipboard';

  @override
  String expiresAt(Object date) {
    return 'Expires at: $date';
  }

  @override
  String get deviceList => 'Device List';

  @override
  String get noDevicesToDisplay => 'No devices to display';

  @override
  String get unnamedDevice => 'Unnamed Device';

  @override
  String get currentDevice => 'Current Device';

  @override
  String get groupOwner => 'Group Owner';

  @override
  String get unknownDevice => 'Unknown Device';

  @override
  String get unknownPlatform => 'Unknown Platform';

  @override
  String get removeDevice => 'Remove Device';

  @override
  String get confirmLeaveGroup =>
      'Are you sure you want to leave this device group?';

  @override
  String get confirmRemoveDevice =>
      'Are you sure you want to remove the device';

  @override
  String get removeDeviceFeatureComingSoon =>
      'Remove device feature coming soon';

  @override
  String get unknown => 'Unknown';

  @override
  String get loadGroupInfoFailed => 'Failed to load group info';

  @override
  String get renameGroup => 'Rename Group';

  @override
  String get groupName => 'Group Name';

  @override
  String get enterNewGroupName => 'Enter a new group name';

  @override
  String get groupNameHint => 'Group name cannot be empty';

  @override
  String get renamingGroup => 'Renaming group...';

  @override
  String get groupRenameSuccess => 'Group renamed successfully';

  @override
  String get groupRenameFailed => 'Failed to rename group';

  @override
  String get renameFailed => 'Rename failed';

  @override
  String get groupLeaveConfirm => 'Are you sure you want to leave this group?';

  @override
  String get editMemory => 'Edit Memory';

  @override
  String get enterTitle => 'Enter title';

  @override
  String get enterContent => 'Enter content';

  @override
  String get tags => 'Tags';

  @override
  String get addTag => 'Add Tag';

  @override
  String get generateTags => 'Generate Tags';

  @override
  String get generatingTags => 'Generating tags...';

  @override
  String get https => 'https://...';

  @override
  String get usernameEmail => 'Username/Email';

  @override
  String get loginAccount => 'Login account';

  @override
  String get loginPassword => 'Login password';

  @override
  String get otherInformation => 'Other information';

  @override
  String get amount => 'Amount';

  @override
  String get zeroZero => '0.00';

  @override
  String get type => 'Type';

  @override
  String get category => 'Category';

  @override
  String get eg => 'e.g.,';

  @override
  String get date => 'Date';

  @override
  String get detailedExplanation => 'Detailed explanation';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTimeOptional => 'End Time (Optional)';

  @override
  String get location => 'Location';

  @override
  String get conferenceRoomRestaurant => 'Conference room, restaurant, etc.';

  @override
  String get details => 'Details';

  @override
  String get meetingContentNotes => 'Meeting content, notes';

  @override
  String get reminder => 'Reminder';

  @override
  String get noReminder => 'No reminder';

  @override
  String get fiveMinutesBefore => '5 minutes before';

  @override
  String get fifteenMinutesBefore => '15 minutes before';

  @override
  String get thirtyMinutesBefore => '30 minutes before';

  @override
  String get oneHourBefore => '1 hour before';

  @override
  String get detailedDescription => 'Detailed Description';

  @override
  String get specificRequirementsNotes => 'Specific requirements, notes';

  @override
  String get priority => 'Priority';

  @override
  String get low => 'Low';

  @override
  String get medium => 'Medium';

  @override
  String get high => 'High';

  @override
  String get completed => 'Completed';

  @override
  String get dueDateOptional => 'Due Date (Optional)';

  @override
  String get urlLink => 'URL Link';

  @override
  String get description => 'Description';

  @override
  String get purposeOrContent => 'Purpose or content of this link';

  @override
  String get enterTagName => 'Enter tag name';

  @override
  String get selectDate => 'Select date';

  @override
  String get selectTime => 'Select time';

  @override
  String get updateSuccess => 'Update successful';

  @override
  String get updateFailed => 'Update failed';

  @override
  String get catering => 'Catering';

  @override
  String get transportation => 'Transportation';

  @override
  String get scanDeviceJoinOtherDevices => 'Scan with other devices to join';

  @override
  String get joinGroup => 'Join Group';

  @override
  String get expiresIn => 'Expires in';

  @override
  String get copied => 'Copied';

  @override
  String get noGroupInfo => 'No group info available';

  @override
  String get generateFailed => 'Failed to generate';

  @override
  String get deviceJoinCode => 'Device Join Code';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get generatingJoinCode => 'Generating join code...';

  @override
  String get groupPrefix => 'Group';

  @override
  String get copyright => '© 2023 Send To Myself';

  @override
  String get deviceInfo => 'Device Info';

  @override
  String get deviceName => 'Device Name';

  @override
  String get deviceType => 'Device Type';

  @override
  String get platform => 'Platform';

  @override
  String get deviceId => 'Device ID';

  @override
  String get appTheme => 'App Theme';

  @override
  String get defaultTheme => 'Default';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get enabled => 'Enabled';

  @override
  String get aboutApp => 'About App';

  @override
  String get sendFileFailed => 'Send file failed';

  @override
  String get noFilesToSend => 'No files to send';

  @override
  String get batchRecall => 'Batch Recall';

  @override
  String get recall => 'Recall';

  @override
  String get batchRecallReason => 'Recall messages';

  @override
  String get batchDelete => 'Batch Delete';

  @override
  String confirmBatchDelete(int count) {
    return 'Are you sure you want to delete $count messages?';
  }

  @override
  String get batchDeleteReason => 'Delete messages';

  @override
  String batchDeleteSuccess(int count) {
    return 'Successfully deleted $count messages';
  }

  @override
  String batchDeleteFailedWithError(String error) {
    return 'Batch delete failed: $error';
  }

  @override
  String get debugInfoTitle => 'Debug Info';

  @override
  String get permanentStorageDirectory => 'Permanent Storage Directory';

  @override
  String get storageUsage => 'Storage Usage';

  @override
  String get fileCacheStats => 'File Cache Stats';

  @override
  String get deduplicationDiagnostics => 'Deduplication Diagnostics';

  @override
  String get clearDeduplicationRecords => 'Clear Deduplication Records';

  @override
  String get startConversation => 'Start a new conversation';

  @override
  String get sendMessageOrFileToStart => 'Send a message or file to start';

  @override
  String get cancelUpload => 'Cancel Upload';

  @override
  String get cancelDownload => 'Cancel Download';

  @override
  String get confirmCancelUpload =>
      'Are you sure you want to cancel the upload?';

  @override
  String get confirmCancelDownload =>
      'Are you sure you want to cancel the download?';

  @override
  String get continueTransfer => 'Continue Transfer';

  @override
  String get confirmCancel => 'Confirm Cancel';

  @override
  String get uploadCancelled => 'Upload cancelled';

  @override
  String get downloadCancelled => 'Download cancelled';

  @override
  String get file => 'File';

  @override
  String get addDescriptionText => 'Add description';

  @override
  String get inputMessageHintDesktop =>
      'Input message, paste screenshot, or drag file here';

  @override
  String get inputMessageHintMobile => 'Input message';

  @override
  String get imageFile => 'Image File';

  @override
  String get videoFile => 'Video File';

  @override
  String get documentFile => 'Document File';

  @override
  String get audioFile => 'Audio File';

  @override
  String get selectFileType => 'Select file type';

  @override
  String get selectFileTypeMultiple => 'Select file type (multiple)';

  @override
  String get image => 'Image';

  @override
  String get video => 'Video';

  @override
  String get document => 'Document';

  @override
  String get audio => 'Audio';

  @override
  String get fileDownloadFailed => 'File download failed';

  @override
  String get fileNotExistsOrExpired => 'File does not exist or has expired';

  @override
  String get noPermissionToDownload => 'No permission to download';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get textCopiedToClipboard => 'Text copied to clipboard';

  @override
  String get canDragSelectText => 'You can drag to select text';

  @override
  String get allContentCopied => 'All content copied';

  @override
  String get recallMessage => 'Recall Message';

  @override
  String get deleteMessageTitle => 'Delete Message';

  @override
  String get confirmDeleteSingleMessage =>
      'Are you sure you want to delete this message?';

  @override
  String get messageContentAddedToInput => 'Message content added to input';

  @override
  String get confirmDeleteMessage =>
      'Are you sure you want to delete this message?';

  @override
  String get gallery => 'Gallery';

  @override
  String get documents => 'Documents';

  @override
  String get saveFailed => 'Save failed';

  @override
  String get messageShare => 'Message Share';

  @override
  String get textShared => 'Text shared';

  @override
  String get messageRecalledText => '[You recalled a message]';

  @override
  String get filePathCopied => 'File path copied';

  @override
  String get copyFilePathFailed => 'Copy file path failed';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categoryHint => 'e.g., Work, Personal';

  @override
  String get dateLabel => 'Date';

  @override
  String get notesHint => 'Add notes...';

  @override
  String get scheduleTitleLabel => 'Schedule Title';

  @override
  String get scheduleTitleHint => 'e.g., Team Meeting';

  @override
  String get startTimeLabel => 'Start Time';

  @override
  String get endTimeOptionalLabel => 'End Time (Optional)';

  @override
  String get locationLabel => 'Location';

  @override
  String get locationHint => 'e.g., Conference Room A';

  @override
  String get detailsLabel => 'Details';

  @override
  String get meetingDetailsHint => 'e.g., Agenda, Attendees';

  @override
  String get advanceReminderLabel => 'Advance Reminder';

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
  String get whatToDoHint => 'e.g., Buy groceries';

  @override
  String get detailedDescriptionLabel => 'Detailed Description';

  @override
  String get taskRequirementsHint => 'e.g., Milk, Bread, Eggs';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get dueDateOptionalLabel => 'Due Date (Optional)';

  @override
  String get websiteLinkName => 'Website/Link Name';

  @override
  String get urlLinkLabel => 'URL/Link';

  @override
  String get linkDescriptionLabel => 'Description';

  @override
  String get linkPurposeHint => 'e.g., Project research';

  @override
  String get fileDescription => 'File Description';

  @override
  String get fileExplanation => 'e.g., Contract draft';

  @override
  String pleaseEnter(String label) {
    return 'Please enter $label';
  }

  @override
  String get saveToLocal => 'Save to Local';

  @override
  String get openFileLocation => 'Open File Location';

  @override
  String get selectMessages => 'Select Messages';

  @override
  String selectedMessages(int count) {
    return '$count selected';
  }

  @override
  String get deleteTooltip => 'Delete';

  @override
  String get messageFilter => 'Message Filter';

  @override
  String get searchMessagesOrFiles => 'Search messages or files';

  @override
  String get messageType => 'Message Type';

  @override
  String get all => 'All';

  @override
  String get text => 'Text';

  @override
  String get saveToGallery => 'Save to Gallery';

  @override
  String get confirmShare => 'Confirm Share';

  @override
  String get textSent => 'Text sent';

  @override
  String get groups => 'Groups';

  @override
  String get noGroup => 'No Group';

  @override
  String get memories => 'Memories';

  @override
  String get createGroup => 'Create Group';

  @override
  String get groupDescriptionOptional => 'Group Description (optional)';

  @override
  String get groupDescriptionHint => 'Enter group description';

  @override
  String get pleaseEnterGroupName => 'Please enter group name';

  @override
  String groupCreatedSuccessfully(String name) {
    return 'Group \'$name\' created successfully';
  }

  @override
  String get createGroupFailed => 'Create group failed';

  @override
  String get deviceOs => 'Device OS';

  @override
  String get deviceVersion => 'Device Version';

  @override
  String get deviceRegistrationFailed => 'Device registration failed';

  @override
  String get placeQRInFrame => 'Place QR code in the frame';

  @override
  String get joiningGroup => 'Joining group...';

  @override
  String get reconnecting => 'Reconnecting...';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get networkNormal => 'Network normal';

  @override
  String get networkLimited => 'Network limited';

  @override
  String get networkUnavailable => 'Network unavailable';

  @override
  String get checking => 'Checking...';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get loggingOut => 'Logging out...';

  @override
  String get logoutSuccess => 'Logout successful';

  @override
  String get logoutError => 'Error logging out';

  @override
  String get logoutFailed => 'Logout failed';

  @override
  String get loginStatusExpired => 'Login status has expired';

  @override
  String get logoutFailedContent =>
      'Logout failed. You can force logout or try again.';

  @override
  String get forceLogout => 'Force Logout';

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
  String get now => 'Now';

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
  String get justActive => 'Just active';

  @override
  String get onlyMyself => 'Only myself';

  @override
  String devicesCount(int count) {
    return '$count devices';
  }

  @override
  String get sendToMyself => 'Send to myself';

  @override
  String get clickToStartGroupChat => 'Click to start group chat';

  @override
  String get noConversations => 'No conversations';

  @override
  String get joinGroupToStartChat => 'Join a group to start chatting';

  @override
  String get pleaseSelectGroup => 'Please select a group';

  @override
  String get clickGroupSelectorHint =>
      'Click the group selector at the top to select or create a group';

  @override
  String get enterGroupCode => 'Enter Group Code';

  @override
  String get cameraUnavailable => 'Camera unavailable';

  @override
  String get desktopInputModeRecommended => 'Desktop input mode is recommended';

  @override
  String get checkCameraPermissions => 'Check camera permissions';

  @override
  String get switchToInput => 'Switch to Input';

  @override
  String get cameraStartupFailed => 'Camera startup failed';

  @override
  String get startingCamera => 'Starting camera...';

  @override
  String get switchToInputModeOrCheckPermissions =>
      'Switch to input mode or check camera permissions';

  @override
  String get placeQRInScanFrame => 'Place QR code in the scan frame';

  @override
  String get enterInviteCodeHint => 'Enter invite code';

  @override
  String get inviteCodePlaceholder => 'Invite Code';

  @override
  String get groupLeaveSuccess => 'Left group successfully';

  @override
  String get groupLeaveFailed => 'Failed to leave group';

  @override
  String get deviceRemoved => 'Device removed';

  @override
  String get groupManagement => 'Group Management';

  @override
  String get groupMembers => 'Members';

  @override
  String get generateQRCode => 'Generate QR Code';

  @override
  String get noDevices => 'No devices';

  @override
  String get myself => 'Myself';

  @override
  String get deviceConnected => 'Device connected';

  @override
  String get subscriptionManagement => 'Subscription Management';

  @override
  String get currentSubscription => 'Current Subscription';

  @override
  String get supports => 'Supports';

  @override
  String get appName => 'App Name';

  @override
  String get logoutFromCurrentDevice => 'Logout from current device';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get messageRecalled => 'Message recalled';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String deleteFailedWithError(String error) {
    return 'Delete failed with error: $error';
  }

  @override
  String get groupMemberLimitReached => 'Group member limit reached';

  @override
  String get upgradeToSupportMoreDevices => 'Upgrade to support more devices';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get upgradeSubscription => 'Upgrade Subscription';

  @override
  String get viewSubscription => 'View Subscription';

  @override
  String get youHaveBeenRemovedFromGroup =>
      'You have been removed from the group';

  @override
  String get group => 'Group';

  @override
  String get hasBeenDeleted => 'has been deleted';

  @override
  String get loadGroupsFailed => 'Failed to load groups';

  @override
  String get pleaseSelectAGroup => 'Please select a group';

  @override
  String get generateInviteCodeFailed => 'Failed to generate invite code';

  @override
  String get currentCanAdd => 'You can add';

  @override
  String get devicesUnit => 'devices';

  @override
  String get upgradeToBasicVersionCanSupport =>
      'Upgrade to Basic version to support';

  @override
  String get fiveDevices => '5 devices';

  @override
  String get upgradeToProfessionalVersionCanSupport =>
      'Upgrade to Professional version to support';

  @override
  String get tenDevices => '10 devices';

  @override
  String get reachedMaxDeviceCount => 'Reached max device count';

  @override
  String get getGroupDetailsFailed => 'Failed to get group details';

  @override
  String get getGroupMembersFailed => 'Failed to get group members';

  @override
  String get renameGroupFailed => 'Failed to rename group';

  @override
  String get removeDeviceFailed => 'Failed to remove device';

  @override
  String get renameDeviceFailed => 'Failed to rename device';

  @override
  String get groupMemberLimitReachedUpgrade =>
      'Group member limit reached. Upgrade subscription to support more devices.';

  @override
  String get upgradeToUnlockMoreFeatures =>
      'Upgrade subscription to unlock more features:';

  @override
  String get basicVersion5Devices => '• Basic version: supports 5 devices';

  @override
  String get proVersion10Devices => '• Pro version: supports 10 devices';
}
