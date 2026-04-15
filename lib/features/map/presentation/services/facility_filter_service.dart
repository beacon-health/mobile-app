import '../../constants/filter_constants.dart';
import '../../domain/models/facility_model.dart';

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

      // Category filter — match on appCategory
      final matchesCategory = selectedCategories.isEmpty ||
          selectedCategories.contains(facility.appCategory);

      // Eligibility requirements filter
      // U (unknown) values are omitted from the map and always
      // pass through.
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

      return matchesSearch &&
          matchesFavorites &&
          matchesOpenNow &&
          matchesCategory &&
          matchesRequirements;
    }).toList();
  }

  /// Returns all unique app categories from a list of facilities.
  static Set<String> getAvailableCategories(
    List<Facility> facilities,
  ) {
    final categories = <String>{};
    for (final facility in facilities) {
      categories.add(facility.appCategory);
    }
    return categories;
  }
}
