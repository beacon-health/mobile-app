/// Category taxonomy for the map.
///
/// Two dimensions, both sourced from `FCT_Supabase`:
/// * **`category_broad`** (13 values) drives the map's Category filter. The
///   values are already user-facing prose, so they render as-is.
/// * **`category_detail`** (21 values) is the finer grain beneath it. It isn't
///   a filter dimension (21 chips is too many) but it is searchable and
///   available for display.
///
/// Marker icons and colors consolidate the 13 broad values into the four
/// high-level groups shown on the Home page, plus a neutral fallback. Keeping
/// the filter list and the icon grouping in one place means they can't drift.
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

  // The four consolidated groups (+ a neutral fallback) that drive marker
  // icons/colors and the Home quick-action buttons.
  static const String groupHealthCare = 'Health Care';
  static const String groupMentalHealth = 'Mental Health';
  static const String groupBasicNeeds = 'Basic Needs';
  static const String groupHousingShelter = 'Housing & Shelter';
  static const String groupOther = 'Community Resource';

  /// Consolidates a `category_broad` value (or null) into a high-level group
  /// for marker icon/color selection.
  ///
  /// 'Community Services' is deliberately left in [groupOther]: it's the
  /// generic community-nonprofit bucket and the single largest category, so
  /// giving it a neutral pin keeps the specific groups legible on the map.
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
      case 'Children and Families':
      case 'Seniors':
      case 'Veterans':
      case 'Disability Services':
        return groupBasicNeeds;
      default:
        return groupOther;
    }
  }

  /// The `category_broad` values that roll up into [group] — used by the Home
  /// quick-action buttons to translate a tapped group into a map filter.
  static List<String> valuesForGroup(String group) {
    return categoryBroadValues.where((v) => groupFor(v) == group).toList();
  }

  /// True if [value] is one of the four consolidated group names.
  static bool isGroup(String value) =>
      value == groupHealthCare ||
      value == groupMentalHealth ||
      value == groupBasicNeeds ||
      value == groupHousingShelter;
}
