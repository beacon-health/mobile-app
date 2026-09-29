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
    testWidgets('selected chips fill with the secondary color', (tester) async {
      await _pump(
        tester,
        CustomFilterChip(
          label: 'Open Now',
          isSelected: true,
          hasDropdown: false,
          onTap: () {},
        ),
      );
      final decoration = _decorationOf(
        tester,
        find.descendant(
          of: find.byType(CustomFilterChip),
          matching: find.byType(Container),
        ),
      );
      expect(decoration.color, _scheme(tester).secondary);
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
    Border borderOf(WidgetTester tester) => _decorationOf(
          tester,
          find.descendant(
            of: find.byType(SelectionTile),
            matching: find.byType(Container),
          ),
        ).border! as Border;

    testWidgets('selected tiles get the thicker primary outline',
        (tester) async {
      await _pump(
        tester,
        const SelectionTile(
          label: 'Yes',
          selected: true,
          padding: EdgeInsets.zero,
        ),
      );
      final side = borderOf(tester).top;
      expect(side.width, AppSizes.borderSelected);
      expect(side.color, _scheme(tester).primary);
    });

    testWidgets('unselected tiles use the default outline', (tester) async {
      await _pump(
        tester,
        const SelectionTile(
          label: 'No',
          selected: false,
          padding: EdgeInsets.zero,
        ),
      );
      expect(borderOf(tester).top.width, AppSizes.border);
    });
  });
}
