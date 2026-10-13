import 'package:beacon_app/core/services/recent_facilities_service.dart';
import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/features/home/presentation/pages/home_page.dart';
import 'package:beacon_app/features/home/presentation/widgets/main_nav_bar.dart';
import 'package:beacon_app/features/map/presentation/widgets/facility/facility_list_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/app_shell.dart';
import '../../../../helpers/test_facility.dart';

/// Home inside the real tab shell.
void main() {
  const groups = [
    'Health care',
    'Mental health',
    'Housing & shelter',
    'Basic needs',
    'Community resources',
    'Specialized services',
  ];

  Future<void> pumpHome(WidgetTester tester, {Size? size}) async {
    await resetAppState(tester);
    await pumpAppShell(
      tester,
      repository: FakeFacilityRepository([
        createTestFacility(id: 'a', name: 'Near North Health Service'),
      ]),
      size: size ?? const Size(390, 844),
    );
  }

  group('quick actions', () {
    testWidgets('labels are text-colored and readable; the icon has the color',
        (tester) async {
      // They were 9pt, in the category color: 2.4:1 at best.
      await pumpHome(tester);
      final scheme =
          Theme.of(tester.element(find.byType(HomePage))).colorScheme;

      for (final label in groups) {
        final text = tester.widget<Text>(find.text(label));
        expect(text.style!.color, scheme.onSurface, reason: label);
        expect(text.style!.fontSize, greaterThanOrEqualTo(11), reason: label);
        expect(text.maxLines, isNull, reason: '$label may wrap');
      }
    });

    testWidgets('each tile is a full-size target that filters the map',
        (tester) async {
      await pumpHome(tester);

      for (final label in groups) {
        final tile = find.ancestor(
          of: find.text(label),
          matching: find.byType(InkWell),
        );
        expect(
          tester.getSize(tile).height,
          greaterThanOrEqualTo(AppSizes.minTouchTarget),
          reason: label,
        );
      }

      await tester.tap(find.text('Mental health'));
      await settle(tester);
      expect(selectedTab(tester), NavTab.map);
      expect(find.byType(FacilityListPanel), findsOneWidget);
    });

    testWidgets('sit three across, and fewer as the text grows',
        (tester) async {
      double tileTop(String label) => tester
          .getTopLeft(
            find.ancestor(
              of: find.text(label),
              matching: find.byType(InkWell),
            ),
          )
          .dy;
      int tilesInFirstRow() => groups
          .where((g) => (tileTop(g) - tileTop(groups.first)).abs() < 1)
          .length;

      await pumpHome(tester);
      expect(tilesInFirstRow(), 3);

      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tilesInFirstRow(), 2);

      tester.platformDispatcher.textScaleFactorTestValue = 2.5;
      await tester.pumpAndSettle();
      expect(tilesInFirstRow(), 1);
    });

    testWidgets('fit in Spanish on a narrow phone', (tester) async {
      // "Servicios especializados" in a tile a third of 320pt wide.
      await pumpHome(tester, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the map preview is a named button that opens the map',
      (tester) async {
    await pumpHome(tester);
    final semantics = tester.ensureSemantics();

    expect(find.bySemanticsLabel('Open map'), findsOneWidget);
    await tester.tap(find.text('Open map'));
    await settle(tester);

    expect(selectedTab(tester), NavTab.map);
    semantics.dispose();
  });

  testWidgets('a facility name gets two lines before it is cut',
      (tester) async {
    await pumpHome(tester);
    RecentFacilitiesService().addFacility(
      createTestFacility(
        id: 'long',
        name: 'First Baptist Congregational Church of Chicago',
      ),
    );
    await tester.pumpAndSettle();

    final name = tester.widget<Text>(
      find.text('First Baptist Congregational Church of Chicago'),
    );
    expect(name.maxLines, 2);
  });

  testWidgets('section titles are sentence case', (tester) async {
    await pumpHome(tester);

    expect(find.text('Find healthcare resources'), findsOneWidget);
    expect(find.text('Recently viewed'), findsOneWidget);
    expect(find.text('Your favorites'), findsOneWidget);
  });
}
