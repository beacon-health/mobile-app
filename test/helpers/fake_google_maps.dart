import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

/// One `GoogleMap` widget as [FakeGoogleMaps] sees it.
class FakeMap {
  FakeMap(this.mapId, this.initialCamera) : camera = initialCamera;

  final int mapId;
  final CameraPosition initialCamera;

  /// Where the camera is now.
  CameraPosition camera;

  /// The options the widget has asked for (my-location dot, gestures, …).
  MapConfiguration configuration = const MapConfiguration();

  /// The markers currently on the map.
  final Map<MarkerId, Marker> markers = {};

  /// Every camera animation the app requested, oldest first.
  final List<CameraPosition> animations = [];

  /// The widget's size in logical pixels, used to work out what is visible.
  Size viewSize = Size.zero;

  /// While set, "what zoom are you at?" waits on it before answering with
  /// the zoom at the moment it was asked — a slow platform round trip, during
  /// which the camera may have moved on.
  Completer<void>? zoomAnswerGate;

  bool disposed = false;

  CameraPosition? get lastAnimation =>
      animations.isEmpty ? null : animations.last;

  /// Count bubbles — the app gives those ids starting with `cluster_`.
  List<Marker> get clusterMarkers => [
        for (final marker in markers.values)
          if (marker.markerId.value.startsWith('cluster_')) marker,
      ];

  /// Markers standing for a single facility.
  List<Marker> get facilityMarkers => [
        for (final marker in markers.values)
          if (!marker.markerId.value.startsWith('cluster_')) marker,
      ];
}

/// Stands in for the native Google Maps SDK, so widgets that contain a
/// `GoogleMap` can run under `flutter test`. It keeps a camera per map,
/// answers the questions the app asks of it (zoom, visible region), records
/// what the app tells it (markers, animations), and lets a test play the
/// user: move the camera, tap a marker, tap the map.
///
/// Animations arrive instantly unless [holdAnimations] is set.
class FakeGoogleMaps extends GoogleMapsFlutterPlatform {
  /// Creates the fake and makes it the plugin's platform implementation for
  /// the current test.
  FakeGoogleMaps.install() {
    GoogleMapsFlutterPlatform.instance = this;
  }

  /// Maps by creation id, in the order their widgets were built.
  final Map<int, FakeMap> maps = {};

  /// When true, an animation is recorded but the camera stays put until
  /// [finishAnimation] — for testing what happens mid-flight.
  bool holdAnimations = false;

  // Asynchronous, like the real platform channel: callbacks land after the
  // call that caused them returns, so pump once before asserting on them.
  final StreamController<MapEvent<Object?>> _events =
      StreamController<MapEvent<Object?>>.broadcast();

  /// The map whose widget asked for [zoom] as its starting zoom. The app's
  /// two maps differ there, which is the simplest way to tell them apart.
  FakeMap mapStartingAtZoom(double zoom) =>
      maps.values.firstWhere((map) => map.initialCamera.zoom == zoom);

  // --- What a test does to the map -----------------------------------------

  /// The user drags or pinches the map to [position].
  void userMovesCamera(FakeMap map, CameraPosition position) {
    _events.add(CameraMoveStartedEvent(map.mapId));
    _arrive(map, position);
  }

  /// Completes the most recent animation recorded while [holdAnimations].
  void finishAnimation(FakeMap map) => _arrive(map, map.animations.last);

  void tapMarker(FakeMap map, MarkerId markerId) =>
      _events.add(MarkerTapEvent(map.mapId, markerId));

  void tapMap(FakeMap map, LatLng position) =>
      _events.add(MapTapEvent(map.mapId, position));

  void _arrive(FakeMap map, CameraPosition position) {
    map.camera = position;
    _events
      ..add(CameraMoveEvent(map.mapId, position))
      ..add(CameraIdleEvent(map.mapId));
  }

  // --- What the plugin asks of the platform --------------------------------

