import 'package:beacon_app/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// Selection-chip rows for the Filter modal. The helpers take a [BuildContext]
/// so chips theme correctly instead of rendering invisibly on dark surfaces.
class SelectionChipBuilder<T> {
  static Widget buildMultiSelection<T>({
    required BuildContext context,
    required List<T> options,
    required Set<T> selectedValues,
    required void Function(T, bool) onToggle,
    required String Function(T) getLabel,
  }) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final option in options)
          SelectionTile(
            label: getLabel(option),
            selected: selectedValues.contains(option),
            onTap: () => onToggle(option, !selectedValues.contains(option)),
          ),
      ],
    );
  }
}

/// Outlined option in the Filter modal's category list. Selected, it tints
/// with the primary color, thickens its outline, and gains a check mark — so
/// the state shows in shape as well as color.
class SelectionTile extends StatelessWidget {
  const SelectionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected ? scheme.primaryText : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.primary.tint : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.smAll,
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outline,
            width: selected ? AppSizes.borderSelected : AppSizes.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    Icon(Icons.check, size: AppIconSize.md, color: foreground),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: foreground,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
