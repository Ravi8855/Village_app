import 'panchayat_models.dart';

abstract class PanchayatRepository {
  Future<List<PanchayatService>> fetchServices();
  Future<List<Yojana>> fetchYojanas();
}
