import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Web-Mercator arithmetic for positioning the Google map's camera.
///
/// Everything is in logical pixels: at zoom `z` the whole world is
/// `256 * 2^z` logical pixels wide on both iOS and Android.
class MapGeometry {
  MapGeometry._();

  static const double _earthRadiusMeters = 6371000;
  static const double _equatorMetersPerPixelAtZoom0 = 156543.03392;
  static const double _tileSize = 256;

  /// Ground distance covered by one logical pixel at [latitude] and [zoom].
  static double metersPerPixel(double latitude, double zoom) =>
      _equatorMetersPerPixelAtZoom0 *
      math.cos(latitude * math.pi / 180) /
      math.pow(2, zoom);

  /// The zoom at which [meters] on the ground spans [pixels] on screen.
  static double zoomForScale({
    required double meters,
    required double pixels,
    required double latitude,
  }) {
    final metersPerPixel = meters / pixels;
    return _log2(
      _equatorMetersPerPixelAtZoom0 *
          math.cos(latitude * math.pi / 180) /
          metersPerPixel,
    );
  }

  /// Great-circle distance between two points.
  static double distanceMeters(LatLng a, LatLng b) {
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return _earthRadiusMeters * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  /// The smallest box holding every point, or null when there are none.
  static LatLngBounds? boundsOf(Iterable<LatLng> points) {
    if (points.isEmpty) return null;
    var south = points.first.latitude;
    var north = south;
    var west = points.first.longitude;
    var east = west;
    for (final p in points) {
      south = math.min(south, p.latitude);
      north = math.max(north, p.latitude);
      west = math.min(west, p.longitude);
      east = math.max(east, p.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  static LatLng centerOf(LatLngBounds bounds) => LatLng(
        (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
        (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
      );

  /// The closest zoom at which [bounds] still fits inside [viewport]. A box
  /// with no extent (a single point) fits at any zoom, so it returns
  /// [double.infinity] — clamp the result.
  static double zoomToFit(LatLngBounds bounds, Size viewport) {
    final lngSpan =
        (bounds.northeast.longitude - bounds.southwest.longitude).abs();
    final ySpan = (_mercatorY(bounds.southwest.latitude) -
            _mercatorY(bounds.northeast.latitude))
        .abs();

    final zoomForWidth = lngSpan == 0
        ? double.infinity
        : _log2(viewport.width / (_tileSize * lngSpan / 360));
    final zoomForHeight = ySpan == 0
        ? double.infinity
        : _log2(viewport.height / (_tileSize * ySpan));
    return math.min(zoomForWidth, zoomForHeight);
  }

  /// Where the camera must point, at [zoom], to draw [point]
  /// [pixelsAboveCenter] logical pixels above the middle of the map. Used to
  /// center something in the strip a bottom sheet leaves visible.
  static LatLng targetShowing(
    LatLng point, {
    required double zoom,
    required double pixelsAboveCenter,
  }) {
    final worldPixels = _tileSize * math.pow(2, zoom);
    final centerY =
        _mercatorY(point.latitude) + pixelsAboveCenter / worldPixels;
    return LatLng(_latitudeFromMercatorY(centerY), point.longitude);
  }

  /// Latitude as a 0–1 fraction of the Mercator world, north at 0.
  static double _mercatorY(double latitude) {
    final sinLat = math.sin(latitude * math.pi / 180);
    return 0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi);
  }

  static double _latitudeFromMercatorY(double y) {
    final n = math.pi * (1 - 2 * y);
    // atan(sinh(n)), written out because dart:math has no sinh.
    return math.atan((math.exp(n) - math.exp(-n)) / 2) * 180 / math.pi;
  }

  static double _log2(num x) => math.log(x) / math.ln2;
}
