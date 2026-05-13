import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/core_providers.dart';
import '../application/app_update_service.dart';
import '../data/app_update_preferences_store.dart';
import '../data/app_update_repository_impl.dart';
import '../data/in_app_update_datasource.dart';
import '../data/play_store_metadata_datasource.dart';
import '../domain/app_update_repository.dart';

final appUpdatePreferencesStoreProvider =
    Provider<AppUpdatePreferencesStore>((ref) {
  return AppUpdatePreferencesStore();
});

final inAppUpdateDataSourceProvider = Provider<InAppUpdateDataSource>((ref) {
  return InAppUpdateDataSource();
});

final playStoreMetadataDataSourceProvider =
    Provider<PlayStoreMetadataDataSource>((ref) {
  return PlayStoreMetadataDataSource(ref.watch(httpClientProvider).client);
});

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>((ref) {
  return AppUpdateRepositoryImpl(
    playCoreDataSource: ref.watch(inAppUpdateDataSourceProvider),
    playStoreMetadataDataSource: ref.watch(playStoreMetadataDataSourceProvider),
    preferencesStore: ref.watch(appUpdatePreferencesStoreProvider),
  );
});

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService(ref.watch(appUpdateRepositoryProvider));
});

final appUpdateSupportedProvider = Provider<bool>((ref) {
  return ref.watch(appUpdateRepositoryProvider).isSupported;
});
