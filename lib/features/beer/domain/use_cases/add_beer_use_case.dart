import 'package:brewtaste/core/errors/error_reporter.dart';
import 'package:brewtaste/features/beer/domain/errors/beer_errors.dart';
import 'package:brewtaste/features/beer/domain/repositories/beer_repository.dart';
import 'package:brewtaste/shared/domain/entities/beer.dart';

final class AddBeerUseCase {
  const AddBeerUseCase(this._repository);

  final BeerRepository _repository;

  Future<Beer> call({
    required String sessionId,
    required String name,
    required String brewery,
    String? style,
    String? hops,
    String? aromas,
  }) async {
    try {
      return await _repository.addBeer(
        sessionId: sessionId,
        name: name.trim(),
        brewery: brewery.trim(),
        style: _clean(style),
        hops: _clean(hops),
        aromas: _clean(aromas),
      );
    } on BeerBusinessException {
      rethrow;
    } catch (error, stackTrace) {
      ErrorReporter.report(error, stackTrace);
      rethrow;
    }
  }

  static String? _clean(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
