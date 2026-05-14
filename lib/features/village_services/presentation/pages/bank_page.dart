import 'package:flutter/material.dart';

import '../../../../core/constants/location_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/health_facility_card.dart';

class BankPage extends StatelessWidget {
  const BankPage({super.key});

  @override
  Widget build(BuildContext context) {
    const baseLat = NaganoorLocation.latitude;
    const baseLng = NaganoorLocation.longitude;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank'),
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
                  const Color(0xFF1565C0).withValues(alpha: 0.9),
                  const Color(0xFF0D47A1).withValues(alpha: 0.95),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Banking in Naganoor',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Branches, timings, and contact details for village banking services.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HealthFacilityCard(
            name: 'State Bank of India — Naganoor',
            address: 'Main road, near bus stand, Naganoor',
            timings: 'Mon–Sat · 10:00am – 4:00pm',
            phone: '08452200111',
            mapUrl: Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=${baseLat + 0.0015},${baseLng - 0.001}',
            ),
          ),
          const SizedBox(height: 10),
          HealthFacilityCard(
            name: 'Grameena Bank — Naganoor',
            address: 'Opposite Panchayat office, Naganoor',
            timings: 'Mon–Sat · 10:00am – 4:00pm',
            phone: '08452200222',
            mapUrl: Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=${baseLat + 0.002},${baseLng + 0.001}',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Carry Aadhaar and passbook for account-related services. ATM services may be available outside branch hours.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.soil,
                ),
          ),
        ],
      ),
    );
  }
}
