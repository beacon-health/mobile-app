import 'package:beacon_app/core/utils/zip_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZipState.stateFor', () {
    test('resolves ZIPs in the launched states', () {
      // Illinois spans 600–629; Oklahoma is 730–732 and 734–749.
      expect(ZipState.stateFor('60601'), 'IL');
      expect(ZipState.stateFor('62999'), 'IL');
      expect(ZipState.stateFor('73102'), 'OK');
      expect(ZipState.stateFor('74103'), 'OK');
      expect(ZipState.stateFor('74966'), 'OK');
    });

    test('keeps neighbours on the right side of a block edge', () {
      expect(ZipState.stateFor('59901'), 'MT');
      expect(ZipState.stateFor('63101'), 'MO');
      expect(ZipState.stateFor('72901'), 'AR');
      // 733 is carved out of the Oklahoma range for Austin, Texas.
      expect(ZipState.stateFor('73301'), 'TX');
      expect(ZipState.stateFor('75001'), 'TX');
    });

    test('covers every state, DC and the territories', () {
      const samples = {
        'AK': '99501', 'AL': '35203', 'AR': '72201', 'AZ': '85001',
        'CA': '90001', 'CO': '80202', 'CT': '06103', 'DC': '20001',
        'DE': '19801', 'FL': '33101', 'GA': '30303', 'GU': '96910',
        'HI': '96813', 'IA': '50309', 'ID': '83702', 'IL': '60601',
        'IN': '46204', 'KS': '66603', 'KY': '40202', 'LA': '70112',
        'MA': '02108', 'MD': '21201', 'ME': '04101', 'MI': '48226',
        'MN': '55401', 'MO': '64106', 'MS': '39201', 'MT': '59601',
        'NC': '27601', 'ND': '58501', 'NE': '68508', 'NH': '03301',
        'NJ': '07102', 'NM': '87101', 'NV': '89101', 'NY': '10001',
        'OH': '43215', 'OK': '73102', 'OR': '97201', 'PA': '19103',
        'PR': '00901', 'RI': '02903', 'SC': '29201', 'SD': '57501',
        'TN': '37203', 'TX': '77002', 'UT': '84101', 'VA': '23219',
        'VI': '00802', 'VT': '05602', 'WA': '98101', 'WI': '53202',
        'WV': '25301', 'WY': '82001', //
      };
      expect(samples, hasLength(54));
      for (final MapEntry(key: state, value: zip) in samples.entries) {
        expect(ZipState.stateFor(zip), state, reason: zip);
      }
    });

    test('returns null for anything that is not a state ZIP', () {
      expect(ZipState.stateFor('00000'), isNull);
      expect(ZipState.stateFor('09012'), isNull, reason: 'military (AE)');
      expect(ZipState.stateFor('96201'), isNull, reason: 'military (AP)');
      expect(ZipState.stateFor('6060'), isNull);
      expect(ZipState.stateFor('606011'), isNull);
      expect(ZipState.stateFor('6o6o1'), isNull);
      expect(ZipState.stateFor('Current Location'), isNull);
      expect(ZipState.stateFor(''), isNull);
    });

    test('ignores surrounding whitespace', () {
      expect(ZipState.stateFor(' 60601 '), 'IL');
      expect(ZipState.isWellFormed(' 60601 '), isTrue);
      expect(ZipState.isWellFormed('Ubicación actual'), isFalse);
    });
  });
}
