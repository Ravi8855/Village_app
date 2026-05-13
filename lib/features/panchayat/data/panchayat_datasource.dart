import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../domain/panchayat_models.dart';

class PanchayatRemoteDataSource {
  Future<List<PanchayatService>> fetchServices() async {
    if (!EnvConfig.supabaseEnabled) return const [];

    final rows = await Supabase.instance.client
        .from('panchayat_services')
        .select()
        .order('event_date', ascending: false);

    return (rows as List<dynamic>).map(_serviceFromRow).toList();
  }

  Future<List<Yojana>> fetchYojanas() async {
    if (!EnvConfig.supabaseEnabled) return const [];

    final rows = await Supabase.instance.client
        .from('yojanas')
        .select()
        .order('event_date', ascending: false);

    return (rows as List<dynamic>).map(_yojanaFromRow).toList();
  }

  PanchayatService _serviceFromRow(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    return PanchayatService(
      id: map['id'] as String,
      sectionType:
          PanchayatSectionTypeX.fromDb(map['section_type'] as String?),
      title: map['title'] as String,
      description: map['description'] as String,
      imageUrl: map['image_url'] as String?,
      eventDate: map['event_date'] != null
          ? DateTime.parse(map['event_date'] as String)
          : null,
      status: _statusFromString(map['status'] as String?),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Yojana _yojanaFromRow(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    return Yojana(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      imageUrl: map['image_url'] as String?,
      eventDate: map['event_date'] != null
          ? DateTime.parse(map['event_date'] as String)
          : null,
      status: _statusFromString(map['status'] as String?),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  PanchayatItemStatus _statusFromString(String? value) {
    switch (value) {
      case 'scheduled':
        return PanchayatItemStatus.scheduled;
      case 'completed':
        return PanchayatItemStatus.completed;
      case 'cancelled':
        return PanchayatItemStatus.cancelled;
      case 'upcoming':
        return PanchayatItemStatus.upcoming;
      case 'closed':
        return PanchayatItemStatus.closed;
      default:
        return PanchayatItemStatus.active;
    }
  }
}

class PanchayatLocalDataSource {
  List<PanchayatService> get services => [
        PanchayatService(
          id: 'local-water',
          sectionType: PanchayatSectionType.waterSupply,
          title: 'Weekly tank cleaning',
          description:
              'Overhead tank cleaning every Tuesday 9am–1pm. Ward 2 may see low pressure.',
          status: PanchayatItemStatus.scheduled,
          eventDate: DateTime.now().add(const Duration(days: 2)),
        ),
        PanchayatService(
          id: 'local-power',
          sectionType: PanchayatSectionType.electricity,
          title: 'Feeder maintenance notice',
          description:
              '11kV feeder maintenance Thursday 10am–2pm. Charge inverters in advance.',
          status: PanchayatItemStatus.scheduled,
          eventDate: DateTime.now().add(const Duration(days: 4)),
        ),
        PanchayatService(
          id: 'local-kb',
          sectionType: PanchayatSectionType.knowledgeBoard,
          title: 'Gram Sabha minutes',
          description:
              'Annual budget Gram Sabha minutes and action items are published here.',
          status: PanchayatItemStatus.active,
          eventDate: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ];

  List<Yojana> get yojanas => [
        Yojana(
          id: 'local-yojana-1',
          title: 'Haritha Haram tree plantation',
          description:
              'Village-wide sapling drive along tank bund and school grounds.',
          status: PanchayatItemStatus.active,
          eventDate: DateTime.now().add(const Duration(days: 14)),
        ),
        Yojana(
          id: 'local-yojana-2',
          title: 'PM-KISAN awareness camp',
          description:
              'Enrollment help desk at Panchayat office for eligible farmers.',
          status: PanchayatItemStatus.upcoming,
          eventDate: DateTime.now().add(const Duration(days: 10)),
        ),
      ];
}
