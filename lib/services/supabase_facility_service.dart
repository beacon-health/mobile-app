import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for querying Illinois healthcare facilities from Supabase.
///
/// Fetches all 691 facilities from the `facilities_il_full` view once
/// and caches them. All filtering (distance, search, category) is done
/// client-side since the dataset is small.
class SupabaseFacilityService {
  SupabaseFacilityService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  List<Facility>? _cache;

  static const String _viewName = 'facilities_il_full';

  /// Fetches all facilities, using an in-memory cache after first load.
  Future<List<Facility>> getAllFacilities({bool forceRefresh = false}) async {
    if (_cache != null && !forceRefresh) return _cache!;

    try {
      developer.log(
        'Fetching all facilities from $_viewName...',
        name: 'SupabaseFacilityService',
      );

      final response =
          await _client.from(_viewName).select().order('facility_name');

      final facilities = <Facility>[];
      for (final json in response as List) {
        try {
          facilities.add(
            Facility.fromSupabase(json as Map<String, dynamic>),
          );
        } catch (e) {
          developer.log(
            'Error parsing facility: $e',
            name: 'SupabaseFacilityService',
          );
        }
      }

      developer.log(
        'Loaded ${facilities.length} facilities',
        name: 'SupabaseFacilityService',
      );

      _cache = facilities;
      return facilities;
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching facilities: $e',
        name: 'SupabaseFacilityService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Returns facilities within [radiusKm] of a point, sorted by distance.
  Future<List<Facility>> getFacilitiesNearLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final all = await getAllFacilities();

    final nearby = all.where((f) {
      if (f.location.latitude == 0.0 && f.location.longitude == 0.0) {
        return false;
      }
      return _haversineKm(
            latitude,
            longitude,
            f.location.latitude,
            f.location.longitude,
          ) <=
          radiusKm;
    }).toList();

    nearby.sort((a, b) {
      final distA = _haversineKm(
        latitude,
        longitude,
        a.location.latitude,
        a.location.longitude,
      );
      final distB = _haversineKm(
        latitude,
        longitude,
        b.location.latitude,
        b.location.longitude,
      );
      return distA.compareTo(distB);
    });

    return nearby;
  }

  /// Fetches a single facility by its ID.
  Future<Facility?> getFacilityById(String id) async {
    final all = await getAllFacilities();
    try {
      return all.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Searches facilities by name or description.
  Future<List<Facility>> searchFacilities(
    String query, {
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    List<Facility> pool;
    if (latitude != null && longitude != null && radiusKm != null) {
      pool = await getFacilitiesNearLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
    } else {
      pool = await getAllFacilities();
    }

    if (query.trim().isEmpty) return pool;

    final q = query.toLowerCase();
    return pool
        .where(
          (f) =>
              f.name.toLowerCase().contains(q) ||
              f.description.toLowerCase().contains(q),
        )
        .toList();
  }

  /// Clears the in-memory cache, forcing a fresh fetch next time.
  void clearCache() => _cache = null;

  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}
