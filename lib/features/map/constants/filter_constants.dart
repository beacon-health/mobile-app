/// Hard requirements that restrict which users can access a facility.
enum EligibilityRequirement {
  proofOfIncome,
  proofOfResidency,
  insuranceRequired,
  referralRequired,
}

extension EligibilityRequirementExtension on EligibilityRequirement {
  String get displayName {
    switch (this) {
      case EligibilityRequirement.proofOfIncome:
        return 'Proof of income required';
      case EligibilityRequirement.proofOfResidency:
        return 'Proof of residency required';
      case EligibilityRequirement.insuranceRequired:
        return 'Insurance required';
      case EligibilityRequirement.referralRequired:
        return 'Referral required';
    }
  }

  /// Maps to the snake_case keys used in [FacilityEligibility.toFilterMap]
  /// and the Supabase column names.
  String get fieldKey {
    switch (this) {
      case EligibilityRequirement.proofOfIncome:
        return 'proof_of_income';
      case EligibilityRequirement.proofOfResidency:
        return 'proof_of_residency';
      case EligibilityRequirement.insuranceRequired:
        return 'insurance_required';
      case EligibilityRequirement.referralRequired:
        return 'referral_required';
    }
  }
}

/// User-friendly service attributes that are nice-to-have rather than gating.
enum PreferenceRequirement {
  acceptsWalkins,
  appointmentOnly,
  openToImmigrants,
  freeServicesAvailable,
  slidingScaleAvailable,
  otherLanguages,
  telehealthAvailable,
  wheelchairAccessible,
  servesOutsideArea,
}

extension PreferenceRequirementExtension on PreferenceRequirement {
  String get displayName {
    switch (this) {
      case PreferenceRequirement.acceptsWalkins:
        return 'Accepts walk-ins';
      case PreferenceRequirement.appointmentOnly:
        return 'Appointment only';
      case PreferenceRequirement.openToImmigrants:
        return 'Open to immigrants';
      case PreferenceRequirement.freeServicesAvailable:
        return 'Free services available';
      case PreferenceRequirement.slidingScaleAvailable:
        return 'Sliding scale available';
      case PreferenceRequirement.otherLanguages:
        return 'Other languages available';
      case PreferenceRequirement.telehealthAvailable:
        return 'Telehealth available';
      case PreferenceRequirement.wheelchairAccessible:
        return 'Wheelchair accessible';
      case PreferenceRequirement.servesOutsideArea:
        return 'Serves outside area';
    }
  }

  /// Maps to the snake_case keys used in [FacilityEligibility.toFilterMap]
  /// and the Supabase column names.
  String get fieldKey {
    switch (this) {
      case PreferenceRequirement.acceptsWalkins:
        return 'accepts_walkins';
      case PreferenceRequirement.appointmentOnly:
        return 'appointment_only';
      case PreferenceRequirement.openToImmigrants:
        return 'open_to_immigrants';
      case PreferenceRequirement.freeServicesAvailable:
        return 'free_services_available';
      case PreferenceRequirement.slidingScaleAvailable:
        return 'sliding_scale_available';
      case PreferenceRequirement.otherLanguages:
        return 'other_languages';
      case PreferenceRequirement.telehealthAvailable:
        return 'telehealth_available';
      case PreferenceRequirement.wheelchairAccessible:
        return 'wheelchair_accessible';
      case PreferenceRequirement.servesOutsideArea:
        return 'serves_outside_area';
    }
  }
}

class FilterConstants {
  static const double modalHeightRatio = 0.60;
  static const Duration animationDuration = Duration(milliseconds: 200);

  static const List<EligibilityRequirement> eligibilityRequirements = [
    EligibilityRequirement.proofOfIncome,
    EligibilityRequirement.proofOfResidency,
    EligibilityRequirement.insuranceRequired,
    EligibilityRequirement.referralRequired,
  ];

  static const List<PreferenceRequirement> preferenceRequirements = [
    PreferenceRequirement.acceptsWalkins,
    PreferenceRequirement.appointmentOnly,
    PreferenceRequirement.openToImmigrants,
    PreferenceRequirement.freeServicesAvailable,
    PreferenceRequirement.slidingScaleAvailable,
    PreferenceRequirement.otherLanguages,
    PreferenceRequirement.telehealthAvailable,
    PreferenceRequirement.wheelchairAccessible,
    PreferenceRequirement.servesOutsideArea,
  ];
}

class FilterDesignTokens {
  static const double filterBarHeight = 40.0;
  static const double chipHeight = 32.0;

  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingXLarge = 20.0;
  static const double spacingXXLarge = 32.0;

  static const double paddingButton = 14.0;

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 20.0;

  static const double borderWidthNormal = 1.0;
  static const double borderWidthSelected = 2.0;

  static const double fontSizeSmall = 13.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeNormal = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 20.0;

  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 18.0;
  static const double iconSizeLarge = 24.0;

  static const double chipPaddingHorizontal = 12.0;
  static const double chipPaddingVertical = 8.0;

  static const double selectionChipPaddingHorizontal = 16.0;
  static const double selectionChipPaddingVertical = 10.0;

  static const double eligibilityOptionPaddingVertical = 12.0;

  static const double shadowBlurRadius = 4.0;
  static const double shadowOffsetY = 2.0;
  static const double shadowOpacity = 0.05;

  static const double modalShadowBlurRadius = 10.0;
  static const double modalShadowOffsetY = -5.0;
}
