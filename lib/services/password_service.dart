import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Password hashing for admin accounts (stored in Supabase).
class PasswordService {
  PasswordService._();

  static const _salt = 'naganoor_village_auth_v1';

  static String hashPassword(String password) {
    final normalized = password.trim();
    final bytes = utf8.encode('$_salt::$normalized');
    return sha256.convert(bytes).toString();
  }

  static bool verifyPassword(String password, String? storedHash) {
    if (storedHash == null || storedHash.isEmpty) return false;
    return hashPassword(password) == storedHash;
  }
}
