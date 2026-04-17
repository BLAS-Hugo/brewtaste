import 'package:brewtaste/core/appwrite/auth_notifier.dart';
import 'package:brewtaste/features/session/presentation/providers/create_session_use_case_provider.dart';
import 'package:brewtaste/shared/domain/entities/session.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_session_notifier.g.dart';

@riverpod
class CreateSessionNotifier extends _$CreateSessionNotifier {
  @override
  Future<Session?> build() async => null;

  Future<void> submit({
    required String pseudo,
    required bool isBlind,
    required List<GuessField> guessFields,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final userId = await ref.read(authProvider.future);
      return ref.read(createSessionUseCaseProvider).call(
        hostId: userId,
        pseudo: pseudo,
        isBlind: isBlind,
        guessFields: guessFields,
      );
    });
  }
}
