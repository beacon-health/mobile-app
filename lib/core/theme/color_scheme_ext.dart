import 'package:beacon_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Named alpha blends of [ColorScheme] colors, so hint / disabled / overlay
/// opacities stay consistent instead of scattered `withValues` calls — and the
/// semantic roles Material has no slot for.
extension ColorSchemeExt on ColorScheme {
  bool get _isDark => brightness == Brightness.dark;

  /// Muted text / icon shade for hints and secondary labels (~60% onSurface).
  Color get onSurfaceMuted => onSurface.withValues(alpha: 0.6);

  /// Slightly stronger secondary shade, e.g. body copy (~70% onSurface).
  Color get onSurfaceSecondary => onSurface.withValues(alpha: 0.7);

  /// Faded shade for disabled / locked content (~50% onSurface).
  Color get onSurfaceFaded => onSurface.withValues(alpha: 0.5);

  /// Strong emphasis shade for overlays and tooltips (~85% onSurface).
  Color get onSurfaceStrong => onSurface.withValues(alpha: 0.85);

  /// Bittersweet as text: inline links and the active tab's label. `tertiary`
  /// itself is for fills and icons.
  Color get tertiaryText =>
      _isDark ? AppColors.bittersweet : AppColors.bittersweetText;

  /// Green as text: text buttons, outlined-button labels, selected options.
  /// `primary` itself is for fills and icons.
  Color get primaryText => _isDark ? primary : AppColors.resedaGreenText;

  /// Background of a facility row and of the facility sheet.
  Color get facilityCard =>
      _isDark ? AppColors.darkSurface : AppColors.honeydew;

  /// The pill behind the active tab's icon.
  Color get navIndicator => _isDark
      ? secondaryContainer
      : AppColors.bittersweet.withValues(alpha: AppOpacity.navIndicator);

  /// Keyboard and switch-access focus ring.
  Color get focusRing => secondary;

  /// Dimming behind dialogs and sheets.
  Color get modalScrim => Colors.black.withValues(
        alpha: _isDark ? AppOpacity.scrimDark : AppOpacity.scrim,
      );

  /// Hairline around cards in dark mode, where shadows don't show. Null in
  /// light mode, which separates cards with the shadow alone.
  BorderSide? get cardOutline =>
      _isDark ? BorderSide(color: outlineVariant) : null;
}
