import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
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
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('es'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Beacon'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Find Healthcare Resources'**
  String get homeGreeting;

  /// No description provided for @homeFavorites.
  ///
  /// In en, this message translates to:
  /// **'Your Favorites'**
  String get homeFavorites;

  /// No description provided for @homeNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get homeNoFavorites;

  /// No description provided for @homeNoFavoritesHint.
  ///
  /// In en, this message translates to:
  /// **'Add favorites from the map page to see them here'**
  String get homeNoFavoritesHint;

  /// No description provided for @homeNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby Resources'**
  String get homeNearby;

  /// No description provided for @homeQuickFind.
  ///
  /// In en, this message translates to:
  /// **'Quick Find'**
  String get homeQuickFind;

  /// No description provided for @homeUrgentCare.
  ///
  /// In en, this message translates to:
  /// **'Urgent Care'**
  String get homeUrgentCare;

  /// No description provided for @homeHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing Shelters'**
  String get homeHousing;

  /// No description provided for @homeFreeClinics.
  ///
  /// In en, this message translates to:
  /// **'Free Clinics'**
  String get homeFreeClinics;

  /// No description provided for @homeFoodPantry.
  ///
  /// In en, this message translates to:
  /// **'Food Pantry'**
  String get homeFoodPantry;

  /// No description provided for @mapResourcesNearYou.
  ///
  /// In en, this message translates to:
  /// **'Resources near you'**
  String get mapResourcesNearYou;

  /// No description provided for @mapSwipeUp.
  ///
  /// In en, this message translates to:
  /// **'Swipe up to view resources'**
  String get mapSwipeUp;

  /// No description provided for @mapSearchFacilities.
  ///
  /// In en, this message translates to:
  /// **'Search facilities...'**
  String get mapSearchFacilities;

  /// No description provided for @mapSearchLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter ZIP code'**
  String get mapSearchLocation;

  /// No description provided for @mapLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading facilities...'**
  String get mapLoading;

  /// No description provided for @mapNoResults.
  ///
  /// In en, this message translates to:
  /// **'No facilities found in this area'**
  String get mapNoResults;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsSignedInWith.
  ///
  /// In en, this message translates to:
  /// **'Signed in with {provider}'**
  String settingsSignedInWith(String provider);

  /// No description provided for @settingsApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsApp;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsEligibility.
  ///
  /// In en, this message translates to:
  /// **'Eligibility Preferences'**
  String get settingsEligibility;

  /// No description provided for @settingsZipCode.
  ///
  /// In en, this message translates to:
  /// **'ZIP Code'**
  String get settingsZipCode;

  /// No description provided for @settingsWheelchair.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair accessible'**
  String get settingsWheelchair;

  /// No description provided for @settingsProofOfIncome.
  ///
  /// In en, this message translates to:
  /// **'Proof of income available'**
  String get settingsProofOfIncome;

  /// No description provided for @settingsInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance status'**
  String get settingsInsurance;

  /// No description provided for @settingsWalkIns.
  ///
  /// In en, this message translates to:
  /// **'Accepts walk-ins'**
  String get settingsWalkIns;

  /// No description provided for @settingsTelehealth.
  ///
  /// In en, this message translates to:
  /// **'Telehealth preference'**
  String get settingsTelehealth;

  /// No description provided for @settingsHouseholdSize.
  ///
  /// In en, this message translates to:
  /// **'Household size'**
  String get settingsHouseholdSize;

  /// No description provided for @settingsAnnualIncome.
  ///
  /// In en, this message translates to:
  /// **'Annual income'**
  String get settingsAnnualIncome;

  /// No description provided for @settingsEmployment.
  ///
  /// In en, this message translates to:
  /// **'Employment status'**
  String get settingsEmployment;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTermsOfService;

  /// No description provided for @settingsDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get settingsDeveloper;

  /// No description provided for @settingsDemoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode'**
  String get settingsDemoMode;

  /// No description provided for @settingsDemoModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Use mock data and skip authentication'**
  String get settingsDemoModeDesc;

  /// No description provided for @settingsDemoModeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Switching demo mode will restart the app flow. Continue?'**
  String get settingsDemoModeConfirm;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get settingsSignOutConfirm;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get profileName;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileZipCode.
  ///
  /// In en, this message translates to:
  /// **'ZIP Code'**
  String get profileZipCode;

  /// No description provided for @profileDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get profileDateOfBirth;

  /// No description provided for @profileMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get profileMonth;

  /// No description provided for @profileYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get profileYear;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get profileLanguage;

  /// No description provided for @profileOptionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Optional Information'**
  String get profileOptionalInfo;

  /// No description provided for @profileGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileGender;

  /// No description provided for @profileHouseholdSize.
  ///
  /// In en, this message translates to:
  /// **'Household Size'**
  String get profileHouseholdSize;

  /// No description provided for @profileAnnualIncome.
  ///
  /// In en, this message translates to:
  /// **'Annual Income'**
  String get profileAnnualIncome;

  /// No description provided for @profileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get profileSaveChanges;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @profileChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get profileChangePassword;

  /// No description provided for @profilePrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get profilePrivacyPolicy;

  /// No description provided for @profileCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an Account'**
  String get profileCreateAccount;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueWithApple;

  /// No description provided for @authContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get authContinueAsGuest;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By clicking continue, you agree to our '**
  String get authTermsPrefix;

  /// No description provided for @authTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get authTermsOfService;

  /// No description provided for @authAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get authAnd;

  /// No description provided for @authPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacyPolicy;

  /// No description provided for @authSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select a language 🌐'**
  String get authSelectLanguage;

  /// No description provided for @authSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get authSigningIn;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonYesPerYear.
  ///
  /// In en, this message translates to:
  /// **'{amount}/year'**
  String commonYesPerYear(String amount);

  /// No description provided for @filterCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get filterCategories;

  /// No description provided for @filterDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get filterDistance;

  /// No description provided for @filterOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get filterOpenNow;

  /// No description provided for @filterFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get filterFavorites;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get filterApply;

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
