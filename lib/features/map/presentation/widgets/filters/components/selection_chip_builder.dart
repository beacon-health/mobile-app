import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:flutter/material.dart';

class SelectionChipBuilder<T> {
  static Widget buildSingleSelection<T>({
    required List<T> options,
    required T selectedValue,
    required Function(T) onSelected,
    required String Function(T) getLabel,
  }) {
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
                color: isSelected ? AppTheme.resedaGreen : Colors.grey.shade300,
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
                color: isSelected ? AppTheme.resedaGreen : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  static Widget buildMultiSelection<T>({
    required List<T> options,
    required Set<T> selectedValues,
    required Function(T, bool) onToggle,
    required String Function(T) getLabel,
  }) {
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
                color: isSelected ? AppTheme.resedaGreen : Colors.grey.shade300,
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
                color: isSelected ? AppTheme.resedaGreen : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
