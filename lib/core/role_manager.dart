import 'config/env_config.dart';
import '../models/app_role.dart';
import '../models/app_user_model.dart';

/// Enforces super-admin and department-admin role rules.
class RoleManager {
  RoleManager._();

  static String get superAdminEmail => EnvConfig.superAdminEmail;

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static bool isSuperAdminEmail(String email) =>
      normalizeEmail(email) == superAdminEmail;

  /// Role assigned on first-time signup. Only the permanent super-admin email
  /// may receive [AppRole.superAdmin]; everyone else is a normal user.
  static AppRole roleForNewSignup(String email) {
    if (isSuperAdminEmail(email)) return AppRole.superAdmin;
    return AppRole.user;
  }

  /// Existing accounts keep their stored role (prevents privilege escalation).
  static AppRole resolveRoleOnLogin(AppUserModel existing) => existing.role;

  static bool canAccessAdminDashboard(AppUserModel user) {
    if (user.isBlocked) return false;
    return user.role.isSuperAdmin || user.role.isDeptAdmin;
  }

  static bool canCreateDepartmentAdmin(AppUserModel? actor) =>
      actor != null && actor.role.isSuperAdmin && !actor.isBlocked;

  static bool canApproveDepartmentAdmin(AppUserModel? actor) =>
      canCreateDepartmentAdmin(actor);

  static bool canSelfRegisterAsDeptAdmin(AppRole role) => role == AppRole.deptAdmin;

  /// Dept admins cannot change role or department via signup/profile.
  static bool canChangeRole(AppUserModel? actor, AppUserModel target) {
    if (actor == null || !actor.role.isSuperAdmin) return false;
    if (isSuperAdminEmail(target.email)) return false;
    return true;
  }

  static void assertSignupRole(AppRole role) {
    if (canSelfRegisterAsDeptAdmin(role)) {
      throw StateError('Department admins cannot self-register.');
    }
  }
}
