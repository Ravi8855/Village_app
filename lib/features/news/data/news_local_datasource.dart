import '../domain/announcement.dart';
import 'announcement_seeds.dart';

class NewsLocalDataSource {
  NewsLocalDataSource(List<Announcement> seed)
      : _items = List<Announcement>.from(seed);

  final List<Announcement> _items;

  factory NewsLocalDataSource.withSeed() {
    return NewsLocalDataSource(AnnouncementSeeds.all);
  }

  Future<List<Announcement>> readAll({bool includeInactive = false}) async {
    final copy = List<Announcement>.from(_items);
    final filtered = includeInactive
        ? copy
        : copy.where((a) => a.isActive).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  Future<void> append(Announcement announcement) async {
    _items.add(announcement);
  }

  Future<void> replace(Announcement announcement) async {
    final index = _items.indexWhere((e) => e.id == announcement.id);
    if (index >= 0) {
      _items[index] = announcement;
    } else {
      _items.add(announcement);
    }
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}
