import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../providers/auth_provider.dart';

/// Settings screen — logout is available here only.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (user != null) ...[
            ListTile(
              title: Text(user.fullName),
              subtitle: Text('${user.email}\nRole: ${user.role.value}'),
              isThreeLine: true,
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sign out'),
            subtitle: const Text(
              'You will need email OTP again on this device.',
            ),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutePaths.signup);
            },
          ),
        ],
      ),
    );
  }
}
