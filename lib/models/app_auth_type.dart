import 'app_role.dart';

/// How the account authenticates after initial setup.
enum AppAuthType {
  otpUser('otp_user'),
  deptAdminPassword('dept_admin_password'),
  superAdminPassword('super_admin_password');

  const AppAuthType(this.value);

  final String value;

  static AppAuthType? fromValue(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final t in AppAuthType.values) {
      if (t.value == raw) return t;
    }
    return null;
  }

  static AppAuthType forRole(AppRole role, {bool isSuperAdminEmail = false}) {
    if (isSuperAdminEmail || role.isSuperAdmin) {
      return AppAuthType.superAdminPassword;
    }
    if (role.isDeptAdmin) return AppAuthType.deptAdminPassword;
    return AppAuthType.otpUser;
  }
}
