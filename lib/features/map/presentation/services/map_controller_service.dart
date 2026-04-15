import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/widgets/markers/marker_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapControllerService {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  String? _selectedFacilityId;

  GoogleMapController? get controller => _controller;
  Set<Marker> get markers => _markers;
  String? get selectedFacilityId => _selectedFacilityId;

  void setController(GoogleMapController controller) {
    _controller = controller;
  }

  Future<void> animateToLocation(
    double latitude,
    double longitude, {
    double? zoom,
  }) async {
    if (_controller == null) return;

    await _controller!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(latitude, longitude),
        zoom ?? MapConstants.defaultZoom,
      ),
    );
  }

  Future<void> animateToLocationWithDistance(
    double latitude,
    double longitude,
    double distance,
  ) async {
    final zoom = getZoomLevelForDistance(distance);
    await animateToLocation(latitude, longitude, zoom: zoom);
  }

  double getZoomLevelForDistance(double distance) {
    return MapConstants.distanceToZoom[distance] ?? MapConstants.defaultZoom;
  }

  Future<void> updateMarkers(
    List<Facility> facilities,
    BuildContext context, {
    required Function(String) onMarkerTap,
  }) async {
    final newMarkers = <Marker>{};

    for (final facility in facilities) {
      final markerIcon = await MarkerUtils.createFacilityMarker(
        facility.name,
        facility.isFavorite,
        facility.primaryCategory,
        context,
        showName: true,
      );

      final marker = Marker(
        markerId: MarkerId(facility.id),
        position:
            LatLng(facility.location.latitude, facility.location.longitude),
        icon: markerIcon,
        onTap: () => onMarkerTap(facility.id),
      );

      newMarkers.add(marker);
    }

    _markers = newMarkers;
  }

  void selectFacility(String? facilityId) {
    _selectedFacilityId = facilityId;
  }

  Future<void> centerOnFacility(Facility facility) async {
    await animateToLocation(
      facility.location.latitude,
      facility.location.longitude,
      zoom: MapConstants.detailZoom,
    );
  }

  Future<void> resetToDefaultLocation() async {
    await animateToLocation(
      MapConstants.defaultLatitude,
      MapConstants.defaultLongitude,
      zoom: MapConstants.defaultZoom,
    );
  }

  void dispose() {
    _controller = null;
    _markers.clear();
    _selectedFacilityId = null;
  }
}
