import 'package:beacon_app/core/services/error_reporter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Whether an error on `onAuthStateChange` is a background session refresh
/// that failed because the device is offline. gotrue retries it once the
/// network is back, so it is not a bug.
bool isOfflineRefresh(Object error) => error is AuthRetryableFetchException;

/// The `onError` every `onAuthStateChange` listener passes. gotrue puts a
/// failed background refresh on that stream as an error event, and a listener
/// without `onError` lets it escape as an uncaught error. Offline refreshes are
/// dropped ([isOfflineRefresh]); anything else is reported under [context].
void Function(Object error, StackTrace stack) onAuthStreamError(
  String context,
) =>
    (error, stack) {
      if (isOfflineRefresh(error)) return;
      ErrorReporter.instance.report(error, stack, context: context);
    };
