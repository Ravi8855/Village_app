import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/annabhagya_models.dart';

class DistributionScheduleCard extends StatelessWidget {
  const DistributionScheduleCard({
    super.key,
    required this.schedule,
  });

  final DistributionSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('EEEE, MMM d, yyyy').format(schedule.distributionDate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(
              icon: Icons.calendar_month_rounded,
              label: 'Distribution date',
              value: dateLabel,
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.schedule_rounded,
              label: 'Timing',
              value: schedule.timeSlot,
            ),
            const SizedBox(height: 16),
            Text(
              'Items distributed',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in schedule.items)
                  Chip(
                    avatar: Icon(
                      Icons.grain_rounded,
                      size: 18,
                      color: AppColors.leaf.withValues(alpha: 0.9),
                    ),
                    label: Text('${item.itemNameKn} · ${item.itemName}'),
                    backgroundColor: AppColors.rice,
                    side: BorderSide(color: AppColors.leaf.withValues(alpha: 0.2)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.sky),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
