import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:beacon_app/features/map/domain/models/eligibility_model.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('Facility.fromSupabase', () {
    test('parses minimal valid data', () {
      final data = <String, dynamic>{
        'id': 'abc-123',
        'facility_name': 'Test Clinic',
        'facility_description': 'A free clinic',
        'latitude': 41.8781,
        'longitude': -87.6298,
        'street_address': '100 N Main St',
        'city': 'Chicago',
        'state': 'IL',
        'postal_code': '60601',
        'category_broad': 'Medical Care',
        'category_detail': 'Community Clinic',
      };

      final facility = Facility.fromSupabase(data);

      expect(facility.id, 'abc-123');
      expect(facility.name, 'Test Clinic');
      expect(facility.description, 'A free clinic');
      expect(facility.location.latitude, 41.8781);
      expect(facility.location.longitude, -87.6298);
      expect(facility.city, 'Chicago');
      expect(facility.categoryBroad, 'Medical Care');
      expect(facility.serviceTags, isEmpty);
    });

    test('reads service_tags, main tag first, and drops unknown keys', () {
      final facility = Facility.fromSupabase(<String, dynamic>{
        'id': 'tags-1',
        'facility_name': 'Hope Center',
        'latitude': 41.0,
        'longitude': -87.0,
        'category_broad': 'Community Services',
        'service_tags': ['food_pantry', 'not_a_chip', 'seniors'],
      });
      expect(facility.serviceTags, ['food_pantry', 'seniors']);
      // The pin follows the main chip, not category_broad.
      expect(facility.primaryCategory, FacilityCategories.groupBasicNeeds);
    });

    test('handles null optional fields gracefully', () {
      final data = <String, dynamic>{
        'id': 'abc-456',
        'facility_name': 'Bare Minimum',
        'latitude': 0.0,
        'longitude': 0.0,
        'city': '',
        'state': '',
      };

      final facility = Facility.fromSupabase(data);

      expect(facility.id, 'abc-456');
      expect(facility.name, 'Bare Minimum');
      expect(facility.website, isNull);
      expect(facility.email, isNull);
      expect(facility.phones, isEmpty);
      expect(facility.services, isEmpty);
    });
  });

  group('last checked', () {
    Facility withChecked(Object? value) => Facility.fromSupabase({
          'id': 'x',
          'facility_name': 'Test',
          'latitude': 41.8781,
          'longitude': -87.6298,
          'city': 'Chicago',
          'state': 'IL',
          'last_checked_at': value,
        });

    test('reads a timestamptz as the moment it names', () {
      final checked = withChecked('2026-10-03T14:05:00+00:00').lastCheckedAt;
      expect(checked, DateTime.utc(2026, 10, 3, 14, 5));
    });

    test('anything else is no date', () {
      for (final value in [null, '', 'soon', 42]) {
        expect(withChecked(value).lastCheckedAt, isNull, reason: '$value');
      }
    });

    test('survives copyWith', () {
      final facility = withChecked('2026-10-03T14:05:00Z');
      expect(
        facility.copyWith(isFavorite: true).lastCheckedAt,
        facility.lastCheckedAt,
      );
    });
  });

  group('Facility.fromSupabase eligibility extras', () {
    Map<String, dynamic> row(Map<String, dynamic> extra) => {
          'id': 'x',
          'facility_name': 'Test Clinic',
          'latitude': 41.8781,
          'longitude': -87.6298,
          'city': 'Chicago',
          'state': 'IL',
          // Present on every row that has eligibility data at all.
          'operational': 'Y',
          ...extra,
        };

    test('reads Medicaid, income limit and service area', () {
      final facility = Facility.fromSupabase(
        row({
          'accepts_medicaid': 'Y',
          'income_limit': ' At or below 138% of the federal poverty level. ',
          'service_area': 'Garvin, McClain and Grady counties',
        }),
      );

      expect(facility.eligibility!.acceptsMedicaid, EligibilityValue.yes);
      expect(
        facility.eligibility!.incomeLimit,
        'At or below 138% of the federal poverty level.',
      );
      expect(
        facility.eligibility!.serviceArea,
        'Garvin, McClain and Grady counties',
      );
      expect(facility.eligibilityRequirements['accepts_medicaid'], isTrue);
    });

    test('a "no" is a known answer; a blank is not', () {
      final refuses = Facility.fromSupabase(row({'accepts_medicaid': 'N'}));
      expect(refuses.eligibility!.acceptsMedicaid, EligibilityValue.no);
      expect(refuses.eligibilityRequirements['accepts_medicaid'], isFalse);

      // Most rows: the column is null, so the facility passes the gate.
      final unknown = Facility.fromSupabase(row({}));
      expect(unknown.eligibility!.acceptsMedicaid, EligibilityValue.unknown);
      expect(
        unknown.eligibilityRequirements.containsKey('accepts_medicaid'),
        isFalse,
      );
    });

    test('placeholder text in the free-text columns is treated as absent', () {
      final facility = Facility.fromSupabase(
        row({'income_limit': 'N', 'service_area': '   '}),
      );

      expect(facility.eligibility!.incomeLimit, isNull);
      expect(facility.eligibility!.serviceArea, isNull);
    });

    test('a row from before the columns existed still parses', () {
      // What the 1.0.0-era query returned: none of the three keys.
      final facility = Facility.fromSupabase(row({'proof_of_income': 'N'}));

      expect(facility.eligibility!.acceptsMedicaid, EligibilityValue.unknown);
      expect(facility.eligibility!.incomeLimit, isNull);
      expect(facility.eligibility!.serviceArea, isNull);
    });
  });

  group('Facility address', () {
    test('joins street, city, state and ZIP once each', () {
      final facility = Facility.fromSupabase({
        'id': 'x',
        'facility_name': 'Test',
        'latitude': 1.0,
        'longitude': 1.0,
        'street_address': '35 E Wacker Dr',
        'city': 'Chicago',
        'state': 'IL',
        'postal_code': '60601',
      });

      expect(facility.address, '35 E Wacker Dr, Chicago, IL 60601');
      expect(facility.hasAddress, isTrue);
    });

    test('knows when there is nothing to route to', () {
      final facility = Facility.fromSupabase({
        'id': 'x',
        'facility_name': 'Test',
        'latitude': 1.0,
        'longitude': 1.0,
      });

      expect(facility.address, Facility.addressUnavailable);
      expect(facility.hasAddress, isFalse);
    });
  });

  group('Facility computed properties', () {
    test('primaryPhone returns first phone or fallback', () {
      const withPhone = Facility(
        id: '1',
        name: 'A',
        description: '',
        location: LatLng(0, 0),
        address: '',
        city: '',
        state: '',
        phones: [PhoneContact(number: '312-555-0100')],
      );
      expect(withPhone.primaryPhone, '312-555-0100');

      const noPhone = Facility(
        id: '2',
        name: 'B',
        description: '',
        location: LatLng(0, 0),
        address: '',
        city: '',
        state: '',
      );
      expect(noPhone.primaryPhone, 'Phone not available');
    });

    test('hoursDisplay formats correctly', () {
      const facility = Facility(
        id: '1',
        name: 'A',
        description: '',
        location: LatLng(0, 0),
        address: '',
        city: '',
        state: '',
        hours: [
          OperatingHours(day: 'mon', opensAt: '09:00', closesAt: '17:00'),
        ],
      );
      expect(facility.hoursDisplay, contains('Mon'));
    });
  });
}
