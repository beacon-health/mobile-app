import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Error-reporting facade: [developer.log] in debug, Sentry in release. Both
/// paths no-op safely when Sentry was never initialized.
class ErrorReporter {
  static final ErrorReporter instance = ErrorReporter._();
  ErrorReporter._();

  /// [context] identifies the call site, e.g. `'HomePage._loadData'`.
  void report(
    Object error,
    StackTrace? stackTrace, {
    String? context,
  }) {
    if (kDebugMode) {
      developer.log(
        context != null ? '[$context] $error' : '$error',
        name: 'ErrorReporter',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }

    // Release path — forward to Sentry if it's been initialized. The Hub is
    // a no-op when not enabled, so this is safe to call unconditionally.
    if (Sentry.isEnabled) {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: context == null
            ? null
            : (scope) => scope.setTag('context', context),
      );
    }
  }
}
