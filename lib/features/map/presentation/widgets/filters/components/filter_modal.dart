import 'package:flutter/material.dart';
import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:beacon_app/features/map/utils/facility_display_utils.dart';
import 'selection_chip_builder.dart';

enum FilterSection {
  distance,
  category,
  eligibility,
}

class FilterModal extends StatefulWidget {
  final double selectedDistance;
  final Set<String> selectedCategories;
  final List<String> availableCategories;
  final Map<EligibilityRequirement, bool?> selectedEligibilityRequirements;
  final bool showFavoritesOnly;
  final bool showOpenNowOnly;
  final FilterSection? expandedSection;

  const FilterModal({
    Key? key,
    required this.selectedDistance,
    required this.selectedCategories,
    required this.availableCategories,
    required this.selectedEligibilityRequirements,
    required this.showFavoritesOnly,
    required this.showOpenNowOnly,
    this.expandedSection,
  }) : super(key: key);

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late double _tempDistance;
  late Set<String> _tempCategories;
  late Map<EligibilityRequirement, bool?> _tempEligibilityRequirements;
  late bool _tempShowFavoritesOnly;
  late bool _tempShowOpenNowOnly;

  FilterSection? _expandedSection;
  final ScrollController _scrollController = ScrollController();
  final Map<FilterSection, GlobalKey> _sectionKeys = {
    FilterSection.distance: GlobalKey(),
    FilterSection.category: GlobalKey(),
    FilterSection.eligibility: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _tempDistance = widget.selectedDistance;
    _tempCategories = Set.from(widget.selectedCategories);
    _tempEligibilityRequirements =
        Map.from(widget.selectedEligibilityRequirements);
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
      'distance': MapConstants.distanceOptions.first,
      'categories': <String>{},
      'eligibilityRequirements': <EligibilityRequirement, bool?>{},
      'showFavoritesOnly': false,
      'showOpenNowOnly': false,
    });
  }

  void _apply() {
    Navigator.pop(context, {
      'distance': _tempDistance,
      'categories': _tempCategories,
      'eligibilityRequirements': _tempEligibilityRequirements,
      'showFavoritesOnly': _tempShowFavoritesOnly,
      'showOpenNowOnly': _tempShowOpenNowOnly,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height * FilterConstants.modalHeightRatio,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
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
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: FilterDesignTokens.fontSizeXLarge,
                    fontWeight: FontWeight.w600,
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
                  'Open Now',
                  _tempShowOpenNowOnly,
                  (value) => setState(() => _tempShowOpenNowOnly = value),
                ),
                const SizedBox(height: FilterDesignTokens.spacingLarge),
                _buildToggleSection(
                  'Favorites',
                  _tempShowFavoritesOnly,
                  (value) => setState(() => _tempShowFavoritesOnly = value),
                ),
                const Divider(height: FilterDesignTokens.spacingXXLarge),
                _buildExpandableSection(
                  FilterSection.distance,
                  'Distance',
                  _buildDistanceContent(),
                ),
                const Divider(height: FilterDesignTokens.spacingXXLarge),
                _buildExpandableSection(
                  FilterSection.category,
                  'Category',
                  _buildCategoryContent(),
                ),
                const Divider(height: FilterDesignTokens.spacingXXLarge),
                _buildExpandableSection(
                  FilterSection.eligibility,
                  'Eligibility',
                  _buildEligibilityContent(),
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
              color: Colors.white,
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
                          vertical: FilterDesignTokens.paddingButton),
                      side: BorderSide(color: AppTheme.resedaGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            FilterDesignTokens.borderRadiusSmall),
                      ),
                    ),
                    child: const Text(
                      'Clear all',
                      style: TextStyle(
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
                          vertical: FilterDesignTokens.paddingButton),
                      backgroundColor: AppTheme.resedaGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            FilterDesignTokens.borderRadiusSmall),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
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
      String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: FilterDesignTokens.fontSizeNormal,
            fontWeight: FontWeight.w500,
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
      FilterSection section, String title, Widget content) {
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
                  vertical: FilterDesignTokens.spacingSmall),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: FilterDesignTokens.fontSizeNormal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
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

  Widget _buildDistanceContent() {
    return SelectionChipBuilder.buildSingleSelection<double>(
      options: MapConstants.distanceOptions,
      selectedValue: _tempDistance,
      onSelected: (distance) => setState(() => _tempDistance = distance),
      getLabel: (distance) => '${distance.toStringAsFixed(
        distance == distance.roundToDouble() ? 0 : 1,
      )} mi',
    );
  }

  Widget _buildCategoryContent() {
    return SelectionChipBuilder.buildMultiSelection<String>(
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
      getLabel: (category) =>
          FacilityCategoryIcons.getCategoryDisplayName(category),
    );
  }

  Widget _buildEligibilityContent() {
    for (final requirement in FilterConstants.eligibilityRequirements) {
      _tempEligibilityRequirements.putIfAbsent(requirement, () => null);
    }

    return Column(
      children: FilterConstants.eligibilityRequirements.map((requirement) {
        return Padding(
          padding:
              const EdgeInsets.only(bottom: FilterDesignTokens.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                requirement.displayName,
                style: const TextStyle(
                  fontSize: FilterDesignTokens.fontSizeMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: FilterDesignTokens.spacingSmall),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_tempEligibilityRequirements[requirement] ==
                              true) {
                            _tempEligibilityRequirements[requirement] = null;
                          } else {
                            _tempEligibilityRequirements[requirement] = true;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: FilterDesignTokens
                                .eligibilityOptionPaddingVertical),
                        decoration: BoxDecoration(
                          color:
                              _tempEligibilityRequirements[requirement] == true
                                  ? AppTheme.resedaGreen.withValues(alpha: 0.1)
                                  : Colors.transparent,
                          border: Border.all(
                            color: _tempEligibilityRequirements[requirement] ==
                                    true
                                ? AppTheme.resedaGreen
                                : Colors.grey.shade300,
                            width: _tempEligibilityRequirements[requirement] ==
                                    true
                                ? FilterDesignTokens.borderWidthSelected
                                : FilterDesignTokens.borderWidthNormal,
                          ),
                          borderRadius: BorderRadius.circular(
                              FilterDesignTokens.borderRadiusSmall),
                        ),
                        child: Center(
                          child: Text(
                            'Yes',
                            style: TextStyle(
                              color:
                                  _tempEligibilityRequirements[requirement] ==
                                          true
                                      ? AppTheme.resedaGreen
                                      : Colors.black87,
                              fontWeight:
                                  _tempEligibilityRequirements[requirement] ==
                                          true
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: FilterDesignTokens.spacingSmall),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_tempEligibilityRequirements[requirement] ==
                              false) {
                            _tempEligibilityRequirements[requirement] = null;
                          } else {
                            _tempEligibilityRequirements[requirement] = false;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: FilterDesignTokens
                                .eligibilityOptionPaddingVertical),
                        decoration: BoxDecoration(
                          color:
                              _tempEligibilityRequirements[requirement] == false
                                  ? AppTheme.resedaGreen.withValues(alpha: 0.1)
                                  : Colors.transparent,
                          border: Border.all(
                            color: _tempEligibilityRequirements[requirement] ==
                                    false
                                ? AppTheme.resedaGreen
                                : Colors.grey.shade300,
                            width: _tempEligibilityRequirements[requirement] ==
                                    false
                                ? FilterDesignTokens.borderWidthSelected
                                : FilterDesignTokens.borderWidthNormal,
                          ),
                          borderRadius: BorderRadius.circular(
                              FilterDesignTokens.borderRadiusSmall),
                        ),
                        child: Center(
                          child: Text(
                            'No',
                            style: TextStyle(
                              color:
                                  _tempEligibilityRequirements[requirement] ==
                                          false
                                      ? AppTheme.resedaGreen
                                      : Colors.black87,
                              fontWeight:
                                  _tempEligibilityRequirements[requirement] ==
                                          false
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
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
}
