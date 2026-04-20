import 'package:brewtaste/core/appwrite/auth_notifier.dart';
import 'package:brewtaste/core/errors/error_reporter.dart';
import 'package:brewtaste/features/beer/infra/beer_repository_provider.dart';
import 'package:brewtaste/features/session/domain/errors/session_errors.dart';
import 'package:brewtaste/features/session/infra/session_repository_provider.dart';
import 'package:brewtaste/features/voting/infra/vote_repository_provider.dart';
import 'package:brewtaste/features/voting/presentation/providers/advance_round_use_case_provider.dart';
import 'package:brewtaste/features/voting/presentation/providers/start_voting_use_case_provider.dart';
import 'package:brewtaste/features/voting/presentation/providers/submit_vote_use_case_provider.dart';
import 'package:brewtaste/shared/domain/entities/beer.dart';
import 'package:brewtaste/shared/domain/entities/participant.dart';
import 'package:brewtaste/shared/domain/entities/session.dart';
import 'package:brewtaste/shared/domain/entities/vote.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tasting_notifier.g.dart';

class TastingState {
  const TastingState({
    required this.session,
    required this.beers,
    required this.votes,
    required this.participants,
    required this.currentUserId,
    required this.votedBeerIds,
  });

  final Session session;
  final List<Beer> beers;
  final List<Vote> votes;
  final List<Participant> participants;
  final String currentUserId;
  final Set<String> votedBeerIds;

  bool get isHost => currentUserId == session.hostId;

  Beer? get activeBeer =>
      beers.where((beer) => beer.status == BeerStatus.voting).firstOrNull;

  int get participantCount =>
      participants.where((participant) => !participant.isHost).length;

  int voteCountFor(String beerId) =>
      votes.where((vote) => vote.beerId == beerId).length;

  bool hasVotedFor(String beerId) => votedBeerIds.contains(beerId);

  List<Beer> get visibleBeers {
    if (isHost || !session.isBlind) return beers;
    return beers.map((beer) {
      if (beer.status == BeerStatus.revealed) return beer;
      return beer.copyWith(name: null, brewery: null);
    }).toList();
  }

  TastingState copyWith({
    Session? session,
    List<Beer>? beers,
    List<Vote>? votes,
    List<Participant>? participants,
    Set<String>? votedBeerIds,
  }) =>
      TastingState(
        session: session ?? this.session,
        beers: beers ?? this.beers,
        votes: votes ?? this.votes,
        participants: participants ?? this.participants,
        currentUserId: currentUserId,
        votedBeerIds: votedBeerIds ?? this.votedBeerIds,
      );
}

@riverpod
class TastingNotifier extends _$TastingNotifier {
  @override
  Future<TastingState> build(String sessionId) async {
    final userId = await ref.read(authProvider.future);
    final sessionRepo = ref.read(sessionRepositoryProvider);
    final beerRepo = ref.read(beerRepositoryProvider);

    Session? session;
    var beers = <Beer>[];
    var participants = <Participant>[];

    await Future.wait([
      sessionRepo.getSessionById(sessionId).then((s) => session = s),
      beerRepo.getBeers(sessionId).then((b) => beers = b),
      sessionRepo.getParticipants(sessionId).then((p) => participants = p),
    ]);

    if (session == null) throw SessionNotFoundException(sessionId);
    final resolvedSession = session!;

    var current = TastingState(
      session: resolvedSession,
      beers: beers,
      votes: const [],
      participants: participants,
      currentUserId: userId,
      votedBeerIds: const {},
    );

    final beersSub = beerRepo.watchBeers(sessionId).listen(
      (updatedBeers) {
        state = AsyncData(current = current.copyWith(beers: updatedBeers));
      },
      onError: (Object error, StackTrace stackTrace) {
        ErrorReporter.report(error, stackTrace);
      },
    );
    ref.onDispose(beersSub.cancel);

    final sessionSub = sessionRepo.watchSession(sessionId).listen(
      (updatedSession) {
        state = AsyncData(
          current = current.copyWith(session: updatedSession),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        ErrorReporter.report(error, stackTrace);
      },
    );
    ref.onDispose(sessionSub.cancel);

    if (userId == resolvedSession.hostId) {
      final votesSub = ref
          .read(voteRepositoryProvider)
          .watchVotesForSession(sessionId)
          .listen(
        (updatedVotes) {
          state = AsyncData(current = current.copyWith(votes: updatedVotes));
        },
        onError: (Object error, StackTrace stackTrace) {
          ErrorReporter.report(error, stackTrace);
        },
      );
      ref.onDispose(votesSub.cancel);
    }

    return current;
  }

  Future<void> startVoting(String beerId) async {
    try {
      await ref.read(startVotingUseCaseProvider).call(beerId);
    } catch (error, stackTrace) {
      ErrorReporter.report(error, stackTrace);
      rethrow;
    }
  }

  Future<void> revealBeer(String beerId) async {
    try {
      await ref.read(advanceRoundUseCaseProvider).revealBeer(beerId);
    } catch (error, stackTrace) {
      ErrorReporter.report(error, stackTrace);
      rethrow;
    }
  }

  Future<void> endSession() async {
    try {
      await ref.read(advanceRoundUseCaseProvider).endSession(sessionId);
    } catch (error, stackTrace) {
      ErrorReporter.report(error, stackTrace);
      rethrow;
    }
  }

  Future<void> submitVote({
    required String beerId,
    required Map<String, String> guesses,
    required bool hasSkipped,
    int? score,
  }) async {
    final current = state.value;
    if (current == null) return;
    if (current.hasVotedFor(beerId)) return;

    try {
      await ref.read(submitVoteUseCaseProvider).call(
            sessionId: sessionId,
            beerId: beerId,
            userId: current.currentUserId,
            guesses: guesses,
            hasSkipped: hasSkipped,
            score: score,
          );
      state = AsyncData(
        current.copyWith(
          votedBeerIds: {...current.votedBeerIds, beerId},
        ),
      );
    } catch (error, stackTrace) {
      ErrorReporter.report(error, stackTrace);
      rethrow;
    }
  }
}
