import 'package:freezed_annotation/freezed_annotation.dart';

part 'beer.freezed.dart';

enum BeerStatus { pending, voting, revealed }

@freezed
abstract class Beer with _$Beer {
  const factory Beer({
    required String id,
    required String sessionId,
    required BeerStatus status,
    required DateTime addedAt,
    String? name,
    String? brewery,
    String? style,
    String? hops,
    String? aromas,
  }) = _Beer;
}
