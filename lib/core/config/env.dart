/// Build-time configuration, compiled into the app.
///
/// Values come from the `.env` file passed to Flutter at build time:
///
///   flutter run --dart-define-from-file=.env
///   flutter build appbundle --dart-define-from-file=.env
///   flutter build ipa --dart-define-from-file=.env
///
/// The `.env` file itself is NOT bundled into the app (it is not listed under
/// `assets:` in pubspec.yaml). A missing key compiles to an empty string;
/// [missingKeys] lists them so startup can report a build run without the flag.
abstract final class Env {
  /// Content project (questions, subjects, customizations).
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_KEY');

  /// Main project (auth, profiles, Skulk, study rooms).
  static const supabase2Url = String.fromEnvironment('SUPABASE_2_URL');
  static const supabase2AnonKey = String.fromEnvironment('SUPABASE_2_KEY');

  static const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  /// Only used by the old in-app AI solver, which nothing opens any more.
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const driveApiKey = String.fromEnvironment('DRIVE_API_KEY');

  /// [googleWebClientId], or null when it wasn't provided (GoogleSignIn
  /// treats null as "not set", but rejects an empty string).
  static String? get googleWebClientIdOrNull =>
      googleWebClientId.isEmpty ? null : googleWebClientId;

  /// Keys the app needs that were not provided at build time.
  static List<String> get missingKeys => [
    if (supabaseUrl.isEmpty) 'SUPABASE_URL',
    if (supabaseAnonKey.isEmpty) 'SUPABASE_KEY',
    if (supabase2Url.isEmpty) 'SUPABASE_2_URL',
    if (supabase2AnonKey.isEmpty) 'SUPABASE_2_KEY',
    if (googleWebClientId.isEmpty) 'GOOGLE_WEB_CLIENT_ID',
    if (driveApiKey.isEmpty) 'DRIVE_API_KEY',
  ];
}
