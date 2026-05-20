import 'package:shared_preferences/shared_preferences.dart';

/// Persists only the authenticated session (not the user database).
class SessionManager {
  SessionManager(this._prefs);

  final SharedPreferences _prefs;

  static const sessionUidKey = 'village_auth_session_uid';
  static const sessionTokenKey = 'village_auth_session_token';
  static const loginStateKey = 'village_auth_logged_in';

  /// Legacy local user list key — migrated once to Supabase then removed.
  static const legacyUsersKey = 'village_users_v1';
  static const legacyMigrationDoneKey = 'village_users_migrated_to_supabase_v1';

  String? get sessionUid => _prefs.getString(sessionUidKey);

  String? get sessionToken => _prefs.getString(sessionTokenKey);

  bool get isLoggedIn => _prefs.getBool(loginStateKey) ?? false;

  Future<void> saveSession({
    required String uid,
    String? token,
  }) async {
    await _prefs.setString(sessionUidKey, uid);
    await _prefs.setBool(loginStateKey, true);
    if (token != null && token.isNotEmpty) {
      await _prefs.setString(sessionTokenKey, token);
    }
  }

  Future<void> clearSession() async {
    await _prefs.remove(sessionUidKey);
    await _prefs.remove(sessionTokenKey);
    await _prefs.setBool(loginStateKey, false);
  }

  bool get legacyMigrationDone =>
      _prefs.getBool(legacyMigrationDoneKey) ?? false;

  Future<void> markLegacyMigrationDone() async {
    await _prefs.setBool(legacyMigrationDoneKey, true);
    await _prefs.remove(legacyUsersKey);
  }

  String? get legacyUsersJson => _prefs.getString(legacyUsersKey);

  Future<void> saveLocalUsersJson(String json) async {
    await _prefs.setString(legacyUsersKey, json);
  }
}
