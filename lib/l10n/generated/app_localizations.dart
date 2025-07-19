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

  /// No description provided for @monthDay.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day}'**
  String monthDay(int month, int day);

  /// No description provided for @expiresInHoursAndMinutes.
  ///
  /// In en, this message translates to:
  /// **'Expires in {hours}h {minutes}m'**
  String expiresInHoursAndMinutes(int hours, int minutes);

  /// No description provided for @expiresInMinutes.
  ///
  /// In en, this message translates to:
  /// **'Expires in {minutes}m'**
  String expiresInMinutes(int minutes);

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @yearMonthDay.
  ///
  /// In en, this message translates to:
  /// **'{year}/{month}/{day}'**
  String yearMonthDay(int year, int month, int day);

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
  /// **'Device registration is required for the first use, which will generate a unique identifier for you.'**
  String get deviceRegistration;

  /// No description provided for @joinGroupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Joined group successfully'**
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

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @scanQRCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQRCode;

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

  /// No description provided for @appSlogan.
  ///
  /// In en, this message translates to:
  /// **'Your personal file transfer assistant'**
  String get appSlogan;

  /// No description provided for @myFiles.
  ///
  /// In en, this message translates to:
  /// **'My Files'**
  String get myFiles;

  /// No description provided for @filesFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Files Feature Coming Soon'**
  String get filesFeatureComingSoon;

  /// No description provided for @stayTuned.
  ///
  /// In en, this message translates to:
  /// **'Stay tuned!'**
  String get stayTuned;

  /// No description provided for @noDeviceGroups.
  ///
  /// In en, this message translates to:
  /// **'No Device Groups'**
  String get noDeviceGroups;

  /// No description provided for @scanQRToJoin.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code to join a group'**
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
  String deviceCount(Object count);

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
  /// **'Created on {date}'**
  String createdOn(String date);

  /// No description provided for @unknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownDate;

  /// No description provided for @memoriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{No Memories} =1{1 Memory} other{{count} Memories}}'**
  String memoriesCount(num count);

  /// No description provided for @searchMemories.
  ///
  /// In en, this message translates to:
  /// **'Search memories...'**
  String get searchMemories;

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

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @noMemories.
  ///
  /// In en, this message translates to:
  /// **'No Memories Yet'**
  String get noMemories;

  /// No description provided for @noMemoriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Create your first memory to get started!'**
  String get noMemoriesDesc;

  /// No description provided for @createMemory.
  ///
  /// In en, this message translates to:
  /// **'Create Memory'**
  String get createMemory;

  /// No description provided for @quickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get quickAdd;

  /// No description provided for @memoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Memory'**
  String get memoryDeleteTitle;

  /// No description provided for @confirmDeleteMemory.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this memory?'**
  String get confirmDeleteMemory;

  /// No description provided for @deleteMemorySuccess.
  ///
  /// In en, this message translates to:
  /// **'Memory deleted successfully'**
  String get deleteMemorySuccess;

  /// No description provided for @deleteMemoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete memory'**
  String get deleteMemoryFailed;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day}'**
  String dateFormat(Object day, Object month);

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @passwords.
  ///
  /// In en, this message translates to:
  /// **'Passwords'**
  String get passwords;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @quickTexts.
  ///
  /// In en, this message translates to:
  /// **'Quick Texts'**
  String get quickTexts;

  /// No description provided for @myMemory.
  ///
  /// In en, this message translates to:
  /// **'My Memory'**
  String get myMemory;

  /// No description provided for @groupMemory.
  ///
  /// In en, this message translates to:
  /// **'{groupName}\'s Memory'**
  String groupMemory(Object groupName);

  /// No description provided for @totalItemsSaved.
  ///
  /// In en, this message translates to:
  /// **'{count} items saved'**
  String totalItemsSaved(Object count);

  /// No description provided for @selectGroupToView.
  ///
  /// In en, this message translates to:
  /// **'Select a group to view memories'**
  String get selectGroupToView;

  /// No description provided for @groupStorage.
  ///
  /// In en, this message translates to:
  /// **'Group Storage'**
  String get groupStorage;

  /// No description provided for @localStory.
  ///
  /// In en, this message translates to:
  /// **'Local Storage'**
  String get localStory;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No Notes Yet'**
  String get noNotes;

  /// No description provided for @recordImportantInfo.
  ///
  /// In en, this message translates to:
  /// **'Record important information and ideas'**
  String get recordImportantInfo;

  /// No description provided for @noPasswords.
  ///
  /// In en, this message translates to:
  /// **'No Passwords Yet'**
  String get noPasswords;

  /// No description provided for @securelyStore.
  ///
  /// In en, this message translates to:
  /// **'Securely store your account passwords'**
  String get securelyStore;

  /// No description provided for @noContacts.
  ///
  /// In en, this message translates to:
  /// **'No Contacts Yet'**
  String get noContacts;

  /// No description provided for @saveImportantContacts.
  ///
  /// In en, this message translates to:
  /// **'Save important contact information'**
  String get saveImportantContacts;

  /// No description provided for @noQuickTexts.
  ///
  /// In en, this message translates to:
  /// **'No Quick Texts Yet'**
  String get noQuickTexts;

  /// No description provided for @saveCommonTexts.
  ///
  /// In en, this message translates to:
  /// **'Save common texts and templates'**
  String get saveCommonTexts;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

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

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addPassword.
  ///
  /// In en, this message translates to:
  /// **'Add Password'**
  String get addPassword;

  /// No description provided for @editPassword.
  ///
  /// In en, this message translates to:
  /// **'Edit Password'**
  String get editPassword;

  /// No description provided for @site.
  ///
  /// In en, this message translates to:
  /// **'Site/App'**
  String get site;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username/Email'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get addContact;

  /// No description provided for @editContact.
  ///
  /// In en, this message translates to:
  /// **'Edit Contact'**
  String get editContact;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @addQuickText.
  ///
  /// In en, this message translates to:
  /// **'Add Quick Text'**
  String get addQuickText;

  /// No description provided for @editQuickText.
  ///
  /// In en, this message translates to:
  /// **'Edit Quick Text'**
  String get editQuickText;

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
  /// **'Enter a title for your memory'**
  String get titleHint;

  /// No description provided for @contentLabel.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get contentLabel;

  /// No description provided for @writeYourThoughts.
  ///
  /// In en, this message translates to:
  /// **'Write down your thoughts...'**
  String get writeYourThoughts;

  /// No description provided for @websiteAppName.
  ///
  /// In en, this message translates to:
  /// **'Website/App Name'**
  String get websiteAppName;

  /// No description provided for @websiteAppNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Google, Facebook'**
  String get websiteAppNameHint;

  /// No description provided for @websiteAddress.
  ///
  /// In en, this message translates to:
  /// **'Website Address'**
  String get websiteAddress;

  /// No description provided for @websiteAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., https://www.google.com'**
  String get websiteAddressHint;

  /// No description provided for @usernameEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Username/Email'**
  String get usernameEmailLabel;

  /// No description provided for @loginAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Your login account'**
  String get loginAccountHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Your login password'**
  String get passwordHint;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @otherInfoHint.
  ///
  /// In en, this message translates to:
  /// **'Other information, such as security questions'**
  String get otherInfoHint;

  /// No description provided for @expenseItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Expense Item'**
  String get expenseItemLabel;

  /// No description provided for @expenseItemHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Coffee, Lunch'**
  String get expenseItemHint;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @amountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 25.50'**
  String get amountHint;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

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

  /// No description provided for @preparingToSendFiles.
  ///
  /// In en, this message translates to:
  /// **'Preparing to send files...'**
  String get preparingToSendFiles;

  /// No description provided for @shareSuccess.
  ///
  /// In en, this message translates to:
  /// **'Share Successful'**
  String get shareSuccess;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Share Failed'**
  String get shareFailed;

  /// No description provided for @shareException.
  ///
  /// In en, this message translates to:
  /// **'Share Exception'**
  String get shareException;

  /// No description provided for @contentSentToGroup.
  ///
  /// In en, this message translates to:
  /// **'Content has been sent to the current group'**
  String get contentSentToGroup;

  /// No description provided for @pleaseTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get pleaseTryAgainLater;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @waitingForApp.
  ///
  /// In en, this message translates to:
  /// **'Waiting for app to start...'**
  String get waitingForApp;

  /// No description provided for @appSlowToStart.
  ///
  /// In en, this message translates to:
  /// **'App is slow to start, trying to process share...'**
  String get appSlowToStart;

  /// No description provided for @tryAgainIfFailed.
  ///
  /// In en, this message translates to:
  /// **'If it fails, please try sharing again'**
  String get tryAgainIfFailed;

  /// No description provided for @processingShare.
  ///
  /// In en, this message translates to:
  /// **'Processing share...'**
  String get processingShare;

  /// No description provided for @subscriptionPricingTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription & Pricing'**
  String get subscriptionPricingTitle;

  /// No description provided for @subscriptionPricingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your plan'**
  String get subscriptionPricingSubtitle;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until: {date}'**
  String validUntil(Object date);

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get mostPopular;

  /// No description provided for @monthlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Monthly Plan'**
  String get monthlyPlan;

  /// No description provided for @yearlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Yearly Plan'**
  String get yearlyPlan;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @priceVariesByRegion.
  ///
  /// In en, this message translates to:
  /// **'Price may vary by region.'**
  String get priceVariesByRegion;

  /// No description provided for @purchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchase Successful'**
  String get purchaseSuccess;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase Failed'**
  String get purchaseFailed;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get freePlan;

  /// No description provided for @deviceLimit.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} devices'**
  String deviceLimit(Object count);

  /// No description provided for @chooseYourPlan.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Plan'**
  String get chooseYourPlan;

  /// No description provided for @basicPlan.
  ///
  /// In en, this message translates to:
  /// **'Basic Plan'**
  String get basicPlan;

  /// No description provided for @proPlan.
  ///
  /// In en, this message translates to:
  /// **'Pro Plan'**
  String get proPlan;

  /// No description provided for @enterprisePlan.
  ///
  /// In en, this message translates to:
  /// **'Enterprise Plan'**
  String get enterprisePlan;

  /// No description provided for @freePlanDescription.
  ///
  /// In en, this message translates to:
  /// **'For personal use'**
  String get freePlanDescription;

  /// No description provided for @basicPlanDescription.
  ///
  /// In en, this message translates to:
  /// **'For small teams'**
  String get basicPlanDescription;

  /// No description provided for @proPlanDescription.
  ///
  /// In en, this message translates to:
  /// **'For growing businesses'**
  String get proPlanDescription;

  /// No description provided for @enterprisePlanDescription.
  ///
  /// In en, this message translates to:
  /// **'For large organizations'**
  String get enterprisePlanDescription;

  /// No description provided for @feature2DeviceGroup.
  ///
  /// In en, this message translates to:
  /// **'Up to 2 devices in a group'**
  String get feature2DeviceGroup;

  /// No description provided for @featureBasicFileTransfer.
  ///
  /// In en, this message translates to:
  /// **'Basic file transfer (up to 100MB)'**
  String get featureBasicFileTransfer;

  /// No description provided for @featureTextMessage.
  ///
  /// In en, this message translates to:
  /// **'Text messages'**
  String get featureTextMessage;

  /// No description provided for @featureImageTransfer.
  ///
  /// In en, this message translates to:
  /// **'Image transfer'**
  String get featureImageTransfer;

  /// No description provided for @feature5DeviceGroup.
  ///
  /// In en, this message translates to:
  /// **'Up to 5 devices in a group'**
  String get feature5DeviceGroup;

  /// No description provided for @featureUnlimitedFileTransfer.
  ///
  /// In en, this message translates to:
  /// **'Unlimited file transfer (up to 1GB)'**
  String get featureUnlimitedFileTransfer;

  /// No description provided for @featureVideoTransfer.
  ///
  /// In en, this message translates to:
  /// **'Video transfer'**
  String get featureVideoTransfer;

  /// No description provided for @cameraUnavailableSwitchedToInput.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable, switched to input mode.'**
  String get cameraUnavailableSwitchedToInput;

  /// No description provided for @desktopCameraUnstableTip.
  ///
  /// In en, this message translates to:
  /// **'Desktop camera scanning may be unstable, it is recommended to use input mode.'**
  String get desktopCameraUnstableTip;

  /// No description provided for @joinGroupSuccessExclamation.
  ///
  /// In en, this message translates to:
  /// **'Joined group successfully!'**
  String get joinGroupSuccessExclamation;

  /// No description provided for @joinGroupFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Failed to join group.'**
  String get joinGroupFailedGeneric;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {error}'**
  String operationFailed(Object error);

  /// No description provided for @pleaseEnterInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the invite code.'**
  String get pleaseEnterInviteCode;

  /// No description provided for @inviteCodeLengthError.
  ///
  /// In en, this message translates to:
  /// **'Invite code length error.'**
  String get inviteCodeLengthError;

  /// No description provided for @loadDevicesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load devices'**
  String get loadDevicesFailed;

  /// No description provided for @createJoinCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create join code'**
  String get createJoinCodeFailed;

  /// No description provided for @leaveGroupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Left group successfully'**
  String get leaveGroupSuccess;

  /// No description provided for @leaveGroupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to leave group'**
  String get leaveGroupFailed;

  /// No description provided for @groupInfoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Group info updated'**
  String get groupInfoUpdated;

  /// No description provided for @refreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Refresh failed'**
  String get refreshFailed;

  /// No description provided for @deviceGroup.
  ///
  /// In en, this message translates to:
  /// **'Device Group'**
  String get deviceGroup;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get leaveGroup;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// No description provided for @generateDeviceJoinCode.
  ///
  /// In en, this message translates to:
  /// **'Generate Device Join Code'**
  String get generateDeviceJoinCode;

  /// No description provided for @scanQRToJoinDeviceGroup.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code to join this device group'**
  String get scanQRToJoinDeviceGroup;

  /// No description provided for @joinCode.
  ///
  /// In en, this message translates to:
  /// **'Join Code'**
  String get joinCode;

  /// No description provided for @copyJoinCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Join Code'**
  String get copyJoinCode;

  /// No description provided for @joinCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Join code copied to clipboard'**
  String get joinCodeCopied;

  /// No description provided for @expiresAt.
  ///
  /// In en, this message translates to:
  /// **'Expires at: {date}'**
  String expiresAt(Object date);

  /// No description provided for @deviceList.
  ///
  /// In en, this message translates to:
  /// **'Device List'**
  String get deviceList;

  /// No description provided for @noDevicesToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No devices to display'**
  String get noDevicesToDisplay;

  /// No description provided for @unnamedDevice.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Device'**
  String get unnamedDevice;

  /// No description provided for @currentDevice.
  ///
  /// In en, this message translates to:
  /// **'Current Device'**
  String get currentDevice;

  /// No description provided for @groupOwner.
  ///
  /// In en, this message translates to:
  /// **'Group Owner'**
  String get groupOwner;

  /// No description provided for @unknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown Device'**
  String get unknownDevice;

  /// No description provided for @unknownPlatform.
  ///
  /// In en, this message translates to:
  /// **'Unknown Platform'**
  String get unknownPlatform;

  /// No description provided for @removeDevice.
  ///
  /// In en, this message translates to:
  /// **'Remove Device'**
  String get removeDevice;

  /// No description provided for @confirmLeaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this device group?'**
  String get confirmLeaveGroup;

  /// No description provided for @confirmRemoveDevice.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the device'**
  String get confirmRemoveDevice;

  /// No description provided for @removeDeviceFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Remove device feature coming soon'**
  String get removeDeviceFeatureComingSoon;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @loadGroupInfoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load group info'**
  String get loadGroupInfoFailed;

  /// No description provided for @renameGroup.
  ///
  /// In en, this message translates to:
  /// **'Rename Group'**
  String get renameGroup;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @enterNewGroupName.
  ///
  /// In en, this message translates to:
  /// **'Enter a new group name'**
  String get enterNewGroupName;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Group name cannot be empty'**
  String get groupNameHint;

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

  /// No description provided for @groupLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this group?'**
  String get groupLeaveConfirm;

  /// No description provided for @editMemory.
  ///
  /// In en, this message translates to:
  /// **'Edit Memory'**
  String get editMemory;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter title'**
  String get enterTitle;

  /// No description provided for @enterContent.
  ///
  /// In en, this message translates to:
  /// **'Enter content'**
  String get enterContent;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get addTag;

  /// No description provided for @generateTags.
  ///
  /// In en, this message translates to:
  /// **'Generate Tags'**
  String get generateTags;

  /// No description provided for @generatingTags.
  ///
  /// In en, this message translates to:
  /// **'Generating tags...'**
  String get generatingTags;

  /// No description provided for @https.
  ///
  /// In en, this message translates to:
  /// **'https://...'**
  String get https;

  /// No description provided for @usernameEmail.
  ///
  /// In en, this message translates to:
  /// **'Username/Email'**
  String get usernameEmail;

  /// No description provided for @loginAccount.
  ///
  /// In en, this message translates to:
  /// **'Login account'**
  String get loginAccount;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Login password'**
  String get loginPassword;

  /// No description provided for @otherInformation.
  ///
  /// In en, this message translates to:
  /// **'Other information'**
  String get otherInformation;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @zeroZero.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get zeroZero;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @eg.
  ///
  /// In en, this message translates to:
  /// **'e.g.,'**
  String get eg;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @detailedExplanation.
  ///
  /// In en, this message translates to:
  /// **'Detailed explanation'**
  String get detailedExplanation;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTimeOptional.
  ///
  /// In en, this message translates to:
  /// **'End Time (Optional)'**
  String get endTimeOptional;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @conferenceRoomRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Conference room, restaurant, etc.'**
  String get conferenceRoomRestaurant;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @meetingContentNotes.
  ///
  /// In en, this message translates to:
  /// **'Meeting content, notes'**
  String get meetingContentNotes;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @noReminder.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get noReminder;

  /// No description provided for @fiveMinutesBefore.
  ///
  /// In en, this message translates to:
  /// **'5 minutes before'**
  String get fiveMinutesBefore;

  /// No description provided for @fifteenMinutesBefore.
  ///
  /// In en, this message translates to:
  /// **'15 minutes before'**
  String get fifteenMinutesBefore;

  /// No description provided for @thirtyMinutesBefore.
  ///
  /// In en, this message translates to:
  /// **'30 minutes before'**
  String get thirtyMinutesBefore;

  /// No description provided for @oneHourBefore.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get oneHourBefore;

  /// No description provided for @detailedDescription.
  ///
  /// In en, this message translates to:
  /// **'Detailed Description'**
  String get detailedDescription;

  /// No description provided for @specificRequirementsNotes.
  ///
  /// In en, this message translates to:
  /// **'Specific requirements, notes'**
  String get specificRequirementsNotes;

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

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @dueDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Due Date (Optional)'**
  String get dueDateOptional;

  /// No description provided for @urlLink.
  ///
  /// In en, this message translates to:
  /// **'URL Link'**
  String get urlLink;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @purposeOrContent.
  ///
  /// In en, this message translates to:
  /// **'Purpose or content of this link'**
  String get purposeOrContent;

  /// No description provided for @enterTagName.
  ///
  /// In en, this message translates to:
  /// **'Enter tag name'**
  String get enterTagName;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @updateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Update successful'**
  String get updateSuccess;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// No description provided for @catering.
  ///
  /// In en, this message translates to:
  /// **'Catering'**
  String get catering;

  /// No description provided for @transportation.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get transportation;

  /// No description provided for @scanDeviceJoinOtherDevices.
  ///
  /// In en, this message translates to:
  /// **'Scan with other devices to join'**
  String get scanDeviceJoinOtherDevices;

  /// No description provided for @joinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get joinGroup;

  /// No description provided for @expiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in'**
  String get expiresIn;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @noGroupInfo.
  ///
  /// In en, this message translates to:
  /// **'No group info available'**
  String get noGroupInfo;

  /// No description provided for @generateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate'**
  String get generateFailed;

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

  /// No description provided for @groupPrefix.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupPrefix;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2023 Send To Myself'**
  String get copyright;

  /// No description provided for @deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device Info'**
  String get deviceInfo;

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

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// No description provided for @deviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceId;

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

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

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

  /// No description provided for @sendFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Send file failed'**
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

  /// No description provided for @batchRecallReason.
  ///
  /// In en, this message translates to:
  /// **'Recall messages'**
  String get batchRecallReason;

  /// No description provided for @batchDelete.
  ///
  /// In en, this message translates to:
  /// **'Batch Delete'**
  String get batchDelete;

  /// No description provided for @confirmBatchDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} messages?'**
  String confirmBatchDelete(int count);

  /// No description provided for @batchDeleteReason.
  ///
  /// In en, this message translates to:
  /// **'Delete messages'**
  String get batchDeleteReason;

  /// No description provided for @batchDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully deleted {count} messages'**
  String batchDeleteSuccess(int count);

  /// No description provided for @batchDeleteFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Batch delete failed: {error}'**
  String batchDeleteFailedWithError(String error);

  /// No description provided for @debugInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Debug Info'**
  String get debugInfoTitle;

  /// No description provided for @permanentStorageDirectory.
  ///
  /// In en, this message translates to:
  /// **'Permanent Storage Directory'**
  String get permanentStorageDirectory;

  /// No description provided for @storageUsage.
  ///
  /// In en, this message translates to:
  /// **'Storage Usage'**
  String get storageUsage;

  /// No description provided for @fileCacheStats.
  ///
  /// In en, this message translates to:
  /// **'File Cache Stats'**
  String get fileCacheStats;

  /// No description provided for @deduplicationDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Deduplication Diagnostics'**
  String get deduplicationDiagnostics;

  /// No description provided for @clearDeduplicationRecords.
  ///
  /// In en, this message translates to:
  /// **'Clear Deduplication Records'**
  String get clearDeduplicationRecords;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a new conversation'**
  String get startConversation;

  /// No description provided for @sendMessageOrFileToStart.
  ///
  /// In en, this message translates to:
  /// **'Send a message or file to start'**
  String get sendMessageOrFileToStart;

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

  /// No description provided for @confirmCancelUpload.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel the upload?'**
  String get confirmCancelUpload;

  /// No description provided for @confirmCancelDownload.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel the download?'**
  String get confirmCancelDownload;

  /// No description provided for @continueTransfer.
  ///
  /// In en, this message translates to:
  /// **'Continue Transfer'**
  String get continueTransfer;

  /// No description provided for @confirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancel'**
  String get confirmCancel;

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

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @addDescriptionText.
  ///
  /// In en, this message translates to:
  /// **'Add description'**
  String get addDescriptionText;

  /// No description provided for @inputMessageHintDesktop.
  ///
  /// In en, this message translates to:
  /// **'Input message, paste screenshot, or drag file here'**
  String get inputMessageHintDesktop;

  /// No description provided for @inputMessageHintMobile.
  ///
  /// In en, this message translates to:
  /// **'Input message'**
  String get inputMessageHintMobile;

  /// No description provided for @imageFile.
  ///
  /// In en, this message translates to:
  /// **'Image File'**
  String get imageFile;

  /// No description provided for @videoFile.
  ///
  /// In en, this message translates to:
  /// **'Video File'**
  String get videoFile;

  /// No description provided for @documentFile.
  ///
  /// In en, this message translates to:
  /// **'Document File'**
  String get documentFile;

  /// No description provided for @audioFile.
  ///
  /// In en, this message translates to:
  /// **'Audio File'**
  String get audioFile;

  /// No description provided for @selectFileType.
  ///
  /// In en, this message translates to:
  /// **'Select file type'**
  String get selectFileType;

  /// No description provided for @selectFileTypeMultiple.
  ///
  /// In en, this message translates to:
  /// **'Select file type (multiple)'**
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
  /// **'No permission to download'**
  String get noPermissionToDownload;

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
  /// **'You can drag to select text'**
  String get canDragSelectText;

  /// No description provided for @allContentCopied.
  ///
  /// In en, this message translates to:
  /// **'All content copied'**
  String get allContentCopied;

  /// No description provided for @recallMessage.
  ///
  /// In en, this message translates to:
  /// **'Recall Message'**
  String get recallMessage;

  /// No description provided for @deleteMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get deleteMessageTitle;

  /// No description provided for @confirmDeleteSingleMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get confirmDeleteSingleMessage;

  /// No description provided for @messageContentAddedToInput.
  ///
  /// In en, this message translates to:
  /// **'Message content added to input'**
  String get messageContentAddedToInput;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get confirmDeleteMessage;

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

  /// No description provided for @messageShare.
  ///
  /// In en, this message translates to:
  /// **'Message Share'**
  String get messageShare;

  /// No description provided for @textShared.
  ///
  /// In en, this message translates to:
  /// **'Text shared'**
  String get textShared;

  /// No description provided for @messageRecalledText.
  ///
  /// In en, this message translates to:
  /// **'[You recalled a message]'**
  String get messageRecalledText;

  /// No description provided for @filePathCopied.
  ///
  /// In en, this message translates to:
  /// **'File path copied'**
  String get filePathCopied;

  /// No description provided for @copyFilePathFailed.
  ///
  /// In en, this message translates to:
  /// **'Copy file path failed'**
  String get copyFilePathFailed;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Work, Personal'**
  String get categoryHint;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Add notes...'**
  String get notesHint;

  /// No description provided for @scheduleTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule Title'**
  String get scheduleTitleLabel;

  /// No description provided for @scheduleTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Team Meeting'**
  String get scheduleTitleHint;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTimeLabel;

  /// No description provided for @endTimeOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'End Time (Optional)'**
  String get endTimeOptionalLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @locationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Conference Room A'**
  String get locationHint;

  /// No description provided for @detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsLabel;

  /// No description provided for @meetingDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Agenda, Attendees'**
  String get meetingDetailsHint;

  /// No description provided for @advanceReminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Advance Reminder'**
  String get advanceReminderLabel;

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

  /// No description provided for @whatToDoHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Buy groceries'**
  String get whatToDoHint;

  /// No description provided for @detailedDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Detailed Description'**
  String get detailedDescriptionLabel;

  /// No description provided for @taskRequirementsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Milk, Bread, Eggs'**
  String get taskRequirementsHint;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// No description provided for @dueDateOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Date (Optional)'**
  String get dueDateOptionalLabel;

  /// No description provided for @websiteLinkName.
  ///
  /// In en, this message translates to:
  /// **'Website/Link Name'**
  String get websiteLinkName;

  /// No description provided for @urlLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'URL/Link'**
  String get urlLinkLabel;

  /// No description provided for @linkDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get linkDescriptionLabel;

  /// No description provided for @linkPurposeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Project research'**
  String get linkPurposeHint;

  /// No description provided for @fileDescription.
  ///
  /// In en, this message translates to:
  /// **'File Description'**
  String get fileDescription;

  /// No description provided for @fileExplanation.
  ///
  /// In en, this message translates to:
  /// **'e.g., Contract draft'**
  String get fileExplanation;

  /// No description provided for @pleaseEnter.
  ///
  /// In en, this message translates to:
  /// **'Please enter {label}'**
  String pleaseEnter(String label);

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

  /// No description provided for @deleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTooltip;

  /// No description provided for @messageFilter.
  ///
  /// In en, this message translates to:
  /// **'Message Filter'**
  String get messageFilter;

  /// No description provided for @searchMessagesOrFiles.
  ///
  /// In en, this message translates to:
  /// **'Search messages or files'**
  String get searchMessagesOrFiles;

  /// No description provided for @messageType.
  ///
  /// In en, this message translates to:
  /// **'Message Type'**
  String get messageType;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @saveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save to Gallery'**
  String get saveToGallery;

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

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @noGroup.
  ///
  /// In en, this message translates to:
  /// **'No Group'**
  String get noGroup;

  /// No description provided for @memories.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get memories;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @groupDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Group Description (optional)'**
  String get groupDescriptionOptional;

  /// No description provided for @groupDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Enter group description'**
  String get groupDescriptionHint;

  /// No description provided for @pleaseEnterGroupName.
  ///
  /// In en, this message translates to:
  /// **'Please enter group name'**
  String get pleaseEnterGroupName;

  /// No description provided for @groupCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Group \'{name}\' created successfully'**
  String groupCreatedSuccessfully(String name);

  /// No description provided for @createGroupFailed.
  ///
  /// In en, this message translates to:
  /// **'Create group failed'**
  String get createGroupFailed;

  /// No description provided for @deviceOs.
  ///
  /// In en, this message translates to:
  /// **'Device OS'**
  String get deviceOs;

  /// No description provided for @deviceVersion.
  ///
  /// In en, this message translates to:
  /// **'Device Version'**
  String get deviceVersion;

  /// No description provided for @deviceRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Device registration failed'**
  String get deviceRegistrationFailed;

  /// No description provided for @placeQRInFrame.
  ///
  /// In en, this message translates to:
  /// **'Place QR code in the frame'**
  String get placeQRInFrame;

  /// No description provided for @joiningGroup.
  ///
  /// In en, this message translates to:
  /// **'Joining group...'**
  String get joiningGroup;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnecting;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @networkNormal.
  ///
  /// In en, this message translates to:
  /// **'Network normal'**
  String get networkNormal;

  /// No description provided for @networkLimited.
  ///
  /// In en, this message translates to:
  /// **'Network limited'**
  String get networkLimited;

  /// No description provided for @networkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Network unavailable'**
  String get networkUnavailable;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @loggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get loggingOut;

  /// No description provided for @logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get logoutSuccess;

  /// No description provided for @logoutError.
  ///
  /// In en, this message translates to:
  /// **'Error logging out'**
  String get logoutError;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get logoutFailed;

  /// No description provided for @loginStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Login status has expired'**
  String get loginStatusExpired;

  /// No description provided for @logoutFailedContent.
  ///
  /// In en, this message translates to:
  /// **'Logout failed. You can force logout or try again.'**
  String get logoutFailedContent;

  /// No description provided for @forceLogout.
  ///
  /// In en, this message translates to:
  /// **'Force Logout'**
  String get forceLogout;

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

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

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

  /// No description provided for @justActive.
  ///
  /// In en, this message translates to:
  /// **'Just active'**
  String get justActive;

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

  /// No description provided for @sendToMyself.
  ///
  /// In en, this message translates to:
  /// **'Send to myself'**
  String get sendToMyself;

  /// No description provided for @clickToStartGroupChat.
  ///
  /// In en, this message translates to:
  /// **'Click to start group chat'**
  String get clickToStartGroupChat;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations'**
  String get noConversations;

  /// No description provided for @joinGroupToStartChat.
  ///
  /// In en, this message translates to:
  /// **'Join a group to start chatting'**
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

  /// No description provided for @enterGroupCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Group Code'**
  String get enterGroupCode;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get cameraUnavailable;

  /// No description provided for @desktopInputModeRecommended.
  ///
  /// In en, this message translates to:
  /// **'Desktop input mode is recommended'**
  String get desktopInputModeRecommended;

  /// No description provided for @checkCameraPermissions.
  ///
  /// In en, this message translates to:
  /// **'Check camera permissions'**
  String get checkCameraPermissions;

  /// No description provided for @switchToInput.
  ///
  /// In en, this message translates to:
  /// **'Switch to Input'**
  String get switchToInput;

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

  /// No description provided for @switchToInputModeOrCheckPermissions.
  ///
  /// In en, this message translates to:
  /// **'Switch to input mode or check camera permissions'**
  String get switchToInputModeOrCheckPermissions;

  /// No description provided for @placeQRInScanFrame.
  ///
  /// In en, this message translates to:
  /// **'Place QR code in the scan frame'**
  String get placeQRInScanFrame;

  /// No description provided for @enterInviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter invite code'**
  String get enterInviteCodeHint;

  /// No description provided for @inviteCodePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get inviteCodePlaceholder;

  /// No description provided for @groupLeaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully left the group'**
  String get groupLeaveSuccess;

  /// No description provided for @groupLeaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to leave the group'**
  String get groupLeaveFailed;

  /// No description provided for @deviceRemoved.
  ///
  /// In en, this message translates to:
  /// **'Device removed'**
  String get deviceRemoved;

  /// No description provided for @groupManagement.
  ///
  /// In en, this message translates to:
  /// **'Group Management'**
  String get groupManagement;

  /// No description provided for @groupMembers.
  ///
  /// In en, this message translates to:
  /// **'Group Members'**
  String get groupMembers;

  /// No description provided for @generateQRCode.
  ///
  /// In en, this message translates to:
  /// **'Generate QR Code'**
  String get generateQRCode;

  /// No description provided for @noDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices'**
  String get noDevices;

  /// No description provided for @myself.
  ///
  /// In en, this message translates to:
  /// **'Myself'**
  String get myself;

  /// No description provided for @deviceConnected.
  ///
  /// In en, this message translates to:
  /// **'Device connected'**
  String get deviceConnected;

  /// No description provided for @subscriptionManagement.
  ///
  /// In en, this message translates to:
  /// **'Subscription Management'**
  String get subscriptionManagement;

  /// No description provided for @currentSubscription.
  ///
  /// In en, this message translates to:
  /// **'Current Subscription'**
  String get currentSubscription;

  /// No description provided for @supports.
  ///
  /// In en, this message translates to:
  /// **'Supports'**
  String get supports;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'App Name'**
  String get appName;

  /// No description provided for @logoutFromCurrentDevice.
  ///
  /// In en, this message translates to:
  /// **'Logout from current device'**
  String get logoutFromCurrentDevice;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @messageRecalled.
  ///
  /// In en, this message translates to:
  /// **'Message recalled'**
  String get messageRecalled;

  /// No description provided for @messageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// No description provided for @deleteFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Delete failed with error: {error}'**
  String deleteFailedWithError(String error);

  /// No description provided for @groupMemberLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Group member limit reached'**
  String get groupMemberLimitReached;

  /// No description provided for @upgradeToSupportMoreDevices.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to support more devices'**
  String get upgradeToSupportMoreDevices;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @upgradeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Subscription'**
  String get upgradeSubscription;

  /// No description provided for @viewSubscription.
  ///
  /// In en, this message translates to:
  /// **'View Subscription'**
  String get viewSubscription;

  /// No description provided for @youHaveBeenRemovedFromGroup.
  ///
  /// In en, this message translates to:
  /// **'You have been removed from the group'**
  String get youHaveBeenRemovedFromGroup;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @hasBeenDeleted.
  ///
  /// In en, this message translates to:
  /// **'has been deleted'**
  String get hasBeenDeleted;

  /// No description provided for @loadGroupsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load groups'**
  String get loadGroupsFailed;

  /// No description provided for @pleaseSelectAGroup.
  ///
  /// In en, this message translates to:
  /// **'Please select a group'**
  String get pleaseSelectAGroup;

  /// No description provided for @generateInviteCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate invite code'**
  String get generateInviteCodeFailed;

  /// No description provided for @currentCanAdd.
  ///
  /// In en, this message translates to:
  /// **'You can add'**
  String get currentCanAdd;

  /// No description provided for @devicesUnit.
  ///
  /// In en, this message translates to:
  /// **'devices'**
  String get devicesUnit;

  /// No description provided for @upgradeToBasicVersionCanSupport.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Basic version to support'**
  String get upgradeToBasicVersionCanSupport;

  /// No description provided for @fiveDevices.
  ///
  /// In en, this message translates to:
  /// **'5 devices'**
  String get fiveDevices;

  /// No description provided for @upgradeToProfessionalVersionCanSupport.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Professional version to support'**
  String get upgradeToProfessionalVersionCanSupport;

  /// No description provided for @tenDevices.
  ///
  /// In en, this message translates to:
  /// **'10 devices'**
  String get tenDevices;

  /// No description provided for @reachedMaxDeviceCount.
  ///
  /// In en, this message translates to:
  /// **'Reached max device count'**
  String get reachedMaxDeviceCount;

  /// No description provided for @getGroupDetailsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get group details'**
  String get getGroupDetailsFailed;

  /// No description provided for @getGroupMembersFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get group members'**
  String get getGroupMembersFailed;

  /// No description provided for @renameGroupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename group'**
  String get renameGroupFailed;

  /// No description provided for @removeDeviceFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove device'**
  String get removeDeviceFailed;

  /// No description provided for @renameDeviceFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename device'**
  String get renameDeviceFailed;

  /// No description provided for @groupMemberLimitReachedUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Group member limit reached. Upgrade subscription to support more devices.'**
  String get groupMemberLimitReachedUpgrade;

  /// No description provided for @upgradeToUnlockMoreFeatures.
  ///
  /// In en, this message translates to:
  /// **'Upgrade subscription to unlock more features:'**
  String get upgradeToUnlockMoreFeatures;

  /// No description provided for @basicVersion5Devices.
  ///
  /// In en, this message translates to:
  /// **'• Basic version: supports 5 devices'**
  String get basicVersion5Devices;

  /// No description provided for @proVersion10Devices.
  ///
  /// In en, this message translates to:
  /// **'• Pro version: supports 10 devices'**
  String get proVersion10Devices;
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
