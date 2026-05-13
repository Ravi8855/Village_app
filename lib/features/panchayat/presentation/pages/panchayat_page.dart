import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_status_widgets.dart';
import '../../domain/panchayat_models.dart';
import '../panchayat_providers.dart';
import '../widgets/panchayat_item_card.dart';

class PanchayatPage extends ConsumerWidget {
  const PanchayatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(panchayatServicesProvider);
    final yojanas = ref.watch(yojanasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panchayat'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(panchayatServicesProvider);
          ref.invalidate(yojanasProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _PanchayatHero(),
            const SizedBox(height: 16),
            _SectionBlock(
              title: 'Water Supply',
              icon: Icons.water_drop_rounded,
              accent: AppColors.sky,
              asyncItems: services,
              filter: PanchayatSectionType.waterSupply,
            ),
            _SectionBlock(
              title: 'Electricity Supply',
              icon: Icons.bolt_rounded,
              accent: const Color(0xFFF9A825),
              asyncItems: services,
              filter: PanchayatSectionType.electricity,
            ),
            _SectionBlock(
              title: 'Gram KB / Knowledge Board',
              icon: Icons.menu_book_rounded,
              accent: AppColors.leaf,
              asyncItems: services,
              filter: PanchayatSectionType.knowledgeBoard,
            ),
            const SizedBox(height: 8),
            Text(
              'Panchayat Yojanas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            yojanas.when(
              data: (items) {
                if (items.isEmpty) {
                  return const AppEmptyState(
                    title: 'No yojanas listed yet',
                    icon: Icons.account_balance_rounded,
                  );
                }
                return Column(
                  children: [
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PanchayatItemCard(
                          title: item.title,
                          description: item.description,
                          status: item.status.label,
                          date: item.eventDate,
                          imageUrl: item.imageUrl,
                          accent: AppColors.clay,
                        ),
                      ),
                  ],
                );
              },
              loading: () => const AppLoading(message: 'Loading yojanas…'),
              error: (e, _) => AppError(
                message: e.toString(),
                onRetry: () => ref.invalidate(yojanasProvider),
              ),
            ),
            if (!EnvConfig.supabaseEnabled) ...[
              const SizedBox(height: 16),
              Text(
                'Connect Supabase to sync Panchayat updates live.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PanchayatHero extends StatelessWidget {
  const _PanchayatHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.leaf.withValues(alpha: 0.9),
            AppColors.forest.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Naganoor Gram Panchayat',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Water, power, knowledge board, and village schemes — updated for residents.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    required this.icon,
    required this.accent,
    required this.asyncItems,
    required this.filter,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final AsyncValue<List<PanchayatService>> asyncItems;
  final PanchayatSectionType filter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          asyncItems.when(
            data: (items) {
              final filtered =
                  items.where((e) => e.sectionType == filter).toList();
              if (filtered.isEmpty) {
                return AppEmptyState(
                  title: 'No updates in $title',
                  icon: icon,
                );
              }
              return Column(
                children: [
                  for (final item in filtered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PanchayatItemCard(
                        title: item.title,
                        description: item.description,
                        status: item.status.label,
                        date: item.eventDate,
                        imageUrl: item.imageUrl,
                        accent: accent,
                      ),
                    ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (e, _) => Text('Could not load: $e'),
          ),
        ],
      ),
    );
  }
}
