import 'package:brewtaste/core/errors/error_reporter.dart';
import 'package:brewtaste/features/beer/domain/errors/beer_errors.dart';
import 'package:brewtaste/features/beer/domain/repositories/beer_repository.dart';

final class StartVotingUseCase {
  const StartVotingUseCase(this._repository);

  final BeerRepository _repository;

  Future<void> call(String beerId) async {
    try {
      await _repository.startVoting(beerId);
    } on BeerBusinessException {
      rethrow;
    } catch (error, stackTrace) {
      ErrorReporter.report(error, stackTrace);
      rethrow;
    }
  }
}
