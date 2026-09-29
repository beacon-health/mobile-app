import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps styling on the design tokens in `lib/core/theme/`. Each rule names
/// the token to use instead; the token files themselves are exempt.
void main() {
  const exemptDirs = ['lib/core/theme/', 'lib/l10n/'];

  // A number literal other than 0 / 0.0, not part of an identifier.
  const nonZeroNumber = r'(?<![\w.])(?:[1-9]\d*(?:\.\d+)?|0\.\d*[1-9]\d*)';

  final rules = <_Rule>[
    _Rule(
      'hex color',
      RegExp(r'Color\(0x'),
      'Use AppColors or a ColorScheme role.',
    ),
    _Rule(
      'Material palette color',
      RegExp(r'(?<!\w)Colors\.(?!white\b|black\b|transparent\b)\w+'),
      'Use AppColors or a ColorScheme role (only white / black / '
          'transparent are allowed).',
    ),
    _Rule(
      'literal font size',
      RegExp(r'fontSize:\s*' + nonZeroNumber),
      'Use a Theme.of(context).textTheme role or an AppTypography style.',
    ),
    _Rule(
      'literal corner radius',
      RegExp(r'Radius\.circular\(\s*' + nonZeroNumber),
      'Use AppRadii.',
    ),
    _Rule(
      'ad-hoc shadow',
      RegExp(r'\bBoxShadow\('),
      'Use AppShadows.card / raised / sheet.',
    ),
    _Rule(
      'literal padding',
      RegExp(r'EdgeInsets\.\w+\(([^()]*)\)', dotAll: true),
      'Use AppSpacing.',
      argPattern: RegExp(nonZeroNumber),
    ),
    _Rule(
      'literal gap',
      RegExp(
          r'SizedBox\(\s*(?:height|width):\s*' + nonZeroNumber + r'\s*,?\s*\)'),
      'Use SizedBox(height: AppSpacing.x).',
    ),
    _Rule(
      'literal alpha',
      RegExp(r'withValues\(\s*alpha:\s*' + nonZeroNumber),
      'Use AppOpacity, the .tint / .tintStrong / .tintBorder extensions, '
          'or a ColorSchemeExt shade.',
    ),
  ];

  // Canvas-painted map markers render at bitmap scale, not in the widget
  // tree, so their paint alphas stay local to the painter.
  const allowed = {
    'literal alpha': {
      'lib/features/map/presentation/widgets/markers/marker_icon_factory.dart',
      // Brand buttons dim by a fixed amount while a sign-in is in flight.
      'lib/core/widgets/native_sign_in_button.dart',
    },
  };

  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !exemptDirs.any(f.path.startsWith))
      .toList();

  for (final rule in rules) {
    test('no ${rule.name} outside lib/core/theme', () {
      final violations = <String>[];
      for (final file in files) {
        if (allowed[rule.name]?.contains(file.path) ?? false) continue;
        final source = _stripComments(file.readAsStringSync());
        for (final match in rule.pattern.allMatches(source)) {
          final args = rule.argPattern == null ? null : match.group(1);
          if (args != null && !rule.argPattern!.hasMatch(args)) continue;
          final line = '\n'.allMatches(source.substring(0, match.start)).length;
          final snippet = match.group(0)!.replaceAll(RegExp(r'\s+'), ' ');
          violations.add('${file.path}:${line + 1}  $snippet');
        }
      }
      expect(
        violations,
        isEmpty,
        reason: '${rule.fix}\n${violations.join('\n')}',
      );
    });
  }
}

class _Rule {
  const _Rule(this.name, this.pattern, this.fix, {this.argPattern});

  final String name;
  final RegExp pattern;
  final String fix;

  /// When set, [pattern]'s first group must also contain this to count.
  final RegExp? argPattern;
}

/// Drops `//` comments so doc examples don't trip the rules. Line structure is
/// preserved for accurate line numbers.
String _stripComments(String source) =>
    source.replaceAll(RegExp(r'//.*$', multiLine: true), '');
