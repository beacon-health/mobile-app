import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:flutter/foundation.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// How a passkey sign-in or creation ended.
enum PasskeyOutcome {
  /// Signed in, or the passkey was created.
  success,

  /// The person closed the system sheet. A choice, not a fault: nothing is
  /// shown and nothing is reported.
  cancelled,

  /// Sign-in only: this phone has no passkey for Beacon.
  noPasskey,

  /// The phone can't do passkeys right now: too old, no screen lock, or no
  /// account to sync them to.
  unavailable,

  failed,
}

/// Passkeys, through Supabase Auth: the phone holds a key that unlocks with
/// Face ID, a fingerprint or the screen lock, and nothing is typed.
///
/// What the backend allows shapes the flow. A passkey can *sign in* to an
/// account with no session, but can only be *created* by someone already
/// signed in — so a new person signs in with Apple or Google once and adds a
/// passkey from there.
abstract class PasskeyService {
  /// Set at build time (`--dart-define=PASSKEYS_ENABLED=true`). Off until
  /// the project has passkeys switched on and a domain that vouches for the
  /// app, without which every attempt would fail.
  static const bool _enabledAtBuild = bool.fromEnvironment('PASSKEYS_ENABLED');

  @visibleForTesting
  static bool? debugEnabled;

  @visibleForTesting
  static PasskeyService? debugInstance;

  static final PasskeyService _supabase = SupabasePasskeyService();

  static PasskeyService get instance => debugInstance ?? _supabase;

  /// Whether passkeys are offered at all. Like the sign-in provider, the rule
  /// takes the platform so both sides are tested.
  static bool isOfferedOn(TargetPlatform platform, {bool isWeb = kIsWeb}) {
    if (!(debugEnabled ?? _enabledAtBuild) || isWeb) return false;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.android;
  }

  /// Signs in with a passkey already on the phone.
  Future<PasskeyOutcome> signIn();

  /// Creates a passkey for the signed-in user. [name] is the label the phone
  /// shows for it.
  Future<PasskeyOutcome> create({String? name});

  /// Whether the signed-in user already has a passkey, so they aren't asked
  /// to create a second.
  Future<bool> hasPasskey();
}

class SupabasePasskeyService implements PasskeyService {
  final PasskeyAuthenticator _authenticator = PasskeyAuthenticator();

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  Future<PasskeyOutcome> signIn() => _run(
        'signIn',
        () => _auth.signInWithPasskey(_authenticator),
      );

  @override
  Future<PasskeyOutcome> create({String? name}) {
    final label = name?.trim();
    return _run(
      'create',
      () => _auth.registerPasskey(
        _authenticator,
        friendlyName: label == null || label.isEmpty ? null : label,
      ),
    );
  }

  @override
  Future<bool> hasPasskey() async {
    try {
      // Supabase marks its passkey API experimental; this is the one direct
      // use of it, and the feature is off until the build opts in.
      // ignore: experimental_member_use
      return (await _auth.passkey.list()).isNotEmpty;
    } catch (e, stack) {
      ErrorReporter.instance.report(
        e,
        stack,
        context: 'PasskeyService.hasPasskey',
      );
      // Unknown: don't nag.
      return true;
    }
  }

  /// Runs one ceremony and sorts how it ended. Only real faults are
  /// reported; closing the sheet, or having no passkey yet, are outcomes.
  Future<PasskeyOutcome> _run(
    String what,
    Future<Object?> Function() ceremony,
  ) async {
    try {
      await ceremony();
      return PasskeyOutcome.success;
    } on PasskeyAuthCancelledException {
      return PasskeyOutcome.cancelled;
    } on NoCredentialsAvailableException {
      return PasskeyOutcome.noPasskey;
    } on SyncAccountNotAvailableException {
      return PasskeyOutcome.unavailable;
    } on DeviceNotSupportedException {
      return PasskeyOutcome.unavailable;
    } on PasskeyUnsupportedException {
      return PasskeyOutcome.unavailable;
    } catch (e, stack) {
      ErrorReporter.instance.report(
        e,
        stack,
        context: 'PasskeyService.$what',
      );
      return PasskeyOutcome.failed;
    }
  }
}
