import 'package:beacon_app/features/map/presentation/services/facility_filter_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_facility.dart';

void main() {
  group('FacilityFilterService.filterFacilities', () {
    final facilities = [
      createTestFacility(
        id: '1',
        name: 'Free Clinic',
        appCategory: 'Health Care',
      ),
      createTestFacility(
        id: '2',
        name: 'Food Pantry A',
        appCategory: 'Food Pantry',
      ),
      createTestFacility(
        id: '3',
        name: 'Shelter B',
        appCategory: 'Housing & Shelter',
      ),
      createTestFacility(
        id: '4',
        name: 'Mental Health Center',
        appCategory: 'Mental Health',
        isFavorite: true,
      ),
    ];

    test('returns all when no filters are active', () {
      final result = FacilityFilterService.filterFacilities(
        facilities,
        searchText: '',
        selectedCategories: {},
        showFavoritesOnly: false,
        showOpenNowOnly: false,
      );
      expect(result, hasLength(4));
    });

    test('filters by search text (name match)', () {
      final result = FacilityFilterService.filterFacilities(
        facilities,
        searchText: 'clinic',
        selectedCategories: {},
        showFavoritesOnly: false,
        showOpenNowOnly: false,
      );
      expect(result, hasLength(1));
      expect(result.first.name, 'Free Clinic');
    });

    test('filters by category', () {
      final result = FacilityFilterService.filterFacilities(
        facilities,
        searchText: '',
        selectedCategories: {'Food Pantry'},
        showFavoritesOnly: false,
        showOpenNowOnly: false,
      );
      expect(result, hasLength(1));
      expect(result.first.id, '2');
    });

    test('filters by favorites only', () {
      final result = FacilityFilterService.filterFacilities(
        facilities,
        searchText: '',
        selectedCategories: {},
        showFavoritesOnly: true,
        showOpenNowOnly: false,
      );
      expect(result, hasLength(1));
      expect(result.first.id, '4');
    });

    test('combines search + category filters', () {
      final result = FacilityFilterService.filterFacilities(
        facilities,
        searchText: 'pantry',
        selectedCategories: {'Food Pantry'},
        showFavoritesOnly: false,
        showOpenNowOnly: false,
      );
      expect(result, hasLength(1));
      expect(result.first.id, '2');
    });

    test('returns empty when nothing matches', () {
      final result = FacilityFilterService.filterFacilities(
        facilities,
        searchText: 'nonexistent',
        selectedCategories: {},
        showFavoritesOnly: false,
        showOpenNowOnly: false,
      );
      expect(result, isEmpty);
    });
  });

  group('FacilityFilterService.getAvailableCategories', () {
    test('returns unique categories', () {
      final facilities = [
        createTestFacility(appCategory: 'Health Care'),
        createTestFacility(appCategory: 'Health Care'),
        createTestFacility(appCategory: 'Food Pantry'),
      ];
      final categories =
          FacilityFilterService.getAvailableCategories(facilities);
      expect(categories, {'Health Care', 'Food Pantry'});
    });
  });
}
