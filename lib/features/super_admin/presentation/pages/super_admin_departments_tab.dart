import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/domain/department.dart';
import '../../../department_admin/presentation/widgets/department_update_form_sheet.dart';
import '../../../department_updates/domain/department_update.dart';
import '../../../department_updates/presentation/department_update_providers.dart';

/// Super-admin: view, add, edit, and delete any department notice.
class SuperAdminDepartmentsTab extends ConsumerWidget {
  const SuperAdminDepartmentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatesAsync = ref.watch(allDepartmentUpdatesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMenu(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add content'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(allDepartmentUpdatesProvider),
        child: updatesAsync.when(
          data: (updates) {
            if (updates.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('No department content yet.')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: updates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final u = updates[index];
                return Card(
                  child: ListTile(
                    title: Text(u.title),
                    subtitle: Text(
                      '${u.department.label} · '
                      '${DateFormat('MMM d, yyyy').format(u.createdAt)}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'edit') {
                          await _openForm(context, ref, u.department, existing: u);
                        } else if (action == 'delete') {
                          await _delete(context, ref, u);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ),
    );
  }

  Future<void> _showAddMenu(BuildContext context, WidgetRef ref) async {
    final dept = await showModalBottomSheet<VillageDepartment>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Choose department',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            for (final d in _managedDepartments)
              ListTile(
                title: Text(d.label),
                onTap: () => Navigator.pop(ctx, d),
              ),
          ],
        ),
      ),
    );
    if (dept != null && context.mounted) {
      await _openForm(context, ref, dept);
    }
  }

  static const _managedDepartments = [
    VillageDepartment.electricity,
    VillageDepartment.waterSupply,
    VillageDepartment.hospital,
    VillageDepartment.bank,
    VillageDepartment.postOffice,
  ];

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    VillageDepartment department, {
    DepartmentUpdate? existing,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DepartmentUpdateFormSheet(
        department: department,
        existing: existing,
        skipPermissionCheck: true,
      ),
    );
    if (saved == true) {
      ref.invalidate(allDepartmentUpdatesProvider);
      ref.invalidate(departmentUpdatesProvider(department));
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    DepartmentUpdate update,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete content?'),
        content: Text('Remove “${update.title}”?'),
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
    if (ok == true) {
      await ref.read(departmentUpdateRepositoryProvider).delete(update.id);
      ref.invalidate(allDepartmentUpdatesProvider);
      ref.invalidate(departmentUpdatesProvider(update.department));
    }
  }
}
