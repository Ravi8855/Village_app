import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/env_config.dart';
import '../../../../shared/widgets/app_status_widgets.dart';
import '../../domain/temple.dart';
import '../temple_providers.dart';

class TempleDetailPage extends ConsumerWidget {
  const TempleDetailPage({super.key, required this.templeId});

  final String templeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templeAsync = ref.watch(templeDetailProvider(templeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Temple details'),
      ),
      body: templeAsync.when(
        data: (temple) {
          if (temple == null) {
            return const AppError(message: 'Temple not found.');
          }
          return _TempleDetailBody(temple: temple);
        },
        loading: () => const AppLoading(message: 'Loading temple…'),
        error: (e, _) => AppError(
          message: e.toString(),
          onRetry: () => ref.invalidate(templeDetailProvider(templeId)),
        ),
      ),
    );
  }
}

class _TempleDetailBody extends StatelessWidget {
  const _TempleDetailBody({required this.temple});

  final Temple temple;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (temple.imageUrl != null && temple.imageUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              temple.imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          temple.templeName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(temple.description),
        const SizedBox(height: 16),
        _InfoTile(
          icon: Icons.place_outlined,
          label: 'Location',
          value: temple.location,
        ),
        if (temple.timings != null)
          _InfoTile(
            icon: Icons.schedule_outlined,
            label: 'Timings',
            value: temple.timings!,
          ),
        if (temple.festivals != null)
          _InfoTile(
            icon: Icons.celebration_outlined,
            label: 'Festivals',
            value: temple.festivals!,
          ),
        const SizedBox(height: 16),
        _TempleMapPreview(temple: temple),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _openMaps(temple),
          icon: const Icon(Icons.map_outlined),
          label: const Text('Open in Google Maps'),
        ),
      ],
    );
  }

  Future<void> _openMaps(Temple temple) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${temple.latitude},${temple.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TempleMapPreview extends StatelessWidget {
  const _TempleMapPreview({required this.temple});

  final Temple temple;

  @override
  Widget build(BuildContext context) {
    if (!EnvConfig.mapsConfigured) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Add MAPS_API_KEY via --dart-define to preview the map here.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final position = LatLng(temple.latitude, temple.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: position, zoom: 15),
          markers: {
            Marker(
              markerId: MarkerId(temple.id),
              position: position,
              infoWindow: InfoWindow(title: temple.templeName),
            ),
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }
}
