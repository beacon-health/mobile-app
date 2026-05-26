import 'dart:developer' as developer;

import 'package:beacon_app/features/map/data/supabase_facility_service.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';

/// Abstract interface for facility data access.
///
/// Both [FacilityRepository] (Supabase) and `DemoFacilityRepository` (local
/// JSON) implement this interface, enabling seamless swapping via demo mode.
abstract class FacilityRepositoryBase {
  Future<List<Facility>> loadFacilities();

  Future<List<Facility>> loadFacilitiesWithDistance({
    required double latitude,
    required double longitude,
    required double radiusMiles,
  });

  Future<List<Facility>> loadFacilitiesNearLocation({
    required double latitude,
    required double longitude,
    double radiusInKm = 50.0,
  });

  Stream<List<Facility>> getFacilitiesStream();

  Future<List<Facility>> searchFacilities(
    String query, {
    double? latitude,
    double? longitude,
    double? radiusMiles,
  });

  Future<Facility?> getFacilityById(String id);
}

/// Repository for healthcare facility data backed by Supabase.
///
/// Provides a clean interface for accessing facility data from Supabase.
class FacilityRepository implements FacilityRepositoryBase {
  FacilityRepository({SupabaseFacilityService? service})
      : _service = service ?? SupabaseFacilityService();

  final SupabaseFacilityService _service;

  /// Loads all healthcare facilities.
  @override
  Future<List<Facility>> loadFacilities() async {
    try {
      return await _service.getAllFacilities();
    } catch (e, stackTrace) {
      developer.log(
        'Error loading facilities: $e',
        name: 'FacilityRepository',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Loads facilities within the specified distance from the given location.
  ///
  /// Uses efficient bounding box queries to filter facilities by proximity.
  @override
  Future<List<Facility>> loadFacilitiesWithDistance({
    required double latitude,
    required double longitude,
    required double radiusMiles,
  }) async {
    try {
      // Convert miles to kilometers for the service
      final radiusKm = radiusMiles * 1.60934;

      return await _service.getFacilitiesNearLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error loading facilities with distance: $e',
        name: 'FacilityRepository',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Loads facilities near a specific location within the given radius.
  @override
  Future<List<Facility>> loadFacilitiesNearLocation({
    required double latitude,
    required double longitude,
    double radiusInKm = 50.0,
  }) async {
    try {
      return await _service.getFacilitiesNearLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusInKm,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error loading facilities near location: $e',
        name: 'FacilityRepository',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Returns a stream of all facilities.
  ///
  /// Currently implemented as a single-shot stream since we have a small dataset.
  @override
  Stream<List<Facility>> getFacilitiesStream() {
    return Stream.fromFuture(loadFacilities());
  }

  /// Searches facilities by name, optionally filtered by location.
  ///
  /// If [latitude], [longitude], and [radiusMiles] are provided, searches only
  /// within that radius. Otherwise searches all facilities.
  @override
  Future<List<Facility>> searchFacilities(
    String query, {
    double? latitude,
    double? longitude,
    double? radiusMiles,
  }) async {
    try {
      final radiusKm = radiusMiles != null ? radiusMiles * 1.60934 : null;

      return await _service.searchFacilities(
        query,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error searching facilities: $e',
        name: 'FacilityRepository',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Gets a single facility by ID.
  @override
  Future<Facility?> getFacilityById(String id) async {
    try {
      return await _service.getFacilityById(id);
    } catch (e, stackTrace) {
      developer.log(
        'Error getting facility by ID: $e',
        name: 'FacilityRepository',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
