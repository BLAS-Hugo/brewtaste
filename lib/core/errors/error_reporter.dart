import 'package:sentry_flutter/sentry_flutter.dart';

abstract final class ErrorReporter {
  static void report(Object error, StackTrace? stack) =>
      Sentry.captureException(error, stackTrace: stack);
}
