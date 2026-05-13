import '../../../core/config/env_config.dart';
import '../domain/announcement.dart';
import '../domain/news_repository.dart';
import 'news_local_datasource.dart';
import 'news_remote_supabase_datasource.dart';

class NewsRepositoryImpl implements NewsRepository {
  NewsRepositoryImpl({
    required NewsLocalDataSource local,
    required NewsRemoteSupabaseDataSource remote,
  })  : _local = local,
        _remote = remote;

  final NewsLocalDataSource _local;
  final NewsRemoteSupabaseDataSource _remote;

  @override
  Future<List<Announcement>> fetchAll({bool includeInactive = false}) async {
    final local = await _local.readAll(includeInactive: includeInactive);
    if (!EnvConfig.supabaseEnabled) return local;

    try {
      final remote =
          await _remote.fetchAll(includeInactive: includeInactive);
      final map = <String, Announcement>{
        for (final a in remote) a.id: a,
        for (final a in local) a.id: a,
      };
      final merged = map.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return merged;
    } catch (_) {
      return local;
    }
  }

  @override
  Future<void> create(Announcement announcement) async {
    await _local.append(announcement);
    if (EnvConfig.supabaseEnabled) {
      await _remote.insert(announcement);
    }
  }

  @override
  Future<void> update(Announcement announcement) async {
    await _local.replace(announcement);
    if (EnvConfig.supabaseEnabled) {
      await _remote.update(announcement);
    }
  }

  @override
  Future<void> delete(String id) async {
    await _local.remove(id);
    if (EnvConfig.supabaseEnabled) {
      await _remote.delete(id);
    }
  }
}
