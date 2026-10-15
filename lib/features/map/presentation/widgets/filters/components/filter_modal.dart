import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/drag_handle.dart';
import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:beacon_app/features/map/constants/filter_l10n.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/components/selection_chip_builder.dart';
import 'package:beacon_app/features/map/presentation/widgets/markers/marker_icon_factory.dart';
import 'package:beacon_app/features/map/utils/facility_formatting.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

// Category + Preferences only: distance is fixed at
// MapConstants.defaultRadiusMiles and eligibility auto-applies from Profile.
enum FilterSection {
  category,
  preferences,
}

/// The filters as the sheet holds them before "Show results" commits them.
typedef FilterSelection = ({
  Set<String> categories,
  Map<PreferenceRequirement, bool?> preferenceRequirements,
  bool showFavoritesOnly,
  bool showOpenNowOnly,
});

class FilterModal extends StatefulWidget {
  final Set<String> selectedCategories;
  final List<String> availableCategories;
  final Map<PreferenceRequirement, bool?> selectedPreferenceRequirements;
  final bool showFavoritesOnly;
  final bool showOpenNowOnly;

  /// The section to scroll to on opening: the one whose chip was tapped.
  final FilterSection? expandedSection;

  /// Guests can't favorite or filter by preferences. Both controls render
  /// locked here, exactly as their chips do in the filter bar, so the two
  /// can't disagree.
  final bool isGuest;

  /// Called when a guest taps a locked control (the sign-in prompt).
  final VoidCallback? onLockedTap;

  /// How many facilities a selection would leave on the map, so the button
  /// can say what tapping it will do. Null hides the count ("Apply").
  final int Function(FilterSelection)? resultCount;

