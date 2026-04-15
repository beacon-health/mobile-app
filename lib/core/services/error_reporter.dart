import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Thin error-reporting facade.
///
/// Debug builds: errors are printed via [developer.log] with a named tag for
/// console filtering. Release builds: no-op.
///
/// Post-MVP: replace the release path with
/// `Sentry.captureException(error, stackTrace: stackTrace)` (or equivalent)
/// without touching any call sites.
class ErrorReporter {
  static final ErrorReporter instance = ErrorReporter._();
  ErrorReporter._();

  /// Reports [error] with an optional [stackTrace] and [context] label.
  ///
  /// [context] is a short identifier for the call site, e.g.
  /// `'HomePage._loadData'`. Shown in the log tag for easy filtering.
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
    }
    // TODO(post-MVP): Sentry.captureException(error, stackTrace: stackTrace);
  }
}
