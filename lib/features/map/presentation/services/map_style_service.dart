import 'dart:convert';

import 'package:flutter/services.dart';

class MapStyleService {
  static String? _cachedLightStyle;
  static String? _cachedDarkStyle;

  static Future<String> loadMapStyle({
    Brightness brightness = Brightness.light,
  }) async {
    final isDark = brightness == Brightness.dark;

    if (!isDark && _cachedLightStyle != null) return _cachedLightStyle!;
    if (isDark && _cachedDarkStyle != null) return _cachedDarkStyle!;

    try {
      final filename =
          isDark ? 'dark_style.json' : 'minimal_style.json';
      final String jsonString =
          await rootBundle.loadString('assets/map_styles/$filename');
      final styleArray = json.decode(jsonString) as List<dynamic>;
      final result = json.encode(styleArray);

      if (isDark) {
        _cachedDarkStyle = result;
      } else {
        _cachedLightStyle = result;
      }
      return result;
    } catch (e) {
      throw Exception('Failed to load map style: $e');
    }
  }

  static void clearCache() {
    _cachedLightStyle = null;
    _cachedDarkStyle = null;
  }
}
