import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FacilityCategories.groupFor', () {
    test('hospitals consolidate to Health Care (except PSYCH)', () {
      expect(
        FacilityCategories.groupFor('Hospital- ACUTE'),
        FacilityCategories.groupHealthCare,
      );
      expect(
        FacilityCategories.groupFor('Hospital- REHAB'),
        FacilityCategories.groupHealthCare,
      );
      expect(
        FacilityCategories.groupFor('Nonprofit - Health Care'),
        FacilityCategories.groupHealthCare,
      );
    });

    test('psych / treatment / mental-health nonprofit map to Mental Health', () {
      expect(
        FacilityCategories.groupFor('Hospital- PSYCH'),
        FacilityCategories.groupMentalHealth,
      );
      expect(
        FacilityCategories.groupFor('Treatment Facility'),
        FacilityCategories.groupMentalHealth,
      );
      expect(
        FacilityCategories.groupFor(
          'Nonprofit - Mental Health and Crisis Intervention',
        ),
        FacilityCategories.groupMentalHealth,
      );
    });

    test('housing / human-services map to their groups', () {
      expect(
        FacilityCategories.groupFor('Nonprofit - Housing and Shelter'),
        FacilityCategories.groupHousingShelter,
      );
      expect(
        FacilityCategories.groupFor('Nonprofit - Human Services'),
        FacilityCategories.groupBasicNeeds,
      );
      expect(
        FacilityCategories.groupFor('Nonprofit - Public and Societal Benefit'),
        FacilityCategories.groupBasicNeeds,
      );
    });

    test('null / unknown falls back to the neutral group', () {
      expect(FacilityCategories.groupFor(null), FacilityCategories.groupOther);
      expect(
        FacilityCategories.groupFor('Something Else'),
        FacilityCategories.groupOther,
      );
    });
  });

  group('FacilityCategories.valuesForGroup', () {
    test('every level-2 value belongs to exactly one group', () {
      for (final value in FacilityCategories.categoryLevel2Values) {
        final group = FacilityCategories.groupFor(value);
        expect(FacilityCategories.valuesForGroup(group), contains(value));
      }
    });

    test('Health Care group includes acute hospitals and nonprofit health', () {
      final values = FacilityCategories.valuesForGroup(
        FacilityCategories.groupHealthCare,
      );
      expect(values, contains('Hospital- ACUTE'));
      expect(values, contains('Nonprofit - Health Care'));
      expect(values, isNot(contains('Hospital- PSYCH')));
    });
  });
}
