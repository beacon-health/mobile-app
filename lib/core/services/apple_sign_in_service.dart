import 'dart:convert';

import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/sign_in_result.dart';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Native Sign in with Apple: fetches an identity token on-device and hands
/// it to Supabase via [GoTrueClient.signInWithIdToken], so the dashboard needs
/// only the bundle ID — no OAuth redirect or secret key JWT.
class AppleSignInService {
  AppleSignInService._();

  /// Triggers the system Sign in with Apple sheet and, on success, completes
  /// the Supabase session via `signInWithIdToken`. Safe to call only from
  /// platforms where Sign in with Apple is supported (iOS / macOS).
  static Future<SignInResult> signIn() async {
    try {
      final rawNonce = Supabase.instance.client.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      // `fullName` is deliberately not requested — nothing reads a user's
      // name, and Supabase would persist it to auth.users.raw_user_meta_data.
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        return const SignInResult(
          SignInOutcome.failed,
          errorMessage: 'Apple did not return an identity token.',
        );
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      return const SignInResult(SignInOutcome.success);
    } on SignInWithAppleAuthorizationException catch (e, stack) {
      // Unlike Credential Manager on Android, Apple's cancellation code is
      // trustworthy, so a bare cancel stays silent and unreported.
      if (e.code == AuthorizationErrorCode.canceled) {
        return const SignInResult(SignInOutcome.cancelled);
      }
      ErrorReporter.instance.report(
        e,
        stack,
        context: 'AppleSignInService.signIn',
      );
      return SignInResult(
        SignInOutcome.failed,
        errorMessage: e.message,
      );
    } on AuthException catch (e, stack) {
      ErrorReporter.instance.report(
        e,
        stack,
        context: 'AppleSignInService.signIn',
      );
      return SignInResult(
        SignInOutcome.failed,
        errorMessage: e.message,
      );
    } catch (e, stack) {
      ErrorReporter.instance.report(
        e,
        stack,
        context: 'AppleSignInService.signIn',
      );
      return SignInResult(
        SignInOutcome.failed,
        errorMessage: e.toString(),
      );
    }
  }
}
