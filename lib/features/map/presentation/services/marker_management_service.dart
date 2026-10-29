import 'dart:async';
import 'dart:math' as math;

import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/widgets/markers/marker_icon_factory.dart';
import 'package:beacon_app/features/map/utils/map_geometry.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Builds map markers. A region query can return up to 250 facilities, so
/// markers cluster below [MapConstants.clusterZoomThreshold].
class MarkerManagementService {
  /// Pixel-grid cell size used to bucket facilities into clusters.
  static const double _clusterGridPx = 90.0;

  /// Deliberately constant, not zoom-scaled, so fanned markers behave like two
  /// real adjacent addresses instead of sliding apart as the user zooms.
  static const double _fanOutRadiusMeters = 25.0;

  /// How far, on screen, a fanned-out pin must sit from the point it shares
  /// before the pins can be told apart and tapped one at a time.
  static const double _minFanOutPx = 26.0;

  /// The zoom from which facilities sharing one address are drawn as separate
  /// fanned-out pins. Below it they would stack into what looks like a single
  /// pin, so they stay a count bubble instead.
  static double fanOutZoom(double latitude) => MapGeometry.zoomForScale(
        meters: _fanOutRadiusMeters,
        pixels: _minFanOutPx,
        latitude: latitude,
      );

  /// Where to send the camera to open a same-address bubble: just past
  /// [fanOutZoom], so rounding in the map's reported zoom can't leave it shut.
  static double fanOutRevealZoom(double latitude) =>
      fanOutZoom(latitude) + 0.25;

  /// Splits [facilities] into what to draw at [zoom]: lone facilities, and
  /// groups that share a marker. Pure, so the clustering rules can be tested
  /// without a map.
  ///
  /// Below the cluster threshold, facilities bucket into a screen-pixel grid.
  /// At or above it, only facilities at the same address group, and only until
  /// [fanOutZoom] gives their fanned-out pins room.
  static List<List<Facility>> groupForZoom(
    List<Facility> facilities,
    double zoom,
  ) {
    final located = [
      for (final f in facilities)
        if (f.location.latitude != 0.0 || f.location.longitude != 0.0) f,
    ];

    final buckets = <String, List<Facility>>{};
    if (zoom < MapConstants.clusterZoomThreshold) {
      for (final f in located) {
        final key = _pixelBucketKey(
          f.location.latitude,
          f.location.longitude,
          zoom,
        );
        (buckets[key] ??= []).add(f);
      }
      return buckets.values.toList();
    }

    for (final f in located) {
      (buckets[_pointKey(f.location)] ??= []).add(f);
    }
    return [
      for (final group in buckets.values)
        if (group.length > 1 &&
            zoom < fanOutZoom(group.first.location.latitude))
          group
        else
          for (final f in group) [f],
    ];
  }

  /// Draws [facilities] for [zoom]: one marker per lone facility and a count
  /// bubble, wired to [onClusterTap], per group from [groupForZoom].
  static Future<Set<Marker>> createMarkersClustered(
    List<Facility> facilities,
    MarkerStyle style, {
    required double zoom,
    required bool showFacilityNames,
    required Map<String, BitmapDescriptor> markerIconCache,
    required void Function(Facility) onFacilityTap,
    required void Function(List<Facility>) onClusterTap,
  }) async {
    final fanned = _fannedOutPositions(facilities);
    final markers = <Marker>{};
    for (final group in groupForZoom(facilities, zoom)) {
      try {
        if (group.length == 1) {
          markers.add(
            await _createMarkerForFacility(
              group.single,
              style,
              showFacilityNames,
              markerIconCache,
              onFacilityTap,
              positionOverride: fanned[group.single.id],
            ),
          );
        } else {
          markers.add(await _createClusterMarker(group, style, onClusterTap));
        }
      } catch (e, stackTrace) {
        ErrorReporter.instance.report(
          e,
          stackTrace,
          context: 'MarkerManagementService.marker',
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
    final worldY =
        (0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) * scale;
    final gx = (worldX / _clusterGridPx).floor();
    final gy = (worldY / _clusterGridPx).floor();
    return '$gx:$gy';
  }

  /// Identifies a coordinate to ~10 cm, so facilities geocoded to the same
  /// address share a key.
  static String _pointKey(LatLng point) =>
      '${point.latitude.toStringAsFixed(6)}:'
      '${point.longitude.toStringAsFixed(6)}';

  static Future<Marker> _createClusterMarker(
    List<Facility> facilities,
    MarkerStyle style,
    void Function(List<Facility>) onClusterTap,
  ) async {
    var lat = 0.0;
    var lng = 0.0;
    for (final f in facilities) {
      lat += f.location.latitude;
      lng += f.location.longitude;
    }
    final center = LatLng(lat / facilities.length, lng / facilities.length);
    final count = facilities.length;
    final icon = await MarkerUtils.createClusterMarker(count, style);

    return Marker(
      markerId:
          MarkerId('cluster_${center.latitude}_${center.longitude}_$count'),
      position: center,
      icon: icon,
      onTap: () => onClusterTap(facilities),
      consumeTapEvents: true,
      anchor: const Offset(0.5, 0.5),
    );
  }

  /// Returns adjusted positions for facilities that share exact coordinates:
  /// groups of n > 1 spread evenly on a circle around the shared point.
  /// Deterministic (sorted by id) so markers don't jump between renders.
  static Map<String, LatLng> _fannedOutPositions(List<Facility> facilities) {
    final groups = <String, List<Facility>>{};
    for (final f in facilities) {
      (groups[_pointKey(f.location)] ??= []).add(f);
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
    MarkerStyle style,
    bool showFacilityNames,
    Map<String, BitmapDescriptor> markerIconCache,
    void Function(Facility) onMarkerTap, {
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
          style,
          showName: showFacilityNames,
        );
        markerIconCache[cacheKey] = icon;
      } catch (e, stackTrace) {
        ErrorReporter.instance.report(
          e,
          stackTrace,
          context: 'MarkerManagementService.icon',
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
}
