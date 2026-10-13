import 'package:beacon_app/core/services/coverage_service.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final zipService = ZipCodeService();
  final coverage = CoverageService();
  late List<String> geocoded;

  Location at(double latitude, double longitude) => Location(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime(2026),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await zipService.clear();
    coverage
      ..debugReset()
      ..debugSetStates(['IL', 'OK']);
    geocoded = [];
    zipService.debugGeocode = (address) async {
      geocoded.add(address);
      return [at(35.4676, -97.5164)];
    };
  });

  tearDown(() {
    zipService.debugGeocode = null;
    coverage.debugReset();
  });

  group('ZipCodeService.setZipCode', () {
    test('saves a ZIP in a launched state', () async {
      final result = await zipService.setZipCode('73102');

      expect(result, ZipResult.saved);
      expect(zipService.zipCode, '73102');
      expect(zipService.latitude, 35.4676);
      expect(zipService.longitude, -97.5164);
      expect(zipService.hasCompletedOnboarding, isTrue);
      expect(geocoded, ['73102, USA']);
    });

    test('turns away a ZIP outside coverage without storing anything',
        () async {
      final result = await zipService.setZipCode('75001');

      expect(result, ZipResult.outsideCoverage);
      expect(zipService.zipCode, isNull);
      expect(zipService.latitude, MapConstants.defaultLatitude);
      expect(zipService.hasCompletedOnboarding, isFalse);
      // The geocoder is never asked about a ZIP that can't be used.
      expect(geocoded, isEmpty);
    });

    test('keeps the previous ZIP when a new one is turned away', () async {
      await zipService.setZipCode('60601');

      final result = await zipService.setZipCode('10001');

      expect(result, ZipResult.outsideCoverage);
      expect(zipService.zipCode, '60601');
    });

    test('rejects text that is not a ZIP', () async {
      expect(await zipService.setZipCode('00000'), ZipResult.notFound);
      expect(
          await zipService.setZipCode('Current Location'), ZipResult.notFound);
      expect(geocoded, isEmpty);
    });

    test('reports not found when the geocoder cannot place the ZIP', () async {
      zipService.debugGeocode = (_) async => [];
      expect(await zipService.setZipCode('60601'), ZipResult.notFound);

      zipService.debugGeocode = (_) async => throw Exception('no result');
      expect(await zipService.setZipCode('60601'), ZipResult.notFound);

      expect(zipService.zipCode, isNull);
    });

    test('re-reads coverage before turning a ZIP away', () async {
      // The device last saw Illinois only; Oklahoma launched since.
      coverage
        ..debugReset()
        ..debugFetch = () async => ['IL', 'OK'];

      expect(await zipService.setZipCode('74103'), ZipResult.saved);
    });

    test('accepts any state once the gate is off', () async {
      coverage.debugSetStates([CoverageService.nationwideCode]);

      expect(await zipService.setZipCode('75001'), ZipResult.saved);
    });
  });

  group('ZipCodeService GPS mode', () {
    test('turning GPS on remembers the ZIP, and turning it off restores it',
        () async {
      await zipService.setZipCode('60601');
      final zipLat = zipService.latitude;

      await zipService.setCurrentLocation(
        latitude: 41.95,
        longitude: -87.70,
        syncToCloud: false,
      );
      expect(zipService.locationSearchEnabled, isTrue);
      expect(zipService.zipCode, ZipCodeService.currentLocationSentinel);
      expect(zipService.latitude, 41.95);
      expect(zipService.previousZipCode, '60601');

      final restored =
          await zipService.disableLocationSearch(syncToCloud: false);

      expect(restored, isTrue);
      expect(zipService.locationSearchEnabled, isFalse);
      expect(zipService.zipCode, '60601');
      expect(zipService.latitude, zipLat);
    });

    test('with no earlier ZIP, turning GPS off asks the caller for one',
        () async {
      await zipService.setCurrentLocation(
        latitude: 41.95,
        longitude: -87.70,
        syncToCloud: false,
      );

      final restored =
          await zipService.disableLocationSearch(syncToCloud: false);

      expect(restored, isFalse);
      expect(zipService.zipCode, isNull);
      // The map still has somewhere to render while the ZIP is asked for.
      expect(zipService.latitude, 41.95);
    });

    test('the stored label is the same in every language', () async {
      // A translated label was once stored here and later mistaken for a ZIP.
      await zipService.setCurrentLocation(
        latitude: 41.95,
        longitude: -87.70,
        syncToCloud: false,
      );
      expect(zipService.zipCode, 'Current Location');
    });

    test('everything survives a restart', () async {
      await zipService.setZipCode('73102');
      await zipService.setCurrentLocation(
        latitude: 35.5,
        longitude: -97.5,
        syncToCloud: false,
      );

      await zipService.init();

      expect(zipService.locationSearchEnabled, isTrue);
      expect(zipService.latitude, 35.5);
      expect(zipService.previousZipCode, '73102');
      expect(zipService.hasCompletedOnboarding, isTrue);
    });

    test('notifies listeners when the mode changes', () async {
      var notifications = 0;
      void onChange() => notifications++;
      zipService.addListener(onChange);
      addTearDown(() => zipService.removeListener(onChange));

      await zipService.setLocationSearchEnabled(true, syncToCloud: false);
      await zipService.setLocationSearchEnabled(true, syncToCloud: false);

      expect(notifications, 1, reason: 'no change the second time');
    });
  });
}
