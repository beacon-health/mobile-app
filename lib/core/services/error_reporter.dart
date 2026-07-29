import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Thin error-reporting facade.
///
/// Debug builds: errors are printed via [developer.log] with a named tag for
/// console filtering. Release builds: forwards to Sentry via
/// [Sentry.captureException] when Sentry has been initialized (see
/// `main.dart`). If Sentry was not initialized — no DSN supplied — the release
/// path is a no-op, so callers never crash on reports.
class ErrorReporter {
  static final ErrorReporter instance = ErrorReporter._();
  ErrorReporter._();

  /// Reports [error] with an optional [stackTrace] and [context] label.
  ///
  /// [context] is a short identifier for the call site, e.g.
  /// `'HomePage._loadData'`. Shown in the log tag for easy filtering and
  /// attached as a `context` tag on the Sentry event.
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
