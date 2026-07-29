import 'dart:math' as math;
import 'dart:ui' as ui show ImageByteFormat, PictureRecorder;

import 'package:beacon_app/core/theme/app_theme.dart';
import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utility class for creating custom map markers.
///
/// Creates circular markers with icons based on facility category.
class MarkerUtils {
  static const double _markerSize = 100.0;
  static const double _baseFontSize = 24.0;
  static const double _nameAreaHeight = 120.0;
  static const double _horizontalPadding = 20.0;
  static const double _textPadding = 12.0;

  static final Map<String, BitmapDescriptor> _markerCache = {};

  /// Creates a custom marker for a facility.
  ///
  /// [name] is the facility name to display.
  /// [isFavorite] indicates if the facility is marked as favorite.
  /// [primaryCategory] is the main category from categoryLevel1.
  /// [showName] controls whether the facility name is shown below the marker.
  static Future<BitmapDescriptor> createFacilityMarker(
    String name,
    bool isFavorite,
    String? primaryCategory,
    BuildContext context, {
    required bool showName,
  }) async {
    final cacheKey = '${name}_${primaryCategory ?? 'default'}_$showName';

    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    final double canvasWidth =
        math.max(_markerSize, 200.0 + _horizontalPadding * 2);
    const double totalHeight = _markerSize + _nameAreaHeight;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final markerX = (canvasWidth - _markerSize) / 2;

    canvas.save();
    canvas.translate(markerX, 0);
    _drawFacilityMarker(canvas, primaryCategory);
    canvas.restore();

    if (showName && name.isNotEmpty) {
      _drawName(canvas, name, canvasWidth, markerX, _markerSize);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasWidth.ceil(), totalHeight.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final descriptor = BitmapDescriptor.bytes(
      bytes,
      imagePixelRatio: devicePixelRatio,
    );

    _markerCache[cacheKey] = descriptor;
    return descriptor;
  }

  /// Creates a cluster bubble showing the number of facilities grouped at a
  /// zoomed-out point. Cached per exact count.
  static Future<BitmapDescriptor> createClusterMarker(
    int count,
    BuildContext context,
  ) async {
    final cacheKey = 'cluster_$count';
    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    // Bubble grows with magnitude so large clusters read clearly.
    final double size = count < 10
        ? 90.0
        : count < 100
            ? 110.0
            : 130.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final radius = size * 0.42;

    // Translucent halo.
    canvas.drawCircle(
      center,
      radius * 1.18,
      Paint()..color = AppTheme.resedaGreen.withValues(alpha: 0.35),
    );
    // Main filled circle.
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = AppTheme.resedaGreen,
    );
    // White border.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    final label = count > 999 ? '999+' : '$count';
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.34,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.ceil(), size.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final descriptor = BitmapDescriptor.bytes(
      bytes,
      imagePixelRatio: devicePixelRatio,
    );

    _markerCache[cacheKey] = descriptor;
    return descriptor;
  }

  static void _drawName(
    Canvas canvas,
    String text,
    double canvasWidth,
    double markerX,
    double markerWidth,
  ) {
    if (text.isEmpty) return;

    const textStyle = TextStyle(
      color: Colors.black,
      fontSize: _baseFontSize,
      fontWeight: FontWeight.bold,
      height: 1.1,
      shadows: [
        Shadow(
          color: Colors.white,
          offset: Offset(1, 1),
          blurRadius: 3,
        ),
        Shadow(
          color: Colors.white,
          offset: Offset(-1, -1),
          blurRadius: 3,
        ),
        Shadow(
          color: Colors.white,
          offset: Offset(1, -1),
          blurRadius: 3,
        ),
        Shadow(
          color: Colors.white,
          offset: Offset(-1, 1),
          blurRadius: 3,
        ),
        Shadow(
          color: Colors.white,
          offset: Offset(0, 0),
          blurRadius: 6,
        ),
      ],
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 4,
      textAlign: TextAlign.center,
    );

    final maxTextWidth = canvasWidth - _horizontalPadding * 2;

    textPainter.layout(maxWidth: maxTextWidth);

    final textX = (canvasWidth - textPainter.width) / 2;
    const textY = _markerSize + _textPadding;

    textPainter.paint(canvas, Offset(textX, textY));
  }

  static void _drawFacilityMarker(Canvas canvas, String? category) {
    const center = Offset(_markerSize / 2, _markerSize / 2);
    const radius = _markerSize * 0.4;

    // Shadow
    canvas.drawCircle(
      center + const Offset(2, 2),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..style = PaintingStyle.fill,
    );

    // Main circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = getColorForCategory(category)
        ..style = PaintingStyle.fill,
    );

    // Border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Icon
    final icon = getIconForCategory(category);
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: _markerSize * 0.45,
          fontFamily: icon.fontFamily,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (_markerSize - textPainter.width) / 2,
        (_markerSize - textPainter.height) / 2,
      ),
    );
  }

  /// Returns the icon for one of the [FacilityCategories] group names.
  static IconData getIconForCategory(String? category) {
    switch (category) {
      case FacilityCategories.groupHealthCare:
        return Icons.medical_services;
      case FacilityCategories.groupMentalHealth:
        return Icons.psychology;
      case FacilityCategories.groupBasicNeeds:
        return Icons.volunteer_activism;
      case FacilityCategories.groupHousingShelter:
        return Icons.night_shelter;
      case FacilityCategories.groupCommunity:
        return Icons.groups;
      case FacilityCategories.groupSpecialized:
        return Icons.diversity_3;
      default:
        return Icons.place;
    }
  }

  /// Returns the color for one of the [FacilityCategories] group names.
  ///
  /// Uses [AppTheme] category colors as the single source of truth.
  static Color getColorForCategory(String? category) {
    switch (category) {
      case FacilityCategories.groupHealthCare:
        return AppTheme.healthCare;
      case FacilityCategories.groupMentalHealth:
        return AppTheme.mentalHealth;
      case FacilityCategories.groupBasicNeeds:
        return AppTheme.basicNeeds;
      case FacilityCategories.groupHousingShelter:
        return AppTheme.housingShelter;
      case FacilityCategories.groupCommunity:
        return AppTheme.communityResources;
      case FacilityCategories.groupSpecialized:
        return AppTheme.specializedServices;
      default:
        return AppTheme.paynesGray;
    }
  }

  static void clearCache() {
    _markerCache.clear();
  }
}
