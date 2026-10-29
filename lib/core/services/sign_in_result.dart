/// Possible outcomes from a native sign-in attempt — Sign in with Apple or
/// Google.
enum SignInOutcome {
  /// User completed the provider flow AND Supabase accepted the identity token.
  success,

  /// User explicitly dismissed the provider's sign-in sheet.
  cancelled,

  /// Google found no account on the device to sign in with (Android's
  /// Credential Manager: "No credential available"). The person can add one
  /// in Settings; nothing is wrong with the app.
  noGoogleAccount,

  /// Sign in with Apple couldn't finish for a reason Apple doesn't name
  /// (`AuthorizationError` 1000) — most often an iPhone with no Apple Account
  /// signed in. Still reported: a missing entitlement looks the same.
  appleUnavailable,

  /// The provider returned an error other than cancellation, or Supabase
  /// rejected the identity token (network/secret/config issues).
  failed,
}

/// Result of a native sign-in attempt.
class SignInResult {
  const SignInResult(this.outcome, {this.errorMessage});

  final SignInOutcome outcome;
  final String? errorMessage;

  bool get isSuccess => outcome == SignInOutcome.success;
  bool get isCancelled => outcome == SignInOutcome.cancelled;
}
