import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_status_widgets.dart';
import '../../../../shared/widgets/emergency_contact_row.dart';
import '../../../../shared/widgets/health_facility_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/health_place.dart';
import '../health_providers.dart';
import '../widgets/hospitals_map_view.dart';

class HealthPage extends ConsumerWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(healthPlacesProvider);
    final emergencies = ref.watch(emergencyContactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health & care'),
      ),
      body: places.when(
        data: (list) {
          return emergencies.when(
            data: (contacts) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  SectionHeader(title: 'Nearby on map'),
                  const SizedBox(height: 8),
                  HospitalsMapView(places: list),
                  const SizedBox(height: 16),
                  SectionHeader(title: 'Hospitals & clinics'),
                  const SizedBox(height: 8),
                  ...list.where((p) => p.type != HealthPlaceType.pharmacy).map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: HealthFacilityCard(
                            name: p.name,
                            address: p.address,
                            timings: p.timings,
                            phone: p.phone,
                            mapUrl: Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}',
                            ),
                          ),
                        ),
                      ),
                  const SizedBox(height: 8),
                  SectionHeader(title: 'Medicine shops'),
                  const SizedBox(height: 8),
                  ...list.where((p) => p.type == HealthPlaceType.pharmacy).map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: HealthFacilityCard(
                            name: p.name,
                            address: p.address,
                            timings: p.timings,
                            phone: p.phone,
                            mapUrl: Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}',
                            ),
                          ),
                        ),
                      ),
                  const SizedBox(height: 8),
                  Card(
                    color: AppColors.clay.withValues(alpha: 0.12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.emergency, color: AppColors.clay),
                              const SizedBox(width: 8),
                              Text(
                                'Emergency contacts',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                          const Divider(),
                          ...contacts.map(
                            (c) => EmergencyContactRow(
                              label: c.label,
                              number: c.phone,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const AppLoading(),
            error: (e, _) => AppError(
              message: e.toString(),
              onRetry: () => ref.invalidate(emergencyContactsProvider),
            ),
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => AppError(
          message: e.toString(),
          onRetry: () => ref.invalidate(healthPlacesProvider),
        ),
      ),
    );
  }
}
