import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/location_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/quick_action_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/village_hero_banner.dart';
import '../../../../shared/widgets/weather_summary_tile.dart';
import '../../../news/domain/announcement.dart';
import '../../../news/presentation/news_providers.dart';
import '../../../weather/data/weather_code_descriptions.dart';
import '../../../weather/presentation/weather_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(weeklyForecastProvider);
    final news = ref.watch(newsListNotifierProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverToBoxAdapter(
              child: VillageHeroBanner(
                title: NaganoorLocation.villageName,
                subtitle: 'Community updates, weather, and care — in one place.',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: weather.when(
                data: (days) {
                  if (days.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final today = days.first;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Today’s weather',
                        actionLabel: 'Details',
                        onAction: () => context.go(AppRoutePaths.weather),
                      ),
                      SizedBox(
                        height: 150,
                        child: WeatherSummaryTile(
                          dayLabel: DateFormat('EEEE, MMM d').format(today.date),
                          highC: today.maxTempC,
                          lowC: today.minTempC,
                          description:
                              WeatherCodeDescriptions.label(today.weatherCode),
                          rainChance: today.rainChancePercent,
                          isToday: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Quick actions',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
              ),
              delegate: SliverChildListDelegate([
                QuickActionCard(
                  icon: Icons.water_drop_rounded,
                  label: 'Water supply',
                  accent: AppColors.sky,
                  onTap: () => context.push(AppRoutePaths.waterSupply),
                ),
                QuickActionCard(
                  icon: Icons.local_hospital_rounded,
                  label: 'Hospital',
                  accent: AppColors.clay,
                  onTap: () => context.go(AppRoutePaths.health),
                ),
                QuickActionCard(
                  icon: Icons.account_balance_rounded,
                  label: 'Panchayat',
                  accent: AppColors.leaf,
                  onTap: () => context.push(AppRoutePaths.panchayat),
                ),
                QuickActionCard(
                  icon: Icons.temple_hindu_rounded,
                  label: 'Temples',
                  accent: const Color(0xFF6A1B9A),
                  onTap: () => context.push(AppRoutePaths.temples),
                ),
                QuickActionCard(
                  icon: Icons.agriculture_rounded,
                  label: 'Farming',
                  accent: const Color(0xFF6D4C41),
                  onTap: () => context.go(AppRoutePaths.weather),
                ),
                QuickActionCard(
                  icon: Icons.rice_bowl_rounded,
                  label: 'ಅನ್ನಭಾಗ್ಯ ಯೋಜನೆ',
                  accent: const Color(0xFF558B2F),
                  onTap: () => context.push(AppRoutePaths.annabhagya),
                ),
                QuickActionCard(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Bank',
                  accent: const Color(0xFF1565C0),
                  onTap: () => context.push(AppRoutePaths.bank),
                ),
                QuickActionCard(
                  icon: Icons.local_post_office_rounded,
                  label: 'Post office',
                  accent: const Color(0xFFE65100),
                  onTap: () => context.push(AppRoutePaths.postman),
                ),
                QuickActionCard(
                  icon: Icons.bolt_rounded,
                  label: 'Electricity',
                  accent: const Color(0xFFF9A825),
                  onTap: () => context.push(AppRoutePaths.electricity),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Latest announcements',
                actionLabel: 'View all',
                onAction: () => context.go(AppRoutePaths.news),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: news.when(
              data: (items) {
                final top = items.take(3).toList();
                if (top.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Text('No announcements yet.'),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final a = top[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AnnouncementPreviewTile(announcement: a),
                      );
                    },
                    childCount: top.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Text('Could not load news: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementPreviewTile extends StatelessWidget {
  const _AnnouncementPreviewTile({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          announcement.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          DateFormat('MMM d · h:mm a').format(announcement.createdAt),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.go(AppRoutePaths.news),
      ),
    );
  }
}
