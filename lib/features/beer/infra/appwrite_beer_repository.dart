import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:brewtaste/core/appwrite/appwrite_constants.dart';
import 'package:brewtaste/core/errors/error_reporter.dart';
import 'package:brewtaste/features/beer/data/dtos/beer_dto.dart';
import 'package:brewtaste/features/beer/domain/repositories/beer_repository.dart';
import 'package:brewtaste/shared/domain/entities/beer.dart';

// Appwrite 23 deprecated the Documents API in favour of TablesDB (a new
// structured-data feature). Our backend uses Collections, so we keep using
// the Documents API until a full backend migration is warranted.
// ignore_for_file: deprecated_member_use

final class AppwriteBeerRepository implements BeerRepository {
  AppwriteBeerRepository({
    required Databases databases,
    required Realtime realtime,
  })  : _databases = databases,
        _realtime = realtime;

  final Databases _databases;
  final Realtime _realtime;

  static const String _db = AppwriteConstants.databaseId;
  static const String _beers = AppwriteConstants.beersCollection;
  static const int _pageLimit = 100;

  @override
  Future<Beer> addBeer({
    required String sessionId,
    required String name,
    required String brewery,
    String? style,
    String? hops,
    String? aromas,
  }) async {
    final doc = await _databases.createDocument(
      databaseId: _db,
      collectionId: _beers,
      documentId: ID.unique(),
      data: BeerDto.toMap(
        sessionId: sessionId,
        status: BeerStatus.pending,
        name: name,
        brewery: brewery,
        style: style,
        hops: hops,
        aromas: aromas,
      ),
    );
    return _parseDoc(doc, BeerDto.fromDocument);
  }

  @override
  Future<Beer> editBeer({
    required String beerId,
    required String name,
    required String brewery,
    String? style,
    String? hops,
    String? aromas,
  }) async {
    final doc = await _databases.updateDocument(
      databaseId: _db,
      collectionId: _beers,
      documentId: beerId,
      data: BeerDto.toUpdateMap(
        name: name,
        brewery: brewery,
        style: style,
        hops: hops,
        aromas: aromas,
      ),
    );
    return _parseDoc(doc, BeerDto.fromDocument);
  }

  @override
  Future<void> startVoting(String beerId) async {
    await _databases.updateDocument(
      databaseId: _db,
      collectionId: _beers,
      documentId: beerId,
      data: {'status': BeerStatus.voting.name},
    );
  }

  @override
  Future<List<Beer>> getBeers(String sessionId) async {
    final result = await _databases.listDocuments(
      databaseId: _db,
      collectionId: _beers,
      queries: [
        Query.equal('sessionId', sessionId),
        Query.orderAsc(r'$createdAt'),
        Query.limit(_pageLimit),
      ],
    );
    return result.documents
        .map((doc) => _parseDoc(doc, BeerDto.fromDocument))
        .toList();
  }

  @override
  Stream<List<Beer>> watchBeers(String sessionId) {
    const channel = 'databases.$_db.collections.$_beers.documents';
    final controller = StreamController<List<Beer>>();

    RealtimeSubscription? currentSubscription;
    var canceledByConsumer = false;

    var fetchChain = Future<void>.value();

    controller.onCancel = () {
      canceledByConsumer = true;
      _closeSubscription(currentSubscription);
    };

    void attach() {
      if (canceledByConsumer || controller.isClosed) return;

      currentSubscription = _realtime.subscribe([channel]);

      currentSubscription!.stream.listen(
        (event) {
          if (event.payload['sessionId'] != sessionId) return;

          final isRelevant = event.events.any(
            (name) =>
                name.contains('documents.*.create') ||
                name.contains('documents.*.update') ||
                name.contains('documents.*.delete'),
          );
          if (!isRelevant) return;

          fetchChain = fetchChain.then(
            (_) => getBeers(sessionId).then(
              (list) {
                if (!controller.isClosed) controller.add(list);
              },
              onError: (Object error, StackTrace stackTrace) {
                if (!controller.isClosed) {
                  controller.addError(error, stackTrace);
                }
              },
            ),
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          _closeSubscription(currentSubscription);
          attach();
          if (!controller.isClosed) controller.addError(error, stackTrace);
        },
        onDone: () {
          _closeSubscription(currentSubscription);
          attach();
        },
      );
    }

    unawaited(
      getBeers(sessionId).then(
        (initial) {
          if (!controller.isClosed) controller.add(initial);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!controller.isClosed) controller.addError(error, stackTrace);
        },
      ),
    );

    attach();

    return controller.stream;
  }

  T _parseDoc<T>(Document doc, T Function(Document) parse) {
    try {
      return parse(doc);
    } catch (error, stackTrace) {
      ErrorReporter.report(error, stackTrace);
      rethrow;
    }
  }

  void _closeSubscription(RealtimeSubscription? subscription) {
    if (subscription == null) return;
    unawaited(subscription.close());
  }
}
