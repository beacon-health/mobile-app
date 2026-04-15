import 'package:flutter/material.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart';
import '../components/filter_chip.dart';

class EligibilityFilter extends StatelessWidget {
  final Map<EligibilityRequirement, bool?> selectedRequirements;
  final VoidCallback onTap;

  const EligibilityFilter({
    super.key,
    required this.selectedRequirements,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters =
        selectedRequirements.values.any((value) => value != null);

    return CustomFilterChip(
      label: 'Eligibility',
      isSelected: hasActiveFilters,
      hasDropdown: true,
      onTap: onTap,
    );
  }
}
