import 'package:brewtaste/features/session/domain/use_cases/create_session_use_case.dart';
import 'package:brewtaste/features/session/infra/session_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_session_use_case_provider.g.dart';

@Riverpod(keepAlive: true)
CreateSessionUseCase createSessionUseCase(Ref ref) =>
    CreateSessionUseCase(ref.watch(sessionRepositoryProvider));
