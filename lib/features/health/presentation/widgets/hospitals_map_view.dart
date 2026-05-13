import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/constants/location_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/health_place.dart';

class HospitalsMapView extends StatefulWidget {
  const HospitalsMapView({super.key, required this.places});

  final List<HealthPlace> places;

  @override
  State<HospitalsMapView> createState() => _HospitalsMapViewState();
}

class _HospitalsMapViewState extends State<HospitalsMapView> {
  late final CameraPosition _camera = CameraPosition(
    target: LatLng(
      NaganoorLocation.latitude,
      NaganoorLocation.longitude,
    ),
    zoom: 13.6,
  );

  @override
  Widget build(BuildContext context) {
    if (!EnvConfig.mapsConfigured) {
      return _MapsPlaceholder(places: widget.places);
    }

    final markers = widget.places.map((p) {
      return Marker(
        markerId: MarkerId(p.id),
        position: LatLng(p.latitude, p.longitude),
        infoWindow: InfoWindow(title: p.name, snippet: p.address),
      );
    }).toSet();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: GoogleMap(
          initialCameraPosition: _camera,
          markers: markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }
}

class _MapsPlaceholder extends StatelessWidget {
  const _MapsPlaceholder({required this.places});

  final List<HealthPlace> places;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.sky.withValues(alpha: 0.25),
            AppColors.leaf.withValues(alpha: 0.2),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Google Maps',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add MAPS_API_KEY via --dart-define to show the live village map. '
            'Until then, use the Maps buttons on each card.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Text(
            '${places.length} locations pinned around Naganoor',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}
