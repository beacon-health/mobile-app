import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  // TODO: Make default zipcode configurable in app settings
  // Zipcode 60613 coordinates (Chicago, IL - Lakeview area)
  static const double _defaultLatitude = 41.9542;
  static const double _defaultLongitude = -87.6668;
  static const String _defaultLocationName = "Current Location";

  static Future<LocationResult> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          debugPrint('Location permission denied, using default location');
          return LocationResult.defaultLocation();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
            'Location permission permanently denied, using default location');
        return LocationResult.defaultLocation();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: _defaultLocationName,
        isCurrentLocation: true,
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return LocationResult.defaultLocation();
    }
  }

  static bool hasLocationChanged(
      double currentLat, double currentLng, double newLat, double newLng) {
    const double threshold = 0.001;
    return (currentLat - newLat).abs() > threshold ||
        (currentLng - newLng).abs() > threshold;
  }
}

class LocationResult {
  final double latitude;
  final double longitude;
  final String locationName;
  final bool isCurrentLocation;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.isCurrentLocation,
  });

  factory LocationResult.defaultLocation() {
    return LocationResult(
      latitude: LocationService._defaultLatitude,
      longitude: LocationService._defaultLongitude,
      locationName: "Chicago, IL 60613",
      isCurrentLocation: false,
    );
  }

  factory LocationResult.fromCoordinates(
      double latitude, double longitude, String locationName) {
    return LocationResult(
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      isCurrentLocation: false,
    );
  }
}
