import 'package:brewtaste/core/errors/error_reporter.dart';
import 'package:brewtaste/features/beer/infra/beer_repository_provider.dart';
import 'package:brewtaste/features/results/domain/entities/beer_result.dart';
import 'package:brewtaste/features/results/domain/services/results_calculation_service.dart';
import 'package:brewtaste/features/session/domain/errors/session_errors.dart';
import 'package:brewtaste/features/session/infra/session_repository_provider.dart';
import 'package:brewtaste/features/voting/infra/vote_repository_provider.dart';
import 'package:brewtaste/shared/domain/entities/beer.dart';
import 'package:brewtaste/shared/domain/entities/participant.dart';
import 'package:brewtaste/shared/domain/entities/session.dart';
import 'package:brewtaste/shared/domain/entities/vote.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'results_notifier.g.dart';

class ResultsState {
  const ResultsState({
    required this.session,
    required this.rankedBeers,
    required this.votes,
    required this.participants,
  });

  final Session session;
  final List<BeerResult> rankedBeers;
  final List<Vote> votes;
  final List<Participant> participants;
}

@riverpod
class ResultsNotifier extends _$ResultsNotifier {
  @override
  Future<ResultsState> build(String sessionId) async {
    final sessionRepo = ref.read(sessionRepositoryProvider);
    final beerRepo = ref.read(beerRepositoryProvider);
    final voteRepo = ref.read(voteRepositoryProvider);

    Session? session;
    var beers = <Beer>[];
    var participants = <Participant>[];
    var votes = <Vote>[];

    try {
      await Future.wait([
        sessionRepo.getSessionById(sessionId).then((s) => session = s),
        beerRepo.getBeers(sessionId).then((b) => beers = b),
        sessionRepo.getParticipants(sessionId).then((p) => participants = p),
        voteRepo.getVotesForSession(sessionId).then((v) => votes = v),
      ]);
    } catch (error, stackTrace) {
      ErrorReporter.report(error, stackTrace);
      rethrow;
    }

    if (session == null) throw SessionNotFoundException(sessionId);

    final rankedBeers = const ResultsCalculationService().calculate(
      beers: beers,
      votes: votes,
      participants: participants,
    );

    return ResultsState(
      session: session!,
      rankedBeers: rankedBeers,
      votes: votes,
      participants: participants,
    );
  }
}
