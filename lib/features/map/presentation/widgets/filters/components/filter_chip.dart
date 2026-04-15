import 'package:flutter/material.dart';
import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart';

class CustomFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool hasDropdown;
  final VoidCallback onTap;

  const CustomFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.hasDropdown,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FilterDesignTokens.chipPaddingHorizontal,
          vertical: FilterDesignTokens.chipPaddingVertical,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.paynesGray : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.paynesGray : Colors.grey.shade300,
            width: FilterDesignTokens.borderWidthNormal,
          ),
          borderRadius:
              BorderRadius.circular(FilterDesignTokens.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: FilterDesignTokens.shadowOpacity),
              blurRadius: FilterDesignTokens.shadowBlurRadius,
              offset: const Offset(0, FilterDesignTokens.shadowOffsetY),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: FilterDesignTokens.fontSizeSmall,
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: FilterDesignTokens.spacingXSmall),
              Icon(
                Icons.keyboard_arrow_down,
                size: FilterDesignTokens.iconSizeSmall,
                color: isSelected ? Colors.white : Colors.black54,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
