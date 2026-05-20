/// Compile-time environment values.
///
/// Loaded via `--dart-define` or `--dart-define-from-file=dart_defines.json`.
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

  static const mapsApiKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get mapsConfigured => mapsApiKey.isNotEmpty;

  /// EmailJS — maps from VITE_* keys when passed via dart_defines.json.
  static const emailJsServiceId = String.fromEnvironment(
    'EMAILJS_SERVICE_ID',
    defaultValue: '',
  );

  static const emailJsTemplateId = String.fromEnvironment(
    'EMAILJS_TEMPLATE_ID',
    defaultValue: '',
  );

  static const emailJsPublicKey = String.fromEnvironment(
    'EMAILJS_PUBLIC_KEY',
    defaultValue: '',
  );

  static bool get emailJsConfigured =>
      emailJsServiceId.isNotEmpty &&
      emailJsTemplateId.isNotEmpty &&
      emailJsPublicKey.isNotEmpty;

  static const superAdminEmail = String.fromEnvironment(
    'SUPER_ADMIN_EMAIL',
    defaultValue: 'ravivtu12345@gmail.com',
  );

  /// Super admin password (admin login only — not OTP).
  static const superAdminPassword = String.fromEnvironment(
    'SUPER_ADMIN_PASSWORD',
    defaultValue: 'Naganoor@Super2025',
  );

  static bool get superAdminPasswordConfigured =>
      superAdminPassword.isNotEmpty;
}
