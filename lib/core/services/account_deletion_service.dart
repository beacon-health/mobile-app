import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:beacon_app/core/services/local_user_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Possible outcomes from an account-deletion attempt.
enum AccountDeletionOutcome {
  /// The server deleted the account and local state has been cleared.
  success,

  /// No signed-in user — nothing to delete.
  notSignedIn,

  /// The RPC failed. The account still exists.
  failed,
}

/// Result of an account-deletion attempt.
class AccountDeletionResult {
  const AccountDeletionResult(this.outcome, {this.errorMessage});

  final AccountDeletionOutcome outcome;
  final String? errorMessage;

  bool get isSuccess => outcome == AccountDeletionOutcome.success;
}

/// Permanently deletes the signed-in user's account (Guideline 5.1.1(v)).
///
/// Backed by the `delete_account` Postgres function, which is applied by hand
/// and not tracked in this repo: SECURITY DEFINER, takes no arguments, and
/// acts only on `auth.uid()`. It anonymizes the user's ratings and correction
/// submissions, then deletes their favorites, settings, and `auth.users` row.
class AccountDeletionService {
  AccountDeletionService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _rpc = 'delete_account';
  static const String _logContext = 'AccountDeletionService.deleteAccount';

  Future<AccountDeletionResult> deleteAccount() async {
    if (_client.auth.currentUser == null) {
      return const AccountDeletionResult(AccountDeletionOutcome.notSignedIn);
    }

    try {
      await _client.rpc<void>(_rpc);
    } on PostgrestException catch (e, stackTrace) {
      ErrorReporter.instance.report(e, stackTrace, context: _logContext);
      return AccountDeletionResult(
        AccountDeletionOutcome.failed,
        errorMessage: e.message,
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(e, stackTrace, context: _logContext);
      return AccountDeletionResult(
        AccountDeletionOutcome.failed,
        errorMessage: e.toString(),
      );
    }

    await _clearLocalState();
    return const AccountDeletionResult(AccountDeletionOutcome.success);
  }

  /// Failures here are reported but not surfaced — the server-side delete
  /// already succeeded, so the account is gone either way.
  Future<void> _clearLocalState() async {
    try {
      // The JWT is already orphaned, so a 403 from the server-side revoke is
      // expected; the local session still gets cleared.
      await _client.auth.signOut();
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(e, stackTrace, context: '$_logContext.out');
    }
    await clearLocalUserData(logContext: '$_logContext.local');
  }
}
