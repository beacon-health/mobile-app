import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/zip_code_service.dart';
import 'package:geolocator/geolocator.dart';

/// Outcome of a [LocationService.getCurrentLocation] call.
enum LocationStatus {
  /// GPS coordinates were obtained successfully.
  granted,

  /// User denied the OS permission prompt (not permanent).
  denied,

  /// User permanently denied or disabled location for the app.
  permanentlyDenied,

  /// Location services are disabled at the OS level.
  serviceDisabled,

  /// An unexpected error occurred (e.g. plugin/IO failure).
  error,
}

/// Provides GPS-based location lookup backed by the OS permission flow.
///
/// On denial / failure, [getCurrentLocation] returns a [LocationResult] backed
/// by the user's current [ZipCodeService] coordinates so callers always have
/// usable lat/lng to fall back to.
class LocationService {
  static const String _logContext = 'LocationService';

  static Future<LocationResult> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult._fromFallback(LocationStatus.serviceDisabled);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult._fromFallback(LocationStatus.permanentlyDenied);
      }
      if (permission == LocationPermission.denied) {
        return LocationResult._fromFallback(LocationStatus.denied);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: 'Current Location',
        status: LocationStatus.granted,
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        e,
        stackTrace,
        context: '$_logContext.getCurrentLocation',
      );
      return LocationResult._fromFallback(LocationStatus.error);
    }
  }

  /// Returns the current OS-level permission state without prompting.
  static Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  /// Whether the user has already granted GPS access (whileInUse or always).
  static Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static bool hasLocationChanged(
    double currentLat,
    double currentLng,
    double newLat,
    double newLng,
  ) {
    const double threshold = 0.001;
    return (currentLat - newLat).abs() > threshold ||
        (currentLng - newLng).abs() > threshold;
  }
}

class LocationResult {
  final double latitude;
  final double longitude;
  final String locationName;
  final LocationStatus status;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.status,
  });

  bool get isCurrentLocation => status == LocationStatus.granted;

  /// Falls back to the user's saved ZIP-code coordinates so a denied/failed
  /// GPS lookup still yields a usable location.
  factory LocationResult._fromFallback(LocationStatus status) {
    final zip = ZipCodeService();
    return LocationResult(
      latitude: zip.latitude,
      longitude: zip.longitude,
      locationName: zip.zipCode ?? 'Current Location',
      status: status,
    );
  }

  factory LocationResult.fromCoordinates(
    double latitude,
    double longitude,
    String locationName,
  ) {
    return LocationResult(
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      status: LocationStatus.granted,
    );
  }
}
