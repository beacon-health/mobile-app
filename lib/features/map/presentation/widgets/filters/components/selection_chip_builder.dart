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
          GestureDetector(
            onTap: () => onToggle(option, !selectedValues.contains(option)),
            child: SelectionTile(
              label: getLabel(option),
              selected: selectedValues.contains(option),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
      ],
    );
  }
}

/// Outlined option that tints with the primary color when [selected]. Shared
/// by the Filter modal's category chips and its Yes / No toggles.
class SelectionTile extends StatelessWidget {
  const SelectionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.padding,
    this.center = false,
  });

  final String label;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final text = Text(
      label,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: selected ? primary : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: selected ? primary.tint : Colors.transparent,
        border: Border.all(
          color: selected ? primary : theme.dividerColor,
          width: selected ? AppSizes.borderSelected : AppSizes.border,
        ),
        borderRadius: AppRadii.smAll,
      ),
      child: center ? Center(child: text) : text,
    );
  }
}
