import 'package:flutter/material.dart';

import '../../../../core/constants/location_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/health_facility_card.dart';

class PostmanPage extends StatelessWidget {
  const PostmanPage({super.key});

  @override
  Widget build(BuildContext context) {
    const baseLat = NaganoorLocation.latitude;
    const baseLng = NaganoorLocation.longitude;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post office'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE65100).withValues(alpha: 0.9),
                  const Color(0xFFBF360C).withValues(alpha: 0.95),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'India Post — Naganoor',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Post office timings, delivery support, and village postal services.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HealthFacilityCard(
            name: 'Naganoor Sub Post Office',
            address: 'Bus stand circle, Naganoor',
            timings: 'Mon–Sat · 9:00am – 5:00pm',
            phone: '08452200333',
            mapUrl: Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=${baseLat - 0.001},${baseLng + 0.0015}',
            ),
          ),
          const SizedBox(height: 10),
          HealthFacilityCard(
            name: 'Village delivery contact',
            address: 'Covers Naganoor and nearby hamlets',
            timings: 'Delivery · Mon–Sat',
            phone: '09490033445',
            mapUrl: null,
          ),
          const SizedBox(height: 16),
          Text(
            'For speed post, registered post, and money orders, visit during working hours with valid ID.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.soil,
                ),
          ),
        ],
      ),
    );
  }
}
