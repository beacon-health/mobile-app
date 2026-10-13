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

    testWidgets('has a Sign out button, with a confirmation', (tester) async {
      // "I didn't see a sign out button": it is at the foot of this page.
      await pumpProfile(tester);

      await scrollTo(tester, find.text('Sign out'));
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Sign out?'), findsOneWidget);
      // Says what happens to what they saved, not just "are you sure".
      expect(
        find.textContaining('stay with your account'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Delete account reads as destructive, not as a link',
        (tester) async {
      await pumpProfile(tester);

      await scrollTo(tester, find.text('Delete account'));

      final button = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Delete account'),
          matching: find.bySubtype<TextButton>(),
        ),
      );
      final scheme =
          Theme.of(tester.element(find.byType(ProfilePage))).colorScheme;
      expect(button.style!.foregroundColor!.resolve({}), scheme.error);
    });

    testWidgets('links to ratings and requests', (tester) async {
      await pumpProfile(tester);

      expect(find.text('Your ratings'), findsOneWidget);
      expect(find.text('Your requests'), findsOneWidget);
    });

    testWidgets('a checked box saves', (tester) async {
      await pumpProfile(tester);
      await eligibility.setApplyEligibilityToSearch(true);
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Medicaid'));
      await tester.tap(find.text('Medicaid'));
      await tester.pumpAndSettle();

      expect(eligibility.eligibility.acceptsMedicaid, isTrue);
      expect(eligibility.eligibility.insuranceRequired, isFalse);
    });

    testWidgets(
        'switching the filter off locks the answers without losing them',
        (tester) async {
      await pumpProfile(tester);
      await eligibility.updateEligibility(
        const EligibilityState(proofOfIncome: true, applyToSearch: true),
      );
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text(_filterSwitch));
      await tester.tap(find.text(_filterSwitch));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Medicaid'));

      final boxes =
          tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(boxes, hasLength(5));
      expect(boxes.map((tile) => tile.onChanged), everyElement(isNull));
      expect(eligibility.eligibility.applyToSearch, isFalse);
      expect(eligibility.eligibility.proofOfIncome, isTrue);
    });
  });

  group('guest', () {
    testWidgets('sees a sign-in prompt and nothing to sign out of',
        (tester) async {
      await pumpProfile(tester, signedIn: false);

      expect(find.byType(NativeSignInButton), findsOneWidget);
      expect(find.text('Sign out'), findsNothing);
      expect(find.text('Delete account'), findsNothing);
    });

    testWidgets('can say what they can provide, kept on the device',
        (tester) async {
      // Onboarding promises this is editable in Profile; for a guest it used
      // to be a sign-in card and nothing else.
      await pumpProfile(tester, signedIn: false);

      expect(find.text('What you can provide'), findsOneWidget);
      expect(find.text('Saved on this device'), findsOneWidget);

      // Off until they say so: nothing was hidden on their behalf.
      expect(eligibility.eligibility.applyToSearch, isFalse);
      await scrollTo(tester, find.text(_filterSwitch));
      await tester.tap(find.text(_filterSwitch));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Proof of address'));
      await tester.tap(find.text('Proof of address'));
      await tester.pumpAndSettle();

      expect(eligibility.eligibility.applyToSearch, isTrue);
      expect(eligibility.eligibility.proofOfResidency, isTrue);
    });

    testWidgets('signed-in users are not told it is on the device',
        (tester) async {
      await pumpProfile(tester);

      expect(find.text('What you can provide'), findsOneWidget);
      expect(find.text('Saved on this device'), findsNothing);
    });
  });
}

const _filterSwitch = 'Filter by what I can provide';
