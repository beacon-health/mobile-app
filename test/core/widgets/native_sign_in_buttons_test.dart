import 'package:beacon_app/core/theme/theme.dart';
import 'package:beacon_app/core/widgets/native_sign_in_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('nativeSignInProvidersFor', () {
    test('iOS offers Apple, then Google', () {
      expect(
        nativeSignInProvidersFor(TargetPlatform.iOS, isWeb: false),
        [NativeSignInProvider.apple, NativeSignInProvider.google],
      );
    });

    test('Android offers Google alone', () {
      expect(
        nativeSignInProvidersFor(TargetPlatform.android, isWeb: false),
        [NativeSignInProvider.google],
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
          nativeSignInProvidersFor(platform, isWeb: false),
          isEmpty,
          reason: platform.name,
        );
      }
    });

    test('web offers no provider', () {
      expect(
        nativeSignInProvidersFor(TargetPlatform.android, isWeb: true),
        isEmpty,
      );
    });
  });

  group('NativeSignInButtons', () {
    ButtonStyle styleOf(WidgetTester tester, String provider) => tester
        .widget<ElevatedButton>(
          find.ancestor(
            of: find.text('Continue with $provider'),
            matching: find.bySubtype<ElevatedButton>(),
          ),
        )
        .style!;
    Color background(WidgetTester tester, String provider) =>
        styleOf(tester, provider).backgroundColor!.resolve({})!;
    Color foreground(WidgetTester tester, String provider) =>
        styleOf(tester, provider).foregroundColor!.resolve({})!;

    testWidgets(
      'iOS stacks Apple above Google, the same width',
      (tester) async {
        mockPlatformServices();
        await pumpThemed(tester, const Scaffold(body: NativeSignInButtons()));
        final apple = tester.getRect(find.text('Continue with Apple'));
        final google = tester.getRect(find.text('Continue with Google'));
        expect(apple.top, lessThan(google.top));

        Rect button(String provider) => tester.getRect(
              find.ancestor(
                of: find.text('Continue with $provider'),
                matching: find.bySubtype<ElevatedButton>(),
              ),
            );
        expect(button('Apple').width, button('Google').width);
        expect(button('Apple').height, button('Google').height);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      'Android offers Google alone',
      (tester) async {
        mockPlatformServices();
        await pumpThemed(tester, const Scaffold(body: NativeSignInButtons()));
        expect(find.text('Continue with Google'), findsOneWidget);
        expect(find.text('Continue with Apple'), findsNothing);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );

    testWidgets(
      'Apple is black in light mode and white in dark',
      (tester) async {
        // A black button on a navy screen has no visible edge.
        mockPlatformServices();
        await pumpThemed(tester, const Scaffold(body: NativeSignInButtons()));
        expect(background(tester, 'Apple'), Colors.black);
        expect(foreground(tester, 'Apple'), Colors.white);

        await pumpThemed(
          tester,
          const Scaffold(body: NativeSignInButtons()),
          brightness: Brightness.dark,
        );
        expect(background(tester, 'Apple'), Colors.white);
        expect(foreground(tester, 'Apple'), Colors.black);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      "Google is white in light mode and Google's dark style in dark",
      (tester) async {
        // The white button was the brightest thing on a dark screen.
        mockPlatformServices();
        await pumpThemed(tester, const Scaffold(body: NativeSignInButtons()));
        expect(background(tester, 'Google'), Colors.white);

        await pumpThemed(
          tester,
          const Scaffold(body: NativeSignInButtons()),
          brightness: Brightness.dark,
        );
        expect(background(tester, 'Google'), AppColors.googleDarkButton);
        expect(foreground(tester, 'Google'), AppColors.googleDarkButtonText);
        expect(
          styleOf(tester, 'Google').side!.resolve({})!.color,
          AppColors.googleDarkButtonBorder,
        );
      },
      variant: TargetPlatformVariant.all(
        excluding: {
          TargetPlatform.fuchsia,
          TargetPlatform.linux,
          TargetPlatform.macOS,
          TargetPlatform.windows,
        },
      ),
    );
  });
}
