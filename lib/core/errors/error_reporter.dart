import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

abstract final class ErrorReporter {
  /// Injectable seam for tests. When non-null, this callback is invoked
  /// instead of Sentry. Always restore to `null` via `addTearDown` to
  /// prevent state leaking into subsequent tests.
  @visibleForTesting
  static void Function(Object error, StackTrace? stack)? onReport;

  static void report(Object error, StackTrace? stack) {
    final handler = onReport;
    if (handler != null) {
      handler(error, stack);
    } else {
      unawaited(Sentry.captureException(error, stackTrace: stack));
    }
  }
}
