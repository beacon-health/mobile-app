import 'package:beacon_app/core/services/recent_facilities_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_facility.dart';

void main() {
  final service = RecentFacilitiesService();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service.clear();
  });

  List<String> ids() => [for (final f in service.recentFacilities) f.id];

  test('lists the most recently viewed first', () {
    service
      ..addFacility(createTestFacility(id: 'a'))
      ..addFacility(createTestFacility(id: 'b'));

    expect(ids(), ['b', 'a']);
    expect(service.isEmpty, isFalse);
  });

  test('viewing a facility again moves it to the front once', () {
    service
      ..addFacility(createTestFacility(id: 'a'))
      ..addFacility(createTestFacility(id: 'b'))
      ..addFacility(createTestFacility(id: 'a'));

    expect(ids(), ['a', 'b']);
  });

  test('keeps only the newest ${RecentFacilitiesService.maxItems}', () {
    for (final id in ['a', 'b', 'c', 'd', 'e']) {
      service.addFacility(createTestFacility(id: id));
    }

    expect(ids(), ['e', 'd', 'c']);
  });

  test('removes one and clears all', () {
    service
      ..addFacility(createTestFacility(id: 'a'))
      ..addFacility(createTestFacility(id: 'b'))
      ..removeFacility('a');
    expect(ids(), ['b']);

    service.clear();
    expect(service.isEmpty, isTrue);
  });

  test('notifies listeners on every change', () {
    var notifications = 0;
    void onChange() => notifications++;
    service.addListener(onChange);
    addTearDown(() => service.removeListener(onChange));

    service
      ..addFacility(createTestFacility(id: 'a'))
      ..removeFacility('missing')
      ..removeFacility('a');

    expect(notifications, 2, reason: 'removing a missing id changes nothing');
  });
}
