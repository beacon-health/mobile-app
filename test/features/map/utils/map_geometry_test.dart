import 'dart:ui';

import 'package:beacon_app/features/map/utils/map_geometry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../helpers/fake_google_maps.dart';

void main() {
  const chicago = LatLng(41.8781, -87.6298);

  group('MapGeometry', () {
    test('metersPerPixel halves with each zoom level', () {
      final z12 = MapGeometry.metersPerPixel(chicago.latitude, 12);
      final z13 = MapGeometry.metersPerPixel(chicago.latitude, 13);
      expect(z12, closeTo(28.45, 0.05));
      expect(z13, closeTo(z12 / 2, 1e-9));
    });

    test('zoomForScale inverts metersPerPixel', () {
      final zoom = MapGeometry.zoomForScale(
        meters: 25,
        pixels: 26,
        latitude: chicago.latitude,
      );
      expect(
        MapGeometry.metersPerPixel(chicago.latitude, zoom) * 26,
        closeTo(25, 1e-6),
      );
    });

    test('distanceMeters matches a known distance', () {
      // One degree of latitude is about 111.2 km everywhere.
      expect(
        MapGeometry.distanceMeters(
          chicago,
          LatLng(chicago.latitude + 1, chicago.longitude),
        ),
        closeTo(111195, 100),
      );
      expect(MapGeometry.distanceMeters(chicago, chicago), 0);
    });

    test('boundsOf wraps every point, and is null for none', () {
      final bounds = MapGeometry.boundsOf(const [
        LatLng(41.9, -87.7),
        LatLng(41.8, -87.6),
        LatLng(41.85, -87.65),
      ])!;
      expect(bounds.southwest, const LatLng(41.8, -87.7));
      expect(bounds.northeast, const LatLng(41.9, -87.6));
      expect(MapGeometry.centerOf(bounds).latitude, closeTo(41.85, 1e-9));
      expect(MapGeometry.boundsOf(const []), isNull);
    });

    test('zoomToFit shows the whole box and no closer', () {
      final bounds = LatLngBounds(
        southwest: const LatLng(41.86, -87.66),
        northeast: const LatLng(41.90, -87.60),
      );
      const viewport = Size(300, 400);
      final zoom = MapGeometry.zoomToFit(bounds, viewport);

      // At that zoom the box fits the viewport…
      final visible = FakeGoogleMaps.visibleRegionOf(
        CameraPosition(target: MapGeometry.centerOf(bounds), zoom: zoom),
        viewport,
      );
      expect(visible.southwest.latitude, lessThanOrEqualTo(41.86 + 1e-6));
      expect(visible.northeast.latitude, greaterThanOrEqualTo(41.90 - 1e-6));
      expect(visible.southwest.longitude, lessThanOrEqualTo(-87.66 + 1e-6));
      expect(visible.northeast.longitude, greaterThanOrEqualTo(-87.60 - 1e-6));

      // …and half a level closer it no longer does.
      final closer = FakeGoogleMaps.visibleRegionOf(
        CameraPosition(target: MapGeometry.centerOf(bounds), zoom: zoom + 0.5),
        viewport,
      );
      expect(
        closer.contains(bounds.southwest) && closer.contains(bounds.northeast),
        isFalse,
      );
    });

    test('zoomToFit of a single point is unbounded', () {
      final point = LatLngBounds(southwest: chicago, northeast: chicago);
      expect(
        MapGeometry.zoomToFit(point, const Size(300, 400)),
        double.infinity,
      );
    });

    test('targetShowing shifts the camera so the point sits above center', () {
      const zoom = 16.0;
      final target = MapGeometry.targetShowing(
        chicago,
        zoom: zoom,
        pixelsAboveCenter: 150,
      );

      // The camera points south of the facility by 150 px of ground…
      expect(target.longitude, chicago.longitude);
      expect(target.latitude, lessThan(chicago.latitude));
      expect(
        MapGeometry.distanceMeters(target, chicago),
        closeTo(150 * MapGeometry.metersPerPixel(chicago.latitude, zoom), 0.5),
      );
      // …and no shift at all leaves it centered.
      final centered = MapGeometry.targetShowing(
        chicago,
        zoom: zoom,
        pixelsAboveCenter: 0,
      );
      expect(centered.latitude, closeTo(chicago.latitude, 1e-9));
    });
  });
}
