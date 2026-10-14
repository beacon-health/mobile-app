import 'package:beacon_app/core/services/accessibility_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final settings = AccessibilitySettings();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await settings.init();
  });

  test('both options start off', () {
    expect(settings.openMapAsList, isFalse);
    expect(settings.largerMapPins, isFalse);
    expect(settings.pinScale, 1);
  });

  test('larger pins draw bigger', () async {
    await settings.setLargerMapPins(true);

    expect(settings.pinScale, AccessibilitySettings.largerPinScale);
    // A pin's name is drawn at 8pt on a 3x phone; this brings it past 11.
    expect(8 * settings.pinScale, greaterThanOrEqualTo(11));
  });

  test('choices survive a restart', () async {
    await settings.setOpenMapAsList(true);
    await settings.setLargerMapPins(true);

    await settings.init();

    expect(settings.openMapAsList, isTrue);
    expect(settings.largerMapPins, isTrue);
  });

  test('tells listeners once per change, and not for a repeat', () async {
    var notified = 0;
    void listener() => notified++;
    settings.addListener(listener);
    addTearDown(() => settings.removeListener(listener));

    await settings.setOpenMapAsList(true);
    await settings.setOpenMapAsList(true);

    expect(notified, 1);
  });
}
