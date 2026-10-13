import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/drag_handle.dart';
import 'package:beacon_app/core/widgets/empty_state.dart';
import 'package:beacon_app/core/widgets/section_header.dart';
import 'package:beacon_app/core/widgets/tag_chip.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/components/filter_chip.dart';
import 'package:beacon_app/features/map/presentation/widgets/filters/components/selection_chip_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

ColorScheme _scheme(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold))).colorScheme;

BoxDecoration _decorationOf(WidgetTester tester, Finder container) =>
    tester.widget<Container>(container).decoration! as BoxDecoration;

void main() {
  group('TagChip', () {
    testWidgets('tints text, outline, and background with its color',
        (tester) async {
      await _pump(
        tester,
        const TagChip(label: 'Walk-ins', color: AppColors.healthCare),
      );

      final text = tester.widget<Text>(find.text('Walk-ins'));
      expect(text.style?.color, AppColors.healthCare);
      final decoration = _decorationOf(
        tester,
        find.descendant(
          of: find.byType(TagChip),
          matching: find.byType(Container),
        ),
      );
      expect(decoration.color, AppColors.healthCare.tint);
      expect(
        (decoration.border! as Border).top.color,
        AppColors.healthCare.tintBorder,
      );
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('shows an icon when given one', (tester) async {
      await _pump(
        tester,
        const TagChip(
          label: 'Telehealth',
          color: AppColors.mentalHealth,
          icon: Icons.videocam,
        ),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.videocam));
      expect(icon.color, AppColors.mentalHealth);
      expect(icon.size, AppIconSize.xs);
    });
  });

  group('EmptyState', () {
    testWidgets('renders title and message, and no action by default',
        (tester) async {
      await _pump(
        tester,
        const EmptyState(
          icon: Icons.inbox,
          title: 'Nothing here',
          message: 'Come back later.',
        ),
      );
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Come back later.'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('renders its action', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        EmptyState(
          icon: Icons.inbox,
          title: 'Nothing here',
          message: 'Come back later.',
          action: FilledButton(
            onPressed: () => tapped = true,
            child: const Text('Add one'),
          ),
        ),
      );
      await tester.tap(find.text('Add one'));
      expect(tapped, isTrue);
    });
  });

  testWidgets('SectionHeader uses the secondary color', (tester) async {
    await _pump(tester, const SectionHeader('Account'));
    final text = tester.widget<Text>(find.text('Account'));
    expect(text.style?.color, _scheme(tester).secondary);
  });

  testWidgets('DragHandle takes its size from the sheet theme', (tester) async {
    await _pump(tester, const DragHandle());
    final size = tester.getSize(
      find.descendant(
        of: find.byType(DragHandle),
        matching: find.byType(Container),
      ),
    );
    expect(size, const Size(AppSizes.handleWidth, AppSizes.handleHeight));
  });

  group('CustomFilterChip', () {
    BoxDecoration chipDecoration(WidgetTester tester) => tester
        .widget<DecoratedBox>(
          find.descendant(
            of: find.byType(CustomFilterChip),
            matching: find.byType(DecoratedBox),
          ),
        )
        .decoration as BoxDecoration;

    Color labelColor(WidgetTester tester, String label) =>
        tester.widget<Text>(find.text(label)).style!.color!;

    testWidgets('selected chips fill with the secondary color', (tester) async {
      await _pump(
        tester,
        CustomFilterChip(
          label: 'Open now',
          isSelected: true,
          hasDropdown: false,
          onTap: () {},
        ),
      );
      expect(chipDecoration(tester).color, _scheme(tester).secondary);
    });

    testWidgets('is a full-size touch target', (tester) async {
      await _pump(
        tester,
        CustomFilterChip(
          label: 'Open now',
          isSelected: false,
          hasDropdown: false,
          onTap: () {},
        ),
      );
      expect(
        tester.getSize(find.byType(CustomFilterChip)).height,
        greaterThanOrEqualTo(AppSizes.minTouchTarget),
      );
    });

    testWidgets('locked chips show a lock and hide the dropdown arrow',
        (tester) async {
      await _pump(
        tester,
        CustomFilterChip(
          label: 'Favorites',
          isSelected: false,
          hasDropdown: true,
          isLocked: true,
          onTap: () {},
        ),
      );
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
    });

    testWidgets('a locked chip is as readable as any other, and still taps',
        (tester) async {
      // It was drawn at 38% opacity, which read as "does nothing" — but
      // tapping it offers sign-in.
      var taps = 0;
      await _pump(
        tester,
        CustomFilterChip(
          label: 'Favorites',
          isSelected: false,
          hasDropdown: false,
          isLocked: true,
          onTap: () => taps++,
        ),
      );

      expect(labelColor(tester, 'Favorites'), _scheme(tester).onSurface);
      await tester.tap(find.text('Favorites'));
      expect(taps, 1);
    });

    testWidgets('unlocked dropdown chips show the arrow and handle taps',
        (tester) async {
      var taps = 0;
      await _pump(
        tester,
        CustomFilterChip(
          label: 'Category',
          isSelected: false,
          hasDropdown: true,
          onTap: () => taps++,
        ),
      );
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      await tester.tap(find.text('Category'));
      expect(taps, 1);
    });
  });

  group('SelectionTile', () {
    BorderSide sideOf(WidgetTester tester) => (tester
            .widget<Material>(
              find.descendant(
                of: find.byType(SelectionTile),
                matching: find.byType(Material),
              ),
            )
            .shape! as RoundedRectangleBorder)
        .side;

    testWidgets('selected tiles get the thicker primary outline and a check',
        (tester) async {
      await _pump(
        tester,
        SelectionTile(label: 'Housing', selected: true, onTap: () {}),
      );
      expect(sideOf(tester).width, AppSizes.borderSelected);
      expect(sideOf(tester).color, _scheme(tester).primary);
      // Selected shows in shape, not only in color.
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('unselected tiles use the default outline', (tester) async {
      await _pump(
        tester,
        SelectionTile(label: 'Housing', selected: false, onTap: () {}),
      );
      expect(sideOf(tester).width, AppSizes.border);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('is a full-size touch target that reports taps',
        (tester) async {
      var taps = 0;
      await _pump(
        tester,
        SelectionTile(label: 'Food', selected: false, onTap: () => taps++),
      );
      expect(
        tester.getSize(find.byType(SelectionTile)).height,
        greaterThanOrEqualTo(AppSizes.minTouchTarget),
      );
      await tester.tap(find.text('Food'));
      expect(taps, 1);
    });
  });
}
