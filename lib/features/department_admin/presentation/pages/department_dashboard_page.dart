import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/department.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gov_dashboard_card.dart';
import '../../../department_updates/presentation/department_update_providers.dart';

class DepartmentDashboardPage extends ConsumerWidget {
  const DepartmentDashboardPage({super.key, required this.department});

  final VillageDepartment department;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatesAsync = ref.watch(departmentUpdatesProvider(department));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.rice,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                department.label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.forest,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage notices and service updates for your department. '
                'Village residents can view public information without signing in.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        updatesAsync.when(
          data: (items) => GovDashboardCard(
            title: 'Published notices',
            subtitle: '${items.length} active updates',
            icon: Icons.article_outlined,
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(e.toString()),
        ),
        const SizedBox(height: 10),
        const GovDashboardCard(
          title: 'Public village data',
          subtitle: 'Residents can browse Panchayat, temples, weather, and health',
          icon: Icons.visibility_outlined,
        ),
      ],
    );
  }
}
