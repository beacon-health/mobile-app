import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/components/filter_chip.dart';
import 'package:flutter/material.dart';

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
