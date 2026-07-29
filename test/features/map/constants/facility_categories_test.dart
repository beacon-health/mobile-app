import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FacilityCategories.groupFor', () {
    test('medical categories consolidate to Health Care', () {
      for (final value in [
        'Medical Care',
        'Hospitals',
        'Home Care',
        'Health Charities',
      ]) {
        expect(
          FacilityCategories.groupFor(value),
          FacilityCategories.groupHealthCare,
          reason: '$value should group as Health Care',
        );
      }
    });

    test('mental health and addiction recovery map to Mental Health', () {
      expect(
        FacilityCategories.groupFor('Mental Health'),
        FacilityCategories.groupMentalHealth,
      );
      expect(
        FacilityCategories.groupFor('Addiction Recovery'),
        FacilityCategories.groupMentalHealth,
      );
    });

    test('housing maps to Housing & Shelter', () {
      expect(
        FacilityCategories.groupFor('Housing'),
        FacilityCategories.groupHousingShelter,
      );
    });

    test('population-specific services map to Basic Needs', () {
      for (final value in [
        'Basic Needs',
        'Children and Families',
        'Seniors',
        'Veterans',
        'Disability Services',
      ]) {
        expect(
          FacilityCategories.groupFor(value),
          FacilityCategories.groupBasicNeeds,
          reason: '$value should group as Basic Needs',
        );
      }
    });

    test('generic community services and unknowns fall back to Other', () {
      expect(
        FacilityCategories.groupFor('Community Services'),
        FacilityCategories.groupOther,
      );
      expect(FacilityCategories.groupFor(null), FacilityCategories.groupOther);
      expect(
        FacilityCategories.groupFor('Something Else'),
        FacilityCategories.groupOther,
      );
    });
  });

  group('FacilityCategories.valuesForGroup', () {
    test('every category_broad value belongs to exactly one group', () {
      for (final value in FacilityCategories.categoryBroadValues) {
        final group = FacilityCategories.groupFor(value);
        expect(FacilityCategories.valuesForGroup(group), contains(value));
      }
    });

    test('the broad value list matches the database exactly', () {
      expect(FacilityCategories.categoryBroadValues, hasLength(13));
      expect(
        FacilityCategories.categoryBroadValues,
        containsAll(['Medical Care', 'Hospitals', 'Housing', 'Veterans']),
      );
    });

    test('Health Care group includes hospitals but not mental health', () {
      final values = FacilityCategories.valuesForGroup(
        FacilityCategories.groupHealthCare,
      );
      expect(values, contains('Hospitals'));
      expect(values, contains('Medical Care'));
      expect(values, isNot(contains('Mental Health')));
    });
  });
}
