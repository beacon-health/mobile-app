import 'dart:ui';

import 'package:beacon_app/core/services/coverage_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/core/utils/coverage_text.dart';
import 'package:beacon_app/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final es = lookupAppLocalizations(const Locale('es'));
  final zh = lookupAppLocalizations(const Locale('zh'));

  group('localizedStateList', () {
    test('reads as prose in English', () {
      expect(localizedStateList(en, ['IL']), 'Illinois');
      expect(localizedStateList(en, ['IL', 'OK']), 'Illinois and Oklahoma');
      expect(
        localizedStateList(en, ['IL', 'OK', 'IN']),
        'Illinois, Oklahoma, and Indiana',
      );
      expect(localizedStateList(en, []), '');
    });

    test('Spanish uses "e" before a name starting with an i sound', () {
      expect(localizedStateList(es, ['IL', 'OK']), 'Illinois y Oklahoma');
      expect(localizedStateList(es, ['OK', 'IL']), 'Oklahoma e Illinois');
      expect(
        localizedStateList(es, ['IL', 'OK', 'IN']),
        'Illinois, Oklahoma e Indiana',
      );
      expect(
        localizedStateList(es, ['IL', 'OK', 'NY']),
        'Illinois, Oklahoma y Nueva York',
      );
    });

    test('Chinese joins without spaces', () {
      expect(localizedStateList(zh, ['IL', 'OK']), '伊利诺伊州和俄克拉荷马州');
      expect(
        localizedStateList(zh, ['IL', 'OK', 'IN']),
        '伊利诺伊州、俄克拉荷马州和印第安纳州',
      );
    });

    test('an unknown code falls back to the code itself', () {
      expect(localizedStateList(en, ['ZZ']), 'ZZ');
    });

    test('every language names all 54 states and territories', () {
      const codes = [
        'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'DC', 'FL', 'GA', //
        'GU', 'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
        'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM',
        'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'PR', 'RI', 'SC', 'SD',
        'TN', 'TX', 'UT', 'VT', 'VA', 'VI', 'WA', 'WV', 'WI', 'WY',
      ];
      expect(codes, hasLength(54));
      for (final l10n in [en, es, zh]) {
        for (final code in codes) {
          expect(l10n.stateName(code), isNot(code), reason: code);
        }
      }
    });
  });

  group('zipErrorMessage', () {
    setUp(() => CoverageService().debugSetStates(['IL', 'OK']));
    tearDown(CoverageService().debugReset);

    test('an uncovered ZIP names the states that are live', () {
      expect(
        zipErrorMessage(en, ZipResult.outsideCoverage),
        "Beacon isn't available in that area yet. It currently covers "
        'Illinois and Oklahoma.',
      );
    });

    test('an unknown ZIP gets the not-found message', () {
      expect(
        zipErrorMessage(en, ZipResult.notFound),
        en.settingsZipNotFoundError,
      );
    });
  });
}
