import '../models/app_user_model.dart';

/// Result of email + password check on the admin login screen.
enum AdminLoginOutcome {
  success,
  requiresOtpActivation,
  awaitingApproval,
  invalidCredentials,
  blocked,
  notAdminAccount,
}

class AdminLoginResult {
  const AdminLoginResult({
    required this.outcome,
    this.user,
  });

  final AdminLoginOutcome outcome;
  final AppUserModel? user;
}
