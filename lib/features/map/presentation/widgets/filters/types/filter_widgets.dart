import 'package:beacon_app/features/map/presentation/widgets/filters/components/filter_chip.dart';
import 'package:flutter/material.dart';

class ToggleFilter extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const ToggleFilter({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomFilterChip(
      label: label,
      isSelected: isActive,
      hasDropdown: false,
      onTap: onTap,
    );
  }
}

class ValueFilter extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const ValueFilter({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomFilterChip(
      label: label,
      isSelected: true,
      hasDropdown: true,
      onTap: onTap,
    );
  }
}
