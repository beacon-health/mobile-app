import 'package:beacon_app/features/map/data/facility_repository.dart';
import 'package:beacon_app/features/map/data/supabase_facility_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The data layer around the `facilities_near` query: what it asks for, what
/// it caches, and how it copes with bad rows and failures.
void main() {
  Map<String, dynamic> row(String id) => {
        'id': id,
        'facility_name': 'Facility $id',
        'latitude': 41.88,
        'longitude': -87.63,
        'city': 'Chicago',
        'state': 'IL',
      };

  late List<Map<String, dynamic>> calls;
  late List<dynamic> response;

  SupabaseFacilityService service() => SupabaseFacilityService(
        nearbyQuery: (params) async {
          calls.add(params);
          return response;
        },
      );

  setUp(() {
    calls = [];
    response = [row('a'), row('b')];
  });

  group('SupabaseFacilityService.getFacilitiesNearLocation', () {
    test('asks for a bounded, metric query', () async {
      final facilities = await service().getFacilitiesNearLocation(
        latitude: 41.88,
        longitude: -87.63,
        radiusKm: 8,
      );

      expect(facilities.map((f) => f.id), ['a', 'b']);
      expect(calls.single, {
        'lat': 41.88,
        'lng': -87.63,
        'radius_m': 8000.0,
        'max_results': 250,
      });
    });

    test('answers a repeat of the same search from memory', () async {
      final s = service();
      await s.getFacilitiesNearLocation(
        latitude: 41.88,
        longitude: -87.63,
        radiusKm: 8,
      );
      // A few hundred metres away rounds to the same region.
      await s.getFacilitiesNearLocation(
        latitude: 41.8812,
        longitude: -87.6311,
        radiusKm: 8,
      );

      expect(calls, hasLength(1));
    });

    test('queries again for a different place or radius', () async {
      final s = service();
      await s.getFacilitiesNearLocation(
        latitude: 41.88,
        longitude: -87.63,
        radiusKm: 8,
      );
      await s.getFacilitiesNearLocation(
        latitude: 41.95,
        longitude: -87.63,
        radiusKm: 8,
      );
      await s.getFacilitiesNearLocation(
        latitude: 41.88,
        longitude: -87.63,
        radiusKm: 16,
      );

      expect(calls, hasLength(3));
    });

    test('clearCache forgets everything', () async {
      final s = service();
      await s.getFacilitiesNearLocation(
        latitude: 41.88,
        longitude: -87.63,
        radiusKm: 8,
      );
      s.clearCache();
      await s.getFacilitiesNearLocation(
        latitude: 41.88,
        longitude: -87.63,
        radiusKm: 8,
      );

      expect(calls, hasLength(2));
    });

    test('keeps a bounded number of regions', () async {
      final s = service();
      // More distinct regions than the cache holds, then the first again.
      for (var i = 0; i < 20; i++) {
        await s.getFacilitiesNearLocation(
          latitude: 40 + i * 0.5,
          longitude: -87.63,
          radiusKm: 8,
        );
      }
      await s.getFacilitiesNearLocation(
        latitude: 40,
        longitude: -87.63,
        radiusKm: 8,
      );

      expect(calls, hasLength(21), reason: 'the oldest region was evicted');
    });

    test('skips a row it cannot read and keeps the rest', () async {
      response = [
        row('a'),
        {'id': 12345, 'facility_name': 'Wrong type for id'},
        row('c'),
      ];

      final facilities = await service().getFacilitiesNearLocation(
        latitude: 41.88,
        longitude: -87.63,
        radiusKm: 8,
      );

      expect(facilities.map((f) => f.id), ['a', 'c']);
    });

    test('an empty or missing response is an empty list', () async {
      response = [];
      expect(
        await service().getFacilitiesNearLocation(
          latitude: 1,
          longitude: 1,
          radiusKm: 8,
        ),
        isEmpty,
      );
    });

    test('carries the eligibility columns through', () async {
      response = [
        {
          ...row('a'),
          'operational': 'Y',
          'accepts_medicaid': 'Y',
          'income_limit': 'Below 200% FPL',
          'service_area': 'Cook County',
        },
      ];

      final facility = (await service().getFacilitiesNearLocation(
        latitude: 41.88,
        longitude: -87.63,
        radiusKm: 8,
      ))
          .single;

      expect(facility.eligibilityRequirements['accepts_medicaid'], isTrue);
      expect(facility.eligibility!.incomeLimit, 'Below 200% FPL');
      expect(facility.eligibility!.serviceArea, 'Cook County');
    });
  });

  group('FacilityRepository', () {
    test('converts miles to kilometres for the query', () async {
      final repository = FacilityRepository(service: service());

      await repository.loadFacilitiesWithDistance(
        latitude: 41.88,
        longitude: -87.63,
        radiusMiles: 5,
      );

      expect(calls.single['radius_m'], closeTo(8046.7, 0.1));
    });

    test('a failed query is an empty list, not a crash', () async {
      final repository = FacilityRepository(
        service: SupabaseFacilityService(
          nearbyQuery: (_) async => throw Exception('network down'),
        ),
      );

      expect(
        await repository.loadFacilitiesWithDistance(
          latitude: 41.88,
          longitude: -87.63,
          radiusMiles: 5,
        ),
        isEmpty,
      );
    });
  });
}
