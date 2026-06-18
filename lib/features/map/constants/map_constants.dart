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

  static const List<double> distanceOptions = [1.0, 3.0, 5.0, 10.0];

  static final Map<double, double> distanceToZoom = {
    1.0: 14.0,
    3.0: 12.5,
    5.0: 12.0,
    10.0: 11.0,
  };

  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Curve animationCurve = Curves.easeInOut;

  static const double panelBorderRadius = 20.0;
  static const double panelHandleWidth = 40.0;
  static const double panelHandleHeight = 4.0;
  static const double panelHeaderHeight = 50.0;

  static const double markerSize = 40.0;
  static const double selectedMarkerSize = 50.0;
}
