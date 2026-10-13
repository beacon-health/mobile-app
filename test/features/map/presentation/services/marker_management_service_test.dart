import 'package:beacon_app/features/map/constants/map_constants.dart';
import 'package:beacon_app/features/map/presentation/services/marker_management_service.dart';
import 'package:beacon_app/features/map/utils/map_geometry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../helpers/test_facility.dart';

void main() {
  const chicago = LatLng(41.8781, -87.6298);

  // Two programs at one street address, and one a few blocks away.
  final twinA = createTestFacility(id: 'a', location: chicago);
  final twinB = createTestFacility(id: 'b', location: chicago);
  final apart = createTestFacility(
    id: 'c',
    location: LatLng(chicago.latitude + 0.01, chicago.longitude),
  );

  List<List<String>> groups(double zoom) => [
        for (final group in MarkerManagementService.groupForZoom(
          [twinA, twinB, apart],
          zoom,
        ))
          [for (final f in group) f.id],
      ];

  group('MarkerManagementService.groupForZoom', () {
    test('zoomed far out, everything nearby shares a bubble', () {
      expect(groups(6), [
        ['a', 'b', 'c'],
      ]);
    });

    test('at the cluster threshold, only a shared address still groups', () {
      expect(
        groups(MapConstants.clusterZoomThreshold),
        unorderedEquals([
          ['a', 'b'],
          ['c'],
        ]),
      );
    });

    test('a shared address stays grouped until its pins can fan out', () {
      final fanOut = MarkerManagementService.fanOutZoom(chicago.latitude);

      // 1.0.0 drew these as two pins on top of each other from zoom 14 up,
      // which looked like a single pin until the map was zoomed in three
      // more levels.
      expect(groups(fanOut - 0.1), anyElement(equals(['a', 'b'])));
      expect(groups(fanOut), [
        ['a'],
        ['b'],
        ['c'],
      ]);
    });

    test('the reveal zoom is past the fan-out zoom, with room for rounding',
        () {
      final fanOut = MarkerManagementService.fanOutZoom(chicago.latitude);
      final reveal = MarkerManagementService.fanOutRevealZoom(chicago.latitude);
      expect(reveal, greaterThan(fanOut));
      expect(groups(reveal - 0.1).length, 3);
      // Sanity: at the fan-out zoom the pins really are a tappable distance
      // from the point they share.
      expect(
        25 / MapGeometry.metersPerPixel(chicago.latitude, fanOut),
        closeTo(26, 0.01),
      );
    });

    test('a facility with no coordinates is left off the map', () {
      final unlocated = createTestFacility(
        id: 'nowhere',
        location: const LatLng(0, 0),
      );
      for (final zoom in [6.0, 15.0, 18.0]) {
        final ids =
            MarkerManagementService.groupForZoom([unlocated, apart], zoom)
                .expand((g) => g)
                .map((f) => f.id);
        expect(ids, ['c'], reason: 'zoom $zoom');
      }
    });
  });
}
