import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/types/category_filter.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/types/eligibility_filter.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/types/filter_widgets.dart';
import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final double selectedDistance;
  final Set<String> selectedCategories;
  final Map<EligibilityRequirement, bool?> selectedEligibilityRequirements;
  final bool showFavoritesOnly;
  final bool showOpenNowOnly;
  final VoidCallback onFavoritesTap;
  final VoidCallback onOpenNowTap;
  final VoidCallback onFiltersTap;
  final VoidCallback onDistanceTap;
  final VoidCallback onCategoryTap;
  final VoidCallback onEligibilityTap;

  const FilterBar({
    super.key,
    required this.selectedDistance,
    required this.selectedCategories,
    required this.selectedEligibilityRequirements,
    required this.showFavoritesOnly,
    required this.showOpenNowOnly,
    required this.onFavoritesTap,
    required this.onOpenNowTap,
    required this.onFiltersTap,
    required this.onDistanceTap,
    required this.onCategoryTap,
    required this.onEligibilityTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: FilterDesignTokens.filterBarHeight,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(
              left: FilterDesignTokens.spacingLarge,
              right: FilterDesignTokens.spacingSmall,
            ),
            children: [
              GestureDetector(
                onTap: onFiltersTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FilterDesignTokens.spacingLarge,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.resedaGreen,
                    borderRadius: BorderRadius.circular(
                      FilterDesignTokens.borderRadiusMedium,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune,
                        color: Colors.white,
                        size: FilterDesignTokens.iconSizeMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: FilterDesignTokens.spacingSmall),
              ValueFilter(
                label:
                    '${selectedDistance.toStringAsFixed(selectedDistance == selectedDistance.roundToDouble() ? 0 : 1)} mi',
                onTap: onDistanceTap,
              ),
              const SizedBox(width: FilterDesignTokens.spacingSmall),
              CategoryFilter(
                selectedCategories: selectedCategories,
                onTap: onCategoryTap,
              ),
              const SizedBox(width: FilterDesignTokens.spacingSmall),
              ToggleFilter(
                label: 'Open Now',
                isActive: showOpenNowOnly,
                onTap: onOpenNowTap,
              ),
              const SizedBox(width: FilterDesignTokens.spacingSmall),
              ToggleFilter(
                label: 'Favorites',
                isActive: showFavoritesOnly,
                onTap: onFavoritesTap,
              ),
              const SizedBox(width: FilterDesignTokens.spacingSmall),
              EligibilityFilter(
                selectedRequirements: selectedEligibilityRequirements,
                onTap: onEligibilityTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
