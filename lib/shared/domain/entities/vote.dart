import 'package:freezed_annotation/freezed_annotation.dart';

part 'vote.freezed.dart';

@freezed
abstract class Vote with _$Vote {
  const factory Vote({
    required String id,
    required String sessionId,
    required String beerId,
    required String userId,
    required Map<String, String> guesses,
    required bool hasSkipped,
    int? score,
  }) = _Vote;
}
