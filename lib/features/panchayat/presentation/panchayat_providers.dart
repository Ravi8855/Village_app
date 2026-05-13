import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/panchayat_datasource.dart';
import '../data/panchayat_repository_impl.dart';
import '../domain/panchayat_models.dart';
import '../domain/panchayat_repository.dart';

final panchayatRemoteDataSourceProvider =
    Provider<PanchayatRemoteDataSource>((ref) {
  return PanchayatRemoteDataSource();
});

final panchayatLocalDataSourceProvider =
    Provider<PanchayatLocalDataSource>((ref) {
  return PanchayatLocalDataSource();
});

final panchayatRepositoryProvider = Provider<PanchayatRepository>((ref) {
  return PanchayatRepositoryImpl(
    remote: ref.watch(panchayatRemoteDataSourceProvider),
    local: ref.watch(panchayatLocalDataSourceProvider),
  );
});

final panchayatServicesProvider =
    FutureProvider<List<PanchayatService>>((ref) {
  return ref.watch(panchayatRepositoryProvider).fetchServices();
});

final yojanasProvider = FutureProvider<List<Yojana>>((ref) {
  return ref.watch(panchayatRepositoryProvider).fetchYojanas();
});
