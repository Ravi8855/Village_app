import 'announcement.dart';

abstract class NewsRepository {
  Future<List<Announcement>> fetchAll({bool includeInactive = false});
  Future<void> create(Announcement announcement);
  Future<void> update(Announcement announcement);
  Future<void> delete(String id);
}
