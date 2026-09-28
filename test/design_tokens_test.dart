import 'dart:convert';
import 'dart:io';

import 'package:beacon_app/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// `design/tokens.json` and `design/tokens.css` are generated from the Dart
/// tokens so Claude Design (and anyone else off-device) sees exactly what the
/// app ships. This test fails when they drift; regenerate with:
///
///   flutter test test/design_tokens_test.dart --update-goldens
void main() {
  test('design/tokens.json matches lib/core/theme', () {
    final json = '${const JsonEncoder.withIndent('  ').convert(_tokens())}\n';
    _expectOrUpdate('design/tokens.json', json);
  });

  test('design/tokens.css matches lib/core/theme', () {
    _expectOrUpdate('design/tokens.css', _css(_tokens()));
  });
}

void _expectOrUpdate(String path, String generated) {
  final file = File(path);
  if (autoUpdateGoldenFiles) {
    file
      ..createSync(recursive: true)
      ..writeAsStringSync(generated);
    return;
  }
  expect(
    file.existsSync() ? file.readAsStringSync() : '',
    generated,
    reason: '$path is stale. Run: '
        'flutter test test/design_tokens_test.dart --update-goldens',
  );
}

Map<String, Object> _tokens() {
  final light = AppTheme.lightTheme;
  final dark = AppTheme.darkTheme;
  return {
    'meta': {
      'source': 'lib/core/theme/',
      'generatedBy': 'test/design_tokens_test.dart',
      'note': 'Generated file. Edit the Dart tokens, then regenerate.',
    },
    'color': {
      'brand': {
        'resedaGreen': _hex(AppColors.resedaGreen),
        'paynesGray': _hex(AppColors.paynesGray),
        'bittersweet': _hex(AppColors.bittersweet),
        'honeydew': _hex(AppColors.honeydew),
      },
      'category': {
        'healthCare': _hex(AppColors.healthCare),
        'mentalHealth': _hex(AppColors.mentalHealth),
        'basicNeeds': _hex(AppColors.basicNeeds),
        'housingShelter': _hex(AppColors.housingShelter),
        'communityResources': _hex(AppColors.communityResources),
        'specializedServices': _hex(AppColors.specializedServices),
        'fallback': _hex(AppColors.categoryFallback),
      },
      'status': {
        'favorite': _hex(AppColors.favorite),
        'warning': _hex(AppColors.warning),
        'userLocation': _hex(AppColors.userLocation),
      },
      'gradient': {
        'onboardingLight': [
          _hex(AppColors.lightGradientStart),
          _hex(AppColors.lightGradientEnd),
        ],
        'onboardingDark': [
          _hex(AppColors.darkGradientStart),
          _hex(AppColors.darkGradientEnd),
        ],
      },
      'light': _schemeRoles(light),
      'dark': _schemeRoles(dark),
    },
    'opacity': {
      'tint': AppOpacity.tint,
      'tintStrong': AppOpacity.tintStrong,
      'tintBorder': AppOpacity.tintBorder,
      'disabled': AppOpacity.disabled,
      'onSurfaceFaded': 0.5,
      'onSurfaceMuted': 0.6,
      'onSurfaceSecondary': 0.7,
      'onSurfaceStrong': 0.85,
    },
    'spacing': {
      'xxs': _n(AppSpacing.xxs),
      'xs': _n(AppSpacing.xs),
      'sm': _n(AppSpacing.sm),
      'md': _n(AppSpacing.md),
      'lg': _n(AppSpacing.lg),
      'xl': _n(AppSpacing.xl),
      'xxl': _n(AppSpacing.xxl),
      'xxxl': _n(AppSpacing.xxxl),
      'huge': _n(AppSpacing.huge),
      'pageGutter': _n(AppSpacing.pageGutter),
      'onboardingGutter': _n(AppSpacing.onboardingGutter),
      'sheetGutter': _n(AppSpacing.sheetGutter),
    },
    'radius': {
      'sm': _n(AppRadii.sm),
      'md': _n(AppRadii.md),
      'lg': _n(AppRadii.lg),
      'xl': _n(AppRadii.xl),
      'pill': _n(AppRadii.pill),
    },
    'iconSize': {
      'xs': _n(AppIconSize.xs),
      'sm': _n(AppIconSize.sm),
      'md': _n(AppIconSize.md),
      'lg': _n(AppIconSize.lg),
      'xl': _n(AppIconSize.xl),
      'xxl': _n(AppIconSize.xxl),
      'hero': _n(AppIconSize.hero),
    },
    'size': {
      'minTouchTarget': _n(AppSizes.minTouchTarget),
      'avatar': _n(AppSizes.avatar),
      'border': _n(AppSizes.border),
      'borderSelected': _n(AppSizes.borderSelected),
      'handleWidth': _n(AppSizes.handleWidth),
      'handleHeight': _n(AppSizes.handleHeight),
    },
    'shadow': {
      'card': _shadows(AppShadows.card),
      'raised': _shadows(AppShadows.raised),
      'sheet': _shadows(AppShadows.sheet),
    },
    'motion': {
      'fastMs': AppMotion.fast.inMilliseconds,
      'mediumMs': AppMotion.medium.inMilliseconds,
      'curve': 'ease-in-out',
    },
    'typography': {
      'fontFamily': AppTypography.fontFamily,
      'roles': {
        for (final entry in _typeRoles.entries)
          entry.key: _textStyle(entry.value),
      },
      'special': {
        'quickActionLabel': _textStyle(AppTypography.quickActionLabel),
        'zipInput': _textStyle(AppTypography.zipInput),
      },
    },
  };
}

