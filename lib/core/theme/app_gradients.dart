import 'package:beacon_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Shared gradient backgrounds for the onboarding, ZIP entry, and login
/// screens, so their light/dark palettes stay in sync.
abstract final class AppGradients {
  /// Vertical soft-green (light) / deep-navy (dark) backdrop used behind
  /// onboarding, zip entry, and login.
  static LinearGradient onboarding(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark
          ? const [AppColors.darkGradientStart, AppColors.darkGradientEnd]
          : const [AppColors.lightGradientStart, AppColors.lightGradientEnd],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }
}
