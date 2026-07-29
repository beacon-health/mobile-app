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

    test('food and essentials maps to Basic Needs', () {
      expect(
        FacilityCategories.groupFor('Basic Needs'),
        FacilityCategories.groupBasicNeeds,
      );
    });

    test('population-specific services map to Specialized Services', () {
      for (final value in [
        'Children and Families',
        'Seniors',
        'Veterans',
        'Disability Services',
      ]) {
        expect(
          FacilityCategories.groupFor(value),
          FacilityCategories.groupSpecialized,
          reason: '$value should group as Specialized Services',
        );
      }
    });

    test('community nonprofits map to Community Resources', () {
      expect(
        FacilityCategories.groupFor('Community Services'),
        FacilityCategories.groupCommunity,
      );
    });

    test('only null / unrecognized values fall back to Other', () {
      expect(FacilityCategories.groupFor(null), FacilityCategories.groupOther);
      expect(
        FacilityCategories.groupFor('Something Else'),
        FacilityCategories.groupOther,
      );
    });

    test('every known broad value maps to a real group, never the fallback',
        () {
      for (final value in FacilityCategories.categoryBroadValues) {
        expect(
          FacilityCategories.groupFor(value),
          isNot(FacilityCategories.groupOther),
          reason: '$value must belong to a quick-action group',
        );
      }
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

    test('the six quick-action groups cover all 13 broad values', () {
      expect(FacilityCategories.quickActionGroups, hasLength(6));
      final covered = [
        for (final g in FacilityCategories.quickActionGroups)
          ...FacilityCategories.valuesForGroup(g),
      ];
      expect(covered..sort(), FacilityCategories.categoryBroadValues.toList());
    });

    test('isGroup accepts group names and rejects raw broad values', () {
      expect(FacilityCategories.isGroup(FacilityCategories.groupCommunity),
          isTrue);
      expect(FacilityCategories.isGroup(FacilityCategories.groupSpecialized),
          isTrue);
      expect(FacilityCategories.isGroup('Medical Care'), isFalse);
      expect(
          FacilityCategories.isGroup(FacilityCategories.groupOther), isFalse);
    });
  });
}
