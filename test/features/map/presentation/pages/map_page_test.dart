import 'dart:async';

import 'package:beacon_app/core/services/accessibility_settings.dart';
import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/pages/map_page.dart';
import 'package:beacon_app/features/map/presentation/services/marker_management_service.dart';
import 'package:beacon_app/features/map/presentation/widgets/facility/facility_card.dart';
import 'package:beacon_app/features/map/presentation/widgets/facility/facility_list_panel.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/components/filter_bar.dart';
import 'package:beacon_app/features/map/utils/map_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../helpers/app_shell.dart';
import '../../../../helpers/fake_google_maps.dart';
import '../../../../helpers/test_facility.dart';

/// The map page inside the real tab shell, over a fake map and data source.
void main() {
  // The user's saved location. The map opens on it at zoom 15, where the
  // view is about 1.4 km wide and 2.8 km tall.
  const home = LatLng(41.8850, -87.6220);

  LatLng offset(double north, double east) =>
      LatLng(home.latitude + north, home.longitude + east);

  // Distances from `home`: near 110 m, the twins 555 m, mid 710 m, far 3.3 km.
  final near = createTestFacility(
    id: 'near',
    name: 'Near Clinic',
    location: offset(0.0010, 0),
  );
  final mid = createTestFacility(
    id: 'mid',
    name: 'Mid Pantry',
    location: offset(0.0060, 0.0030),
  );
  final far = createTestFacility(
    id: 'far',
    name: 'Far Shelter',
    location: offset(0.0300, 0),
  );
  // Two programs at one street address — about one facility in ten is.
  final twinA = createTestFacility(
    id: 'twin-a',
    name: 'Twin A',
    location: offset(-0.0040, -0.0040),
  );
  final twinB = createTestFacility(
    id: 'twin-b',
    name: 'Twin B',
    location: offset(-0.0040, -0.0040),
  );
  final everything = [near, mid, far, twinA, twinB];

  late FakeFacilityRepository repository;
  late FakeGoogleMaps maps;
  late FakeMap map;

  Future<void> pumpMap(
    WidgetTester tester, {
    List<Facility>? facilities,
    LocationPermission locationPermission = LocationPermission.denied,
  }) async {
    await resetAppState(tester, locationPermission: locationPermission);
    await saveLocation(home);
    repository = FakeFacilityRepository(facilities ?? everything);
    maps = await pumpAppShell(tester, repository: repository);
    map = maps.mapStartingAtZoom(MapConstants.defaultZoom);
    await openTab(tester, 'Map');
  }

  List<String> listed(WidgetTester tester) => [
        for (final f in tester
            .widget<FacilityListPanel>(find.byType(FacilityListPanel))
            .facilities)
          f.id,
      ];

  Future<void> userMoves(
    WidgetTester tester,
    LatLng target,
    double zoom,
  ) async {
    maps.userMovesCamera(map, CameraPosition(target: target, zoom: zoom));
    await settle(tester);
  }

  Matcher isNear(LatLng point, {double meters = 30}) => predicate<LatLng>(
        (actual) => MapGeometry.distanceMeters(actual, point) <= meters,
        'within $meters m of $point',
      );

  group('the list follows the map', () {
    testWidgets('opens on the saved location, nearest first', (tester) async {
      await pumpMap(tester);

      expect(map.camera.target, isNear(home));
      expect(map.camera.zoom, MapConstants.detailZoom);
      // `far` is loaded and has a marker, but is off screen.
      expect(listed(tester), ['near', 'twin-a', 'twin-b', 'mid']);
      expect(find.text('4 resources in this area'), findsOneWidget);
    });

    testWidgets('re-sorts around the new center when the map moves',
        (tester) async {
      await pumpMap(tester);

      await userMoves(tester, mid.location, 15);

      expect(listed(tester).first, 'mid');
      expect(listed(tester), contains('near'));
    });

    testWidgets('drops what leaves the view and picks up what enters it',
        (tester) async {
      await pumpMap(tester);

      await userMoves(tester, far.location, 16);
      expect(listed(tester), ['far']);
      expect(find.text('1 resource in this area'), findsOneWidget);

      await userMoves(tester, home, 12);
      expect(listed(tester), hasLength(5));
    });

    testWidgets('says to zoom out when matches exist but none are on screen',
        (tester) async {
      await pumpMap(tester);

      // Open water, well away from every facility.
      await userMoves(tester, offset(0, 0.05), 17);

      expect(listed(tester), isEmpty);
      expect(find.text('Nothing in this part of the map'), findsOneWidget);
      // Not the "no facilities / request one" state: there are facilities.
      expect(find.text('No facilities in this area'), findsNothing);
    });

    testWidgets('says there are none when the area has none', (tester) async {
      await pumpMap(tester, facilities: []);

      expect(find.text('No facilities in this area'), findsOneWidget);
      expect(find.text('Nothing in this part of the map'), findsNothing);
    });

    testWidgets('a text search lists matches that are off screen',
        (tester) async {
      await pumpMap(tester);
      expect(listed(tester), isNot(contains('far')));

      await tester.enterText(find.byType(TextField), 'shelter');
      await settle(tester);

      expect(listed(tester), ['far']);
    });

    testWidgets('"Search this area" queries the map center, not the camera',
        (tester) async {
      await pumpMap(tester);
      final queriesBefore = repository.queries.length;

      // Panning alone never queries.
      await userMoves(tester, offset(0.05, 0), 13);
      expect(repository.queries, hasLength(queriesBefore));
      expect(find.text('Search this area'), findsOneWidget);

      repository.facilities = [
        createTestFacility(
          id: 'north',
          name: 'North Clinic',
          location: offset(0.05, 0),
        ),
      ];
      final animationsBefore = map.animations.length;
      await tester.tap(find.text('Search this area'));
      await settle(tester);

      expect(repository.queries.last, isNear(offset(0.05, 0)));
      expect(listed(tester), ['north']);
      expect(find.text('Search this area'), findsNothing);
      expect(map.animations, hasLength(animationsBefore));
    });
  });

  group('clusters', () {
    testWidgets(
        'facilities at one address stay a bubble until pins can fan out',
        (tester) async {
      await pumpMap(tester);

      // Zoom 15 draws pins individually, but two pins 25 m apart would sit
      // on top of each other there and read as one.
      expect(map.clusterMarkers, hasLength(1));
      expect(
        map.facilityMarkers.map((m) => m.markerId.value),
        unorderedEquals(['near', 'mid', 'far']),
      );
    });

    testWidgets('tapping a same-address bubble zooms to where the pins part',
        (tester) async {
      await pumpMap(tester);

      maps.tapMarker(map, map.clusterMarkers.single.markerId);
      await settle(tester);

      final revealZoom = MarkerManagementService.fanOutRevealZoom(
        twinA.location.latitude,
      );
      expect(map.camera.zoom, closeTo(revealZoom, 0.01));
      expect(map.clusterMarkers, isEmpty);
      final twins = [
        for (final m in map.facilityMarkers)
          if (m.markerId.value.startsWith('twin')) m.position,
      ];
      expect(twins, hasLength(2));
      expect(twins.first, isNot(twins.last));
      // And the list is down to what the bubble held.
      expect(listed(tester), ['twin-a', 'twin-b']);
    });

    testWidgets('tapping a cluster frames its members and lists them',
        (tester) async {
      await pumpMap(tester);
      await userMoves(tester, home, 11);

      // Whatever the grid made of them at this zoom, take the biggest group.
      final groups = MarkerManagementService.groupForZoom(everything, 11)
        ..sort((a, b) => b.length.compareTo(a.length));
      final members = groups.first;
      expect(members.length, greaterThan(1));
      final bubble = map.clusterMarkers.firstWhere(
        (m) => m.markerId.value.endsWith('_${members.length}'),
      );

      maps.tapMarker(map, bubble.markerId);
      await settle(tester);

      expect(map.camera.zoom, greaterThan(12));
      expect(listed(tester), containsAll(members.map((f) => f.id)));
      final visible = await maps.getVisibleRegion(mapId: map.mapId);
      for (final member in members) {
        expect(visible.contains(member.location), isTrue, reason: member.id);
      }
    });

    testWidgets('a refresh requested mid-refresh is not lost', (tester) async {
      await pumpMap(tester);

      // The first refresh is under way, having read zoom 11, when the camera
      // lands at zoom 18. That second request used to be dropped, leaving
      // zoom 11's clusters on a map that had moved on.
      map.zoomAnswerGate = Completer<void>();
      maps.userMovesCamera(map, const CameraPosition(target: home, zoom: 11));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      maps.userMovesCamera(
        map,
        CameraPosition(target: twinA.location, zoom: 18),
      );
      await tester.pump();
      map.zoomAnswerGate!.complete();
      map.zoomAnswerGate = null;
      await settle(tester);

      expect(map.clusterMarkers, isEmpty, reason: 'zoom 18 draws every pin');
      expect(map.facilityMarkers, hasLength(5));
    });
  });

  group('selecting a facility', () {
    testWidgets('a marker tap opens the card and brings the pin into view',
        (tester) async {
      await pumpMap(tester);

      maps.tapMarker(map, const MarkerId('mid'));
      await settle(tester);

      expect(find.byType(FacilityCard), findsOneWidget);
      expect(find.text('Mid Pantry'), findsOneWidget);
      expect(map.camera.zoom, MapConstants.markerZoom);
      // Centered in the strip above the card, so the camera itself points
      // south of the pin.
      expect(map.camera.target.latitude, lessThan(mid.location.latitude));
      expect(map.camera.target.longitude, mid.location.longitude);
    });

    testWidgets('closing the card returns the map to where it was',
        (tester) async {
      await pumpMap(tester);
      final before = map.camera;

      maps.tapMarker(map, const MarkerId('mid'));
      await settle(tester);
      expect(map.camera, isNot(before));

      await pressBack(tester);

      expect(map.camera, before);
      expect(listed(tester), ['near', 'twin-a', 'twin-b', 'mid']);
    });

    testWidgets('…unless the user moved the map while the card was open',
        (tester) async {
      await pumpMap(tester);

      maps.tapMarker(map, const MarkerId('mid'));
      await settle(tester);
      await userMoves(tester, far.location, 16);
      final animationsBefore = map.animations.length;

      await pressBack(tester);

      expect(map.animations, hasLength(animationsBefore));
      expect(map.camera.target, isNear(far.location));
      expect(listed(tester), ['far']);
    });

    testWidgets('expanding a row centers its pin without reshuffling the list',
        (tester) async {
      await pumpMap(tester);
      final before = map.camera;
      final orderBefore = listed(tester);

      await tester.tap(find.text('Near Clinic'));
      await settle(tester);

      expect(find.text('Directions'), findsOneWidget);
      expect(map.camera.zoom, 15, reason: 'never zooms out of a closer view');
      expect(map.camera.target, isNot(before.target));
      expect(listed(tester), orderBefore);

      await tester.tap(find.text('Near Clinic'));
      await settle(tester);

      expect(find.text('Directions'), findsNothing);
      expect(map.camera, before);
    });

    testWidgets('moving the map yourself closes the expanded row',
        (tester) async {
      await pumpMap(tester);

      await tester.tap(find.text('Near Clinic'));
      await settle(tester);
      await userMoves(tester, mid.location, 16);

      expect(find.text('Directions'), findsNothing);
      expect(listed(tester).first, 'mid');
    });

    testWidgets('tapping the map closes the card', (tester) async {
      await pumpMap(tester);

      maps.tapMarker(map, const MarkerId('near'));
      await settle(tester);
      maps.tapMap(map, home);
      await settle(tester);

      expect(find.byType(FacilityCard), findsNothing);
      expect(find.byType(FacilityListPanel), findsOneWidget);
    });
  });

  group('location', () {
    testWidgets('a new saved location reloads both maps and moves the camera',
        (tester) async {
      await pumpMap(tester);
      const springfield = LatLng(39.7817, -89.6501);
      repository.queries.clear();

      await saveLocation(springfield, zip: '62701');
      await settle(tester);

      // Home's map cutout and the Map tab each re-query. Home used to keep
      // showing the old area until the app was restarted.
      expect(
        repository.queries.where((q) => q == springfield),
        hasLength(2),
      );
      expect(map.camera.target, springfield);
      expect(maps.mapStartingAtZoom(14).camera.target, springfield);
    });

    testWidgets('the blue dot shows only in GPS mode', (tester) async {
      await pumpMap(tester, locationPermission: LocationPermission.whileInUse);
      final homeMap = maps.mapStartingAtZoom(MapConstants.homeCutoutZoom);

      // Permission is granted, but the user chose a ZIP.
      expect(map.configuration.myLocationEnabled, isFalse);
      expect(homeMap.configuration.myLocationEnabled, isFalse);

      await ZipCodeService().setCurrentLocation(
        latitude: 41.9,
        longitude: -87.65,
        syncToCloud: false,
      );
      await settle(tester);
      expect(map.configuration.myLocationEnabled, isTrue);
      expect(homeMap.configuration.myLocationEnabled, isTrue);

      await ZipCodeService().disableLocationSearch(syncToCloud: false);
      await settle(tester);
      expect(map.configuration.myLocationEnabled, isFalse);
      expect(homeMap.configuration.myLocationEnabled, isFalse);
    });

    testWidgets('no dot in GPS mode without permission', (tester) async {
      await pumpMap(tester);

      await ZipCodeService().setCurrentLocation(
        latitude: 41.9,
        longitude: -87.65,
        syncToCloud: false,
      );
      await settle(tester);

      expect(map.configuration.myLocationEnabled, isFalse);
    });
  });

  group('guests', () {
    testWidgets('locked chips prompt for sign-in and change nothing',
        (tester) async {
      await pumpMap(tester);

      for (final chip in ['Favorites', 'Preferences']) {
        // The chip row scrolls sideways; Preferences starts off screen.
        await tester.scrollUntilVisible(
          find.text(chip),
          100,
          scrollable: find.descendant(
            of: find.byType(FilterBar),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(chip));
        await settle(tester);
        expect(find.byType(Dialog), findsOneWidget, reason: chip);
        await pressBack(tester);
      }

      expect(listed(tester), hasLength(4));
    });

    testWidgets('the filter pane cannot empty the list through Favorites',
        (tester) async {
      await pumpMap(tester);

      await tester.tap(find.text('Filters'));
      await settle(tester);
      await tester.tap(find.text('Favorites').last);
      await settle(tester);
      // The prompt, not a toggle.
      expect(find.byType(Dialog), findsOneWidget);
      await pressBack(tester);

      // The button counts everything loaded: all five, one of them off
      // screen.
      await tester.tap(find.text('Show 5 results'));
      await settle(tester);

      expect(listed(tester), hasLength(4));
    });

    testWidgets('a heart offers sign-in and saves nothing', (tester) async {
      // It used to be greyed out, as if broken.
      await pumpMap(tester);

      await tester.tap(find.byTooltip('Save Near Clinic'));
      await settle(tester);

      expect(find.byType(Dialog), findsOneWidget);
      await pressBack(tester);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });
  });

  group('favorites (signed in)', () {
    testWidgets('a heart tapped in the list shows at once and filters',
        (tester) async {
      await resetAppState(tester);
      await saveLocation(home);
      GuestModeService().debugUser = testUser();
      repository = FakeFacilityRepository(everything);
      maps = await pumpAppShell(
        tester,
        repository: repository,
        home: const MapPage(),
      );
      map = maps.mapStartingAtZoom(MapConstants.defaultZoom);

      await tester.tap(find.byTooltip('Save Near Clinic'));
      await settle(tester);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byTooltip('Remove Near Clinic from favorites'), findsOne);

      await tester.ensureVisible(find.text('Favorites'));
      await tester.tap(find.text('Favorites'));
      await settle(tester);

      expect(listed(tester), ['near']);
    });
  });

  group('eligibility', () {
    final needsReferral = createTestFacility(
      id: 'referral',
      name: 'Referral Clinic',
      location: offset(0.0020, 0),
      eligibilityRequirements: {'referral_required': true},
    );
    final noReferral = createTestFacility(
      id: 'walk-in',
      name: 'Walk-in Clinic',
      location: offset(0.0030, 0),
      eligibilityRequirements: {'referral_required': false},
    );

    Future<void> setEligibility(
      WidgetTester tester,
      EligibilityState state,
    ) async {
      await EligibilityPreferencesService()
          .updateEligibility(state, syncToCloud: false);
      await settle(tester);
    }

    Future<void> pumpSignedIn(WidgetTester tester) async {
      await resetAppState(tester);
      await saveLocation(home);
      GuestModeService().debugUser = testUser();
      repository = FakeFacilityRepository([needsReferral, noReferral]);
      maps = await pumpAppShell(
        tester,
        repository: repository,
        home: const MapPage(),
      );
      map = maps.mapStartingAtZoom(MapConstants.defaultZoom);
    }

    testWidgets('an unchecked box hides what requires it; checked shows it too',
        (tester) async {
      await pumpSignedIn(tester);

      // Answered, with nothing checked: "I don't have a referral".
      await setEligibility(
        tester,
        const EligibilityState(applyToSearch: true),
      );
      expect(listed(tester), ['walk-in']);

      // Checking it adds the facility that asks for a referral and keeps the
      // one that doesn't.
      await setEligibility(
        tester,
        const EligibilityState(referralRequired: true, applyToSearch: true),
      );
      expect(listed(tester), ['referral', 'walk-in']);

      await setEligibility(tester, const EligibilityState());
      expect(listed(tester), ['referral', 'walk-in']);
    });

    testWidgets('nothing is hidden from someone who has not answered',
        (tester) async {
      // Neither a guest nor a new account: unchecked boxes mean "I don't have
      // it" only once the person has been asked.
      await pumpMap(tester, facilities: [needsReferral, noReferral]);
      expect(listed(tester), ['referral', 'walk-in']);

      await pumpSignedIn(tester);
      expect(listed(tester), ['referral', 'walk-in']);
    });

    testWidgets("a guest's answers filter the map too", (tester) async {
      // Guests can give and change them on Profile now, so they apply.
      await pumpMap(tester, facilities: [needsReferral, noReferral]);

      await setEligibility(
        tester,
        const EligibilityState(applyToSearch: true),
      );
      expect(listed(tester), ['walk-in']);

      await setEligibility(
        tester,
        const EligibilityState(referralRequired: true, applyToSearch: true),
      );
      expect(listed(tester), ['referral', 'walk-in']);
    });
  });

  group('the facility sheet', () {
    testWidgets('a tapped pin opens the same full-width sheet as the list',
        (tester) async {
      // It used to be an inset floating card: a second surface for the same
      // facility.
      await pumpMap(tester);
      final listWidth = tester.getSize(find.byType(FacilityListPanel)).width;

      maps.tapMarker(map, const MarkerId('near'));
      await settle(tester);

      final sheet = tester.getRect(find.byType(FacilityCard));
      expect(sheet.left, 0);
      expect(sheet.width, listWidth);
      // Directions sits under the name, above everything else.
      expect(
        tester.getTopLeft(find.text('Directions')).dy,
        lessThan(tester.getTopLeft(find.text('Services')).dy),
      );
    });
  });

  group('accessibility settings', () {
    testWidgets('"Open Map as a list" starts with the list raised',
        (tester) async {
      await resetAppState(tester);
      await saveLocation(home);
      await AccessibilitySettings().setOpenMapAsList(true);
      repository = FakeFacilityRepository(everything);
      maps = await pumpAppShell(tester, repository: repository);
      await openTab(tester, 'Map');

      final panel =
          tester.widget<FacilityListPanel>(find.byType(FacilityListPanel));
      expect(panel.isFullyExpanded, isTrue);
      // Still one back press from the map.
      await pressBack(tester);
      expect(
        tester
            .widget<FacilityListPanel>(find.byType(FacilityListPanel))
            .isFullyExpanded,
        isFalse,
      );
    });

    testWidgets('with motion reduced the camera cuts instead of flying',
        (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpMap(tester);
      final flights = map.animations.length;
      final before = map.camera;

      maps.tapMarker(map, const MarkerId('near'));
      await settle(tester);

      expect(map.camera, isNot(before));
      expect(map.animations, hasLength(flights));
      expect(find.byType(FacilityCard), findsOneWidget);
    });
  });

  group('mapBackTarget', () {
    test('closes the innermost open layer first', () {
      MapBackTarget target({
        bool card = false,
        bool row = false,
        bool search = false,
        bool panel = false,
      }) =>
          mapBackTarget(
            cardOpen: card,
            rowExpanded: row,
            hasSearchText: search,
            panelFullyExpanded: panel,
          );

      expect(target(), MapBackTarget.nothing);
      expect(target(search: true), MapBackTarget.searchText);
      // A raised list comes down before the search that filled it is cleared.
      expect(target(panel: true, search: true), MapBackTarget.expandedPanel);
      expect(
        target(panel: true, search: true, row: true),
        MapBackTarget.expandedRow,
      );
      expect(
        target(panel: true, search: true, row: true, card: true),
        MapBackTarget.facilityCard,
      );
    });
  });
}
