import 'package:brewtaste/features/session/domain/errors/session_errors.dart';
import 'package:brewtaste/shared/domain/entities/participant.dart';
import 'package:brewtaste/shared/domain/entities/session.dart';

abstract interface class SessionRepository {
  /// Creates a new session document and the host participant document.
  /// The [code] has already been validated as unique by the use case.
  Future<Session> createSession({
    required String hostId,
    required bool isBlind,
    required List<GuessField> guessFields,
    required String code,
  });

  /// Returns the session matching [code], or `null` if no session with that
  /// code exists.
  ///
  /// Throws [SessionRevealedException] if the session status is `revealed`.
  /// Throws [SessionExpiredException] if the session was created more than
  /// 24 hours ago.
  Future<Session?> getSessionByCode(String code);

  /// Returns the session with [sessionId], or `null` if not found.
  ///
  /// Used by router guards and screens that receive an ID in the path param.
  Future<Session?> getSessionById(String sessionId);

  /// Returns the current participant list for [sessionId].
  ///
  /// Capped at 100 participants (Appwrite hard limit per query). Sessions
  /// with more than 100 participants will silently truncate.
  Future<List<Participant>> getParticipants(String sessionId);

  /// Emits the participant list whenever a participant is created or deleted
  /// in [sessionId]. The current list is emitted immediately on subscribe
  /// so callers do not need a separate [getParticipants] call.
  ///
  /// Reconnects automatically on WebSocket errors or server-initiated closes.
  Stream<List<Participant>> watchParticipants(String sessionId);

  /// Emits the session whenever its document changes.
  Stream<Session> watchSession(String sessionId);

  /// Creates a participant document for the given user in [sessionId].
  Future<Participant> createParticipant({
    required String sessionId,
    required String userId,
    required String pseudo,
    required bool isHost,
  });

  /// Deletes all votes for [kickedUserId] in [sessionId], then deletes
  /// the participant document [participantId].
  Future<void> kickParticipant({
    required String sessionId,
    required String participantId,
    required String kickedUserId,
  });

  /// Transitions the session from `waiting` to `tasting`.
  Future<void> startSession(String sessionId);

  /// Transitions the session from `tasting` to `revealed`.
  Future<void> revealSession(String sessionId);
}
