import 'package:beacon_app/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// Pill in the map's horizontal filter bar. Selected chips fill with the
/// secondary color; locked chips (guest-only features) render disabled with a
/// lock icon.
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final Color iconColor;

    if (isLocked) {
      bgColor = scheme.surfaceContainerHighest;
      borderColor = scheme.outlineVariant;
      textColor = scheme.onSurface.withValues(alpha: AppOpacity.disabled);
      iconColor = textColor;
    } else if (isSelected) {
      bgColor = scheme.secondary;
      borderColor = scheme.secondary;
      textColor = scheme.onSecondary;
      iconColor = scheme.onSecondary;
    } else {
      bgColor = theme.cardTheme.color ?? scheme.surface;
      borderColor = scheme.outlineVariant;
      textColor = scheme.onSurface;
      iconColor = scheme.onSurfaceMuted;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: AppSizes.border),
          borderRadius: AppRadii.mdAll,
          boxShadow: AppShadows.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocked) ...[
              Icon(Icons.lock_outline, size: AppIconSize.sm, color: iconColor),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: textColor,
                fontWeight:
                    isSelected && !isLocked ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (hasDropdown && !isLocked) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.keyboard_arrow_down,
                size: AppIconSize.sm,
                color: iconColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
