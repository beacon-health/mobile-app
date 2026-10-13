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
}
