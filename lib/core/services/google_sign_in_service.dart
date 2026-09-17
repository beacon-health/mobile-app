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
      // A build-configuration mistake, not something a user can act on — and
      // this layer has no BuildContext to localize with. Report the specifics
      // and let NativeSignInButton show the localized authSignInError.
      ErrorReporter.instance.report(
        StateError('GOOGLE_WEB_CLIENT_ID dart-define is missing'),
        StackTrace.current,
        context: 'GoogleSignInService.signIn/notConfigured',
      );
      return const SignInResult(SignInOutcome.failed);
    }

    try {
      await _ensureInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        ErrorReporter.instance.report(
          StateError('Google returned no identity token'),
          StackTrace.current,
          context: 'GoogleSignInService.signIn/noIdToken',
        );
        return const SignInResult(SignInOutcome.failed);
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      return const SignInResult(SignInOutcome.success);
    } on GoogleSignInException catch (e, stack) {
      // Credential Manager reports configuration failures as `canceled`, the
      // same code a user gets for dismissing the sheet. Four real failures
      // during Android bring-up — a missing client ID, a Play-less emulator
      // image, device check-in disabled, and an unregistered signing key
      // (UNREGISTERED_ON_API_CONSOLE) — all arrived here as `canceled` and were
      // silently swallowed, leaving a button that did nothing.
      //
      // Two defences, because the codes alone can't be trusted:
      //
      //  1. Every cancellation is reported, so failures are visible in Sentry
      //     even when the UI stays quiet. A deliberate dismissal is cheap to
      //     filter; an invisible outage is not.
      //  2. A cancellation carrying a `description` is treated as a failure.
      //     Dismissals come back bare; Play Services attaches detail when
      //     something is actually wrong. This is a heuristic, which is why (1)
      //     is the guarantee and this is the improvement.
      if (e.code == GoogleSignInExceptionCode.canceled) {
        final detail = e.description;
        ErrorReporter.instance.report(
          e,
          stack,
          context: 'GoogleSignInService.signIn/cancelled',
        );
        if (detail == null || detail.isEmpty) {
          return const SignInResult(SignInOutcome.cancelled);
        }
        return SignInResult(SignInOutcome.failed, errorMessage: detail);
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
