import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/role_manager.dart';
import '../../../../models/app_role.dart';
import '../../../../models/app_user_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../storage/user_providers.dart';
import '../widgets/admin_account_detail_sheet.dart';

/// Super-admin: village users only (live Supabase sync).
class SuperAdminUsersTab extends ConsumerStatefulWidget {
  const SuperAdminUsersTab({super.key});

  @override
  ConsumerState<SuperAdminUsersTab> createState() => _SuperAdminUsersTabState();
}

class _SuperAdminUsersTabState extends ConsumerState<SuperAdminUsersTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppUserModel> _filterUsers(List<AppUserModel> all) {
    final villageUsers =
        all.where((u) => u.role == AppRole.user).toList();
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return villageUsers;
    return villageUsers.where((u) {
      return u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.mobileNumber.contains(q);
    }).toList();
  }

  void _openUserDetail(BuildContext context, AppUserModel user) {
    if (RoleManager.isSuperAdminEmail(user.email)) {
      showAdminAccountDetailSheet(context, user: user);
      return;
    }
    showAdminAccountDetailSheet(
      context,
      user: user,
      onBlock: () => _blockUser(context, user, true),
      onUnblock: () => _blockUser(context, user, false),
      onDelete: () => _deleteUser(context, user),
    );
  }

  Future<void> _blockUser(
    BuildContext context,
    AppUserModel user,
    bool block,
  ) async {
    try {
      await ref.read(authProvider.notifier).setUserBlocked(user.uid, block);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _deleteUser(BuildContext context, AppUserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text('Remove ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authProvider.notifier).deleteUser(user.uid);
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
            'Village users',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SearchBar(
            controller: _searchController,
            hintText: 'Search users by name, email, mobile…',
            leading: const Icon(Icons.search),
            onSubmitted: (v) => setState(() => _query = v),
            trailing: [
              if (_query.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (all) {
              final users = _filterUsers(all);
              if (users.isEmpty) {
                return const Center(
                  child: Text('No village users found.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _UserListTile(
                    user: user,
                    onTap: () => _openUserDetail(context, user),
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

class _UserListTile extends StatelessWidget {
  const _UserListTile({
    required this.user,
    required this.onTap,
  });

  final AppUserModel user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(
                  user.firstName.isNotEmpty
                      ? user.firstName[0].toUpperCase()
                      : '?',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(user.email),
                    Text(
                      user.mobileNumber,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (user.isBlocked)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Blocked',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
