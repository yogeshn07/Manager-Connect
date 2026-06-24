/// Firebase configuration loaded from dart-define environment variables.
/// Provided at build time: --dart-define=FIREBASE_API_KEY=...
/// When all values are empty, Firebase is skipped gracefully.
abstract final class FirebaseConfig {
  static const String apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const String messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String appId = String.fromEnvironment('FIREBASE_APP_ID');

  static bool get isConfigured => apiKey.isNotEmpty && projectId.isNotEmpty;
}
