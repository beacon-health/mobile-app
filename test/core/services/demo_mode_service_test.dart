import 'package:beacon_app/core/services/demo_mode_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DemoModeService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to demo mode off', () async {
      final service = DemoModeService();
      await service.init();
      expect(service.isDemoMode, isFalse);
    });

    test('persists demo mode on', () async {
      SharedPreferences.setMockInitialValues({'demo_mode_enabled': true});
      final service = DemoModeService();
      await service.init();
      expect(service.isDemoMode, isTrue);
    });
  });
}
