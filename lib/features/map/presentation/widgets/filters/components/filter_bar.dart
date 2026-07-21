import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/types/category_filter.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/types/filter_widgets.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/types/preferences_filter.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final Set<String> selectedCategories;
  final Map<PreferenceRequirement, bool?> selectedPreferenceRequirements;
  final bool showFavoritesOnly;
  final bool showOpenNowOnly;
  final bool isGuestMode;
  final VoidCallback onFavoritesTap;
  final VoidCallback onOpenNowTap;
  final VoidCallback onFiltersTap;
  final VoidCallback onCategoryTap;
  final VoidCallback onPreferencesTap;

  const FilterBar({
    super.key,
    required this.selectedCategories,
    required this.selectedPreferenceRequirements,
    required this.showFavoritesOnly,
    required this.showOpenNowOnly,
    required this.onFavoritesTap,
    required this.onOpenNowTap,
    required this.onFiltersTap,
    required this.onCategoryTap,
    required this.onPreferencesTap,
    this.isGuestMode = false,
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
              ToggleFilter(
                label: AppLocalizations.of(context)!.filterOpenNow,
                isActive: showOpenNowOnly,
                onTap: onOpenNowTap,
              ),
              const SizedBox(width: FilterDesignTokens.spacingSmall),
              ToggleFilter(
                label: AppLocalizations.of(context)!.filterFavorites,
                isActive: showFavoritesOnly,
                isLocked: isGuestMode,
                onTap: onFavoritesTap,
              ),
              const SizedBox(width: FilterDesignTokens.spacingSmall),
              CategoryFilter(
                selectedCategories: selectedCategories,
                onTap: onCategoryTap,
              ),
              const SizedBox(width: FilterDesignTokens.spacingSmall),
              PreferencesFilter(
                selectedRequirements: selectedPreferenceRequirements,
                isLocked: isGuestMode,
                onTap: onPreferencesTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
