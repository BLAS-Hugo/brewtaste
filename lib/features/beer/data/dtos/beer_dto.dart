import 'package:appwrite/models.dart';
import 'package:brewtaste/features/session/data/dtos/dto_helpers.dart';
import 'package:brewtaste/shared/domain/entities/beer.dart';

const _collection = 'beers';

final class BeerDto {
  const BeerDto._();

  static Beer fromDocument(Document doc) {
    final data = doc.data;
    final id = doc.$id;
    return Beer(
      id: id,
      sessionId: data.require<String>('sessionId', id, _collection),
      status: data.parseEnum(BeerStatus.values, 'status', id, _collection),
      name: data['name'] as String?,
      brewery: data['brewery'] as String?,
      style: data['style'] as String?,
      hops: data['hops'] as String?,
      aromas: data['aromas'] as String?,
      addedAt: DateTime.parse(doc.$createdAt).toUtc(),
    );
  }

  static Beer fromRealtimePayload(String id, Map<String, dynamic> payload) {
    return Beer(
      id: id,
      sessionId: payload.require<String>('sessionId', id, _collection),
      status: payload.parseEnum(BeerStatus.values, 'status', id, _collection),
      name: payload['name'] as String?,
      brewery: payload['brewery'] as String?,
      style: payload['style'] as String?,
      hops: payload['hops'] as String?,
      aromas: payload['aromas'] as String?,
      addedAt: DateTime.parse(
        payload.require<String>(r'$createdAt', id, _collection),
      ).toUtc(),
    );
  }

  /// Builds the map written to Appwrite on create or update.
  ///
  /// `addedAt` is intentionally omitted — Appwrite's server-managed
  /// `$createdAt` is used instead.
  static Map<String, dynamic> toMap({
    required String sessionId,
    required BeerStatus status,
    required String name,
    required String brewery,
    String? style,
    String? hops,
    String? aromas,
  }) {
    return {
      'sessionId': sessionId,
      'status': status.name,
      'name': name,
      'brewery': brewery,
      'style': ?style,
      'hops': ?hops,
      'aromas': ?aromas,
    };
  }

  static Map<String, dynamic> toUpdateMap({
    required String name,
    required String brewery,
    String? style,
    String? hops,
    String? aromas,
  }) {
    return {
      'name': name,
      'brewery': brewery,
      'style': style,
      'hops': hops,
      'aromas': aromas,
    };
  }
}
