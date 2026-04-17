import 'package:brewtaste/core/appwrite/auth_notifier.dart';
import 'package:brewtaste/features/session/presentation/providers/join_session_use_case_provider.dart';
import 'package:brewtaste/shared/domain/entities/participant.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'join_session_notifier.g.dart';

@riverpod
class JoinSessionNotifier extends _$JoinSessionNotifier {
  @override
  Future<Participant?> build() async => null;

  Future<void> submit({
    required String code,
    required String pseudo,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final userId = await ref.read(authProvider.future);
      return ref.read(joinSessionUseCaseProvider).call(
        code: code,
        userId: userId,
        pseudo: pseudo,
      );
    });
  }
}
