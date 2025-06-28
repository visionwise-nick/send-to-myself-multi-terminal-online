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
  /// **'Version 1.0.0'**
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
  /// **'Please select a group first'**
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
  /// **'File size'**
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
  /// **'File too large to send'**
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
  /// **'Search memories, tags...'**
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
  /// **'Please enter group name'**
  String get groupNameHint;

  /// No description provided for @groupDescription.
  ///
  /// In en, this message translates to:
  /// **'Group Description (Optional)'**
  String get groupDescription;

  /// No description provided for @groupDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Please enter group description'**
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

  /// No description provided for @manualInput.
  ///
  /// In en, this message translates to:
  /// **'Manual Input'**
  String get manualInput;

  /// No description provided for @flashlight.
  ///
  /// In en, this message translates to:
  /// **'Flashlight'**
  String get flashlight;

  /// No description provided for @enterJoinCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Join Code'**
  String get enterJoinCode;

  /// No description provided for @joinCodeHint.
  ///
  /// In en, this message translates to:
  /// **'8-digit join code'**
  String get joinCodeHint;

  /// No description provided for @joinGroupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully joined group!'**
  String get joinGroupSuccess;

  /// No description provided for @joinGroupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to join group'**
  String get joinGroupFailed;

  /// No description provided for @joinFailed.
  ///
  /// In en, this message translates to:
  /// **'Join failed'**
  String get joinFailed;

  /// No description provided for @joiningGroup.
  ///
  /// In en, this message translates to:
  /// **'Joining group...'**
  String get joiningGroup;

  /// No description provided for @placeQRInFrame.
  ///
  /// In en, this message translates to:
  /// **'Place QR code within the frame to scan'**
  String get placeQRInFrame;

  /// No description provided for @deviceJoinCode.
  ///
  /// In en, this message translates to:
  /// **'Device Join Code'**
  String get deviceJoinCode;

  /// No description provided for @regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerate;

  /// No description provided for @generatingJoinCode.
  ///
  /// In en, this message translates to:
  /// **'Generating join code...'**
  String get generatingJoinCode;

  /// No description provided for @generateFailed.
  ///
  /// In en, this message translates to:
  /// **'Generation failed'**
  String get generateFailed;

  /// No description provided for @noGroupInfo.
  ///
  /// In en, this message translates to:
  /// **'No available group information'**
  String get noGroupInfo;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

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
  /// **'Reconnecting'**
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
  /// **'{minutes} minutes ago'**
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

  /// No description provided for @sectionsettings.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionsettings;

  /// No description provided for @deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device Information'**
  String get deviceInfo;

  /// No description provided for @deviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceId;

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @appTheme.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get appTheme;

  /// No description provided for @defaultTheme.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultTheme;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon, please stay tuned!'**
  String get featureComingSoon;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout from this device?'**
  String get logoutConfirmMessage;

  /// No description provided for @sectionmemory.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionmemory;

  /// No description provided for @memoriesCount.
  ///
  /// In en, this message translates to:
  /// **'Saved {count} memories'**
  String memoriesCount(int count);

  /// No description provided for @noMemoriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Start creating your first memory'**
  String get noMemoriesDesc;

  /// No description provided for @viewMemory.
  ///
  /// In en, this message translates to:
  /// **'View Memory'**
  String get viewMemory;

  /// No description provided for @quickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get quickAdd;

  /// No description provided for @addMemoryFromText.
  ///
  /// In en, this message translates to:
  /// **'Add from Text'**
  String get addMemoryFromText;

  /// No description provided for @addMemoryFromImage.
  ///
  /// In en, this message translates to:
  /// **'Add from Image'**
  String get addMemoryFromImage;

  /// No description provided for @addMemoryFromFile.
  ///
  /// In en, this message translates to:
  /// **'Add from File'**
  String get addMemoryFromFile;

  /// No description provided for @sectionjoingroup.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionjoingroup;

  /// No description provided for @scanMode.
  ///
  /// In en, this message translates to:
  /// **'Scan Mode'**
  String get scanMode;

  /// No description provided for @inputMode.
  ///
  /// In en, this message translates to:
  /// **'Input Mode'**
  String get inputMode;

  /// No description provided for @cameraInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Camera initialization failed'**
  String get cameraInitFailed;

  /// No description provided for @cameraNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Camera not available, switched to manual input mode'**
  String get cameraNotAvailable;

  /// No description provided for @desktopCameraTip.
  ///
  /// In en, this message translates to:
  /// **'Desktop mode recommends manual input, camera scanning may be unstable'**
  String get desktopCameraTip;

  /// No description provided for @enterGroupCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Group Code'**
  String get enterGroupCode;

  /// No description provided for @groupCodePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter 8-digit group code'**
  String get groupCodePlaceholder;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get invalidCode;

  /// No description provided for @codeRequired.
  ///
  /// In en, this message translates to:
  /// **'Code is required'**
  String get codeRequired;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @switchToScan.
  ///
  /// In en, this message translates to:
  /// **'Switch to Scan Mode'**
  String get switchToScan;

  /// No description provided for @switchToInput.
  ///
  /// In en, this message translates to:
  /// **'Switch to Input Mode'**
  String get switchToInput;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get cameraUnavailable;

  /// No description provided for @checkCameraPermissions.
  ///
  /// In en, this message translates to:
  /// **'Please check camera permission settings'**
  String get checkCameraPermissions;

  /// No description provided for @desktopInputModeRecommended.
  ///
  /// In en, this message translates to:
  /// **'Desktop mode recommends using the \"Enter Invite Code\" mode below'**
  String get desktopInputModeRecommended;

  /// No description provided for @cameraStartupFailed.
  ///
  /// In en, this message translates to:
  /// **'Camera startup failed'**
  String get cameraStartupFailed;

  /// No description provided for @startingCamera.
  ///
  /// In en, this message translates to:
  /// **'Starting camera...'**
  String get startingCamera;

  /// No description provided for @placeQRInScanFrame.
  ///
  /// In en, this message translates to:
  /// **'Place QR code within the scan frame'**
  String get placeQRInScanFrame;

  /// No description provided for @switchToInputModeOrCheckPermissions.
  ///
  /// In en, this message translates to:
  /// **'Please switch to input mode or check camera permissions'**
  String get switchToInputModeOrCheckPermissions;

  /// No description provided for @enterInviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Please enter group invite code (4-20 digits)'**
  String get enterInviteCodeHint;

  /// No description provided for @inviteCodePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCodePlaceholder;

  /// No description provided for @clickToJoinGroup.
  ///
  /// In en, this message translates to:
  /// **'Click to join group'**
  String get clickToJoinGroup;

  /// No description provided for @selectGroup.
  ///
  /// In en, this message translates to:
  /// **'Select Group'**
  String get selectGroup;

  /// No description provided for @createGroupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create group'**
  String get createGroupFailed;

  /// No description provided for @pleaseEnterGroupName.
  ///
  /// In en, this message translates to:
  /// **'Please enter group name'**
  String get pleaseEnterGroupName;

  /// No description provided for @groupCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Group \"{name}\" created successfully'**
  String groupCreatedSuccessfully(Object name);

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @writeYourThoughts.
  ///
  /// In en, this message translates to:
  /// **'Write your thoughts...'**
  String get writeYourThoughts;

  /// No description provided for @enterNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter note title'**
  String get enterNoteTitle;

  /// No description provided for @websiteAppName.
  ///
  /// In en, this message translates to:
  /// **'Website/App Name'**
  String get websiteAppName;

  /// No description provided for @websiteAppNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g.: WeChat, Taobao'**
  String get websiteAppNameHint;

  /// No description provided for @websiteAddress.
  ///
  /// In en, this message translates to:
  /// **'Website Address'**
  String get websiteAddress;

  /// No description provided for @websiteAddressHint.
  ///
  /// In en, this message translates to:
  /// **'https://...'**
  String get websiteAddressHint;

  /// No description provided for @usernameEmail.
  ///
  /// In en, this message translates to:
  /// **'Username/Email'**
  String get usernameEmail;

  /// No description provided for @loginAccount.
  ///
  /// In en, this message translates to:
  /// **'Login Account'**
  String get loginAccount;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Login Password'**
  String get loginPassword;

  /// No description provided for @sectionchat.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionchat;

  /// No description provided for @sendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed'**
  String get sendFailed;

  /// No description provided for @maxAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum allowed'**
  String get maxAllowed;

  /// No description provided for @selectFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Select file failed'**
  String get selectFileFailed;

  /// No description provided for @pasteFailed.
  ///
  /// In en, this message translates to:
  /// **'Paste failed'**
  String get pasteFailed;

  /// No description provided for @fileProcessingFailed.
  ///
  /// In en, this message translates to:
  /// **'File processing failed'**
  String get fileProcessingFailed;

  /// No description provided for @sharedTextMessages.
  ///
  /// In en, this message translates to:
  /// **'Shared {count} text messages'**
  String sharedTextMessages(Object count);

  /// No description provided for @sharedFiles.
  ///
  /// In en, this message translates to:
  /// **'Shared {count} files'**
  String sharedFiles(Object count);

  /// No description provided for @batchShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Batch share failed'**
  String get batchShareFailed;

  /// No description provided for @copiedMessages.
  ///
  /// In en, this message translates to:
  /// **'Copied {count} messages to clipboard'**
  String copiedMessages(Object count);

  /// No description provided for @messagesAddedToInput.
  ///
  /// In en, this message translates to:
  /// **'{count} message contents added to input box'**
  String messagesAddedToInput(Object count);

  /// No description provided for @favoriteMessages.
  ///
  /// In en, this message translates to:
  /// **'Favorited {count}/{total} messages'**
  String favoriteMessages(Object count, Object total);

  /// No description provided for @recalledMessages.
  ///
  /// In en, this message translates to:
  /// **'Recalled {count} messages'**
  String recalledMessages(Object count);

  /// No description provided for @batchRecallFailed.
  ///
  /// In en, this message translates to:
  /// **'Batch recall failed'**
  String get batchRecallFailed;

  /// No description provided for @deletedMessages.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} messages'**
  String deletedMessages(Object count);

  /// No description provided for @batchDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Batch delete failed'**
  String get batchDeleteFailed;

  /// No description provided for @debugInfo.
  ///
  /// In en, this message translates to:
  /// **'Debug Info'**
  String get debugInfo;

  /// No description provided for @permanentStorageDir.
  ///
  /// In en, this message translates to:
  /// **'Permanent Storage Directory'**
  String get permanentStorageDir;

  /// No description provided for @storageUsage.
  ///
  /// In en, this message translates to:
  /// **'Storage Usage:'**
  String get storageUsage;

  /// No description provided for @chatData.
  ///
  /// In en, this message translates to:
  /// **'Chat Data'**
  String get chatData;

  /// No description provided for @memoryData.
  ///
  /// In en, this message translates to:
  /// **'Memory Data'**
  String get memoryData;

  /// No description provided for @userData.
  ///
  /// In en, this message translates to:
  /// **'User Data'**
  String get userData;

  /// No description provided for @fileCache.
  ///
  /// In en, this message translates to:
  /// **'File Cache'**
  String get fileCache;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @fileCacheStats.
  ///
  /// In en, this message translates to:
  /// **'File Cache Stats:'**
  String get fileCacheStats;

  /// No description provided for @totalFiles.
  ///
  /// In en, this message translates to:
  /// **'Total Files'**
  String get totalFiles;

  /// No description provided for @validFiles.
  ///
  /// In en, this message translates to:
  /// **'Valid Files'**
  String get validFiles;

  /// No description provided for @invalidFiles.
  ///
  /// In en, this message translates to:
  /// **'Invalid Files'**
  String get invalidFiles;

  /// No description provided for @deduplicationDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Deduplication Diagnostics:'**
  String get deduplicationDiagnostics;

  /// No description provided for @processedMessageIds.
  ///
  /// In en, this message translates to:
  /// **'Processed Message IDs'**
  String get processedMessageIds;

  /// No description provided for @timestampRecords.
  ///
  /// In en, this message translates to:
  /// **'Timestamp Records'**
  String get timestampRecords;

  /// No description provided for @uiMessages.
  ///
  /// In en, this message translates to:
  /// **'UI Messages'**
  String get uiMessages;

  /// No description provided for @websocketConnection.
  ///
  /// In en, this message translates to:
  /// **'WebSocket Connection'**
  String get websocketConnection;

  /// No description provided for @lastMessageReceived.
  ///
  /// In en, this message translates to:
  /// **'Last Message Received'**
  String get lastMessageReceived;

  /// No description provided for @forceClearDedupRecords.
  ///
  /// In en, this message translates to:
  /// **'Force clear dedup records and restart WebSocket listening'**
  String get forceClearDedupRecords;

  /// No description provided for @clearDedupRecords.
  ///
  /// In en, this message translates to:
  /// **'Clear Dedup Records'**
  String get clearDedupRecords;

  /// No description provided for @getDebugInfoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get debug info'**
  String get getDebugInfoFailed;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @textCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Text copied to clipboard'**
  String get textCopiedToClipboard;

  /// No description provided for @canDragSelectText.
  ///
  /// In en, this message translates to:
  /// **'You can directly drag to select text content'**
  String get canDragSelectText;

  /// No description provided for @allContentCopied.
  ///
  /// In en, this message translates to:
  /// **'All content copied to clipboard'**
  String get allContentCopied;

  /// No description provided for @messageRecalled.
  ///
  /// In en, this message translates to:
  /// **'Message recalled'**
  String get messageRecalled;

  /// No description provided for @recallFailed.
  ///
  /// In en, this message translates to:
  /// **'Recall failed'**
  String get recallFailed;

  /// No description provided for @messageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// No description provided for @messageAddedToInput.
  ///
  /// In en, this message translates to:
  /// **'Message content added to input box'**
  String get messageAddedToInput;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// No description provided for @favoriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Favorite failed'**
  String get favoriteFailed;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @unfavoriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove from favorites'**
  String get unfavoriteFailed;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get confirmDeleteMessage;

  /// No description provided for @jumpedToOriginalMessage.
  ///
  /// In en, this message translates to:
  /// **'Jumped to original message'**
  String get jumpedToOriginalMessage;

  /// No description provided for @originalMessageNotExists.
  ///
  /// In en, this message translates to:
  /// **'Original message does not exist or has been deleted'**
  String get originalMessageNotExists;

  /// No description provided for @fileInfoIncomplete.
  ///
  /// In en, this message translates to:
  /// **'File information incomplete'**
  String get fileInfoIncomplete;

  /// No description provided for @featureOnlyMobile.
  ///
  /// In en, this message translates to:
  /// **'This feature is only available on mobile'**
  String get featureOnlyMobile;

  /// No description provided for @fileNotExistsDownloading.
  ///
  /// In en, this message translates to:
  /// **'File does not exist, downloading...'**
  String get fileNotExistsDownloading;

  /// No description provided for @fileDownloadFailedCannotSave.
  ///
  /// In en, this message translates to:
  /// **'File download failed, cannot save'**
  String get fileDownloadFailedCannotSave;

  /// No description provided for @sectionnetworkdebug.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionnetworkdebug;

  /// No description provided for @networkDiagnosticTool.
  ///
  /// In en, this message translates to:
  /// **'Network Diagnostic Tool'**
  String get networkDiagnosticTool;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear Logs'**
  String get clearLogs;

  /// No description provided for @copyLogs.
  ///
  /// In en, this message translates to:
  /// **'Copy Logs'**
  String get copyLogs;

  /// No description provided for @connectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Connection Status'**
  String get connectionStatus;

  /// No description provided for @connectionDetails.
  ///
  /// In en, this message translates to:
  /// **'Connection Details'**
  String get connectionDetails;

  /// No description provided for @networkTest.
  ///
  /// In en, this message translates to:
  /// **'Network Test'**
  String get networkTest;

  /// No description provided for @testWebSocket.
  ///
  /// In en, this message translates to:
  /// **'Test WebSocket'**
  String get testWebSocket;

  /// No description provided for @forceReconnect.
  ///
  /// In en, this message translates to:
  /// **'Force Reconnect'**
  String get forceReconnect;

  /// No description provided for @pingTest.
  ///
  /// In en, this message translates to:
  /// **'Ping Test'**
  String get pingTest;

  /// No description provided for @diagnosticLogs.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic Logs'**
  String get diagnosticLogs;

  /// No description provided for @recordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String recordsCount(int count);

  /// No description provided for @startingNetworkDiagnostic.
  ///
  /// In en, this message translates to:
  /// **'Starting network diagnostic test...'**
  String get startingNetworkDiagnostic;

  /// No description provided for @testingBasicConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Testing basic connectivity...'**
  String get testingBasicConnectivity;

  /// No description provided for @testingDnsResolution.
  ///
  /// In en, this message translates to:
  /// **'Testing DNS resolution...'**
  String get testingDnsResolution;

  /// No description provided for @testingServerConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Testing server connectivity...'**
  String get testingServerConnectivity;

  /// No description provided for @networkDiagnosticComplete.
  ///
  /// In en, this message translates to:
  /// **'Network diagnostic test complete'**
  String get networkDiagnosticComplete;

  /// No description provided for @testingConnection.
  ///
  /// In en, this message translates to:
  /// **'Testing connection'**
  String get testingConnection;

  /// No description provided for @connectionSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Connection successful'**
  String get connectionSuccessful;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection Failed'**
  String get connectionFailed;

  /// No description provided for @connectionStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Connection status changed'**
  String get connectionStatusChanged;

  /// No description provided for @networkStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Network status changed'**
  String get networkStatusChanged;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error occurred'**
  String get errorOccurred;

  /// No description provided for @messageReceived.
  ///
  /// In en, this message translates to:
  /// **'Message received'**
  String get messageReceived;

  /// No description provided for @sectionsplash.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionsplash;

  /// No description provided for @appSlogan.
  ///
  /// In en, this message translates to:
  /// **'Cross-device file sharing and sync'**
  String get appSlogan;

  /// No description provided for @myFiles.
  ///
  /// In en, this message translates to:
  /// **'My Files'**
  String get myFiles;

  /// No description provided for @filesFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'File feature coming soon'**
  String get filesFeatureComingSoon;

  /// No description provided for @stayTuned.
  ///
  /// In en, this message translates to:
  /// **'Stay tuned'**
  String get stayTuned;

  /// No description provided for @sectiondevicegroups.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectiondevicegroups;

  /// No description provided for @noDeviceGroups.
  ///
  /// In en, this message translates to:
  /// **'No device groups yet'**
  String get noDeviceGroups;

  /// No description provided for @scanQRToJoin.
  ///
  /// In en, this message translates to:
  /// **'Use other devices to scan QR code to join'**
  String get scanQRToJoin;

  /// No description provided for @myDeviceGroups.
  ///
  /// In en, this message translates to:
  /// **'My Device Groups'**
  String get myDeviceGroups;

  /// No description provided for @unnamedGroup.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Group'**
  String get unnamedGroup;

  /// No description provided for @deviceCount.
  ///
  /// In en, this message translates to:
  /// **'{count} devices'**
  String deviceCount(int count);

  /// No description provided for @youAreOwner.
  ///
  /// In en, this message translates to:
  /// **'You are the owner'**
  String get youAreOwner;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Created on'**
  String get createdOn;

  /// No description provided for @unknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownDate;

  /// No description provided for @sectiondebug.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectiondebug;

  /// No description provided for @batchDelete.
  ///
  /// In en, this message translates to:
  /// **'Batch Delete'**
  String get batchDelete;

  /// No description provided for @confirmBatchDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the selected {count} messages? This action cannot be undone.'**
  String confirmBatchDelete(int count);

  /// No description provided for @batchDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} messages'**
  String batchDeleteSuccess(int count);

  /// No description provided for @batchDeleteFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Batch delete failed: {error}'**
  String batchDeleteFailedWithError(String error);

  /// No description provided for @deleteMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get deleteMessageTitle;

  /// No description provided for @confirmDeleteSingleMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message? This action cannot be undone.'**
  String get confirmDeleteSingleMessage;

  /// No description provided for @deleteFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailedWithError(String error);

  /// No description provided for @recallFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Recall failed: {error}'**
  String recallFailedWithError(String error);

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start conversation'**
  String get startConversation;

  /// No description provided for @sendMessageOrFileToStart.
  ///
  /// In en, this message translates to:
  /// **'Send a message or file to start chatting'**
  String get sendMessageOrFileToStart;

  /// No description provided for @debugInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Debug Info'**
  String get debugInfoTitle;

  /// No description provided for @permanentStorageDirectory.
  ///
  /// In en, this message translates to:
  /// **'Permanent Storage Directory:'**
  String get permanentStorageDirectory;

  /// No description provided for @memoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Memory'**
  String get memoryDeleteTitle;

  /// No description provided for @confirmDeleteMemory.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This action cannot be undone.'**
  String confirmDeleteMemory(String title);

  /// No description provided for @deleteMemorySuccess.
  ///
  /// In en, this message translates to:
  /// **'Delete successful'**
  String get deleteMemorySuccess;

  /// No description provided for @deleteMemoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteMemoryFailed;

  /// No description provided for @memorySavedWithAI.
  ///
  /// In en, this message translates to:
  /// **'Memory saved, AI generated title and {count} tags'**
  String memorySavedWithAI(int count);

  /// No description provided for @saveFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailedWithError(String error);

  /// No description provided for @deleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTooltip;

  /// No description provided for @sectionsnackbar.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionsnackbar;

  /// No description provided for @sharedTextMessagesCount.
  ///
  /// In en, this message translates to:
  /// **'Shared {count} text messages'**
  String sharedTextMessagesCount(int count);

  /// No description provided for @sharedFilesAndText.
  ///
  /// In en, this message translates to:
  /// **'Shared {fileCount} files{textPart}'**
  String sharedFilesAndText(int fileCount, String textPart);

  /// No description provided for @andTextMessages.
  ///
  /// In en, this message translates to:
  /// **' and {count} text messages'**
  String andTextMessages(int count);

  /// No description provided for @batchShareFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Batch share failed: {error}'**
  String batchShareFailedWithError(String error);

  /// No description provided for @copiedMessagesToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied {count} messages to clipboard'**
  String copiedMessagesToClipboard(int count);

  /// No description provided for @messagesAddedToInputBox.
  ///
  /// In en, this message translates to:
  /// **'{count} message contents added to input box'**
  String messagesAddedToInputBox(int count);

  /// No description provided for @favoritedMessagesCount.
  ///
  /// In en, this message translates to:
  /// **'Favorited {successCount}/{totalCount} messages'**
  String favoritedMessagesCount(int successCount, int totalCount);

  /// No description provided for @recalledMessagesCount.
  ///
  /// In en, this message translates to:
  /// **'Recalled {count} messages'**
  String recalledMessagesCount(int count);

  /// No description provided for @batchRecallFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Batch recall failed: {error}'**
  String batchRecallFailedWithError(String error);

  /// No description provided for @forceClearedDedupRecords.
  ///
  /// In en, this message translates to:
  /// **'Force cleared dedup records and restarted WebSocket listening'**
  String get forceClearedDedupRecords;

  /// No description provided for @getDebugInfoFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to get debug info: {error}'**
  String getDebugInfoFailedWithError(String error);

  /// No description provided for @textCanBeDragSelected.
  ///
  /// In en, this message translates to:
  /// **'You can directly drag to select text content'**
  String get textCanBeDragSelected;

  /// No description provided for @allContentCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'All content copied to clipboard'**
  String get allContentCopiedToClipboard;

  /// No description provided for @messageContentAddedToInput.
  ///
  /// In en, this message translates to:
  /// **'Message content added to input box'**
  String get messageContentAddedToInput;

  /// No description provided for @featureOnlyAvailableOnMobile.
  ///
  /// In en, this message translates to:
  /// **'This feature is only available on mobile'**
  String get featureOnlyAvailableOnMobile;

  /// No description provided for @fileDownloadFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'File download failed: {error}'**
  String fileDownloadFailedWithError(String error);

  /// No description provided for @fileUrlNotExistsCannotDownload.
  ///
  /// In en, this message translates to:
  /// **'File URL does not exist, cannot download'**
  String get fileUrlNotExistsCannotDownload;

  /// No description provided for @fileLocationOpened.
  ///
  /// In en, this message translates to:
  /// **'File location opened'**
  String get fileLocationOpened;

  /// No description provided for @filePathCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'File path copied to clipboard'**
  String get filePathCopiedToClipboard;

  /// No description provided for @fileLinkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'File link copied to clipboard'**
  String get fileLinkCopiedToClipboard;

  /// No description provided for @sectionmisc.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionmisc;

  /// No description provided for @sectionauth.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionauth;

  /// No description provided for @loggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get loggingOut;

  /// No description provided for @logoutSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Successfully logged out'**
  String get logoutSuccessMessage;

  /// No description provided for @logoutError.
  ///
  /// In en, this message translates to:
  /// **'Error occurred during logout'**
  String get logoutError;

  /// No description provided for @logoutFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Logout failed: {error}'**
  String logoutFailedWithError(String error);

  /// No description provided for @loginStatusInvalid.
  ///
  /// In en, this message translates to:
  /// **'Login status has expired'**
  String get loginStatusInvalid;

  /// No description provided for @logoutFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout Failed'**
  String get logoutFailedTitle;

  /// No description provided for @logoutFailedContent.
  ///
  /// In en, this message translates to:
  /// **'Logout failed, you can choose to force logout or retry.'**
  String get logoutFailedContent;

  /// No description provided for @forceLogout.
  ///
  /// In en, this message translates to:
  /// **'Force Logout'**
  String get forceLogout;

  /// No description provided for @sectiongroup.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectiongroup;

  /// No description provided for @createNewGroup.
  ///
  /// In en, this message translates to:
  /// **'Create New Group'**
  String get createNewGroup;

  /// No description provided for @groupCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Group \"{name}\" created successfully'**
  String groupCreatedSuccess(String name);

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @sectionconnection.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionconnection;

  /// No description provided for @onlineStatus.
  ///
  /// In en, this message translates to:
  /// **'{online}/{total} online'**
  String onlineStatus(int online, int total);

  /// No description provided for @networkNormal.
  ///
  /// In en, this message translates to:
  /// **'Network Normal'**
  String get networkNormal;

  /// No description provided for @networkLimited.
  ///
  /// In en, this message translates to:
  /// **'Network Limited'**
  String get networkLimited;

  /// No description provided for @networkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Network Unavailable'**
  String get networkUnavailable;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get checking;

  /// No description provided for @sendFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send file'**
  String get sendFileFailed;

  /// No description provided for @noFilesToSend.
  ///
  /// In en, this message translates to:
  /// **'No files to send'**
  String get noFilesToSend;

  /// No description provided for @batchRecall.
  ///
  /// In en, this message translates to:
  /// **'Batch Recall'**
  String get batchRecall;

  /// No description provided for @recall.
  ///
  /// In en, this message translates to:
  /// **'Recall'**
  String get recall;

  /// No description provided for @clearDeduplicationRecords.
  ///
  /// In en, this message translates to:
  /// **'Clear Deduplication Records'**
  String get clearDeduplicationRecords;

  /// No description provided for @cancelUpload.
  ///
  /// In en, this message translates to:
  /// **'Cancel Upload'**
  String get cancelUpload;

  /// No description provided for @cancelDownload.
  ///
  /// In en, this message translates to:
  /// **'Cancel Download'**
  String get cancelDownload;

  /// No description provided for @confirmCancelTransfer.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel {action} this file?'**
  String confirmCancelTransfer(String action);

  /// No description provided for @continueTransfer.
  ///
  /// In en, this message translates to:
  /// **'Continue Transfer'**
  String get continueTransfer;

  /// No description provided for @confirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Confirm cancel'**
  String get confirmCancel;

  /// No description provided for @transferCancelled.
  ///
  /// In en, this message translates to:
  /// **'{action} cancelled'**
  String transferCancelled(String action);

  /// No description provided for @preparingDownload.
  ///
  /// In en, this message translates to:
  /// **'Preparing download'**
  String get preparingDownload;

  /// No description provided for @fileNotExists.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get fileNotExists;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @fileDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'File download failed'**
  String get fileDownloadFailed;

  /// No description provided for @fileNotExistsOrExpired.
  ///
  /// In en, this message translates to:
  /// **'File does not exist or has expired'**
  String get fileNotExistsOrExpired;

  /// No description provided for @noPermissionToDownload.
  ///
  /// In en, this message translates to:
  /// **'No permission to download this file'**
  String get noPermissionToDownload;

  /// No description provided for @imageFile.
  ///
  /// In en, this message translates to:
  /// **'Image file'**
  String get imageFile;

  /// No description provided for @videoFile.
  ///
  /// In en, this message translates to:
  /// **'Video file'**
  String get videoFile;

  /// No description provided for @documentFile.
  ///
  /// In en, this message translates to:
  /// **'Document file'**
  String get documentFile;

  /// No description provided for @audioFile.
  ///
  /// In en, this message translates to:
  /// **'Audio file'**
  String get audioFile;

  /// No description provided for @selectFileType.
  ///
  /// In en, this message translates to:
  /// **'Select file type'**
  String get selectFileType;

  /// No description provided for @selectFileTypeMultiple.
  ///
  /// In en, this message translates to:
  /// **'Select file type (multiple files can be sent directly)'**
  String get selectFileTypeMultiple;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @canDragToSelectText.
  ///
  /// In en, this message translates to:
  /// **'You can drag to select text content'**
  String get canDragToSelectText;

  /// No description provided for @recallMessage.
  ///
  /// In en, this message translates to:
  /// **'Recall message'**
  String get recallMessage;

  /// No description provided for @addToFavoritesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add to favorites'**
  String get addToFavoritesFailed;

  /// No description provided for @removeFromFavoritesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove from favorites'**
  String get removeFromFavoritesFailed;

  /// No description provided for @jumpedToOriginal.
  ///
  /// In en, this message translates to:
  /// **'Jumped to original message'**
  String get jumpedToOriginal;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// No description provided for @textShared.
  ///
  /// In en, this message translates to:
  /// **'Text shared'**
  String get textShared;

  /// No description provided for @fileNotAvailableAndNoTextToShare.
  ///
  /// In en, this message translates to:
  /// **'File not available and no text content to share'**
  String get fileNotAvailableAndNoTextToShare;

  /// No description provided for @messageRecalledText.
  ///
  /// In en, this message translates to:
  /// **'[This message has been recalled]'**
  String get messageRecalledText;

  /// No description provided for @cannotOpenFileLocation.
  ///
  /// In en, this message translates to:
  /// **'Cannot open file location'**
  String get cannotOpenFileLocation;

  /// No description provided for @copyFilePathFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to copy file path'**
  String get copyFilePathFailed;

  /// No description provided for @copyFileLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to copy file link'**
  String get copyFileLinkFailed;

  /// No description provided for @desktopVideoNoValidSource.
  ///
  /// In en, this message translates to:
  /// **'Desktop: No valid video source'**
  String get desktopVideoNoValidSource;

  /// No description provided for @mobileVideoNoValidSource.
  ///
  /// In en, this message translates to:
  /// **'Mobile: No valid video source'**
  String get mobileVideoNoValidSource;

  /// No description provided for @desktopVideo.
  ///
  /// In en, this message translates to:
  /// **'Desktop video'**
  String get desktopVideo;

  /// No description provided for @sectionchatui.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionchatui;

  /// No description provided for @continuedTransfer.
  ///
  /// In en, this message translates to:
  /// **'Continue transfer'**
  String get continuedTransfer;

  /// No description provided for @sectionchatmessages.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionchatmessages;

  /// No description provided for @batchRecallReason.
  ///
  /// In en, this message translates to:
  /// **'Batch recall'**
  String get batchRecallReason;

  /// No description provided for @batchDeleteReason.
  ///
  /// In en, this message translates to:
  /// **'Batch delete'**
  String get batchDeleteReason;

  /// No description provided for @confirmCancelUpload.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel uploading this file?'**
  String get confirmCancelUpload;

  /// No description provided for @confirmCancelDownload.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel downloading this file?'**
  String get confirmCancelDownload;

  /// No description provided for @uploadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Upload cancelled'**
  String get uploadCancelled;

  /// No description provided for @downloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled'**
  String get downloadCancelled;

  /// No description provided for @favoritesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add to favorites'**
  String get favoritesFailed;

  /// No description provided for @fileUnavailableNoText.
  ///
  /// In en, this message translates to:
  /// **'File unavailable and no text content to share'**
  String get fileUnavailableNoText;

  /// No description provided for @filePathCopied.
  ///
  /// In en, this message translates to:
  /// **'File path copied to clipboard'**
  String get filePathCopied;

  /// No description provided for @fileLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'File link copied to clipboard'**
  String get fileLinkCopied;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter note title'**
  String get titleHint;

  /// No description provided for @contentLabel.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get contentLabel;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @otherInfo.
  ///
  /// In en, this message translates to:
  /// **'Other Information'**
  String get otherInfo;

  /// No description provided for @expenseItem.
  ///
  /// In en, this message translates to:
  /// **'Expense Item'**
  String get expenseItem;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @detailedDescription.
  ///
  /// In en, this message translates to:
  /// **'Detailed Description'**
  String get detailedDescription;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule Title'**
  String get scheduleTitle;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @advanceReminder.
  ///
  /// In en, this message translates to:
  /// **'Advance Reminder'**
  String get advanceReminder;

  /// No description provided for @noReminder.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get noReminder;

  /// No description provided for @task.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get task;

  /// No description provided for @whatToDo.
  ///
  /// In en, this message translates to:
  /// **'What to do'**
  String get whatToDo;

  /// No description provided for @detailedTaskDescription.
  ///
  /// In en, this message translates to:
  /// **'Detailed Description'**
  String get detailedTaskDescription;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @websiteOrLinkName.
  ///
  /// In en, this message translates to:
  /// **'Website or link name'**
  String get websiteOrLinkName;

  /// No description provided for @linkPurpose.
  ///
  /// In en, this message translates to:
  /// **'The purpose or content of this link'**
  String get linkPurpose;

  /// No description provided for @fileDescription.
  ///
  /// In en, this message translates to:
  /// **'File description'**
  String get fileDescription;

  /// No description provided for @fileExplanation.
  ///
  /// In en, this message translates to:
  /// **'File explanation'**
  String get fileExplanation;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @clickToSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Click to select file'**
  String get clickToSelectFile;

  /// No description provided for @addAccountPassword.
  ///
  /// In en, this message translates to:
  /// **'Add Account Password'**
  String get addAccountPassword;

  /// No description provided for @recordExpense.
  ///
  /// In en, this message translates to:
  /// **'Record Expense'**
  String get recordExpense;

  /// No description provided for @createSchedule.
  ///
  /// In en, this message translates to:
  /// **'Create Schedule'**
  String get createSchedule;

  /// No description provided for @addTodo.
  ///
  /// In en, this message translates to:
  /// **'Add Todo'**
  String get addTodo;

  /// No description provided for @saveLink.
  ///
  /// In en, this message translates to:
  /// **'Save Link'**
  String get saveLink;

  /// No description provided for @saveImage.
  ///
  /// In en, this message translates to:
  /// **'Save Image'**
  String get saveImage;

  /// No description provided for @saveVideo.
  ///
  /// In en, this message translates to:
  /// **'Save Video'**
  String get saveVideo;

  /// No description provided for @saveDocument.
  ///
  /// In en, this message translates to:
  /// **'Save Document'**
  String get saveDocument;

  /// No description provided for @writeNote.
  ///
  /// In en, this message translates to:
  /// **'Write Note'**
  String get writeNote;

  /// No description provided for @pleaseSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Please select file'**
  String get pleaseSelectFile;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Save successful'**
  String get saveSuccess;

  /// No description provided for @sectioninput.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectioninput;

  /// No description provided for @inputMessageHintDesktop.
  ///
  /// In en, this message translates to:
  /// **'Enter message or drag files...(Enter to send)'**
  String get inputMessageHintDesktop;

  /// No description provided for @inputMessageHintMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter message or drag files...'**
  String get inputMessageHintMobile;

  /// No description provided for @addDescriptionText.
  ///
  /// In en, this message translates to:
  /// **'Add description text...(Enter to send)'**
  String get addDescriptionText;

  /// No description provided for @sectionmenu.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionmenu;

  /// No description provided for @sideMenu.
  ///
  /// In en, this message translates to:
  /// **'Side Menu'**
  String get sideMenu;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @networkDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Network Diagnostics'**
  String get networkDiagnostics;

  /// No description provided for @currentDevice.
  ///
  /// In en, this message translates to:
  /// **'Current Device'**
  String get currentDevice;

  /// No description provided for @systemInfo.
  ///
  /// In en, this message translates to:
  /// **'System Information'**
  String get systemInfo;

  /// No description provided for @noGroup.
  ///
  /// In en, this message translates to:
  /// **'No Group'**
  String get noGroup;

  /// No description provided for @sectionpriority.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionpriority;

  /// No description provided for @highPriority.
  ///
  /// In en, this message translates to:
  /// **'High Priority'**
  String get highPriority;

  /// No description provided for @mediumPriority.
  ///
  /// In en, this message translates to:
  /// **'Medium Priority'**
  String get mediumPriority;

  /// No description provided for @lowPriority.
  ///
  /// In en, this message translates to:
  /// **'Low Priority'**
  String get lowPriority;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @sectionaccount.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionaccount;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account: {username} • Website: {website}'**
  String accountInfo(String username, String website);

  /// No description provided for @sectionforms.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionforms;

  /// No description provided for @loginAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Login account'**
  String get loginAccountHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Login password'**
  String get passwordHint;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @otherInfoHint.
  ///
  /// In en, this message translates to:
  /// **'Other information'**
  String get otherInfoHint;

  /// No description provided for @expenseItemHint.
  ///
  /// In en, this message translates to:
  /// **'e.g.: Lunch, Shopping'**
  String get expenseItemHint;

  /// No description provided for @amountHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get amountHint;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g.: Food, Transportation'**
  String get categoryHint;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @detailsHint.
  ///
  /// In en, this message translates to:
  /// **'Detailed description'**
  String get detailsHint;

  /// No description provided for @scheduleTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Meeting, appointment, etc.'**
  String get scheduleTitleHint;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTimeLabel;

  /// No description provided for @endTimeOptional.
  ///
  /// In en, this message translates to:
  /// **'End Time (Optional)'**
  String get endTimeOptional;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @locationHint.
  ///
  /// In en, this message translates to:
  /// **'Meeting room, restaurant, etc.'**
  String get locationHint;

  /// No description provided for @detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsLabel;

  /// No description provided for @meetingDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Meeting content, notes'**
  String get meetingDetailsHint;

  /// No description provided for @minutes5Before.
  ///
  /// In en, this message translates to:
  /// **'5 minutes before'**
  String get minutes5Before;

  /// No description provided for @minutes15Before.
  ///
  /// In en, this message translates to:
  /// **'15 minutes before'**
  String get minutes15Before;

  /// No description provided for @minutes30Before.
  ///
  /// In en, this message translates to:
  /// **'30 minutes before'**
  String get minutes30Before;

  /// No description provided for @hour1Before.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get hour1Before;

  /// No description provided for @taskLabel.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get taskLabel;

  /// No description provided for @taskRequirementsHint.
  ///
  /// In en, this message translates to:
  /// **'Specific requirements, notes'**
  String get taskRequirementsHint;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// No description provided for @dueDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Due Date (Optional)'**
  String get dueDateOptional;

  /// No description provided for @websiteLinkName.
  ///
  /// In en, this message translates to:
  /// **'Website or link name'**
  String get websiteLinkName;

  /// No description provided for @urlLink.
  ///
  /// In en, this message translates to:
  /// **'URL Link'**
  String get urlLink;

  /// No description provided for @sectionshare.
  ///
  /// In en, this message translates to:
  /// **''**
  String get sectionshare;

  /// No description provided for @confirmShare.
  ///
  /// In en, this message translates to:
  /// **'Confirm Share'**
  String get confirmShare;

  /// No description provided for @textSent.
  ///
  /// In en, this message translates to:
  /// **'Text sent'**
  String get textSent;

  /// No description provided for @fileSent.
  ///
  /// In en, this message translates to:
  /// **'File sent'**
  String get fileSent;

  /// No description provided for @filesSent.
  ///
  /// In en, this message translates to:
  /// **'{count} files sent'**
  String filesSent(int count);
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
