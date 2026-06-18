/// Category taxonomy for the map.
///
/// Filtering is driven by `category_level_2` (12 known values; null also occurs
/// in the data), while marker icons / colors consolidate those into the four
/// high-level groups shown on the Home page. Keeping both in one place means the
/// filter list and the icon grouping never drift apart.
class FacilityCategories {
  /// The 12 distinct `category_level_2` values, used as the map's Category
  /// filter options. (A facility may also have a null value — it simply won't
  /// match any selected category.)
  static const List<String> categoryLevel2Values = [
    'Hospital- ACUTE',
    'Hospital- CHILD',
    'Hospital- LTACH',
    'Hospital- PSYCH',
    'Hospital- REHAB',
    'Hospital- RELIGIOUS NON-MED',
    'Nonprofit - Health Care',
    'Nonprofit - Housing and Shelter',
    'Nonprofit - Human Services',
    'Nonprofit - Mental Health and Crisis Intervention',
    'Nonprofit - Public and Societal Benefit',
    'Treatment Facility',
  ];

  // The four consolidated groups (+ a neutral fallback) that drive marker
  // icons/colors and the Home quick-action buttons.
  static const String groupHealthCare = 'Health Care';
  static const String groupMentalHealth = 'Mental Health';
  static const String groupBasicNeeds = 'Basic Needs';
  static const String groupHousingShelter = 'Housing & Shelter';
  static const String groupOther = 'Community Resource';

  /// Consolidates a `category_level_2` value (or null) into a high-level group
  /// for marker icon/color selection.
  static String groupFor(String? categoryLevel2) {
    switch (categoryLevel2) {
      case 'Hospital- ACUTE':
      case 'Hospital- CHILD':
      case 'Hospital- LTACH':
      case 'Hospital- REHAB':
      case 'Hospital- RELIGIOUS NON-MED':
      case 'Nonprofit - Health Care':
        return groupHealthCare;
      case 'Hospital- PSYCH':
      case 'Nonprofit - Mental Health and Crisis Intervention':
      case 'Treatment Facility':
        return groupMentalHealth;
      case 'Nonprofit - Housing and Shelter':
        return groupHousingShelter;
      case 'Nonprofit - Human Services':
      case 'Nonprofit - Public and Societal Benefit':
        return groupBasicNeeds;
      default:
        return groupOther;
    }
  }

  /// The `category_level_2` values that roll up into [group] — used by the Home
  /// quick-action buttons to translate a tapped group into a map filter.
  static List<String> valuesForGroup(String group) {
    return categoryLevel2Values.where((v) => groupFor(v) == group).toList();
  }

  /// True if [value] is one of the four consolidated group names.
  static bool isGroup(String value) =>
      value == groupHealthCare ||
      value == groupMentalHealth ||
      value == groupBasicNeeds ||
      value == groupHousingShelter;
}
