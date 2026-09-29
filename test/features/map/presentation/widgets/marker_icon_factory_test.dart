import 'dart:typed_data';

import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:beacon_app/features/map/presentation/widgets/markers/marker_icon_factory.dart';
import 'package:flutter_test/flutter_test.dart';

/// Width and height from a PNG's IHDR chunk.
(int, int) _pngSize(Uint8List png) {
  final data = ByteData.sublistView(png);
  return (data.getUint32(16), data.getUint32(20));
}

/// The Claude Design map kit (.design-sync/map-kit.css) sizes its pins and
/// cluster bubbles from these bitmaps, so their dimensions are a contract.
void main() {
  testWidgets('facility pins render at the documented canvas size',
      (tester) async {
    await tester.runAsync(() async {
      final png = await MarkerUtils.facilityMarkerPng(
        FacilityCategories.groupHealthCare,
      );
      expect(png.sublist(1, 4), 'PNG'.codeUnits);
      final size = MarkerUtils.facilityMarkerCanvasSize;
      expect(_pngSize(png), (size.width.ceil(), size.height.ceil()));
    });
  });

  testWidgets('cluster bubbles grow with the count', (tester) async {
    await tester.runAsync(() async {
      final widths = [
        for (final count in const [7, 42, 180])
          _pngSize(await MarkerUtils.clusterMarkerPng(count)).$1,
      ];
      expect(widths, [90, 110, 130]);
    });
  });
}
