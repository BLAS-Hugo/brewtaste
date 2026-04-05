import 'package:freezed_annotation/freezed_annotation.dart';

part 'participant.freezed.dart';

@freezed
abstract class Participant with _$Participant {
  const factory Participant({
    required String id,
    required String sessionId,
    required String userId,
    required String pseudo,
    required bool isHost,
    required DateTime joinedAt,
  }) = _Participant;
}
