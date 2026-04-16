import 'dart:math';

import 'package:brewtaste/core/errors/error_reporter.dart';
import 'package:brewtaste/features/session/domain/errors/session_errors.dart';
import 'package:brewtaste/features/session/domain/repositories/session_repository.dart';
import 'package:brewtaste/features/session/infra/session_repository_provider.dart';
import 'package:brewtaste/shared/domain/entities/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_session_use_case.g.dart';

final class CreateSessionUseCase {
  const CreateSessionUseCase(this._repository);

  final SessionRepository _repository;

  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final _random = Random();
  static const _maxAttempts = 5;

  Future<Session> call({
    required String hostId,
    required bool isBlind,
    required List<GuessField> guessFields,
  }) async {
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final code = _generateCode();
      try {
        final existing = await _repository.getSessionByCode(code);
        if (existing == null) {
          return _repository.createSession(
            hostId: hostId,
            isBlind: isBlind,
            guessFields: guessFields,
            code: code,
          );
        }
        // existing != null → code is taken, try next
      } on SessionRevealedException {
        continue; // code exists but session is revealed — still taken, retry
      } on SessionExpiredException {
        continue; // code exists but session expired — still taken, retry
      }
    }

    const error = SessionCodeCollisionException();
    ErrorReporter.report(error, StackTrace.current);
    throw error;
  }

  static String _generateCode() {
    final suffix = List.generate(
      4,
      (_) => _chars[_random.nextInt(_chars.length)],
    ).join();
    return 'BREW-$suffix';
  }
}

@riverpod
CreateSessionUseCase createSessionUseCase(Ref ref) =>
    CreateSessionUseCase(ref.watch(sessionRepositoryProvider));
