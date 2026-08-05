import 'dart:convert';

import 'package:flutter/services.dart';

/// Loads Google Maps JSON styles by [Brightness]. Cached per brightness — a
/// single shared cache would pin whichever style loaded first.
class MapStyleService {
  static final Map<Brightness, String> _cache = {};

  static Future<String> loadMapStyle({
    Brightness brightness = Brightness.light,
  }) async {
    final cached = _cache[brightness];
    if (cached != null) return cached;

    final filename = brightness == Brightness.dark
        ? 'dark_style.json'
        : 'minimal_style.json';
    try {
      final jsonString =
          await rootBundle.loadString('assets/map_styles/$filename');
      // Round-trip through decode/encode to validate the JSON early.
      final styleArray = json.decode(jsonString) as List<dynamic>;
      final encoded = json.encode(styleArray);
      _cache[brightness] = encoded;
      return encoded;
    } catch (e) {
      throw Exception('Failed to load map style ($filename): $e');
    }
  }

  static void clearCache() => _cache.clear();
}
