import 'package:beacon_app/core/theme/color_scheme_ext.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Coverage disclaimer, shown wherever "no results" could otherwise read as a
/// broken app: both onboarding location steps and the empty facility list.
class CoverageNotice extends StatelessWidget {
  const CoverageNotice({super.key, this.textAlign = TextAlign.start});

  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.coverageNotice,
            textAlign: textAlign,
            style: TextStyle(fontSize: 13, height: 1.35, color: color),
          ),
        ),
      ],
    );
  }
}
