import 'package:beacon_app/core/theme/app_colors.dart';
import 'package:beacon_app/core/theme/app_radii.dart';
import 'package:beacon_app/core/theme/app_sizes.dart';
import 'package:beacon_app/core/theme/app_spacing.dart';
import 'package:beacon_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Builds the light and dark [ThemeData] from the design tokens.
///
/// Everything Flutter would otherwise pick per platform (font, ink effect,
/// typography base, app-bar title alignment, status-bar icons) is pinned here,
/// so iOS and Android render the same design. Navigation *behavior* — page
/// transitions, back-swipe, scroll physics — deliberately stays native.
abstract final class AppTheme {
  static ThemeData get lightTheme => _build(_lightScheme);
  static ThemeData get darkTheme => _build(_darkScheme);

  /// Light mode uses the brand colors verbatim for the semantic roles.
  static final ColorScheme _lightScheme = _schemeFor(Brightness.light).copyWith(
    primary: AppColors.resedaGreen,
    onPrimary: Colors.white,
    secondary: AppColors.paynesGray,
    onSecondary: Colors.white,
    surface: AppColors.lightSurface,
  );

  /// Dark mode keeps Material's lighter tonal variants of the same hues for
  /// primary / secondary, which stay legible on the navy surfaces.
  static final ColorScheme _darkScheme = _schemeFor(Brightness.dark).copyWith(
    surface: AppColors.darkBackground,
  );

  static ColorScheme _schemeFor(Brightness brightness) {
    final primary = ColorScheme.fromSeed(
      seedColor: AppColors.resedaGreen,
      brightness: brightness,
    );
    // Fidelity keeps Payne's gray's low chroma; the default tonal-spot
    // variant would turn it into a saturated sky blue in dark mode.
    final secondary = ColorScheme.fromSeed(
      seedColor: AppColors.paynesGray,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    return primary.copyWith(
      secondary: secondary.primary,
      onSecondary: secondary.onPrimary,
      secondaryContainer: secondary.primaryContainer,
      onSecondaryContainer: secondary.onPrimaryContainer,
      // Bittersweet is the accent for links, actions, and destructive
      // buttons in both modes.
      tertiary: AppColors.bittersweet,
      onTertiary: Colors.white,
    );
  }

  static ThemeData _build(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final textTheme = AppTypography.textTheme.apply(
      fontFamily: AppTypography.fontFamily,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final cardColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final scaffoldColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    const buttonShape = RoundedRectangleBorder(borderRadius: AppRadii.smAll);
    const buttonMinSize = Size(64, AppSizes.minTouchTarget);
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.md,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      // Pin the typography base: without this iOS starts from the SF-based
      // Cupertino text theme and Android from Roboto's.
      typography: Typography.material2021(
        platform: TargetPlatform.android,
        colorScheme: scheme,
      ),
      textTheme: textTheme,
      // Android defaults to InkSparkle and iOS to InkRipple.
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      scaffoldBackgroundColor: scaffoldColor,
      dividerColor: scheme.outlineVariant,
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      appBarTheme: AppBarTheme(
        // Android left-aligns by default; iOS centers.
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldColor,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: systemOverlayStyleFor(scheme.brightness),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        margin: const EdgeInsets.all(AppSpacing.xs),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: const OutlineInputBorder(borderRadius: AppRadii.smAll),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : scheme.outline,
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: textTheme.labelMedium,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.smAll),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.secondary,
        // Trailing values ("1.0.0", a ZIP, "Ask each time") read as one style.
        leadingAndTrailingTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.xlAll),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheetTop),
        dragHandleColor: scheme.onSurface.withValues(alpha: 0.2),
        dragHandleSize: const Size(AppSizes.handleWidth, AppSizes.handleHeight),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.honeydew,
        selectedItemColor: AppColors.bittersweet,
        unselectedItemColor: scheme.onSurfaceVariant,
        // Same size selected and unselected: no label jump on tab change.
        selectedLabelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
      ),
    );
  }

  /// Payne's-gray filled button for onboarding and auth calls to action,
  /// where a reseda-green button would disappear into the green gradient.
  /// Merges over the theme's `filledButtonTheme`, so shape and size match.
  static ButtonStyle secondaryFilledButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton.styleFrom(
      backgroundColor: scheme.secondary,
      foregroundColor: scheme.onSecondary,
    );
  }

  /// Status- and navigation-bar styling for [brightness], applied app-wide
  /// from `BeaconApp` so pages without an [AppBar] (Home, Map, onboarding)
  /// also follow the in-app theme rather than the OS setting.
  static SystemUiOverlayStyle systemOverlayStyleFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // Android reads the icon brightness, iOS the bar brightness.
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }
}
