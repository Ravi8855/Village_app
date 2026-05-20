import '../../models/app_department.dart';
import '../../models/app_user_model.dart';
import '../domain/department.dart';

/// Central permission checks for roles and department-scoped actions.
class PermissionService {
  PermissionService._();

  static VillageDepartment? villageDepartmentForUser(AppUserModel user) {
    final appDept = user.departmentEnum;
    if (appDept == null) return null;
    return switch (appDept) {
      AppDepartment.electricity => VillageDepartment.electricity,
      AppDepartment.waterSupply => VillageDepartment.waterSupply,
      AppDepartment.hospital => VillageDepartment.hospital,
      AppDepartment.bank => VillageDepartment.bank,
      AppDepartment.postOffice => VillageDepartment.postOffice,
    };
  }

  static bool isActiveUser(AppUserModel? user) =>
      user != null && !user.isBlocked;

  static bool canAccessSuperAdminDashboard(AppUserModel? user) =>
      isActiveUser(user) && user!.role.isSuperAdmin;

  static bool canAccessDeptAdminDashboard(AppUserModel? user) =>
      isActiveUser(user) &&
      user!.role.isDeptAdmin &&
      user.isApproved &&
      user.isOtpVerified &&
      user.signupCompleted &&
      user.departmentEnum != null;

  static bool isDeptAdminPendingApproval(AppUserModel? user) =>
      isActiveUser(user) &&
      user!.role.isDeptAdmin &&
      !user.isApproved;

  /// Approved but must complete one-time OTP after password login.
  static bool isDeptAdminPendingOtpActivation(AppUserModel? user) =>
      isActiveUser(user) &&
      user!.role.isDeptAdmin &&
      user.isApproved &&
      !user.isOtpVerified;

  static bool isDeptAdminInvitePendingSignup(AppUserModel? user) =>
      isActiveUser(user) &&
      user!.role.isDeptAdmin &&
      !user.isApproved;

  static bool canManageUsers(AppUserModel? user) =>
      canAccessSuperAdminDashboard(user);

  static bool canCreateDepartmentAdmin(AppUserModel? user) =>
      canAccessSuperAdminDashboard(user);

  static bool canApproveDepartmentAdmin(AppUserModel? user) =>
      canAccessSuperAdminDashboard(user);

  static bool canManageDepartment(
    AppUserModel? user,
    VillageDepartment department,
  ) {
    if (!isActiveUser(user)) return false;
    if (user!.role.isSuperAdmin) return true;
    if (!user.role.isDeptAdmin || !user.isApproved) return false;
    return villageDepartmentForUser(user) == department;
  }

  static void assertCanManageDepartment(
    AppUserModel? user,
    VillageDepartment department,
  ) {
    if (!canManageDepartment(user, department)) {
      throw StateError(
        'You do not have permission to manage ${department.label} content.',
      );
    }
  }

  static void assertCanManageUsers(AppUserModel? user) {
    if (!canManageUsers(user)) {
      throw StateError('Only the super admin can manage users.');
    }
  }
}
