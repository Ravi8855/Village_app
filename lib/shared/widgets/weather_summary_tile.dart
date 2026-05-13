import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class WeatherSummaryTile extends StatelessWidget {
  const WeatherSummaryTile({
    super.key,
    required this.dayLabel,
    required this.highC,
    required this.lowC,
    required this.description,
    required this.rainChance,
    this.isToday = false,
  });

  final String dayLabel;
  final double highC;
  final double lowC;
  final String description;
  final int rainChance;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isToday
              ? [AppColors.sky, AppColors.leaf.withValues(alpha: 0.85)]
              : [Colors.white, Colors.white],
        ),
        boxShadow: [
          if (!isToday)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isToday ? Colors.white : AppColors.soil,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '${highC.round()}° / ${lowC.round()}°',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isToday ? Colors.white : AppColors.soil,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isToday
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppColors.soil.withValues(alpha: 0.75),
                ),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                Icons.water_drop_outlined,
                size: 16,
                color: isToday ? Colors.white : AppColors.sky,
              ),
              const SizedBox(width: 4),
              Text(
                '$rainChance% rain',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isToday ? Colors.white : AppColors.sky,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
