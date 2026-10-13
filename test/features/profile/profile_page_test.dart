import 'package:beacon_app/core/services/eligibility_preferences_service.dart';
import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/widgets/native_sign_in_button.dart';
import 'package:beacon_app/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_shell.dart';
import '../../helpers/pump_app.dart';

void main() {
  final eligibility = EligibilityPreferencesService();

  Future<void> pumpProfile(WidgetTester tester, {bool signedIn = true}) async {
    await resetAppState(tester);
    if (signedIn) {
      GuestModeService().debugUser = testUser(
        email: 'pat@example.org',
        name: 'Pat Example',
      );
    }
    await pumpThemed(tester, const ProfilePage());
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  group('signed in', () {
    testWidgets('shows who is signed in', (tester) async {
      await pumpProfile(tester);

      expect(find.text('Pat Example'), findsOneWidget);
      expect(find.text('pat@example.org'), findsOneWidget);
      expect(find.byType(NativeSignInButton), findsNothing);
    });

    testWidgets('has a Sign Out button, with a confirmation', (tester) async {
      // "I didn't see a sign out button": it is at the foot of this page.
      await pumpProfile(tester);

      await scrollTo(tester, find.text('Sign Out'));
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('has a Delete Account button', (tester) async {
      await pumpProfile(tester);

      await scrollTo(tester, find.text('Delete Account'));

      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('links to ratings and requests', (tester) async {
      await pumpProfile(tester);

      expect(find.text('Your Ratings'), findsOneWidget);
      expect(find.text('Your Requests'), findsOneWidget);
    });

    testWidgets('the Medicaid gate saves like the others', (tester) async {
      await pumpProfile(tester);

      await scrollTo(tester, find.text('Accepts Medicaid'));
      await tester.tap(find.text('Accepts Medicaid'));
      await tester.pumpAndSettle();

      expect(eligibility.eligibility.acceptsMedicaid, isTrue);
      expect(eligibility.eligibility.insuranceRequired, isFalse);
    });

    testWidgets('switching "apply to search" off disables the gates',
        (tester) async {
      await pumpProfile(tester);

      await tester.tap(find.text('Apply eligibility criteria to search'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Accepts Medicaid'));

      final gates = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .where((tile) => (tile.title! as Text).data != null)
          .where(
            (tile) =>
                (tile.title! as Text).data !=
                'Apply eligibility criteria to search',
          );
      expect(gates, isNotEmpty);
      expect(gates.map((tile) => tile.onChanged), everyElement(isNull));
      expect(eligibility.eligibility.applyToSearch, isFalse);
    });
  });

  group('guest', () {
    testWidgets('sees a sign-in prompt and nothing to sign out of',
        (tester) async {
      await pumpProfile(tester, signedIn: false);

      expect(find.byType(NativeSignInButton), findsOneWidget);
      expect(find.text('Sign Out'), findsNothing);
      expect(find.text('Accepts Medicaid'), findsNothing);
    });
  });
}
