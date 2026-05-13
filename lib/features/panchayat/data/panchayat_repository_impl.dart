import '../../../core/config/env_config.dart';
import '../domain/panchayat_models.dart';
import '../domain/panchayat_repository.dart';
import 'panchayat_datasource.dart';

class PanchayatRepositoryImpl implements PanchayatRepository {
  PanchayatRepositoryImpl({
    required PanchayatRemoteDataSource remote,
    required PanchayatLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final PanchayatRemoteDataSource _remote;
  final PanchayatLocalDataSource _local;

  @override
  Future<List<PanchayatService>> fetchServices() async {
    if (!EnvConfig.supabaseEnabled) return _local.services;
    try {
      final remote = await _remote.fetchServices();
      return remote.isEmpty ? _local.services : remote;
    } catch (_) {
      return _local.services;
    }
  }

  @override
  Future<List<Yojana>> fetchYojanas() async {
    if (!EnvConfig.supabaseEnabled) return _local.yojanas;
    try {
      final remote = await _remote.fetchYojanas();
      return remote.isEmpty ? _local.yojanas : remote;
    } catch (_) {
      return _local.yojanas;
    }
  }
}
