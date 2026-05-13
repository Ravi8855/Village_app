import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_status_widgets.dart';
import '../temple_providers.dart';
import '../widgets/temple_card.dart';

class TemplesListPage extends ConsumerWidget {
  const TemplesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temples = ref.watch(templesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Temples'),
      ),
      body: temples.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              title: 'No temples listed yet',
              icon: Icons.temple_hindu_rounded,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(templesListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6A1B9A).withValues(alpha: 0.85),
                          AppColors.forest.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                    child: Text(
                      'Sacred places of Naganoor — timings, festivals, and directions.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  );
                }
                final temple = items[index - 1];
                return TempleCard(
                  temple: temple,
                  onTap: () => context.push(
                    AppRoutePaths.templeDetail(temple.id),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const AppLoading(message: 'Loading temples…'),
        error: (e, _) => AppError(
          message: e.toString(),
          onRetry: () => ref.invalidate(templesListProvider),
        ),
      ),
    );
  }
}
