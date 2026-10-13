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

  Switch favoritesSwitch(WidgetTester tester) =>
      tester.widgetList<Switch>(find.byType(Switch)).last;

  group('FilterModal for guests', () {
    testWidgets('locks Favorites and Preferences and prompts on tap',
        (tester) async {
      var prompts = 0;
      await openModal(tester, isGuest: true, onLockedTap: () => prompts++);

      expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
      expect(favoritesSwitch(tester).onChanged, isNull);

      await tester.tap(find.text('Favorites'));
      await tester.tap(find.text('Preferences'));
      await tester.pumpAndSettle();

      expect(prompts, 2);
      // The section never opens, so none of its options can be reached.
      expect(find.text('Accepts walk-ins').hitTestable(), findsNothing);
    });

    testWidgets('leaves Open Now and Category usable', (tester) async {
      await openModal(tester, isGuest: true);

      final openNow = tester.widgetList<Switch>(find.byType(Switch)).first;
      expect(openNow.onChanged, isNotNull);

      await tester.tap(find.text('Category'));
      await tester.pumpAndSettle();
      expect(find.text('Medical Care').hitTestable(), findsOneWidget);
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

      expect(favoritesSwitch(tester).value, isFalse);

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(result()!['showFavoritesOnly'], isFalse);
      // The modal lists every preference with a null ("no filter") value.
      final preferences = result()!['preferenceRequirements']
          as Map<PreferenceRequirement, bool?>;
      expect(preferences.values, everyElement(isNull));
    });
  });

  group('FilterModal for signed-in users', () {
    testWidgets('Favorites toggles and Preferences opens', (tester) async {
      final result = await openModal(tester, isGuest: false);

      expect(find.byIcon(Icons.lock_outline), findsNothing);

      await tester.tap(find.byType(Switch).last);
      await tester.tap(find.text('Preferences'));
      await tester.pumpAndSettle();
      expect(find.text('Accepts walk-ins').hitTestable(), findsOneWidget);

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(result()!['showFavoritesOnly'], isTrue);
    });
  });
}
