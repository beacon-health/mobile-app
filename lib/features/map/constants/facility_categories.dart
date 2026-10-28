/// Category taxonomy for the map.
///
/// Three dimensions, all sourced from `FCT_Supabase`:
/// * **`service_tags`** (24 keys) drive the map's Category filter: the 3-5
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
  /// value — it simply won't match any group. None of them is money, work or
  /// legal help, so an untagged facility never lands in
  /// [groupMoneyJobsLegal].
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
  // quick-action grid, plus a neutral fallback. These strings are keys — the
  // filter value and the icon/color key — not what anyone reads: the names on
  // screen come from `FacilityCategoryIcons.groupLabel`.
  static const String groupHealthCare = 'Health Care';
  static const String groupMentalHealth = 'Mental Health';
  static const String groupBasicNeeds = 'Basic Needs';
  static const String groupHousingShelter = 'Housing & Shelter';
  static const String groupFamilyCommunity = 'Family & Community';
  static const String groupMoneyJobsLegal = 'Money, Jobs & Legal Help';

  /// Fallback for facilities whose category is null or unrecognized.
  ///
  /// Every known value maps to one of the six groups above, so this only ever
  /// applies to unknown data — it is **not** a quick-action button. Keeping it
  /// separate from [groupFamilyCommunity] means a grey pin unambiguously reads
  /// as "uncategorized" rather than "community nonprofit".
  static const String groupOther = 'Other';

  /// The six quick-action groups, in Home grid order (3 columns × 2 rows).
  static const List<String> quickActionGroups = [
    groupHealthCare,
    groupMentalHealth,
    groupHousingShelter,
    groupBasicNeeds,
    groupFamilyCommunity,
    groupMoneyJobsLegal,
  ];

  /// The `service_tags` keys and the group each sits under, in filter-sheet
  /// order — the one list of chips. Grouped by what someone comes looking
  /// for: rides sit with the families, seniors, veterans and people with
  /// disabilities most of those programs serve, and money, work and legal
  /// help share a group of their own.
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
    'children_families': groupFamilyCommunity,
    'seniors': groupFamilyCommunity,
    'disability': groupFamilyCommunity,
    'veterans': groupFamilyCommunity,
    'transportation': groupFamilyCommunity,
    'financial_support': groupMoneyJobsLegal,
    'jobs_education': groupMoneyJobsLegal,
    'legal': groupMoneyJobsLegal,
  };

  /// The 24 chip keys, in filter-sheet order: the Category filter's options.
  static final List<String> serviceTagKeys =
      List.unmodifiable(serviceTagGroups.keys);

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
      case 'Children and Families':
      case 'Seniors':
      case 'Veterans':
      case 'Disability Services':
        return groupFamilyCommunity;
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
