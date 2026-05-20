import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/app_role.dart';
import '../../../../models/app_user_model.dart';

/// Full account details for super-admin (village user or dept admin).
void showAdminAccountDetailSheet(
  BuildContext context, {
  required AppUserModel user,
  VoidCallback? onBlock,
  VoidCallback? onUnblock,
  VoidCallback? onDelete,
  VoidCallback? onApprove,
  VoidCallback? onRemoveAdmin,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return _AdminAccountDetailBody(
          user: user,
          scrollController: scrollController,
          onBlock: onBlock,
          onUnblock: onUnblock,
          onDelete: onDelete,
          onApprove: onApprove,
          onRemoveAdmin: onRemoveAdmin,
        );
      },
    ),
  );
}

class _AdminAccountDetailBody extends StatelessWidget {
  const _AdminAccountDetailBody({
    required this.user,
    required this.scrollController,
    this.onBlock,
    this.onUnblock,
    this.onDelete,
    this.onApprove,
    this.onRemoveAdmin,
  });

  final AppUserModel user;
  final ScrollController scrollController;
  final VoidCallback? onBlock;
  final VoidCallback? onUnblock;
  final VoidCallback? onDelete;
  final VoidCallback? onApprove;
  final VoidCallback? onRemoveAdmin;

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('MMM d, yyyy · h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final isDeptAdmin = user.role == AppRole.deptAdmin;
    final canApprove = isDeptAdmin && user.signupCompleted && !user.isApproved;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Text(
          user.fullName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          isDeptAdmin ? 'Department administrator' : 'Village user',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        if (isDeptAdmin) ...[
          const SizedBox(height: 8),
          Chip(label: Text(user.deptAdminStatusLabel)),
        ],
        const SizedBox(height: 20),
        _DetailRow(label: 'First name', value: user.firstName),
        _DetailRow(label: 'Last name', value: user.lastName),
        _DetailRow(label: 'Email', value: user.email),
        _DetailRow(label: 'Mobile', value: user.mobileNumber),
        _DetailRow(label: 'Gender', value: user.gender),
        _DetailRow(label: 'Role', value: user.role.value),
        if (isDeptAdmin)
          _DetailRow(
            label: 'Department',
            value: user.departmentEnum?.label ?? user.department ?? '—',
          ),
        _DetailRow(label: 'Account status', value: user.isBlocked ? 'Blocked' : 'Active'),
        if (isDeptAdmin) ...[
          _DetailRow(
            label: 'Signup completed',
            value: user.signupCompleted ? 'Yes' : 'No (invite pending)',
          ),
          _DetailRow(
            label: 'Admin approved',
            value: user.isApproved ? 'Yes' : 'No',
          ),
        ],
        _DetailRow(label: 'Created', value: _formatDate(user.createdAt)),
        _DetailRow(label: 'Last login', value: _formatDate(user.lastLoginAt)),
        _DetailRow(label: 'User ID', value: user.uid),
        const SizedBox(height: 20),
        if (canApprove && onApprove != null)
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onApprove!();
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Approve department admin'),
          ),
        if (isDeptAdmin && onRemoveAdmin != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onRemoveAdmin!();
            },
            icon: const Icon(Icons.person_remove_outlined),
            label: const Text('Remove admin role'),
          ),
        ],
        if (!isDeptAdmin && onBlock != null && !user.isBlocked) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onBlock!();
            },
            icon: const Icon(Icons.block),
            label: const Text('Block user'),
          ),
        ],
        if (!isDeptAdmin && onUnblock != null && user.isBlocked) ...[
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.pop(context);
              onUnblock!();
            },
            icon: const Icon(Icons.lock_open),
            label: const Text('Unblock user'),
          ),
        ],
        if (!isDeptAdmin && onDelete != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onDelete!();
            },
            icon: Icon(Icons.delete_outline,
                color: Theme.of(context).colorScheme.error),
            label: Text(
              'Delete user',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
