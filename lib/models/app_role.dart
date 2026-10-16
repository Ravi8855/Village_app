/// Application roles for village users and administrators.
enum AppRole {
  superAdmin('super_admin'),
  deptAdmin('dept_admin'),
  user('user');

  const AppRole(this.value);

  final String value;

  static AppRole? fromValue(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final role in AppRole.values) {
      if (role.value == raw) return role;
    }
    return null;
  }

  bool get isSuperAdmin => this == AppRole.superAdmin;
  bool get isDeptAdmin => this == AppRole.deptAdmin;
  bool get isUser => this == AppRole.user;
}
