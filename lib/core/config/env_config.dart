/// Compile-time environment values.
///
/// Loaded via `--dart-define` or `--dart-define-from-file=dart_defines.json`.
/// Keep real keys in [dart_defines.json] (gitignored); use
/// [dart_defines.example.json] as a template.
class EnvConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get supabaseEnabled =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Public browser/mobile Maps key (optional).
  static const mapsApiKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get mapsConfigured => mapsApiKey.isNotEmpty;

  /// Admin account email (compile-time via dart_defines / --dart-define).
  /// Password is never stored here — only Supabase Auth validates credentials.
  static const adminEmail = String.fromEnvironment(
    'ADMIN_EMAIL',
    defaultValue: 'ravichalmar@gmail.com',
  );

  static bool get adminEmailConfigured => adminEmail.trim().isNotEmpty;
}
