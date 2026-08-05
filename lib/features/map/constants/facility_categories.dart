/// Category taxonomy for the map.
///
/// Two dimensions, both sourced from `FCT_Supabase`:
/// * **`category_broad`** (13 values) drives the map's Category filter. The
///   values are already user-facing prose, so they render as-is.
/// * **`category_detail`** (21 values) is the finer grain beneath it. It isn't
///   a filter dimension (21 chips is too many) but it is searchable and
///   available for display.
///
/// Marker icons and colors consolidate the 13 broad values into the six Home
/// quick-action groups, plus a neutral fallback.
class FacilityCategories {
  /// The 13 distinct `category_broad` values, used as the Category filter
  /// options. A facility may have a null value — it simply won't match any
  /// selected category.
  static const List<String> categoryBroadValues = [
    'Addiction Recovery',
    'Basic Needs',
    'Children and Families',
    'Community Services',
    'Disability Services',
    'Health Charities',
    'Home Care',
    'Hospitals',
    'Housing',
    'Medical Care',
    'Mental Health',
    'Seniors',
    'Veterans',
  ];

  // The six consolidated groups that drive marker icons/colors and the Home
  // quick-action grid, plus a neutral fallback.
  static const String groupHealthCare = 'Health Care';
  static const String groupMentalHealth = 'Mental Health';
  static const String groupBasicNeeds = 'Basic Needs';
  static const String groupHousingShelter = 'Housing & Shelter';
  static const String groupCommunity = 'Community Resources';
  static const String groupSpecialized = 'Specialized Services';

  /// Fallback for facilities whose `category_broad` is null or unrecognized.
  ///
  /// Every known value maps to one of the six groups above, so this only ever
  /// applies to unknown data — it is **not** a quick-action button. Keeping it
  /// separate from [groupCommunity] means a grey pin unambiguously reads as
  /// "uncategorized" rather than "community nonprofit".
  static const String groupOther = 'Other';

  /// The six quick-action groups, in Home grid order (3 columns × 2 rows).
  static const List<String> quickActionGroups = [
    groupHealthCare,
    groupMentalHealth,
    groupHousingShelter,
    groupBasicNeeds,
    groupCommunity,
    groupSpecialized,
  ];

  /// Consolidates a `category_broad` value (or null) into a high-level group
  /// for marker icon/color selection.
  static String groupFor(String? categoryBroad) {
    switch (categoryBroad) {
      case 'Medical Care':
      case 'Hospitals':
      case 'Home Care':
      case 'Health Charities':
        return groupHealthCare;
      case 'Mental Health':
      case 'Addiction Recovery':
        return groupMentalHealth;
      case 'Housing':
        return groupHousingShelter;
      case 'Basic Needs':
        return groupBasicNeeds;
      case 'Community Services':
        return groupCommunity;
      case 'Children and Families':
      case 'Seniors':
      case 'Veterans':
      case 'Disability Services':
        return groupSpecialized;
      default:
        return groupOther;
    }
  }

  /// The `category_broad` values that roll up into [group] — used by the Home
  /// quick-action buttons to translate a tapped group into a map filter.
  static List<String> valuesForGroup(String group) {
    return categoryBroadValues.where((v) => groupFor(v) == group).toList();
  }

  /// True if [value] is one of the six consolidated group names (i.e. a Home
  /// quick-action), rather than a raw `category_broad` value.
  static bool isGroup(String value) => quickActionGroups.contains(value);
}
