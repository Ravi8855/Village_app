import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/role_manager.dart';

/// Generates, stores, and validates short-lived email OTP codes.
class OtpService {
  OtpService(this._prefs);

  final SharedPreferences _prefs;
  static const otpLength = 6;
  static const expiryMinutes = 5;
  static const resendCooldownSeconds = 60;

  String _storageKey(String email) =>
      'email_otp_${RoleManager.normalizeEmail(email)}';

  String generateOtp() {
    final random = Random.secure();
    final code = random.nextInt(1000000);
    return code.toString().padLeft(otpLength, '0');
  }

  Future<void> saveOtp({
    required String email,
    required String otp,
  }) async {
    final expiresAt =
        DateTime.now().toUtc().add(const Duration(minutes: expiryMinutes));
    final payload = jsonEncode({
      'otp': otp,
      'expiresAt': expiresAt.toIso8601String(),
      'sentAt': DateTime.now().toUtc().toIso8601String(),
    });
    await _prefs.setString(_storageKey(email), payload);
  }

  Future<int> secondsUntilResendAllowed(String email) async {
    final raw = _prefs.getString(_storageKey(email));
    if (raw == null) return 0;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final sentAt = DateTime.tryParse(map['sentAt'] as String? ?? '');
    if (sentAt == null) return 0;
    final elapsed = DateTime.now().toUtc().difference(sentAt).inSeconds;
    final remaining = resendCooldownSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  Future<bool> verifyOtp({
    required String email,
    required String input,
  }) async {
    final raw = _prefs.getString(_storageKey(email));
    if (raw == null) return false;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    final storedOtp = map['otp'] as String?;
    final expiresAt = DateTime.tryParse(map['expiresAt'] as String? ?? '');
    if (storedOtp == null || expiresAt == null) return false;
    if (DateTime.now().toUtc().isAfter(expiresAt)) return false;
    return storedOtp.trim() == input.trim();
  }

  Future<void> clearOtp(String email) async {
    await _prefs.remove(_storageKey(email));
  }
}
