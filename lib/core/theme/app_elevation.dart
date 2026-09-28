import 'package:flutter/painting.dart';

/// Shadow presets. Flat by default; a shadow means "floats above the map or
/// page", never decoration.
abstract final class AppShadows {
  /// Resting containers on the page: Home lists, filter chips.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Elements floating over the map: search bar, "Search this area" pill, the
  /// Home map preview, the single-facility card.
  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Sheets and sticky footers that sit above content, casting upward.
  static const List<BoxShadow> sheet = [
    BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, -4)),
  ];
}
