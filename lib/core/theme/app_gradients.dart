import 'package:flutter/material.dart';

/// Shared gradient backgrounds for the onboarding, ZIP entry, and login
/// screens, so their light/dark palettes stay in sync.
class AppGradients {
  const AppGradients._();

  /// Vertical soft-green (light) / deep-navy (dark) backdrop used behind
  /// onboarding, zip entry, and login.
  static LinearGradient onboarding(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: isDark
          ? const [Color(0xFF1A1A2E), Color(0xFF16213E)]
          : const [Color(0xFFF4F7F5), Color(0xFFDCE6DD)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }
}
