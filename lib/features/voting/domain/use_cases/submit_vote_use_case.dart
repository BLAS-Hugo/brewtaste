import 'package:brewtaste/core/errors/error_reporter.dart';
import 'package:brewtaste/features/voting/domain/repositories/vote_repository.dart';
import 'package:brewtaste/shared/domain/entities/vote.dart';

final class SubmitVoteUseCase {
  const SubmitVoteUseCase(this._repository);

  final VoteRepository _repository;

  Future<Vote> call({
    required String sessionId,
    required String beerId,
    required String userId,
    required Map<String, String> guesses,
    required bool hasSkipped,
    int? score,
  }) async {
    assert(
      hasSkipped || (score != null && score >= 1 && score <= 10),
      'score must be 1–10 unless skipping',
    );
    try {
      return await _repository.submitVote(
        sessionId: sessionId,
        beerId: beerId,
        userId: userId,
        guesses: guesses,
        hasSkipped: hasSkipped,
        score: score,
      );
    } catch (error, stackTrace) {
      ErrorReporter.report(error, stackTrace);
      rethrow;
    }
  }
}
