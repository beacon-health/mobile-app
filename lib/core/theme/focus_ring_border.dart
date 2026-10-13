import 'package:beacon_app/core/theme/app_sizes.dart';
import 'package:flutter/painting.dart';

/// A rounded rectangle that also draws a focus ring just outside itself: a
/// line [AppSizes.focusRingWidth] thick, [AppSizes.focusRingGap] clear of the
/// edge. The gap is what keeps the ring visible around a filled button of the
/// ring's own color.
///
/// `AppTheme` swaps this in as a button's shape while it holds keyboard or
/// switch-access focus.
class FocusRingBorder extends RoundedRectangleBorder {
  const FocusRingBorder({
    required this.ringColor,
    super.side,
    super.borderRadius,
  });

  final Color ringColor;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    super.paint(canvas, rect, textDirection: textDirection);
    const distance = AppSizes.focusRingGap + AppSizes.focusRingWidth / 2;
    canvas.drawRRect(
      borderRadius.resolve(textDirection).toRRect(rect).inflate(distance),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppSizes.focusRingWidth
        ..color = ringColor,
    );
  }

  @override
  FocusRingBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) =>
      FocusRingBorder(
        ringColor: ringColor,
        side: side ?? this.side,
        borderRadius: borderRadius ?? this.borderRadius,
      );

  @override
  ShapeBorder scale(double t) => FocusRingBorder(
        ringColor: ringColor,
        side: side.scale(t),
        borderRadius: borderRadius * t,
      );

  @override
  bool operator ==(Object other) =>
      other is FocusRingBorder &&
      other.ringColor == ringColor &&
      other.side == side &&
      other.borderRadius == borderRadius;

  @override
  int get hashCode => Object.hash(ringColor, side, borderRadius);
}
