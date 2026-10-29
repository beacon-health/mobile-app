import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/sign_in_result.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Native Sign in with Google: Credential Manager's account picker on
/// Android, Google's sign-in sheet on iOS. Either returns a Google ID token,
/// which is handed to Supabase via [GoTrueClient.signInWithIdToken] — the same
/// shape as `AppleSignInService`.
///
/// Configuration lives outside the code:
/// - `GOOGLE_WEB_CLIENT_ID` dart-define: the **Web** OAuth client ID, passed
///   as the server client ID on both platforms. It must also be listed first
///   under Client IDs on the Supabase Google provider.
/// - An **Android** OAuth client in Google Cloud for `org.beaconhealth.app`
///   carrying every signing SHA-1 (debug, upload, Play App Signing). Its ID is
///   never referenced in code — Credential Manager matches it by package name
///   and signature.
/// - An **iOS** OAuth client for the same bundle ID. Its ID is the
///   `GOOGLE_IOS_CLIENT_ID` build setting (from `ios/Flutter/Secrets.xcconfig`),
///   which Info.plist turns into `GIDClientID` and the reversed-ID URL scheme
///   the sheet returns through. It is also listed under Client IDs on
///   Supabase.
///
/// No nonce is sent: google_sign_in 7.x fixes the nonce at `initialize`, which
/// may run only once per process, so a fresh nonce per attempt isn't
/// possible. Google's iOS SDK puts a nonce of its own in every ID token, so
/// the Supabase Google provider has "Skip nonce check" on.
class GoogleSignInService {
  GoogleSignInService._();

  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static Future<void>? _initialization;

  /// Shows the Google account picker and, on success, completes the Supabase
  /// session via `signInWithIdToken`.
  static Future<SignInResult> signIn() async {
    if (_webClientId.isEmpty) {
      // A build-configuration mistake, not something a user can act on — and
      // this layer has no BuildContext to localize with. Report the specifics
      // and let NativeSignInButtons show the localized authSignInError.
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
      final (:result, :report) = interpret(e, defaultTargetPlatform);
      if (report) {
        ErrorReporter.instance.report(
          e,
          stack,
          context: e.code == GoogleSignInExceptionCode.canceled
              ? 'GoogleSignInService.signIn/cancelled'
              : 'GoogleSignInService.signIn',
        );
      }
      return result;
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

  /// What a [GoogleSignInException] on [platform] means for the person, and
  /// whether it is a bug worth reporting.
  ///
  /// On Android, Credential Manager reports configuration failures as
  /// `canceled`, the same code a person gets for dismissing the sheet. Four
  /// real failures during Android bring-up — a missing client ID, a Play-less
  /// emulator image, device check-in disabled, and an unregistered signing key
  /// (UNREGISTERED_ON_API_CONSOLE) — all arrived as `canceled` and were
  /// silently swallowed, leaving a button that did nothing. So there:
  ///
  ///  1. A cancel is reported, so failures are visible in Sentry even when
  ///     the UI stays quiet — except Credential Manager's own words for a
  ///     closed picker ([isPickerClosed]), which are the person's choice.
  ///  2. A cancel carrying any other description is treated as a failure:
  ///     Play Services attaches detail when something is actually wrong.
  ///
  /// A phone with no Google account on it is not a bug either: the person is
  /// told to add one ([SignInOutcome.noGoogleAccount]).
  static ({SignInResult result, bool report}) interpret(
    GoogleSignInException e,
    TargetPlatform platform,
  ) {
    final detail = e.description;
    if (e.code == GoogleSignInExceptionCode.canceled) {
      if (!cancelMayHideFailure(platform) || isPickerClosed(detail)) {
        return (
          result: const SignInResult(SignInOutcome.cancelled),
          report: false,
        );
      }
      if (detail == null || detail.isEmpty) {
        return (
          result: const SignInResult(SignInOutcome.cancelled),
          report: true,
        );
      }
      return (
        result: SignInResult(SignInOutcome.failed, errorMessage: detail),
        report: true,
      );
    }
    if (isNoAccount(e)) {
      return (
        result: const SignInResult(SignInOutcome.noGoogleAccount),
        report: false,
      );
    }
    return (
      result: SignInResult(
        SignInOutcome.failed,
        errorMessage: detail ?? e.code.name,
      ),
      report: true,
    );
  }

  /// The message when the person closes the account picker: Credential
  /// Manager's "activity is cancelled by the user." or Play Services'
  /// "[16] Cancelled by user." — the same code 16 also carries real failures
  /// ("[16] Account reauth failed."), so the words decide, not the number.
  static bool isPickerClosed(String? description) =>
      description != null && _pickerClosed.hasMatch(description);

  static final RegExp _pickerClosed =
      RegExp('cancell?ed by (the )?user', caseSensitive: false);

  /// google_sign_in_android's error when Credential Manager finds no Google
  /// account on the device (`NoCredentialException`).
  static bool isNoAccount(GoogleSignInException e) =>
      e.code == GoogleSignInExceptionCode.unknownError &&
      (e.description?.startsWith('No credential available') ?? false);

  /// Whether a `canceled` result on [platform] may be a failure in disguise.
  /// Android's Credential Manager gives configuration problems the same code
  /// as a dismissed sheet. Google's iOS sheet reports them as errors of their
  /// own, so there a cancel is only the person changing their mind — a
  /// choice, not a bug, and not reported.
  static bool cancelMayHideFailure(TargetPlatform platform) =>
      platform == TargetPlatform.android;

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
