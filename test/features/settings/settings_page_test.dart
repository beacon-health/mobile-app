import 'package:beacon_app/core/services/coverage_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../helpers/app_shell.dart';
import '../../helpers/pump_app.dart';

void main() {
  final zipService = ZipCodeService();

  Future<void> pumpSettings(
    WidgetTester tester, {
    Set<String> installedUrlSchemes = const {},
    LocationPermission locationPermission = LocationPermission.denied,
    Locale locale = const Locale('en'),
  }) async {
    await resetAppState(
      tester,
      installedUrlSchemes: installedUrlSchemes,
      locationPermission: locationPermission,
    );
    CoverageService().debugSetStates(['IL', 'OK']);
    zipService.debugGeocode = (_) async => [
          Location(
            latitude: 36.154,
            longitude: -95.9928,
            timestamp: DateTime(2026),
          ),
        ];
    addTearDown(() => zipService.debugGeocode = null);
    await pumpThemed(tester, const SettingsPage(), locale: locale);
  }

  Future<void> saveZip(WidgetTester tester, String zip) async {
    await tester.tap(find.text('ZIP Code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), zip);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  group('ZIP code', () {
    testWidgets('shows the saved ZIP', (tester) async {
      await pumpSettings(tester);
      expect(find.text('60601'), findsOneWidget);
    });

    testWidgets('saves a ZIP in a launched state', (tester) async {
      await pumpSettings(tester);

      await saveZip(tester, '74103');

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('ZIP code updated'), findsOneWidget);
      expect(zipService.zipCode, '74103');
      expect(zipService.latitude, 36.154);
    });

    testWidgets('turns away a ZIP outside coverage and keeps the old one',
        (tester) async {
      await pumpSettings(tester);

      await saveZip(tester, '10001');

      // Still open, with the reason.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.textContaining('It currently covers Illinois and Oklahoma.'),
        findsOneWidget,
      );
      expect(zipService.zipCode, '60601');
    });

    testWidgets('a ZIP that does not exist says so', (tester) async {
      await pumpSettings(tester);

      await saveZip(tester, '00000');

      expect(
        find.text("Couldn't find that ZIP code. Try again."),
        findsOneWidget,
      );
      expect(zipService.zipCode, '60601');
    });
  });

  group('Use My Location', () {
    testWidgets('switching on stores the same label in every language',
        (tester) async {
      // In Spanish this used to store "Ubicación actual" as the ZIP, which
      // the next sign-in then tried, and failed, to look up.
      await pumpSettings(
        tester,
        locationPermission: LocationPermission.whileInUse,
        locale: const Locale('es'),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(zipService.locationSearchEnabled, isTrue);
      expect(zipService.zipCode, ZipCodeService.currentLocationSentinel);
      // What the user sees is still translated.
      expect(find.text('Ubicación actual'), findsOneWidget);
    });

    testWidgets('locks the ZIP row while it is on', (tester) async {
      await pumpSettings(
        tester,
        locationPermission: LocationPermission.whileInUse,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ZIP Code'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Current Location'), findsOneWidget);
    });

    testWidgets('switching off restores the earlier ZIP', (tester) async {
      await pumpSettings(
        tester,
        locationPermission: LocationPermission.whileInUse,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(zipService.locationSearchEnabled, isFalse);
      expect(zipService.zipCode, '60601');
      expect(find.text('60601'), findsOneWidget);
    });

    testWidgets('a refused permission leaves the app on the ZIP',
        (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(zipService.locationSearchEnabled, isFalse);
      expect(zipService.zipCode, '60601');
    });
  });

  group('Directions app', () {
    Future<List<String>> openPicker(WidgetTester tester) async {
      await tester.tap(find.text('Directions app'));
      await tester.pumpAndSettle();
      return [
        for (final tile in tester.widgetList<ListTile>(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(ListTile),
          ),
        ))
          (tile.title! as Text).data!,
      ];
    }

    testWidgets(
      'Android offers Google Maps and Waze, never Apple Maps',
      (tester) async {
        await pumpSettings(
          tester,
          installedUrlSchemes: {'google.navigation', 'waze'},
        );

        expect(
          await openPicker(tester),
          ['Google Maps', 'Waze', 'Ask each time'],
        );
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );

    testWidgets(
      'Android lists only what is installed',
      (tester) async {
        await pumpSettings(tester, installedUrlSchemes: {'google.navigation'});

        expect(await openPicker(tester), ['Google Maps', 'Ask each time']);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );

    testWidgets(
      'iOS always offers Apple Maps',
      (tester) async {
        await pumpSettings(tester, installedUrlSchemes: {'comgooglemaps'});

        expect(
          await openPicker(tester),
          ['Apple Maps', 'Google Maps', 'Ask each time'],
        );
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      'remembers the choice',
      (tester) async {
        await pumpSettings(
          tester,
          installedUrlSchemes: {'google.navigation', 'waze'},
        );
        expect(find.text('Ask each time'), findsOneWidget);

        await openPicker(tester);
        await tester.tap(find.text('Waze'));
        await tester.pumpAndSettle();

        expect(find.text('Waze'), findsOneWidget);
        expect(find.text('Ask each time'), findsNothing);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  });

  group('About', () {
    testWidgets('shows the version and the legal links', (tester) async {
      await pumpSettings(tester);

      expect(find.text('1.0.0'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
    });
  });
}
