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
  String get mapSearchLocation => 'Enter ZIP code';

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
  String get profileChangePassword => 'Change Password';

  @override
  String get profilePrivacyPolicy => 'Privacy Policy';

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
}
