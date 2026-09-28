import 'package:flutter/animation.dart';

/// Icon sizes. Material's default (24) is [lg].
abstract final class AppIconSize {
  static const double xs = 14;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 28;
  static const double xxl = 40;
  static const double hero = 48;
}

/// Fixed component dimensions shared across screens.
abstract final class AppSizes {
  /// Minimum height for tappable controls — Material's 48dp, which also
  /// clears iOS's 44pt guideline, so both platforms get the same target.
  static const double minTouchTarget = 48;

  /// Square badge / avatar tile (provider badge, choice-card icon).
  static const double avatar = 48;

  /// Outline widths: default, and for a selected option.
  static const double border = 1;
  static const double borderSelected = 2;

  /// Grab handle on sheets and draggable panels.
  static const double handleWidth = 40;
  static const double handleHeight = 4;

  /// Brand logo: Home header (height), location choice and login (width).
  static const double logoCompact = 70;
  static const double logoMedium = 180;
  static const double logoHero = 240;
}

/// Animation durations and curve.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeInOut;
}
