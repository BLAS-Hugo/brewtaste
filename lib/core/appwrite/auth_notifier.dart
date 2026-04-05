import 'package:appwrite/appwrite.dart';
import 'package:brewtaste/core/appwrite/appwrite_client.dart';
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
    } on AppwriteException {
      final session = await account.createAnonymousSession();
      return session.userId;
    }
  }
}
