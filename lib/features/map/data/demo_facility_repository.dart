import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/features/map/data/facility_repository.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Facility repository that loads mock data from a local JSON asset.
///
/// Used when demo mode is active. Performs client-side distance filtering
/// using the Haversine formula since the dataset is small (~40 facilities).
/// Supports locale-based description selection (names stay in English).
class DemoFacilityRepository implements FacilityRepositoryBase {
  List<Facility>? _cachedFacilities;
  String? _cachedLocale;

  @override
  Future<List<Facility>> loadFacilities() async {
    final currentLocale = LocaleProvider().locale.languageCode;

    // Invalidate cache if locale changed
    if (_cachedFacilities != null && _cachedLocale == currentLocale) {
      return _cachedFacilities!;
    }

    try {
      final jsonString =
          await rootBundle.loadString('assets/demo/demo_facilities.json');
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

      final facilities = <Facility>[];
      for (final item in jsonList) {
        final map = Map<String, dynamic>.from(item as Map);
        final isFavorite = map.remove('is_favorite') as bool? ?? false;

        // Select description based on locale (name stays in English)
        if (currentLocale != 'en') {
          final localizedDesc =
              map['facility_description_$currentLocale'] as String?;
          if (localizedDesc != null && localizedDesc.isNotEmpty) {
            map['facility_description'] = localizedDesc;
          }
        }

        final facility = Facility.fromSupabase(map);
        if (isFavorite) {
          facilities.add(facility.copyWith(isFavorite: true));
        } else {
          facilities.add(facility);
        }
      }

      _cachedFacilities = facilities;
      _cachedLocale = currentLocale;

      developer.log(
        'Loaded ${facilities.length} demo facilities (locale: $currentLocale)',
        name: 'DemoFacilityRepository',
      );

      return facilities;
    } catch (e, stackTrace) {
      developer.log(
        'Error loading demo facilities: $e',
        name: 'DemoFacilityRepository',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Future<List<Facility>> loadFacilitiesWithDistance({
    required double latitude,
    required double longitude,
    required double radiusMiles,
  }) async {
    final all = await loadFacilities();
    final radiusKm = radiusMiles * 1.60934;

    return all.where((facility) {
      final distance = _haversineKm(
        latitude,
        longitude,
        facility.location.latitude,
        facility.location.longitude,
      );
      return distance <= radiusKm;
    }).toList()
      ..sort((a, b) {
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
  }

  @override
  Future<List<Facility>> loadFacilitiesNearLocation({
    required double latitude,
    required double longitude,
    double radiusInKm = 50.0,
  }) async {
    final all = await loadFacilities();

    return all.where((facility) {
      final distance = _haversineKm(
        latitude,
        longitude,
        facility.location.latitude,
        facility.location.longitude,
      );
      return distance <= radiusInKm;
    }).toList();
  }

  @override
  Stream<List<Facility>> getFacilitiesStream() {
    return Stream.fromFuture(loadFacilities());
  }

  @override
  Future<List<Facility>> searchFacilities(
    String query, {
    double? latitude,
    double? longitude,
    double? radiusMiles,
  }) async {
    final all = await loadFacilities();
    if (query.trim().isEmpty) return all;

    final queryLower = query.toLowerCase();
    return all
        .where(
          (f) =>
              f.name.toLowerCase().contains(queryLower) ||
              f.description.toLowerCase().contains(queryLower) ||
              f.services.any((s) => s.toLowerCase().contains(queryLower)),
        )
        .toList();
  }

  @override
  Future<List<Facility>> getFacilitiesByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final all = await loadFacilities();
    final idSet = ids.toSet();
    return all.where((f) => idSet.contains(f.id)).toList();
  }

  @override
  Future<Facility?> getFacilityById(String id) async {
    final all = await loadFacilities();
    try {
      return all.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
