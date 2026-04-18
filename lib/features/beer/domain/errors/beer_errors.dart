sealed class BeerBusinessException implements Exception {
  const BeerBusinessException();
}

final class BeerNotFoundException extends BeerBusinessException {
  const BeerNotFoundException(this.beerId);

  final String beerId;

  @override
  String toString() => 'BeerNotFoundException: beer $beerId not found';
}
