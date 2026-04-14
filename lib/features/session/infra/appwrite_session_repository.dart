import 'dart:async';

import 'package:appwrite/appwrite.dart';
// `Session` is hidden because appwrite/models.dart also exports a `Session`
// class, which would conflict with the domain entity of the same name.
import 'package:appwrite/models.dart' hide Session;
import 'package:brewtaste/core/appwrite/appwrite_constants.dart';
import 'package:brewtaste/core/errors/error_reporter.dart';
import 'package:brewtaste/features/session/data/dtos/participant_dto.dart';
import 'package:brewtaste/features/session/data/dtos/session_dto.dart';
import 'package:brewtaste/features/session/domain/errors/session_errors.dart';
import 'package:brewtaste/features/session/domain/repositories/session_repository.dart';
import 'package:brewtaste/shared/domain/entities/participant.dart';
import 'package:brewtaste/shared/domain/entities/session.dart';

// Appwrite 23 deprecated the Documents API in favour of TablesDB (a new
// structured-data feature). Our backend uses Collections, so we keep using
// the Documents API until a full backend migration is warranted.
// ignore_for_file: deprecated_member_use

final class AppwriteSessionRepository implements SessionRepository {
  AppwriteSessionRepository({
    required Databases databases,
    required Realtime realtime,
  })  : _databases = databases,
        _realtime = realtime;

  final Databases _databases;
  final Realtime _realtime;

  static const String _db = AppwriteConstants.databaseId;
  static const String _sessions = AppwriteConstants.sessionsCollection;
  static const String _participants = AppwriteConstants.participantsCollection;
  static const String _votes = AppwriteConstants.votesCollection;

  // Maximum documents returned per query. Appwrite's hard limit is 100.
  static const int _pageLimit = 100;

  @override
  Future<Session> createSession({
    required String hostId,
    required bool isBlind,
    required List<GuessField> guessFields,
    required String code,
  }) async {
    final doc = await _databases.createDocument(
      databaseId: _db,
      collectionId: _sessions,
      documentId: ID.unique(),
      data: SessionDto.toMap(
        hostId: hostId,
        status: SessionStatus.waiting,
        code: code,
        isBlind: isBlind,
        guessFields: guessFields,
      ),
    );
    return _parseDoc(doc, SessionDto.fromDocument);
  }

  @override
  Future<Session?> getSessionByCode(String code) async {
    final result = await _databases.listDocuments(
      databaseId: _db,
      collectionId: _sessions,
      queries: [
        Query.equal('code', code),
        Query.limit(1),
      ],
    );
    if (result.documents.isEmpty) return null;

    final session = _parseDoc(result.documents.first, SessionDto.fromDocument);

    if (session.status == SessionStatus.revealed) {
      throw SessionRevealedException(session.id);
    }

    final age = DateTime.now().toUtc().difference(session.createdAt);
    if (age > const Duration(hours: 24)) {
      throw SessionExpiredException(session.id);
    }

    return session;
  }

