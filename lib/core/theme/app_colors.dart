import 'package:flutter/material.dart';

/// Raw palette. Widgets should prefer the semantic [ColorScheme] roles built
/// from it in `AppTheme` (primary = reseda green, secondary = Payne's gray,
/// tertiary = bittersweet) so light and dark mode each get an accessible tone.
/// Reach for these constants directly only for fixed-meaning colors: the
/// category palette, map markers, and third-party brand marks.
///
/// Mirrored to `design/tokens.json` / `design/tokens.css` for Claude Design;
/// `test/design_tokens_test.dart` fails if the export drifts.
abstract final class AppColors {
  // --- Brand ---------------------------------------------------------------

  static const Color resedaGreen = Color(0xFF6C7C59);
  static const Color paynesGray = Color(0xFF536878);
  static const Color bittersweet = Color(0xFFFE6F5E);
  static const Color honeydew = Color(0xFFF0FFF0);

  // --- Category palette ----------------------------------------------------
  // One per Home quick-action group. These double as marker pins, so they must
  // stay distinguishable at ~20px; paynesGray is reserved for the fallback.

  static const Color healthCare = resedaGreen;
  static const Color mentalHealth = Color(0xFF7A6BA8);
  static const Color basicNeeds = bittersweet;
  static const Color housingShelter = Color(0xFF35A7EE);
  static const Color communityResources = Color(0xFFC9962C);
  static const Color specializedServices = Color(0xFF157F7A);
  static const Color categoryFallback = paynesGray;

  // --- Surfaces ------------------------------------------------------------

  static const Color lightBackground = Colors.white;
  static const Color lightSurface = Colors.white;
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF222240);

  /// Onboarding / login / ZIP entry backdrop, top to bottom.
  static const Color lightGradientStart = Color(0xFFF4F7F5);
  static const Color lightGradientEnd = Color(0xFFDCE6DD);
  static const Color darkGradientStart = darkBackground;
  static const Color darkGradientEnd = Color(0xFF16213E);

  // --- Status --------------------------------------------------------------

  /// Filled heart on favorited facilities.
  static const Color favorite = Color(0xFFF44336);

  /// Non-blocking warnings (e.g. location access denied). Dark enough for
  /// white snack-bar text to stay legible.
  static const Color warning = Color(0xFFB35C00);

  /// "Use my location" control — the platform-standard location blue, so it
  /// matches the blue dot the map SDK draws on both iOS and Android.
  static const Color userLocation = Color(0xFF2196F3);

  // --- Third-party brand marks ---------------------------------------------

  static const Color appleBlack = Colors.black;
  static const Color googleBlue = Color(0xFF4285F4);

  /// Sign in with Google (light variant): near-black label, hairline border.
  static const Color googleButtonText = Color(0xDD000000);
  static const Color googleButtonBorder = Color(0x1F000000);
}

/// Standard alpha levels for tinting a color onto a surface, so selected
/// states, chips, and badges share one look instead of ad-hoc opacities.
abstract final class AppOpacity {
  /// Background wash behind a selected option, chip, or badge.
  static const double tint = 0.12;

  /// Stronger wash for a selected chip or avatar background.
  static const double tintStrong = 0.18;

  /// Hairline border around a tinted chip.
  static const double tintBorder = 0.3;

  /// Disabled foreground (icons, locked controls).
  static const double disabled = 0.38;
}

extension AppColorTint on Color {
  /// This color at [AppOpacity.tint] — the standard selected/chip background.
  Color get tint => withValues(alpha: AppOpacity.tint);

  /// This color at [AppOpacity.tintStrong].
  Color get tintStrong => withValues(alpha: AppOpacity.tintStrong);

  /// This color at [AppOpacity.tintBorder] — the standard chip outline.
  Color get tintBorder => withValues(alpha: AppOpacity.tintBorder);
}
