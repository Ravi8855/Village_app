import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';
import '../data/news_local_datasource.dart';
import '../data/news_remote_supabase_datasource.dart';
import '../data/news_repository_impl.dart';
import '../domain/announcement.dart';
import '../domain/announcement_category.dart';
import '../domain/news_repository.dart';

final newsLocalDataSourceProvider = Provider<NewsLocalDataSource>((ref) {
  return NewsLocalDataSource.withSeed();
});

final newsRemoteDataSourceProvider =
    Provider<NewsRemoteSupabaseDataSource>((ref) {
  return NewsRemoteSupabaseDataSource();
});

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepositoryImpl(
    local: ref.watch(newsLocalDataSourceProvider),
    remote: ref.watch(newsRemoteDataSourceProvider),
  );
});

final newsListNotifierProvider =
    AsyncNotifierProvider<NewsListNotifier, List<Announcement>>(
  NewsListNotifier.new,
);

class NewsListNotifier extends AsyncNotifier<List<Announcement>> {
  @override
  Future<List<Announcement>> build() {
    final isAdmin = ref.watch(isNewsAdminProvider);
    return ref
        .read(newsRepositoryProvider)
        .fetchAll(includeInactive: isAdmin);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final isAdmin = ref.read(isNewsAdminProvider);
    state = await AsyncValue.guard(
      () => ref
          .read(newsRepositoryProvider)
          .fetchAll(includeInactive: isAdmin),
    );
  }

  Future<void> addAnnouncement(Announcement announcement) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(newsRepositoryProvider).create(announcement);
      return ref.read(newsRepositoryProvider).fetchAll(
            includeInactive: ref.read(isNewsAdminProvider),
          );
    });
  }

  Future<void> updateAnnouncement(Announcement announcement) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(newsRepositoryProvider).update(announcement);
      return ref.read(newsRepositoryProvider).fetchAll(
            includeInactive: ref.read(isNewsAdminProvider),
          );
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(newsRepositoryProvider).delete(id);
      return ref.read(newsRepositoryProvider).fetchAll(
            includeInactive: ref.read(isNewsAdminProvider),
          );
    });
  }
}

final newsSearchQueryProvider = StateProvider<String>((ref) => '');

final newsCategoryFilterProvider =
    StateProvider<AnnouncementCategory?>((ref) => null);
