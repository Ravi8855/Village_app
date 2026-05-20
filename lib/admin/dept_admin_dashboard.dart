import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/permissions/permission_service.dart';
import '../core/router/app_router.dart';
import '../core/domain/department.dart';
import '../features/department_admin/presentation/pages/department_dashboard_page.dart';
import '../features/department_admin/presentation/pages/department_updates_page.dart';
import '../features/water_supply/presentation/pages/water_supply_notices_page.dart';
import '../providers/auth_provider.dart';

/// Department administrator dashboard for assigned department only.
class DeptAdminDashboard extends ConsumerStatefulWidget {
  const DeptAdminDashboard({super.key});

  @override
  ConsumerState<DeptAdminDashboard> createState() => _DeptAdminDashboardState();
}

class _DeptAdminDashboardState extends ConsumerState<DeptAdminDashboard> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (!PermissionService.canAccessDeptAdminDashboard(user)) {
      return const Scaffold(
        body: Center(child: Text('Department admin access required.')),
      );
    }

    final department = PermissionService.villageDepartmentForUser(user!);
    if (department == null) {
      return const Scaffold(
        body: Center(child: Text('No department assigned to this account.')),
      );
    }

    final noticesPage = department == VillageDepartment.waterSupply
        ? const WaterSupplyNoticesPage(embeddedInAdmin: true)
        : DepartmentUpdatesPage(department: department);

    final pages = [
      DepartmentDashboardPage(department: department),
      noticesPage,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${department.label} admin'),
        actions: [
          IconButton(
            tooltip: 'Village home',
            onPressed: () => context.go(AppRoutePaths.home),
            icon: const Icon(Icons.home_outlined),
          ),
          IconButton(
            tooltip: 'Settings / logout',
            onPressed: () => context.push(AppRoutePaths.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            label: 'Notices',
          ),
        ],
      ),
    );
  }
}
