import 'package:brewtaste/core/errors/error_reporter.dart';
import 'package:brewtaste/features/session/domain/errors/session_errors.dart';
import 'package:brewtaste/features/session/domain/repositories/session_repository.dart';
import 'package:brewtaste/features/session/domain/use_cases/join_session_use_case.dart';
// Required for SessionRepository interface method stubs.
import 'package:brewtaste/shared/domain/entities/participant.dart';
import 'package:brewtaste/shared/domain/entities/session.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

final class _FakeSessionRepository implements SessionRepository {
  _FakeSessionRepository({
    required this.onGetSessionByCode,
    this.onCreateParticipant,
  });

  final Future<Session?> Function(String code) onGetSessionByCode;
  final Future<Participant> Function({
    required String sessionId,
    required String userId,
    required String pseudo,
    required bool isHost,
  })? onCreateParticipant;

  String? lastCodePassedToRepo;

  @override
  Future<Session?> getSessionByCode(String code) {
    lastCodePassedToRepo = code;
    return onGetSessionByCode(code);
  }

  @override
  Future<Participant> createParticipant({
    required String sessionId,
    required String userId,
    required String pseudo,
    required bool isHost,
  }) {
    final handler = onCreateParticipant;
    return handler != null
        ? handler(
            sessionId: sessionId,
            userId: userId,
            pseudo: pseudo,
            isHost: isHost,
          )
        : throw StateError(
            '_FakeSessionRepository.createParticipant called but '
            'onCreateParticipant is null',
          );
  }

