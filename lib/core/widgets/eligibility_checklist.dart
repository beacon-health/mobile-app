import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// "What can you provide?" — the five things a facility may ask for, as a
/// checklist. A checked box means the person has it. Shared by onboarding and
/// Profile so the two can't word the question differently.
///
/// What a box hides on the map is decided in one place:
/// `FacilityFilterService.eligibilityGates`.
class EligibilityChecklist extends StatelessWidget {
  const EligibilityChecklist({
    super.key,
    required this.value,
    required this.onChanged,
    this.showExamples = false,
  });

  final EligibilityState value;

  /// Null shows the answers but locks them (the filter is switched off).
  final ValueChanged<EligibilityState>? onChanged;

  /// Adds a line under the two documents saying what counts as one.
  final bool showExamples;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = [
      _Row(
        icon: Icons.attach_money,
        title: l10n.eligProofOfIncome,
        example: l10n.eligProofOfIncomeHint,
        checked: value.proofOfIncome,
        apply: (v) => value.copyWith(proofOfIncome: v),
      ),
      _Row(
        icon: Icons.home_outlined,
        title: l10n.eligProofOfResidency,
        example: l10n.eligProofOfResidencyHint,
        checked: value.proofOfResidency,
        apply: (v) => value.copyWith(proofOfResidency: v),
      ),
      _Row(
        icon: Icons.health_and_safety,
        title: l10n.eligInsuranceRequired,
        checked: value.insuranceRequired,
        apply: (v) => value.copyWith(insuranceRequired: v),
      ),
      _Row(
        icon: Icons.badge_outlined,
        title: l10n.eligAcceptsMedicaid,
        checked: value.acceptsMedicaid,
        apply: (v) => value.copyWith(acceptsMedicaid: v),
      ),
      _Row(
        icon: Icons.assignment_ind_outlined,
        title: l10n.eligReferralRequired,
        checked: value.referralRequired,
        apply: (v) => value.copyWith(referralRequired: v),
      ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, row) in rows.indexed) ...[
            if (index > 0) const Divider(height: 1),
            CheckboxListTile(
              secondary: Icon(row.icon),
              title: Text(row.title),
              subtitle: showExamples && row.example != null
                  ? Text(row.example!)
                  : null,
              value: row.checked,
              onChanged: onChanged == null
                  ? null
                  : (checked) => onChanged!(row.apply(checked ?? false)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row {
  const _Row({
    required this.icon,
    required this.title,
    required this.checked,
    required this.apply,
    this.example,
  });

  final IconData icon;
  final String title;
  final String? example;
  final bool checked;
  final EligibilityState Function(bool) apply;
}
