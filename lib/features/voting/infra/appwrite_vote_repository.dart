import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:brewtaste/core/appwrite/appwrite_constants.dart';
import 'package:brewtaste/core/errors/error_reporter.dart';
import 'package:brewtaste/features/voting/data/dtos/vote_dto.dart';
import 'package:brewtaste/features/voting/domain/repositories/vote_repository.dart';
import 'package:brewtaste/shared/domain/entities/vote.dart';

// Appwrite 23 deprecated the Documents API in favour of TablesDB. Our backend
// uses Collections, so we keep using the Documents API until a full migration.
// ignore_for_file: deprecated_member_use

final class AppwriteVoteRepository implements VoteRepository {
  AppwriteVoteRepository({
    required Databases databases,
    required Realtime realtime,
  })  : _databases = databases,
        _realtime = realtime;

  final Databases _databases;
  final Realtime _realtime;

  static const String _db = AppwriteConstants.databaseId;
  static const String _votes = AppwriteConstants.votesCollection;
  static const int _pageLimit = 100;

  @override
  Future<Vote> submitVote({
    required String sessionId,
    required String beerId,
    required String userId,
    required Map<String, String> guesses,
    required bool hasSkipped,
    int? score,
  }) async {
    final doc = await _databases.createDocument(
      databaseId: _db,
      collectionId: _votes,
      documentId: ID.unique(),
      data: VoteDto.toMap(
        sessionId: sessionId,
        beerId: beerId,
        userId: userId,
        guesses: guesses,
        hasSkipped: hasSkipped,
        score: score,
      ),
    );
    return _parseDoc(doc, VoteDto.fromDocument);
  }

  @override
  Stream<List<Vote>> watchVotesForSession(String sessionId) {
    const channel = 'databases.$_db.collections.$_votes.documents';
    final controller = StreamController<List<Vote>>();

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
                name.contains('documents.*.delete'),
          );
          if (!isRelevant) return;

          fetchChain = fetchChain.then(
            (_) => _getVotesForSession(sessionId).then(
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
      _getVotesForSession(sessionId).then(
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

  Future<List<Vote>> _getVotesForSession(String sessionId) async {
    final result = await _databases.listDocuments(
      databaseId: _db,
      collectionId: _votes,
      queries: [
        Query.equal('sessionId', sessionId),
        Query.limit(_pageLimit),
      ],
    );
    return result.documents
        .map((doc) => _parseDoc(doc, VoteDto.fromDocument))
        .toList();
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
