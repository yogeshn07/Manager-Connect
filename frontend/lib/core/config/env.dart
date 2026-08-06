/// Supabase configuration supplied at build time.
///
/// Values come from `--dart-define` (CI) or `--dart-define-from-file=env.json`
/// (local development). No credentials are hardcoded here — see
/// `frontend/env.example.json` and the "Running locally" section of README.md.
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
