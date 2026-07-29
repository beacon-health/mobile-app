// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navMap => 'Map';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeGreeting => 'Find Healthcare Resources';

  @override
  String get homeFavorites => 'Your Favorites';

  @override
  String get homeNoFavorites => 'No favorites yet';

  @override
  String get homeNoFavoritesHint =>
      'Add favorites from the map page to see them here';

  @override
  String get homeRecentlyViewed => 'Recently Viewed Facilities';

  @override
  String get homeNoRecentlyViewed => 'No recently viewed facilities';

  @override
  String get homeNoRecentlyViewedHint =>
      'Tap a facility on the map to see it here.';

  @override
  String get mapSearchLocation => 'Enter ZIP code';

  @override
  String get mapSearchResourcesHint => 'Search for resources...';

  @override
  String get mapAreaLabel => 'Map area';

  @override
  String get mapSearchThisArea => 'Search this area';

  @override
  String get mapSearching => 'Searching…';

  @override
  String get mapSwipeUpToView => 'Swipe up to view resources';

  @override
  String get mapResourcesNearYou => 'Resources near you';

  @override
  String get mapNoFacilitiesInArea => 'No facilities in this area';

  @override
  String get mapCantFindFacility =>
      'Can\'t find a facility? Submit a request to add one.';

  @override
  String get mapRequestFacility => 'Request a facility';

  @override
  String get mapLoadFailed => 'Failed to load facilities. Please try again.';

  @override
  String get mapRetry => 'Retry';

  @override
  String get mapInvalidZip =>
      'Please enter a valid 5-digit zip code (e.g., 60605)';

  @override
  String mapZipNotFound(String zipCode) {
    return 'Could not find location for zip code $zipCode.';
  }

  @override
  String get filterOpenNow => 'Open Now';

  @override
  String get filterFavorites => 'Favorites';

  @override
  String get filterCategory => 'Category';

  @override
  String get filterPreferences => 'Preferences';

  @override
  String get filterFilters => 'Filters';

  @override
  String get filterClearAll => 'Clear All';

  @override
  String get filterApply => 'Apply';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get eligProofOfIncome => 'Proof of income required';

  @override
  String get eligProofOfResidency => 'Proof of residency required';

  @override
  String get eligInsuranceRequired => 'Insurance required';

  @override
  String get eligReferralRequired => 'Referral required';

  @override
  String get prefAcceptsWalkIns => 'Accepts walk-ins';

  @override
  String get prefAppointmentOnly => 'Appointment only';

  @override
  String get prefOpenToImmigrants => 'Open to immigrants';

  @override
  String get prefFreeServices => 'Free services available';

  @override
  String get prefSlidingScale => 'Sliding scale available';

  @override
  String get prefOtherLanguages => 'Other languages available';

  @override
  String get prefTelehealth => 'Telehealth available';

  @override
  String get prefWheelchairAccessible => 'Wheelchair accessible';

  @override
  String get prefServesOutsideArea => 'Serves outside area';

  @override
  String get cardNextSteps => 'Next Steps';

  @override
  String get cardHours => 'Hours';

  @override
  String get cardServices => 'Services';

  @override
  String get cardAtAGlance => 'At a Glance';

  @override
  String get cardVisitWebsite => 'Visit website';

  @override
  String get cardWebsiteNotAvailable => 'Website not available';

  @override
  String get cardGetDirections => 'Get directions';

  @override
  String get cardContactForHours => 'Contact facility for hours';

  @override
  String get cardOpen247 => 'Open 24/7';

  @override
  String get cardAddressNotAvailable =>
      'Address information not available for this facility';

  @override
  String get chipWalkIns => 'Walk-ins';

  @override
  String get chipFree => 'Free';

  @override
  String get chipTelehealth => 'Telehealth';

  @override
  String get chipAccessible => 'Accessible';

  @override
  String get chipSlidingScale => 'Sliding Scale';

  @override
  String get chipOtherLanguages => 'Other Languages';

  @override
  String get ratingAlreadyRated => 'You already rated this — update it below.';

  @override
  String get ratingDateVisited => 'Date visited';

  @override
  String get ratingRemove => 'Remove';

  @override
  String get ratingSubmit => 'Submit';

  @override
  String get ratingUpdate => 'Update';

  @override
  String get ratingThanks => 'Thanks for your rating!';

  @override
  String get ratingUpdated => 'Rating updated.';

  @override
  String get ratingRemoved => 'Rating removed.';

  @override
  String get ratingSendFailed => 'Couldn\'t send rating. Please try again.';

  @override
  String get ratingRemoveFailed => 'Couldn\'t remove rating. Please try again.';

  @override
  String get ratingSignInRequired => 'Sign in required to rate a facility.';

  @override
  String get requestDialogTitle => 'Request a facility';

  @override
  String get requestDialogIntro =>
      'Tell us about a facility we\'re missing and our team will review it.';

  @override
  String get requestFieldName => 'Facility name *';

  @override
  String get requestFieldNameError => 'Please enter the facility name';

  @override
  String get requestSubmitted =>
      'Request submitted — we\'ll review it soon. Thanks!';

  @override
  String get requestSubmitFailed =>
      'Couldn\'t submit request. Please try again.';

  @override
  String get requestSignInRequired => 'Sign in required to submit a request.';

  @override
  String get settingsYourRatings => 'Your Ratings';

  @override
  String get settingsYourRequests => 'Your Requests';

  @override
  String get settingsDirectionsApp => 'Directions app';

  @override
  String get settingsAskEachTime => 'Ask each time';

  @override
  String get settingsSignInHint =>
      'Sign in to store favorites, filter by preferences, and more!';

  @override
  String get settingsZipUpdated => 'ZIP code updated';

  @override
  String get settingsUpdateZipTitle => 'Update ZIP Code';

  @override
  String get settingsZipValidation => 'Please enter a 5-digit ZIP code';

  @override
  String get settingsZipNotFoundError =>
      'Couldn\'t find that ZIP code. Try again.';

  @override
  String get ratingsEmptyTitle => 'You haven\'t rated any facilities yet.';

  @override
  String get ratingsEmptyHint =>
      'Rate a facility from the map or from Recently Viewed on the Home page. Your ratings show up here.';

  @override
  String ratingsVisitedOn(String date) {
    return 'Visited $date';
  }

  @override
  String get requestsEmptyTitle => 'No requests yet';

  @override
  String get requestsEmptyHint =>
      'Know a facility we\'re missing? Submit a request and we\'ll review it.';

  @override
  String get directionsOpenWith => 'Open directions with';

  @override
  String get directionsChangeLater => 'You can change this later in Settings.';

  @override
  String get directionsOpenFailed => 'Couldn\'t open directions.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsApp => 'App';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsEligibility => 'Eligibility';

  @override
  String get settingsZipCode => 'ZIP Code';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsTermsOfService => 'Terms of Service';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get settingsSignOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get profileTitle => 'Profile';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authContinueAsGuest => 'Continue as Guest';

  @override
  String get authOr => 'or';

  @override
  String get authTermsPrefix => 'By clicking continue, you agree to our ';

  @override
  String get authTermsOfService => 'Terms of Service';

  @override
  String get authAnd => ' and ';

  @override
  String get authPrivacyPolicy => 'Privacy Policy';

  @override
  String get authSelectLanguage => 'Select a language 🌐';

  @override
  String get authSignInPromptTitle => 'Sign in to use this feature';

  @override
  String get authSignInPromptBody =>
      'Create a free account to unlock Favorites, Eligibility filters, and more.';

  @override
  String get authSignInError => 'Sign-in failed. Please try again.';

  @override
  String get locationChoiceTitle => 'How would you like to find resources?';

  @override
  String get locationChoiceSubtitle =>
      'We\'ll use this to show resources near you.';

  @override
  String get locationChoiceUseLocation => 'Location-Based Search';

  @override
  String get locationChoiceUseLocationDesc =>
      'Use GPS for the most accurate results.';

  @override
  String get locationChoiceEnterZip => 'Enter Zip Code';

  @override
  String get locationChoiceEnterZipDesc => 'Search by ZIP code in the US.';

  @override
  String get locationCurrentLocation => 'Current Location';

  @override
  String get locationPermissionDenied =>
      'Location access denied. Enable it in Settings > Privacy > Location Services.';

  @override
  String get locationPermissionDeniedTitle => 'Location Access Required';

  @override
  String get locationPermissionDeniedBody =>
      'To use GPS-based search, enable location for Beacon in iOS Settings > Privacy > Location Services.';

  @override
  String get locationUseMyLocationTooltip => 'Use my location';

  @override
  String get settingsUseMyLocation => 'Use My Location';

  @override
  String get settingsUseMyLocationDesc => 'Use GPS instead of ZIP code';

  @override
  String get settingsSignOutSuccess => 'Signed out';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get navProfile => 'Profile';

  @override
  String get profileApplyEligibility => 'Apply eligibility criteria to search';

  @override
  String get profileApplyEligibilityDesc =>
      'Only show facilities that match your eligibility.';

  @override
  String get commonSave => 'Save';

  @override
  String get commonLinkFailed => 'Could not open that link.';

  @override
  String get onboardingEligibilityTitle => 'Your eligibility';

  @override
  String get onboardingEligibilitySubtitle =>
      'Tell us what applies to you so we can show facilities you qualify for. You can change this anytime on your Profile.';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get requestFieldWebsite => 'Facility website *';

  @override
  String get requestFieldWebsiteError => 'Please enter the facility website';

  @override
  String get correctionDialogTitle => 'Submit corrections';

  @override
  String get correctionDialogIntro =>
      'Update anything that\'s wrong and our team will review it.';

  @override
  String get correctionFieldName => 'Name';

  @override
  String get correctionFieldWebsite => 'Website';

  @override
  String get correctionFieldPhone => 'Phone';

  @override
  String get correctionFieldHours => 'Hours';

  @override
  String get correctionFieldAddress => 'Address';

  @override
  String get correctionSubmitted =>
      'Correction submitted — we\'ll review it. Thanks!';

  @override
  String get correctionSubmitFailed =>
      'Couldn\'t submit correction. Please try again.';

  @override
  String get requestTypeNew => 'New facility';

  @override
  String get requestTypeCorrection => 'Correction';

  @override
  String get cardRatePromptLead => 'Already visited? ';

  @override
  String get cardRatePromptAction => 'Rate your experience';

  @override
  String get cardCorrectionPromptLead => 'Incorrect info? ';

  @override
  String get cardCorrectionPromptAction => 'Submit corrections here';
}
