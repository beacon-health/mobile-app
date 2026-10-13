import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/utils/map_geometry.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FacilityFilterService {
  /// Orders [facilities] nearest to [center] first and, when [within] is
  /// given, keeps only those inside it — what the list shows, so it matches
  /// what is on the map. With no [center] (the map hasn't reported its view
  /// yet) everything passes in its original order.
  ///
  /// Ties break on name then id: facilities that share an address are the
  /// same distance away, and without a tiebreak they would swap places on
  /// every refresh.
  static List<Facility> nearestFirst(
    List<Facility> facilities, {
    required LatLng? center,
    LatLngBounds? within,
  }) {
    if (center == null) return List.of(facilities);

    final distance = <String, double>{};
    final kept = <Facility>[];
    for (final facility in facilities) {
      if (within != null && !within.contains(facility.location)) continue;
      kept.add(facility);
      distance[facility.id] =
          MapGeometry.distanceMeters(center, facility.location);
    }
    kept.sort((a, b) {
      final byDistance = distance[a.id]!.compareTo(distance[b.id]!);
      if (byDistance != 0) return byDistance;
      final byName = a.name.compareTo(b.name);
      return byName != 0 ? byName : a.id.compareTo(b.id);
    });
    return kept;
  }

  /// What a facility's eligibility fields must be for someone who answered
  /// [state] to be shown it, in the form [filterFacilities] takes: a facility
  /// passes a gate when its value matches or isn't known.
  ///
  /// The four "required" switches say what the person can provide. Left off,
  /// facilities that require it are hidden; switched on, they are shown along
  /// with everything else — a switch never hides a facility that doesn't ask
  /// for it. Medicaid runs the other way: accepting it turns nobody away, so
  /// only switching it on filters, hiding the places known not to take it.
  static Map<EligibilityRequirement, bool?> eligibilityGates(
    EligibilityState state,
  ) {
    if (!state.applyToSearch) return const {};
    return {
      if (!state.proofOfIncome) EligibilityRequirement.proofOfIncome: false,
      if (!state.proofOfResidency)
        EligibilityRequirement.proofOfResidency: false,
      if (!state.insuranceRequired)
        EligibilityRequirement.insuranceRequired: false,
      if (!state.referralRequired)
        EligibilityRequirement.referralRequired: false,
      if (state.acceptsMedicaid) EligibilityRequirement.acceptsMedicaid: true,
    };
  }

  /// Filters by search text, categories, and preferences.
  /// [selectedCategories] holds `category_broad` values; Home quick-actions
  /// expand a group into its members first.
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
      // Client-side over the loaded region pool (≤250 rows), so matching
      // across every field costs nothing server-side.
      final q = searchText.toLowerCase();
      final matchesSearch = q.isEmpty ||
          facility.name.toLowerCase().contains(q) ||
          facility.description.toLowerCase().contains(q) ||
          facility.services.any(
            (s) => s.toLowerCase().contains(q),
          ) ||
          (facility.servicesSummary?.toLowerCase().contains(q) ?? false) ||
          (facility.categoryBroad?.toLowerCase().contains(q) ?? false) ||
          (facility.categoryDetail?.toLowerCase().contains(q) ?? false) ||
          facility.city.toLowerCase().contains(q);

      // Favorites filter
      final matchesFavorites = !showFavoritesOnly || facility.isFavorite;

      // Open Now filter
      final matchesOpenNow = !showOpenNowOnly || facility.isOpenNow;

      // Category filter — match on category_broad (the filter dimension).
      final matchesCategory = selectedCategories.isEmpty ||
          (facility.categoryBroad != null &&
              selectedCategories.contains(facility.categoryBroad));

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

  /// Distinct `category_broad` values present in [facilities]. The Category
  /// filter uses the fixed `FacilityCategories` list instead, so every option
  /// shows regardless of region.
  static Set<String> getAvailableCategories(
    List<Facility> facilities,
  ) {
    final categories = <String>{};
    for (final facility in facilities) {
      final c = facility.categoryBroad;
      if (c != null && c.isNotEmpty) categories.add(c);
    }
    return categories;
  }
}
