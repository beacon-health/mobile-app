import 'package:flutter/material.dart';

/// Convenience accessors for the alpha blends of [ColorScheme] colors used
/// repeatedly across the UI. Centralising these keeps hint / disabled /
/// overlay opacities consistent instead of scattering `withValues(alpha: …)`
/// calls throughout widget code.
extension ColorSchemeExt on ColorScheme {
  /// Muted text / icon shade for hints and secondary labels (~60% onSurface).
  Color get onSurfaceMuted => onSurface.withValues(alpha: 0.6);

  /// Slightly stronger secondary shade, e.g. body copy (~70% onSurface).
  Color get onSurfaceSecondary => onSurface.withValues(alpha: 0.7);

  /// Faded shade for disabled / locked content (~50% onSurface).
  Color get onSurfaceFaded => onSurface.withValues(alpha: 0.5);

  /// Strong emphasis shade for overlays and tooltips (~85% onSurface).
  Color get onSurfaceStrong => onSurface.withValues(alpha: 0.85);
}
