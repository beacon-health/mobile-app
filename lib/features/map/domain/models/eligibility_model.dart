/// Represents a tri-state eligibility value from the database.
///
/// Most eligibility fields use Y (yes), N (no), or U (unknown).
enum EligibilityValue {
  yes,
  no,
  unknown;

  /// Parses a Y/N/U string into an [EligibilityValue].
  static EligibilityValue fromString(String? value) {
    if (value == null) return EligibilityValue.unknown;
    switch (value.toUpperCase()) {
      case 'Y':
        return EligibilityValue.yes;
      case 'N':
        return EligibilityValue.no;
      default:
        return EligibilityValue.unknown;
    }
  }

  /// Converts to a nullable bool for filtering.
  ///
  /// Y → true, N → false, U → null (passes through all filters).
  bool? toBool() {
    switch (this) {
      case EligibilityValue.yes:
        return true;
      case EligibilityValue.no:
        return false;
      case EligibilityValue.unknown:
        return null;
    }
  }
}

/// Structured eligibility data for a facility.
///
/// Sourced from the `DM_Supabase_Eligibility` table, joined via
/// the `facilities_il_full` view.
class FacilityEligibility {
  final EligibilityValue operational;
  final EligibilityValue proofOfIncome;
  final EligibilityValue proofOfResidency;
  final EligibilityValue insuranceRequired;
  final EligibilityValue referralRequired;
  final EligibilityValue acceptsWalkins;
  final EligibilityValue appointmentOnly;
  final EligibilityValue openToImmigrants;
  final EligibilityValue freeServicesAvailable;
  final EligibilityValue slidingScaleAvailable;
  final EligibilityValue otherLanguages;
  final EligibilityValue telehealthAvailable;
  final EligibilityValue wheelchairAccessible;
  final EligibilityValue servesOutsideArea;
  final EligibilityValue directServices;
  final EligibilityValue hoursListed;

  final String? ageRestriction;
  final String? restrictedGroups;
  final String? operatingHours;
  final String? otherEligibilitySummary;
  final String? servicesSummary;
  final String? facilityCategory;
  final String? extractionDate;

  const FacilityEligibility({
    this.operational = EligibilityValue.unknown,
    this.proofOfIncome = EligibilityValue.unknown,
    this.proofOfResidency = EligibilityValue.unknown,
    this.insuranceRequired = EligibilityValue.unknown,
    this.referralRequired = EligibilityValue.unknown,
    this.acceptsWalkins = EligibilityValue.unknown,
    this.appointmentOnly = EligibilityValue.unknown,
    this.openToImmigrants = EligibilityValue.unknown,
    this.freeServicesAvailable = EligibilityValue.unknown,
    this.slidingScaleAvailable = EligibilityValue.unknown,
    this.otherLanguages = EligibilityValue.unknown,
    this.telehealthAvailable = EligibilityValue.unknown,
    this.wheelchairAccessible = EligibilityValue.unknown,
    this.servesOutsideArea = EligibilityValue.unknown,
    this.directServices = EligibilityValue.unknown,
    this.hoursListed = EligibilityValue.unknown,
    this.ageRestriction,
    this.restrictedGroups,
    this.operatingHours,
    this.otherEligibilitySummary,
    this.servicesSummary,
    this.facilityCategory,
    this.extractionDate,
  });

  /// Creates a [FacilityEligibility] from a flat Supabase row.
  ///
  /// Expects column names from the `facilities_il_full` view
  /// (snake_case, matching DM_Supabase_Eligibility columns).
  factory FacilityEligibility.fromSupabase(Map<String, dynamic> data) {
    return FacilityEligibility(
      operational: EligibilityValue.fromString(
        data['operational'] as String?,
      ),
      proofOfIncome: EligibilityValue.fromString(
        data['proof_of_income'] as String?,
      ),
      proofOfResidency: EligibilityValue.fromString(
        data['proof_of_residency'] as String?,
      ),
      insuranceRequired: EligibilityValue.fromString(
        data['insurance_required'] as String?,
      ),
      referralRequired: EligibilityValue.fromString(
        data['referral_required'] as String?,
      ),
      acceptsWalkins: EligibilityValue.fromString(
        data['accepts_walkins'] as String?,
      ),
      appointmentOnly: EligibilityValue.fromString(
        data['appointment_only'] as String?,
      ),
      openToImmigrants: EligibilityValue.fromString(
        data['open_to_immigrants'] as String?,
      ),
      freeServicesAvailable: EligibilityValue.fromString(
        data['free_services_available'] as String?,
      ),
      slidingScaleAvailable: EligibilityValue.fromString(
        data['sliding_scale_available'] as String?,
      ),
      otherLanguages: EligibilityValue.fromString(
        data['other_languages'] as String?,
      ),
      telehealthAvailable: EligibilityValue.fromString(
        data['telehealth_available'] as String?,
      ),
      wheelchairAccessible: EligibilityValue.fromString(
        data['wheelchair_accessible'] as String?,
      ),
      servesOutsideArea: EligibilityValue.fromString(
        data['serves_outside_area'] as String?,
      ),
      directServices: EligibilityValue.fromString(
        data['direct_services'] as String?,
      ),
      hoursListed: EligibilityValue.fromString(
        data['hours_listed'] as String?,
      ),
      ageRestriction: _nullIfN(data['age_restriction'] as String?),
      restrictedGroups: _nullIfN(data['restricted_groups'] as String?),
      operatingHours: _nullIfN(data['operating_hours'] as String?),
      otherEligibilitySummary: _nullIfU(
        data['other_eligibility_summary'] as String?,
      ),
      servicesSummary: data['services_summary'] as String?,
      facilityCategory: data['facility_category'] as String?,
      extractionDate: data['extraction_date'] as String?,
    );
  }

  /// Returns a map of eligibility field keys to nullable bools.
  ///
  /// Used by the filter system. Keys use snake_case matching DB columns.
  /// Unknown values are omitted (null passes through all filters).
  Map<String, bool> toFilterMap() {
    final map = <String, bool>{};
    _addIfKnown(map, 'proof_of_income', proofOfIncome);
    _addIfKnown(map, 'proof_of_residency', proofOfResidency);
    _addIfKnown(map, 'insurance_required', insuranceRequired);
    _addIfKnown(map, 'referral_required', referralRequired);
    _addIfKnown(map, 'accepts_walkins', acceptsWalkins);
    _addIfKnown(map, 'appointment_only', appointmentOnly);
    _addIfKnown(map, 'open_to_immigrants', openToImmigrants);
    _addIfKnown(map, 'free_services_available', freeServicesAvailable);
    _addIfKnown(map, 'sliding_scale_available', slidingScaleAvailable);
    _addIfKnown(map, 'other_languages', otherLanguages);
    _addIfKnown(map, 'telehealth_available', telehealthAvailable);
    _addIfKnown(map, 'wheelchair_accessible', wheelchairAccessible);
    _addIfKnown(map, 'serves_outside_area', servesOutsideArea);
    return map;
  }

  static void _addIfKnown(
    Map<String, bool> map,
    String key,
    EligibilityValue value,
  ) {
    final b = value.toBool();
    if (b != null) map[key] = b;
  }

  static String? _nullIfN(String? value) {
    if (value == null || value.toUpperCase() == 'N') return null;
    return value;
  }

  static String? _nullIfU(String? value) {
    if (value == null || value.toUpperCase() == 'U') return null;
    return value;
  }
}
