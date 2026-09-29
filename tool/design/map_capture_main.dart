// App entry point for tool/design/capture_map_backgrounds.dart. Shows only
// the app's Google Map in Beacon's map styles — no UI on top — and steps
// through the Claude Design map kit's backgrounds, logging a
// `BEACON_CAPTURE <name>` line when each is ready to screenshot.
//
// Needs the iOS Maps key the Runner app already provides; no Supabase.
// ignore_for_file: avoid_print
import 'dart:async';

import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:beacon_app/features/map/presentation/services/map_style_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const _center = LatLng(
  MapConstants.defaultLatitude,
  MapConstants.defaultLongitude,
);

/// (file name, theme, zoom): the app's list zoom and its default city zoom.
const List<(String, Brightness, double)> _states = [
  ('light_neighborhood', Brightness.light, MapConstants.listExpandZoom),
  ('light_city', Brightness.light, MapConstants.defaultZoom),
  ('dark_neighborhood', Brightness.dark, MapConstants.listExpandZoom),
  ('dark_city', Brightness.dark, MapConstants.defaultZoom),
];

/// Google Maps has no "tiles loaded" callback; give tiles time to settle.
const _settle = Duration(seconds: 8);

/// How long each state stays up after its log line, for the screenshot.
const _hold = Duration(seconds: 4);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // No status bar: designs draw their own phone chrome.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  runApp(const _MapCapture());
}

class _MapCapture extends StatefulWidget {
  const _MapCapture();

  @override
  State<_MapCapture> createState() => _MapCaptureState();
}

class _MapCaptureState extends State<_MapCapture> {
  final _ready = Completer<GoogleMapController>();
  Brightness _brightness = Brightness.light;
  String? _style;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    final controller = await _ready.future;
    for (final (name, brightness, zoom) in _states) {
      final style = await MapStyleService.loadMapStyle(brightness: brightness);
      setState(() {
        _brightness = brightness;
        _style = style;
      });
      await controller.moveCamera(CameraUpdate.newLatLngZoom(_center, zoom));
      await Future<void>.delayed(_settle);
      print('BEACON_CAPTURE $name');
      await Future<void>.delayed(_hold);
    }
    print('BEACON_CAPTURE_DONE');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _brightness == Brightness.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
      home: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: _center,
          zoom: MapConstants.listExpandZoom,
        ),
        style: _style,
        onMapCreated: _ready.complete,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
      ),
    );
  }
}
