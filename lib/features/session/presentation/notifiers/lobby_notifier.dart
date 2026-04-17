import 'package:brewtaste/core/appwrite/auth_notifier.dart';
import 'package:brewtaste/core/errors/error_reporter.dart';
import 'package:brewtaste/features/session/domain/errors/session_errors.dart';
import 'package:brewtaste/features/session/infra/session_repository_provider.dart';
import 'package:brewtaste/shared/domain/entities/participant.dart';
import 'package:brewtaste/shared/domain/entities/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lobby_notifier.g.dart';

class LobbyState {
  const LobbyState({
    required this.session,
    required this.participants,
    required this.currentUserId,
  });

  final Session session;
  final List<Participant> participants;
  final String currentUserId;

  bool get isHost => currentUserId == session.hostId;

  LobbyState copyWith({
    Session? session,
    List<Participant>? participants,
  }) =>
      LobbyState(
        session: session ?? this.session,
        participants: participants ?? this.participants,
        currentUserId: currentUserId,
      );
}

@riverpod
class LobbyNotifier extends _$LobbyNotifier {
  @override
  Future<LobbyState> build(String sessionId) async {
    final userId = await ref.read(authProvider.future);
    final repo = ref.read(sessionRepositoryProvider);

    final session = await repo.getSessionById(sessionId);
    if (session == null) throw SessionNotFoundException(sessionId);

    final initialParticipants = await repo.getParticipants(sessionId);
    var current = LobbyState(
      session: session,
      participants: initialParticipants,
      currentUserId: userId,
    );

    final participantsSub = repo.watchParticipants(sessionId).listen(
      (participants) {
        state = AsyncData(
          current = current.copyWith(participants: participants),
        );
      },
      onError: (Object e, StackTrace st) {
        ErrorReporter.report(e, st);
      },
    );
    ref.onDispose(participantsSub.cancel);

    final sessionSub = repo.watchSession(sessionId).listen(
      (s) {
        state = AsyncData(current = current.copyWith(session: s));
      },
      onError: (Object e, StackTrace st) {
        ErrorReporter.report(e, st);
      },
    );
    ref.onDispose(sessionSub.cancel);

    return current;
  }

  Future<void> kick({
    required String participantId,
    required String kickedUserId,
  }) async {
    try {
      await ref.read(sessionRepositoryProvider).kickParticipant(
            sessionId: sessionId,
            participantId: participantId,
            kickedUserId: kickedUserId,
          );
    } catch (e, st) {
      ErrorReporter.report(e, st);
      rethrow;
    }
  }

  Future<void> startSession() async {
    try {
      await ref.read(sessionRepositoryProvider).startSession(sessionId);
    } catch (e, st) {
      ErrorReporter.report(e, st);
      rethrow;
    }
  }
}
