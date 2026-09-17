import 'package:beacon_app/core/widgets/native_sign_in_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
