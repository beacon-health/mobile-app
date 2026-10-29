import 'package:beacon_app/core/services/google_sign_in_service.dart';
import 'package:beacon_app/core/services/sign_in_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  group('GoogleSignInService.interpret', () {
    ({SignInResult result, bool report}) interpret(
      GoogleSignInExceptionCode code, {
      String? description,
      TargetPlatform platform = TargetPlatform.android,
    }) =>
        GoogleSignInService.interpret(
          GoogleSignInException(code: code, description: description),
          platform,
        );

    test('closing the Android picker is a quiet cancel', () {
      // It used to show these words as an error, in either wording.
      for (final words in [
        'activity is cancelled by the user.',
        '[16] Cancelled by user.',
        'Canceled by user',
      ]) {
        final (:result, :report) = interpret(
          GoogleSignInExceptionCode.canceled,
          description: words,
        );
        expect(result.outcome, SignInOutcome.cancelled, reason: words);
        expect(report, isFalse, reason: words);
      }
    });

    test('a bare Android cancel stays quiet on screen but is reported', () {
      // Configuration failures have arrived looking exactly like this.
      final (:result, :report) = interpret(GoogleSignInExceptionCode.canceled);
      expect(result.outcome, SignInOutcome.cancelled);
      expect(report, isTrue);
    });

    test('an Android cancel with other detail is a reported failure', () {
      final (:result, :report) = interpret(
        GoogleSignInExceptionCode.canceled,
        description: '[16] Account reauth failed.',
      );
      expect(result.outcome, SignInOutcome.failed);
      expect(result.errorMessage, '[16] Account reauth failed.');
      expect(report, isTrue);
    });

    test('an iOS cancel is quiet, whatever it says', () {
      final (:result, :report) = interpret(
        GoogleSignInExceptionCode.canceled,
        description: 'The user canceled the sign-in flow.',
        platform: TargetPlatform.iOS,
      );
      expect(result.outcome, SignInOutcome.cancelled);
      expect(report, isFalse);
    });

    test('no Google account on the phone is told to the person, not reported',
        () {
      final (:result, :report) = interpret(
        GoogleSignInExceptionCode.unknownError,
        description: 'No credential available: No credentials available',
      );
      expect(result.outcome, SignInOutcome.noGoogleAccount);
      expect(report, isFalse);
    });

    test('anything else is a reported failure', () {
      final (:result, :report) = interpret(
        GoogleSignInExceptionCode.providerConfigurationError,
      );
      expect(result.outcome, SignInOutcome.failed);
      expect(result.errorMessage, 'providerConfigurationError');
      expect(report, isTrue);
    });
  });
}
