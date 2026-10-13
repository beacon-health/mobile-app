import 'package:beacon_app/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// A dashed vertical rule, lighter than a [Divider]: it separates columns of
/// one list rather than one section from the next. Takes its parent's height.
class DashedVerticalDivider extends StatelessWidget {
  const DashedVerticalDivider({super.key, this.width = AppSpacing.xl});

  /// The space the rule sits in the middle of.
  final double width;

  @override
  Widget build(BuildContext context) {
    final divider = DividerTheme.of(context).color ??
        Theme.of(context).colorScheme.outlineVariant;
    return SizedBox(
      width: width,
      child: CustomPaint(
        painter: _DashedLinePainter(
          divider.withValues(alpha: AppOpacity.subtleDivider),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = AppSizes.border;
    final x = size.width / 2;
    for (var y = 0.0; y < size.height; y += 2 * AppSpacing.xs) {
      final end = (y + AppSpacing.xs).clamp(0.0, size.height);
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
