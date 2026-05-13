import '../../../core/config/env_config.dart';
import '../domain/temple.dart';
import '../domain/temple_repository.dart';
import 'temple_datasource.dart';

class TempleRepositoryImpl implements TempleRepository {
  TempleRepositoryImpl({
    required TempleRemoteDataSource remote,
    required TempleLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final TempleRemoteDataSource _remote;
  final TempleLocalDataSource _local;

  @override
  Future<List<Temple>> fetchAll() async {
    if (!EnvConfig.supabaseEnabled) return _local.all;
    try {
      final remote = await _remote.fetchAll();
      return remote.isEmpty ? _local.all : remote;
    } catch (_) {
      return _local.all;
    }
  }

  @override
  Future<Temple?> fetchById(String id) async {
    Temple? fromLocal() {
      for (final temple in _local.all) {
        if (temple.id == id) return temple;
      }
      return null;
    }

    if (!EnvConfig.supabaseEnabled) return fromLocal();
    try {
      final remote = await _remote.fetchById(id);
      return remote ?? fromLocal();
    } catch (_) {
      return fromLocal();
    }
  }
}
