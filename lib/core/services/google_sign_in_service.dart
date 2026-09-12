import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/sign_in_result.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Native Sign in with Google (Android): Credential Manager shows the system
/// account picker and returns a Google ID token, which is handed to Supabase
/// via [GoTrueClient.signInWithIdToken] — the same shape as
/// `AppleSignInService` on iOS, with no browser redirect.
///
/// Configuration lives outside the code:
/// - `GOOGLE_WEB_CLIENT_ID` dart-define: the **Web** OAuth client ID (not the
///   Android one). It must also be listed first under Client IDs on the
///   Supabase Google provider.
/// - An **Android** OAuth client in Google Cloud for `org.beaconhealth.app`
///   carrying every signing SHA-1 (debug, upload, Play App Signing). Its ID is
///   never referenced in code — Credential Manager matches it by package name
///   and signature.
///
/// No nonce is sent, matching Supabase's Flutter guide: google_sign_in 7.x
/// fixes the nonce at `initialize`, which may run only once per process, so a
/// fresh nonce per attempt isn't possible.
class GoogleSignInService {
  GoogleSignInService._();

  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static Future<void>? _initialization;

  /// Shows the Google account picker and, on success, completes the Supabase
  /// session via `signInWithIdToken`. Safe to call only on Android.
  static Future<SignInResult> signIn() async {
    if (_webClientId.isEmpty) {
      return const SignInResult(
        SignInOutcome.failed,
        errorMessage: 'Google sign-in is not configured for this build.',
      );
    }

    try {
      await _ensureInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        return const SignInResult(
          SignInOutcome.failed,
          errorMessage: 'Google did not return an identity token.',
        );
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      return const SignInResult(SignInOutcome.success);
    } on GoogleSignInException catch (e, stack) {
      // Credential Manager also reports some misconfigurations (wrong SHA-1,
      // package name, or client ID) as `canceled`. If the picker closes
      // instantly without the user touching it, suspect Google Cloud config.
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const SignInResult(SignInOutcome.cancelled);
      }
      ErrorReporter.instance.report(
        e,
        stack,
        context: 'GoogleSignInService.signIn',
      );
      return SignInResult(
        SignInOutcome.failed,
        errorMessage: e.description ?? e.code.name,
      );
    } on AuthException catch (e, stack) {
      ErrorReporter.instance.report(
        e,
        stack,
        context: 'GoogleSignInService.signIn',
      );
      return SignInResult(SignInOutcome.failed, errorMessage: e.message);
    } catch (e, stack) {
      ErrorReporter.instance.report(
        e,
        stack,
        context: 'GoogleSignInService.signIn',
      );
      return SignInResult(SignInOutcome.failed, errorMessage: e.toString());
    }
  }

  /// google_sign_in 7.x requires exactly one awaited `initialize` per process
  /// before any other call. Cache it so repeat taps share a single call, and
  /// clear it on failure so a later tap can retry.
  static Future<void> _ensureInitialized() async {
    final pending = _initialization ??=
        GoogleSignIn.instance.initialize(serverClientId: _webClientId);
    try {
      await pending;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }
}
