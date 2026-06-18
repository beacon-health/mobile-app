import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';

/// Service for filtering facilities based on various criteria.
class FacilityFilterService {
  /// Filters facilities based on search text, categories, and other filters.
  ///
  /// [selectedCategories] contains app category strings (e.g., "Health Care").
  static List<Facility> filterFacilities(
    List<Facility> allFacilities, {
    required String searchText,
    required Set<String> selectedCategories,
    Map<EligibilityRequirement, bool?>? selectedEligibilityRequirements,
    Map<PreferenceRequirement, bool?>? selectedPreferenceRequirements,
    required bool showFavoritesOnly,
    required bool showOpenNowOnly,
  }) {
    return allFacilities.where((facility) {
      // Search filter
      final q = searchText.toLowerCase();
      final matchesSearch = q.isEmpty ||
          facility.name.toLowerCase().contains(q) ||
          facility.description.toLowerCase().contains(q) ||
          facility.services.any(
            (s) => s.toLowerCase().contains(q),
          );

      // Favorites filter
      final matchesFavorites = !showFavoritesOnly || facility.isFavorite;

      // Open Now filter
      final matchesOpenNow = !showOpenNowOnly || facility.isOpenNow;

      // Category filter — match on category_level_2 (the map's filter dimension)
      final matchesCategory = selectedCategories.isEmpty ||
          (facility.categoryLevel2 != null &&
              selectedCategories.contains(facility.categoryLevel2));

      // Eligibility requirements filter
      // null values are unset and always pass through.
      bool matchesRequirements = true;
      if (selectedEligibilityRequirements != null) {
        for (final entry in selectedEligibilityRequirements.entries) {
          if (entry.value == null) continue;
          final facilityValue =
              facility.eligibilityRequirements[entry.key.fieldKey];
          if (facilityValue == null) continue;
          if (facilityValue != entry.value) {
            matchesRequirements = false;
            break;
          }
        }
      }

      // Preference requirements filter — same logic as eligibility.
      bool matchesPreferences = true;
      if (selectedPreferenceRequirements != null) {
        for (final entry in selectedPreferenceRequirements.entries) {
          if (entry.value == null) continue;
          final facilityValue =
              facility.eligibilityRequirements[entry.key.fieldKey];
          if (facilityValue == null) continue;
          if (facilityValue != entry.value) {
            matchesPreferences = false;
            break;
          }
        }
      }

      return matchesSearch &&
          matchesFavorites &&
          matchesOpenNow &&
          matchesCategory &&
          matchesRequirements &&
          matchesPreferences;
    }).toList();
  }

  /// Returns the distinct `category_level_2` values present in [facilities].
  ///
  /// The map's Category filter uses the fixed `FacilityCategories` list rather
  /// than this (so all options show regardless of region), but this stays
  /// available for any region-scoped needs.
  static Set<String> getAvailableCategories(
    List<Facility> facilities,
  ) {
    final categories = <String>{};
    for (final facility in facilities) {
      final c = facility.categoryLevel2;
      if (c != null && c.isNotEmpty) categories.add(c);
    }
    return categories;
  }
}
