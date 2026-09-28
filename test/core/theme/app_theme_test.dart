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
        expect(ios.bottomNavigationBarTheme, android.bottomNavigationBarTheme);
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
