import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';

enum SessionStatus { waiting, tasting, revealed }

enum GuessField { style, brewery, hops, aromas }

@freezed
abstract class Session with _$Session {
  const factory Session({
    required String id,
    required String hostId,
    required SessionStatus status,
    required String code,
    required bool isBlind,
    required List<GuessField> guessFields,
    required DateTime createdAt,
  }) = _Session;
}
