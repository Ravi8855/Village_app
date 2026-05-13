import '../domain/announcement.dart';
import '../domain/announcement_category.dart';

class AnnouncementSeeds {
  static List<Announcement> get all => [
        Announcement(
          id: 'seed-1',
          title: 'Water supply maintenance — Tuesday',
          description:
              'Main overhead tank will be cleaned 9am–1pm. Low pressure expected in Ward 2.',
          category: AnnouncementCategory.waterSupply,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        Announcement(
          id: 'seed-2',
          title: 'Scheduled power interruption',
          description:
              '11kV feeder maintenance on Thursday 10am–2pm. Inverter users are advised to charge early.',
          category: AnnouncementCategory.electricity,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Announcement(
          id: 'seed-3',
          title: 'Gram Sabha — annual budget discussion',
          description:
              'All residents are invited to the Panchayat office on Sunday at 4pm for the Gram Sabha.',
          category: AnnouncementCategory.panchayat,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Announcement(
          id: 'seed-4',
          title: 'Bonalu procession route',
          description:
              'Festival procession begins near the temple tank at 6pm. Volunteers requested for crowd support.',
          category: AnnouncementCategory.temples,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];
}
