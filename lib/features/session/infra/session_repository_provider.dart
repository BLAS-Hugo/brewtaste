import 'package:brewtaste/core/appwrite/appwrite_client.dart';
import 'package:brewtaste/features/session/domain/repositories/session_repository.dart';
import 'package:brewtaste/features/session/infra/appwrite_session_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_repository_provider.g.dart';

@Riverpod(keepAlive: true)
SessionRepository sessionRepository(Ref ref) {
  return AppwriteSessionRepository(
    databases: ref.watch(appwriteDatabasesProvider),
    realtime: ref.watch(appwriteRealtimeProvider),
  );
}
