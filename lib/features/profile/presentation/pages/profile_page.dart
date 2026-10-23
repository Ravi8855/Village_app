import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/location_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/app_role.dart';
import '../../../../providers/auth_provider.dart';

/// Professional resident profile and settings page.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isSuperAdmin = user?.role.isSuperAdmin ?? false;
    final isDeptAdmin = user?.role.isDeptAdmin ?? false;
    final hasAdminAccess = isSuperAdmin || isDeptAdmin;

    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (hasAdminAccess)
            IconButton(
              tooltip: isSuperAdmin ? 'Super admin panel' : 'Dept admin panel',
              icon: const Icon(Icons.admin_panel_settings_rounded),
              onPressed: () {
                if (isSuperAdmin) {
                  context.go(AppRoutePaths.superAdminHome);
                } else {
                  context.go(AppRoutePaths.deptAdminHome);
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // 1. Profile Header Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: AppColors.forest,
                        child: Text(
                          user != null && user.firstName.isNotEmpty
                              ? user.firstName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const CircleAvatar(
                          radius: 11,
                          backgroundColor: Color(0xFF2E7D32),
                          child: Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName.isNotEmpty == true
                        ? user!.fullName
                        : 'Village Resident',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'No email provided',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.soil.withValues(alpha: 0.8),
                        ),
                  ),
                  if (user?.mobileNumber.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      user!.mobileNumber,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.soil.withValues(alpha: 0.65),
                          ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _roleBadgeColor(user?.role).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _roleBadgeColor(user?.role).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _roleIcon(user?.role),
                          size: 16,
                          color: _roleBadgeColor(user?.role),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _roleLabel(user),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _roleBadgeColor(user?.role),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Admin Quick Switch Banner (if admin)
          if (hasAdminAccess) ...[
            Card(
              color: AppColors.forest.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppColors.forest.withValues(alpha: 0.25),
                ),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.forest,
                  child: Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  isSuperAdmin ? 'Super Admin Dashboard' : 'Department Admin Dashboard',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Manage village records, users & notices'),
                trailing: const Icon(Icons.arrow_forward_rounded),
                onTap: () {
                  if (isSuperAdmin) {
                    context.go(AppRoutePaths.superAdminHome);
                  } else {
                    context.go(AppRoutePaths.deptAdminHome);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 3. Citizen & Village Details
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Village Information',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.forest,
                        ),
                  ),
                  const Divider(height: 16),
                  const _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Village',
                    value: '${NaganoorLocation.villageName} (ನಾಗನೂರು)',
                  ),
                  const _InfoRow(
                    icon: Icons.account_balance_outlined,
                    label: 'Gram Panchayat',
                    value: 'Naganoor Gram Panchayat',
                  ),
                  const _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Citizen Status',
                    value: 'Verified Resident',
                  ),
                  if (user != null)
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Registered',
                      value: DateFormat('MMMM d, yyyy').format(user.createdAt),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Quick Actions
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.water_drop_outlined, color: Color(0xFF0288D1)),
                  title: const Text('Water Supply Notices'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutePaths.waterSupply),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.local_hospital_outlined, color: Color(0xFFE53935)),
                  title: const Text('Primary Health Centre (PHC)'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go(AppRoutePaths.health),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.temple_hindu_outlined, color: Color(0xFF7B1FA2)),
                  title: const Text('Temples & Festivals'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutePaths.temples),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.rice_bowl_outlined, color: Color(0xFF558B2F)),
                  title: const Text('ಅನ್ನಭಾಗ್ಯ ಯೋಜನೆ Schedule'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutePaths.annabhagya),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Sign Out Button
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text(
                'Sign out',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Sign out of your session on this device'),
              onTap: () => _confirmSignOut(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Color _roleBadgeColor(AppRole? role) {
    if (role == null) return AppColors.forest;
    return switch (role) {
      AppRole.superAdmin => const Color(0xFF6A1B9A),
      AppRole.deptAdmin => const Color(0xFF0277BD),
      AppRole.user => const Color(0xFF2E7D32),
    };
  }

  IconData _roleIcon(AppRole? role) {
    if (role == null) return Icons.person_rounded;
    return switch (role) {
      AppRole.superAdmin => Icons.stars_rounded,
      AppRole.deptAdmin => Icons.admin_panel_settings_rounded,
      AppRole.user => Icons.verified_user_rounded,
    };
  }

  String _roleLabel(dynamic user) {
    if (user == null) return 'Resident';
    if (user.role == AppRole.superAdmin) return 'Super Administrator';
    if (user.role == AppRole.deptAdmin) {
      final deptLabel = user.departmentEnum?.label ?? user.department ?? '';
      return deptLabel.isNotEmpty ? '$deptLabel Admin' : 'Department Admin';
    }
    return 'Verified Village Resident';
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Are you sure you want to sign out from Naganoor Village App?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        context.go(AppRoutePaths.signup);
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.soil.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.soil.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
