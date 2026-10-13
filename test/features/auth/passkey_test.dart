import 'package:beacon_app/core/services/guest_mode_service.dart';
import 'package:beacon_app/core/services/passkey_service.dart';
import 'package:beacon_app/core/widgets/native_sign_in_button.dart';
import 'package:beacon_app/features/auth/presentation/pages/create_passkey_page.dart';
import 'package:beacon_app/features/auth/presentation/pages/location_choice_page.dart';
import 'package:beacon_app/features/auth/presentation/pages/login_page.dart';
import 'package:beacon_app/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_shell.dart';
import '../../helpers/fake_passkeys.dart';
import '../../helpers/pump_app.dart';

void main() {
  double top(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder).dy;

  group('PasskeyService.isOfferedOn', () {
    test('is off unless the build switches it on', () {
      expect(PasskeyService.isOfferedOn(TargetPlatform.iOS, isWeb: false),
          isFalse);
    });

    test('is offered on both phones once switched on, and nowhere else', () {
      PasskeyService.debugEnabled = true;
      addTearDown(() => PasskeyService.debugEnabled = null);

      for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
        expect(
          PasskeyService.isOfferedOn(platform, isWeb: false),
          isTrue,
          reason: platform.name,
        );
      }
      expect(
        PasskeyService.isOfferedOn(TargetPlatform.macOS, isWeb: false),
        isFalse,
      );
      expect(
        PasskeyService.isOfferedOn(TargetPlatform.android, isWeb: true),
        isFalse,
      );
    });
  });

  group('sign-in screen', () {
    setUp(mockPlatformServices);

    testWidgets('has no passkey button while passkeys are off', (tester) async {
      await pumpThemed(tester, const LoginPage());

      expect(find.text('Sign in with a passkey'), findsNothing);
      expect(find.byType(NativeSignInButton), findsOneWidget);
    });

    testWidgets(
      'offers exactly three ways in, in order: passkey, provider, guest',
      (tester) async {
        usePasskeys();
        await pumpThemed(tester, const LoginPage());
        final provider =
            defaultTargetPlatform == TargetPlatform.iOS ? 'Apple' : 'Google';

        final order = [
          find.text('Sign in with a passkey'),
          find.text('Continue with $provider'),
          find.text('Continue as guest'),
        ];
        for (final option in order) {
          expect(option, findsOneWidget);
        }
        expect(top(tester, order[0]), lessThan(top(tester, order[1])));
        expect(top(tester, order[1]), lessThan(top(tester, order[2])));
        // No email, no password, anywhere.
        expect(find.byType(TextField), findsNothing);
      },
      variant: shippingPlatforms,
    );

    testWidgets('a passkey on the phone signs in and moves on', (tester) async {
      final passkeys = usePasskeys();
      await pumpThemed(tester, const LoginPage());

      await tester.tap(find.text('Sign in with a passkey'));
      await tester.pumpAndSettle();

      expect(passkeys.signIns, 1);
      expect(find.byType(LocationChoicePage), findsOneWidget);
    });

    testWidgets('with no passkey on the phone, says how to get one',
        (tester) async {
      usePasskeys().signInOutcome = PasskeyOutcome.noPasskey;
      await pumpThemed(tester, const LoginPage());

      await tester.tap(find.text('Sign in with a passkey'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        find.textContaining("There's no passkey for Beacon on this phone yet"),
        findsOneWidget,
      );
    });

    testWidgets('closing the system sheet is not an error', (tester) async {
      usePasskeys().signInOutcome = PasskeyOutcome.cancelled;
      await pumpThemed(tester, const LoginPage());

      await tester.tap(find.text('Sign in with a passkey'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.textContaining('passkey for Beacon'), findsNothing);
      expect(find.textContaining('failed'), findsNothing);
    });
  });

  group('creating a passkey', () {
    setUp(mockPlatformServices);

    Future<bool? Function()> open(WidgetTester tester) async {
      bool? result;
      await pumpThemed(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreatePasskeyPage()),
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

    testWidgets('says what a passkey is for, and asks only for a name',
        (tester) async {
      usePasskeys();
      await open(tester);

      expect(find.text('Create your passkey'), findsOneWidget);
      expect(find.textContaining('Beacon never sees it'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Name (optional)'), findsOneWidget);
    });

    testWidgets('creates one with the name given', (tester) async {
      final passkeys = usePasskeys();
      final result = await open(tester);

      await tester.enterText(find.byType(TextField), "Maria's phone");
      await tester.tap(find.text('Create passkey'));
      await tester.pumpAndSettle();

      expect(passkeys.createdNames, ["Maria's phone"]);
      expect(result(), isTrue);
      expect(find.text('Passkey created'), findsOneWidget);
    });

    testWidgets('"Not now" leaves without creating one', (tester) async {
      final passkeys = usePasskeys();
      final result = await open(tester);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(passkeys.createdNames, isEmpty);
      expect(result(), isNull);
      expect(find.byType(CreatePasskeyPage), findsNothing);
    });

    testWidgets('closing the system sheet stays on the page, with no error',
        (tester) async {
      usePasskeys().createOutcome = PasskeyOutcome.cancelled;
      await open(tester);

      await tester.tap(find.text('Create passkey'));
      await tester.pumpAndSettle();

      expect(find.byType(CreatePasskeyPage), findsOneWidget);
      expect(find.textContaining("Couldn't create"), findsNothing);
    });

    testWidgets('a failure says so and can be retried', (tester) async {
      final passkeys = usePasskeys()..createOutcome = PasskeyOutcome.failed;
      await open(tester);

      await tester.tap(find.text('Create passkey'));
      await tester.pumpAndSettle();
      expect(
        find.text("Couldn't create a passkey. Please try again."),
        findsOneWidget,
      );

      passkeys.createOutcome = PasskeyOutcome.success;
      await tester.tap(find.text('Create passkey'));
      await tester.pumpAndSettle();
      expect(passkeys.createdNames, hasLength(2));
      expect(find.byType(CreatePasskeyPage), findsNothing);
    });
  });

  group('Profile', () {
    Future<void> pumpSignedIn(WidgetTester tester) async {
      await resetAppState(tester);
      GuestModeService().debugUser = testUser();
      await pumpThemed(tester, const ProfilePage());
    }

    testWidgets('offers "Add a passkey" to a signed-in person', (tester) async {
      usePasskeys();
      await pumpSignedIn(tester);

      await tester.tap(find.text('Add a passkey'));
      await tester.pumpAndSettle();

      expect(find.byType(CreatePasskeyPage), findsOneWidget);
    });

    testWidgets('has no passkey row while passkeys are off', (tester) async {
      await pumpSignedIn(tester);

      expect(find.text('Add a passkey'), findsNothing);
    });
  });
}
