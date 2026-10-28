import 'package:beacon_app/core/services/google_sign_in_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleSignInService.cancelMayHideFailure', () {
    test('Android: a cancel may be a configuration failure', () {
      // Credential Manager gives both the same code.
      expect(
        GoogleSignInService.cancelMayHideFailure(TargetPlatform.android),
        isTrue,
      );
    });

    test('iOS: a cancel is only the person changing their mind', () {
      expect(
        GoogleSignInService.cancelMayHideFailure(TargetPlatform.iOS),
        isFalse,
      );
    });
  });
}
