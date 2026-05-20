import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' show ClientException;
import 'package:uuid/uuid.dart';

import '../core/config/env_config.dart';
import '../core/role_manager.dart';
import '../models/app_auth_type.dart';
import '../models/app_department.dart';
import '../models/app_role.dart';
import '../models/app_user_model.dart';
import '../services/password_service.dart';
import 'local_user_datasource.dart';
import 'session_manager.dart';
import 'user_supabase_datasource.dart';

/// User persistence: Supabase when `village_app_users` exists, else local fallback.
class UserRepository {
  UserRepository({
    required SessionManager session,
    UserSupabaseDataSource? supabase,
  })  : _session = session,
        _supabase = supabase,
        _local = LocalUserDataSource(session);

  final SessionManager _session;
  final UserSupabaseDataSource? _supabase;
  final LocalUserDataSource _local;
  static const _uuid = Uuid();

  bool? _usesSupabase;
  bool _backendInitialized = false;

  bool get usesSupabaseTable => _usesSupabase ?? false;

  bool get isRemoteEnabled =>
      EnvConfig.supabaseEnabled && _supabase != null;

  /// Call once at startup to pick Supabase vs local storage.
  Future<void> initBackend() async {
    if (_backendInitialized) return;
    _backendInitialized = true;

    if (!isRemoteEnabled) {
      _usesSupabase = false;
      if (kDebugMode) {
        debugPrint('[UserRepository] Using local user store (Supabase not configured).');
      }
      return;
    }

    try {
      _usesSupabase = await _supabase!.isTableReady();
      if (kDebugMode) {
        debugPrint(
          _usesSupabase!
              ? '[UserRepository] Using Supabase table village_app_users.'
              : '[UserRepository] village_app_users missing — using local store. '
                  'Run supabase/apply_village_app_users.sql in Supabase SQL Editor.',
        );
      }
    } catch (e) {
      _usesSupabase = false;
      _fallbackToLocalOnNetworkError(e);
      if (kDebugMode) {
        debugPrint('[UserRepository] Supabase probe failed ($e); using local store.');
      }
    }
  }

  Future<void> _ensureBackend() async {
    if (!_backendInitialized) await initBackend();
  }

  static bool _isNetworkError(Object e) {
    if (e is ClientException) return true;
    final msg = e.toString().toLowerCase();
    return msg.contains('failed to fetch') ||
        msg.contains('socketexception') ||
        msg.contains('connection refused') ||
        msg.contains('network is unreachable');
  }

  void _fallbackToLocalOnNetworkError(Object e) {
    if (_isNetworkError(e)) {
      _usesSupabase = false;
      if (kDebugMode) {
        debugPrint(
          '[UserRepository] Supabase unreachable — using local store. '
          'Check project URL, anon key, and browser network/CORS.',
        );
      }
    }
  }

  Future<T?> _trySupabaseRead<T>(Future<T?> Function() request) async {
    if (!_usesSupabase!) return null;
    try {
      return await request();
    } catch (e) {
      _fallbackToLocalOnNetworkError(e);
      if (_isNetworkError(e)) return null;
      rethrow;
    }
  }

  Future<AppUserModel?> getByEmail(String email) async {
    await _ensureBackend();
    final normalized = RoleManager.normalizeEmail(email);
    if (_usesSupabase!) {
      final remote = await _trySupabaseRead(
        () => _supabase!.getByEmail(normalized),
      );
      if (remote != null) return remote;
      return _local.getByEmail(normalized);
    }
    return _local.getByEmail(normalized);
  }

  Future<AppUserModel?> getByUid(String uid) async {
    await _ensureBackend();
    if (_usesSupabase!) {
      final remote = await _trySupabaseRead(() => _supabase!.getByUid(uid));
      if (remote != null) return remote;
      return _local.getByUid(uid);
    }
    return _local.getByUid(uid);
  }

  Future<bool> emailExists(String email) async =>
      (await getByEmail(email)) != null;

