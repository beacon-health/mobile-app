import 'package:beacon_app/core/services/coverage_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/utils/coverage_text.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Coverage disclaimer, shown wherever "no results" could otherwise read as a
/// broken app: both onboarding location steps and the empty facility list.
/// Names whichever states [CoverageService] reports as live, and disappears
/// once the allow-list is switched off.
class CoverageNotice extends StatelessWidget {
  const CoverageNotice({super.key, this.textAlign = TextAlign.start});

  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final coverage = CoverageService();
    return ListenableBuilder(
      listenable: coverage,
      builder: (context, _) {
        final states = coverage.launchedStates;
        if (coverage.isNationwide || states.isEmpty) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final l10n = AppLocalizations.of(context)!;
        final color = theme.colorScheme.onSurfaceSecondary;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: AppIconSize.sm, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.coverageNotice(localizedStateList(l10n, states)),
                textAlign: textAlign,
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
          ],
        );
      },
    );
  }
}
