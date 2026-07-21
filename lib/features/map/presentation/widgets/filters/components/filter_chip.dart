import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:flutter/material.dart';

class CustomFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool hasDropdown;
  final bool isLocked;
  final VoidCallback onTap;

  const CustomFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.hasDropdown,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final Color iconColor;

    if (isLocked) {
      bgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
      borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
      textColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
      iconColor = textColor;
    } else if (isSelected) {
      bgColor = const Color(0xFF536878); // AppTheme.paynesGray
      borderColor = const Color(0xFF536878);
      textColor = Colors.white;
      iconColor = Colors.white;
    } else {
      bgColor = isDark ? const Color(0xFF222240) : Colors.white;
      borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
      textColor = isDark ? Colors.white70 : Colors.black87;
      iconColor = isDark ? Colors.white54 : Colors.black54;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FilterDesignTokens.chipPaddingHorizontal,
          vertical: FilterDesignTokens.chipPaddingVertical,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: borderColor,
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
            if (isLocked) ...[
              Icon(
                Icons.lock_outline,
                size: FilterDesignTokens.iconSizeSmall,
                color: iconColor,
              ),
              const SizedBox(width: FilterDesignTokens.spacingXSmall),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight:
                    isSelected && !isLocked ? FontWeight.w600 : FontWeight.w500,
                fontSize: FilterDesignTokens.fontSizeSmall,
              ),
            ),
            if (hasDropdown && !isLocked) ...[
              const SizedBox(width: FilterDesignTokens.spacingXSmall),
              Icon(
                Icons.keyboard_arrow_down,
                size: FilterDesignTokens.iconSizeSmall,
                color: iconColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
