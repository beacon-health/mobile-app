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

  List<String> gates(WidgetTester tester) => [
        for (final tile
            in tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)))
          (tile.title! as Text).data!,
      ];

  testWidgets('offers every eligibility gate, Medicaid among them',
      (tester) async {
    await pumpThemed(tester, const EligibilityOnboardingPage());

    expect(gates(tester), [
      'Proof of income required',
      'Proof of residency required',
      'Insurance required',
      'Referral required',
      'Accepts Medicaid',
    ]);
  });

  testWidgets('every gate starts off and can be switched on', (tester) async {
    await pumpThemed(tester, const EligibilityOnboardingPage());

    SwitchListTile medicaid() => tester.widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, 'Accepts Medicaid'),
        );
    expect(medicaid().value, isFalse);

    await tester.tap(find.text('Accepts Medicaid'));
    await tester.pumpAndSettle();

    expect(medicaid().value, isTrue);
  });

  testWidgets('the Medicaid gate is translated', (tester) async {
    await pumpThemed(
      tester,
      const EligibilityOnboardingPage(),
      locale: const Locale('es'),
    );

    expect(find.text('Acepta Medicaid'), findsOneWidget);
  });
}
