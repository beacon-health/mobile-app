import 'package:flutter/material.dart';

/// Named alpha blends of [ColorScheme] colors, so hint / disabled / overlay
/// opacities stay consistent instead of scattered `withValues` calls.
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
