import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/permissions/permission_service.dart';
import '../core/role_manager.dart';
import '../models/app_auth_type.dart';
import '../models/app_department.dart';
import '../models/app_role.dart';
import '../models/app_user_model.dart';
import '../services/email_auth_service.dart';
import '../services/otp_service.dart';
import '../storage/session_manager.dart';
import '../storage/user_repository.dart';
import '../storage/user_providers.dart';
import 'admin_login_result.dart';

final otpServiceProvider = FutureProvider<OtpService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return OtpService(prefs);
});

final emailAuthServiceProvider = Provider<EmailAuthService>((ref) {
  return EmailAuthService();
});

class AuthState {
  const AuthState({
    this.user,
    this.pendingActivationUser,
    this.initialized = false,
    this.loading = false,
  });

  final AppUserModel? user;
  final AppUserModel? pendingActivationUser;
  final bool initialized;
  final bool loading;

  bool get isLoggedIn => user != null;

  String get homeRoute {
    final current = user;
    if (current == null) return '/signup';
    if (current.isBlocked) return '/signup';
    return switch (current.role) {
      AppRole.superAdmin => '/admin/super',
      AppRole.deptAdmin when !current.isApproved => '/admin/pending',
      AppRole.deptAdmin when !current.isOtpVerified => '/admin/activate',
      AppRole.deptAdmin => '/admin/dept',
      AppRole.user => '/home',
    };
  }

