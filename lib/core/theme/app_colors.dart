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

  /// Bittersweet and reseda green darkened for text. The brand tones are
  /// 2.7:1 and 4.5:1 on white — fine for fills and icons, too faint to read.
  /// Reach them through `colorScheme.tertiaryText` / `primaryText`.
  static const Color bittersweetText = Color(0xFFA5483D);
  static const Color resedaGreenText = Color(0xFF5C694C);

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

  /// The four category colors too dark to read on navy, lightened for icons
  /// and labels in dark mode. Map pins keep the fixed colors above in both
  /// modes: they sit on their own white-ringed circle, not on the surface.
  static const Color healthCareOnDark = Color(0xFF829072);
  static const Color mentalHealthOnDark = Color(0xFF9184B7);
  static const Color specializedServicesOnDark = Color(0xFF449995);
  static const Color categoryFallbackOnDark = Color(0xFF7E8E9A);

  // --- Surfaces ------------------------------------------------------------

  static const Color lightBackground = Colors.white;
  static const Color lightSurface = Colors.white;

  /// Dark mode steps up in lightness as surfaces rise — page, card, bar —
  /// because a shadow can't be seen on navy.
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF242444);
  static const Color darkNavBar = Color(0xFF2E2E52);

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

  /// Sign in with Google (light variant): near-black label, hairline border.
  static const Color googleButtonText = Color(0xDD000000);
  static const Color googleButtonBorder = Color(0x1F000000);

  /// Sign in with Google (dark variant), from Google's branding guidelines.
  static const Color googleDarkButton = Color(0xFF131314);
  static const Color googleDarkButtonText = Color(0xFFE3E3E3);
  static const Color googleDarkButtonBorder = Color(0xFF8E918F);
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

  /// The pill behind the active tab's icon.
  static const double navIndicator = 0.16;

  /// A rule between columns of one list, lighter than a section divider.
  static const double subtleDivider = 0.6;

  /// Keyboard-focus wash on rows and tiles that can't carry a ring.
  static const double focus = 0.24;

  /// Dimming behind dialogs and sheets. Navy needs more of it to read as
  /// dimmed at all.
  static const double scrim = 0.4;
  static const double scrimDark = 0.6;
}

extension AppColorTint on Color {
  /// This color at [AppOpacity.tint] — the standard selected/chip background.
  Color get tint => withValues(alpha: AppOpacity.tint);

  /// This color at [AppOpacity.tintStrong].
  Color get tintStrong => withValues(alpha: AppOpacity.tintStrong);

  /// This color at [AppOpacity.tintBorder] — the standard chip outline.
  Color get tintBorder => withValues(alpha: AppOpacity.tintBorder);
}
