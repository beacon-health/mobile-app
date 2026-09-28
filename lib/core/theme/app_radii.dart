import 'package:flutter/widgets.dart';

/// Corner-radius scale.
///
/// | Token | Use |
/// |---|---|
/// | [sm] | Buttons, text fields, option toggles, small badges |
/// | [md] | Cards, list containers, chips, quick-action tiles |
/// | [lg] | Large choice cards, dialogs, the Home map preview |
/// | [xl] | Bottom sheets and the map's sliding panels (top corners) |
/// | [pill] | Fully rounded: search bar, floating pills, drag handles |
abstract final class AppRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  /// Top corners only — bottom sheets and panels anchored to the bottom edge.
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}
