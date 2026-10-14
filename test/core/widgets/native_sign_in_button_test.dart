import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/native_sign_in_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('nativeSignInProviderFor', () {
    test('iOS offers Sign in with Apple', () {
      expect(
        nativeSignInProviderFor(TargetPlatform.iOS, isWeb: false),
        NativeSignInProvider.apple,
      );
    });

    test('Android offers Sign in with Google', () {
      expect(
        nativeSignInProviderFor(TargetPlatform.android, isWeb: false),
        NativeSignInProvider.google,
      );
    });

    test('platforms Beacon does not ship to offer no provider', () {
      for (final platform in [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      ]) {
        expect(
          nativeSignInProviderFor(platform, isWeb: false),
          isNull,
          reason: platform.name,
        );
      }
    });

    test('web offers no provider', () {
      expect(
        nativeSignInProviderFor(TargetPlatform.android, isWeb: true),
        isNull,
      );
    });
  });

  group('NativeSignInButton', () {
    ButtonStyle styleOf(WidgetTester tester) =>
        tester.widget<ElevatedButton>(find.bySubtype<ElevatedButton>()).style!;
    Color background(WidgetTester tester) =>
        styleOf(tester).backgroundColor!.resolve({})!;
    Color foreground(WidgetTester tester) =>
        styleOf(tester).foregroundColor!.resolve({})!;

    testWidgets(
      'Apple is black in light mode and white in dark',
      (tester) async {
        // A black button on a navy screen has no visible edge.
        mockPlatformServices();
        await pumpThemed(tester, const Scaffold(body: NativeSignInButton()));
        expect(background(tester), Colors.black);
        expect(foreground(tester), Colors.white);

        await pumpThemed(
          tester,
          const Scaffold(body: NativeSignInButton()),
          brightness: Brightness.dark,
        );
        expect(background(tester), Colors.white);
        expect(foreground(tester), Colors.black);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      "Google is white in light mode and Google's dark style in dark",
      (tester) async {
        // The white button was the brightest thing on a dark screen.
        mockPlatformServices();
        await pumpThemed(tester, const Scaffold(body: NativeSignInButton()));
        expect(background(tester), Colors.white);

        await pumpThemed(
          tester,
          const Scaffold(body: NativeSignInButton()),
          brightness: Brightness.dark,
        );
        expect(background(tester), AppColors.googleDarkButton);
        expect(foreground(tester), AppColors.googleDarkButtonText);
        expect(
          styleOf(tester).side!.resolve({})!.color,
          AppColors.googleDarkButtonBorder,
        );
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  });
}
