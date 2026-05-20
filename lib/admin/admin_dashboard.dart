import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/permissions/permission_service.dart';
import '../core/router/app_router.dart';
import '../features/super_admin/presentation/pages/super_admin_admins_tab.dart';
import '../features/super_admin/presentation/pages/super_admin_departments_tab.dart';
import '../features/super_admin/presentation/pages/super_admin_users_tab.dart';
import '../models/app_department.dart';
import '../providers/auth_provider.dart';
import '../shared/utils/form_toast.dart';
import '../shared/utils/form_validators.dart';

/// Super-admin dashboard: users, department admins, and all department content.
class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _index = 0;

  static const _tabs = [
    ('Users', Icons.people_outline),
    ('Dept admins', Icons.admin_panel_settings_outlined),
    ('Content', Icons.apartment_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (!PermissionService.canAccessSuperAdminDashboard(user)) {
      return const Scaffold(
        body: Center(child: Text('Super admin access required.')),
      );
    }

    final pages = [
      const SuperAdminUsersTab(),
      SuperAdminAdminsTab(onCreateAdmin: () => _showCreateDeptAdmin(context)),
      const SuperAdminDepartmentsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super admin'),
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
      floatingActionButton: _index == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateDeptAdmin(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Create dept admin'),
            )
          : null,
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.$2),
              label: tab.$1,
            ),
        ],
      ),
    );
  }

  Future<void> _showCreateDeptAdmin(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _CreateDeptAdminSheet(),
    );
  }
}

class _CreateDeptAdminSheet extends ConsumerStatefulWidget {
  const _CreateDeptAdminSheet();

  @override
  ConsumerState<_CreateDeptAdminSheet> createState() =>
      _CreateDeptAdminSheetState();
}

class _CreateDeptAdminSheetState extends ConsumerState<_CreateDeptAdminSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _tempPasswordController = TextEditingController();
  AppDepartment _department = AppDepartment.electricity;
  String _gender = 'Male';
  bool _saving = false;
  bool _showValidation = false;

  static const _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _tempPasswordController.dispose();
    super.dispose();
  }

  bool _validateAllFields() {
    setState(() => _showValidation = true);
    return _formKey.currentState?.validate() ?? false;
  }

  Future<void> _save() async {
    if (!_validateAllFields()) return;

    final mobile = _mobileController.text.replaceAll(RegExp(r'\D'), '');

    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).createDepartmentAdmin(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            mobileNumber: mobile,
            email: _emailController.text.trim(),
            gender: _gender,
            department: _department,
            temporaryPassword: _tempPasswordController.text,
          );
      if (mounted) {
        Navigator.pop(context, true);
        showFormSuccess(
          context,
          'Department admin created. Share the temporary password, then '
          'approve them after they activate via Admin sign-in.',
        );
      }
    } catch (e) {
      if (mounted) showFormError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: _showValidation
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create department admin',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Assign a temporary password. After you approve them, they sign in '
            'at Admin sign-in, verify email once with OTP, then use password only.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _firstNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'First name *',
              border: OutlineInputBorder(),
            ),
            validator: FormValidators.firstName,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Last name *',
              border: OutlineInputBorder(),
            ),
            validator: FormValidators.lastName,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              labelText: 'Mobile *',
              prefixText: '+91 ',
              border: OutlineInputBorder(),
            ),
            validator: FormValidators.mobile,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email *',
              border: OutlineInputBorder(),
            ),
            validator: FormValidators.email,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: const InputDecoration(
              labelText: 'Gender *',
              border: OutlineInputBorder(),
            ),
            items: _genders
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _gender = v);
            },
            validator: FormValidators.gender,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _tempPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Temporary password *',
              hintText: 'Min. 8 characters — share securely',
              border: OutlineInputBorder(),
            ),
            validator: FormValidators.temporaryPassword,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AppDepartment>(
            value: _department,
            decoration: const InputDecoration(
              labelText: 'Department *',
              border: OutlineInputBorder(),
            ),
            items: AppDepartment.values
                .map(
                  (d) => DropdownMenuItem(value: d, child: Text(d.label)),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _department = v);
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create admin'),
          ),
        ],
          ),
        ),
      ),
    );
  }
}