  @override
  Future<void> init(int mapId) async {}

  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) {
    final isNew = !maps.containsKey(creationId);
    final map = maps.putIfAbsent(
      creationId,
      () => FakeMap(creationId, widgetConfiguration.initialCameraPosition),
    );
    if (isNew) {
      // Later changes arrive through the update calls below.
      map.configuration = mapConfiguration;
      for (final marker in mapObjects.markers) {
        map.markers[marker.markerId] = marker;
      }
    }
    return _FakeMapView(
      key: ValueKey<int>(creationId),
      map: map,
      onCreated: () => onPlatformViewCreated(creationId),
    );
  }

  @override
  Future<void> updateMapConfiguration(
    MapConfiguration configuration, {
    required int mapId,
  }) async {
    final map = maps[mapId]!;
    map.configuration = map.configuration.applyDiff(configuration);
  }

  @override
  Future<void> updateMarkers(
    MarkerUpdates markerUpdates, {
    required int mapId,
  }) async {
    final markers = maps[mapId]!.markers;
    markerUpdates.markerIdsToRemove.forEach(markers.remove);
    for (final marker in [
      ...markerUpdates.markersToAdd,
      ...markerUpdates.markersToChange,
    ]) {
      markers[marker.markerId] = marker;
    }
  }

  @override
  Future<void> updatePolygons(
    PolygonUpdates polygonUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updatePolylines(
    PolylineUpdates polylineUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateCircles(
    CircleUpdates circleUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateHeatmaps(
    HeatmapUpdates heatmapUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateTileOverlays({
    required Set<TileOverlay> newTileOverlays,
    required int mapId,
  }) async {}

  @override
  Future<void> updateClusterManagers(
    ClusterManagerUpdates clusterManagerUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> updateGroundOverlays(
    GroundOverlayUpdates groundOverlayUpdates, {
    required int mapId,
  }) async {}

  @override
  Future<void> animateCamera(
    CameraUpdate cameraUpdate, {
    required int mapId,
  }) async {
    final map = maps[mapId]!;
    final target = _resolve(cameraUpdate, map.camera);
    map.animations.add(target);
    if (!holdAnimations) _arrive(map, target);
  }

  @override
  Future<void> animateCameraWithConfiguration(
    CameraUpdate cameraUpdate,
    CameraUpdateAnimationConfiguration configuration, {
    required int mapId,
  }) =>
      animateCamera(cameraUpdate, mapId: mapId);

  @override
  Future<void> moveCamera(
    CameraUpdate cameraUpdate, {
    required int mapId,
  }) async {
    final map = maps[mapId]!;
    final target = _resolve(cameraUpdate, map.camera);
    // A move to where the camera already is produces no callbacks.
    if (target != map.camera) _arrive(map, target);
  }

  @override
  Future<void> setMapStyle(String? mapStyle, {required int mapId}) async {}

  @override
  Future<String?> getStyleError({required int mapId}) async => null;

  @override
  Future<double> getZoomLevel({required int mapId}) async {
    final map = maps[mapId]!;
    final zoom = map.camera.zoom;
    await map.zoomAnswerGate?.future;
    return zoom;
  }

  @override
  Future<LatLngBounds> getVisibleRegion({required int mapId}) async {
    final map = maps[mapId]!;
    return visibleRegionOf(map.camera, map.viewSize);
  }

  @override
  void dispose({required int mapId}) => maps[mapId]?.disposed = true;

  Stream<T> _eventsOf<T extends MapEvent<Object?>>(int mapId) => _events.stream
      .where((event) => event.mapId == mapId && event is T)
      .cast<T>();

  @override
  Stream<CameraMoveStartedEvent> onCameraMoveStarted({required int mapId}) =>
      _eventsOf<CameraMoveStartedEvent>(mapId);

  @override
  Stream<CameraMoveEvent> onCameraMove({required int mapId}) =>
      _eventsOf<CameraMoveEvent>(mapId);

  @override
  Stream<CameraIdleEvent> onCameraIdle({required int mapId}) =>
      _eventsOf<CameraIdleEvent>(mapId);

  @override
  Stream<MarkerTapEvent> onMarkerTap({required int mapId}) =>
      _eventsOf<MarkerTapEvent>(mapId);

  @override
  Stream<InfoWindowTapEvent> onInfoWindowTap({required int mapId}) =>
      _eventsOf<InfoWindowTapEvent>(mapId);

  @override
  Stream<MarkerDragStartEvent> onMarkerDragStart({required int mapId}) =>
      _eventsOf<MarkerDragStartEvent>(mapId);

  @override
  Stream<MarkerDragEvent> onMarkerDrag({required int mapId}) =>
      _eventsOf<MarkerDragEvent>(mapId);

  @override
  Stream<MarkerDragEndEvent> onMarkerDragEnd({required int mapId}) =>
      _eventsOf<MarkerDragEndEvent>(mapId);

  @override
  Stream<PolylineTapEvent> onPolylineTap({required int mapId}) =>
      _eventsOf<PolylineTapEvent>(mapId);

  @override
  Stream<PolygonTapEvent> onPolygonTap({required int mapId}) =>
      _eventsOf<PolygonTapEvent>(mapId);

  @override
  Stream<CircleTapEvent> onCircleTap({required int mapId}) =>
      _eventsOf<CircleTapEvent>(mapId);

  @override
  Stream<GroundOverlayTapEvent> onGroundOverlayTap({required int mapId}) =>
      _eventsOf<GroundOverlayTapEvent>(mapId);

  @override
  Stream<MapTapEvent> onTap({required int mapId}) =>
      _eventsOf<MapTapEvent>(mapId);

  @override
  Stream<MapLongPressEvent> onLongPress({required int mapId}) =>
      _eventsOf<MapLongPressEvent>(mapId);

  @override
  Stream<ClusterTapEvent> onClusterTap({required int mapId}) =>
      _eventsOf<ClusterTapEvent>(mapId);

  /// Turns the camera updates the app uses into the position they lead to.
  static CameraPosition _resolve(CameraUpdate update, CameraPosition from) {
    return switch (update) {
      CameraUpdateNewCameraPosition(:final cameraPosition) => cameraPosition,
      CameraUpdateNewLatLngZoom(:final latLng, :final zoom) =>
        CameraPosition(target: latLng, zoom: zoom),
      CameraUpdateNewLatLng(:final latLng) =>
        CameraPosition(target: latLng, zoom: from.zoom),
      CameraUpdateZoomTo(:final zoom) =>
        CameraPosition(target: from.target, zoom: zoom),
      _ => throw UnimplementedError(
          'FakeGoogleMaps does not model ${update.runtimeType}',
        ),
    };
  }

  /// The area a camera shows in a view of [size] logical pixels, by the same
  /// Web Mercator rules the real SDK uses.
  static LatLngBounds visibleRegionOf(CameraPosition camera, Size size) {
    if (size.isEmpty) {
      return LatLngBounds(southwest: camera.target, northeast: camera.target);
    }
    final worldPixels = 256 * math.pow(2, camera.zoom);
    final halfLng = size.width / 2 / worldPixels * 360;
    final centerY = _mercatorY(camera.target.latitude);
    final halfY = size.height / 2 / worldPixels;
    return LatLngBounds(
      southwest: LatLng(
        _latitudeAt(centerY + halfY),
        camera.target.longitude - halfLng,
      ),
      northeast: LatLng(
        _latitudeAt(centerY - halfY),
        camera.target.longitude + halfLng,
      ),
    );
  }

  static double _mercatorY(double latitude) {
    final sinLat = math.sin(latitude * math.pi / 180);
    return 0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi);
  }

  static double _latitudeAt(double y) {
    final n = math.pi * (1 - 2 * y);
    return math.atan((math.exp(n) - math.exp(-n)) / 2) * 180 / math.pi;
  }
}

/// The widget standing where the native map view would be. It reports its
/// size, and tells the plugin the "platform view" exists once it is on
/// screen, as the real one does.
class _FakeMapView extends StatefulWidget {
  const _FakeMapView({
    required this.map,
    required this.onCreated,
    super.key,
  });

  final FakeMap map;
  final VoidCallback onCreated;

  @override
  State<_FakeMapView> createState() => _FakeMapViewState();
}

class _FakeMapViewState extends State<_FakeMapView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onCreated();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        widget.map.viewSize = constraints.biggest;
        return const SizedBox.expand();
      },
    );
  }
}
