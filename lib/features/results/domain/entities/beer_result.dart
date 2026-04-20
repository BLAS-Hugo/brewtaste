import 'package:brewtaste/shared/domain/entities/beer.dart';

class BeerResult {
  const BeerResult({
    required this.rank,
    required this.beer,
    required this.averageScore,
    required this.validVoteCount,
    required this.totalVoteCount,
  });

  final int rank;
  final Beer beer;
  final double? averageScore;
  final int validVoteCount;
  final int totalVoteCount;
}
