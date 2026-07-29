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
