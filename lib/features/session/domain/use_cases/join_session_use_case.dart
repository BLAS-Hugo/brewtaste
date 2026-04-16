import 'package:brewtaste/core/errors/error_reporter.dart';
import 'package:brewtaste/features/session/domain/errors/session_errors.dart';
import 'package:brewtaste/features/session/domain/repositories/session_repository.dart';
import 'package:brewtaste/shared/domain/entities/participant.dart';

final class JoinSessionUseCase {
  const JoinSessionUseCase(this._repository);

  final SessionRepository _repository;

  /// Joins an existing session using [code] and [pseudo].
  ///
  /// [code] is normalised via `trim().toUpperCase()` before any repository
  /// call. The caller is responsible for obtaining [userId] from the auth
  /// layer before invoking this use case.
  ///
  /// Throws [SessionNotFoundException] (with the normalised code) if no
  /// active session matches [code].
  /// [SessionRevealedException] and [SessionExpiredException] propagate as-is
  /// — they are business errors and are NOT reported to Sentry.
  /// Any other exception is reported to Sentry before propagating.
  Future<Participant> call({
    required String code,
    required String userId,
    required String pseudo,
  }) async {
    final normalisedCode = code.trim().toUpperCase();
    final normalisedPseudo = pseudo.trim();

    try {
      final session = await _repository.getSessionByCode(normalisedCode);
      if (session == null) {
        throw SessionNotFoundException(normalisedCode);
      }
      return await _repository.createParticipant(
        sessionId: session.id,
        userId: userId,
        pseudo: normalisedPseudo,
        isHost: false,
      );
    } on SessionBusinessException {
      rethrow;
    } catch (e, st) {
      ErrorReporter.report(e, st);
      rethrow;
    }
  }
}
