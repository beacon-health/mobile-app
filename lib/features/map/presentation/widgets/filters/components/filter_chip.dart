import 'package:beacon_app/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// Pill in the map's horizontal filter bar. Selected chips fill with the
/// secondary color. A locked chip (something that needs an account) looks
/// like any other and carries a lock: it still does something when tapped —
/// it offers sign-in — so it must not read as disabled.
class CustomFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool hasDropdown;
  final bool isLocked;
  final VoidCallback onTap;

  /// Leading icon, for the chip that opens every filter.
  final IconData? icon;

  /// Fills the chip with the primary container: the one chip that opens a
  /// sheet rather than toggling a filter.
  final bool isProminent;

  const CustomFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.hasDropdown,
    required this.onTap,
    this.isLocked = false,
    this.icon,
    this.isProminent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final Color iconColor;

    if (isProminent) {
      bgColor = scheme.primaryContainer;
      borderColor = scheme.primaryContainer;
      textColor = scheme.onPrimaryContainer;
      iconColor = scheme.onPrimaryContainer;
    } else if (isSelected && !isLocked) {
      bgColor = scheme.secondary;
      borderColor = scheme.secondary;
      textColor = scheme.onSecondary;
      iconColor = scheme.onSecondary;
    } else {
      bgColor = theme.cardTheme.color ?? scheme.surface;
      borderColor = scheme.outline;
      textColor = scheme.onSurface;
      iconColor = scheme.onSurfaceVariant;
    }

    final emphasized = isProminent || (isSelected && !isLocked);
    final leading = isLocked ? Icons.lock_outline : icon;

    return Semantics(
      button: true,
      selected: isLocked || isProminent ? null : isSelected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: AppSizes.border),
          borderRadius: AppRadii.mdAll,
          boxShadow: AppShadows.card,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadii.mdAll,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leading != null) ...[
                      Icon(leading, size: AppIconSize.md, color: iconColor),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: textColor,
                        fontWeight:
                            emphasized ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (hasDropdown && !isLocked) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: AppIconSize.md,
                        color: iconColor,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
