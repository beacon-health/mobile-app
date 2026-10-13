import 'package:beacon_app/core/theme/app_colors.dart';
import 'package:beacon_app/core/theme/app_radii.dart';
import 'package:beacon_app/core/theme/app_sizes.dart';
import 'package:beacon_app/core/theme/app_spacing.dart';
import 'package:beacon_app/core/theme/app_typography.dart';
import 'package:beacon_app/core/theme/color_scheme_ext.dart';
import 'package:beacon_app/core/theme/focus_ring_border.dart';
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

  /// What `MaterialApp` switches to when the OS asks for more contrast
  /// ("Increase Contrast" on iOS, "High contrast text" on Android): every
  /// outline steps up to the next stronger tone.
  static ThemeData get highContrastLightTheme =>
      _build(_highContrast(_lightScheme));
  static ThemeData get highContrastDarkTheme =>
      _build(_highContrast(_darkScheme));

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
      // Bittersweet is an accent for fills and icons: the tab bar and the
      // Basic needs category. Text that wants it uses `tertiaryText`;
      // destructive actions use `error`.
      tertiary: AppColors.bittersweet,
      onTertiary: Colors.white,
    );
  }

  static ColorScheme _highContrast(ColorScheme scheme) => scheme.copyWith(
        outline: scheme.onSurfaceVariant,
        outlineVariant: scheme.outline,
      );

  static ThemeData _build(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final textTheme = AppTypography.textTheme.apply(
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final cardColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final scaffoldColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final navBarColor = isDark ? AppColors.darkNavBar : AppColors.honeydew;

    const buttonShape = RoundedRectangleBorder(borderRadius: AppRadii.smAll);
    const buttonMinSize = Size(64, AppSizes.minTouchTarget);
    const buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.md,
    );
    // A button that holds keyboard focus draws a ring around itself.
    final focusableShape = WidgetStateProperty.resolveWith<OutlinedBorder>(
      (states) => states.contains(WidgetState.focused)
          ? FocusRingBorder(
              borderRadius: AppRadii.smAll,
              ringColor: scheme.focusRing,
            )
          : buttonShape,
    );

    OutlineInputBorder inputBorder(Color color, [double? width]) =>
        OutlineInputBorder(
          borderRadius: AppRadii.smAll,
          borderSide: BorderSide(color: color, width: width ?? AppSizes.border),
        );

    final navLabel = AppTypography.navLabel.copyWith(
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
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
      // Rows, tiles and chips can't carry a ring, so they wash with it.
      focusColor: scheme.focusRing.withValues(alpha: AppOpacity.focus),
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
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mdAll,
          side: scheme.cardOutline ?? BorderSide.none,
        ),
      ),
      // One input style everywhere: outlined, with a border that clears 3:1
      // against the page and a thicker one on focus.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: inputBorder(scheme.outline),
        enabledBorder: inputBorder(scheme.outline),
        focusedBorder: inputBorder(scheme.primary, AppSizes.borderSelected),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, AppSizes.borderSelected),
        floatingLabelStyle: TextStyle(color: scheme.primaryText),
        helperMaxLines: 3,
        errorMaxLines: 3,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          textStyle: textTheme.labelLarge,
        ).copyWith(shape: focusableShape),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          textStyle: textTheme.labelLarge,
        ).copyWith(shape: focusableShape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primaryText,
          side: BorderSide(color: scheme.primary),
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          textStyle: textTheme.labelLarge,
        ).copyWith(shape: focusableShape),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primaryText,
          minimumSize: buttonMinSize,
          textStyle: textTheme.labelLarge,
        ).copyWith(shape: focusableShape),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSizes.minTouchTarget),
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
        // The checked row of a picker: green that reads as text.
        selectedColor: scheme.primaryText,
        // Trailing values ("Match device", a ZIP, "Ask each time") read as
        // one style.
        leadingAndTrailingTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        barrierColor: scheme.modalScrim,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.xlAll,
          side: scheme.cardOutline ?? BorderSide.none,
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: scheme.modalScrim,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheetTop),
        dragHandleColor: scheme.onSurface.withValues(alpha: 0.2),
        dragHandleSize: const Size(AppSizes.handleWidth, AppSizes.handleHeight),
      ),
      // The active tab is marked three ways, never by color alone: a pill
      // behind a filled icon, and a bolder label.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBarColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.navIndicator,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: AppIconSize.lg,
            color: !states.contains(WidgetState.selected)
                ? scheme.onSurfaceVariant
                // On the dark pill, bittersweet is too close in lightness.
                : (isDark ? scheme.onSecondaryContainer : scheme.tertiaryText),
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? navLabel.copyWith(
                  color: scheme.tertiaryText,
                  fontWeight: AppTypography.navLabelActiveWeight,
                )
              : navLabel.copyWith(color: scheme.onSurfaceVariant),
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

  /// [theme] adjusted for the person reading it, which the static themes
  /// can't know: Chinese gets taller lines, and the OS "Bold Text" setting
  /// steps every weight up. Inter is bundled, so the OS can't embolden it
  /// for us.
  static ThemeData adapted(
    ThemeData theme, {
    required Locale locale,
    required bool boldText,
  }) {
    final isCjk = locale.languageCode == 'zh';
    if (!isCjk && !boldText) return theme;

    TextStyle? adapt(TextStyle? style) {
      if (style == null) return null;
      final height = style.height;
      return style.copyWith(
        fontWeight: boldText ? bolder(style.fontWeight) : null,
        height:
            isCjk && height != null && height < AppTypography.cjkMinLineHeight
                ? AppTypography.cjkMinLineHeight
                : null,
      );
    }

    final text = theme.textTheme;
    return theme.copyWith(
      textTheme: text.copyWith(
        headlineMedium: adapt(text.headlineMedium),
        titleLarge: adapt(text.titleLarge),
        titleMedium: adapt(text.titleMedium),
        titleSmall: adapt(text.titleSmall),
        bodyLarge: adapt(text.bodyLarge),
        bodyMedium: adapt(text.bodyMedium),
        bodySmall: adapt(text.bodySmall),
        labelLarge: adapt(text.labelLarge),
        labelMedium: adapt(text.labelMedium),
        labelSmall: adapt(text.labelSmall),
      ),
    );
  }

  /// The next weight up among the four Inter weights the app bundles.
  static FontWeight? bolder(FontWeight? weight) => switch (weight) {
        null => null,
        FontWeight.w400 || FontWeight.w500 => FontWeight.w600,
        _ => FontWeight.w700,
      };

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

  /// The same, outlined: the quieter of two onboarding choices.
  static ButtonStyle secondaryOutlinedButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.styleFrom(
      foregroundColor: scheme.secondary,
      side: BorderSide(color: scheme.secondary),
    );
  }

  /// Destructive actions: deleting an account, removing a rating.
  static ButtonStyle destructiveTextButton(BuildContext context) =>
      TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
      );

  static ButtonStyle destructiveFilledButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton.styleFrom(
      backgroundColor: scheme.error,
      foregroundColor: scheme.onError,
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
