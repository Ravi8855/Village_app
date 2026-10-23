import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/domain/department.dart';
import '../../../department_admin/presentation/widgets/department_update_form_sheet.dart';
import '../../../department_updates/domain/department_update.dart';
import '../../../department_updates/presentation/department_update_providers.dart';

/// Super-admin: view all village departments, filter notices, add, edit, and delete.
class SuperAdminDepartmentsTab extends ConsumerStatefulWidget {
  const SuperAdminDepartmentsTab({super.key});

  @override
  ConsumerState<SuperAdminDepartmentsTab> createState() =>
      _SuperAdminDepartmentsTabState();
}

class _SuperAdminDepartmentsTabState
    extends ConsumerState<SuperAdminDepartmentsTab> {
  VillageDepartment? _selectedDepartment;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _iconForDept(VillageDepartment dept) {
    return switch (dept) {
      VillageDepartment.waterSupply => Icons.water_drop_rounded,
      VillageDepartment.hospital => Icons.local_hospital_rounded,
      VillageDepartment.panchayat => Icons.account_balance_rounded,
      VillageDepartment.temples => Icons.temple_hindu_rounded,
      VillageDepartment.annabhagya => Icons.rice_bowl_rounded,
      VillageDepartment.bank => Icons.account_balance_wallet_rounded,
      VillageDepartment.postOffice => Icons.local_post_office_rounded,
      VillageDepartment.electricity => Icons.bolt_rounded,
    };
  }

  Color _colorForDept(VillageDepartment dept) {
    return switch (dept) {
      VillageDepartment.waterSupply => const Color(0xFF0288D1),
      VillageDepartment.hospital => const Color(0xFFE53935),
      VillageDepartment.panchayat => const Color(0xFF2E7D32),
      VillageDepartment.temples => const Color(0xFF7B1FA2),
      VillageDepartment.annabhagya => const Color(0xFF558B2F),
      VillageDepartment.bank => const Color(0xFF1565C0),
      VillageDepartment.postOffice => const Color(0xFFE65100),
      VillageDepartment.electricity => const Color(0xFFF57F17),
    };
  }

  List<DepartmentUpdate> _filterUpdates(List<DepartmentUpdate> all) {
    var filtered = all;
    if (_selectedDepartment != null) {
      filtered = filtered.where((u) => u.department == _selectedDepartment).toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered.where((u) {
        return u.title.toLowerCase().contains(q) ||
            u.description.toLowerCase().contains(q) ||
            u.department.label.toLowerCase().contains(q);
      }).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final updatesAsync = ref.watch(allDepartmentUpdatesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMenu(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add content'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(allDepartmentUpdatesProvider),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Village Departments',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            // Department filter chips
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  ChoiceChip(
                    label: const Text('All Departments'),
                    selected: _selectedDepartment == null,
                    onSelected: (val) {
                      if (val) setState(() => _selectedDepartment = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  for (final dept in VillageDepartment.values) ...[
                    ChoiceChip(
                      avatar: Icon(
                        _iconForDept(dept),
                        size: 16,
                        color: _colorForDept(dept),
                      ),
                      label: Text(dept.label),
                      selected: _selectedDepartment == dept,
                      onSelected: (val) {
                        setState(() => _selectedDepartment = val ? dept : null);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SearchBar(
                controller: _searchController,
                hintText: 'Search department notices…',
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
              child: updatesAsync.when(
                data: (all) {
                  final updates = _filterUpdates(all);
                  if (updates.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('No department content found.')),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: updates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final u = updates[index];
                      final color = _colorForDept(u.department);
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.15),
                            child: Icon(
                              _iconForDept(u.department),
                              color: color,
                            ),
                          ),
                          title: Text(
                            u.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                u.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      u.department.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(u.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) async {
                              if (action == 'edit') {
                                await _openForm(context, u.department, existing: u);
                              } else if (action == 'delete') {
                                await _delete(context, u);
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
          ],
        ),
      ),
    );
  }

  Future<void> _showAddMenu(BuildContext context) async {
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
            for (final d in VillageDepartment.values)
              ListTile(
                leading: Icon(_iconForDept(d), color: _colorForDept(d)),
                title: Text(d.label),
                onTap: () => Navigator.pop(ctx, d),
              ),
          ],
        ),
      ),
    );
    if (dept != null && context.mounted) {
      await _openForm(context, dept);
    }
  }

  Future<void> _openForm(
    BuildContext context,
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

