import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Apple's logo, drawn from the Sign in with Apple plugin's own outline of
/// it. Material's `Icons.apple` is a different drawing.
class AppleMark extends StatelessWidget {
  const AppleMark({super.key, required this.size, required this.color});

  /// The height of the box the logo is drawn in.
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // The proportions the plugin's own button gives the logo.
      width: size * _aspect,
      height: size,
      child: CustomPaint(painter: AppleLogoPainter(color: color)),
    );
  }

  static const double _aspect = 25 / 31;
}
