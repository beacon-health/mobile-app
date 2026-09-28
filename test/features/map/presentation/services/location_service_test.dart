import 'package:beacon_app/features/map/presentation/services/location_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

/// Drives LocationService through geolocator's method channel, which is the
/// platform implementation plugins fall back to under `flutter test`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.baseflow.com/geolocator');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Services on and permission granted, so the only variable is how
  /// `getCurrentPosition` answers.
  void mockPositionRequest(Object? Function() respond) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      return switch (call.method) {
        'isLocationServiceEnabled' => true,
        'checkPermission' => LocationPermission.whileInUse.index,
        'getCurrentPosition' => respond(),
        _ => null,
      };
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('returns the device position when granted', () async {
    mockPositionRequest(() => {'latitude': 41.9, 'longitude': -87.6});
    final result = await LocationService.getCurrentLocation();
    expect(result.status, LocationStatus.granted);
    expect((result.latitude, result.longitude), (41.9, -87.6));
  });

  // BEACON-5: iPad apps on Mac let getCurrentPosition raise its own prompt;
  // declining it threw PermissionDeniedException, which was reported to
  // Sentry as a crash.
  test('a denial from the position request is a denial, not an error',
      () async {
    mockPositionRequest(
      () => throw PlatformException(code: 'PERMISSION_DENIED'),
    );
    final result = await LocationService.getCurrentLocation();
    expect(result.status, LocationStatus.denied);
  });

  test('services switched off mid-request read as serviceDisabled', () async {
    mockPositionRequest(
      () => throw PlatformException(code: 'LOCATION_SERVICES_DISABLED'),
    );
    final result = await LocationService.getCurrentLocation();
    expect(result.status, LocationStatus.serviceDisabled);
  });

  test('unexpected failures still surface as errors', () async {
    mockPositionRequest(
      () => throw PlatformException(code: 'LOCATION_UPDATE_FAILURE'),
    );
    final result = await LocationService.getCurrentLocation();
    expect(result.status, LocationStatus.error);
  });
}
