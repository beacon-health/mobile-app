import 'package:beacon_app/core/services/map_launcher_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const address = '35 E Wacker Dr, Chicago, IL 60601';

  group('MapLauncherService.appsFor', () {
    test('iOS offers Apple Maps first, then Google Maps and Waze', () {
      expect(
        MapLauncherService.appsFor(TargetPlatform.iOS),
        [MapApp.appleMaps, MapApp.googleMaps, MapApp.waze],
      );
    });

    test('Android never offers Apple Maps', () {
      expect(
        MapLauncherService.appsFor(TargetPlatform.android),
        [MapApp.googleMaps, MapApp.waze],
      );
    });

    test('platforms the app does not ship to offer nothing', () {
      for (final platform in [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      ]) {
        expect(MapLauncherService.appsFor(platform), isEmpty);
      }
    });
  });

  group('MapLauncherService.probeUri', () {
    test('uses the scheme each platform actually registers', () {
      expect(
        MapLauncherService.probeUri(MapApp.appleMaps, TargetPlatform.iOS),
        isNull,
        reason: 'ships with iOS',
      );
      expect(
        MapLauncherService.probeUri(MapApp.googleMaps, TargetPlatform.iOS)!
            .scheme,
        'comgooglemaps',
      );
      // comgooglemaps does not exist on Android.
      expect(
        MapLauncherService.probeUri(MapApp.googleMaps, TargetPlatform.android)!
            .scheme,
        'google.navigation',
      );
      for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
        expect(
          MapLauncherService.probeUri(MapApp.waze, platform)!.scheme,
          'waze',
        );
      }
    });
  });

  group('MapLauncherService.directionsUri', () {
    test('Google Maps on Android opens its universal directions link', () {
      final uri = MapLauncherService.directionsUri(
        MapApp.googleMaps,
        address,
        TargetPlatform.android,
      );
      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters, {'api': '1', 'destination': address});
    });

    test('Google Maps on iOS keeps its app scheme', () {
      final uri = MapLauncherService.directionsUri(
        MapApp.googleMaps,
        address,
        TargetPlatform.iOS,
      );
      expect(uri.scheme, 'comgooglemaps');
      expect(uri.queryParameters['daddr'], address);
    });

    test('addresses are percent-encoded', () {
      final uri = MapLauncherService.directionsUri(
        MapApp.waze,
        '1 Main St #4 & Co, Tulsa, OK',
        TargetPlatform.android,
      );
      expect(uri.toString(), isNot(contains(' ')));
      expect(uri.queryParameters['q'], '1 Main St #4 & Co, Tulsa, OK');
      expect(uri.queryParameters['navigate'], 'yes');
    });

    test('the fallback tries a geo link, then Google Maps on the web', () {
      final uris = MapLauncherService.fallbackUris(address);
      expect(uris.map((u) => u.scheme), ['geo', 'https']);
    });
  });

  group('MapLauncherService.installedApps', () {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    late List<String> probed;

    /// Answers `canLaunch` with whether the URL's scheme is in [installed].
    void mockInstalled(Set<String> installed) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method != 'canLaunch') return null;
        final url = (call.arguments as Map<Object?, Object?>)['url']! as String;
        probed.add(url);
        return installed.contains(Uri.parse(url).scheme);
      });
    }

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      probed = [];
    });
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('Android lists Google Maps and Waze when both are installed',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      mockInstalled({'google.navigation', 'waze'});

      expect(
        await MapLauncherService.installedApps(),
        [MapApp.googleMaps, MapApp.waze],
      );
      expect(probed, isNot(contains(startsWith('comgooglemaps'))));
    });

    test('Android with no known map app lists nothing', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      mockInstalled({});

      expect(await MapLauncherService.installedApps(), isEmpty);
    });

    test('iOS always includes Apple Maps', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      mockInstalled({});

      expect(await MapLauncherService.installedApps(), [MapApp.appleMaps]);
    });

    test('a remembered app that is not installed here is forgotten', () async {
      // 1.0.0 offered Apple Maps on Android, so some devices stored it.
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      mockInstalled({'google.navigation'});
      await MapLauncherService.setPreferredApp(MapApp.appleMaps);

      expect(await MapLauncherService.preferredApp(), isNull);

      await MapLauncherService.setPreferredApp(MapApp.googleMaps);
      expect(await MapLauncherService.preferredApp(), MapApp.googleMaps);
    });
  });
}
