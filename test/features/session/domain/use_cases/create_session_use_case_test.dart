import 'package:brewtaste/features/session/domain/errors/session_errors.dart';
import 'package:brewtaste/features/session/domain/repositories/session_repository.dart';
import 'package:brewtaste/features/session/domain/use_cases/create_session_use_case.dart';
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
    this.sessionToReturn,
  });

  /// Called with (code, zeroBasedCallIndex). Return null for "code is free",
  /// return a Session for "code is taken", or throw to simulate errors.
  final Future<Session?> Function(String code, int callIndex)
      onGetSessionByCode;
  final Session? sessionToReturn;

  int getSessionByCodeCallCount = 0;
  int createSessionCallCount = 0;

  /// The code most recently passed to [createSession], captured for assertions.
  String? lastCreatedCode;

  @override
  Future<Session?> getSessionByCode(String code) {
    final index = getSessionByCodeCallCount++;
    return onGetSessionByCode(code, index);
  }

  @override
  Future<Session> createSession({
    required String hostId,
    required bool isBlind,
    required List<GuessField> guessFields,
    required String code,
  }) async {
    createSessionCallCount++;
    lastCreatedCode = code;
    return sessionToReturn ??
        (throw StateError(
          '_FakeSessionRepository.createSession called but '
          'sessionToReturn is null',
        ));
  }

  // Remaining interface methods are not exercised by these tests.
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
  Future<Participant> createParticipant({
    required String sessionId,
    required String userId,
    required String pseudo,
    required bool isHost,
  }) =>
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

Session _fakeSession({String code = 'BREW-TEST'}) => Session(
      id: 'session-1',
      hostId: 'host-1',
      status: SessionStatus.waiting,
      code: code,
      isBlind: false,
      guessFields: const [],
      createdAt: DateTime.now().toUtc(),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CreateSessionUseCase', () {
    const hostId = 'host-1';
    const isBlind = false;
    const guessFields = <GuessField>[];

    test('happy path — unique code on first attempt', () async {
      final created = _fakeSession();
      final repo = _FakeSessionRepository(
        onGetSessionByCode: (_, i) async => null,
        sessionToReturn: created,
      );
      final useCase = CreateSessionUseCase(repo);

      final result = await useCase(
        hostId: hostId,
        isBlind: isBlind,
        guessFields: guessFields,
      );

      expect(result, created);
      expect(repo.getSessionByCodeCallCount, 1);
      expect(repo.createSessionCallCount, 1);
    });

    test('createSession receives the same code that passed uniqueness check',
        () async {
      String? checkedCode;
      final created = _fakeSession();
      final repo = _FakeSessionRepository(
        onGetSessionByCode: (code, i) async {
          checkedCode = code;
          return null;
        },
        sessionToReturn: created,
      );

      await CreateSessionUseCase(repo)(
        hostId: hostId,
        isBlind: isBlind,
        guessFields: guessFields,
      );

      expect(repo.lastCreatedCode, isNotNull);
      expect(repo.lastCreatedCode, checkedCode);
    });

    test('generated code matches BREW-XXXX format', () async {
      String? capturedCode;
      final repo = _FakeSessionRepository(
        onGetSessionByCode: (code, i) async {
          capturedCode = code;
          return null;
        },
        sessionToReturn: _fakeSession(),
      );

      await CreateSessionUseCase(repo)(
        hostId: hostId,
        isBlind: isBlind,
        guessFields: guessFields,
      );

      expect(capturedCode, matches(RegExp(r'^BREW-[A-Z0-9]{4}$')));
    });

    test('one collision then success', () async {
      final taken = _fakeSession(code: 'BREW-AAAA');
      final created = _fakeSession(code: 'BREW-BBBB');
      final repo = _FakeSessionRepository(
        onGetSessionByCode: (_, index) async => index == 0 ? taken : null,
        sessionToReturn: created,
      );
      final useCase = CreateSessionUseCase(repo);

      final result = await useCase(
        hostId: hostId,
        isBlind: isBlind,
        guessFields: guessFields,
      );

      expect(result, created);
      expect(repo.getSessionByCodeCallCount, 2);
      expect(repo.createSessionCallCount, 1);
    });

    test('four collisions then success (boundary)', () async {
      final taken = _fakeSession();
      final created = _fakeSession(code: 'BREW-ZZZZ');
      final repo = _FakeSessionRepository(
        onGetSessionByCode: (_, index) async => index < 4 ? taken : null,
        sessionToReturn: created,
      );
      final useCase = CreateSessionUseCase(repo);

      final result = await useCase(
        hostId: hostId,
        isBlind: isBlind,
        guessFields: guessFields,
      );

      expect(result, created);
      expect(repo.getSessionByCodeCallCount, 5);
      expect(repo.createSessionCallCount, 1);
    });

    test(
      'all 5 attempts collide — throws SessionCodeCollisionException',
      () async {
        final taken = _fakeSession();
        final repo = _FakeSessionRepository(
          onGetSessionByCode: (_, i) async => taken,
        );
        final useCase = CreateSessionUseCase(repo);

        await expectLater(
          () => useCase(
            hostId: hostId,
            isBlind: isBlind,
            guessFields: guessFields,
          ),
          throwsA(isA<SessionCodeCollisionException>()),
        );

        expect(repo.getSessionByCodeCallCount, 5);
        expect(repo.createSessionCallCount, 0);
      },
    );

    test(
      'SessionRevealedException counts as collision — retries and succeeds',
      () async {
        final created = _fakeSession();
        final repo = _FakeSessionRepository(
          onGetSessionByCode: (code, index) async {
            if (index == 0) throw const SessionRevealedException('session-old');
            return null;
          },
          sessionToReturn: created,
        );
        final useCase = CreateSessionUseCase(repo);

        final result = await useCase(
          hostId: hostId,
          isBlind: isBlind,
          guessFields: guessFields,
        );

        expect(result, created);
        expect(repo.getSessionByCodeCallCount, 2);
        expect(repo.createSessionCallCount, 1);
      },
    );

    test(
      'SessionExpiredException counts as collision — retries and succeeds',
      () async {
        final created = _fakeSession();
        final repo = _FakeSessionRepository(
          onGetSessionByCode: (code, index) async {
            if (index == 0) throw const SessionExpiredException('session-old');
            return null;
          },
          sessionToReturn: created,
        );
        final useCase = CreateSessionUseCase(repo);

        final result = await useCase(
          hostId: hostId,
          isBlind: isBlind,
          guessFields: guessFields,
        );

        expect(result, created);
        expect(repo.getSessionByCodeCallCount, 2);
        expect(repo.createSessionCallCount, 1);
      },
    );

    test(
      'unexpected exception propagates and does not swallow remaining attempts',
      () async {
        final repo = _FakeSessionRepository(
          onGetSessionByCode: (_, i) async =>
              throw Exception('network error'),
        );
        final useCase = CreateSessionUseCase(repo);

        await expectLater(
          () => useCase(
            hostId: hostId,
            isBlind: isBlind,
            guessFields: guessFields,
          ),
          throwsA(isA<Exception>()),
        );

        // Only 1 attempt — unexpected errors are not retried.
        expect(repo.getSessionByCodeCallCount, 1);
        expect(repo.createSessionCallCount, 0);
      },
    );
  });
}
