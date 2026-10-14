import 'package:beacon_app/features/home/presentation/widgets/main_nav_bar.dart';
import 'package:beacon_app/features/map/presentation/widgets/facility/facility_list_panel.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/components/filter_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../helpers/app_shell.dart';
import '../../../../helpers/fake_google_maps.dart';
import '../../../../helpers/test_facility.dart';

/// Android's back button against the real tab shell. None of the tabs, nor
/// anything the map opens over itself, is a route, so the framework's default
/// ("pop a route, else leave the app") closed the app from everywhere. These
/// tests press back in each state a person can be in.
void main() {
  // Saved location a little off the map's built-in default, so the map goes
  // to it on creation exactly as it does for a real user.
  const home = LatLng(41.8850, -87.6220);

  final facilities = [
    createTestFacility(
      id: 'near',
      name: 'Near Clinic',
      location: LatLng(home.latitude + 0.0010, home.longitude),
    ),
    createTestFacility(
      id: 'mid',
      name: 'Mid Pantry',
      location: LatLng(home.latitude + 0.0060, home.longitude + 0.0030),
    ),
  ];

  late PlatformLog platform;
  late FakeGoogleMaps maps;
  late FakeMap map;

  Future<void> pumpShell(WidgetTester tester) async {
    platform = await resetAppState(tester);
    await saveLocation(home);
    maps = await pumpAppShell(
      tester,
      repository: FakeFacilityRepository(facilities),
    );
    map = maps.mapStartingAtZoom(12);
  }

  double panelHeight(WidgetTester tester) =>
      tester.getSize(find.byType(FacilityListPanel)).height;

  testWidgets('back on Home leaves the app', (tester) async {
    await pumpShell(tester);
    expect(selectedTab(tester), NavTab.home);

    await pressBack(tester);

    expect(platform.exits, 1);
  });

  testWidgets('back on any other tab returns to Home instead of leaving',
      (tester) async {
    await pumpShell(tester);

    for (final label in ['Map', 'Profile', 'Settings']) {
      await openTab(tester, label);
      expect(selectedTab(tester), isNot(NavTab.home), reason: label);

      await pressBack(tester);

      expect(selectedTab(tester), NavTab.home, reason: label);
      expect(platform.exits, 0, reason: label);
    }
  });

  testWidgets('tells Android when it will take the back button',
      (tester) async {
    // Predictive back asks this up front; a wrong answer sends the press to
    // the launcher without the app ever hearing about it.
    await pumpShell(tester);
    // "No" is the platform's starting assumption, so nothing is sent for it.
    expect(platform.frameworkHandlesBack, isNot(true), reason: 'Home');

    await openTab(tester, 'Map');
    expect(platform.frameworkHandlesBack, isTrue, reason: 'Map');

    await pressBack(tester);
    expect(platform.frameworkHandlesBack, isFalse, reason: 'Home again');
  });

  testWidgets('back closes an open facility card, then leaves the map',
      (tester) async {
    await pumpShell(tester);
    await openTab(tester, 'Map');

    maps.tapMarker(map, const MarkerId('near'));
    await settle(tester);
    expect(find.text('Directions'), findsOneWidget);
    expect(find.byType(FacilityListPanel), findsNothing);

    await pressBack(tester);

    expect(find.text('Directions'), findsNothing);
    expect(find.byType(FacilityListPanel), findsOneWidget);
    expect(selectedTab(tester), NavTab.map);

    await pressBack(tester);
    expect(selectedTab(tester), NavTab.home);
    expect(platform.exits, 0);
  });

  testWidgets('back collapses an expanded list row', (tester) async {
    await pumpShell(tester);
    await openTab(tester, 'Map');

    await tester.tap(find.text('Near Clinic'));
    await settle(tester);
    expect(find.text('Directions'), findsOneWidget);

    await pressBack(tester);

    expect(find.text('Directions'), findsNothing);
    expect(selectedTab(tester), NavTab.map);
  });

  testWidgets('back clears a search', (tester) async {
    await pumpShell(tester);
    await openTab(tester, 'Map');

    await tester.enterText(find.byType(TextField), 'pantry');
    await settle(tester);
    expect(find.text('Near Clinic'), findsNothing);

    await pressBack(tester);

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('Near Clinic'), findsOneWidget);
    expect(selectedTab(tester), NavTab.map);
  });

  testWidgets('back lowers a raised list', (tester) async {
    await pumpShell(tester);
    await openTab(tester, 'Map');
    final resting = panelHeight(tester);

    await tester.fling(
      find.text('2 resources in this area'),
      const Offset(0, -200),
      1500,
    );
    await settle(tester);
    expect(panelHeight(tester), greaterThan(resting));

    await pressBack(tester);

    expect(panelHeight(tester), resting);
    expect(selectedTab(tester), NavTab.map);
  });

  testWidgets('back lowers a raised list before it clears the search',
      (tester) async {
    // One press must not cost both the view and the typed text.
    await pumpShell(tester);
    await openTab(tester, 'Map');
    final resting = panelHeight(tester);
    String searchText() =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;

    await tester.enterText(find.byType(TextField), 'clinic');
    await settle(tester);
    // The list can only be raised once the keyboard is out of the way.
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(tester);
    await tester.fling(
      find.textContaining('in this area'),
      const Offset(0, -200),
      1500,
    );
    await settle(tester);
    expect(panelHeight(tester), greaterThan(resting));

    await pressBack(tester);
    expect(panelHeight(tester), resting);
    expect(searchText(), 'clinic');

    await pressBack(tester);
    expect(searchText(), isEmpty);
    expect(selectedTab(tester), NavTab.map);
  });

  testWidgets('back closes the filter sheet and stays on the map',
      (tester) async {
    await pumpShell(tester);
    await openTab(tester, 'Map');

    // The button that opens every filter says what it is.
    await tester.tap(find.text('Filters'));
    await settle(tester);
    expect(find.byType(FilterModal), findsOneWidget);

    await pressBack(tester);

    expect(find.byType(FilterModal), findsNothing);
    expect(selectedTab(tester), NavTab.map);
    expect(platform.exits, 0);
  });

  testWidgets('back closes a dialog and stays on the map', (tester) async {
    await pumpShell(tester);
    await openTab(tester, 'Map');

    // A guest tapping the locked Favorites chip gets the sign-in prompt.
    await tester.ensureVisible(find.text('Favorites'));
    await tester.tap(find.text('Favorites'));
    await settle(tester);
    expect(find.byType(Dialog), findsOneWidget);

    await pressBack(tester);

    expect(find.byType(Dialog), findsNothing);
    expect(selectedTab(tester), NavTab.map);
  });

  testWidgets('each press undoes one layer, innermost first', (tester) async {
    await pumpShell(tester);
    await openTab(tester, 'Map');

    await tester.enterText(find.byType(TextField), 'clinic');
    await settle(tester);
    await tester.tap(find.text('Near Clinic'));
    await settle(tester);
    expect(find.text('Directions'), findsOneWidget);

    await pressBack(tester); // the expanded row
    expect(find.text('Directions'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'clinic',
    );

    await pressBack(tester); // the search
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );

    await pressBack(tester); // the tab
    expect(selectedTab(tester), NavTab.home);

    await pressBack(tester); // the app
    expect(platform.exits, 1);
  });

  testWidgets('tapping a tab switches to it', (tester) async {
    await pumpShell(tester);

    await openTab(tester, 'Settings');
    expect(selectedTab(tester), NavTab.settings);
    expect(find.text('Directions app'), findsOneWidget);

    await openTab(tester, 'Profile');
    expect(selectedTab(tester), NavTab.profile);

    await openTab(tester, 'Map');
    expect(selectedTab(tester), NavTab.map);
    expect(find.byType(FacilityListPanel), findsOneWidget);
  });
}
