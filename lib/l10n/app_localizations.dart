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

  /// No description provided for @homeRecentlyViewed.
  ///
  /// In en, this message translates to:
  /// **'Recently Viewed Facilities'**
  String get homeRecentlyViewed;

  /// No description provided for @homeNoRecentlyViewed.
  ///
  /// In en, this message translates to:
  /// **'No recently viewed facilities'**
  String get homeNoRecentlyViewed;

  /// No description provided for @homeNoRecentlyViewedHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a facility on the map to see it here.'**
  String get homeNoRecentlyViewedHint;

  /// No description provided for @mapSearchLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter ZIP code'**
  String get mapSearchLocation;

  /// No description provided for @mapSearchResourcesHint.
  ///
  /// In en, this message translates to:
  /// **'Search for resources...'**
  String get mapSearchResourcesHint;

  /// No description provided for @mapAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Map area'**
  String get mapAreaLabel;

  /// No description provided for @mapSearchThisArea.
  ///
  /// In en, this message translates to:
  /// **'Search this area'**
  String get mapSearchThisArea;

  /// No description provided for @mapSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get mapSearching;

  /// No description provided for @mapSwipeUpToView.
  ///
  /// In en, this message translates to:
  /// **'Swipe up to view resources'**
  String get mapSwipeUpToView;

  /// No description provided for @mapResourcesNearYou.
  ///
  /// In en, this message translates to:
  /// **'Resources near you'**
  String get mapResourcesNearYou;

  /// No description provided for @mapNoFacilitiesInArea.
  ///
  /// In en, this message translates to:
  /// **'No facilities in this area'**
  String get mapNoFacilitiesInArea;

  /// No description provided for @mapCantFindFacility.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find a facility? Submit a request to add one.'**
  String get mapCantFindFacility;

  /// No description provided for @mapRequestFacility.
  ///
  /// In en, this message translates to:
  /// **'Request a facility'**
  String get mapRequestFacility;

  /// No description provided for @mapLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load facilities. Please try again.'**
  String get mapLoadFailed;

  /// No description provided for @mapRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get mapRetry;

  /// No description provided for @mapInvalidZip.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 5-digit zip code (e.g., 60605)'**
  String get mapInvalidZip;

  /// No description provided for @mapZipNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find location for zip code {zipCode}.'**
  String mapZipNotFound(String zipCode);

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

  /// No description provided for @filterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filterCategory;

  /// No description provided for @filterPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get filterPreferences;

  /// No description provided for @filterFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterFilters;

  /// No description provided for @filterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get filterClearAll;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @eligProofOfIncome.
  ///
  /// In en, this message translates to:
  /// **'Proof of income required'**
  String get eligProofOfIncome;

  /// No description provided for @eligProofOfResidency.
  ///
  /// In en, this message translates to:
  /// **'Proof of residency required'**
  String get eligProofOfResidency;

  /// No description provided for @eligInsuranceRequired.
  ///
  /// In en, this message translates to:
  /// **'Insurance required'**
  String get eligInsuranceRequired;

  /// No description provided for @eligReferralRequired.
  ///
  /// In en, this message translates to:
  /// **'Referral required'**
  String get eligReferralRequired;

  /// No description provided for @prefAcceptsWalkIns.
  ///
  /// In en, this message translates to:
  /// **'Accepts walk-ins'**
  String get prefAcceptsWalkIns;

  /// No description provided for @prefAppointmentOnly.
  ///
  /// In en, this message translates to:
  /// **'Appointment only'**
  String get prefAppointmentOnly;

  /// No description provided for @prefOpenToImmigrants.
  ///
  /// In en, this message translates to:
  /// **'Open to immigrants'**
  String get prefOpenToImmigrants;

  /// No description provided for @prefFreeServices.
  ///
  /// In en, this message translates to:
  /// **'Free services available'**
  String get prefFreeServices;

  /// No description provided for @prefSlidingScale.
  ///
  /// In en, this message translates to:
  /// **'Sliding scale available'**
  String get prefSlidingScale;

  /// No description provided for @prefOtherLanguages.
  ///
  /// In en, this message translates to:
  /// **'Other languages available'**
  String get prefOtherLanguages;

  /// No description provided for @prefTelehealth.
  ///
  /// In en, this message translates to:
  /// **'Telehealth available'**
  String get prefTelehealth;

  /// No description provided for @prefWheelchairAccessible.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair accessible'**
  String get prefWheelchairAccessible;

  /// No description provided for @prefServesOutsideArea.
  ///
  /// In en, this message translates to:
  /// **'Serves outside area'**
  String get prefServesOutsideArea;

  /// No description provided for @cardNextSteps.
  ///
  /// In en, this message translates to:
  /// **'Next Steps'**
  String get cardNextSteps;

  /// No description provided for @cardHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get cardHours;

  /// No description provided for @cardServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get cardServices;

  /// No description provided for @cardAtAGlance.
  ///
  /// In en, this message translates to:
  /// **'At a Glance'**
  String get cardAtAGlance;

  /// No description provided for @cardVisitWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit website'**
  String get cardVisitWebsite;

  /// No description provided for @cardWebsiteNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Website not available'**
  String get cardWebsiteNotAvailable;

  /// No description provided for @cardGetDirections.
  ///
  /// In en, this message translates to:
  /// **'Get directions'**
  String get cardGetDirections;

  /// No description provided for @cardContactForHours.
  ///
  /// In en, this message translates to:
  /// **'Contact facility for hours'**
  String get cardContactForHours;

  /// No description provided for @cardOpen247.
  ///
  /// In en, this message translates to:
  /// **'Open 24/7'**
  String get cardOpen247;

  /// No description provided for @cardAddressNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Address information not available for this facility'**
  String get cardAddressNotAvailable;

  /// No description provided for @chipWalkIns.
  ///
  /// In en, this message translates to:
  /// **'Walk-ins'**
  String get chipWalkIns;

  /// No description provided for @chipFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get chipFree;

  /// No description provided for @chipTelehealth.
  ///
  /// In en, this message translates to:
  /// **'Telehealth'**
  String get chipTelehealth;

  /// No description provided for @chipAccessible.
  ///
  /// In en, this message translates to:
  /// **'Accessible'**
  String get chipAccessible;

  /// No description provided for @chipSlidingScale.
  ///
  /// In en, this message translates to:
  /// **'Sliding Scale'**
  String get chipSlidingScale;

  /// No description provided for @chipOtherLanguages.
  ///
  /// In en, this message translates to:
  /// **'Other Languages'**
  String get chipOtherLanguages;

  /// No description provided for @ratingAlreadyRated.
  ///
  /// In en, this message translates to:
  /// **'You already rated this — update it below.'**
  String get ratingAlreadyRated;

  /// No description provided for @ratingDateVisited.
  ///
  /// In en, this message translates to:
  /// **'Date visited'**
  String get ratingDateVisited;

  /// No description provided for @ratingRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get ratingRemove;

  /// No description provided for @ratingSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get ratingSubmit;

  /// No description provided for @ratingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get ratingUpdate;

  /// No description provided for @ratingThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your rating!'**
  String get ratingThanks;

  /// No description provided for @ratingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Rating updated.'**
  String get ratingUpdated;

  /// No description provided for @ratingRemoved.
  ///
  /// In en, this message translates to:
  /// **'Rating removed.'**
  String get ratingRemoved;

  /// No description provided for @ratingSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send rating. Please try again.'**
  String get ratingSendFailed;

  /// No description provided for @ratingRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove rating. Please try again.'**
  String get ratingRemoveFailed;

  /// No description provided for @ratingSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in required to rate a facility.'**
  String get ratingSignInRequired;

  /// No description provided for @requestDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Request a facility'**
  String get requestDialogTitle;

  /// No description provided for @requestDialogIntro.
  ///
  /// In en, this message translates to:
  /// **'Tell us about a facility we\'re missing and our team will review it.'**
  String get requestDialogIntro;

  /// No description provided for @requestFieldName.
  ///
  /// In en, this message translates to:
  /// **'Facility name *'**
  String get requestFieldName;

  /// No description provided for @requestFieldNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter the facility name'**
  String get requestFieldNameError;

  /// No description provided for @requestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request submitted — we\'ll review it soon. Thanks!'**
  String get requestSubmitted;

  /// No description provided for @requestSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t submit request. Please try again.'**
  String get requestSubmitFailed;

  /// No description provided for @requestSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in required to submit a request.'**
  String get requestSignInRequired;

  /// No description provided for @settingsYourRatings.
  ///
  /// In en, this message translates to:
  /// **'Your Ratings'**
  String get settingsYourRatings;

  /// No description provided for @settingsYourRequests.
  ///
  /// In en, this message translates to:
  /// **'Your Requests'**
  String get settingsYourRequests;

  /// No description provided for @settingsDirectionsApp.
  ///
  /// In en, this message translates to:
  /// **'Directions app'**
  String get settingsDirectionsApp;

  /// No description provided for @settingsAskEachTime.
  ///
  /// In en, this message translates to:
  /// **'Ask each time'**
  String get settingsAskEachTime;

  /// No description provided for @settingsSignInHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in to store favorites, filter by preferences, and more!'**
  String get settingsSignInHint;

  /// No description provided for @settingsZipUpdated.
  ///
  /// In en, this message translates to:
  /// **'ZIP code updated'**
  String get settingsZipUpdated;

  /// No description provided for @settingsUpdateZipTitle.
  ///
  /// In en, this message translates to:
  /// **'Update ZIP Code'**
  String get settingsUpdateZipTitle;

  /// No description provided for @settingsZipValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a 5-digit ZIP code'**
  String get settingsZipValidation;

  /// No description provided for @settingsZipNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find that ZIP code. Try again.'**
  String get settingsZipNotFoundError;

  /// No description provided for @ratingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t rated any facilities yet.'**
  String get ratingsEmptyTitle;

  /// No description provided for @ratingsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Rate a facility from the map or from Recently Viewed on the Home page. Your ratings show up here.'**
  String get ratingsEmptyHint;

  /// No description provided for @ratingsVisitedOn.
  ///
  /// In en, this message translates to:
  /// **'Visited {date}'**
  String ratingsVisitedOn(String date);

  /// No description provided for @requestsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get requestsEmptyTitle;

  /// No description provided for @requestsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Know a facility we\'re missing? Submit a request and we\'ll review it.'**
  String get requestsEmptyHint;

  /// No description provided for @directionsOpenWith.
  ///
  /// In en, this message translates to:
  /// **'Open directions with'**
  String get directionsOpenWith;

  /// No description provided for @directionsChangeLater.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in Settings.'**
  String get directionsChangeLater;

  /// No description provided for @directionsOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open directions.'**
  String get directionsOpenFailed;

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
  /// **'Eligibility'**
  String get settingsEligibility;

  /// No description provided for @settingsZipCode.
  ///
  /// In en, this message translates to:
  /// **'ZIP Code'**
  String get settingsZipCode;

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

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

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

  /// No description provided for @authSignInPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use this feature'**
  String get authSignInPromptTitle;

  /// No description provided for @authSignInPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Create a free account to unlock Favorites, Eligibility filters, and more.'**
  String get authSignInPromptBody;

  /// No description provided for @authSignInError.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get authSignInError;

  /// No description provided for @locationChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'How would you like to find resources?'**
  String get locationChoiceTitle;

  /// No description provided for @locationChoiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll use this to show resources near you.'**
  String get locationChoiceSubtitle;

  /// No description provided for @locationChoiceUseLocation.
  ///
  /// In en, this message translates to:
  /// **'Location-Based Search'**
  String get locationChoiceUseLocation;

  /// No description provided for @locationChoiceUseLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Use GPS for the most accurate results.'**
  String get locationChoiceUseLocationDesc;

  /// No description provided for @locationChoiceEnterZip.
  ///
  /// In en, this message translates to:
  /// **'Enter Zip Code'**
  String get locationChoiceEnterZip;

  /// No description provided for @locationChoiceEnterZipDesc.
  ///
  /// In en, this message translates to:
  /// **'Search by ZIP code in the US.'**
  String get locationChoiceEnterZipDesc;

  /// No description provided for @locationCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get locationCurrentLocation;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access denied. Enable it in Settings > Privacy > Location Services.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Access Required'**
  String get locationPermissionDeniedTitle;

  /// No description provided for @locationPermissionDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'To use GPS-based search, enable location for Beacon in iOS Settings > Privacy > Location Services.'**
  String get locationPermissionDeniedBody;

  /// No description provided for @locationUseMyLocationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get locationUseMyLocationTooltip;

  /// No description provided for @settingsUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use My Location'**
  String get settingsUseMyLocation;

  /// No description provided for @settingsUseMyLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Use GPS instead of ZIP code'**
  String get settingsUseMyLocationDesc;

  /// No description provided for @settingsSignOutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get settingsSignOutSuccess;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @profileApplyEligibility.
  ///
  /// In en, this message translates to:
  /// **'Apply eligibility criteria to search'**
  String get profileApplyEligibility;

  /// No description provided for @profileApplyEligibilityDesc.
  ///
  /// In en, this message translates to:
  /// **'Only show facilities that match your eligibility.'**
  String get profileApplyEligibilityDesc;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @homeCategoryHealthCare.
  ///
  /// In en, this message translates to:
  /// **'Health Care'**
  String get homeCategoryHealthCare;

  /// No description provided for @homeCategoryMentalHealth.
  ///
  /// In en, this message translates to:
  /// **'Mental Health'**
  String get homeCategoryMentalHealth;

  /// No description provided for @homeCategoryHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing & Shelter'**
  String get homeCategoryHousing;

  /// No description provided for @homeCategoryBasicNeeds.
  ///
  /// In en, this message translates to:
  /// **'Basic Needs'**
  String get homeCategoryBasicNeeds;

  /// No description provided for @homeCategoryCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community Resources'**
  String get homeCategoryCommunity;

  /// No description provided for @homeCategorySpecialized.
  ///
  /// In en, this message translates to:
  /// **'Specialized Services'**
  String get homeCategorySpecialized;

  /// No description provided for @commonLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open that link.'**
  String get commonLinkFailed;

  /// No description provided for @onboardingEligibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Your eligibility'**
  String get onboardingEligibilityTitle;

  /// No description provided for @onboardingEligibilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what applies to you so we can show facilities you qualify for. You can change this anytime on your Profile.'**
  String get onboardingEligibilitySubtitle;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @requestFieldWebsite.
  ///
  /// In en, this message translates to:
  /// **'Facility website *'**
  String get requestFieldWebsite;

  /// No description provided for @requestFieldWebsiteError.
  ///
  /// In en, this message translates to:
  /// **'Please enter the facility website'**
  String get requestFieldWebsiteError;

  /// No description provided for @correctionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit corrections'**
  String get correctionDialogTitle;

  /// No description provided for @correctionDialogIntro.
  ///
  /// In en, this message translates to:
  /// **'Update anything that\'s wrong and our team will review it.'**
  String get correctionDialogIntro;

  /// No description provided for @correctionFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get correctionFieldName;

  /// No description provided for @correctionFieldWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get correctionFieldWebsite;

  /// No description provided for @correctionFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get correctionFieldPhone;

  /// No description provided for @correctionFieldHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get correctionFieldHours;

  /// No description provided for @correctionFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get correctionFieldAddress;

  /// No description provided for @correctionSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Correction submitted — we\'ll review it. Thanks!'**
  String get correctionSubmitted;

  /// No description provided for @correctionSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t submit correction. Please try again.'**
  String get correctionSubmitFailed;

  /// No description provided for @requestTypeNew.
  ///
  /// In en, this message translates to:
  /// **'New facility'**
  String get requestTypeNew;

  /// No description provided for @requestTypeCorrection.
  ///
  /// In en, this message translates to:
  /// **'Correction'**
  String get requestTypeCorrection;

  /// No description provided for @cardRatePromptLead.
  ///
  /// In en, this message translates to:
  /// **'Already visited? '**
  String get cardRatePromptLead;

  /// No description provided for @cardRatePromptAction.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience'**
  String get cardRatePromptAction;

  /// No description provided for @cardCorrectionPromptLead.
  ///
  /// In en, this message translates to:
  /// **'Incorrect info? '**
  String get cardCorrectionPromptLead;

  /// No description provided for @cardCorrectionPromptAction.
  ///
  /// In en, this message translates to:
  /// **'Submit corrections here'**
  String get cardCorrectionPromptAction;
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
