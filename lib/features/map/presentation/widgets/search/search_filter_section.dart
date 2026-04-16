import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/components/filter_bar.dart';
import 'package:beacon_app/features/map/presentation/widgets/search/facility_search.dart';
import 'package:beacon_app/features/map/presentation/widgets/search/location_search.dart';
import 'package:flutter/material.dart';

class SearchFilterSection extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onSearchChanged;
  final String currentLocation;
  final Function(String, double?, double?) onLocationChanged;
  final Function(bool) onLocationFocusChanged;
  final double selectedDistance;
  final Set<String> selectedCategories;
  final Map<EligibilityRequirement, bool?> selectedEligibilityRequirements;
  final Map<PreferenceRequirement, bool?> selectedPreferenceRequirements;
  final bool showFavoritesOnly;
  final bool showOpenNowOnly;
  final VoidCallback onFavoritesTap;
  final VoidCallback onOpenNowTap;
  final VoidCallback onFiltersTap;
  final VoidCallback onDistanceTap;
  final VoidCallback onCategoryTap;
  final VoidCallback onEligibilityTap;
  final VoidCallback onPreferencesTap;

  const SearchFilterSection({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.currentLocation,
    required this.onLocationChanged,
    required this.onLocationFocusChanged,
    required this.selectedDistance,
    required this.selectedCategories,
    required this.selectedEligibilityRequirements,
    required this.selectedPreferenceRequirements,
    required this.showFavoritesOnly,
    required this.showOpenNowOnly,
    required this.onFavoritesTap,
    required this.onOpenNowTap,
    required this.onFiltersTap,
    required this.onDistanceTap,
    required this.onCategoryTap,
    required this.onEligibilityTap,
    required this.onPreferencesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FacilitySearch(
            controller: searchController,
            focusNode: searchFocusNode,
            onChanged: onSearchChanged,
            onClear: onSearchChanged,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: LocationSearch(
            currentLocation: currentLocation,
            onLocationChanged: onLocationChanged,
            onFocusChanged: onLocationFocusChanged,
          ),
        ),
        FilterBar(
          selectedDistance: selectedDistance,
          selectedCategories: selectedCategories,
          selectedEligibilityRequirements: selectedEligibilityRequirements,
          selectedPreferenceRequirements: selectedPreferenceRequirements,
          showFavoritesOnly: showFavoritesOnly,
          showOpenNowOnly: showOpenNowOnly,
          onFavoritesTap: onFavoritesTap,
          onOpenNowTap: onOpenNowTap,
          onFiltersTap: onFiltersTap,
          onDistanceTap: onDistanceTap,
          onCategoryTap: onCategoryTap,
          onEligibilityTap: onEligibilityTap,
          onPreferencesTap: onPreferencesTap,
        ),
      ],
    );
  }
}
