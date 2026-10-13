import 'dart:io';

import 'package:beacon_app/core/services/map_launcher_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks that the native project files still say what the Dart code relies
/// on. Each of these has shipped broken before, and none of them fails a
/// build or a widget test when it drifts — only a person on a real device
/// finds out.
void main() {
  final manifest =
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

  String plistArray(String key) {
    final match = RegExp(
      '<key>$key</key>\\s*<array>(.*?)</array>',
      dotAll: true,
    ).firstMatch(infoPlist);
    expect(match, isNotNull, reason: '$key missing from Info.plist');
    return match!.group(1)!;
  }

  group('Android', () {
    test('declares every map app the code looks for', () {
      // Without a <queries> entry, Android 11+ reports the app as not
      // installed, and "Get directions" silently loses it.
      final queries = RegExp('<queries>(.*?)</queries>', dotAll: true)
          .firstMatch(manifest)
          ?.group(1);
      expect(queries, isNotNull, reason: 'no <queries> block');

      final schemes = <String>{
        for (final app in MapLauncherService.appsFor(TargetPlatform.android))
          if (MapLauncherService.probeUri(app, TargetPlatform.android)
              case final Uri probe)
            probe.scheme,
        // The fallback when none of them is installed.
        'geo',
      };
      for (final scheme in schemes) {
        expect(
          queries,
          contains('android:scheme="$scheme"'),
          reason: 'add a <queries> intent for the "$scheme" scheme',
        );
      }
    });

    test('asks for foreground location only', () {
      expect(manifest, contains('android.permission.ACCESS_FINE_LOCATION'));
      expect(manifest, contains('android.permission.ACCESS_COARSE_LOCATION'));
      // Never needed, and it triggers extra Play review.
      expect(
        RegExp('<uses-permission[^>]*ACCESS_BACKGROUND_LOCATION')
            .hasMatch(manifest),
        isFalse,
      );
    });

    test('takes back the foreground-service permission geolocator adds', () {
      // Beacon reads location only while it is on screen. Shipping the
      // permission anyway makes Play ask for a declaration and a review, and
      // refuse the upload until it has them.
      expect(
        RegExp(
          r'<uses-permission\s+'
          r'android:name="android\.permission\.FOREGROUND_SERVICE_LOCATION"\s+'
          'tools:node="remove"',
        ).hasMatch(manifest),
        isTrue,
      );
      expect(
        File('android/permissions.txt').readAsStringSync(),
        isNot(contains('android.permission.FOREGROUND_SERVICE')),
      );
    });

    test('reads the Maps key from the build, not from source', () {
      expect(manifest, contains(r'android:value="${GOOGLE_MAPS_API_KEY}"'));
      expect(manifest, isNot(contains('AIza')));
    });
  });

  group('iOS', () {
    test('declares every map app the code looks for', () {
      // An unlisted scheme makes canLaunchUrl answer "no" on iOS.
      final declared = plistArray('LSApplicationQueriesSchemes');
      for (final app in MapLauncherService.appsFor(TargetPlatform.iOS)) {
        final probe = MapLauncherService.probeUri(app, TargetPlatform.iOS);
        if (probe == null) continue;
        expect(
          declared,
          contains('<string>${probe.scheme}</string>'),
          reason: 'add "${probe.scheme}" to LSApplicationQueriesSchemes',
        );
      }
    });

    test('adopts the UIScene lifecycle', () {
      // Apps built with the iOS 27 SDK refuse to launch without it.
      expect(infoPlist, contains('<key>UIApplicationSceneManifest</key>'));
      expect(infoPlist, contains('<string>FlutterSceneDelegate</string>'));
    });

    test('explains why it wants location', () {
      expect(
        infoPlist,
        contains('<key>NSLocationWhenInUseUsageDescription</key>'),
      );
      expect(
        infoPlist,
        isNot(contains('NSLocationAlwaysAndWhenInUseUsageDescription')),
      );
    });

    test('reads the Maps key from the build, not from source', () {
      expect(infoPlist, contains(r'$(GOOGLE_MAPS_API_KEY)'));
      expect(infoPlist, isNot(contains('AIza')));
    });
  });
}
