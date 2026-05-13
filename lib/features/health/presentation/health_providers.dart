import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/health_repository_impl.dart';
import '../domain/health_place.dart';
import '../domain/health_repository.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepositoryImpl();
});

final healthPlacesProvider = FutureProvider<List<HealthPlace>>((ref) {
  return ref.watch(healthRepositoryProvider).fetchPlaces();
});

final emergencyContactsProvider = FutureProvider<List<EmergencyContact>>((ref) {
  return ref.watch(healthRepositoryProvider).emergencyContacts();
});
