/// Base class for errors that represent expected business conditions.
/// Catch these in notifiers and surface them in the UI. Do NOT send to Sentry.
abstract class SessionBusinessException implements Exception {
  const SessionBusinessException();
}

/// Base class for errors that represent unexpected failures.
/// Always report these to Sentry via ErrorReporter before re-surfacing.
abstract class SessionUnexpectedException implements Exception {
  const SessionUnexpectedException();
}

// ---------------------------------------------------------------------------

/// Session code was not found in any active session.
final class SessionNotFoundException extends SessionBusinessException {
  const SessionNotFoundException(this.code);
  final String code;

  @override
  String toString() =>
      'SessionNotFoundException: no active session with code $code';
}

/// Session status is `revealed` — no longer joinable.
final class SessionRevealedException extends SessionBusinessException {
  const SessionRevealedException(this.sessionId);
  final String sessionId;

  @override
  String toString() =>
      'SessionRevealedException: session $sessionId is already revealed';
}

/// Session was created more than 24 hours ago.
final class SessionExpiredException extends SessionBusinessException {
  const SessionExpiredException(this.sessionId);
  final String sessionId;

  @override
  String toString() =>
      'SessionExpiredException: session $sessionId has expired';
}

/// Failed to generate a unique session code after the maximum number of
/// retries. Always report to Sentry — this should not happen in practice.
final class SessionCodeCollisionException extends SessionUnexpectedException {
  const SessionCodeCollisionException();

  @override
  String toString() =>
      'SessionCodeCollisionException: could not generate a unique '
      'BREW-XXXX code after 5 attempts';
}