  Future<AppUserModel> createUser({
    required String firstName,
    required String lastName,
    required String mobileNumber,
    required String email,
    required String gender,
    required AppRole role,
  }) async {
    RoleManager.assertSignupRole(role);
    final normalizedEmail = RoleManager.normalizeEmail(email);
    if (await emailExists(normalizedEmail)) {
      throw StateError('An account with this email already exists.');
    }

    final user = AppUserModel(
      uid: _uuid.v4(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      mobileNumber: mobileNumber.trim(),
      email: normalizedEmail,
      gender: gender,
      role: role,
      authType: AppAuthType.otpUser,
      isApproved: true,
      isOtpVerified: true,
      signupCompleted: true,
      createdAt: DateTime.now().toUtc(),
      lastLoginAt: DateTime.now().toUtc(),
    );
    return _insert(user);
  }

  Future<AppUserModel> createDepartmentAdmin({
    required String firstName,
    required String lastName,
    required String mobileNumber,
    required String email,
    required String gender,
    required AppDepartment department,
    required String temporaryPassword,
  }) async {
    final normalizedEmail = RoleManager.normalizeEmail(email);
    if (RoleManager.isSuperAdminEmail(normalizedEmail)) {
      throw StateError('Super admin account cannot be recreated.');
    }
    if (await emailExists(normalizedEmail)) {
      throw StateError('This email is already registered.');
    }

    final user = AppUserModel(
      uid: _uuid.v4(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      mobileNumber: mobileNumber.trim(),
      email: normalizedEmail,
      gender: gender,
      role: AppRole.deptAdmin,
      authType: AppAuthType.deptAdminPassword,
      department: department.value,
      passwordHash: PasswordService.hashPassword(temporaryPassword),
      isApproved: false,
      isOtpVerified: false,
      signupCompleted: false,
      tempPasswordChanged: false,
      createdAt: DateTime.now().toUtc(),
    );
    return _insert(user);
  }

  Future<AppUserModel?> verifyPasswordLogin({
    required String email,
    required String password,
  }) async {
    final normalized = RoleManager.normalizeEmail(email);

    if (RoleManager.isSuperAdminEmail(normalized)) {
      return _verifySuperAdminPassword(normalized, password);
    }

    final user = await getByEmail(normalized);
    if (user == null || !user.usesPasswordLogin) return null;
    if (!PasswordService.verifyPassword(password, user.passwordHash)) {
      return null;
    }
    return user;
  }

  Future<AppUserModel?> _verifySuperAdminPassword(
    String email,
    String password,
  ) async {
    final matchesEnvPassword = PasswordService.verifyPassword(
      password,
      PasswordService.hashPassword(EnvConfig.superAdminPassword),
    );

    final user = await getByEmail(email);
    final matchesStoredHash = user != null &&
        PasswordService.verifyPassword(password, user.passwordHash);

    if (!matchesEnvPassword && !matchesStoredHash) return null;

    final hashToStore = PasswordService.hashPassword(
      matchesEnvPassword ? EnvConfig.superAdminPassword : password,
    );

    if (user == null) {
      return _safeInsert(
        AppUserModel(
          uid: _uuid.v4(),
          firstName: 'Super',
          lastName: 'Admin',
          mobileNumber: '',
          email: email,
          gender: 'Other',
          role: AppRole.superAdmin,
          authType: AppAuthType.superAdminPassword,
          passwordHash: hashToStore,
          isApproved: true,
          isOtpVerified: true,
          signupCompleted: true,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }

    if (!user.role.isSuperAdmin) return null;

    if (user.authType != AppAuthType.superAdminPassword ||
        user.passwordHash == null ||
        !PasswordService.verifyPassword(password, user.passwordHash)) {
      return _safeUpdate(
        user.copyWith(
          authType: AppAuthType.superAdminPassword,
          passwordHash: hashToStore,
          isOtpVerified: true,
          signupCompleted: true,
        ),
      );
    }
    return user;
  }

  Future<AppUserModel> activateDeptAdminWithOtp(String uid) async {
    final user = await getByUid(uid);
    if (user == null || !user.role.isDeptAdmin) {
      throw StateError('Department admin account not found.');
    }
    if (!user.isApproved) {
      throw StateError('Account is not approved yet.');
    }
    if (user.isOtpVerified) {
      throw StateError('This account is already activated.');
    }
    return _update(
      user.copyWith(
        isOtpVerified: true,
        signupCompleted: true,
      ),
    );
  }

  Future<AppUserModel> updatePassword(String uid, String newPassword) async {
    final user = await getByUid(uid);
    if (user == null) throw StateError('Account not found.');
    return _update(
      user.copyWith(
        passwordHash: PasswordService.hashPassword(newPassword),
        tempPasswordChanged: true,
      ),
    );
  }

  Future<AppUserModel> _insert(AppUserModel user) async {
    await _ensureBackend();
    return _safeInsert(user);
  }

  Future<AppUserModel> _safeInsert(AppUserModel user) async {
    if (_usesSupabase!) {
      try {
        return await _supabase!.insert(user);
      } catch (e) {
        _fallbackToLocalOnNetworkError(e);
        if (!_isNetworkError(e)) rethrow;
      }
    }
    return _local.insert(user);
  }

  Future<AppUserModel> _update(AppUserModel user) async {
    await _ensureBackend();
    return _safeUpdate(user);
  }

  Future<AppUserModel> _safeUpdate(AppUserModel user) async {
    if (_usesSupabase!) {
      try {
        return await _supabase!.update(user);
      } catch (e) {
        _fallbackToLocalOnNetworkError(e);
        if (!_isNetworkError(e)) rethrow;
      }
    }
    return _local.update(user);
  }

  Future<void> approveDeptAdmin(String uid) => setApproved(uid, true);

  Future<void> setApproved(String uid, bool approved) async {
    final user = await getByUid(uid);
    if (user == null) return;
    if (user.role != AppRole.deptAdmin) {
      throw StateError('Only department admins require approval.');
    }
    await _update(user.copyWith(isApproved: approved));
  }

  Future<void> removeDepartmentAdmin(String uid) async {
    final user = await getByUid(uid);
    if (user == null) return;
    if (user.role != AppRole.deptAdmin) {
      throw StateError('User is not a department admin.');
    }
    if (RoleManager.isSuperAdminEmail(user.email)) {
      throw StateError('Cannot remove the super admin account.');
    }
    await _update(
      user.copyWith(
        role: AppRole.user,
        clearDepartment: true,
        isApproved: true,
      ),
    );
  }

  Future<List<AppUserModel>> getAllUsers() async {
    await _ensureBackend();
    return _usesSupabase! ? _supabase!.getAllUsers() : _local.getAllUsers();
  }

  Future<List<AppUserModel>> getDeptAdmins() async {
    await _ensureBackend();
    return _usesSupabase! ? _supabase!.getDeptAdmins() : _local.getDeptAdmins();
  }

  Stream<List<AppUserModel>> watchAllUsers() async* {
    await _ensureBackend();
    if (_usesSupabase!) {
      yield* _supabase!.watchAllUsers();
    } else {
      yield await _local.getAllUsers();
    }
  }

  Future<List<AppUserModel>> searchUsers(String query) async {
    final all = await getAllUsers();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((u) {
      return u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.mobileNumber.contains(q) ||
          u.role.value.contains(q) ||
          (u.department ?? '').toLowerCase().contains(q);
    }).toList();
  }

  Future<AppUserModel> touchLogin(AppUserModel user) async {
    final updated = user.copyWith(lastLoginAt: DateTime.now().toUtc());
    return _update(updated);
  }

  Future<void> blockUser(String uid, bool blocked) async {
    final user = await getByUid(uid);
    if (user == null) return;
    await _update(user.copyWith(isBlocked: blocked));
  }

  Future<void> setBlocked(String uid, bool blocked) => blockUser(uid, blocked);

  Future<void> deleteUser(String uid) async {
    await _ensureBackend();
    if (_usesSupabase!) {
      await _supabase!.deleteByUid(uid);
    } else {
      await _local.deleteByUid(uid);
    }
    if (_session.sessionUid == uid) {
      await _session.clearSession();
    }
  }

  Future<AppUserModel?> getCurrentUser() async {
    final uid = _session.sessionUid;
    if (uid == null) return null;
    return getByUid(uid);
  }

  /// Upload legacy/local users into Supabase when the table becomes available.
  Future<void> migrateLegacyLocalUsersIfNeeded() async {
    await _ensureBackend();
    if (!_usesSupabase!) return;
    final db = _supabase;
    if (db == null) return;

    final raw = _session.legacyUsersJson;
    if (raw != null && raw.isNotEmpty && !_session.legacyMigrationDone) {
      try {
        final decoded = _decodeLegacyUsers(raw);
        for (final user in decoded) {
          final existing = await db.getByEmail(user.email);
          if (existing == null) {
            await db.insert(user);
          }
        }
      } finally {
        await _session.markLegacyMigrationDone();
      }
      return;
    }

    if (_session.legacyMigrationDone) return;

    final localUsers = await _local.getAllUsers();
    if (localUsers.isEmpty) {
      await _session.markLegacyMigrationDone();
      return;
    }

    for (final user in localUsers) {
      final existing = await db.getByEmail(user.email);
      if (existing == null) {
        await db.insert(user);
      }
    }
    await _session.markLegacyMigrationDone();
    await _session.saveLocalUsersJson('[]');
  }

  static List<AppUserModel> _decodeLegacyUsers(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => AppUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
