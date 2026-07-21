import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:flutter/material.dart';

/// Builds the selection-chip rows used inside the Filter modal.
///
/// Always builds via the static helpers below — they accept a [BuildContext]
/// so chip text and borders can pick up the active theme (avoids hardcoded
/// `Colors.black87` rendering invisibly on a dark surface).
class SelectionChipBuilder<T> {
  static Widget buildSingleSelection<T>({
    required BuildContext context,
    required List<T> options,
    required T selectedValue,
    required void Function(T) onSelected,
    required String Function(T) getLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: FilterDesignTokens.spacingSmall,
      runSpacing: FilterDesignTokens.spacingSmall,
      children: options.map((option) {
        final isSelected = selectedValue == option;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FilterDesignTokens.selectionChipPaddingHorizontal,
              vertical: FilterDesignTokens.selectionChipPaddingVertical,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.resedaGreen.withValues(alpha: 0.1)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? AppTheme.resedaGreen
                    : Theme.of(context).dividerColor,
                width: isSelected
                    ? FilterDesignTokens.borderWidthSelected
                    : FilterDesignTokens.borderWidthNormal,
              ),
              borderRadius:
                  BorderRadius.circular(FilterDesignTokens.borderRadiusSmall),
            ),
            child: Text(
              getLabel(option),
              style: TextStyle(
                color:
                    isSelected ? AppTheme.resedaGreen : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  static Widget buildMultiSelection<T>({
    required BuildContext context,
    required List<T> options,
    required Set<T> selectedValues,
    required void Function(T, bool) onToggle,
    required String Function(T) getLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: FilterDesignTokens.spacingSmall,
      runSpacing: FilterDesignTokens.spacingSmall,
      children: options.map((option) {
        final isSelected = selectedValues.contains(option);
        return GestureDetector(
          onTap: () => onToggle(option, !isSelected),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: FilterDesignTokens.selectionChipPaddingHorizontal,
              vertical: FilterDesignTokens.selectionChipPaddingVertical,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.resedaGreen.withValues(alpha: 0.1)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? AppTheme.resedaGreen
                    : Theme.of(context).dividerColor,
                width: isSelected
                    ? FilterDesignTokens.borderWidthSelected
                    : FilterDesignTokens.borderWidthNormal,
              ),
              borderRadius:
                  BorderRadius.circular(FilterDesignTokens.borderRadiusSmall),
            ),
            child: Text(
              getLabel(option),
              style: TextStyle(
                color:
                    isSelected ? AppTheme.resedaGreen : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
