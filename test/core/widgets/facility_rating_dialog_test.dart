import 'package:beacon_app/core/widgets/facility_rating_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_facility.dart';

/// The rating form's own rules. Loading and saving need a Supabase session
/// and are not exercised here: with none, the "existing rating" lookup fails
/// and the dialog opens as a blank form, which is the state these tests use.
void main() {
  setUp(mockPlatformServices);

  Future<void> openDialog(WidgetTester tester) async {
    await pumpThemed(
      tester,
      // Tests draw every glyph as a full-width block, about twice as wide as
      // the real typeface, so the date row needs a tablet-width dialog to fit.
      size: const Size(900, 1200),
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showFacilityRatingDialog(
              context,
              facility: createTestFacility(name: 'Mercy Clinic'),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  FilledButton submitButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Submit'));

  testWidgets('cannot be submitted until a rating is chosen', (tester) async {
    await openDialog(tester);

    expect(submitButton(tester).onPressed, isNull);
    expect(find.byType(FilterChip), findsNothing);

    await tester.tap(find.byIcon(Icons.thumb_up_outlined));
    await tester.pumpAndSettle();

    expect(submitButton(tester).onPressed, isNotNull);
  });

  testWidgets('a thumbs up offers the positive tags', (tester) async {
    await openDialog(tester);

    await tester.tap(find.byIcon(Icons.thumb_up_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(FilterChip), findsNWidgets(5));
    expect(find.text('Friendly staff'), findsOneWidget);
    expect(find.text('Long wait times'), findsNothing);
  });

  testWidgets('a thumbs down offers the negative tags', (tester) async {
    await openDialog(tester);

    await tester.tap(find.byIcon(Icons.thumb_down_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Long wait times'), findsOneWidget);
    expect(find.text('Friendly staff'), findsNothing);
  });

  testWidgets('tags toggle, and switching the rating clears them',
      (tester) async {
    await openDialog(tester);
    bool selected(String tag) => tester
        .widget<FilterChip>(find.widgetWithText(FilterChip, tag))
        .selected;

    await tester.tap(find.byIcon(Icons.thumb_up_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Friendly staff'));
    await tester.pumpAndSettle();
    expect(selected('Friendly staff'), isTrue);

    await tester.tap(find.text('Friendly staff'));
    await tester.pumpAndSettle();
    expect(selected('Friendly staff'), isFalse);

    await tester.tap(find.text('Affordable or free'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.thumb_down_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.thumb_up_outlined));
    await tester.pumpAndSettle();

    // Praise chosen before the change of heart doesn't come back.
    expect(selected('Affordable or free'), isFalse);
  });

  testWidgets('cancel closes the form', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
