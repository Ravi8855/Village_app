import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/app_role.dart';
import '../../../../models/app_user_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../storage/user_providers.dart';
import '../widgets/admin_account_detail_sheet.dart';

/// Super-admin: department admins (live Supabase sync).
class SuperAdminAdminsTab extends ConsumerStatefulWidget {
  const SuperAdminAdminsTab({super.key, this.onCreateAdmin});

  final VoidCallback? onCreateAdmin;

  @override
  ConsumerState<SuperAdminAdminsTab> createState() =>
      _SuperAdminAdminsTabState();
}

class _SuperAdminAdminsTabState extends ConsumerState<SuperAdminAdminsTab> {
  void _openDetail(BuildContext context, AppUserModel admin) {
    final canApprove = !admin.isApproved;
    showAdminAccountDetailSheet(
      context,
      user: admin,
      onApprove: canApprove ? () => _onAction(context, admin, 'approve') : null,
      onRemoveAdmin: () => _onAction(context, admin, 'remove'),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    AppUserModel admin,
    String action,
  ) async {
    final notifier = ref.read(authProvider.notifier);
    try {
      if (action == 'approve') {
        await notifier.approveDepartmentAdmin(admin.uid);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${admin.fullName} approved.')),
          );
        }
      } else if (action == 'remove') {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove department admin?'),
            content: Text(
              '${admin.fullName} will become a normal village user.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
        if (ok == true) {
          await notifier.removeDepartmentAdmin(admin.uid);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Department admins',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (all) {
              final admins =
                  all.where((u) => u.role == AppRole.deptAdmin).toList();

              if (admins.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No department admins yet. Create an invite, then the '
                          'admin completes signup with OTP before you approve.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: widget.onCreateAdmin,
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Create dept admin'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: admins.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final admin = admins[index];
                  return _DeptAdminListTile(
                    admin: admin,
                    onTap: () => _openDetail(context, admin),
                    onApprove: () => _onAction(context, admin, 'approve'),
                    onRemove: () => _onAction(context, admin, 'remove'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DeptAdminListTile extends StatelessWidget {
  const _DeptAdminListTile({
    required this.admin,
    required this.onTap,
    required this.onApprove,
    required this.onRemove,
  });

  final AppUserModel admin;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final canApprove = !admin.isApproved;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12, right: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(admin.email),
                    const SizedBox(height: 2),
                    Text(
                      admin.departmentEnum?.label ?? admin.department ?? '—',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(admin.deptAdminStatusLabel),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Actions',
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert),
                onSelected: (action) {
                  if (action == 'approve') onApprove();
                  if (action == 'remove') onRemove();
                },
                itemBuilder: (context) => [
                  if (canApprove)
                    const PopupMenuItem(
                      value: 'approve',
                      child: Text('Approve'),
                    ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
