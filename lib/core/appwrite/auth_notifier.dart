import 'package:appwrite/appwrite.dart';
import 'package:brewtaste/core/appwrite/appwrite_client.dart';
import 'package:brewtaste/core/errors/error_reporter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_notifier.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<String> build() async {
    final account = ref.watch(appwriteAccountProvider);
    try {
      final session = await account.getSession(sessionId: 'current');
      return session.userId;
    } on AppwriteException catch (e, stack) {
      // 401 = no active session — expected on first launch
      if (e.code == 401) {
        final session = await account.createAnonymousSession();
        return session.userId;
      }
      // Any other Appwrite error (network, permissions, etc.) is unexpected
      ErrorReporter.report(e, stack);
      rethrow;
    }
  }
}
