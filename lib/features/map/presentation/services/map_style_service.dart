import 'dart:convert';

import 'package:flutter/services.dart';

/// Loads custom Google Maps JSON styles.
///
/// **Design note:** We intentionally always serve the light/minimal style,
/// even when the app is in dark mode. The dark JSON style makes road
/// geometry and labels nearly invisible at typical zoom levels (matching
/// Google's "Night Mode" template) — users reported the map looked broken
/// even though markers were rendering correctly. Light tiles are far more
/// legible alongside our dark UI chrome. If you need to re-enable the dark
/// style later, replace this method body with the brightness-branched
/// implementation from git history.
class MapStyleService {
  static String? _cachedStyle;

  /// Loads the active map style. The [brightness] parameter is accepted for
  /// call-site compatibility but currently ignored — see class doc.
  static Future<String> loadMapStyle({
    Brightness brightness = Brightness.light,
  }) async {
    if (_cachedStyle != null) return _cachedStyle!;

    try {
      const filename = 'minimal_style.json';
      final jsonString =
          await rootBundle.loadString('assets/map_styles/$filename');
      final styleArray = json.decode(jsonString) as List<dynamic>;
      _cachedStyle = json.encode(styleArray);
      return _cachedStyle!;
    } catch (e) {
      throw Exception('Failed to load map style: $e');
    }
  }

  static void clearCache() {
    _cachedStyle = null;
  }
}
