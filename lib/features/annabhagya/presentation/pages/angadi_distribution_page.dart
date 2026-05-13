import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/annabhagya_data.dart';
import '../widgets/distribution_schedule_card.dart';

class AngadiDistributionPage extends StatelessWidget {
  const AngadiDistributionPage({
    super.key,
    required this.angadiId,
  });

  final String angadiId;

  @override
  Widget build(BuildContext context) {
    final angadi = AnnabhagyaData.angadiById(angadiId);
    final schedule = AnnabhagyaData.distributionSchedule;

    if (angadi == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Angadi')),
        body: const Center(child: Text('Angadi not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(angadi.name),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.rice,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.leaf.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  angadi.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(angadi.location),
                const SizedBox(height: 8),
                Text(
                  '${AnnabhagyaData.schemeTitle} — rice & grains distribution schedule',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'When rice & grains will be distributed',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Same schedule applies at Deshapande Angadi and Gowdaru Angadi.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          DistributionScheduleCard(schedule: schedule),
        ],
      ),
    );
  }
}