  AuthState copyWith({
    AppUserModel? user,
    AppUserModel? pendingActivationUser,
    bool? initialized,
    bool? loading,
    bool clearUser = false,
    bool clearPendingActivation = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      pendingActivationUser: clearPendingActivation
          ? null
          : (pendingActivationUser ?? this.pendingActivationUser),
      initialized: initialized ?? this.initialized,
      loading: loading ?? this.loading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState()) {
    _restoreSession();
  }

  final Ref _ref;

  Future<SessionManager> get _session async =>
      _ref.read(sessionManagerProvider.future);

  Future<UserRepository> get _users async =>
      _ref.read(userRepositoryProvider.future);

  Future<OtpService> get _otp async => _ref.read(otpServiceProvider.future);

  EmailAuthService get _email => _ref.read(emailAuthServiceProvider);

  Future<void> _restoreSession() async {
    state = state.copyWith(loading: true);
    try {
      final session = await _session;
      final users = await _users;
      final user = await users.getCurrentUser();
      if (user != null && user.isBlocked) {
        await session.clearSession();
        state = state.copyWith(
          clearUser: true,
          initialized: true,
          loading: false,
        );
        return;
      }
      state = state.copyWith(user: user, initialized: true, loading: false);
    } catch (_) {
      state = state.copyWith(initialized: true, loading: false);
    }
  }

  Future<void> refreshCurrentUser() async {
    final uid = state.user?.uid;
    if (uid == null) return;
    final users = await _users;
    final fresh = await users.getByUid(uid);
    if (fresh != null) {
      state = state.copyWith(user: fresh);
    }
  }

  Future<int> resendCooldownSeconds(String email) async {
    final otp = await _otp;
    return otp.secondsUntilResendAllowed(email);
  }

  /// OTP only for village user signup and first-time dept admin activation.
  Future<void> sendOtp({
    required String email,
    required String recipientName,
    bool forDeptAdminActivation = false,
  }) async {
    final normalized = RoleManager.normalizeEmail(email);
    final users = await _users;
    final existing = await users.getByEmail(normalized);

    if (!forDeptAdminActivation) {
      if (existing != null && existing.usesPasswordLogin) {
        throw StateError(
          'This email is for admin login. Use Admin sign-in instead.',
        );
      }
      if (RoleManager.isSuperAdminEmail(normalized)) {
        throw StateError('Super admin must use Admin sign-in with password.');
      }
    } else {
      if (existing == null || !existing.role.isDeptAdmin) {
        throw StateError('No department admin account found for this email.');
      }
      if (!existing.isApproved) {
        throw StateError('Your account is awaiting super admin approval.');
      }
      if (existing.isOtpVerified) {
        throw StateError('Account already activated. Sign in with password.');
      }
    }

    final otpService = await _otp;
    final wait = await otpService.secondsUntilResendAllowed(normalized);
    if (wait > 0) {
      throw StateError('Please wait $wait seconds before resending OTP.');
    }

    final code = otpService.generateOtp();
    await otpService.saveOtp(email: normalized, otp: code);
    await _email.sendOtpEmail(
      toEmail: normalized,
      otp: code,
      recipientName: recipientName,
    );
  }

  /// Village user one-time signup (OTP only — permanent session after).
  Future<AppUserModel> verifySignupAndCreate({
    required String firstName,
    required String lastName,
    required String mobileNumber,
    required String email,
    required String gender,
    required String otp,
  }) async {
    final normalized = RoleManager.normalizeEmail(email);
    if (RoleManager.isSuperAdminEmail(normalized)) {
      throw StateError('Super admin must use Admin sign-in with password.');
    }

    final otpService = await _otp;
    final valid = await otpService.verifyOtp(email: normalized, input: otp);
    if (!valid) {
      throw StateError('Invalid or expired OTP. Request a new code.');
    }

    final users = await _users;
    final existing = await users.getByEmail(normalized);
    if (existing != null) {
      if (existing.isBlocked) {
        throw StateError('This account is blocked. Contact the village admin.');
      }
      if (existing.usesPasswordLogin) {
        throw StateError(
          'This email is registered as an admin. Use Admin sign-in.',
        );
      }
      await otpService.clearOtp(normalized);
      return _completeLogin(existing);
    }

    final role = RoleManager.roleForNewSignup(normalized);
    RoleManager.assertSignupRole(role);

    final created = await users.createUser(
      firstName: firstName,
      lastName: lastName,
      mobileNumber: mobileNumber,
      email: normalized,
      gender: gender,
      role: role,
    );
    await otpService.clearOtp(normalized);
    return _completeLogin(created);
  }

  /// Admin login: super admin or dept admin (password). Dept may need OTP next.
  Future<AdminLoginResult> loginWithPassword({
    required String email,
    required String password,
  }) async {
    final normalized = RoleManager.normalizeEmail(email);
    final users = await _users;
    final user = await users.verifyPasswordLogin(
      email: normalized,
      password: password,
    );

    if (user == null) {
      final existing = await users.getByEmail(normalized);
      if (existing != null && existing.authType == AppAuthType.otpUser) {
        return const AdminLoginResult(outcome: AdminLoginOutcome.notAdminAccount);
      }
      return const AdminLoginResult(
        outcome: AdminLoginOutcome.invalidCredentials,
      );
    }

    if (user.isBlocked) {
      return AdminLoginResult(outcome: AdminLoginOutcome.blocked, user: user);
    }

    if (user.role.isSuperAdmin) {
      await _completeLogin(user);
      return AdminLoginResult(
        outcome: AdminLoginOutcome.success,
        user: state.user,
      );
    }

    if (user.role.isDeptAdmin) {
      if (!user.isApproved) {
        return AdminLoginResult(
          outcome: AdminLoginOutcome.awaitingApproval,
          user: user,
        );
      }
      if (!user.isOtpVerified) {
        state = state.copyWith(pendingActivationUser: user);
        return AdminLoginResult(
          outcome: AdminLoginOutcome.requiresOtpActivation,
          user: user,
        );
      }
      await _completeLogin(user);
      return AdminLoginResult(
        outcome: AdminLoginOutcome.success,
        user: state.user,
      );
    }

    return const AdminLoginResult(outcome: AdminLoginOutcome.notAdminAccount);
  }

  /// First-time dept admin: after password check, verify OTP once.
  Future<AppUserModel> completeDeptAdminActivation({
    required String otp,
  }) async {
    final pending = state.pendingActivationUser;
    if (pending == null) {
      throw StateError('Sign in with your temporary password first.');
    }

    final normalized = RoleManager.normalizeEmail(pending.email);
    final otpService = await _otp;
    final valid = await otpService.verifyOtp(email: normalized, input: otp);
    if (!valid) {
      throw StateError('Invalid or expired OTP. Request a new code.');
    }

    final users = await _users;
    final activated = await users.activateDeptAdminWithOtp(pending.uid);
    await otpService.clearOtp(normalized);
    state = state.copyWith(clearPendingActivation: true);
    return _completeLogin(activated);
  }

  void clearPendingActivation() {
    state = state.copyWith(clearPendingActivation: true);
  }

  Future<AppUserModel> _completeLogin(AppUserModel user) async {
    final users = await _users;
    final session = await _session;
    final updated = await users.touchLogin(user);
    await session.saveSession(
      uid: updated.uid,
      token: updated.uid,
    );
    state = state.copyWith(
      user: updated,
      initialized: true,
      loading: false,
      clearPendingActivation: true,
    );
    return updated;
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
    final actor = state.user;
    if (!PermissionService.canCreateDepartmentAdmin(actor)) {
      throw StateError('Only the super admin can create department admins.');
    }

    final users = await _users;
    return users.createDepartmentAdmin(
      firstName: firstName,
      lastName: lastName,
      mobileNumber: mobileNumber,
      email: email,
      gender: gender,
      department: department,
      temporaryPassword: temporaryPassword,
    );
  }

  Future<void> approveDepartmentAdmin(String uid) async {
    PermissionService.assertCanManageUsers(state.user);
    final users = await _users;
    await users.approveDeptAdmin(uid);
  }

  Future<void> removeDepartmentAdmin(String uid) async {
    PermissionService.assertCanManageUsers(state.user);
    final users = await _users;
    await users.removeDepartmentAdmin(uid);
  }

  Future<void> setUserBlocked(String uid, bool blocked) async {
    PermissionService.assertCanManageUsers(state.user);
    final users = await _users;
    final target = await users.getByUid(uid);
    if (target != null && RoleManager.isSuperAdminEmail(target.email)) {
      throw StateError('The super admin account cannot be blocked.');
    }
    await users.setBlocked(uid, blocked);
  }

  Future<void> deleteUser(String uid) async {
    PermissionService.assertCanManageUsers(state.user);
    final users = await _users;
    final target = await users.getByUid(uid);
    if (target != null && RoleManager.isSuperAdminEmail(target.email)) {
      throw StateError('The super admin account cannot be deleted.');
    }
    await users.deleteUser(uid);
    if (state.user?.uid == uid) {
      state = state.copyWith(clearUser: true);
    }
  }

  Future<List<AppUserModel>> listUsers({String query = ''}) async {
    final users = await _users;
    return users.searchUsers(query);
  }

  Future<List<AppUserModel>> getDeptAdmins() async {
    final users = await _users;
    return users.getDeptAdmins();
  }

  Future<void> logout() async {
    final session = await _session;
    await session.clearSession();
    state = state.copyWith(
      clearUser: true,
      clearPendingActivation: true,
      initialized: true,
      loading: false,
    );
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));

final isNewsAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authProvider).user;
  return PermissionService.canAccessSuperAdminDashboard(user);
});
