import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/core/theme/color_scheme_ext.dart';
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
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 8, 24),
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
            const Icon(
              Icons.lock_outline,
              size: 48,
              color: AppTheme.paynesGray,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.authSignInPromptTitle,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.authSignInPromptBody,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceMuted,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
