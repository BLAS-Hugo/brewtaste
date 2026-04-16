import 'dart:math';

import 'package:brewtaste/core/errors/error_reporter.dart';
import 'package:brewtaste/features/session/domain/errors/session_errors.dart';
import 'package:brewtaste/features/session/domain/repositories/session_repository.dart';
import 'package:brewtaste/shared/domain/entities/session.dart';

final class CreateSessionUseCase {
  const CreateSessionUseCase(this._repository);

  final SessionRepository _repository;

  // --- Code generation ---
  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  /// Single instance — [Random.secure] seeds from OS entropy; do not
  /// recreate per call.
  static final _random = Random.secure();

  static const _maxAttempts = 5;

  /// Creates a new session for [hostId].
  ///
  /// Generates a unique `BREW-XXXX` code, retrying up to 5 times on
  /// collision. Throws [SessionCodeCollisionException] (already reported
  /// to Sentry) if all attempts fail.
  ///
  /// [SessionRevealedException] and [SessionExpiredException] from the
  /// repository are treated as collisions — the code is still considered
  /// taken even though the session is no longer joinable.
  ///
  /// Any [SessionBusinessException] other than the above propagates to the
  /// caller without being reported to Sentry — it is the caller's
  /// responsibility to surface it in the UI.
  ///
  /// Any other exception (e.g. network or parse failures) is reported to
  /// Sentry before propagating to the caller.
  Future<Session> call({
    required String hostId,
    required bool isBlind,
    required List<GuessField> guessFields,
  }) async {
    for (var i = 0; i < _maxAttempts; i++) {
      final code = _generateCode();
      try {
        final existing = await _repository.getSessionByCode(code);
        if (existing == null) {
          return _repository.createSession(
            hostId: hostId,
            isBlind: isBlind,
            guessFields: guessFields,
            code: code,
          );
        }
        // existing != null → code is taken, try next
      } on SessionRevealedException {
        // The code belongs to a revealed session. It is still considered
        // taken for this attempt to avoid confusing participants who may
        // still have the old code saved. Retry with a fresh code.
        continue;
      } on SessionExpiredException {
        // Same rationale as SessionRevealedException above.
        continue;
      } on SessionBusinessException {
        // Any other business exception from the repository propagates
        // without Sentry — the caller is responsible for UI handling.
        rethrow;
      // All non-business exceptions (network, parse, SDK errors) are treated
      // identically: report to Sentry, then propagate to the caller.
      } catch (e, st) {
        ErrorReporter.report(e, st);
        rethrow;
      }
    }

    const error = SessionCodeCollisionException();
    ErrorReporter.report(error, StackTrace.current);
    throw error;
  }

  /// Returns a random session code in the format `BREW-XXXX` where `XXXX`
  /// is 4 uppercase alphanumeric characters (A–Z, 0–9).
  static String _generateCode() {
    final suffix = List.generate(
      4,
      (_) => _chars[_random.nextInt(_chars.length)],
    ).join();
    return 'BREW-$suffix';
  }
}
