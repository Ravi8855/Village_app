import 'temple.dart';

abstract class TempleRepository {
  Future<List<Temple>> fetchAll();
  Future<Temple?> fetchById(String id);
}
