abstract final class AppwriteConstants {
  static const endpoint = String.fromEnvironment('APPWRITE_ENDPOINT');
  static const projectId = String.fromEnvironment('APPWRITE_PROJECT_ID');
  static const databaseId = String.fromEnvironment('APPWRITE_DATABASE_ID');

  // Appwrite collection IDs — must match the IDs in the Appwrite console
  static const sessionsCollection = 'session';
  static const participantsCollection = 'participants';
  static const beersCollection = 'beers';
  static const votesCollection = 'votes';

  /// Asserts that all required dart-define env vars are present.
  /// Call once in main() in debug mode.
  static void assertEnvironment() {
    assert(endpoint.isNotEmpty, 'APPWRITE_ENDPOINT is not set');
    assert(projectId.isNotEmpty, 'APPWRITE_PROJECT_ID is not set');
    assert(databaseId.isNotEmpty, 'APPWRITE_DATABASE_ID is not set');
  }
}
