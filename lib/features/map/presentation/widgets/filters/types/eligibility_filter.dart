import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/components/filter_chip.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class EligibilityFilter extends StatelessWidget {
  final Map<EligibilityRequirement, bool?> selectedRequirements;
  final bool isLocked;
  final VoidCallback onTap;

  const EligibilityFilter({
    super.key,
    required this.selectedRequirements,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters =
        selectedRequirements.values.any((value) => value != null);

    return CustomFilterChip(
      label: AppLocalizations.of(context)!.filterEligibility,
      isSelected: hasActiveFilters,
      hasDropdown: true,
      isLocked: isLocked,
      onTap: onTap,
    );
  }
}