  const FilterModal({
    super.key,
    required this.selectedCategories,
    required this.availableCategories,
    required this.selectedPreferenceRequirements,
    required this.showFavoritesOnly,
    required this.showOpenNowOnly,
    this.expandedSection,
    this.isGuest = false,
    this.onLockedTap,
    this.resultCount,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late Set<String> _tempCategories;
  late Map<PreferenceRequirement, bool?> _tempPreferenceRequirements;
  late bool _tempShowFavoritesOnly;
  late bool _tempShowOpenNowOnly;

  final ScrollController _scrollController = ScrollController();
  final Map<FilterSection, GlobalKey> _sectionKeys = {
    FilterSection.category: GlobalKey(),
    FilterSection.preferences: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _tempCategories = Set.from(widget.selectedCategories);
    // A guest never carries these two filters, whatever state arrived.
    _tempPreferenceRequirements =
        widget.isGuest ? {} : Map.from(widget.selectedPreferenceRequirements);
    _tempShowFavoritesOnly = !widget.isGuest && widget.showFavoritesOnly;
    _tempShowOpenNowOnly = widget.showOpenNowOnly;

    if (widget.expandedSection != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSection(widget.expandedSection!);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(FilterSection section) {
    final target = _sectionKeys[section]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: AppMotion.of(context, AppMotion.medium),
      curve: AppMotion.curve,
    );
  }

  FilterSelection get _selection => (
        categories: _tempCategories,
        preferenceRequirements: _tempPreferenceRequirements,
        showFavoritesOnly: _tempShowFavoritesOnly,
        showOpenNowOnly: _tempShowOpenNowOnly,
      );

  void _clearAll() {
    Navigator.pop(context, {
      'categories': <String>{},
      'preferenceRequirements': <PreferenceRequirement, bool?>{},
      'showFavoritesOnly': false,
      'showOpenNowOnly': false,
    });
  }

  void _apply() {
    Navigator.pop(context, {
      'categories': _tempCategories,
      'preferenceRequirements': _tempPreferenceRequirements,
      'showFavoritesOnly': _tempShowFavoritesOnly,
      'showOpenNowOnly': _tempShowOpenNowOnly,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final count = widget.resultCount?.call(_selection);

    final sheetColor =
        theme.bottomSheetTheme.backgroundColor ?? colorScheme.surface;

    // A Material, not a colored box: the rows inside paint their ink on it.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height *
            FilterConstants.modalHeightRatio,
      ),
      child: Material(
        color: sheetColor,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheetTop),
        clipBehavior: Clip.antiAlias,
        child: _buildContent(context, sheetColor, count),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color sheetColor, int? count) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final clearButton = OutlinedButton(
      onPressed: _clearAll,
      child: Text(l10n.filterClearAll, textAlign: TextAlign.center),
    );
    // Says what will happen, not just "Apply".
    final applyButton = FilledButton(
      onPressed: _apply,
      child: Text(
        count == null ? l10n.filterApply : l10n.filterShowResults(count),
        textAlign: TextAlign.center,
      ),
    );
    // Side by side and pinned at ordinary text sizes. Past that each needs
    // the full width, and pinned they would crowd out the filters — so they
    // stack at the end of the list instead.
    final stackButtons =
        MediaQuery.textScalerOf(context).scale(100) / 100 >= 1.5;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: AppSpacing.sm),
          child: DragHandle(),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.sheetGutter,
            end: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.filterFilters,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                tooltip: l10n.filterClose,
              ),
            ],
          ),
        ),
        Flexible(
          child: ListView(
            controller: _scrollController,
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: [
              _switchRow(
                l10n.filterOpenNow,
                _tempShowOpenNowOnly,
                (value) => setState(() => _tempShowOpenNowOnly = value),
              ),
              if (widget.isGuest)
                _lockedRow(l10n.filterFavorites)
              else
                _switchRow(
                  l10n.filterFavorites,
                  _tempShowFavoritesOnly,
                  (value) => setState(() => _tempShowFavoritesOnly = value),
                ),
              _sectionTitle(FilterSection.category, l10n.filterCategory),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sheetGutter,
                ),
                child: _buildCategoryContent(),
              ),
              if (widget.isGuest) ...[
                const SizedBox(height: AppSpacing.lg),
                KeyedSubtree(
                  key: _sectionKeys[FilterSection.preferences],
                  child: _lockedRow(l10n.filterPreferences),
                ),
              ] else ...[
                _sectionTitle(
                  FilterSection.preferences,
                  l10n.filterOnlyShowPlacesThat,
                ),
                // A switch per attribute: on means "must have it". There is
                // no "must not" — nobody searches for places that refuse
                // walk-ins.
                for (final requirement
                    in FilterConstants.preferenceRequirements)
                  _switchRow(
                    requirement.localizedName(l10n),
                    _tempPreferenceRequirements[requirement] ?? false,
                    (value) => setState(
                      () => _tempPreferenceRequirements[requirement] =
                          value ? true : null,
                    ),
                  ),
              ],
              if (stackButtons)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sheetGutter,
                    AppSpacing.xl,
                    AppSpacing.sheetGutter,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      applyButton,
                      const SizedBox(height: AppSpacing.sm),
                      clearButton,
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (!stackButtons)
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.sheetGutter,
              right: AppSpacing.sheetGutter,
              top: AppSpacing.md,
              bottom: AppSpacing.md + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: sheetColor,
              boxShadow: AppShadows.sheet,
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: clearButton),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 3, child: applyButton),
              ],
            ),
          ),
      ],
    );
  }

  Widget _sectionTitle(FilterSection section, String title) {
    final theme = Theme.of(context);
    return Padding(
      key: _sectionKeys[section],
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sheetGutter,
        AppSpacing.xl,
        AppSpacing.sheetGutter,
        AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ),
    );
  }

  Widget _switchRow(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sheetGutter,
      ),
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  /// Something that needs an account. Full contrast, with a lock: tapping it
  /// does something (offers sign-in), so it mustn't look switched off.
  Widget _lockedRow(String title) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sheetGutter,
      ),
      title: Text(title),
      trailing: Icon(Icons.lock_outline, color: muted),
      onTap: widget.onLockedTap,
    );
  }

  /// The categories under the six names Home uses for them, in Home's
  /// order, each with its group's icon. Anything outside the six (none
  /// today) follows, unheaded.
  Widget _buildCategoryContent() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final grouped = <String, List<String>>{
      for (final group in FacilityCategories.quickActionGroups) group: [],
    };
    final rest = <String>[];
    for (final category in widget.availableCategories) {
      (grouped[FacilityCategories.groupFor(category)] ?? rest).add(category);
    }

    Widget options(List<String> categories) =>
        SelectionChipBuilder.buildMultiSelection<String>(
          context: context,
          options: categories,
          selectedValues: _tempCategories,
          onToggle: (category, selected) {
            setState(() {
              if (selected) {
                _tempCategories.add(category);
              } else {
                _tempCategories.remove(category);
              }
            });
          },
          getLabel: FacilityCategoryIcons.getCategoryDisplayName,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, MapEntry(key: group, value: categories))
            in grouped.entries.where((e) => e.value.isNotEmpty).indexed) ...[
          Padding(
            // More room above a heading than below it, so each reads as
            // the start of its own group.
            padding: EdgeInsets.only(
              top: index == 0 ? AppSpacing.xs : AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
            child: Semantics(
              header: true,
              child: Row(
                children: [
                  // The group's own icon and color, as on Home.
                  Icon(
                    MarkerUtils.getIconForCategory(group),
                    size: AppIconSize.sm,
                    color: MarkerUtils.getColorForCategory(
                      group,
                      brightness: theme.brightness,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      FacilityCategoryIcons.groupLabel(l10n, group),
                      // Below "Category" in weight and size, so the section
                      // title still leads.
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          options(categories),
        ],
        if (rest.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          options(rest),
        ],
      ],
    );
  }
}
