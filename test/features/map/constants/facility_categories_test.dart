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

    test(
        'population-specific and community services map to Family & '
        'Community', () {
      for (final value in [
        'Children and Families',
        'Seniors',
        'Veterans',
        'Disability Services',
        'Community Services',
      ]) {
        expect(
          FacilityCategories.groupFor(value),
          FacilityCategories.groupFamilyCommunity,
          reason: '$value should group as Family & Community',
        );
      }
    });

    test('only null / unrecognized values fall back to Other', () {
      expect(FacilityCategories.groupFor(null), FacilityCategories.groupOther);
      expect(
        FacilityCategories.groupFor('Something Else'),
        FacilityCategories.groupOther,
      );
    });

    test('chip keys group under their own Home group', () {
      expect(
        FacilityCategories.groupFor('abuse_shelter'),
        FacilityCategories.groupHousingShelter,
      );
      expect(
        FacilityCategories.groupFor('baby_supplies'),
        FacilityCategories.groupBasicNeeds,
      );
      expect(
        FacilityCategories.groupFor('transportation'),
        FacilityCategories.groupFamilyCommunity,
      );
      expect(
        FacilityCategories.groupFor('legal'),
        FacilityCategories.groupMoneyJobsLegal,
      );
    });

    test('the broad value list matches the database exactly', () {
      // An untagged facility's group comes from category_broad, so a new or
      // renamed value would fall back to the grey pin unnoticed.
      expect(FacilityCategories.categoryBroadValues, hasLength(13));
      expect(
        FacilityCategories.categoryBroadValues,
        containsAll(['Medical Care', 'Hospitals', 'Housing', 'Veterans']),
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
    test('every group has three to five chips, and every chip one group', () {
      final covered = <String>[];
      for (final group in FacilityCategories.quickActionGroups) {
        final chips = FacilityCategories.valuesForGroup(group);
        expect(chips.length, inInclusiveRange(3, 5), reason: group);
        covered.addAll(chips);
      }
      expect(covered, FacilityCategories.serviceTagKeys);
    });

    test('the chip keys match the data pipeline exactly', () {
      // beacon-data service_tags.py KEYS; the database CHECK refuses others.
      expect(FacilityCategories.serviceTagKeys.toSet(), {
        'medical_clinic',
        'hospital',
        'dental_vision',
        'home_care',
        'mental_health_care',
        'crisis',
        'addiction',
        'recovery',
        'emergency_shelter',
        'abuse_shelter',
        'transitional_housing',
        'affordable_housing',
        'food_pantry',
        'meals',
        'essentials',
        'baby_supplies',
        'legal',
        'jobs_education',
        'financial_support',
        'transportation',
        'children_families',
        'disability',
        'seniors',
        'veterans',
      });
      expect(FacilityCategories.serviceTagKeys, hasLength(24));
    });

    test('Health Care holds hospitals and clinics, not mental health', () {
      final values = FacilityCategories.valuesForGroup(
        FacilityCategories.groupHealthCare,
      );
      expect(values, containsAll(['hospital', 'medical_clinic']));
      expect(values, isNot(contains('mental_health_care')));
    });

    test('every chip groups under its own Home group', () {
      for (final chip in FacilityCategories.serviceTagKeys) {
        expect(
          FacilityCategories.valuesForGroup(FacilityCategories.groupFor(chip)),
          contains(chip),
        );
      }
    });

    test('isGroup accepts group names and rejects chips and broad values', () {
      expect(
          FacilityCategories.isGroup(FacilityCategories.groupFamilyCommunity),
          isTrue);
      expect(FacilityCategories.isGroup(FacilityCategories.groupMoneyJobsLegal),
          isTrue);
      expect(FacilityCategories.isGroup('Medical Care'), isFalse);
      expect(FacilityCategories.isGroup('medical_clinic'), isFalse);
      expect(
          FacilityCategories.isGroup(FacilityCategories.groupOther), isFalse);
    });
  });

  group('FacilityCategories.matchesSelection', () {
    final housing = FacilityCategories.valuesForGroup(
      FacilityCategories.groupHousingShelter,
    ).toSet();

    test('nothing selected matches everything', () {
      expect(FacilityCategories.matchesSelection(const [], null, {}), isTrue);
    });

    test('a tagged facility matches any chip it carries, and only those', () {
      const tags = ['food_pantry', 'seniors'];
      expect(
        FacilityCategories.matchesSelection(tags, 'Basic Needs', {'seniors'}),
        isTrue,
      );
      expect(
        FacilityCategories.matchesSelection(tags, 'Basic Needs', {'meals'}),
        isFalse,
      );
    });

    test('an untagged facility matches its whole group, never one chip', () {
      expect(
        FacilityCategories.matchesSelection(const [], 'Housing', housing),
        isTrue,
      );
      expect(
        FacilityCategories.matchesSelection(
          const [],
          'Housing',
          {'emergency_shelter'},
        ),
        isFalse,
      );
      expect(
        FacilityCategories.matchesSelection(const [], null, housing),
        isFalse,
      );
    });
  });
}
