import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_he.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_no.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sk.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('cs'),
    Locale('da'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fi'),
    Locale('fr'),
    Locale('he'),
    Locale('hi'),
    Locale('hu'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('ms'),
    Locale('nl'),
    Locale('no'),
    Locale('pl'),
    Locale('pt'),
    Locale('ro'),
    Locale('ru'),
    Locale('sk'),
    Locale('sv'),
    Locale('th'),
    Locale('tr'),
    Locale('uk'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Send To Myself'**
  String get appTitle;

  /// Application description
  ///
  /// In en, this message translates to:
  /// **'Cross-device file sharing and message memory assistant'**
  String get appDescription;

  /// No description provided for @commonSection.
  ///
  /// In en, this message translates to:
  /// **''**
  String get commonSection;

  /// No description provided for @navigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigation;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @memory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memory;

  /// No description provided for @noGroupsMessage.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get noGroupsMessage;

  /// No description provided for @noGroupsHint.
  ///
  /// In en, this message translates to:
  /// **'Click the button above to create or join a group'**
  String get noGroupsHint;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @cut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cut;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @receive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receive;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connecting;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @retry_connection.
  ///
  /// In en, this message translates to:
  /// **'Retry Connection'**
  String get retry_connection;

  /// No description provided for @authSection.
  ///
  /// In en, this message translates to:
  /// **''**
  String get authSection;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up to get started'**
  String get registerSubtitle;

  /// No description provided for @registerDevice.
  ///
  /// In en, this message translates to:
  /// **'Register Device'**
  String get registerDevice;

  /// No description provided for @registering.
  ///
  /// In en, this message translates to:
  /// **'Registering...'**
  String get registering;

  /// No description provided for @deviceRegistration.
  ///
  /// In en, this message translates to:
  /// **'Device Registration'**
  String get deviceRegistration;

  /// No description provided for @deviceRegistrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Device registered successfully'**
  String get deviceRegistrationSuccess;

  /// No description provided for @deviceRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Device registration failed'**
  String get deviceRegistrationFailed;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccess;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logout successful'**
  String get logoutSuccess;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @navigationSection.
  ///
  /// In en, this message translates to:
  /// **''**
  String get navigationSection;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @memories.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get memories;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @sectionmessages.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionmessages;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get newMessage;

  /// No description provided for @onlyMyself.
  ///
  /// In en, this message translates to:
  /// **'Only myself'**
  String get onlyMyself;

  /// No description provided for @devicesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} devices'**
  String devicesCount(int count);

  /// No description provided for @clickToStartGroupChat.
  ///
  /// In en, this message translates to:
  /// **'Click to start group chat'**
  String get clickToStartGroupChat;

  /// No description provided for @sendToMyself.
  ///
  /// In en, this message translates to:
  /// **'Send to myself'**
  String get sendToMyself;

  /// No description provided for @clickToStartChat.
  ///
  /// In en, this message translates to:
  /// **'Click to start chat'**
  String get clickToStartChat;

  /// No description provided for @unknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown device'**
  String get unknownDevice;

  /// No description provided for @unknownType.
  ///
  /// In en, this message translates to:
  /// **'Unknown type'**
  String get unknownType;

  /// No description provided for @myself.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get myself;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations'**
  String get noConversations;

  /// No description provided for @joinGroupToStartChat.
  ///
  /// In en, this message translates to:
  /// **'Join a device group to start chatting'**
  String get joinGroupToStartChat;

  /// No description provided for @pleaseSelectGroup.
  ///
  /// In en, this message translates to:
  /// **'Please select a group'**
  String get pleaseSelectGroup;

  /// No description provided for @clickGroupSelectorHint.
  ///
  /// In en, this message translates to:
  /// **'Click the group selector at the top to select or create a group'**
  String get clickGroupSelectorHint;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get messageHint;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessages;

  /// No description provided for @messagesSent.
  ///
  /// In en, this message translates to:
  /// **'Messages sent'**
  String get messagesSent;

  /// No description provided for @messagesReceived.
  ///
  /// In en, this message translates to:
  /// **'Messages received'**
  String get messagesReceived;

  /// No description provided for @messageDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get messageDelivered;

  /// No description provided for @messageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get messageFailed;

  /// No description provided for @messagePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get messagePending;

  /// No description provided for @copyMessage.
  ///
  /// In en, this message translates to:
  /// **'Copy Message'**
  String get copyMessage;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get deleteMessage;

  /// No description provided for @replyMessage.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyMessage;

  /// No description provided for @forwardMessage.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forwardMessage;

  /// No description provided for @selectMessages.
  ///
  /// In en, this message translates to:
  /// **'Select Messages'**
  String get selectMessages;

  /// No description provided for @selectedMessages.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedMessages(int count);

  /// No description provided for @deleteSelectedMessages.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected Messages'**
  String get deleteSelectedMessages;

  /// No description provided for @deleteMessageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get deleteMessageConfirm;

  /// No description provided for @deleteMessagesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} messages?'**
  String deleteMessagesConfirm(int count);

  /// No description provided for @sectionfiles.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionfiles;

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get selectFile;

  /// No description provided for @selectFiles.
  ///
  /// In en, this message translates to:
  /// **'Select Files'**
  String get selectFiles;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// No description provided for @selectVideo.
  ///
  /// In en, this message translates to:
  /// **'Select Video'**
  String get selectVideo;

  /// No description provided for @selectDocument.
  ///
  /// In en, this message translates to:
  /// **'Select Document'**
  String get selectDocument;

  /// No description provided for @noFiles.
  ///
  /// In en, this message translates to:
  /// **'No files'**
  String get noFiles;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileName;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get fileSize;

  /// No description provided for @fileType.
  ///
  /// In en, this message translates to:
  /// **'File Type'**
  String get fileType;

  /// No description provided for @fileDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fileDate;

  /// No description provided for @uploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload File'**
  String get uploadFile;

  /// No description provided for @downloadFile.
  ///
  /// In en, this message translates to:
  /// **'Download File'**
  String get downloadFile;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get openFile;

  /// No description provided for @shareFile.
  ///
  /// In en, this message translates to:
  /// **'Share File'**
  String get shareFile;

  /// No description provided for @deleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete File'**
  String get deleteFile;

  /// No description provided for @uploadProgress.
  ///
  /// In en, this message translates to:
  /// **'Uploading... {progress}%'**
  String uploadProgress(int progress);

  /// No description provided for @downloadProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading... {progress}%'**
  String downloadProgress(int progress);

  /// No description provided for @uploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Upload successful'**
  String get uploadSuccess;

  /// No description provided for @downloadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Download successful'**
  String get downloadSuccess;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailed;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File is too large'**
  String get fileTooLarge;

  /// No description provided for @unsupportedFileType.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type'**
  String get unsupportedFileType;

  /// No description provided for @saveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save to Gallery'**
  String get saveToGallery;

  /// No description provided for @saveToLocal.
  ///
  /// In en, this message translates to:
  /// **'Save to Local'**
  String get saveToLocal;

  /// No description provided for @openFileLocation.
  ///
  /// In en, this message translates to:
  /// **'Open File Location'**
  String get openFileLocation;

  /// No description provided for @sectionmemories.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionmemories;

  /// No description provided for @createMemory.
  ///
  /// In en, this message translates to:
  /// **'Create Memory'**
  String get createMemory;

  /// No description provided for @editMemory.
  ///
  /// In en, this message translates to:
  /// **'Edit Memory'**
  String get editMemory;

  /// No description provided for @deleteMemory.
  ///
  /// In en, this message translates to:
  /// **'Delete Memory'**
  String get deleteMemory;

  /// No description provided for @memoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get memoryTitle;

  /// No description provided for @memoryContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get memoryContent;

  /// No description provided for @memoryCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get memoryCategory;

  /// No description provided for @memoryTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get memoryTags;

  /// No description provided for @memoryDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get memoryDate;

  /// No description provided for @memoryLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get memoryLocation;

  /// No description provided for @memoryPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get memoryPriority;

  /// No description provided for @memoryStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get memoryStatus;

  /// No description provided for @noMemories.
  ///
  /// In en, this message translates to:
  /// **'No memories yet'**
  String get noMemories;

  /// No description provided for @searchMemories.
  ///
  /// In en, this message translates to:
  /// **'Search memories...'**
  String get searchMemories;

  /// No description provided for @filterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get filterByCategory;

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'Sort by date'**
  String get sortByDate;

  /// No description provided for @sortByPriority.
  ///
  /// In en, this message translates to:
  /// **'Sort by priority'**
  String get sortByPriority;

  /// No description provided for @memoryCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get memoryCategories;

  /// No description provided for @personalMemory.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personalMemory;

  /// No description provided for @workMemory.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get workMemory;

  /// No description provided for @lifeMemory.
  ///
  /// In en, this message translates to:
  /// **'Life'**
  String get lifeMemory;

  /// No description provided for @studyMemory.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get studyMemory;

  /// No description provided for @travelMemory.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travelMemory;

  /// No description provided for @otherMemory.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherMemory;

  /// No description provided for @memoryPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get memoryPriorityHigh;

  /// No description provided for @memoryPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get memoryPriorityMedium;

  /// No description provided for @memoryPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get memoryPriorityLow;

  /// No description provided for @memoryStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get memoryStatusActive;

  /// No description provided for @memoryStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get memoryStatusCompleted;

  /// No description provided for @memoryStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get memoryStatusArchived;

  /// No description provided for @sectiongroups.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectiongroups;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @joinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get joinGroup;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get leaveGroup;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter group name'**
  String get groupNameHint;

  /// No description provided for @groupDescription.
  ///
  /// In en, this message translates to:
  /// **'Group Description'**
  String get groupDescription;

  /// No description provided for @groupDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Enter group description'**
  String get groupDescriptionHint;

  /// No description provided for @groupDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Group Description (Optional)'**
  String get groupDescriptionOptional;

  /// No description provided for @groupMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get groupMembers;

  /// No description provided for @groupSettings.
  ///
  /// In en, this message translates to:
  /// **'Group Settings'**
  String get groupSettings;

  /// No description provided for @noGroups.
  ///
  /// In en, this message translates to:
  /// **'No groups'**
  String get noGroups;

  /// No description provided for @groupCode.
  ///
  /// In en, this message translates to:
  /// **'Group Code'**
  String get groupCode;

  /// No description provided for @scanQRCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQRCode;

  /// No description provided for @generateQRCode.
  ///
  /// In en, this message translates to:
  /// **'Generate QR Code'**
  String get generateQRCode;

  /// No description provided for @joinGroupByCode.
  ///
  /// In en, this message translates to:
  /// **'Join by Code'**
  String get joinGroupByCode;

  /// No description provided for @joinGroupByQR.
  ///
  /// In en, this message translates to:
  /// **'Join by QR Code'**
  String get joinGroupByQR;

  /// No description provided for @groupJoinSuccess.
  ///
  /// In en, this message translates to:
  /// **'Joined group successfully'**
  String get groupJoinSuccess;

  /// No description provided for @groupJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to join group'**
  String get groupJoinFailed;

  /// No description provided for @groupLeaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Left group successfully'**
  String get groupLeaveSuccess;

  /// No description provided for @groupLeaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to leave group'**
  String get groupLeaveFailed;

  /// No description provided for @groupLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this group?'**
  String get groupLeaveConfirm;

  /// No description provided for @groupDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this group?'**
  String get groupDeleteConfirm;

  /// No description provided for @groupCreated.
  ///
  /// In en, this message translates to:
  /// **'Group created successfully'**
  String get groupCreated;

  /// No description provided for @groupCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create group'**
  String get groupCreateFailed;

  /// No description provided for @invalidGroupCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid group code'**
  String get invalidGroupCode;

  /// No description provided for @groupNotFound.
  ///
  /// In en, this message translates to:
  /// **'Group not found'**
  String get groupNotFound;

  /// No description provided for @alreadyInGroup.
  ///
  /// In en, this message translates to:
  /// **'Already in this group'**
  String get alreadyInGroup;

  /// No description provided for @groupFull.
  ///
  /// In en, this message translates to:
  /// **'Group is full'**
  String get groupFull;

  /// No description provided for @renameGroup.
  ///
  /// In en, this message translates to:
  /// **'Rename Group'**
  String get renameGroup;

  /// No description provided for @newGroupName.
  ///
  /// In en, this message translates to:
  /// **'New Group Name'**
  String get newGroupName;

  /// No description provided for @enterNewGroupName.
  ///
  /// In en, this message translates to:
  /// **'Enter new group name'**
  String get enterNewGroupName;

  /// No description provided for @renamingGroup.
  ///
  /// In en, this message translates to:
  /// **'Renaming group...'**
  String get renamingGroup;

  /// No description provided for @groupRenameSuccess.
  ///
  /// In en, this message translates to:
  /// **'Group renamed successfully'**
  String get groupRenameSuccess;

  /// No description provided for @groupRenameFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename group'**
  String get groupRenameFailed;

  /// No description provided for @renameFailed.
  ///
  /// In en, this message translates to:
  /// **'Rename failed'**
  String get renameFailed;

  /// No description provided for @loadGroupInfoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load group information'**
  String get loadGroupInfoFailed;

  /// No description provided for @groupManagement.
  ///
  /// In en, this message translates to:
  /// **'Group Management'**
  String get groupManagement;

  /// No description provided for @membersList.
  ///
  /// In en, this message translates to:
  /// **'Members List'**
  String get membersList;

  /// No description provided for @groupInfo.
  ///
  /// In en, this message translates to:
  /// **'Group Information'**
  String get groupInfo;

  /// No description provided for @sectiondevices.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectiondevices;

  /// No description provided for @deviceName.
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get deviceName;

  /// No description provided for @deviceType.
  ///
  /// In en, this message translates to:
  /// **'Device Type'**
  String get deviceType;

  /// No description provided for @deviceStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get deviceStatus;

  /// No description provided for @deviceLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last Seen'**
  String get deviceLastSeen;

  /// No description provided for @connectedDevices.
  ///
  /// In en, this message translates to:
  /// **'Connected Devices'**
  String get connectedDevices;

  /// No description provided for @availableDevices.
  ///
  /// In en, this message translates to:
  /// **'Available Devices'**
  String get availableDevices;

  /// No description provided for @noDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices'**
  String get noDevices;

  /// No description provided for @connectDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect Device'**
  String get connectDevice;

  /// No description provided for @disconnectDevice.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Device'**
  String get disconnectDevice;

  /// No description provided for @removeDevice.
  ///
  /// In en, this message translates to:
  /// **'Remove Device'**
  String get removeDevice;

  /// No description provided for @deviceConnected.
  ///
  /// In en, this message translates to:
  /// **'Device connected'**
  String get deviceConnected;

  /// No description provided for @deviceDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Device disconnected'**
  String get deviceDisconnected;

  /// No description provided for @deviceRemoved.
  ///
  /// In en, this message translates to:
  /// **'Device removed'**
  String get deviceRemoved;

  /// No description provided for @deviceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Device not found'**
  String get deviceNotFound;

  /// No description provided for @deviceConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect device'**
  String get deviceConnectionFailed;

  /// No description provided for @sectionsync.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionsync;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Sync complete'**
  String get syncComplete;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// No description provided for @autoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto Sync'**
  String get autoSync;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last Sync'**
  String get lastSync;

  /// No description provided for @syncSettings.
  ///
  /// In en, this message translates to:
  /// **'Sync Settings'**
  String get syncSettings;

  /// No description provided for @syncMessages.
  ///
  /// In en, this message translates to:
  /// **'Sync Messages'**
  String get syncMessages;

  /// No description provided for @syncFiles.
  ///
  /// In en, this message translates to:
  /// **'Sync Files'**
  String get syncFiles;

  /// No description provided for @syncMemories.
  ///
  /// In en, this message translates to:
  /// **'Sync Memories'**
  String get syncMemories;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @onlineMode.
  ///
  /// In en, this message translates to:
  /// **'Online Mode'**
  String get onlineMode;

  /// No description provided for @sectionqr.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionqr;

  /// No description provided for @qrCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCodeTitle;

  /// No description provided for @scanQR.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQR;

  /// No description provided for @generateQR.
  ///
  /// In en, this message translates to:
  /// **'Generate QR'**
  String get generateQR;

  /// No description provided for @qrCodeGenerated.
  ///
  /// In en, this message translates to:
  /// **'QR Code generated'**
  String get qrCodeGenerated;

  /// No description provided for @qrCodeScanned.
  ///
  /// In en, this message translates to:
  /// **'QR Code scanned'**
  String get qrCodeScanned;

  /// No description provided for @qrScanFailed.
  ///
  /// In en, this message translates to:
  /// **'QR scan failed'**
  String get qrScanFailed;

  /// No description provided for @invalidQRCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code'**
  String get invalidQRCode;

  /// No description provided for @qrPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied'**
  String get qrPermissionDenied;

  /// No description provided for @qrCameraError.
  ///
  /// In en, this message translates to:
  /// **'Camera error'**
  String get qrCameraError;

  /// No description provided for @sectionnetwork.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionnetwork;

  /// No description provided for @networkStatus.
  ///
  /// In en, this message translates to:
  /// **'Network Status'**
  String get networkStatus;

  /// No description provided for @networkConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get networkConnected;

  /// No description provided for @networkDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get networkDisconnected;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get networkError;

  /// No description provided for @connectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout'**
  String get connectionTimeout;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get serverError;

  /// No description provided for @clientError.
  ///
  /// In en, this message translates to:
  /// **'Client error'**
  String get clientError;

  /// No description provided for @networkDebug.
  ///
  /// In en, this message translates to:
  /// **'Network Debug'**
  String get networkDebug;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Check Connection'**
  String get checkConnection;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnecting;

  /// No description provided for @reconnected.
  ///
  /// In en, this message translates to:
  /// **'Reconnected'**
  String get reconnected;

  /// No description provided for @connectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get connectionLost;

  /// No description provided for @sectionnotifications.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionnotifications;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @disableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Disable Notifications'**
  String get disableNotifications;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @newMessageNotification.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessageNotification;

  /// No description provided for @fileUploadNotification.
  ///
  /// In en, this message translates to:
  /// **'File upload complete'**
  String get fileUploadNotification;

  /// No description provided for @fileDownloadNotification.
  ///
  /// In en, this message translates to:
  /// **'File download complete'**
  String get fileDownloadNotification;

  /// No description provided for @syncCompleteNotification.
  ///
  /// In en, this message translates to:
  /// **'Sync complete'**
  String get syncCompleteNotification;

  /// No description provided for @deviceConnectedNotification.
  ///
  /// In en, this message translates to:
  /// **'Device connected'**
  String get deviceConnectedNotification;

  /// No description provided for @deviceDisconnectedNotification.
  ///
  /// In en, this message translates to:
  /// **'Device disconnected'**
  String get deviceDisconnectedNotification;

  /// No description provided for @sectiontime.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectiontime;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get lastWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get lastMonth;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @sectionerrors.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionerrors;

  /// No description provided for @errorGeneral.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorGeneral;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timeout'**
  String get errorTimeout;

  /// No description provided for @errorServerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Server unavailable'**
  String get errorServerUnavailable;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized access'**
  String get errorUnauthorized;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'Access forbidden'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Resource not found'**
  String get errorNotFound;

  /// No description provided for @errorInternalServer.
  ///
  /// In en, this message translates to:
  /// **'Internal server error'**
  String get errorInternalServer;

  /// No description provided for @errorBadRequest.
  ///
  /// In en, this message translates to:
  /// **'Bad request'**
  String get errorBadRequest;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests'**
  String get errorTooManyRequests;

  /// No description provided for @errorServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Service unavailable'**
  String get errorServiceUnavailable;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get errorUnknown;

  /// No description provided for @errorRetry.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get errorRetry;

  /// No description provided for @sectionfile_sizes.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionfile_sizes;

  /// No description provided for @bytes.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get bytes;

  /// No description provided for @kilobytes.
  ///
  /// In en, this message translates to:
  /// **'KB'**
  String get kilobytes;

  /// No description provided for @megabytes.
  ///
  /// In en, this message translates to:
  /// **'MB'**
  String get megabytes;

  /// No description provided for @gigabytes.
  ///
  /// In en, this message translates to:
  /// **'GB'**
  String get gigabytes;

  /// No description provided for @terabytes.
  ///
  /// In en, this message translates to:
  /// **'TB'**
  String get terabytes;

  /// No description provided for @sectionpermissions.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionpermissions;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get permissionDenied;

  /// No description provided for @permissionCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required'**
  String get permissionCamera;

  /// No description provided for @permissionStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required'**
  String get permissionStorage;

  /// No description provided for @permissionNotification.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required'**
  String get permissionNotification;

  /// No description provided for @permissionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required'**
  String get permissionLocation;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'cs',
    'da',
    'de',
    'en',
    'es',
    'fi',
    'fr',
    'he',
    'hi',
    'hu',
    'id',
    'it',
    'ja',
    'ko',
    'ms',
    'nl',
    'no',
    'pl',
    'pt',
    'ro',
    'ru',
    'sk',
    'sv',
    'th',
    'tr',
    'uk',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'cs':
      return AppLocalizationsCs();
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'he':
      return AppLocalizationsHe();
    case 'hi':
      return AppLocalizationsHi();
    case 'hu':
      return AppLocalizationsHu();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ms':
      return AppLocalizationsMs();
    case 'nl':
      return AppLocalizationsNl();
    case 'no':
      return AppLocalizationsNo();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'sk':
      return AppLocalizationsSk();
    case 'sv':
      return AppLocalizationsSv();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
