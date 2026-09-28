import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:beacon_app/features/map/constants/filter_l10n.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/components/selection_chip_builder.dart';
import 'package:beacon_app/features/map/utils/facility_formatting.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

// Category + Preferences only: distance is fixed at
// MapConstants.defaultRadiusMiles and eligibility auto-applies from Profile.
enum FilterSection {
  category,
  preferences,
}

class FilterModal extends StatefulWidget {
  final Set<String> selectedCategories;
  final List<String> availableCategories;
  final Map<PreferenceRequirement, bool?> selectedPreferenceRequirements;
  final bool showFavoritesOnly;
  final bool showOpenNowOnly;
  final FilterSection? expandedSection;

  const FilterModal({
    super.key,
    required this.selectedCategories,
    required this.availableCategories,
    required this.selectedPreferenceRequirements,
    required this.showFavoritesOnly,
    required this.showOpenNowOnly,
    this.expandedSection,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late Set<String> _tempCategories;
  late Map<PreferenceRequirement, bool?> _tempPreferenceRequirements;
  late bool _tempShowFavoritesOnly;
  late bool _tempShowOpenNowOnly;

  FilterSection? _expandedSection;
  final ScrollController _scrollController = ScrollController();
  final Map<FilterSection, GlobalKey> _sectionKeys = {
    FilterSection.category: GlobalKey(),
    FilterSection.preferences: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _tempCategories = Set.from(widget.selectedCategories);
    _tempPreferenceRequirements =
        Map.from(widget.selectedPreferenceRequirements);
    _tempShowFavoritesOnly = widget.showFavoritesOnly;
    _tempShowOpenNowOnly = widget.showOpenNowOnly;
    _expandedSection = widget.expandedSection;

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
    final key = _sectionKeys[section];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

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
    return Container(
      height:
          MediaQuery.of(context).size.height * FilterConstants.modalHeightRatio,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadii.sheetTop,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sheetGutter,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.filterFilters,
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.sheetGutter),
              children: [
                _buildToggleSection(
                  AppLocalizations.of(context)!.filterOpenNow,
                  _tempShowOpenNowOnly,
                  (value) => setState(() => _tempShowOpenNowOnly = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildToggleSection(
                  AppLocalizations.of(context)!.filterFavorites,
                  _tempShowFavoritesOnly,
                  (value) => setState(() => _tempShowFavoritesOnly = value),
                ),
                const Divider(height: AppSpacing.xxxl),
                _buildExpandableSection(
                  FilterSection.category,
                  AppLocalizations.of(context)!.filterCategory,
                  _buildCategoryContent(),
                ),
                const Divider(height: AppSpacing.xxxl),
                _buildExpandableSection(
                  FilterSection.preferences,
                  AppLocalizations.of(context)!.filterPreferences,
                  _buildPreferencesContent(),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.sheetGutter,
              right: AppSpacing.sheetGutter,
              top: AppSpacing.sheetGutter,
              bottom: AppSpacing.sheetGutter +
                  MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: AppShadows.sheet,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: OutlinedButton(
                    onPressed: _clearAll,
                    child: Text(AppLocalizations.of(context)!.filterClearAll),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 110,
                  child: ElevatedButton(
                    onPressed: _apply,
                    child: Text(AppLocalizations.of(context)!.filterApply),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSection(
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyLarge),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildExpandableSection(
    FilterSection section,
    String title,
    Widget content,
  ) {
    final isExpanded = _expandedSection == section;
    final theme = Theme.of(context);

    return Container(
      key: _sectionKeys[section],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedSection = isExpanded ? null : section;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurfaceMuted,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: content,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: FilterConstants.animationDuration,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent() {
    return SelectionChipBuilder.buildMultiSelection<String>(
      context: context,
      options: widget.availableCategories,
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
  }

  Widget _buildPreferencesContent() {
    for (final requirement in FilterConstants.preferenceRequirements) {
      _tempPreferenceRequirements.putIfAbsent(requirement, () => null);
    }

    return _buildRequirementOptions<PreferenceRequirement>(
      requirements: FilterConstants.preferenceRequirements,
      getValue: (req) => _tempPreferenceRequirements[req],
      getDisplayName: (req) => req.localizedName(AppLocalizations.of(context)!),
      onSetTrue: (req) => setState(
        () => _tempPreferenceRequirements[req] =
            _tempPreferenceRequirements[req] == true ? null : true,
      ),
      onSetFalse: (req) => setState(
        () => _tempPreferenceRequirements[req] =
            _tempPreferenceRequirements[req] == false ? null : false,
      ),
    );
  }

  Widget _buildRequirementOptions<T>({
    required List<T> requirements,
    required bool? Function(T) getValue,
    required String Function(T) getDisplayName,
    required void Function(T) onSetTrue,
    required void Function(T) onSetFalse,
  }) {
    return Column(
      children: requirements.map((requirement) {
        final value = getValue(requirement);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getDisplayName(requirement),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onSetTrue(requirement),
                      child: _optionButton(
                        label: AppLocalizations.of(context)!.commonYes,
                        active: value == true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onSetFalse(requirement),
                      child: _optionButton(
                        label: AppLocalizations.of(context)!.commonNo,
                        active: value == false,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _optionButton({required String label, required bool active}) {
    return SelectionTile(
      label: label,
      selected: active,
      center: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    );
  }
}
