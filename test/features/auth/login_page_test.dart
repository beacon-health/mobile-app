import 'package:beacon_app/core/services/locale_provider.dart';
import 'package:beacon_app/core/widgets/beacon_logo.dart';
import 'package:beacon_app/core/widgets/native_sign_in_buttons.dart';
import 'package:beacon_app/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUp(() async {
    mockPlatformServices();
    await LocaleProvider().setLocale(const Locale('en'), syncToCloud: false);
  });

  double top(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder).dy;

  testWidgets(
    'offers the platform sign-in, then guest, in that order',
    (tester) async {
      await pumpThemed(tester, const LoginPage());
      final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

      expect(find.byType(NativeSignInButtons), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(
        find.text('Continue with Apple'),
        isIOS ? findsOneWidget : findsNothing,
      );
      expect(
        top(tester, find.byType(NativeSignInButtons)),
        lessThan(top(tester, find.text('Continue as guest'))),
      );
      // The quieter choice: outlined, not a second filled button.
      expect(
        find.widgetWithText(FilledButton, 'Continue as guest'),
        findsOneWidget,
      );
    },
    variant: shippingPlatforms,
  );

  testWidgets('the language picker comes first and names the language',
      (tester) async {
    // It used to be the last thing on the page, labelled in English.
    await pumpThemed(tester, const LoginPage());

    expect(find.text('English'), findsOneWidget);
    expect(
      top(tester, find.text('English')),
      lessThan(top(tester, find.byType(Image).first)),
    );
    expect(
      tester.widget<Text>(find.text('English')).semanticsLabel,
      'Language: English. Change language',
    );
  });

  testWidgets('lists each language under its own name and switches',
      (tester) async {
    await pumpThemed(tester, const LoginPage());

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    final options = [
      for (final tile in tester.widgetList<ListTile>(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(ListTile),
        ),
      ))
        (tile.title! as Text).data!,
    ];
    expect(options, ['English', 'Español', '中文']);

    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();

    expect(LocaleProvider().locale.languageCode, 'es');
    await LocaleProvider().setLocale(const Locale('en'), syncToCloud: false);
  });

  testWidgets('the tagline is text in the app language, not part of the logo',
      (tester) async {
    // Baked into the artwork it could not be translated or read aloud.
    await pumpThemed(tester, const LoginPage(), locale: const Locale('es'));
    expect(find.text('Atención médica más llevadera.'), findsOneWidget);
  });

  testWidgets('the logo has its own artwork for a dark screen', (tester) async {
    String logoAsset() => (tester
            .widget<Image>(
              find.descendant(
                of: find.byType(BeaconLogo),
                matching: find.byType(Image),
              ),
            )
            .image as AssetImage)
        .assetName;

    await pumpThemed(tester, const LoginPage());
    expect(logoAsset(), 'assets/beacon-logo.png');

    await pumpThemed(tester, const LoginPage(), brightness: Brightness.dark);
    expect(logoAsset(), 'assets/beacon-logo-dark.png');
  });

  testWidgets('says "By continuing", and ends the sentence', (tester) async {
    await pumpThemed(tester, const LoginPage());

    final terms = find.textContaining('By continuing, you agree to our ',
        findRichText: true);
    expect(terms, findsOneWidget);
    expect(
      tester.widget<RichText>(terms).text.toPlainText(),
      'By continuing, you agree to our Terms of Service and Privacy Policy.',
    );
  });
}
