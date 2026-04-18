import 'package:brewtaste/shared/domain/entities/beer.dart';

abstract interface class BeerRepository {
  Future<Beer> addBeer({
    required String sessionId,
    required String name,
    required String brewery,
    String? style,
    String? hops,
    String? aromas,
  });

  Future<Beer> editBeer({
    required String beerId,
    required String name,
    required String brewery,
    String? style,
    String? hops,
    String? aromas,
  });

  Future<void> startVoting(String beerId);

  Future<List<Beer>> getBeers(String sessionId);

  Stream<List<Beer>> watchBeers(String sessionId);
}
