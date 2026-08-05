import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:beacon_app/l10n/app_localizations.dart';

/// Localized display names for the filter enums. Kept out of
/// `filter_constants.dart` so that file stays free of l10n imports for tests.
extension EligibilityRequirementL10n on EligibilityRequirement {
  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case EligibilityRequirement.proofOfIncome:
        return l10n.eligProofOfIncome;
      case EligibilityRequirement.proofOfResidency:
        return l10n.eligProofOfResidency;
      case EligibilityRequirement.insuranceRequired:
        return l10n.eligInsuranceRequired;
      case EligibilityRequirement.referralRequired:
        return l10n.eligReferralRequired;
    }
  }
}

extension PreferenceRequirementL10n on PreferenceRequirement {
  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case PreferenceRequirement.acceptsWalkins:
        return l10n.prefAcceptsWalkIns;
      case PreferenceRequirement.appointmentOnly:
        return l10n.prefAppointmentOnly;
      case PreferenceRequirement.openToImmigrants:
        return l10n.prefOpenToImmigrants;
      case PreferenceRequirement.freeServicesAvailable:
        return l10n.prefFreeServices;
      case PreferenceRequirement.slidingScaleAvailable:
        return l10n.prefSlidingScale;
      case PreferenceRequirement.otherLanguages:
        return l10n.prefOtherLanguages;
      case PreferenceRequirement.telehealthAvailable:
        return l10n.prefTelehealth;
      case PreferenceRequirement.wheelchairAccessible:
        return l10n.prefWheelchairAccessible;
      case PreferenceRequirement.servesOutsideArea:
        return l10n.prefServesOutsideArea;
    }
  }
}