final _typeRoles = <String, TextStyle>{
  'headlineMedium': AppTypography.textTheme.headlineMedium!,
  'titleLarge': AppTypography.textTheme.titleLarge!,
  'titleMedium': AppTypography.textTheme.titleMedium!,
  'titleSmall': AppTypography.textTheme.titleSmall!,
  'bodyLarge': AppTypography.textTheme.bodyLarge!,
  'bodyMedium': AppTypography.textTheme.bodyMedium!,
  'bodySmall': AppTypography.textTheme.bodySmall!,
  'labelLarge': AppTypography.textTheme.labelLarge!,
  'labelMedium': AppTypography.textTheme.labelMedium!,
  'labelSmall': AppTypography.textTheme.labelSmall!,
};

Map<String, String> _schemeRoles(ThemeData theme) {
  final s = theme.colorScheme;
  return {
    'background': _hex(theme.scaffoldBackgroundColor),
    'card': _hex(theme.cardTheme.color!),
    'navBar': _hex(theme.bottomNavigationBarTheme.backgroundColor!),
    'primary': _hex(s.primary),
    'onPrimary': _hex(s.onPrimary),
    'primaryContainer': _hex(s.primaryContainer),
    'onPrimaryContainer': _hex(s.onPrimaryContainer),
    'secondary': _hex(s.secondary),
    'onSecondary': _hex(s.onSecondary),
    'secondaryContainer': _hex(s.secondaryContainer),
    'onSecondaryContainer': _hex(s.onSecondaryContainer),
    'tertiary': _hex(s.tertiary),
    'onTertiary': _hex(s.onTertiary),
    'error': _hex(s.error),
    'onError': _hex(s.onError),
    'surface': _hex(s.surface),
    'onSurface': _hex(s.onSurface),
    'onSurfaceVariant': _hex(s.onSurfaceVariant),
    'surfaceContainerHighest': _hex(s.surfaceContainerHighest),
    'outline': _hex(s.outline),
    'outlineVariant': _hex(s.outlineVariant),
    'inverseSurface': _hex(s.inverseSurface),
    'onInverseSurface': _hex(s.onInverseSurface),
  };
}

Map<String, num> _textStyle(TextStyle style) => {
      'fontSize': _n(style.fontSize!),
      'fontWeight': style.fontWeight!.value,
      if (style.height != null) 'lineHeight': _n(style.height!),
      if (style.letterSpacing != null)
        'letterSpacing': _n(style.letterSpacing!),
    };

List<Map<String, Object>> _shadows(List<BoxShadow> shadows) => [
      for (final s in shadows)
        {
          'color': _hex(s.color),
          'offsetX': _n(s.offset.dx),
          'offsetY': _n(s.offset.dy),
          'blur': _n(s.blurRadius),
        },
    ];

/// `#RRGGBB`, or `#RRGGBBAA` when not opaque (CSS order).
String _hex(Color color) {
  final argb = color.toARGB32();
  final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
  final alpha = argb >>> 24;
  final suffix = alpha == 0xFF ? '' : alpha.toRadixString(16).padLeft(2, '0');
  return '#${rgb.toUpperCase()}${suffix.toUpperCase()}';
}

num _n(double v) => v == v.roundToDouble() ? v.toInt() : v;

String _kebab(String camel) => camel.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => '-${m[0]!.toLowerCase()}',
    );

