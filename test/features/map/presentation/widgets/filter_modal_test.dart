import 'package:beacon_app/features/map/constants/facility_categories.dart';
import 'package:beacon_app/features/map/constants/filter_constants.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/components/filter_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  setUp(mockPlatformServices);

  /// Opens the modal the way the map does and returns whatever it pops with.
  Future<Map<String, dynamic>? Function()> openModal(
    WidgetTester tester, {
    required bool isGuest,
    bool showFavoritesOnly = false,
    Map<PreferenceRequirement, bool?> preferences = const {},
    VoidCallback? onLockedTap,
    int Function(FilterSelection)? resultCount,
  }) async {
    Map<String, dynamic>? result;
    await pumpThemed(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showModalBottomSheet<Map<String, dynamic>>(
                context: context,
                isScrollControlled: true,
                builder: (_) => FilterModal(
                  selectedCategories: const {},
                  availableCategories: const ['Medical Care', 'Housing'],
                  selectedPreferenceRequirements: preferences,
                  showFavoritesOnly: showFavoritesOnly,
                  showOpenNowOnly: false,
                  isGuest: isGuest,
                  onLockedTap: onLockedTap,
                  resultCount: resultCount,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  testWidgets('categories sit under the six groups Home shows, in its order',
      (tester) async {
    // They were one unordered run of buttons.
    await pumpThemed(
      tester,
      const Scaffold(
        body: FilterModal(
          selectedCategories: {},
          availableCategories: FacilityCategories.categoryBroadValues,
          selectedPreferenceRequirements: {},
          showFavoritesOnly: false,
          showOpenNowOnly: false,
        ),
      ),
      size: const Size(400, 3000),
    );

    // A heading can share its text with a category under it ("Mental
    // Health"); the heading comes first.
    double top(String text) => tester.getTopLeft(find.text(text).first).dy;
    const headings = [
      'Health Care',
      'Mental Health',
      'Housing & Shelter',
      'Basic Needs',
      'Community Resources',
      'Specialized Services',
    ];
    for (var i = 1; i < headings.length; i++) {
      expect(top(headings[i]), greaterThan(top(headings[i - 1])));
    }
    // Each category under its own group, above the next one.
    expect(top('Hospitals'), greaterThan(top('Health Care')));
    expect(top('Hospitals'), lessThan(top('Mental Health')));
    expect(top('Addiction Recovery'), greaterThan(top('Mental Health')));
    expect(top('Addiction Recovery'), lessThan(top('Housing & Shelter')));
    expect(top('Veterans'), greaterThan(top('Specialized Services')));
    // A heading to a screen reader, not another button.
    expect(
      tester.getSemantics(find.text('Health Care')),
      isSemantics(isHeader: true),
    );
  });

  SwitchListTile switchFor(WidgetTester tester, String label) =>
      tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, label));

  Future<void> tapRow(WidgetTester tester, String label) async {
    await tester.scrollUntilVisible(
      find.text(label),
      100,
      scrollable: find
          .descendant(
            of: find.byType(FilterModal),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  group('FilterModal for guests', () {
    testWidgets('locks Favorites and Preferences and prompts on tap',
        (tester) async {
      var prompts = 0;
      await openModal(tester, isGuest: true, onLockedTap: () => prompts++);

      expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
      // Locked rows are rows to tap, not switches that look switched off.
      expect(find.widgetWithText(SwitchListTile, 'Favorites'), findsNothing);

      await tapRow(tester, 'Favorites');
      await tapRow(tester, 'Preferences');

      expect(prompts, 2);
      // None of the preference switches can be reached.
      expect(find.text('Take walk-ins'), findsNothing);
    });

    testWidgets('leaves Open now and Category usable', (tester) async {
      final result = await openModal(tester, isGuest: true);

      expect(switchFor(tester, 'Open now').onChanged, isNotNull);
      await tapRow(tester, 'Open now');
      // The categories are simply there: no section to open first.
      await tapRow(tester, 'Medical Care');

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(result()!['showOpenNowOnly'], isTrue);
      expect(result()!['categories'], {'Medical Care'});
    });

    testWidgets('never applies a favorites or preference filter',
        (tester) async {
      // State left over from before the lock existed must not survive Apply.
      final result = await openModal(
        tester,
        isGuest: true,
        showFavoritesOnly: true,
        preferences: {PreferenceRequirement.acceptsWalkins: true},
      );

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(result()!['showFavoritesOnly'], isFalse);
      final preferences = result()!['preferenceRequirements']
          as Map<PreferenceRequirement, bool?>;
      expect(preferences.values, everyElement(isNull));
    });
  });

  group('FilterModal for signed-in users', () {
    testWidgets('Favorites toggles', (tester) async {
      final result = await openModal(tester, isGuest: false);

      expect(find.byIcon(Icons.lock_outline), findsNothing);
      await tapRow(tester, 'Favorites');

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(result()!['showFavoritesOnly'], isTrue);
    });

    testWidgets('preferences are switches under "Only show places that"',
        (tester) async {
      // They were Yes / No tiles, where "No" asked for places that, say,
      // refuse walk-ins.
      final result = await openModal(tester, isGuest: false);

      expect(find.text('Only show places that'), findsOneWidget);
      expect(find.text('Yes'), findsNothing);
      expect(find.text('No'), findsNothing);

      await tapRow(tester, 'Take walk-ins');
      expect(switchFor(tester, 'Take walk-ins').value, isTrue);

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      final preferences = result()!['preferenceRequirements']
          as Map<PreferenceRequirement, bool?>;
      expect(preferences[PreferenceRequirement.acceptsWalkins], isTrue);
    });

    testWidgets('switching a preference back off removes the filter',
        (tester) async {
      final result = await openModal(
        tester,
        isGuest: false,
        preferences: {PreferenceRequirement.acceptsWalkins: true},
      );

      await tapRow(tester, 'Take walk-ins');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      final preferences = result()!['preferenceRequirements']
          as Map<PreferenceRequirement, bool?>;
      // Off means "no filter", never "must not".
      expect(preferences[PreferenceRequirement.acceptsWalkins], isNull);
    });
  });

  group('FilterModal result count', () {
    testWidgets('the button says how many results it will show',
        (tester) async {
      await openModal(
        tester,
        isGuest: false,
        resultCount: (selection) => selection.showOpenNowOnly ? 1 : 12,
      );
      expect(find.text('Show 12 results'), findsOneWidget);

      await tapRow(tester, 'Open now');

      expect(find.text('Show 1 result'), findsOneWidget);
    });

    testWidgets('says so when nothing would match', (tester) async {
      await openModal(tester, isGuest: false, resultCount: (_) => 0);

      expect(find.text('No results'), findsOneWidget);
    });
  });

  testWidgets('the close button has a name', (tester) async {
    await openModal(tester, isGuest: false);

    expect(find.byTooltip('Close filters'), findsOneWidget);
  });
}
