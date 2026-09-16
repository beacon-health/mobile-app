import 'package:beacon_app/core/services/apple_sign_in_service.dart';
import 'package:beacon_app/core/services/google_sign_in_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/features/auth/presentation/pages/location_choice_page.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The single sign-in provider Beacon offers on a platform.
enum NativeSignInProvider { apple, google }

/// Beacon's platform rule: Sign in with Apple on iOS, Sign in with Google on
/// Android, and nothing on platforms the app doesn't ship to. Every sign-in
/// surface goes through [NativeSignInButton], so this is the only place the
/// rule lives.
NativeSignInProvider? nativeSignInProviderFor(
  TargetPlatform platform, {
  bool isWeb = kIsWeb,
}) {
  if (isWeb) return null;
  return switch (platform) {
    TargetPlatform.iOS => NativeSignInProvider.apple,
    TargetPlatform.android => NativeSignInProvider.google,
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows =>
      null,
  };
}

/// "Continue with Apple" on iOS, "Continue with Google" on Android. On success
/// routes to [LocationChoicePage] with the guest's ZIP pre-filled; on cancel
/// or failure it just stops loading and the caller stays put. Renders nothing
/// on platforms with no provider.
class NativeSignInButton extends StatefulWidget {
  const NativeSignInButton({
    super.key,
    this.onSuccess,
    this.onFailure,
    this.onLoadingChanged,
    this.expanded = true,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  /// Optional hook fired after a successful sign-in. Default behavior is to
  /// push [LocationChoicePage]; provide this to override (e.g. to also pop a
  /// hosting dialog first).
  final VoidCallback? onSuccess;

  /// Optional hook fired when sign-in fails (excluding cancellation, which is
  /// silent). Useful for showing a snackbar in the host screen.
  final void Function(String message)? onFailure;

  /// Optional hook fired when a sign-in attempt starts and finishes, so a host
  /// screen can disable its other actions meanwhile.
  final ValueChanged<bool>? onLoadingChanged;

  /// Whether to take up the full available width.
  final bool expanded;

  final EdgeInsetsGeometry padding;

  @override
  State<NativeSignInButton> createState() => _NativeSignInButtonState();
}

class _NativeSignInButtonState extends State<NativeSignInButton> {
  bool _isLoading = false;

  void _setLoading(bool value) {
    setState(() => _isLoading = value);
    widget.onLoadingChanged?.call(value);
  }

  Future<void> _handleTap(NativeSignInProvider provider) async {
    _setLoading(true);
    final result = switch (provider) {
      NativeSignInProvider.apple => await AppleSignInService.signIn(),
      NativeSignInProvider.google => await GoogleSignInService.signIn(),
    };
    if (!mounted) return;
    _setLoading(false);

    if (result.isSuccess) {
      if (widget.onSuccess != null) {
        widget.onSuccess!.call();
        return;
      }
      // Default: restart onboarding from the location preference page,
      // pre-filling the guest's last-entered ZIP if we have one.
      final prefilledZip =
          ZipCodeService().previousZipCode ?? ZipCodeService().zipCode;
      await Navigator.of(context).pushAndRemoveUntil(
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
    final provider = nativeSignInProviderFor(defaultTargetPlatform);
    if (provider == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final isApple = provider == NativeSignInProvider.apple;
    final background = isApple ? Colors.black : Colors.white;
    final foreground = isApple ? Colors.white : Colors.black87;

    final button = ElevatedButton.icon(
      onPressed: _isLoading ? null : () => _handleTap(provider),
      icon: _isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(foreground),
              ),
            )
          : isApple
              ? const Icon(Icons.apple, size: 22)
              // Google's branding guidelines require their own "G" mark on a
              // Sign in with Google button; Material's `g_mobiledata` glyph is
              // a different letterform and not licensed for this use.
              : Image.asset('assets/google-g-logo.png', height: 18),
      label: Text(
        isApple
            ? l10n?.authContinueWithApple ?? 'Continue with Apple'
            : l10n?.authContinueWithGoogle ?? 'Continue with Google',
      ),
      style: ElevatedButton.styleFrom(
        padding: widget.padding,
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: 0.7),
        disabledForegroundColor: foreground,
        side: isApple ? null : const BorderSide(color: Colors.black12),
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
