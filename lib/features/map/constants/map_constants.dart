import 'package:flutter/material.dart';

class MapConstants {
  static const double defaultZoom = 12.0;
  static const double detailZoom = 15.0;
  static const double markerZoom = 16.0;

  /// At or above this zoom, markers render individually; below it, nearby
  /// facilities are clustered into count bubbles.
  static const double clusterZoomThreshold = 14.0;

  static const double searchBarAreaHeight = 160.0;
  static const double panelMinHeight = 80.0;
  static const double panelDefaultHeightRatio = 0.30;
  static const double panelBottomOffset = 60.0;

  static const double minFlickVelocity = 500.0;
  static const double panelDragThreshold = 3.0;

  static const double defaultLatitude = 41.8781;
  static const double defaultLongitude = -87.6298;

  /// Fixed query radius. The Distance filter was removed in favor of the
  /// "Search this area" button — every query (initial, ZIP change, search
  /// here) uses this radius.
  static const double defaultRadiusMiles = 5.0;

  /// Zoom that roughly frames a [defaultRadiusMiles] query.
  static const double radiusFramingZoom = 12.0;

  /// Zoom used when a list row is expanded — centers the facility closer than
  /// the default region view, but below the tight single-card [markerZoom].
  static const double listExpandZoom = 14.0;

  /// Canonical (locale-independent) location labels. Stored/compared
  /// internally so language switches can't break the "is this a placeholder
  /// label?" logic; widgets translate them at display time.
  static const String currentLocationSentinel = 'Current Location';
  static const String mapAreaSentinel = 'Map area';

  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Curve animationCurve = Curves.easeInOut;

  static const double panelBorderRadius = 20.0;
  static const double panelHandleWidth = 40.0;
  static const double panelHandleHeight = 4.0;
  static const double panelHeaderHeight = 50.0;

  static const double markerSize = 40.0;
  static const double selectedMarkerSize = 50.0;
}
