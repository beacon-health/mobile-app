import 'dart:async';

import 'package:beacon_app/core/services/user_settings_service.dart';
import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ZipCodeService extends ChangeNotifier {
  static final ZipCodeService _instance = ZipCodeService._();
  factory ZipCodeService() => _instance;
  ZipCodeService._();

  /// Canonical, never-translated label stored in place of a ZIP when the user
  /// is on GPS. Stored verbatim so equality checks stay language-independent;
  /// the UI translates it at display time via `locationCurrentLocation`.
  static const String currentLocationSentinel = 'Current Location';

  static const _keyZip = 'user_zip_code';
  static const _keyLat = 'user_latitude';
  static const _keyLng = 'user_longitude';
  static const _keyOnboarded = 'has_completed_onboarding';
  static const _keyLocationSearchEnabled = 'location_search_enabled';
  // Snapshot so a GPS toggle-off can restore it — `_zipCode` gets overwritten
  // with the Current Location sentinel.
  static const _keyPreviousZip = 'user_previous_zip_code';
  static const _keyPreviousLat = 'user_previous_latitude';
  static const _keyPreviousLng = 'user_previous_longitude';

  String? _zipCode;
  double _latitude = MapConstants.defaultLatitude;
  double _longitude = MapConstants.defaultLongitude;
  bool _hasCompletedOnboarding = false;
  bool _locationSearchEnabled = false;
  String? _previousZipCode;
  double? _previousLatitude;
  double? _previousLongitude;

  String? get zipCode => _zipCode;
  double get latitude => _latitude;
  double get longitude => _longitude;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  /// Whether the user opted into GPS-based search (vs. ZIP-based).
  ///
  /// Mirrors `user_settings.location_search_enabled` for signed-in users.
  bool get locationSearchEnabled => _locationSearchEnabled;

  /// The last real ZIP the user entered before turning on GPS-based search.
  /// Null when no prior ZIP was ever stored (e.g. a fresh install that went
  /// straight into GPS mode during onboarding).
  String? get previousZipCode => _previousZipCode;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _zipCode = prefs.getString(_keyZip);
    _latitude = prefs.getDouble(_keyLat) ?? MapConstants.defaultLatitude;
    _longitude = prefs.getDouble(_keyLng) ?? MapConstants.defaultLongitude;
    _hasCompletedOnboarding = prefs.getBool(_keyOnboarded) ?? false;
    _locationSearchEnabled = prefs.getBool(_keyLocationSearchEnabled) ?? false;
    _previousZipCode = prefs.getString(_keyPreviousZip);
    _previousLatitude = prefs.getDouble(_keyPreviousLat);
    _previousLongitude = prefs.getDouble(_keyPreviousLng);
    notifyListeners();
  }

  static final RegExp _zipRegex = RegExp(r'^\d{5}$');

  bool _isRealZip(String? value) =>
      value != null && _zipRegex.hasMatch(value.trim());

  Future<void> setZipAndLocation(
    String zip,
    double lat,
    double lng, {
    bool syncToCloud = true,
  }) async {
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
    if (syncToCloud) {
      unawaited(UserSettingsService.instance.pushLocal());
    }
  }

  /// Geocodes [zipCode] and stores the result.
  /// Returns `true` on success, `false` if the zip cannot be resolved.
  Future<bool> setZipCode(String zipCode, {bool syncToCloud = true}) async {
    try {
      final locations = await locationFromAddress('$zipCode, USA');
      if (locations.isEmpty) return false;
      await setZipAndLocation(
        zipCode,
        locations.first.latitude,
        locations.first.longitude,
        syncToCloud: syncToCloud,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stores GPS coordinates as the active location source. A real 5-digit ZIP
  /// is snapshotted first so [disableLocationSearch] can restore it.
  Future<void> setCurrentLocation({
    required double latitude,
    required double longitude,
    String displayName = currentLocationSentinel,
    bool syncToCloud = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Snapshot prior ZIP before overwriting (only if it's a real ZIP, not
    // already "Current Location" from an earlier GPS session).
    if (_isRealZip(_zipCode)) {
      _previousZipCode = _zipCode;
      _previousLatitude = _latitude;
      _previousLongitude = _longitude;
      await prefs.setString(_keyPreviousZip, _zipCode!);
      await prefs.setDouble(_keyPreviousLat, _latitude);
      await prefs.setDouble(_keyPreviousLng, _longitude);
    }

    _zipCode = displayName;
    _latitude = latitude;
    _longitude = longitude;
    _hasCompletedOnboarding = true;
    _locationSearchEnabled = true;

    await prefs.setString(_keyZip, displayName);
    await prefs.setDouble(_keyLat, latitude);
    await prefs.setDouble(_keyLng, longitude);
    await prefs.setBool(_keyOnboarded, true);
    await prefs.setBool(_keyLocationSearchEnabled, true);

    notifyListeners();
    if (syncToCloud) {
      unawaited(UserSettingsService.instance.pushLocal());
    }
  }

  Future<void> setLocationSearchEnabled(
    bool enabled, {
    bool syncToCloud = true,
  }) async {
    if (_locationSearchEnabled == enabled) return;
    _locationSearchEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLocationSearchEnabled, enabled);
    notifyListeners();
    if (syncToCloud) {
      unawaited(UserSettingsService.instance.pushLocal());
    }
  }

  /// Turns GPS search off, restoring the previous ZIP if there is one.
  /// Returns false when there isn't — the caller must then prompt for a ZIP.
  Future<bool> disableLocationSearch({bool syncToCloud = true}) async {
    final hasPrevious = _isRealZip(_previousZipCode) &&
        _previousLatitude != null &&
        _previousLongitude != null;

    _locationSearchEnabled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLocationSearchEnabled, false);

    if (hasPrevious) {
      _zipCode = _previousZipCode;
      _latitude = _previousLatitude!;
      _longitude = _previousLongitude!;
      await prefs.setString(_keyZip, _previousZipCode!);
      await prefs.setDouble(_keyLat, _previousLatitude!);
      await prefs.setDouble(_keyLng, _previousLongitude!);
    } else {
      // Keep the last known coords so the map still renders while the UI
      // prompts for a ZIP.
      _zipCode = null;
      await prefs.remove(_keyZip);
    }

    notifyListeners();
    if (syncToCloud) {
      unawaited(UserSettingsService.instance.pushLocal());
    }
    return hasPrevious;
  }

  Future<void> clear() async {
    _zipCode = null;
    _latitude = MapConstants.defaultLatitude;
    _longitude = MapConstants.defaultLongitude;
    _hasCompletedOnboarding = false;
    _locationSearchEnabled = false;
    _previousZipCode = null;
    _previousLatitude = null;
    _previousLongitude = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyZip);
    await prefs.remove(_keyLat);
    await prefs.remove(_keyLng);
    await prefs.remove(_keyOnboarded);
    await prefs.remove(_keyLocationSearchEnabled);
    await prefs.remove(_keyPreviousZip);
    await prefs.remove(_keyPreviousLat);
    await prefs.remove(_keyPreviousLng);

    notifyListeners();
  }
}
