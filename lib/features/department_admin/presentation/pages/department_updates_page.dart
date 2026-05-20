import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/domain/department.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../department_updates/domain/department_update.dart';
import '../../../department_updates/presentation/department_update_providers.dart';
import '../widgets/department_update_form_sheet.dart';

class DepartmentUpdatesPage extends ConsumerWidget {
  const DepartmentUpdatesPage({super.key, required this.department});

  final VillageDepartment department;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatesAsync = ref.watch(departmentUpdatesProvider(department));
    final canEdit = PermissionService.canManageDepartment(
      ref.watch(authProvider).user,
      department,
    );

    return Scaffold(
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add notice'),
      )
          : null,
      body: updatesAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No notices yet. Tap Add notice to publish.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(departmentUpdatesProvider(department)),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final u = items[index];
                return _UpdateCard(
                  update: u,
                  canEdit: canEdit,
                  onEdit: () => _openForm(context, ref, existing: u),
                  onDelete: () => _delete(context, ref, u),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    DepartmentUpdate? existing,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DepartmentUpdateFormSheet(
        department: department,
        existing: existing,
      ),
    );
    if (saved == true) {
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
        title: const Text('Delete notice?'),
        content: Text('Remove “${update.title}”?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      try {
        PermissionService.assertCanManageDepartment(
          ref.read(authProvider).user,
          department,
        );
        await ref.read(departmentUpdateRepositoryProvider).delete(update.id);
        ref.invalidate(departmentUpdatesProvider(department));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.update,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  final DepartmentUpdate update;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (update.imageUrl != null && update.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    update.imageUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            Text(
              update.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, yyyy').format(update.createdAt),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Text(update.description),
            if (canEdit)
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
