import 'package:beacon_app/features/map/domain/models/facility_model.dart';
import 'package:beacon_app/features/map/presentation/widgets/facility/facility_list_panel.dart';
import 'package:beacon_app/features/map/utils/facility_formatting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_facility.dart';

void main() {
  setUp(mockPlatformServices);

  Future<void> pumpPanel(
    WidgetTester tester, {
    required List<Facility> facilities,
    int totalMatches = 0,
    bool isLoading = false,
    bool isPanelOpen = true,
    bool isFullyExpanded = false,
    VoidCallback? onRequestFacility,
    Locale locale = const Locale('en'),
    bool settle = true,
  }) =>
      pumpThemed(
        tester,
        Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: FacilityListPanel(
              facilities: facilities,
              totalMatches: totalMatches,
              scrollController: ScrollController(),
              isLoading: isLoading,
              isPanelOpen: isPanelOpen,
              isFullyExpanded: isFullyExpanded,
              isSearchActive: false,
              expandedFacilityId: null,
              onToggleFacilityExpansion: (_) {},
              onToggleFavorite: (_) {},
              onLaunchUrl: (_) async {},
              buildCategoryIcon: FacilityCategoryIcons.buildCategoryIcon,
              onRequestFacility: onRequestFacility,
            ),
          ),
        ),
        locale: locale,
        settle: settle,
      );

  group('FacilityListPanel header', () {
    testWidgets('counts what is listed', (tester) async {
      await pumpPanel(
        tester,
        facilities: [
          createTestFacility(id: 'a', name: 'A'),
          createTestFacility(id: 'b', name: 'B'),
        ],
        totalMatches: 2,
      );
      expect(find.text('2 resources in this area'), findsOneWidget);
    });

    testWidgets('uses the singular for one', (tester) async {
      await pumpPanel(
        tester,
        facilities: [createTestFacility()],
        totalMatches: 1,
      );
      expect(find.text('1 resource in this area'), findsOneWidget);
    });

    testWidgets('is translated', (tester) async {
      await pumpPanel(
        tester,
        facilities: [createTestFacility(), createTestFacility(id: 'b')],
        totalMatches: 2,
        locale: const Locale('es'),
      );
      expect(find.text('2 recursos en esta zona'), findsOneWidget);
    });

    testWidgets('prompts to swipe up when collapsed', (tester) async {
      await pumpPanel(
        tester,
        facilities: [createTestFacility()],
        totalMatches: 1,
        isPanelOpen: false,
      );
      expect(find.text('Swipe up to view resources'), findsOneWidget);
      expect(find.text('Test Facility'), findsNothing);
    });

    testWidgets('stays on one line when the text is large', (tester) async {
      // A wrapped title used to spill out of the fixed-height header.
      tester.platformDispatcher.textScaleFactorTestValue = 2.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpPanel(
        tester,
        facilities: [createTestFacility()],
        totalMatches: 1,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('FacilityListPanel body', () {
    testWidgets('shows a spinner while loading', (tester) async {
      // The spinner animates forever, so this screen can't be settled.
      await pumpPanel(
        tester,
        facilities: const [],
        isLoading: true,
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No facilities in this area'), findsNothing);
    });

    testWidgets('an empty area offers a request and names the coverage',
        (tester) async {
      var requests = 0;
      await pumpPanel(
        tester,
        facilities: const [],
        isFullyExpanded: true,
        onRequestFacility: () => requests++,
      );

      expect(find.text('No facilities in this area'), findsOneWidget);
      expect(find.textContaining('facilities in Illinois'), findsOneWidget);
      await tester.tap(find.text('Request a facility'));
      expect(requests, 1);
    });

    testWidgets('matches that are merely off screen get a zoom-out hint',
        (tester) async {
      await pumpPanel(
        tester,
        facilities: const [],
        totalMatches: 12,
        isFullyExpanded: true,
        onRequestFacility: () {},
      );

      expect(find.text('Nothing in this part of the map'), findsOneWidget);
      expect(
          find.text('Zoom out or move the map to see more.'), findsOneWidget);
      // Nobody should be told to request a facility, or that Beacon doesn't
      // cover them, when twelve are a pinch away.
      expect(find.text('Request a facility'), findsNothing);
      expect(find.textContaining('facilities in Illinois'), findsNothing);
    });
  });

  group('FacilityListPanel.heightFor', () {
    const media = MediaQueryData(size: Size(390, 844));

    double height({
      bool open = true,
      bool expanded = false,
      bool searching = false,
    }) =>
        FacilityListPanel.heightFor(
          media,
          isPanelOpen: open,
          isFullyExpanded: expanded,
          isSearchActive: searching,
        );

    test('grows from collapsed to default to expanded', () {
      expect(height(open: false), lessThan(height()));
      expect(height(), lessThan(height(expanded: true)));
      expect(height(), closeTo(844 * 0.30, 0.01));
    });

    test('a search always shows the default height', () {
      expect(height(open: false, searching: true), height());
      expect(height(expanded: true, searching: true), height());
    });
  });
}
