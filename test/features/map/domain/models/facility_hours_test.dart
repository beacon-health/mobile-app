import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opening hours as the database writes them, and the "Open Now" answer the
/// filter builds on.
void main() {
  Facility withHours(String operatingHours) => Facility.fromSupabase({
        'id': 'x',
        'facility_name': 'Test',
        'latitude': 41.8781,
        'longitude': -87.6298,
        'city': 'Chicago',
        'state': 'IL',
        'operational': 'Y',
        'operating_hours': operatingHours,
      });

  // 2026-10-12 is a Monday.
  DateTime monday(int hour, [int minute = 0]) =>
      DateTime(2026, 10, 12, hour, minute);
  DateTime tuesday(int hour, [int minute = 0]) =>
      DateTime(2026, 10, 13, hour, minute);
  DateTime sunday(int hour, [int minute = 0]) =>
      DateTime(2026, 10, 18, hour, minute);

  group('parsing operating_hours', () {
    test('reads the day-list format', () {
      final facility = withHours(
        'M: 9:00AM-5:00PM, T: Closed, W: 12:30PM-8:00PM, Th: 9:00AM-5:00PM, '
        'F: 9:00AM-12:00PM, Sa: Closed, Su: Closed',
      );

      expect(facility.hours, hasLength(7));
      final byDay = {for (final h in facility.hours) h.day: h};
      expect(byDay['mon']!.opensAt, '09:00');
      expect(byDay['mon']!.closesAt, '17:00');
      expect(byDay['wed']!.opensAt, '12:30');
      expect(byDay['wed']!.closesAt, '20:00');
      expect(byDay['fri']!.closesAt, '12:00');
      // A closed day is listed, with no times.
      expect(byDay['tue']!.opensAt, isNull);
      expect(byDay['tue']!.isClosed, isTrue);
      expect(byDay['mon']!.isClosed, isFalse);
    });

    test('an unknown day is kept apart from a closed one', () {
      final facility = withHours('M: 9:00AM-5:00PM, T: U, Su: Closed');

      final byDay = {for (final h in facility.hours) h.day: h};
      expect(byDay['tue']!.opensAt, isNull);
      expect(byDay['tue']!.isClosed, isFalse);
      expect(byDay['sun']!.isClosed, isTrue);
    });

    test('nothing but unknown days is no hours on file', () {
      expect(withHours('M: U, T: U, W: U').hours, isEmpty);
      // One known fact is worth showing the week for.
      expect(withHours('M: U, T: U, Su: Closed').hours, hasLength(3));
    });

    test('noon and midnight convert correctly', () {
      final facility = withHours('M: 12:00AM-12:00PM');
      expect(facility.hours.single.opensAt, '00:00');
      expect(facility.hours.single.closesAt, '12:00');
    });

    test('a placeholder means no hours on file', () {
      for (final raw in ['N', '']) {
        expect(withHours(raw).hours, isEmpty, reason: '"$raw"');
      }
    });

    test('free text that is not a day list yields no hours, not a crash', () {
      expect(
        withHours('Call for an appointment; hours vary by program').hours,
        isEmpty,
      );
    });
  });

  group('isOpenAt', () {
    final weekdays = withHours('M: 9:00AM-5:00PM, T: Closed, W: 9:00AM-5:00PM');

    test('open inside its hours, closed outside them', () {
      expect(weekdays.isOpenAt(monday(9)), isTrue);
      expect(weekdays.isOpenAt(monday(12, 30)), isTrue);
      expect(weekdays.isOpenAt(monday(17)), isTrue);
      expect(weekdays.isOpenAt(monday(8, 59)), isFalse);
      expect(weekdays.isOpenAt(monday(17, 1)), isFalse);
    });

    test('closed on a day marked closed, or not listed at all', () {
      expect(weekdays.isOpenAt(tuesday(12)), isFalse);
      expect(weekdays.isOpenAt(sunday(12)), isFalse);
    });

    test('no hours on file is never "open"', () {
      expect(withHours('N').isOpenAt(monday(12)), isFalse);
    });

    test('an all-day listing is open at any time', () {
      final allDay = withHours('M: 12:00AM-11:59PM');
      expect(allDay.isOpenAt(monday(0)), isTrue);
      expect(allDay.isOpenAt(monday(3, 30)), isTrue);
      expect(allDay.isOpenAt(monday(23, 59)), isTrue);
    });

    test('hours that run past midnight cover both sides of it', () {
      // "Noon to 2 AM": these read as closing before they opened, so the
      // facility never showed as open at all.
      final lateNight = withHours('M: 12:00PM-2:00AM, T: Closed');

      expect(lateNight.isOpenAt(monday(11, 59)), isFalse);
      expect(lateNight.isOpenAt(monday(13)), isTrue);
      expect(lateNight.isOpenAt(monday(23, 30)), isTrue);
      // Early Tuesday still belongs to Monday's hours…
      expect(lateNight.isOpenAt(tuesday(1, 30)), isTrue);
      // …until they end.
      expect(lateNight.isOpenAt(tuesday(2, 1)), isFalse);
      expect(lateNight.isOpenAt(tuesday(13)), isFalse);
    });

    test('Sunday night carries into Monday morning', () {
      final sundayNight = withHours('Su: 10:00PM-6:00AM');
      expect(sundayNight.isOpenAt(sunday(23)), isTrue);
      expect(sundayNight.isOpenAt(monday(5)), isTrue);
      expect(sundayNight.isOpenAt(monday(7)), isFalse);
    });
  });

  group('phones', () {
    test('lists each number once, main contact first', () {
      final facility = Facility.fromSupabase({
        'id': 'x',
        'facility_name': 'Test',
        'latitude': 1.0,
        'longitude': 1.0,
        'contact_phones': ['3125550100', '3125550100', '3125550199'],
      });

      expect(
        facility.phones.map((p) => p.number),
        ['3125550100', '3125550199'],
      );
      expect(facility.primaryPhone, '3125550100');
    });

    test('a facility with no phone says so', () {
      final facility = Facility.fromSupabase({
        'id': 'x',
        'facility_name': 'Test',
        'latitude': 1.0,
        'longitude': 1.0,
      });
      expect(facility.phones, isEmpty);
      expect(facility.primaryPhone, 'Phone not available');
    });
  });
}
