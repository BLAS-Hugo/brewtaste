import 'dart:convert';

import 'package:appwrite/models.dart';
import 'package:brewtaste/features/session/data/dtos/dto_helpers.dart';
import 'package:brewtaste/shared/domain/entities/vote.dart';

const _collection = 'votes';

final class VoteDto {
  const VoteDto._();

  static Vote fromDocument(Document doc) {
    final data = doc.data;
    final id = doc.$id;
    return Vote(
      id: id,
      sessionId: data.require<String>('sessionId', id, _collection),
      beerId: data.require<String>('beerId', id, _collection),
      userId: data.require<String>('userId', id, _collection),
      score: data['score'] as int?,
      guesses: _decodeGuesses(data['guesses'] as String?),
      hasSkipped: data.require<bool>('hasSkipped', id, _collection),
    );
  }

  static Map<String, dynamic> toMap({
    required String sessionId,
    required String beerId,
    required String userId,
    required Map<String, String> guesses,
    required bool hasSkipped,
    int? score,
  }) {
    return {
      'sessionId': sessionId,
      'beerId': beerId,
      'userId': userId,
      'hasSkipped': hasSkipped,
      'guesses': jsonEncode(guesses),
      'score': ?score,
    };
  }

  static Map<String, String> _decodeGuesses(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as String));
    } on Object {
      return {};
    }
  }
}
