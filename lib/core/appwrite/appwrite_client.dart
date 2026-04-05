import 'package:appwrite/appwrite.dart';
import 'package:brewtaste/core/appwrite/appwrite_constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'appwrite_client.g.dart';

@Riverpod(keepAlive: true)
Client appwriteClient(Ref ref) {
  return Client()
    ..setEndpoint(AppwriteConstants.endpoint)
    ..setProject(AppwriteConstants.projectId);
}

@Riverpod(keepAlive: true)
Account appwriteAccount(Ref ref) {
  return Account(ref.watch(appwriteClientProvider));
}

@Riverpod(keepAlive: true)
Databases appwriteDatabases(Ref ref) {
  return Databases(ref.watch(appwriteClientProvider));
}

@Riverpod(keepAlive: true)
Realtime appwriteRealtime(Ref ref) {
  return Realtime(ref.watch(appwriteClientProvider));
}
