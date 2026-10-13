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
  String get homeGreeting => 'Find healthcare resources';

  @override
  String get homeFavorites => 'Your favorites';

  @override
  String get homeNoFavorites => 'No favorites yet';

  @override
  String get homeNoFavoritesHint =>
      'Add favorites from the map page to see them here';

  @override
  String get homeFavoritesSignInTitle => 'Sign in to save favorites';

  @override
  String get homeFavoritesSignInHint =>
      'Save your favorite facilities by signing in.';

  @override
  String get homeRecentlyViewed => 'Recently viewed';

  @override
  String get homeNoRecentlyViewed => 'No recently viewed facilities';

  @override
  String get homeNoRecentlyViewedHint =>
      'Tap a facility on the map to see it here.';

  @override
  String get mapSearchLocation => 'Enter ZIP code';

  @override
  String get mapSearchResourcesHint => 'Search for resources';

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
  String get mapInvalidZip => 'Enter a 5-digit ZIP code.';

  @override
  String mapZipNotFound(String zipCode) {
    return 'Couldn\'t find ZIP code $zipCode.';
  }

  @override
  String get filterOpenNow => 'Open now';

  @override
  String get filterFavorites => 'Favorites';

  @override
  String get filterCategory => 'Category';

  @override
  String get filterPreferences => 'Preferences';

  @override
  String get filterFilters => 'Filters';

  @override
  String get filterClearAll => 'Clear all';

  @override
  String get filterApply => 'Apply';

  @override
  String get eligProofOfIncome => 'Proof of income';

  @override
  String get eligProofOfResidency => 'Proof of address';

  @override
  String get eligInsuranceRequired => 'Health insurance';

  @override
  String get eligReferralRequired => 'A doctor\'s referral';

  @override
  String get prefAcceptsWalkIns => 'Take walk-ins';

  @override
  String get prefAppointmentOnly => 'Require an appointment';

  @override
  String get prefOpenToImmigrants => 'Are open to immigrants';

  @override
  String get prefFreeServices => 'Offer free services';

  @override
  String get prefSlidingScale => 'Charge on a sliding scale';

  @override
  String get prefOtherLanguages => 'Offer other languages';

  @override
  String get prefTelehealth => 'Offer telehealth';

  @override
  String get prefWheelchairAccessible => 'Are wheelchair accessible';

  @override
  String get prefServesOutsideArea => 'Serve people outside their area';

  @override
  String get cardHours => 'Hours';

  @override
  String get cardServices => 'Services';

  @override
  String get cardServicesAiDisclaimer =>
      'Summary written by AI. It may contain mistakes.';

  @override
  String get cardAtAGlance => 'At a glance';

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
  String get chipSlidingScale => 'Sliding scale';

  @override
  String get chipOtherLanguages => 'Other languages';

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
  String get settingsYourRatings => 'Your ratings';

  @override
  String get settingsYourRequests => 'Your requests';

  @override
  String get settingsDirectionsApp => 'Directions app';

  @override
  String get settingsAskEachTime => 'Ask each time';

  @override
  String get settingsSignInHint =>
      'Sign in to save favorites and use them on any device.';

  @override
  String get settingsZipUpdated => 'ZIP code updated';

  @override
  String get settingsUpdateZipTitle => 'Update ZIP code';

  @override
  String get settingsZipValidation => 'Enter a 5-digit ZIP code.';

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
  String get settingsEligibility => 'What you can provide';

  @override
  String get settingsZipCode => 'ZIP code';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsTermsOfService => 'Terms of service';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutConfirm =>
      'Your favorites and settings stay with your account. They\'re removed from this phone.';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your account, saved favorites, eligibility answers, and settings. Ratings and corrections you submitted stay in the directory but are no longer linked to you. This cannot be undone.';

  @override
  String get deleteAccountConfirm => 'Delete account';

  @override
  String get deleteAccountInProgress => 'Deleting your account…';

  @override
  String get deleteAccountSuccess => 'Your account has been deleted';

  @override
  String get deleteAccountFailed =>
      'Couldn\'t delete your account. Please try again.';

  @override
  String coverageNotice(String states) {
    return 'Beacon currently shows facilities in $states. We\'re adding more states over time.';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String get authContinueAsGuest => 'Continue as guest';

  @override
  String get authOr => 'or';

  @override
  String get authTermsPrefix => 'By continuing, you agree to our ';

  @override
  String get authTermsOfService => 'Terms of Service';

  @override
  String get authAnd => ' and ';

  @override
  String get authPrivacyPolicy => 'Privacy Policy';

  @override
  String get authSelectLanguage => 'Select a language';

  @override
  String get authSignInPromptTitle => 'Sign in to use this feature';

  @override
  String get authSignInPromptBody =>
      'Sign in to save favorites, filter by preferences, and rate places.';

  @override
  String get authSignInError => 'Sign-in failed. Please try again.';

  @override
  String get locationChoiceTitle => 'How would you like to find resources?';

  @override
  String get locationChoiceSubtitle =>
      'We\'ll use this to show resources near you.';

  @override
  String get locationChoiceUseLocation => 'Use my location';

  @override
  String get locationChoiceUseLocationDesc =>
      'Most accurate. We\'ll ask for permission next.';

  @override
  String get locationChoiceEnterZip => 'Enter a ZIP code';

  @override
  String get locationChoiceEnterZipDesc =>
      'Search one area without sharing your location.';

  @override
  String get locationCurrentLocation => 'Current location';

  @override
  String get locationPermissionDenied =>
      'Location access is off. Turn it on for Beacon in your phone\'s settings.';

  @override
  String get locationPermissionDeniedTitle => 'Location access needed';

  @override
  String get locationPermissionDeniedBody =>
      'To search by your location, turn on location access for Beacon in your phone\'s settings.';

  @override
  String get locationUseMyLocationTooltip => 'Use my location';

  @override
  String get settingsUseMyLocation => 'Use my location';

  @override
  String get settingsUseMyLocationDesc => 'Instead of a ZIP code';

  @override
  String get settingsSignOutSuccess => 'Signed out';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get navProfile => 'Profile';

  @override
  String get profileApplyEligibility => 'Filter by what I can provide';

  @override
  String get profileApplyEligibilityDesc =>
      'Hides places that ask for something you haven\'t checked below.';

  @override
  String get profileSignedIn => 'Signed in';

  @override
  String profileSignedInThrough(String provider) {
    return 'Signed in through $provider';
  }

  @override
  String get commonSave => 'Save';

  @override
  String get homeCategoryHealthCare => 'Health care';

  @override
  String get homeCategoryMentalHealth => 'Mental health';

  @override
  String get homeCategoryHousing => 'Housing & shelter';

  @override
  String get homeCategoryBasicNeeds => 'Basic needs';

  @override
  String get homeCategoryCommunity => 'Community resources';

  @override
  String get homeCategorySpecialized => 'Specialized services';

  @override
  String get commonLinkFailed => 'Could not open that link.';

  @override
  String get onboardingEligibilityTitle => 'What can you provide?';

  @override
  String get onboardingEligibilitySubtitle =>
      'We\'ll hide places you couldn\'t use. You can change this anytime in Profile.';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingTagline => 'Find free and low-cost resources near you.';

  @override
  String get zipEntryTitle => 'What\'s your ZIP code?';

  @override
  String get zipEntrySubtitle => 'We\'ll use this to show resources near you.';

  @override
  String get zipEntryInvalid => 'Enter a 5-digit ZIP code.';

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

  @override
  String zipOutsideCoverage(String states) {
    return 'Beacon isn\'t available in that area yet. It currently covers $states.';
  }

  @override
  String stateName(String code) {
    String _temp0 = intl.Intl.selectLogic(
      code,
      {
        'AL': 'Alabama',
        'AK': 'Alaska',
        'AZ': 'Arizona',
        'AR': 'Arkansas',
        'CA': 'California',
        'CO': 'Colorado',
        'CT': 'Connecticut',
        'DE': 'Delaware',
        'DC': 'Washington, D.C.',
        'FL': 'Florida',
        'GA': 'Georgia',
        'GU': 'Guam',
        'HI': 'Hawaii',
        'ID': 'Idaho',
        'IL': 'Illinois',
        'IN': 'Indiana',
        'IA': 'Iowa',
        'KS': 'Kansas',
        'KY': 'Kentucky',
        'LA': 'Louisiana',
        'ME': 'Maine',
        'MD': 'Maryland',
        'MA': 'Massachusetts',
        'MI': 'Michigan',
        'MN': 'Minnesota',
        'MS': 'Mississippi',
        'MO': 'Missouri',
        'MT': 'Montana',
        'NE': 'Nebraska',
        'NV': 'Nevada',
        'NH': 'New Hampshire',
        'NJ': 'New Jersey',
        'NM': 'New Mexico',
        'NY': 'New York',
        'NC': 'North Carolina',
        'ND': 'North Dakota',
        'OH': 'Ohio',
        'OK': 'Oklahoma',
        'OR': 'Oregon',
        'PA': 'Pennsylvania',
        'PR': 'Puerto Rico',
        'RI': 'Rhode Island',
        'SC': 'South Carolina',
        'SD': 'South Dakota',
        'TN': 'Tennessee',
        'TX': 'Texas',
        'UT': 'Utah',
        'VT': 'Vermont',
        'VA': 'Virginia',
        'VI': 'U.S. Virgin Islands',
        'WA': 'Washington',
        'WV': 'West Virginia',
        'WI': 'Wisconsin',
        'WY': 'Wyoming',
        'other': '$code',
      },
    );
    return '$_temp0';
  }

  @override
  String listTwo(String first, String second) {
    return '$first and $second';
  }

  @override
  String listTwoBeforeI(String first, String second) {
    return '$first and $second';
  }

  @override
  String listMany(String rest, String last) {
    return '$rest, and $last';
  }

  @override
  String listManyBeforeI(String rest, String last) {
    return '$rest, and $last';
  }

  @override
  String get listSeparator => ', ';

  @override
  String mapResourcesInView(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resources in this area',
      one: '1 resource in this area',
    );
    return '$_temp0';
  }

  @override
  String get mapNothingInView => 'Nothing in this part of the map';

  @override
  String get mapNothingInViewHint => 'Zoom out or move the map to see more.';

  @override
  String get eligAcceptsMedicaid => 'Medicaid';

  @override
  String get chipMedicaid => 'Medicaid';

  @override
  String get cardIncomeLimit => 'Income limit';

  @override
  String get cardServiceArea => 'Service area';

  @override
  String get labelSeparator => ': ';

  @override
  String get correctionFieldClosed => 'Permanently closed';

  @override
  String get correctionFieldClosedHint =>
      'Turn this on if the location has shut down for good.';

  @override
  String get requestTypeClosure => 'Reported closed';

  @override
  String get homeOpenMap => 'Open map';

  @override
  String filterShowResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count results',
      one: 'Show 1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String get filterOnlyShowPlacesThat => 'Only show places that';

  @override
  String get filterClose => 'Close filters';

  @override
  String filterCategoriesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories',
      one: '1 category',
    );
    return '$_temp0';
  }

  @override
  String get cardDirections => 'Directions';

  @override
  String get cardCall => 'Call';

  @override
  String cardCallNumber(String phone) {
    return 'Call $phone';
  }

  @override
  String get cardWebsite => 'Website';

  @override
  String cardSave(String name) {
    return 'Save $name';
  }

  @override
  String cardUnsave(String name) {
    return 'Remove $name from favorites';
  }

  @override
  String get cardShowDetails => 'Show details';

  @override
  String get cardHideDetails => 'Hide details';

  @override
  String get eligProofOfIncomeHint =>
      'Pay stub, tax return, or benefits letter';

  @override
  String get eligProofOfResidencyHint => 'ID, lease, or utility bill';

  @override
  String get onboardingSkip => 'Skip for now';

  @override
  String onboardingStep(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get authTermsSuffix => '.';

  @override
  String authLanguageButton(String language) {
    return 'Language: $language. Change language';
  }

  @override
  String get zipEntryHelper => '5 digits';

  @override
  String get zipEntryLocationOff =>
      'Location access is off, so enter a ZIP code instead.';

  @override
  String get settingsSignOutTitle => 'Sign out?';

  @override
  String settingsVersionFooter(String version) {
    return 'Beacon $version';
  }

  @override
  String get settingsAccessibility => 'Accessibility';

  @override
  String get settingsMapAsList => 'Open Map as a list';

  @override
  String get settingsMapAsListDesc => 'Easier with screen readers';

  @override
  String get settingsLargerPins => 'Larger map pins';

  @override
  String get settingsLargerPinsDesc => 'Bigger pins and names on the map';

  @override
  String get settingsAppearanceSystem => 'Match device';

  @override
  String get settingsAppearanceLight => 'Light';

  @override
  String get settingsAppearanceDark => 'Dark';

  @override
  String get commonNotSet => 'Not set';

  @override
  String get brandTagline => 'Healthcare made lighter.';
}
