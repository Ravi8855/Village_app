import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/temple_datasource.dart';
import '../data/temple_repository_impl.dart';
import '../domain/temple.dart';
import '../domain/temple_repository.dart';

final templeRemoteDataSourceProvider = Provider<TempleRemoteDataSource>((ref) {
  return TempleRemoteDataSource();
});

final templeLocalDataSourceProvider = Provider<TempleLocalDataSource>((ref) {
  return TempleLocalDataSource();
});

final templeRepositoryProvider = Provider<TempleRepository>((ref) {
  return TempleRepositoryImpl(
    remote: ref.watch(templeRemoteDataSourceProvider),
    local: ref.watch(templeLocalDataSourceProvider),
  );
});

final templesListProvider = FutureProvider<List<Temple>>((ref) {
  return ref.watch(templeRepositoryProvider).fetchAll();
});

final templeDetailProvider =
    FutureProvider.family<Temple?, String>((ref, id) {
  return ref.watch(templeRepositoryProvider).fetchById(id);
});
