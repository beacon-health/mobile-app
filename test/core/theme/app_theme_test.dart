import 'dart:io';

import 'package:beacon_app/core/theme/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds [theme] as it would be on [platform] (ThemeData reads
/// defaultTargetPlatform while constructing).
ThemeData _themeOn(TargetPlatform platform, ThemeData Function() theme) {
  debugDefaultTargetPlatformOverride = platform;
  try {
    return theme();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  final builders = {
    'light': () => AppTheme.lightTheme,
    'dark': () => AppTheme.darkTheme,
  };

  for (final MapEntry(key: mode, value: build) in builders.entries) {
    group('$mode theme', () {
      final android = _themeOn(TargetPlatform.android, build);
      final ios = _themeOn(TargetPlatform.iOS, build);

      test('text renders in Inter on every role', () {
        for (final theme in [android, ios]) {
          final styles = [
            theme.textTheme.headlineMedium,
            theme.textTheme.titleLarge,
            theme.textTheme.titleMedium,
            theme.textTheme.titleSmall,
            theme.textTheme.bodyLarge,
            theme.textTheme.bodyMedium,
            theme.textTheme.bodySmall,
            theme.textTheme.labelLarge,
            theme.textTheme.labelMedium,
            theme.textTheme.labelSmall,
          ];
          for (final style in styles) {
            expect(style?.fontFamily, AppTypography.fontFamily);
          }
        }
      });

      test('iOS and Android get the same visual theme', () {
        expect(ios.textTheme, android.textTheme);
        expect(ios.colorScheme, android.colorScheme);
        expect(ios.splashFactory, android.splashFactory);
        expect(ios.visualDensity, android.visualDensity);
        expect(ios.appBarTheme, android.appBarTheme);
        expect(ios.cardTheme, android.cardTheme);
        expect(ios.inputDecorationTheme, android.inputDecorationTheme);
        expect(
          ios.navigationBarTheme.backgroundColor,
          android.navigationBarTheme.backgroundColor,
        );
        expect(
          ios.navigationBarTheme.indicatorColor,
          android.navigationBarTheme.indicatorColor,
        );
        for (final states in const [
          <WidgetState>{},
          {WidgetState.selected},
        ]) {
          expect(
            ios.navigationBarTheme.labelTextStyle!.resolve(states),
            android.navigationBarTheme.labelTextStyle!.resolve(states),
          );
          expect(
            ios.navigationBarTheme.iconTheme!.resolve(states),
            android.navigationBarTheme.iconTheme!.resolve(states),
          );
        }
        expect(ios.dialogTheme, android.dialogTheme);
        expect(ios.bottomSheetTheme, android.bottomSheetTheme);
      });

      test('pins the choices Flutter would otherwise make per platform', () {
        expect(android.splashFactory, InkRipple.splashFactory);
        expect(android.appBarTheme.centerTitle, isTrue);
        expect(android.materialTapTargetSize, MaterialTapTargetSize.padded);
      });
    });
  }

  test('light mode maps the brand colors onto semantic roles', () {
    final scheme = AppTheme.lightTheme.colorScheme;
    expect(scheme.primary, AppColors.resedaGreen);
    expect(scheme.secondary, AppColors.paynesGray);
    expect(scheme.tertiary, AppColors.bittersweet);
  });

  test('dark mode keeps the bittersweet accent and navy surfaces', () {
    final theme = AppTheme.darkTheme;
    expect(theme.colorScheme.tertiary, AppColors.bittersweet);
    expect(theme.scaffoldBackgroundColor, AppColors.darkBackground);
    expect(theme.cardTheme.color, AppColors.darkSurface);
  });

  test('no text style is smaller than 11pt', () {
    final styles = [
      ...[
        AppTypography.textTheme.headlineMedium,
        AppTypography.textTheme.titleLarge,
        AppTypography.textTheme.titleMedium,
        AppTypography.textTheme.titleSmall,
        AppTypography.textTheme.bodyLarge,
        AppTypography.textTheme.bodyMedium,
        AppTypography.textTheme.bodySmall,
        AppTypography.textTheme.labelLarge,
        AppTypography.textTheme.labelMedium,
        AppTypography.textTheme.labelSmall,
      ].nonNulls,
      AppTypography.navLabel,
      AppTypography.zipInput,
    ];
    for (final style in styles) {
      expect(style.fontSize, greaterThanOrEqualTo(11));
    }
  });

  group('high-contrast themes', () {
    test('step every outline up to a stronger tone', () {
      for (final (normal, high) in [
        (AppTheme.lightTheme, AppTheme.highContrastLightTheme),
        (AppTheme.darkTheme, AppTheme.highContrastDarkTheme),
      ]) {
        expect(high.colorScheme.outline, normal.colorScheme.onSurfaceVariant);
        expect(high.colorScheme.outlineVariant, normal.colorScheme.outline);
        expect(high.dividerColor, normal.colorScheme.outline);
        expect(high.colorScheme.brightness, normal.colorScheme.brightness);
      }
    });
  });

  group('AppTheme.adapted', () {
    final base = AppTheme.lightTheme;

    test('leaves the theme alone for English at ordinary weight', () {
      expect(
        AppTheme.adapted(base, locale: const Locale('en'), boldText: false),
        same(base),
      );
    });

    test('Bold Text steps every weight up', () {
      final bold = AppTheme.adapted(
        base,
        locale: const Locale('en'),
        boldText: true,
      ).textTheme;
      expect(bold.bodyMedium!.fontWeight, FontWeight.w600);
      expect(bold.labelMedium!.fontWeight, FontWeight.w600);
      expect(bold.titleMedium!.fontWeight, FontWeight.w700);
      expect(bold.headlineMedium!.fontWeight, FontWeight.w700);
      // Only the weight: sizes and colors are untouched.
      expect(bold.bodyMedium!.fontSize, base.textTheme.bodyMedium!.fontSize);
      expect(bold.bodyMedium!.color, base.textTheme.bodyMedium!.color);
    });

    test('Chinese gets taller lines, never shorter ones', () {
      final zh = AppTheme.adapted(
        base,
        locale: const Locale('zh'),
        boldText: false,
      ).textTheme;
      for (final style in [zh.titleLarge, zh.bodyMedium, zh.labelSmall]) {
        expect(
          style!.height,
          greaterThanOrEqualTo(AppTypography.cjkMinLineHeight),
        );
      }
      expect(zh.bodyLarge!.height, base.textTheme.bodyLarge!.height);
      expect(zh.bodyMedium!.fontWeight, base.textTheme.bodyMedium!.fontWeight);
    });

    test('names a Chinese font to fall back to', () {
      expect(base.textTheme.bodyMedium!.fontFamilyFallback, isNotEmpty);
      expect(
        base.textTheme.bodyMedium!.fontFamilyFallback,
        AppTypography.fontFamilyFallback,
      );
    });
  });

  group('focus ring', () {
    OutlinedBorder shapeOf(ButtonStyle style, Set<WidgetState> states) =>
        style.shape!.resolve(states)!;

    test('every button draws a ring while it holds keyboard focus', () {
      final theme = AppTheme.lightTheme;
      for (final style in [
        theme.filledButtonTheme.style!,
        theme.elevatedButtonTheme.style!,
        theme.outlinedButtonTheme.style!,
        theme.textButtonTheme.style!,
      ]) {
        final focused = shapeOf(style, {WidgetState.focused});
        expect(focused, isA<FocusRingBorder>());
        expect(
          (focused as FocusRingBorder).ringColor,
          theme.colorScheme.focusRing,
        );
        expect(shapeOf(style, {}), isNot(isA<FocusRingBorder>()));
      }
    });

    test('the ring survives the button applying its own outline', () {
      const ring = FocusRingBorder(
        ringColor: Color(0xFF536878),
        borderRadius: AppRadii.smAll,
      );
      final withSide = ring.copyWith(side: const BorderSide(width: 2));
      expect(withSide, isA<FocusRingBorder>());
      expect(withSide.ringColor, ring.ringColor);
      expect(withSide.side.width, 2);
      expect(ring, isNot(ring.copyWith(side: const BorderSide())));
    });
  });

  test('system bar icons contrast with the in-app theme', () {
    final light = AppTheme.systemOverlayStyleFor(Brightness.light);
    final dark = AppTheme.systemOverlayStyleFor(Brightness.dark);
    // Android reads *IconBrightness; iOS reads statusBarBrightness.
    expect(light.statusBarIconBrightness, Brightness.dark);
    expect(light.statusBarBrightness, Brightness.light);
    expect(dark.statusBarIconBrightness, Brightness.light);
    expect(dark.statusBarBrightness, Brightness.dark);
    expect(dark.systemNavigationBarIconBrightness, Brightness.light);
    // Explicit nav-bar fields, so Android doesn't pick its own scrim.
    expect(light.statusBarColor, const Color(0x00000000));
    expect(light.systemNavigationBarColor, const Color(0x00000000));
    expect(light.systemNavigationBarContrastEnforced, isFalse);
  });

  test('every Inter weight the type scale uses is bundled', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final (weight, file) in const [
      (400, 'Regular'),
      (500, 'Medium'),
      (600, 'SemiBold'),
      (700, 'Bold'),
    ]) {
      final path = 'assets/fonts/inter/Inter-$file.ttf';
      expect(File(path).existsSync(), isTrue, reason: '$path is missing');
      expect(
        pubspec,
        contains('asset: $path\n          weight: $weight'),
        reason: '$path is not declared in pubspec.yaml',
      );
    }
    expect(File('assets/fonts/inter/OFL.txt').existsSync(), isTrue);
  });
}
