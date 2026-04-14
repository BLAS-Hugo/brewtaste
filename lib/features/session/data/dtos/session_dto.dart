// `Session` is hidden because `appwrite/models.dart` also exports a `Session`
// class, which would conflict with the domain entity of the same name.
import 'package:appwrite/models.dart' hide Session;
import 'package:brewtaste/features/session/data/dtos/dto_helpers.dart';
import 'package:brewtaste/shared/domain/entities/session.dart';

const _collection = 'sessions';

final class SessionDto {
  const SessionDto._();

  static Session fromDocument(Document doc) {
    final data = doc.data;
    final id = doc.$id;
    return Session(
      id: id,
      hostId: data.require<String>('hostId', id, _collection),
      status: data.parseEnum(SessionStatus.values, 'status', id, _collection),
      code: data.require<String>('code', id, _collection),
      isBlind: data.require<bool>('isBlind', id, _collection),
      guessFields: data
          .require<List<dynamic>>('guessFields', id, _collection)
          .map(
            (rawField) => DtoMap.parseEnumValue(
              GuessField.values,
              rawField,
              'guessFields',
              id,
              _collection,
            ),
          )
          .toList(),
      // Use Appwrite's server-managed timestamp to avoid client clock drift.
      createdAt: DateTime.parse(doc.$createdAt).toUtc(),
    );
  }

  /// Parses a session from a realtime event payload.
  ///
  /// Realtime payloads mirror the raw Appwrite document JSON but do not go
  /// through Document.fromMap, so we parse them directly here.
  static Session fromRealtimePayload(
    String id,
    Map<String, dynamic> payload,
  ) {
    return Session(
      id: id,
      hostId: payload.require<String>('hostId', id, _collection),
      status: payload.parseEnum(
        SessionStatus.values,
        'status',
        id,
        _collection,
      ),
      code: payload.require<String>('code', id, _collection),
      isBlind: payload.require<bool>('isBlind', id, _collection),
      guessFields: payload
          .require<List<dynamic>>('guessFields', id, _collection)
          .map(
            (rawField) => DtoMap.parseEnumValue(
              GuessField.values,
              rawField,
              'guessFields',
              id,
              _collection,
            ),
          )
          .toList(),
      // Realtime payloads include $createdAt as a top-level key.
      createdAt: DateTime.parse(
        payload.require<String>(r'$createdAt', id, _collection),
      ).toUtc(),
    );
  }

  /// Builds the map written to Appwrite on session creation.
  ///
  /// createdAt is intentionally omitted — Appwrite's server-managed
  /// `$createdAt` field is used instead to avoid client clock drift.
  static Map<String, dynamic> toMap({
    required String hostId,
    required SessionStatus status,
    required String code,
    required bool isBlind,
    required List<GuessField> guessFields,
  }) {
    return {
      'hostId': hostId,
      'status': status.name,
      'code': code,
      'isBlind': isBlind,
      'guessFields': guessFields.map((field) => field.name).toList(),
    };
  }
}
