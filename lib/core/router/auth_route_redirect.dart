import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../permissions/permission_service.dart';
import 'app_router.dart';

/// Global auth guard: session, role-based admin access, dept approval.
String? authRouteRedirect(GoRouterState state, Ref ref) {
  final auth = ref.read(authProvider);
  if (!auth.initialized) return null;

  final location = state.matchedLocation;
  final isAuthGate = location == AppRoutePaths.splash;
  final isSignup = location == AppRoutePaths.signup;
  final isAdminLogin = location == AppRoutePaths.adminLogin;
  final isAdminActivate = location == AppRoutePaths.adminActivate;
  final isSettings = location == AppRoutePaths.settings;
  final isPending = location == AppRoutePaths.deptAdminPending;
  final isPublicAuth =
      isSignup || isAdminLogin || isAdminActivate || isAuthGate;

  if (!auth.isLoggedIn) {
    if (isPublicAuth) return null;
    return AppRoutePaths.signup;
  }

  final user = auth.user!;
  if (user.isBlocked) {
    if (!isSignup && !isAdminLogin) return AppRoutePaths.signup;
    return null;
  }

  if (isSignup || isAuthGate || isAdminLogin) {
    return auth.homeRoute;
  }

  if (isAdminActivate) {
    if (user.role.isDeptAdmin &&
        !user.isOtpVerified &&
        auth.pendingActivationUser != null) {
      return null;
    }
    if (user.role.isDeptAdmin && user.isOtpVerified) {
      return auth.homeRoute;
    }
    return AppRoutePaths.adminLogin;
  }

  if (location == AppRoutePaths.superAdminHome &&
      !PermissionService.canAccessSuperAdminDashboard(user)) {
    return auth.homeRoute;
  }

  if (PermissionService.isDeptAdminPendingApproval(user)) {
    if (!isPending && !isSettings) return AppRoutePaths.deptAdminPending;
    if (location == AppRoutePaths.deptAdminHome) {
      return AppRoutePaths.deptAdminPending;
    }
    return null;
  }

  if (isPending) {
    return PermissionService.canAccessDeptAdminDashboard(user)
        ? AppRoutePaths.deptAdminHome
        : auth.homeRoute;
  }

  if (location == AppRoutePaths.deptAdminHome &&
      !PermissionService.canAccessDeptAdminDashboard(user)) {
    return auth.homeRoute;
  }

  if (isSettings) return null;

  return null;
}
