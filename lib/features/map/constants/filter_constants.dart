enum EligibilityRequirement {
  proofOfIncome,
  proofOfResidency,
  insuranceRequired,
  referralRequired,
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
      case EligibilityRequirement.acceptsWalkins:
        return 'Accepts walk-ins';
      case EligibilityRequirement.appointmentOnly:
        return 'Appointment only';
      case EligibilityRequirement.openToImmigrants:
        return 'Open to immigrants';
      case EligibilityRequirement.freeServicesAvailable:
        return 'Free services available';
      case EligibilityRequirement.slidingScaleAvailable:
        return 'Sliding scale available';
      case EligibilityRequirement.otherLanguages:
        return 'Other languages available';
      case EligibilityRequirement.telehealthAvailable:
        return 'Telehealth available';
      case EligibilityRequirement.wheelchairAccessible:
        return 'Wheelchair accessible';
      case EligibilityRequirement.servesOutsideArea:
        return 'Serves outside area';
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
      case EligibilityRequirement.acceptsWalkins:
        return 'accepts_walkins';
      case EligibilityRequirement.appointmentOnly:
        return 'appointment_only';
      case EligibilityRequirement.openToImmigrants:
        return 'open_to_immigrants';
      case EligibilityRequirement.freeServicesAvailable:
        return 'free_services_available';
      case EligibilityRequirement.slidingScaleAvailable:
        return 'sliding_scale_available';
      case EligibilityRequirement.otherLanguages:
        return 'other_languages';
      case EligibilityRequirement.telehealthAvailable:
        return 'telehealth_available';
      case EligibilityRequirement.wheelchairAccessible:
        return 'wheelchair_accessible';
      case EligibilityRequirement.servesOutsideArea:
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
    EligibilityRequirement.acceptsWalkins,
    EligibilityRequirement.appointmentOnly,
    EligibilityRequirement.openToImmigrants,
    EligibilityRequirement.freeServicesAvailable,
    EligibilityRequirement.slidingScaleAvailable,
    EligibilityRequirement.otherLanguages,
    EligibilityRequirement.telehealthAvailable,
    EligibilityRequirement.wheelchairAccessible,
    EligibilityRequirement.servesOutsideArea,
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
