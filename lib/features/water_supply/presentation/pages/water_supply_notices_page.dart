import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/domain/department.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/utils/form_toast.dart';
import '../../domain/department_notice.dart';
import '../water_notice_providers.dart';
import '../widgets/water_notice_form.dart';

/// Water supply hub: status, timing, notices (realtime), contact.
class WaterSupplyNoticesPage extends ConsumerWidget {
  const WaterSupplyNoticesPage({
    super.key,
    this.embeddedInAdmin = false,
  });

  /// When true, used inside dept admin dashboard (no extra scaffold app bar).
  final bool embeddedInAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final canManage = PermissionService.canManageDepartment(
      user,
      VillageDepartment.waterSupply,
    );
    final noticesAsync = ref.watch(waterNoticesStreamProvider);

    final body = noticesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load notices. Run supabase/migrations/20250524_department_notices.sql\n$e',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (notices) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(waterNoticesStreamProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                embeddedInAdmin ? 8 : 16,
                16,
                8,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _StatusSection(latestNotice: notices.isNotEmpty ? notices.first : null),
                  const SizedBox(height: 16),
                  const _SupplyTimingSection(),
                  const SizedBox(height: 16),
                  _ContactSection(),
                  const SizedBox(height: 20),
                  Text(
                    'Latest notices',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
            if (notices.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyNoticesState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final notice = notices[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NoticeCard(
                          notice: notice,
                          canManage: canManage,
                          onEdit: () => _openForm(context, ref, existing: notice),
                          onDelete: () => _delete(context, ref, notice),
                        ),
                      );
                    },
                    childCount: notices.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (embeddedInAdmin) {
      return Scaffold(
        floatingActionButton: canManage
            ? FloatingActionButton.extended(
                onPressed: () => _openForm(context, ref),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add notice'),
              )
            : null,
        body: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Supply'),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add notice'),
            )
          : null,
      body: body,
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    DepartmentNotice? existing,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => WaterNoticeFormSheet(existing: existing),
    );
    if (saved == true) {
      showFormSuccess(
        context,
        existing == null ? 'Notice published.' : 'Notice updated.',
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    DepartmentNotice notice,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete notice?'),
        content: Text('Remove “${notice.title}”?'),
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
      final user = ref.read(authProvider).user;
      if (user == null) return;
      await ref.read(departmentNoticeRepositoryProvider).deleteNotice(
            actor: user,
            noticeId: notice.id,
          );
      if (context.mounted) {
        showFormSuccess(context, 'Notice deleted.');
      }
    } catch (e) {
      if (context.mounted) showFormError(context, e);
    }
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({this.latestNotice});

  final DepartmentNotice? latestNotice;

  @override
  Widget build(BuildContext context) {
    final status = latestNotice?.title ?? 'No active alerts';
    final detail = latestNotice?.description ??
        'Check latest notices below for supply updates.';

    return Card(
      color: AppColors.rice,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.water_drop_rounded, color: AppColors.sky, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current water status',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    status,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplyTimingSection extends StatelessWidget {
  const _SupplyTimingSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supply timing',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const _TimingRow(
              icon: Icons.wb_sunny_outlined,
              label: 'Morning supply',
              value: '6:00 AM – 9:00 AM (typical)',
            ),
            const SizedBox(height: 6),
            const _TimingRow(
              icon: Icons.nights_stay_outlined,
              label: 'Evening supply',
              value: '5:00 PM – 8:00 PM (typical)',
            ),
            const SizedBox(height: 8),
            Text(
              'Times may change during maintenance — see notices for updates.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimingRow extends StatelessWidget {
  const _TimingRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.leaf),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact information',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.phone_outlined),
              title: Text('Water supply helpline'),
              subtitle: Text('Contact your panchayat office for emergencies'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.location_on_outlined),
              title: Text('Naganoor village'),
              subtitle: Text('Report leaks or low pressure to the dept admin'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNoticesState extends StatelessWidget {
  const _EmptyNoticesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No notices yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Water supply updates will appear here when published.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.notice,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  final DepartmentNotice notice;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('MMM d, yyyy · h:mm a').format(notice.createdAt.toLocal());

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    notice.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (canManage)
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'edit') onEdit();
                      if (action == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatted,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(notice.description),
          ],
        ),
      ),
    );
  }
}
