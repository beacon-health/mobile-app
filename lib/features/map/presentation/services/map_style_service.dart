import 'dart:convert';
import 'package:flutter/services.dart';

class MapStyleService {
  static String? _cachedStyle;

  static Future<String> loadMapStyle() async {
    if (_cachedStyle != null) {
      return _cachedStyle!;
    }

    try {
      final String jsonString =
          await rootBundle.loadString('assets/map_styles/minimal_style.json');
      final List<dynamic> styleArray = json.decode(jsonString);
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
