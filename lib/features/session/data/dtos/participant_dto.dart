import 'package:appwrite/models.dart';
import 'package:brewtaste/features/session/data/dtos/dto_helpers.dart';
import 'package:brewtaste/shared/domain/entities/participant.dart';

const _collection = 'participants';

final class ParticipantDto {
  const ParticipantDto._();

  static Participant fromDocument(Document doc) {
    final data = doc.data;
    final id = doc.$id;
    return Participant(
      id: id,
      sessionId: data.require<String>('sessionId', id, _collection),
      userId: data.require<String>('userId', id, _collection),
      pseudo: data.require<String>('pseudo', id, _collection),
      isHost: data.require<bool>('isHost', id, _collection),
      // Use Appwrite's server-managed timestamp to avoid client clock drift.
      joinedAt: DateTime.parse(doc.$createdAt).toUtc(),
    );
  }

  /// Builds the map written to Appwrite on participant creation.
  ///
  /// joinedAt is intentionally omitted — Appwrite's server-managed
  /// `$createdAt` field is used instead to avoid client clock drift.
  static Map<String, dynamic> toMap({
    required String sessionId,
    required String userId,
    required String pseudo,
    required bool isHost,
  }) {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'pseudo': pseudo,
      'isHost': isHost,
    };
  }
}
