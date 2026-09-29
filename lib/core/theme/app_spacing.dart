/// Spacing scale for padding, margins, and gaps. Every inset and gap in the
/// app should land on one of these steps; `test/design_system_lint_test.dart`
/// rejects numeric literals in `EdgeInsets` and gap-only `SizedBox`es.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Horizontal gutter for tabbed pages, cards, and lists.
  static const double pageGutter = lg;

  /// Horizontal gutter for full-bleed onboarding / auth screens.
  static const double onboardingGutter = xxl;

  /// Horizontal inset inside bottom sheets and modals.
  static const double sheetGutter = xl;
}