  // Remaining interface methods are not exercised by these tests.
  @override
  Future<Session> createSession({
    required String hostId,
    required bool isBlind,
    required List<GuessField> guessFields,
    required String code,
  }) =>
      throw UnimplementedError();
  @override
  Future<Session?> getSessionById(String sessionId) =>
      throw UnimplementedError();
  @override
  Future<List<Participant>> getParticipants(String sessionId) =>
      throw UnimplementedError();
  @override
  Stream<List<Participant>> watchParticipants(String sessionId) =>
      throw UnimplementedError();
  @override
  Stream<Session> watchSession(String sessionId) =>
      throw UnimplementedError();
  @override
  Future<void> kickParticipant({
    required String sessionId,
    required String participantId,
    required String kickedUserId,
  }) =>
      throw UnimplementedError();
  @override
  Future<void> startSession(String sessionId) => throw UnimplementedError();
  @override
  Future<void> revealSession(String sessionId) => throw UnimplementedError();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Session _fakeSession({String id = 'session-1', String code = 'BREW-TEST'}) =>
    Session(
      id: id,
      hostId: 'host-1',
      status: SessionStatus.waiting,
      code: code,
      isBlind: false,
      guessFields: const [],
      createdAt: DateTime.now().toUtc(),
    );

Participant _fakeParticipant() => Participant(
      id: 'participant-1',
      sessionId: 'session-1',
      userId: 'user-1',
      pseudo: 'Hugo',
      isHost: false,
      joinedAt: DateTime.now().toUtc(),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('JoinSessionUseCase', () {
    const userId = 'user-1';
    const pseudo = 'Hugo';

    test('happy path — session found, participant created and returned',
        () async {
      final session = _fakeSession();
      final participant = _fakeParticipant();
      final repo = _FakeSessionRepository(
        onGetSessionByCode: (_) async => session,
        onCreateParticipant: ({
          required sessionId,
          required userId,
          required pseudo,
          required isHost,
        }) async =>
            participant,
      );

      final result = await JoinSessionUseCase(repo)(
        code: 'BREW-TEST',
        userId: userId,
        pseudo: pseudo,
      );

      expect(result, participant);
    });

    test('code is trimmed and uppercased before repository call', () async {
      final session = _fakeSession(code: 'BREW-ABCD');
      final repo = _FakeSessionRepository(
        onGetSessionByCode: (_) async => session,
        onCreateParticipant: ({
          required sessionId,
          required userId,
          required pseudo,
          required isHost,
        }) async =>
            _fakeParticipant(),
      );

      await JoinSessionUseCase(repo)(
        code: '  brew-abcd  ', // mixed case + surrounding spaces
        userId: userId,
        pseudo: pseudo,
      );

      expect(repo.lastCodePassedToRepo, 'BREW-ABCD');
    });

    test('null returned by repository throws SessionNotFoundException',
        () async {
      var createParticipantCalled = false;
      final repo = _FakeSessionRepository(
        onGetSessionByCode: (_) async => null,
        onCreateParticipant: ({
          required sessionId,
          required userId,
          required pseudo,
          required isHost,
        }) async {
          createParticipantCalled = true;
          return _fakeParticipant();
        },
      );

      await expectLater(
        () => JoinSessionUseCase(repo)(
          code: 'BREW-ZZZZ',
          userId: userId,
          pseudo: pseudo,
        ),
        throwsA(
          isA<SessionNotFoundException>().having(
            (e) => e.code,
            'code',
            'BREW-ZZZZ',
          ),
        ),
      );

      expect(createParticipantCalled, false);
    });

    test('SessionRevealedException propagates without Sentry report', () async {
      var sentryReportCount = 0;
      ErrorReporter.onReport = (e, st) => sentryReportCount++;
      addTearDown(() => ErrorReporter.onReport = null);

      final repo = _FakeSessionRepository(
        onGetSessionByCode: (_) async =>
            throw const SessionRevealedException('session-1'),
      );

      await expectLater(
        () => JoinSessionUseCase(repo)(
          code: 'BREW-TEST',
          userId: userId,
          pseudo: pseudo,
        ),
        throwsA(isA<SessionRevealedException>()),
      );

      expect(sentryReportCount, 0);
    });

    test('SessionExpiredException propagates without Sentry report', () async {
      var sentryReportCount = 0;
      ErrorReporter.onReport = (e, st) => sentryReportCount++;
      addTearDown(() => ErrorReporter.onReport = null);

      final repo = _FakeSessionRepository(
        onGetSessionByCode: (_) async =>
            throw const SessionExpiredException('session-1'),
      );

      await expectLater(
        () => JoinSessionUseCase(repo)(
          code: 'BREW-TEST',
          userId: userId,
          pseudo: pseudo,
        ),
        throwsA(isA<SessionExpiredException>()),
      );

      expect(sentryReportCount, 0);
    });

    test('unexpected exception is reported to Sentry and rethrown', () async {
      final unexpected = Exception('network failure');
      Object? reportedError;
      ErrorReporter.onReport = (e, _) => reportedError = e;
      addTearDown(() => ErrorReporter.onReport = null);

      final repo = _FakeSessionRepository(
        onGetSessionByCode: (_) async => throw unexpected,
      );

      await expectLater(
        () => JoinSessionUseCase(repo)(
          code: 'BREW-TEST',
          userId: userId,
          pseudo: pseudo,
        ),
        throwsA(same(unexpected)),
      );

      expect(reportedError, same(unexpected));
    });

    test('pseudo is trimmed before createParticipant call', () async {
      String? capturedPseudo;
      final repo = _FakeSessionRepository(
        onGetSessionByCode: (_) async => _fakeSession(),
        onCreateParticipant: ({
          required sessionId,
          required userId,
          required pseudo,
          required isHost,
        }) async {
          capturedPseudo = pseudo;
          return _fakeParticipant();
        },
      );

      await JoinSessionUseCase(repo)(
        code: 'BREW-TEST',
        userId: userId,
        pseudo: '  Hugo  ',
      );

      expect(capturedPseudo, 'Hugo');
    });

    test('createParticipant is called with isHost: false', () async {
      bool? capturedIsHost;
      final repo = _FakeSessionRepository(
        onGetSessionByCode: (_) async => _fakeSession(),
        onCreateParticipant: ({
          required sessionId,
          required userId,
          required pseudo,
          required isHost,
        }) async {
          capturedIsHost = isHost;
          return _fakeParticipant();
        },
      );

      await JoinSessionUseCase(repo)(
        code: 'BREW-TEST',
        userId: userId,
        pseudo: pseudo,
      );

      expect(capturedIsHost, false);
    });

    test(
      'unexpected exception from createParticipant is reported to Sentry '
      'and rethrown',
      () async {
        final unexpected = Exception('write failure');
        Object? reportedError;
        ErrorReporter.onReport = (e, st) => reportedError = e;
        addTearDown(() => ErrorReporter.onReport = null);

        final repo = _FakeSessionRepository(
          onGetSessionByCode: (_) async => _fakeSession(),
          onCreateParticipant: ({
            required sessionId,
            required userId,
            required pseudo,
            required isHost,
          }) async =>
              throw unexpected,
        );

        await expectLater(
          () => JoinSessionUseCase(repo)(
            code: 'BREW-TEST',
            userId: userId,
            pseudo: pseudo,
          ),
          throwsA(same(unexpected)),
        );

        expect(reportedError, same(unexpected));
      },
    );
  });
}
