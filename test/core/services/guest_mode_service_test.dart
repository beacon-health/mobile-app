import 'package:beacon_app/core/services/demo_mode_service.dart';
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

    test('isGuest returns true in demo mode', () async {
      SharedPreferences.setMockInitialValues({'demo_mode_enabled': true});
      await DemoModeService().init();
      expect(GuestModeService().isGuest, isTrue);
      // Reset for subsequent tests.
      await DemoModeService().setDemoMode(false);
    });

    test('isGuest defaults to true when Supabase is not initialized', () async {
      // Reload DemoModeService from empty prefs → isDemoMode = false.
      await DemoModeService().init();
      // Supabase is not initialized in tests; GuestModeService catches and
      // returns true.
      expect(GuestModeService().isGuest, isTrue);
    });

    test('init completes without error when Supabase is not initialized',
        () async {
      await DemoModeService().init();
      // Should not throw even though Supabase is unavailable.
      await expectLater(GuestModeService().init(), completes);
    });
  });
}
