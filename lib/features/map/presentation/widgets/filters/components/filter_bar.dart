import 'package:beacon_app/core/theme/theme.dart';
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
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: FilterConstants.barHeight,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.sm,
            ),
            children: [
              GestureDetector(
                onTap: onFiltersTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: AppRadii.mdAll,
                  ),
                  child: Icon(
                    Icons.tune,
                    color: scheme.onPrimary,
                    size: AppIconSize.md,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ToggleFilter(
                label: AppLocalizations.of(context)!.filterOpenNow,
                isActive: showOpenNowOnly,
                onTap: onOpenNowTap,
              ),
              const SizedBox(width: AppSpacing.sm),
              ToggleFilter(
                label: AppLocalizations.of(context)!.filterFavorites,
                isActive: showFavoritesOnly,
                isLocked: isGuestMode,
                onTap: onFavoritesTap,
              ),
              const SizedBox(width: AppSpacing.sm),
              CategoryFilter(
                selectedCategories: selectedCategories,
                onTap: onCategoryTap,
              ),
              const SizedBox(width: AppSpacing.sm),
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