  @override
  Future<Session?> getSessionById(String sessionId) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: _db,
        collectionId: _sessions,
        documentId: sessionId,
      );
      return _parseDoc(doc, SessionDto.fromDocument);
    } on AppwriteException catch (appwriteError) {
      if (appwriteError.code == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<Participant>> getParticipants(String sessionId) async {
    final result = await _databases.listDocuments(
      databaseId: _db,
      collectionId: _participants,
      queries: [
        Query.equal('sessionId', sessionId),
        Query.limit(_pageLimit),
      ],
    );
    return result.documents
        .map((doc) => _parseDoc(doc, ParticipantDto.fromDocument))
        .toList();
  }

  @override
  Stream<List<Participant>> watchParticipants(String sessionId) {
    const channel =
        'databases.$_db.collections.$_participants.documents';
    final controller = StreamController<List<Participant>>();

    RealtimeSubscription? currentSubscription;
    var canceledByConsumer = false;

    // Declared outside attach() so the chain survives reconnects — events
    // issued during a reconnect window are still emitted in order.
    var fetchChain = Future<void>.value();

    // Wire onCancel before attach() so no subscription can leak if attach()
    // somehow completes synchronously before the assignment below.
    controller.onCancel = () {
      canceledByConsumer = true;
      _closeSubscription(currentSubscription);
    };

    void attach() {
      if (canceledByConsumer || controller.isClosed) return;

      currentSubscription = _realtime.subscribe([channel]);

      currentSubscription!.stream.listen(
        (event) {
          final payload = event.payload;
          // Filter to this session only — Appwrite Realtime has no
          // server-side query filter on collection-level subscriptions.
          if (payload['sessionId'] != sessionId) return;

          final isRelevant = event.events.any(
            (eventName) =>
                eventName.contains('documents.*.create') ||
                eventName.contains('documents.*.delete'),
          );
          if (!isRelevant) return;

          fetchChain = fetchChain.then(
            (_) => getParticipants(sessionId).then(
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
          // Reconnect before notifying the consumer — a synchronous consumer
          // (e.g. Riverpod autoDispose) may call onCancel during addError,
          // setting canceledByConsumer = true. Scheduling attach() first
          // ensures it runs before the flag is potentially set.
          _closeSubscription(currentSubscription);
          attach();
          if (!controller.isClosed) controller.addError(error, stackTrace);
        },
        onDone: () {
          // Server closed the connection — reconnect unless the consumer
          // deliberately canceled.
          _closeSubscription(currentSubscription);
          attach();
        },
      );
    }

    // Emit the current participant list immediately so consumers don't have
    // to make a separate getParticipants() call on first subscribe.
    unawaited(
      getParticipants(sessionId).then(
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

  @override
  Stream<Session> watchSession(String sessionId) {
    final channel =
        'databases.$_db.collections.$_sessions.documents.$sessionId';
    final controller = StreamController<Session>();

    RealtimeSubscription? currentSubscription;
    var canceledByConsumer = false;

    void attach() {
      if (canceledByConsumer || controller.isClosed) return;

      currentSubscription = _realtime.subscribe([channel]);

      currentSubscription!.stream.listen(
        (event) {
          final isUpdate = event.events
              .any((eventName) => eventName.contains('documents.*.update'));
          final isDelete = event.events
              .any((eventName) => eventName.contains('documents.*.delete'));

          if (isDelete) {
            // Session deleted — close subscription first so its onDone
            // fires while canceledByConsumer is already true, preventing
            // any reconnect attempt.
            canceledByConsumer = true;
            _closeSubscription(currentSubscription);
            unawaited(controller.close());
            return;
          }

          if (!isUpdate) return;

          if (controller.isClosed) return;
          try {
            controller.add(
              SessionDto.fromRealtimePayload(sessionId, event.payload),
            );
          } on Object catch (error, stackTrace) {
            ErrorReporter.report(error, stackTrace);
            if (!controller.isClosed) controller.addError(error, stackTrace);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          // Reconnect before notifying the consumer — same ordering rationale
          // as watchParticipants.
          _closeSubscription(currentSubscription);
          attach();
          if (!controller.isClosed) controller.addError(error, stackTrace);
        },
        onDone: () {
          // Server closed the connection — reconnect unless the consumer
          // deliberately canceled or the session was deleted.
          _closeSubscription(currentSubscription);
          attach();
        },
      );
    }

    // Wire onCancel before attach() so no subscription can leak if attach()
    // somehow completes synchronously before the assignment below.
    controller.onCancel = () {
      canceledByConsumer = true;
      _closeSubscription(currentSubscription);
    };

    attach();

    return controller.stream;
  }

  @override
  Future<Participant> createParticipant({
    required String sessionId,
    required String userId,
    required String pseudo,
    required bool isHost,
  }) async {
    final doc = await _databases.createDocument(
      databaseId: _db,
      collectionId: _participants,
      documentId: ID.unique(),
      data: ParticipantDto.toMap(
        sessionId: sessionId,
        userId: userId,
        pseudo: pseudo,
        isHost: isHost,
      ),
    );
    return _parseDoc(doc, ParticipantDto.fromDocument);
  }

  @override
  Future<void> kickParticipant({
    required String sessionId,
    required String participantId,
    required String kickedUserId,
  }) async {
    // 1. Delete all votes by this user in this session.
    // MVP limit: up to 100 votes per participant. A session with more than
    // 100 beers (extremely unlikely) would leave orphaned votes; revisit
    // with pagination if the product grows to that scale.
    final votes = await _databases.listDocuments(
      databaseId: _db,
      collectionId: _votes,
      queries: [
        Query.equal('sessionId', sessionId),
        Query.equal('userId', kickedUserId),
        Query.limit(_pageLimit),
      ],
    );
    // Collect all non-404 errors so every deletion is attempted before
    // surfacing failures. 404 means the vote was already deleted (race) —
    // safe to ignore; the cascade must still complete.
    final deletionErrors = <(Object, StackTrace)>[];
    await Future.wait(
      votes.documents.map((voteDoc) async {
        try {
          await _databases.deleteDocument(
            databaseId: _db,
            collectionId: _votes,
            documentId: voteDoc.$id,
          );
        } on AppwriteException catch (appwriteError, stackTrace) {
          if (appwriteError.code != 404) {
            deletionErrors.add((appwriteError, stackTrace));
          }
        }
      }),
    );
    if (deletionErrors.isNotEmpty) {
      final (firstError, firstStack) = deletionErrors.first;
      // Return a rejected future so the original Appwrite stack trace is
      // preserved. Error.throwWithStackTrace would also work here but is
      // semantically for Error objects; Future.error is idiomatic for
      // Exception types.
      return Future.error(firstError, firstStack);
    }

    // 2. Delete the participant document.
    await _databases.deleteDocument(
      databaseId: _db,
      collectionId: _participants,
      documentId: participantId,
    );
  }

  @override
  Future<void> startSession(String sessionId) async {
    await _databases.updateDocument(
      databaseId: _db,
      collectionId: _sessions,
      documentId: sessionId,
      data: {'status': SessionStatus.tasting.name},
    );
  }

  @override
  Future<void> revealSession(String sessionId) async {
    await _databases.updateDocument(
      databaseId: _db,
      collectionId: _sessions,
      documentId: sessionId,
      data: {'status': SessionStatus.revealed.name},
    );
  }

  /// Parses [doc] with [parse], reporting any FormatException to Sentry
  /// before rethrowing. Keeps unexpected parse failures observable without
  /// silencing them.
  T _parseDoc<T>(Document doc, T Function(Document) parse) {
    try {
      return parse(doc);
    } on Object catch (error, stackTrace) {
      // Catches FormatException from require<T> / DateTime.parse and any
      // TypeError from raw casts in future DTO changes.
      ErrorReporter.report(error, stackTrace);
      rethrow;
    }
  }

  /// Closes [subscription] without surfacing the returned future.
  void _closeSubscription(RealtimeSubscription? subscription) {
    if (subscription == null) return;
    unawaited(subscription.close());
  }
}
