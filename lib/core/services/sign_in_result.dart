/// Possible outcomes from a native sign-in attempt — Sign in with Apple on
/// iOS, Sign in with Google on Android.
enum SignInOutcome {
  /// User completed the provider flow AND Supabase accepted the identity token.
  success,

  /// User explicitly dismissed the provider's sign-in sheet.
  cancelled,

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
