import 'package:brewtaste/features/results/domain/entities/beer_result.dart';
import 'package:brewtaste/features/results/domain/entities/participant_vote.dart';
import 'package:brewtaste/shared/domain/entities/beer.dart';
import 'package:brewtaste/shared/domain/entities/participant.dart';
import 'package:brewtaste/shared/domain/entities/vote.dart';

final class ResultsCalculationService {
  List<BeerResult> calculate({
    required List<Beer> beers,
    required List<Vote> votes,
    required List<Participant> participants,
  }) {
    final participantCount = participants.where((p) => !p.isHost).length;

    final entries = beers.map((beer) {
      final beerVotes = votes.where((v) => v.beerId == beer.id).toList();
      final validVotes = beerVotes.where((v) => !v.hasSkipped).toList();
      final scores = validVotes.map((v) => v.score!).toList();
      final avg = scores.isEmpty
          ? null
          : scores.reduce((a, b) => a + b) / scores.length;
      return (
        beer: beer,
        avg: avg,
        validCount: validVotes.length,
        totalCount: participantCount,
      );
    }).toList()
      ..sort((a, b) {
        if (a.avg == null && b.avg == null) return 0;
        if (a.avg == null) return 1;
        if (b.avg == null) return -1;
        final comparison = b.avg!.compareTo(a.avg!);
        return comparison != 0
            ? comparison
            : b.validCount.compareTo(a.validCount);
      });

    return entries.asMap().entries.map((entry) {
      final data = entry.value;
      return BeerResult(
        rank: entry.key + 1,
        beer: data.beer,
        averageScore: data.avg,
        validVoteCount: data.validCount,
        totalVoteCount: data.totalCount,
      );
    }).toList();
  }

  List<ParticipantVote> votesForBeer({
    required Beer beer,
    required List<Vote> votes,
    required List<Participant> participants,
  }) {
    return participants
        .where((p) => !p.isHost)
        .map((participant) {
          final vote = votes
              .where(
                (v) => v.beerId == beer.id && v.userId == participant.userId,
              )
              .firstOrNull;
          if (vote == null) return null;
          return ParticipantVote(
            pseudo: participant.pseudo,
            hasSkipped: vote.hasSkipped,
            score: vote.score,
            guesses: vote.guesses,
          );
        })
        .whereType<ParticipantVote>()
        .toList();
  }

  bool guessIsCorrect(String guess, String truth) =>
      guess.toLowerCase().trim() == truth.toLowerCase().trim();
}
