import 'package:beacon_app/core/theme/app_theme.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height:
          MediaQuery.of(context).size.height * FilterConstants.modalHeightRatio,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(FilterDesignTokens.borderRadiusLarge),
          topRight: Radius.circular(FilterDesignTokens.borderRadiusLarge),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FilterDesignTokens.spacingXLarge,
              vertical: FilterDesignTokens.spacingLarge,
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
                  style: TextStyle(
                    fontSize: FilterDesignTokens.fontSizeXLarge,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
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
              padding: const EdgeInsets.all(FilterDesignTokens.spacingXLarge),
              children: [
                _buildToggleSection(
                  AppLocalizations.of(context)!.filterOpenNow,
                  _tempShowOpenNowOnly,
                  (value) => setState(() => _tempShowOpenNowOnly = value),
                ),
                const SizedBox(height: FilterDesignTokens.spacingLarge),
                _buildToggleSection(
                  AppLocalizations.of(context)!.filterFavorites,
                  _tempShowFavoritesOnly,
                  (value) => setState(() => _tempShowFavoritesOnly = value),
                ),
                const Divider(height: FilterDesignTokens.spacingXXLarge),
                _buildExpandableSection(
                  FilterSection.category,
                  AppLocalizations.of(context)!.filterCategory,
                  _buildCategoryContent(),
                ),
                const Divider(height: FilterDesignTokens.spacingXXLarge),
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
              left: FilterDesignTokens.spacingXLarge,
              right: FilterDesignTokens.spacingXLarge,
              top: FilterDesignTokens.spacingXLarge,
              bottom: FilterDesignTokens.spacingXLarge +
                  MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: FilterDesignTokens.shadowOpacity),
                  blurRadius: FilterDesignTokens.modalShadowBlurRadius,
                  offset:
                      const Offset(0, FilterDesignTokens.modalShadowOffsetY),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: OutlinedButton(
                    onPressed: _clearAll,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: FilterDesignTokens.paddingButton,
                      ),
                      side: const BorderSide(color: AppTheme.resedaGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          FilterDesignTokens.borderRadiusSmall,
                        ),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.filterClearAll,
                      style: const TextStyle(
                        color: AppTheme.resedaGreen,
                        fontSize: FilterDesignTokens.fontSizeNormal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 110,
                  child: ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: FilterDesignTokens.paddingButton,
                      ),
                      backgroundColor: AppTheme.resedaGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          FilterDesignTokens.borderRadiusSmall,
                        ),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.filterApply,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: FilterDesignTokens.fontSizeNormal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
        Text(
          title,
          style: TextStyle(
            fontSize: FilterDesignTokens.fontSizeNormal,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.resedaGreen,
        ),
      ],
    );
  }

  Widget _buildExpandableSection(
    FilterSection section,
    String title,
    Widget content,
  ) {
    final isExpanded = _expandedSection == section;

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
              padding: const EdgeInsets.symmetric(
                vertical: FilterDesignTokens.spacingSmall,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: FilterDesignTokens.fontSizeNormal,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding:
                  const EdgeInsets.only(top: FilterDesignTokens.spacingMedium),
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
          padding:
              const EdgeInsets.only(bottom: FilterDesignTokens.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getDisplayName(requirement),
                style: TextStyle(
                  fontSize: FilterDesignTokens.fontSizeMedium,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: FilterDesignTokens.spacingSmall),
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
                  const SizedBox(width: FilterDesignTokens.spacingSmall),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: FilterDesignTokens.eligibilityOptionPaddingVertical,
      ),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.resedaGreen.withValues(alpha: 0.1)
            : Colors.transparent,
        border: Border.all(
          color: active ? AppTheme.resedaGreen : Theme.of(context).dividerColor,
          width: active
              ? FilterDesignTokens.borderWidthSelected
              : FilterDesignTokens.borderWidthNormal,
        ),
        borderRadius: BorderRadius.circular(
          FilterDesignTokens.borderRadiusSmall,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.resedaGreen : colorScheme.onSurface,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
