import 'app_auth_type.dart';
import 'app_department.dart';
import 'app_role.dart';

/// Village user profile (Supabase `village_app_users`; session stores uid only).
class AppUserModel {
  const AppUserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.mobileNumber,
    required this.email,
    required this.gender,
    required this.role,
    required this.authType,
    this.department,
    this.passwordHash,
    this.isBlocked = false,
    this.isApproved = true,
    this.isOtpVerified = true,
    this.signupCompleted = true,
    this.tempPasswordChanged = false,
    required this.createdAt,
    this.lastLoginAt,
  });

  final String uid;
  final String firstName;
  final String lastName;
  final String mobileNumber;
  final String email;
  final String gender;
  final AppRole role;
  final AppAuthType authType;
  final String? department;
  final String? passwordHash;
  final bool isBlocked;
  final bool isApproved;
  final bool isOtpVerified;
  final bool signupCompleted;
  final bool tempPasswordChanged;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  String get fullName => '$firstName $lastName'.trim();

  AppDepartment? get departmentEnum => AppDepartment.fromValue(department);

  bool get usesPasswordLogin =>
      authType == AppAuthType.deptAdminPassword ||
      authType == AppAuthType.superAdminPassword;

  bool get isFullyActivatedDeptAdmin =>
      role.isDeptAdmin && isApproved && isOtpVerified && signupCompleted;

  AppUserModel copyWith({
    String? firstName,
    String? lastName,
    String? mobileNumber,
    String? email,
    String? gender,
    AppRole? role,
    AppAuthType? authType,
    String? department,
    String? passwordHash,
    bool clearPasswordHash = false,
    bool clearDepartment = false,
    bool? isBlocked,
    bool? isApproved,
    bool? isOtpVerified,
    bool? signupCompleted,
    bool? tempPasswordChanged,
    DateTime? lastLoginAt,
  }) {
    return AppUserModel(
      uid: uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      authType: authType ?? this.authType,
      department: clearDepartment ? null : (department ?? this.department),
      passwordHash:
          clearPasswordHash ? null : (passwordHash ?? this.passwordHash),
      isBlocked: isBlocked ?? this.isBlocked,
      isApproved: isApproved ?? this.isApproved,
      isOtpVerified: isOtpVerified ?? this.isOtpVerified,
      signupCompleted: signupCompleted ?? this.signupCompleted,
      tempPasswordChanged: tempPasswordChanged ?? this.tempPasswordChanged,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'firstName': firstName,
        'lastName': lastName,
        'mobileNumber': mobileNumber,
        'email': email,
        'gender': gender,
        'role': role.value,
        'authType': authType.value,
        'department': department,
        'passwordHash': passwordHash,
        'isBlocked': isBlocked,
        'isApproved': isApproved,
        'isOtpVerified': isOtpVerified,
        'signupCompleted': signupCompleted,
        'tempPasswordChanged': tempPasswordChanged,
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
      };

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    final role = AppRole.fromValue(json['role'] as String?) ?? AppRole.user;
    return AppUserModel(
      uid: json['uid'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      role: role,
      authType: AppAuthType.fromValue(json['authType'] as String?) ??
          AppAuthType.forRole(role),
      department: json['department'] as String?,
      passwordHash: json['passwordHash'] as String?,
      isBlocked: json['isBlocked'] as bool? ?? false,
      isApproved: _readIsApproved(json, role),
      isOtpVerified: json['isOtpVerified'] as bool? ??
          json['is_otp_verified'] as bool? ??
          role.isUser,
      signupCompleted: _readSignupCompleted(json, role),
      tempPasswordChanged: json['tempPasswordChanged'] as bool? ??
          json['temp_password_changed'] as bool? ??
          false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      lastLoginAt: json['lastLoginAt'] == null
          ? null
          : DateTime.tryParse(json['lastLoginAt'] as String),
    );
  }

  factory AppUserModel.fromSupabaseRow(Map<String, dynamic> row) {
    final role = AppRole.fromValue(row['role'] as String?) ?? AppRole.user;
    return AppUserModel(
      uid: row['uid'] as String,
      firstName: row['first_name'] as String? ?? '',
      lastName: row['last_name'] as String? ?? '',
      mobileNumber: row['mobile_number'] as String? ?? '',
      email: row['email'] as String? ?? '',
      gender: row['gender'] as String? ?? '',
      role: role,
      authType: AppAuthType.fromValue(row['auth_type'] as String?) ??
          AppAuthType.forRole(role),
      department: row['department'] as String?,
      passwordHash: row['password_hash'] as String?,
      isBlocked: row['is_blocked'] as bool? ?? false,
      isApproved: row['is_approved'] as bool? ?? true,
      isOtpVerified: row['is_otp_verified'] as bool? ??
          (role == AppRole.user || role == AppRole.superAdmin),
      signupCompleted: row['signup_completed'] as bool? ?? true,
      tempPasswordChanged: row['temp_password_changed'] as bool? ?? false,
      createdAt: _parseTimestamp(row['created_at']) ?? DateTime.now().toUtc(),
      lastLoginAt: _parseTimestamp(row['last_login_at']),
    );
  }

  Map<String, dynamic> toSupabaseRow() => {
        'uid': uid,
        'first_name': firstName,
        'last_name': lastName,
        'mobile_number': mobileNumber,
        'email': email,
        'gender': gender,
        'role': role.value,
        'auth_type': authType.value,
        'department': department,
        'password_hash': passwordHash,
        'is_blocked': isBlocked,
        'is_approved': isApproved,
        'is_otp_verified': isOtpVerified,
        'signup_completed': signupCompleted,
        'temp_password_changed': tempPasswordChanged,
        'created_at': createdAt.toUtc().toIso8601String(),
        'last_login_at': lastLoginAt?.toUtc().toIso8601String(),
      };

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    return DateTime.tryParse(value.toString())?.toUtc();
  }

  static bool _readIsApproved(Map<String, dynamic> json, AppRole role) {
    if (json.containsKey('isApproved')) {
      return json['isApproved'] as bool? ?? true;
    }
    return role != AppRole.deptAdmin;
  }

  static bool _readSignupCompleted(Map<String, dynamic> json, AppRole role) {
    if (json.containsKey('signupCompleted')) {
      return json['signupCompleted'] as bool? ?? true;
    }
    if (role == AppRole.deptAdmin) {
      return json['isOtpVerified'] as bool? ?? false;
    }
    return true;
  }

  String get deptAdminStatusLabel {
    if (!isApproved) return 'Awaiting approval';
    if (!isOtpVerified) return 'Activation required';
    if (!signupCompleted) return 'Activation required';
    return 'Active';
  }
}
