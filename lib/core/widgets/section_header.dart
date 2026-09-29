import 'package:beacon_app/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// Group label above a card of settings-style rows (Profile, Settings).
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});

  final String title;

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
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.secondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
