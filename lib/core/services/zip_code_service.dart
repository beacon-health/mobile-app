import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ZipCodeService extends ChangeNotifier {
  static final ZipCodeService _instance = ZipCodeService._();
  factory ZipCodeService() => _instance;
  ZipCodeService._();

  static const _keyZip = 'user_zip_code';
  static const _keyLat = 'user_latitude';
  static const _keyLng = 'user_longitude';
  static const _keyOnboarded = 'has_completed_onboarding';

  String? _zipCode;
  double _latitude = MapConstants.defaultLatitude;
  double _longitude = MapConstants.defaultLongitude;
  bool _hasCompletedOnboarding = false;

  String? get zipCode => _zipCode;
  double get latitude => _latitude;
  double get longitude => _longitude;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _zipCode = prefs.getString(_keyZip);
    _latitude = prefs.getDouble(_keyLat) ?? MapConstants.defaultLatitude;
    _longitude = prefs.getDouble(_keyLng) ?? MapConstants.defaultLongitude;
    _hasCompletedOnboarding = prefs.getBool(_keyOnboarded) ?? false;
    notifyListeners();
  }

  Future<void> setZipAndLocation(
    String zip,
    double lat,
    double lng,
  ) async {
    _zipCode = zip;
    _latitude = lat;
    _longitude = lng;
    _hasCompletedOnboarding = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyZip, zip);
    await prefs.setDouble(_keyLat, lat);
    await prefs.setDouble(_keyLng, lng);
    await prefs.setBool(_keyOnboarded, true);

    notifyListeners();
  }

  /// Geocodes [zipCode] and stores the result.
  /// Returns `true` on success, `false` if the zip cannot be resolved.
  Future<bool> setZipCode(String zipCode) async {
    try {
      final locations = await locationFromAddress('$zipCode, USA');
      if (locations.isEmpty) return false;
      await setZipAndLocation(
        zipCode,
        locations.first.latitude,
        locations.first.longitude,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clear() async {
    _zipCode = null;
    _latitude = MapConstants.defaultLatitude;
    _longitude = MapConstants.defaultLongitude;
    _hasCompletedOnboarding = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyZip);
    await prefs.remove(_keyLat);
    await prefs.remove(_keyLng);
    await prefs.remove(_keyOnboarded);

    notifyListeners();
  }
}
