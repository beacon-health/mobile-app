import 'package:beacon_app/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// Group label above a card of settings-style rows (Profile, Settings), with
/// an optional quiet [note] beside it.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.xxl,
        AppSpacing.pageGutter,
        AppSpacing.sm,
      ),
      // Full width, so the note sits at the far edge. Wraps rather than
      // squeezes: at large text sizes the note drops under the title.
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xxs,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (note != null)
              Text(
                note!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
