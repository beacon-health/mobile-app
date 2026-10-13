import 'package:flutter/material.dart';

/// The Beacon wordmark, in the artwork for the current mode: brand colors on
/// a light screen, the white version on a dark one. It carries no tagline —
/// that is live text (`brandTagline`), so it can be translated, resized and
/// read aloud.
class BeaconLogo extends StatelessWidget {
  const BeaconLogo({super.key, this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark ? 'assets/beacon-logo-dark.png' : 'assets/beacon-logo.png',
      width: width,
      height: height,
      excludeFromSemantics: true,
    );
  }
}
