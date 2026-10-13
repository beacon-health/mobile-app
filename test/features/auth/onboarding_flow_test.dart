import 'package:beacon_app/core/services/coverage_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/features/auth/presentation/pages/location_choice_page.dart';
import 'package:beacon_app/features/auth/presentation/pages/login_page.dart';
import 'package:beacon_app/features/auth/presentation/pages/zip_entry_page.dart';
import 'package:beacon_app/features/auth/presentation/widgets/auth_gate.dart';
import 'package:beacon_app/features/home/presentation/widgets/main_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../helpers/app_shell.dart';
import '../../helpers/test_facility.dart';

/// First run, from the login screen to the tabs, as a guest.
void main() {
  const tulsa = LatLng(36.1540, -95.9928);
  final zipService = ZipCodeService();
  late FakeFacilityRepository repository;

  Future<void> pumpFirstRun(
    WidgetTester tester, {
    LocationPermission locationPermission = LocationPermission.denied,
  }) async {
    await resetAppState(tester, locationPermission: locationPermission);
    await zipService.clear();
    CoverageService().debugSetStates(['IL', 'OK']);
    zipService.debugGeocode = (_) async => [
          Location(
            latitude: tulsa.latitude,
            longitude: tulsa.longitude,
            timestamp: DateTime(2026),
          ),
        ];
    addTearDown(() => zipService.debugGeocode = null);
    repository = FakeFacilityRepository([
      createTestFacility(id: 'a', name: 'Tulsa Clinic', location: tulsa),
    ]);
    await pumpAppShell(
      tester,
      repository: repository,
      home: const AuthGate(),
    );
  }

  Future<void> continueAsGuest(WidgetTester tester) async {
    await tester.tap(find.text('Continue as Guest'));
    await settle(tester);
  }

  Future<void> enterZip(WidgetTester tester, String zip) async {
    await tester.enterText(find.byType(TextFormField), zip);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await settle(tester);
  }

  testWidgets('a first run starts at login', (tester) async {
    await pumpFirstRun(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(MainNavBar), findsNothing);
  });

  testWidgets('a returning user goes straight to the tabs', (tester) async {
    await resetAppState(tester);
    await pumpAppShell(
      tester,
      repository: FakeFacilityRepository(),
      home: const AuthGate(),
    );

    expect(find.byType(MainNavBar), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('a guest can onboard with a ZIP in a launched state',
      (tester) async {
    await pumpFirstRun(tester);

    await continueAsGuest(tester);
    expect(find.byType(LocationChoicePage), findsOneWidget);
    expect(
      find.textContaining('facilities in Illinois and Oklahoma.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Enter Zip Code'));
    await settle(tester);
    await enterZip(tester, '74103');

    expect(find.byType(MainNavBar), findsOneWidget);
    expect(zipService.zipCode, '74103');
    expect(zipService.hasCompletedOnboarding, isTrue);
    expect(zipService.locationSearchEnabled, isFalse);
    // Home and Map both load around the ZIP.
    expect(repository.queries, everyElement(tulsa));
    expect(repository.queries, isNotEmpty);
  });

  testWidgets('a ZIP outside coverage stops at the ZIP screen', (tester) async {
    await pumpFirstRun(tester);
    await continueAsGuest(tester);
    await tester.tap(find.text('Enter Zip Code'));
    await settle(tester);

    await enterZip(tester, '90001');

    expect(find.byType(ZipEntryPage), findsOneWidget);
    expect(find.byType(MainNavBar), findsNothing);
    expect(
      find.textContaining('It currently covers Illinois and Oklahoma.'),
      findsOneWidget,
    );
    expect(zipService.hasCompletedOnboarding, isFalse);
    expect(repository.queries, isEmpty);

    // …and a covered one, typed next, still gets through.
    await enterZip(tester, '74103');
    expect(find.byType(MainNavBar), findsOneWidget);
  });

  testWidgets('choosing GPS with permission skips the ZIP screen',
      (tester) async {
    await pumpFirstRun(
      tester,
      locationPermission: LocationPermission.whileInUse,
    );
    await continueAsGuest(tester);

    await tester.tap(find.text('Location-Based Search'));
    await settle(tester);

    expect(find.byType(MainNavBar), findsOneWidget);
    expect(zipService.locationSearchEnabled, isTrue);
    expect(zipService.zipCode, ZipCodeService.currentLocationSentinel);
    // Where the fake GPS says the device is.
    expect(zipService.latitude, 41.9);
  });

  testWidgets('choosing GPS without permission falls back to the ZIP screen',
      (tester) async {
    await pumpFirstRun(tester);
    await continueAsGuest(tester);

    await tester.tap(find.text('Location-Based Search'));
    await settle(tester);

    expect(find.byType(ZipEntryPage), findsOneWidget);
    expect(zipService.locationSearchEnabled, isFalse);
  });

  testWidgets('back on the ZIP screen returns to the location choice',
      (tester) async {
    final platform = await resetAppState(tester);
    await zipService.clear();
    await pumpAppShell(
      tester,
      repository: FakeFacilityRepository(),
      home: const AuthGate(),
    );
    await continueAsGuest(tester);
    await tester.tap(find.text('Enter Zip Code'));
    await settle(tester);
    expect(find.byType(ZipEntryPage), findsOneWidget);

    await pressBack(tester);

    expect(find.byType(ZipEntryPage), findsNothing);
    expect(find.byType(LocationChoicePage), findsOneWidget);
    expect(platform.exits, 0);
  });
}
