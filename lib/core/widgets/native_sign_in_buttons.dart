import 'package:beacon_app/core/services/apple_sign_in_service.dart';
import 'package:beacon_app/core/services/google_sign_in_service.dart';
import 'package:beacon_app/core/services/sign_in_result.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/apple_mark.dart';
import 'package:beacon_app/features/auth/presentation/pages/location_choice_page.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A sign-in provider Beacon offers.
enum NativeSignInProvider { apple, google }

/// Beacon's platform rule: Sign in with Apple and then Sign in with Google on
/// iOS, Google alone on Android, and nothing on platforms the app doesn't
/// ship to. Apple leads on iOS, where it is the privacy-preserving option the
/// App Store asks to see beside any other. Every sign-in surface goes through
/// [NativeSignInButtons], so this is the only place the rule lives.
List<NativeSignInProvider> nativeSignInProvidersFor(
  TargetPlatform platform, {
  bool isWeb = kIsWeb,
}) {
  if (isWeb) return const [];
  return switch (platform) {
    TargetPlatform.iOS => const [
        NativeSignInProvider.apple,
        NativeSignInProvider.google,
      ],
    TargetPlatform.android => const [NativeSignInProvider.google],
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows =>
      const [],
  };
}

/// The platform's sign-in buttons, stacked: "Continue with Apple" and
/// "Continue with Google" on iOS, "Continue with Google" on Android. On
/// success routes to [LocationChoicePage] with the guest's ZIP pre-filled; on
/// cancel or failure it just stops loading and the caller stays put. While
/// one provider is working, every button waits. Renders nothing on platforms
/// with no provider.
class NativeSignInButtons extends StatefulWidget {
  const NativeSignInButtons({
    super.key,
    this.onSuccess,
    this.onFailure,
    this.onLoadingChanged,
    this.expanded = true,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.md),
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

  /// Whether each button takes up the full available width.
  final bool expanded;

  final EdgeInsetsGeometry padding;

  @override
  State<NativeSignInButtons> createState() => _NativeSignInButtonsState();
}

class _NativeSignInButtonsState extends State<NativeSignInButtons> {
  /// The provider whose sign-in is under way, if any.
  NativeSignInProvider? _pending;

  void _setPending(NativeSignInProvider? provider) {
    setState(() => _pending = provider);
    widget.onLoadingChanged?.call(provider != null);
  }

  Future<void> _handleTap(NativeSignInProvider provider) async {
    _setPending(provider);
    final result = switch (provider) {
      NativeSignInProvider.apple => await AppleSignInService.signIn(),
      NativeSignInProvider.google => await GoogleSignInService.signIn(),
    };
    if (!mounted) return;
    _setPending(null);

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

    final l10n = AppLocalizations.of(context);
    final msg = switch (result.outcome) {
          SignInOutcome.noGoogleAccount => l10n?.authNoGoogleAccount,
          SignInOutcome.appleUnavailable => l10n?.authAppleUnavailable,
          _ => result.errorMessage,
        } ??
        l10n?.authSignInError ??
        'Sign-in failed. Please try again.';
    widget.onFailure?.call(msg);
  }

  @override
  Widget build(BuildContext context) {
    final providers = nativeSignInProvidersFor(defaultTargetPlatform);
    if (providers.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, provider) in providers.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _buildButton(context, provider),
        ],
      ],
    );
  }

  /// One provider's button, in its brand's style.
  Widget _buildButton(BuildContext context, NativeSignInProvider provider) {
    final isLoading = _pending == provider;
    final l10n = AppLocalizations.of(context);
    final isApple = provider == NativeSignInProvider.apple;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Brand-mandated colors, not theme colors, in each brand's own light and
    // dark styles. Apple: black with white text, and the reverse on a dark
    // screen, where a black button would vanish. Google: white with a
    // hairline border, or its near-black dark variant.
    final Color background;
    final Color foreground;
    final BorderSide? side;
    if (isApple) {
      background = isDark ? Colors.white : AppColors.appleBlack;
      foreground = isDark ? AppColors.appleBlack : Colors.white;
      side = null;
    } else {
      background = isDark ? AppColors.googleDarkButton : Colors.white;
      foreground =
          isDark ? AppColors.googleDarkButtonText : AppColors.googleButtonText;
      side = BorderSide(
        color: isDark
            ? AppColors.googleDarkButtonBorder
            : AppColors.googleButtonBorder,
      );
    }

    final button = ElevatedButton.icon(
      onPressed: _pending != null ? null : () => _handleTap(provider),
      icon: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(foreground),
              ),
            )
          : isApple
              ? AppleMark(size: AppIconSize.md, color: foreground)
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
        side: side,
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontFamily: isApple
                  ? AppTypography.appleButtonFontFamily
                  : AppTypography.googleButtonFontFamily,
              fontWeight: FontWeight.w500,
            ),
      ),
    );

    if (!widget.expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
