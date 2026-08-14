import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/recent_facilities_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';

/// Clears every per-user value cached on the device. Shared by sign-out and
/// account deletion so the two paths can't drift apart.
///
/// Clearing the ZIP state also resets `hasCompletedOnboarding`, which is what
/// sends the user back through the location step.
Future<void> clearLocalUserData({required String logContext}) async {
  try {
    await ZipCodeService().clear();
    await EligibilityPreferencesService().clear();
    RecentFacilitiesService().clear();
  } catch (e, stackTrace) {
    ErrorReporter.instance.report(e, stackTrace, context: logContext);
  }
}
