import 'package:beacon_app/core/utils/phone_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatPhoneForDisplay', () {
    test('normalizes the mixed source formats to (xxx) xxx-xxxx', () {
      expect(formatPhoneForDisplay('312-555-1234'), '(312) 555-1234');
      expect(formatPhoneForDisplay('3125551234'), '(312) 555-1234');
      expect(formatPhoneForDisplay('(312) 555-1234'), '(312) 555-1234');
      expect(formatPhoneForDisplay('1-312-555-1234'), '(312) 555-1234');
    });

    test('leaves non-10-digit strings untouched', () {
      expect(formatPhoneForDisplay('555-1234'), '555-1234');
      expect(formatPhoneForDisplay('+44 20 7946 0958'), '+44 20 7946 0958');
      expect(formatPhoneForDisplay(''), '');
    });
  });

  group('dialablePhone', () {
    test('strips everything except digits and +', () {
      expect(dialablePhone('(312) 555-1234 ext. 9'), '31255512349');
      expect(dialablePhone('+1-312-555-1234'), '+13125551234');
    });
  });
}
