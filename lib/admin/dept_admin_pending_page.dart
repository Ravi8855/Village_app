import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../providers/auth_provider.dart';

/// Shown when a department admin account exists but is not yet approved.
class DeptAdminPendingPage extends ConsumerWidget {
  const DeptAdminPendingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending approval'),
        actions: [
          IconButton(
            tooltip: 'Settings / logout',
            onPressed: () => context.push(AppRoutePaths.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Awaiting super admin approval',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              user != null
                  ? 'Your signup for ${user.departmentEnum?.label ?? 'your department'} '
                      '(${user.email}) is complete. The village super admin '
                      'must approve your account before you can edit department '
                      'content.'
                  : 'Your department admin account is pending approval.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () async {
                await ref.read(authProvider.notifier).refreshCurrentUser();
              },
              child: const Text('Check again'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go(AppRoutePaths.home),
              child: const Text('Browse village (read-only)'),
            ),
          ],
        ),
      ),
    );
  }
}
