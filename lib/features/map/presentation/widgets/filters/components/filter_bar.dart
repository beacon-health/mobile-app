import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart'
    show PreferenceRequirement;
import 'package:beacon_app/features/map/presentation/widgets/filters/components/filter_chip.dart';
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
    final l10n = AppLocalizations.of(context)!;
    // A scrolling row sized by its chips, not a fixed-height list: the chips
    // grow with the text size and the bar grows with them.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        // Room for the chips' shadows, which a scroll view would clip.
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          CustomFilterChip(
            label: l10n.filterFilters,
            icon: Icons.tune,
            isProminent: true,
            isSelected: false,
            hasDropdown: false,
            onTap: onFiltersTap,
          ),
          const SizedBox(width: AppSpacing.sm),
          ToggleFilter(
            label: l10n.filterOpenNow,
            isActive: showOpenNowOnly,
            onTap: onOpenNowTap,
          ),
          const SizedBox(width: AppSpacing.sm),
          ToggleFilter(
            label: l10n.filterFavorites,
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
    );
  }
}
