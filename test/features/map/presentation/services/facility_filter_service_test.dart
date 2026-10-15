import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/services/facility_filter_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../helpers/test_facility.dart';

void main() {
  group('FacilityFilterService.filterFacilities', () {
    final facilities = [
      createTestFacility(
        id: '1',
        name: 'Free Clinic',
        categoryBroad: 'Medical Care',
      ),
      createTestFacility(
        id: '2',
        name: 'Food Pantry A',
        serviceTags: const ['food_pantry', 'jobs_education'],
        categoryBroad: 'Community Services',
      ),
      createTestFacility(
        id: '3',
        name: 'Shelter B',
        categoryBroad: 'Housing',
      ),
      createTestFacility(
        id: '4',
        name: 'Mental Health Center',
        categoryBroad: 'Mental Health',
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

    test('filters by chip: every chip a facility carries matches', () {
      for (final chip in ['food_pantry', 'jobs_education']) {
        final result = FacilityFilterService.filterFacilities(
          facilities,
          searchText: '',
          selectedCategories: {chip},
          showFavoritesOnly: false,
          showOpenNowOnly: false,
        );
        expect(result.map((f) => f.id), ['2'], reason: chip);
      }
    });

    test('an untagged facility matches a whole group, not a single chip', () {
      List<String> ids(Set<String> chips) => FacilityFilterService
          .filterFacilities(
            facilities,
            searchText: '',
            selectedCategories: chips,
            showFavoritesOnly: false,
            showOpenNowOnly: false,
          )
          .map((f) => f.id)
          .toList();
      // Shelter B has no tags yet; category_broad 'Housing'.
      expect(ids({'emergency_shelter'}), isEmpty);
      expect(
        ids(FacilityCategories.valuesForGroup(
          FacilityCategories.groupHousingShelter,
        ).toSet()),
        ['3'],
      );
    });

    test('search matches a chip name', () {
      final result = FacilityFilterService.filterFacilities(
        facilities,
        searchText: 'jobs & education',
        selectedCategories: {},
        showFavoritesOnly: false,
        showOpenNowOnly: false,
      );
      expect(result.map((f) => f.id), ['2']);
    });

    test('filters by category', () {
      final result = FacilityFilterService.filterFacilities(
        facilities,
        searchText: '',
        selectedCategories: {'food_pantry'},
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
        selectedCategories: {'food_pantry'},
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

  group('FacilityFilterService.filterFacilities eligibility gates', () {
    final acceptsMedicaid = createTestFacility(
      id: 'yes',
      eligibilityRequirements: {'accepts_medicaid': true},
    );
    final refusesMedicaid = createTestFacility(
      id: 'no',
      eligibilityRequirements: {'accepts_medicaid': false},
    );
    final unknown = createTestFacility(id: 'unknown');

    List<String> filter(Map<EligibilityRequirement, bool?> gates) => [
          for (final f in FacilityFilterService.filterFacilities(
            [acceptsMedicaid, refusesMedicaid, unknown],
            searchText: '',
            selectedCategories: {},
            selectedEligibilityRequirements: gates,
            showFavoritesOnly: false,
            showOpenNowOnly: false,
          ))
            f.id,
        ];

    test('the Medicaid gate drops facilities known not to accept it', () {
      // Unknown passes, as it does for every gate: most facilities have no
      // answer on file, and hiding them would hide most of the map.
      expect(
        filter({EligibilityRequirement.acceptsMedicaid: true}),
        ['yes', 'unknown'],
      );
    });

    test('with the gate off nothing is filtered', () {
      expect(filter({}), ['yes', 'no', 'unknown']);
      expect(
        filter({EligibilityRequirement.acceptsMedicaid: null}),
        ['yes', 'no', 'unknown'],
      );
    });

    test('every gate maps to a facility column', () {
      expect(
        {for (final gate in EligibilityRequirement.values) gate.fieldKey},
        {
          'proof_of_income',
          'proof_of_residency',
          'insurance_required',
          'referral_required',
          'accepts_medicaid',
        },
      );
      expect(
        FilterConstants.eligibilityRequirements,
        EligibilityRequirement.values,
      );
    });
  });

  group('FacilityFilterService.eligibilityGates', () {
    // One facility per answer on file, for each "required" column.
    const requiredColumns = {
      'proof_of_income',
      'proof_of_residency',
      'insurance_required',
      'referral_required',
    };

    EligibilityState allOn({bool applyToSearch = true}) => EligibilityState(
          proofOfIncome: true,
          proofOfResidency: true,
          insuranceRequired: true,
          referralRequired: true,
          applyToSearch: applyToSearch,
        );

    List<String> shown(EligibilityState state, String column) => [
          for (final f in FacilityFilterService.filterFacilities(
            [
              createTestFacility(
                id: 'requires',
                eligibilityRequirements: {column: true},
              ),
              createTestFacility(
                id: 'open',
                eligibilityRequirements: {column: false},
              ),
              createTestFacility(id: 'unknown'),
            ],
            searchText: '',
            selectedCategories: {},
            selectedEligibilityRequirements:
                FacilityFilterService.eligibilityGates(state),
            showFavoritesOnly: false,
            showOpenNowOnly: false,
          ))
            f.id,
        ];

    test('a checked box hides nothing', () {
      // Having insurance used to hide every facility that doesn't require
      // it — most of the map.
      for (final column in requiredColumns) {
        expect(
          shown(allOn(), column),
          ['requires', 'open', 'unknown'],
          reason: column,
        );
      }
    });

    test('an unchecked box hides only what requires it', () {
      for (final column in requiredColumns) {
        expect(
          shown(const EligibilityState(applyToSearch: true), column),
          ['open', 'unknown'],
          reason: column,
        );
      }
    });

    test('someone who never answered has nothing hidden', () {
      // The state of a fresh install, and of a guest who skipped the step.
      for (final column in [...requiredColumns, 'accepts_medicaid']) {
        expect(
          shown(const EligibilityState(), column),
          ['requires', 'open', 'unknown'],
          reason: column,
        );
      }
    });

    test('each switch gates its own column and no other', () {
      final gates = FacilityFilterService.eligibilityGates(
        allOn().copyWith(referralRequired: false),
      );
      expect(gates, {EligibilityRequirement.referralRequired: false});
    });

    test('Medicaid filters only when switched on, and only known refusals', () {
      expect(
          shown(allOn(), 'accepts_medicaid'), ['requires', 'open', 'unknown']);
      expect(
        shown(allOn().copyWith(acceptsMedicaid: true), 'accepts_medicaid'),
        ['requires', 'unknown'],
      );
    });

    test('nothing is gated when eligibility is not applied to search', () {
      expect(
        FacilityFilterService.eligibilityGates(
          const EligibilityState(acceptsMedicaid: true, applyToSearch: false),
        ),
        isEmpty,
      );
    });
  });

  group('FacilityFilterService.nearestFirst', () {
    const center = LatLng(41.8781, -87.6298);
    Facility at(String id, double north, {String? name}) => createTestFacility(
          id: id,
          name: name ?? id,
          location: LatLng(center.latitude + north, center.longitude),
        );

    final close = at('close', 0.001);
    final middle = at('middle', 0.005);
    final distant = at('distant', 0.05);
    final view = LatLngBounds(
      southwest: LatLng(center.latitude - 0.01, center.longitude - 0.01),
      northeast: LatLng(center.latitude + 0.01, center.longitude + 0.01),
    );

    List<String> ids(List<Facility> list) => [for (final f in list) f.id];

    test('sorts by distance from the center', () {
      expect(
        ids(
          FacilityFilterService.nearestFirst(
            [distant, close, middle],
            center: center,
          ),
        ),
        ['close', 'middle', 'distant'],
      );
    });

    test('keeps only what is inside the view', () {
      expect(
        ids(
          FacilityFilterService.nearestFirst(
            [distant, close, middle],
            center: center,
            within: view,
          ),
        ),
        ['close', 'middle'],
      );
    });

    test('sorts from wherever the center is, not from the view', () {
      expect(
        ids(
          FacilityFilterService.nearestFirst(
            [close, middle],
            center: middle.location,
            within: view,
          ),
        ),
        ['middle', 'close'],
      );
    });

    test('before the map reports a view, order and contents are untouched', () {
      expect(
        ids(
          FacilityFilterService.nearestFirst(
            [distant, close, middle],
            center: null,
          ),
        ),
        ['distant', 'close', 'middle'],
      );
    });

    test('facilities at one address keep a stable order', () {
      final zebra = at('2', 0.002, name: 'Zebra House');
      final apple = at('1', 0.002, name: 'Apple House');
      final appleTwin = at('0', 0.002, name: 'Apple House');

      for (final input in [
        [zebra, apple, appleTwin],
        [appleTwin, zebra, apple],
      ]) {
        expect(
          ids(FacilityFilterService.nearestFirst(input, center: center)),
          ['0', '1', '2'],
        );
      }
    });

    test('returns a new list, leaving the input alone', () {
      final input = [distant, close];
      final output = FacilityFilterService.nearestFirst(input, center: center);
      expect(ids(input), ['distant', 'close']);
      expect(identical(input, output), isFalse);
    });
  });

  group('FacilityFilterService.getAvailableCategories', () {
    test('returns the unique chips present', () {
      final facilities = [
        createTestFacility(serviceTags: const ['medical_clinic']),
        createTestFacility(
          serviceTags: const ['medical_clinic', 'dental_vision'],
        ),
        createTestFacility(categoryBroad: 'Addiction Recovery'),
      ];
      final categories =
          FacilityFilterService.getAvailableCategories(facilities);
      expect(categories, {'medical_clinic', 'dental_vision'});
    });
  });
}
