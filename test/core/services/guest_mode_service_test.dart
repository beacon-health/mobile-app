import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GuestModeService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('singleton instance is always the same', () {
      expect(GuestModeService(), same(GuestModeService()));
    });

    test('isGuest defaults to true when Supabase is not initialized', () {
      expect(GuestModeService().isGuest, isTrue);
    });

    test('init completes without error when Supabase is not initialized',
        () async {
      await expectLater(GuestModeService().init(), completes);
    });
  });
}
