import 'package:beacon_app/core/widgets/facility_correction_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_facility.dart';

void main() {
  setUp(mockPlatformServices);

  Future<void> openDialog(WidgetTester tester) async {
    await pumpThemed(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showFacilityCorrectionDialog(
              context,
              facility: createTestFacility(
                name: 'Mercy Clinic',
                website: 'https://example.org',
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  List<bool> fieldsEnabled(WidgetTester tester) => [
        for (final field
            in tester.widgetList<TextFormField>(find.byType(TextFormField)))
          field.enabled,
      ];

  testWidgets('opens pre-filled, with the closed switch off', (tester) async {
    await openDialog(tester);

    expect(find.text('Mercy Clinic'), findsOneWidget);
    expect(find.text('https://example.org'), findsOneWidget);
    expect(find.text('Permanently closed'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    expect(fieldsEnabled(tester), everyElement(isTrue));
  });

  testWidgets('reporting a closure locks the detail fields', (tester) async {
    await openDialog(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    // Name, website, phone, hours, address: none of it matters for a place
    // that no longer exists.
    expect(fieldsEnabled(tester), hasLength(5));
    expect(fieldsEnabled(tester), everyElement(isFalse));
  });

  testWidgets('switching it back off unlocks them', (tester) async {
    await openDialog(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(fieldsEnabled(tester), everyElement(isTrue));
  });

  testWidgets('cancel closes without submitting', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
