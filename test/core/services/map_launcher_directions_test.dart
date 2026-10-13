import 'package:beacon_app/core/services/map_launcher_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_shell.dart';
import '../../helpers/pump_app.dart';

/// "Get directions", start to finish, on each platform. On Android this
/// offered Apple Maps and nothing else.
void main() {
  const address = '35 E Wacker Dr, Chicago, IL 60601';
  late PlatformLog platform;

  Future<void> getDirections(
    WidgetTester tester, {
    required Set<String> installed,
    Set<String> unlaunchable = const {},
  }) async {
    platform = await resetAppState(tester, installedUrlSchemes: installed);
    platform.unlaunchableSchemes.addAll(unlaunchable);
    await pumpThemed(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => MapLauncherService.openDirections(
              context,
              address: address,
            ),
            child: const Text('Get directions'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Get directions'));
    await tester.pumpAndSettle();
  }

  Uri launched() => Uri.parse(platform.launchedUrls.single);

  final android = TargetPlatformVariant.only(TargetPlatform.android);
  final iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

  group('Android', () {
    testWidgets(
      'with only Google Maps installed, opens it without asking',
      (tester) async {
        await getDirections(tester, installed: {'google.navigation'});

        expect(find.byType(BottomSheet), findsNothing);
        expect(launched().host, 'www.google.com');
        expect(launched().path, '/maps/dir/');
        expect(launched().queryParameters['destination'], address);
      },
      variant: android,
    );

    testWidgets(
      'with two map apps, asks once and remembers the answer',
      (tester) async {
        await getDirections(tester, installed: {'google.navigation', 'waze'});

        expect(find.text('Open directions with'), findsOneWidget);
        expect(find.text('Apple Maps'), findsNothing);
        expect(find.text('Google Maps'), findsOneWidget);

        await tester.tap(find.text('Waze'));
        await tester.pumpAndSettle();
        expect(launched().scheme, 'waze');
        expect(launched().queryParameters['q'], address);

        // Second time: straight to Waze.
        await tester.tap(find.text('Get directions'));
        await tester.pumpAndSettle();
        expect(find.text('Open directions with'), findsNothing);
        expect(platform.launchedUrls, hasLength(2));
        expect(Uri.parse(platform.launchedUrls.last).scheme, 'waze');
      },
      variant: android,
    );

    testWidgets(
      'dismissing the chooser opens nothing and remembers nothing',
      (tester) async {
        await getDirections(tester, installed: {'google.navigation', 'waze'});

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(platform.launchedUrls, isEmpty);
        expect(await MapLauncherService.preferredApp(), isNull);
      },
      variant: android,
    );

    testWidgets(
      'with no known map app, hands the address to whatever handles geo:',
      (tester) async {
        await getDirections(tester, installed: {});

        expect(launched().scheme, 'geo');
        expect(find.byType(SnackBar), findsNothing);
      },
      variant: android,
    );

    testWidgets(
      'falls back to the browser when nothing handles geo: either',
      (tester) async {
        await getDirections(tester, installed: {}, unlaunchable: {'geo'});

        expect(platform.launchedUrls, hasLength(2));
        expect(Uri.parse(platform.launchedUrls.last).scheme, 'https');
        expect(find.byType(SnackBar), findsNothing);
      },
      variant: android,
    );

    testWidgets(
      'says so when directions cannot be opened at all',
      (tester) async {
        await getDirections(
          tester,
          installed: {},
          unlaunchable: {'geo', 'https'},
        );

        expect(find.text("Couldn't open directions."), findsOneWidget);
      },
      variant: android,
    );
  });

  group('iOS', () {
    testWidgets(
      'with nothing else installed, opens Apple Maps without asking',
      (tester) async {
        await getDirections(tester, installed: {});

        expect(find.byType(BottomSheet), findsNothing);
        expect(launched().host, 'maps.apple.com');
        expect(launched().queryParameters['daddr'], address);
      },
      variant: iOS,
    );

    testWidgets(
      'with Google Maps installed too, offers both',
      (tester) async {
        await getDirections(tester, installed: {'comgooglemaps'});

        expect(find.text('Apple Maps'), findsOneWidget);
        expect(find.text('Google Maps'), findsOneWidget);
        expect(find.text('Waze'), findsNothing);

        await tester.tap(find.text('Google Maps'));
        await tester.pumpAndSettle();
        expect(launched().scheme, 'comgooglemaps');
      },
      variant: iOS,
    );
  });
}
