import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/env_config.dart';
import '../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '../storage/user_providers.dart';

/// Development-only session and role debug overlay.
class SessionDebugPanel extends ConsumerWidget {
  const SessionDebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) return const SizedBox.shrink();

    final auth = ref.watch(authProvider);
    final user = auth.user;
    final sessionAsync = ref.watch(sessionManagerProvider);
    final repoAsync = ref.watch(userRepositoryProvider);

    final storeLabel = repoAsync.when(
      data: (repo) =>
          repo.usesSupabaseTable ? 'Supabase (global)' : 'Local (this browser)',
      loading: () => '…',
      error: (_, __) => 'error',
    );

    return Material(
      elevation: 6,
      color: Theme.of(context).colorScheme.inverseSurface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  'Session debug',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _line(
              context,
              'Role',
              user?.role.value ?? '—',
            ),
            _line(
              context,
              'Email',
              user?.email ?? '—',
            ),
            _line(
              context,
              'UID',
              user?.uid ?? sessionAsync.valueOrNull?.sessionUid ?? '—',
            ),
            _line(
              context,
              'User store',
              storeLabel,
            ),
            _line(
              context,
              'Supabase',
              EnvConfig.supabaseEnabled ? 'enabled' : 'off',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: auth.isLoggedIn
                      ? () async {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) {
                            context.go(AppRoutePaths.signup);
                          }
                        }
                      : null,
                  child: const Text('Quick logout'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).refreshCurrentUser();
                  },
                  child: const Text('Refresh user'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onInverseSurface,
            ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Wraps a screen body with the debug panel pinned to the bottom.
class SessionDebugHost extends StatelessWidget {
  const SessionDebugHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        const Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: SessionDebugPanel(),
        ),
      ],
    );
  }
}
