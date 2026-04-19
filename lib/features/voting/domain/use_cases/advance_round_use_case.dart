import 'package:brewtaste/core/errors/error_reporter.dart';
import 'package:brewtaste/features/beer/domain/repositories/beer_repository.dart';
import 'package:brewtaste/features/session/domain/repositories/session_repository.dart';

final class AdvanceRoundUseCase {
  const AdvanceRoundUseCase(this._beerRepository, this._sessionRepository);

  final BeerRepository _beerRepository;
  final SessionRepository _sessionRepository;

  Future<void> revealBeer(String beerId) async {
    try {
      await _beerRepository.revealBeer(beerId);
    } catch (error, stackTrace) {
      ErrorReporter.report(error, stackTrace);
      rethrow;
    }
  }

  Future<void> endSession(String sessionId) async {
    try {
      await _sessionRepository.revealSession(sessionId);
    } catch (error, stackTrace) {
      ErrorReporter.report(error, stackTrace);
      rethrow;
    }
  }
}
