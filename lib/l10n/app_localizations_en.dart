// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Beacon';

  @override
  String get navHome => 'Home';

  @override
  String get navMap => 'Map';

  @override
  String get navProfile => 'Profile';

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
  String get homeNearby => 'Nearby Resources';

  @override
  String get homeQuickFind => 'Quick Find';

  @override
  String get homeUrgentCare => 'Urgent Care';

  @override
  String get homeHousing => 'Housing Shelters';

  @override
  String get homeFreeClinics => 'Free Clinics';

  @override
  String get homeFoodPantry => 'Food Pantry';

  @override
  String get mapResourcesNearYou => 'Resources near you';

  @override
  String get mapSwipeUp => 'Swipe up to view resources';

  @override
  String get mapSearchFacilities => 'Search facilities...';

  @override
  String get mapSearchLocation => 'Enter ZIP code';

  @override
  String get mapLoading => 'Loading facilities...';

  @override
  String get mapNoResults => 'No facilities found in this area';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccount => 'Account';

  @override
  String settingsSignedInWith(String provider) {
    return 'Signed in with $provider';
  }

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
  String get settingsWheelchair => 'Wheelchair accessible';

  @override
  String get settingsProofOfIncome => 'Proof of income available';

  @override
  String get settingsInsurance => 'Insurance status';

  @override
  String get settingsWalkIns => 'Accepts walk-ins';

  @override
  String get settingsTelehealth => 'Telehealth preference';

  @override
  String get settingsHouseholdSize => 'Household size';

  @override
  String get settingsAnnualIncome => 'Annual income';

  @override
  String get settingsEmployment => 'Employment status';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsTermsOfService => 'Terms of Service';

  @override
  String get settingsDeveloper => 'Developer';

  @override
  String get settingsDemoMode => 'Demo Mode';

  @override
  String get settingsDemoModeDesc => 'Use mock data and skip authentication';

  @override
  String get settingsDemoModeConfirm =>
      'Switching demo mode will restart the app flow. Continue?';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get settingsSignOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileName => 'Full Name';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileZipCode => 'ZIP Code';

  @override
  String get profileDateOfBirth => 'Date of Birth';

  @override
  String get profileMonth => 'Month';

  @override
  String get profileYear => 'Year';

  @override
  String get profileLanguage => 'Preferred Language';

  @override
  String get profileOptionalInfo => 'Optional Information';

  @override
  String get profileGender => 'Gender';

  @override
  String get profileHouseholdSize => 'Household Size';

  @override
  String get profileAnnualIncome => 'Annual Income';

  @override
  String get profileSaveChanges => 'Save Changes';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileChangePassword => 'Change Password';

  @override
  String get profilePrivacyPolicy => 'Privacy Policy';

  @override
  String get profileCreateAccount => 'Create an Account';

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
  String get authSigningIn => 'Signing in...';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonSave => 'Save';

  @override
  String commonYesPerYear(String amount) {
    return '$amount/year';
  }

  @override
  String get filterCategories => 'Categories';

  @override
  String get filterDistance => 'Distance';

  @override
  String get filterOpenNow => 'Open Now';

  @override
  String get filterFavorites => 'Favorites';

  @override
  String get filterAll => 'All';

  @override
  String get filterApply => 'Apply Filters';

  @override
  String get filterReset => 'Reset';
}
