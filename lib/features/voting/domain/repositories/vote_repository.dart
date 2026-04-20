import 'package:brewtaste/shared/domain/entities/vote.dart';

abstract interface class VoteRepository {
  Future<Vote> submitVote({
    required String sessionId,
    required String beerId,
    required String userId,
    required Map<String, String> guesses,
    required bool hasSkipped,
    int? score,
  });

  Stream<List<Vote>> watchVotesForSession(String sessionId);
}
