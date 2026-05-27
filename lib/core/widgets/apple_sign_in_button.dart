import 'package:beacon_app/core/services/apple_sign_in_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/features/auth/presentation/pages/location_choice_page.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Reusable "Continue with Apple" button used by in-app sign-in CTAs
/// (Settings Account row, locked overlays, locked-favorites card, sign-in
/// prompt dialog).
///
/// Tapping it triggers the native Apple flow. On success, the user is sent
/// to [LocationChoicePage] with their previously-entered ZIP pre-filled so
/// they "restart onboarding from the location preference page". On cancel or
/// failure, the button just stops loading — the caller stays in place.
class AppleSignInButton extends StatefulWidget {
  const AppleSignInButton({
    super.key,
    this.onSuccess,
    this.onFailure,
    this.expanded = true,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  /// Optional hook fired after a successful sign-in. Default behavior is to
  /// push [LocationChoicePage]; provide this to override (e.g. to also pop a
  /// hosting dialog first).
  final VoidCallback? onSuccess;

  /// Optional hook fired when Apple sign-in fails (excluding cancellation,
  /// which is silent). Useful for showing a snackbar in the host screen.
  final void Function(String message)? onFailure;

  /// Whether to take up the full available width.
  final bool expanded;

  final EdgeInsetsGeometry padding;

  @override
  State<AppleSignInButton> createState() => _AppleSignInButtonState();
}

class _AppleSignInButtonState extends State<AppleSignInButton> {
  bool _isLoading = false;

  Future<void> _handleTap() async {
    setState(() => _isLoading = true);
    final result = await AppleSignInService.signIn();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      if (widget.onSuccess != null) {
        widget.onSuccess!.call();
        return;
      }
      // Default: restart onboarding from the location preference page,
      // pre-filling the guest's last-entered ZIP if we have one.
      final prefilledZip = ZipCodeService().previousZipCode ??
          ZipCodeService().zipCode;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => LocationChoicePage(prefilledZip: prefilledZip),
        ),
        (route) => false,
      );
      return;
    }

    if (result.isCancelled) return;

    final msg = result.errorMessage ??
        AppLocalizations.of(context)?.authSignInError ??
            'Sign-in failed. Please try again.';
    widget.onFailure?.call(msg);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final button = ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleTap,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.apple, size: 22),
      label: Text(l10n?.authContinueWithApple ?? 'Continue with Apple'),
      style: ElevatedButton.styleFrom(
        padding: widget.padding,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.black.withValues(alpha: 0.7),
        disabledForegroundColor: Colors.white,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
    );

    if (!widget.expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
