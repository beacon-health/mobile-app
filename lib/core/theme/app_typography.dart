import 'package:flutter/material.dart';

/// Type scale. Inter is bundled (see `pubspec.yaml`) so iOS and Android render
/// the same letterforms — without it iOS falls back to SF Pro and Android to
/// Roboto. Chinese text still falls back to the platform's CJK font.
///
/// Style text through `Theme.of(context).textTheme.<role>` and `copyWith` only
/// the color (or, sparingly, the weight). Raw `fontSize:` literals outside
/// `lib/core/theme/` fail `test/design_system_lint_test.dart`.
///
/// | Role | Size / weight | Use |
/// |---|---|---|
/// | headlineMedium | 26 / 700 | Onboarding screen titles |
/// | titleLarge | 20 / 600 | Page section headings, app bar, dialog titles |
/// | titleMedium | 16 / 600 | Card section titles, empty-state titles |
/// | titleSmall | 14 / 600 | List-row titles, uppercase-style group headers |
/// | bodyLarge | 16 / 400 | Inputs, list-tile titles, lead paragraphs |
/// | bodyMedium | 14 / 400 | Default body text |
/// | bodySmall | 12 / 400 | Captions, addresses, helper text |
/// | labelLarge | 16 / 600 | Buttons |
/// | labelMedium | 13 / 500 | Inline links and actions, chip labels |
/// | labelSmall | 11 / 600 | Badges, status pills, dense chips, hours |
abstract final class AppTypography {
  static const String fontFamily = 'Inter';

  static const TextTheme textTheme = TextTheme(
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.23,
      letterSpacing: -0.2,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.375,
      letterSpacing: 0,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0,
    ),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.23,
      letterSpacing: 0,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.27,
      letterSpacing: 0.1,
    ),
  );

  /// The only sub-11pt text in the app: Home quick-action tile labels, which
  /// must fit two lines inside a ~58pt-wide tile on the smallest phone.
  static const TextStyle quickActionLabel = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w600,
    height: 1.15,
  );

  /// Letter-spaced input text for the 5-digit ZIP fields.
  static const TextStyle zipInput = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: 4,
  );

  /// System font for the Sign in with Apple button — Apple's guidelines
  /// require the platform font there, so it deliberately opts out of Inter.
  static const String appleButtonFontFamily = 'CupertinoSystemText';

  /// Roboto for the Sign in with Google button, per Google's branding rules.
  static const String googleButtonFontFamily = 'Roboto';
}
