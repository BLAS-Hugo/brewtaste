abstract final class AppwriteConstants {
  static const endpoint = String.fromEnvironment('APPWRITE_ENDPOINT');
  static const projectId = String.fromEnvironment('APPWRITE_PROJECT_ID');
  static const databaseId = String.fromEnvironment('APPWRITE_DATABASE_ID');

  static const sessionsCollection = 'sessions';
  static const participantsCollection = 'participants';
  static const beersCollection = 'beers';
  static const votesCollection = 'votes';
}
