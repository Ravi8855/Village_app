import 'package:shared_preferences/shared_preferences.dart';

class AppUpdatePreferencesStore {
  static const _dismissedVersionCodeKey = 'app_update_dismissed_version_code';
  static const _lastPromptVersionCodeKey = 'app_update_last_prompt_version_code';
  static const _lastPromptAtMsKey = 'app_update_last_prompt_at_ms';

  /// Minimum gap between prompts for the same store version.
  static const promptCooldown = Duration(hours: 24);

  Future<int> getDismissedVersionCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dismissedVersionCodeKey) ?? 0;
  }

  Future<void> setDismissedVersionCode(int versionCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dismissedVersionCodeKey, versionCode);
  }

  Future<int> getLastPromptVersionCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastPromptVersionCodeKey) ?? 0;
  }

  Future<DateTime?> getLastPromptAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastPromptAtMsKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> recordPrompt(int versionCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPromptVersionCodeKey, versionCode);
    await prefs.setInt(_lastPromptAtMsKey, DateTime.now().millisecondsSinceEpoch);
  }
}
