import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/features/auth/presentation/pages/eligibility_onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUp(() async {
    mockPlatformServices();
    await EligibilityPreferencesService().clear();
  });

  List<String> options(WidgetTester tester) => [
        for (final tile in tester
            .widgetList<CheckboxListTile>(find.byType(CheckboxListTile)))
          (tile.title! as Text).data!,
      ];

  CheckboxListTile option(WidgetTester tester, String label) =>
      tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, label),
      );

  testWidgets('asks what the person can provide, in their terms',
      (tester) async {
    await pumpThemed(tester, const EligibilityOnboardingPage());

    expect(find.text('What can you provide?'), findsOneWidget);
    // Things a person has — not "X required", which read as either "I have
    // it" or "show me places that demand it".
    expect(options(tester), [
      'Proof of income',
      'Proof of address',
      'Health insurance',
      'Medicaid',
      "A doctor's referral",
    ]);
    expect(find.textContaining('required'), findsNothing);
  });

  testWidgets('says what counts as each document', (tester) async {
    await pumpThemed(tester, const EligibilityOnboardingPage());

    expect(
      find.text('Pay stub, tax return, or benefits letter'),
      findsOneWidget,
    );
    expect(find.text('ID, lease, or utility bill'), findsOneWidget);
  });

  testWidgets('every box starts unchecked and can be checked', (tester) async {
    await pumpThemed(tester, const EligibilityOnboardingPage());
    for (final label in options(tester)) {
      expect(option(tester, label).value, isFalse, reason: label);
    }

    await tester.tap(find.text('Medicaid'));
    await tester.pumpAndSettle();

    expect(option(tester, 'Medicaid').value, isTrue);
    // Nothing is saved until the person leaves the step.
    expect(
        EligibilityPreferencesService().eligibility.acceptsMedicaid, isFalse);
  });

  testWidgets('offers a way to skip', (tester) async {
    await pumpThemed(tester, const EligibilityOnboardingPage());

    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Skip for now'), findsOneWidget);
  });

  testWidgets('the question and its options are translated', (tester) async {
    await pumpThemed(
      tester,
      const EligibilityOnboardingPage(),
      locale: const Locale('es'),
    );

    expect(find.text('¿Qué puedes presentar?'), findsOneWidget);
    expect(find.text('Comprobante de ingresos'), findsOneWidget);
    expect(find.text('Omitir por ahora'), findsOneWidget);
  });
}
