import 'package:flutter/material.dart';

import 'package:beacon_app/core/theme/app_theme.dart';

/// Shows a centered modal dialog prompting guest users to sign in.
///
/// The dialog is barrier-dismissible: tapping outside or pressing the X
/// button closes it.
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 8, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Icon(
              Icons.lock_outline,
              size: 48,
              color: AppTheme.paynesGray,
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Sign in to use this feature',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Create a free account to unlock Favorites, '
                'Eligibility filters, and more.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