String _css(Map<String, Object> t) {
  final color = t['color']! as Map<String, Object>;
  final b = StringBuffer()
    ..writeln(
        '/* Generated from lib/core/theme/ by test/design_tokens_test.dart.')
    ..writeln(' * Do not edit; change the Dart tokens and regenerate with:')
    ..writeln(' *   flutter test test/design_tokens_test.dart --update-goldens')
    ..writeln(' */')
    ..writeln();

  for (final (weight, file) in const [
    (400, 'Regular'),
    (500, 'Medium'),
    (600, 'SemiBold'),
    (700, 'Bold'),
  ]) {
    b
      ..writeln('@font-face {')
      ..writeln("  font-family: 'Inter';")
      ..writeln("  src: url('../assets/fonts/inter/Inter-$file.ttf') "
          "format('truetype');")
      ..writeln('  font-weight: $weight;')
      ..writeln('  font-style: normal;')
      ..writeln('  font-display: swap;')
      ..writeln('}');
  }

  void vars(String prefix, Map<String, Object> group, String unit) {
    for (final e in group.entries) {
      b.writeln('  --$prefix-${_kebab(e.key)}: ${e.value}$unit;');
    }
  }

  void schemeVars(Map<String, Object> scheme) {
    for (final e in scheme.entries) {
      b.writeln('  --color-${_kebab(e.key)}: ${e.value};');
    }
  }

  b
    ..writeln()
    ..writeln(':root {')
    ..writeln("  --font-family: 'Inter', system-ui, -apple-system, "
        "'Segoe UI', Roboto, sans-serif;");
  for (final group in ['brand', 'category', 'status']) {
    vars('color-$group', color[group]! as Map<String, Object>, '');
  }
  final gradient = color['gradient']! as Map<String, Object>;
  final gLight = gradient['onboardingLight']! as List;
  b.writeln('  --gradient-onboarding: linear-gradient(180deg, '
      '${gLight[0]}, ${gLight[1]});');
  schemeVars(color['light']! as Map<String, Object>);
  vars('opacity', t['opacity']! as Map<String, Object>, '');
  vars('space', t['spacing']! as Map<String, Object>, 'px');
  vars('radius', t['radius']! as Map<String, Object>, 'px');
  vars('icon', t['iconSize']! as Map<String, Object>, 'px');
  vars('size', t['size']! as Map<String, Object>, 'px');
  final shadows = t['shadow']! as Map<String, Object>;
  for (final e in shadows.entries) {
    final layers = (e.value as List).cast<Map<String, Object>>().map(
          (s) => '${s['offsetX']}px ${s['offsetY']}px ${s['blur']}px '
              '${s['color']}',
        );
    b.writeln('  --shadow-${e.key}: ${layers.join(', ')};');
  }
  final motion = t['motion']! as Map<String, Object>;
  b
    ..writeln('  --motion-fast: ${motion['fastMs']}ms;')
    ..writeln('  --motion-medium: ${motion['mediumMs']}ms;')
    ..writeln('  --motion-curve: ${motion['curve']};')
    ..writeln('}')
    ..writeln();

  // Dark roles apply for the OS preference unless a page pins
  // data-theme="light", and always under data-theme="dark".
  final gDark = gradient['onboardingDark']! as List;
  void darkVars(String indent) {
    for (final e in (color['dark']! as Map<String, Object>).entries) {
      b.writeln('$indent  --color-${_kebab(e.key)}: ${e.value};');
    }
    b.writeln('$indent  --gradient-onboarding: linear-gradient(180deg, '
        '${gDark[0]}, ${gDark[1]});');
  }

  b
    ..writeln('@media (prefers-color-scheme: dark) {')
    ..writeln('  :root:not([data-theme="light"]) {');
  darkVars('  ');
  b
    ..writeln('  }')
    ..writeln('}')
    ..writeln()
    ..writeln(':root[data-theme="dark"] {');
  darkVars('');
  b
    ..writeln('}')
    ..writeln()
    ..writeln('body {')
    ..writeln('  font-family: var(--font-family);')
    ..writeln('  background: var(--color-background);')
    ..writeln('  color: var(--color-on-surface);')
    ..writeln('}');

  final typography = t['typography']! as Map<String, Object>;
  final roles = {
    ...typography['roles']! as Map<String, Object>,
    ...typography['special']! as Map<String, Object>,
  };
  for (final e in roles.entries) {
    final s = e.value as Map<String, num>;
    b
      ..writeln()
      ..writeln('.text-${_kebab(e.key)} {')
      ..writeln('  font-family: var(--font-family);')
      ..writeln('  font-size: ${s['fontSize']}px;')
      ..writeln('  font-weight: ${s['fontWeight']};');
    if (s['lineHeight'] != null) {
      b.writeln('  line-height: ${s['lineHeight']};');
    }
    if (s['letterSpacing'] != null) {
      b.writeln('  letter-spacing: ${s['letterSpacing']}px;');
    }
    b.writeln('}');
  }
  return b.toString();
}
