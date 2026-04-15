import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/models/facility_model.dart';
import '../widgets/markers/marker_utils.dart';

/// Service for creating and managing map markers for facilities.
///
/// Simplified implementation without clustering since we're working
/// with a small dataset (6 facilities).
class MarkerManagementService {
  /// Creates markers for all facilities.
  static Future<Set<Marker>> createMarkersForFacilities(
    List<Facility> facilities,
    BuildContext context,
    bool showFacilityNames,
    Map<String, BitmapDescriptor> markerIconCache,
    Function(Facility) onMarkerTap,
  ) async {
    final markers = <Marker>{};

    for (final facility in facilities) {
      try {
        final marker = await _createMarkerForFacility(
          facility,
          context,
          showFacilityNames,
          markerIconCache,
          onMarkerTap,
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

  static Future<Marker> _createMarkerForFacility(
    Facility facility,
    BuildContext context,
    bool showFacilityNames,
    Map<String, BitmapDescriptor> markerIconCache,
    Function(Facility) onMarkerTap,
  ) async {
    final markerId = MarkerId(facility.id);
    final position = LatLng(
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
