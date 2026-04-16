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
  static final _random = Random.secure();
  static const _maxAttempts = 5;

  /// Creates a new session for [hostId].
  ///
  /// Generates a unique `BREW-XXXX` code, retrying up to [_maxAttempts]
  /// times on collision. Throws [SessionCodeCollisionException] (already
  /// reported to Sentry) if all attempts fail.
  ///
  /// [SessionRevealedException] and [SessionExpiredException] from the
  /// repository are treated as collisions — the code is still considered
  /// taken even though the session is no longer joinable.
  ///
  /// Any other exception thrown by the repository (e.g. AppwriteException)
  /// propagates to the caller after being reported to Sentry. The caller is
  /// responsible for surfacing it in the UI.
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
      } catch (e, st) {
        // Unexpected error (e.g. network, parse failure) — report to Sentry
        // and surface to the caller for UI handling.
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
