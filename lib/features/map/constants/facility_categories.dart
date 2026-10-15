/// Category taxonomy for the map.
///
/// Three dimensions, all sourced from `FCT_Supabase`:
/// * **`service_tags`** (24 keys) drive the map's Category filter: the 2-4
///   chips under each of the six Home groups. A facility carries every chip
///   it offers (a health center with a pantry is both a Medical Clinic and a
///   Food Pantry); the first is its main one. Keys, not prose: the labels are
///   in the ARB files. The data pipeline writes them (beacon-data
///   `service_tags.py`); this key list must match it.
/// * **`category_broad`** (13 values) is the fallback for a facility with no
///   tags yet: it still sits under its group, so tapping a Home group (every
///   chip of it selected) finds it.
/// * **`category_detail`** (21 values) is searchable and available for display.
///
/// Marker icons and colors consolidate everything into the six Home
/// quick-action groups, plus a neutral fallback.
class FacilityCategories {
  /// The 13 distinct `category_broad` values. A facility may have a null
  /// value — it simply won't match any group.
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

  /// Fallback for facilities whose category is null or unrecognized.
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

  /// The `service_tags` keys and the group each sits under, in filter-sheet
  /// order. Within a group the chips split one dimension, so they don't
  /// overlap.
  static const Map<String, String> serviceTagGroups = {
    'medical_clinic': groupHealthCare,
    'hospital': groupHealthCare,
    'dental_vision': groupHealthCare,
    'home_care': groupHealthCare,
    'mental_health_care': groupMentalHealth,
    'crisis': groupMentalHealth,
    'addiction': groupMentalHealth,
    'recovery': groupMentalHealth,
    'emergency_shelter': groupHousingShelter,
    'abuse_shelter': groupHousingShelter,
    'transitional_housing': groupHousingShelter,
    'affordable_housing': groupHousingShelter,
    'food_pantry': groupBasicNeeds,
    'meals': groupBasicNeeds,
    'essentials': groupBasicNeeds,
    'baby_supplies': groupBasicNeeds,
    'legal': groupCommunity,
    'jobs_education': groupCommunity,
    'financial_support': groupCommunity,
    'transportation': groupCommunity,
    'children_families': groupSpecialized,
    'disability': groupSpecialized,
    'seniors': groupSpecialized,
    'veterans': groupSpecialized,
  };

  /// The 24 chip keys, in filter-sheet order: the Category filter's options.
  /// Const so widgets can take it in a const constructor; tests pin that it
  /// lists exactly [serviceTagGroups]'s keys, in the same order.
  static const List<String> serviceTagKeys = [
    'medical_clinic',
    'hospital',
    'dental_vision',
    'home_care',
    'mental_health_care',
    'crisis',
    'addiction',
    'recovery',
    'emergency_shelter',
    'abuse_shelter',
    'transitional_housing',
    'affordable_housing',
    'food_pantry',
    'meals',
    'essentials',
    'baby_supplies',
    'legal',
    'jobs_education',
    'financial_support',
    'transportation',
    'children_families',
    'disability',
    'seniors',
    'veterans',
  ];

  /// Each chip's English label, for search (screens show the localized label
  /// from the ARB files).
  static const Map<String, String> serviceTagEnglish = {
    'medical_clinic': 'Medical Clinics',
    'hospital': 'Hospitals',
    'dental_vision': 'Dental & Vision',
    'home_care': 'Home Care & Hospice',
    'mental_health_care': 'Mental Health Care',
    'crisis': 'Crisis Support',
    'addiction': 'Addiction Treatment',
    'recovery': 'Recovery',
    'emergency_shelter': 'Emergency Shelter',
    'abuse_shelter': 'Shelter from Abuse',
    'transitional_housing': 'Transitional Housing',
    'affordable_housing': 'Affordable Housing',
    'food_pantry': 'Food Pantries',
    'meals': 'Free Meals',
    'essentials': 'Clothing & Household Items',
    'baby_supplies': 'Baby Supplies',
    'legal': 'Legal Support',
    'jobs_education': 'Jobs & Education',
    'financial_support': 'Financial Support',
    'transportation': 'Transportation',
    'children_families': 'Children & Families',
    'disability': 'Disability Services',
    'seniors': 'Seniors',
    'veterans': 'Veterans',
  };

  static bool isServiceTag(String value) => serviceTagGroups.containsKey(value);

  /// Consolidates a chip key, a `category_broad` value or null into a
  /// high-level group for marker icon/color selection.
  static String groupFor(String? value) {
    final tagGroup = serviceTagGroups[value];
    if (tagGroup != null) return tagGroup;
    switch (value) {
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

  /// The chip keys under [group] — used by the Home quick-action buttons to
  /// translate a tapped group into a map filter (every chip of the group).
  static List<String> valuesForGroup(String group) =>
      serviceTagKeys.where((k) => serviceTagGroups[k] == group).toList();

  /// True if [value] is one of the six consolidated group names (i.e. a Home
  /// quick-action), rather than a chip key.
  static bool isGroup(String value) => quickActionGroups.contains(value);

  /// Whether a facility belongs under the [selected] chips: it carries one of
  /// them, or it has no tags yet and every chip of its `category_broad` group
  /// is selected (a Home group tap), so untagged places never vanish.
  static bool matchesSelection(
    List<String> serviceTags,
    String? categoryBroad,
    Set<String> selected,
  ) {
    if (selected.isEmpty) return true;
    if (serviceTags.isNotEmpty) return serviceTags.any(selected.contains);
    final group = groupFor(categoryBroad);
    if (group == groupOther) return false;
    return valuesForGroup(group).every(selected.contains);
  }
}
