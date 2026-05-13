import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/location_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_status_widgets.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/weather_summary_tile.dart';
import '../../data/weather_code_descriptions.dart';
import '../../domain/crop_advisor.dart';
import '../weather_providers.dart';

class WeatherPage extends ConsumerWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecast = ref.watch(weeklyForecastProvider);
    final tips = CropAdvisor.tips();
    final crops = CropAdvisor.suggestionsFor(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather & farming'),
      ),
      body: forecast.when(
        data: (days) {
          if (days.isEmpty) {
            return const Center(child: Text('No forecast data available.'));
          }
          final maxChance =
              days.map((e) => e.rainChancePercent).reduce((a, b) => a > b ? a : b);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(weeklyForecastProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  'Forecasts use Open-Meteo near ${NaganoorLocation.villageName}. '
                  'Adjust coordinates in `location_constants.dart` for finer accuracy.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SectionHeader(title: '7-day outlook'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 170,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final d = days[index];
                      final label = DateFormat('EEE').format(d.date);
                      return SizedBox(
                        width: 150,
                        child: WeatherSummaryTile(
                          dayLabel: label,
                          highC: d.maxTempC,
                          lowC: d.minTempC,
                          description: WeatherCodeDescriptions.label(d.weatherCode),
                          rainChance: d.rainChancePercent,
                          isToday: index == 0,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SectionHeader(title: 'Rain readiness'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.water_drop, color: AppColors.sky, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Next few days show up to $maxChance% '
                            'rain chance. Plan irrigation and field drainage accordingly.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SectionHeader(title: 'Crop suggestions (seasonal)'),
                const SizedBox(height: 8),
                ...crops.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.spa_outlined),
                        title: Text(line),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SectionHeader(title: 'Farming tips'),
                const SizedBox(height: 8),
                ...tips.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      color: AppColors.rice,
                      child: ListTile(
                        leading: const Icon(Icons.eco_outlined),
                        title: Text(line),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const AppLoading(message: 'Pulling forecast…'),
        error: (e, _) => AppError(
          message: e.toString(),
          onRetry: () => ref.invalidate(weeklyForecastProvider),
        ),
      ),
    );
  }
}
