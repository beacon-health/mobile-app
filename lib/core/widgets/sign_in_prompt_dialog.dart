import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/native_sign_in_button.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Barrier-dismissible modal prompting guests to sign in; "Sign In" pushes
/// [LoginPage] in guest-upgrade mode.
void showSignInPromptDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _SignInPromptDialog(),
  );
}

class _SignInPromptDialog extends StatelessWidget {
  const _SignInPromptDialog();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: colorScheme.onSurfaceMuted,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Icon(
              Icons.lock_outline,
              size: AppIconSize.hero,
              color: colorScheme.secondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l10n.authSignInPromptTitle,
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                l10n.authSignInPromptBody,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceMuted,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Builder(
                builder: (innerContext) => NativeSignInButton(
                  onFailure: (msg) {
                    if (!innerContext.mounted) return;
                    ScaffoldMessenger.of(innerContext).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
