import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

class HealthFacilityCard extends StatelessWidget {
  const HealthFacilityCard({
    super.key,
    required this.name,
    required this.address,
    required this.timings,
    required this.phone,
    this.mapUrl,
  });

  final String name;
  final String address;
  final String timings;
  final String phone;
  final Uri? mapUrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_outlined,
                    size: 18, color: AppColors.leaf.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule,
                    size: 18, color: AppColors.clay.withValues(alpha: 0.9)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    timings,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _launch(Uri(scheme: 'tel', path: phone)),
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Call'),
                ),
                if (mapUrl != null)
                  OutlinedButton.icon(
                    onPressed: () => _launch(mapUrl!),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Maps'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
