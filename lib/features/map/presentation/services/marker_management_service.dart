import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/widgets/markers/marker_icon_factory.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service for creating and managing map markers for facilities.
///
/// At nationwide scale a single region query can return up to 250 facilities,
/// so markers are clustered when zoomed out (see [createMarkersClustered]) and
/// rendered individually once the user zooms in past
/// [MapConstants.clusterZoomThreshold].
class MarkerManagementService {
  /// Pixel-grid cell size used to bucket facilities into clusters.
  static const double _clusterGridPx = 90.0;

  /// Creates markers for [facilities], clustering nearby ones when zoomed out.
  ///
  /// Above [MapConstants.clusterZoomThreshold] this defers to
  /// [createMarkersForFacilities] (individual markers). Below it, facilities
  /// are bucketed by a screen-pixel grid at [zoom]; single-occupancy buckets
  /// render a normal marker, multi-occupancy buckets render a count bubble that
  /// calls [onClusterTap] (used to zoom in).
  static Future<Set<Marker>> createMarkersClustered(
    List<Facility> facilities,
    BuildContext context, {
    required double zoom,
    required bool showFacilityNames,
    required Map<String, BitmapDescriptor> markerIconCache,
    required Function(Facility) onFacilityTap,
    required Function(LatLng) onClusterTap,
  }) async {
    if (zoom >= MapConstants.clusterZoomThreshold) {
      return createMarkersForFacilities(
        facilities,
        context,
        showFacilityNames,
        markerIconCache,
        onFacilityTap,
      );
    }

    final buckets = <String, List<Facility>>{};
    for (final facility in facilities) {
      if (facility.location.latitude == 0.0 &&
          facility.location.longitude == 0.0) {
        continue;
      }
      final key = _pixelBucketKey(
        facility.location.latitude,
        facility.location.longitude,
        zoom,
      );
      (buckets[key] ??= []).add(facility);
    }

    final markers = <Marker>{};
    for (final group in buckets.values) {
      try {
        if (group.length == 1) {
          markers.add(
            await _createMarkerForFacility(
              group.first,
              context,
              showFacilityNames,
              markerIconCache,
              onFacilityTap,
            ),
          );
        } else {
          markers.add(await _createClusterMarker(group, context, onClusterTap));
        }
      } catch (e, stackTrace) {
        developer.log(
          'Error creating cluster/marker: $e',
          name: 'MarkerManagementService',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
    return markers;
  }

  /// Buckets a coordinate into a screen-pixel grid cell at [zoom] using the
  /// Web Mercator projection, so clusters stay visually consistent in size.
  static String _pixelBucketKey(double lat, double lng, double zoom) {
    final scale = 256.0 * math.pow(2.0, zoom);
    final worldX = (lng + 180.0) / 360.0 * scale;
    final sinLat = math.sin(lat * math.pi / 180.0);
    final worldY = (0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) *
        scale;
    final gx = (worldX / _clusterGridPx).floor();
    final gy = (worldY / _clusterGridPx).floor();
    return '$gx:$gy';
  }

  static Future<Marker> _createClusterMarker(
    List<Facility> facilities,
    BuildContext context,
    Function(LatLng) onClusterTap,
  ) async {
    var lat = 0.0;
    var lng = 0.0;
    for (final f in facilities) {
      lat += f.location.latitude;
      lng += f.location.longitude;
    }
    final center = LatLng(lat / facilities.length, lng / facilities.length);
    final count = facilities.length;
    final icon = await MarkerUtils.createClusterMarker(count, context);

    return Marker(
      markerId: MarkerId('cluster_${center.latitude}_${center.longitude}_$count'),
      position: center,
      icon: icon,
      onTap: () => onClusterTap(center),
      consumeTapEvents: true,
      anchor: const Offset(0.5, 0.5),
    );
  }

  /// Creates markers for all facilities.
  ///
  /// Facilities that share the exact same coordinates (e.g. two providers at
  /// one address) are fanned out in a small circle so both markers stay
  /// visible and tappable instead of stacking into one unreadable pin.
  static Future<Set<Marker>> createMarkersForFacilities(
    List<Facility> facilities,
    BuildContext context,
    bool showFacilityNames,
    Map<String, BitmapDescriptor> markerIconCache,
    Function(Facility) onMarkerTap,
  ) async {
    final markers = <Marker>{};
    final positions = _fannedOutPositions(facilities);

    for (final facility in facilities) {
      try {
        final marker = await _createMarkerForFacility(
          facility,
          context,
          showFacilityNames,
          markerIconCache,
          onMarkerTap,
          positionOverride: positions[facility.id],
        );
        markers.add(marker);
      } catch (e, stackTrace) {
        developer.log(
          'Error creating marker for ${facility.id}: $e',
          name: 'MarkerManagementService',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    return markers;
  }

  /// Fixed geographic fan-out radius for co-located facilities.
  ///
  /// Deliberately constant (not zoom-scaled): the offset positions never
  /// change, so markers behave like two real adjacent addresses instead of
  /// sliding closer/apart as the user zooms. ~25 m reads as clearly separate
  /// at street-level zooms and merges back into a cluster bubble below the
  /// clustering threshold.
  static const double _fanOutRadiusMeters = 25.0;

  /// Returns adjusted positions for facilities that share exact coordinates:
  /// groups of n > 1 spread evenly on a circle around the shared point.
  /// Deterministic (sorted by id) so markers don't jump between renders.
  static Map<String, LatLng> _fannedOutPositions(List<Facility> facilities) {
    final groups = <String, List<Facility>>{};
    for (final f in facilities) {
      final key = '${f.location.latitude.toStringAsFixed(6)}:'
          '${f.location.longitude.toStringAsFixed(6)}';
      (groups[key] ??= []).add(f);
    }

    final overrides = <String, LatLng>{};
    for (final group in groups.values) {
      if (group.length < 2) continue;
      group.sort((a, b) => a.id.compareTo(b.id));
      final lat = group.first.location.latitude;
      final lng = group.first.location.longitude;

      for (var i = 0; i < group.length; i++) {
        final angle = 2 * math.pi * i / group.length;
        final dLat = _fanOutRadiusMeters * math.cos(angle) / 111320.0;
        final dLng = _fanOutRadiusMeters *
            math.sin(angle) /
            (111320.0 * math.cos(lat * math.pi / 180));
        overrides[group[i].id] = LatLng(lat + dLat, lng + dLng);
      }
    }
    return overrides;
  }

  static Future<Marker> _createMarkerForFacility(
    Facility facility,
    BuildContext context,
    bool showFacilityNames,
    Map<String, BitmapDescriptor> markerIconCache,
    Function(Facility) onMarkerTap, {
    LatLng? positionOverride,
  }) async {
    final markerId = MarkerId(facility.id);
    final position = positionOverride ??
        LatLng(
          facility.location.latitude,
          facility.location.longitude,
        );

    final primaryCategory = facility.primaryCategory;
    final cacheKey = '${facility.id}_${primaryCategory}_$showFacilityNames';
    BitmapDescriptor? icon = markerIconCache[cacheKey];

    if (icon == null) {
      try {
        icon = await MarkerUtils.createFacilityMarker(
          facility.name,
          facility.isFavorite,
          primaryCategory,
          context,
          showName: showFacilityNames,
        );
        markerIconCache[cacheKey] = icon;
      } catch (e) {
        developer.log(
          'Error creating marker icon: $e',
          name: 'MarkerManagementService',
        );
        icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      }
    }

    return Marker(
      markerId: markerId,
      position: position,
      icon: icon,
      onTap: () => onMarkerTap(facility),
      consumeTapEvents: true,
      anchor: const Offset(0.5, 0.5),
      infoWindow: showFacilityNames
          ? InfoWindow(title: facility.name)
          : InfoWindow.noText,
    );
  }

  /// Creates a debounce timer for marker updates.
  static Timer createDebounceTimer(Duration delay, VoidCallback callback) {
    return Timer(delay, callback);
  }
}
