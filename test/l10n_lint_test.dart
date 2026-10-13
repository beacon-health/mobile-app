import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards for the localization rules in CLAUDE.md, so a slip fails CI instead
/// of reaching users in the wrong language.
void main() {
  Map<String, dynamic> arb(String locale) => jsonDecode(
        File('lib/l10n/app_$locale.arb').readAsStringSync(),
      ) as Map<String, dynamic>;

  final en = arb('en');
  const others = ['es', 'zh'];

  Set<String> messageKeys(Map<String, dynamic> arb) => {
        for (final key in arb.keys)
          if (!key.startsWith('@')) key
      };

  /// The arguments an ICU message takes: `{name}`, and the subject of
  /// `{name, plural, …}` / `{name, select, …}`. Braces alternate between
  /// "argument" and "branch text" as they nest, so `AL{Alabama}` inside a
  /// select is text while the `{count}` inside a plural branch is an argument.
  Set<String> placeholders(String message) {
    final names = <String>{};
    var depth = 0;
    for (var i = 0; i < message.length; i++) {
      final char = message[i];
      if (char == '{') {
        depth++;
        if (depth.isOdd) {
          final name = RegExp(r'\s*([A-Za-z_][A-Za-z0-9_]*)')
              .matchAsPrefix(message, i + 1)
              ?.group(1);
          if (name != null) names.add(name);
        }
      } else if (char == '}') {
        depth--;
      }
    }
    return names;
  }

  group('ARB files', () {
    test('every language has exactly the same keys', () {
      for (final locale in others) {
        final translated = messageKeys(arb(locale));
        expect(
          translated.difference(messageKeys(en)),
          isEmpty,
          reason: 'keys only in app_$locale.arb',
        );
        expect(
          messageKeys(en).difference(translated),
          isEmpty,
          reason: 'keys missing from app_$locale.arb',
        );
      }
    });

    test('no translation is empty', () {
      for (final locale in ['en', ...others]) {
        final file = arb(locale);
        for (final key in messageKeys(file)) {
          expect(
            (file[key] as String).isNotEmpty,
            isTrue,
            reason: '$key in app_$locale.arb',
          );
        }
      }
    });

    test('translations use the same placeholders as English', () {
      for (final locale in others) {
        final translated = arb(locale);
        for (final key in messageKeys(en)) {
          expect(
            placeholders(translated[key] as String),
            placeholders(en[key] as String),
            reason: '$key in app_$locale.arb',
          );
        }
      }
    });

    test('every state and territory has a name in every language', () {
      for (final locale in ['en', ...others]) {
        final names = RegExp(r'\b([A-Z]{2})\{')
            .allMatches(arb(locale)['stateName'] as String)
            .map((m) => m.group(1))
            .toSet();
        expect(names, hasLength(54), reason: 'app_$locale.arb');
      }
    });
  });

  group('hardcoded text', () {
    // A string literal that reads as a sentence — capital first letter, at
    // least one space, closing punctuation — is user-facing copy that skipped
    // the ARB files. That is how an English-only error reached Spanish and
    // Chinese users on the ZIP screen.
    final literal = RegExp(
      r"""(?<![A-Za-z0-9_])(?:'((?:[^'\\\n]|\\.)*)'|"((?:[^"\\\n]|\\.)*)")""",
    );
    final sentence = RegExp(r'^[A-Z].*\s.*[.!?…]$');

    // Where a sentence literal is legitimate: an l10n fallback (`?? '…'`),
    // or text for developers (exceptions, error reports, debug builds).
    final exempt = RegExp(
      r'\?\?|Exception\(|Error\(|throw |report\(|context:|kDebugMode|assert\(',
    );

    // Sign-in failures deliberately surface the provider's own diagnostic.
    const allowed = {
      'lib/core/services/apple_sign_in_service.dart':
          'Apple did not return an identity token.',
    };

    test('no sentence-like string literals outside the ARB files', () {
      final violations = <String>[];
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.contains('/l10n/'));

      for (final file in files) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final trimmed = lines[i].trimLeft();
          if (trimmed.startsWith('//') || trimmed.startsWith('import ')) {
            continue;
          }
          for (final match in literal.allMatches(lines[i])) {
            final text = match.group(1) ?? match.group(2)!;
            if (!sentence.hasMatch(text)) continue;
            if (allowed[file.path] == text) continue;
            // The exemption may sit on the line above (`l10n?.foo ??` then
            // the literal on its own line).
            final context = lines.sublist(i < 2 ? 0 : i - 2, i + 1).join(' ');
            if (exempt.hasMatch(context)) continue;
            violations.add('${file.path}:${i + 1}: "$text"');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Move these strings into lib/l10n/app_*.arb '
            '(all three files), then run `make l10n`.',
      );
    });
  });
}
