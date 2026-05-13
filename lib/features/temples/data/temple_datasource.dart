import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../domain/temple.dart';

class TempleRemoteDataSource {
  Future<List<Temple>> fetchAll() async {
    if (!EnvConfig.supabaseEnabled) return const [];

    final rows = await Supabase.instance.client
        .from('temples')
        .select()
        .order('temple_name');

    return (rows as List<dynamic>).map(_fromRow).toList();
  }

  Future<Temple?> fetchById(String id) async {
    if (!EnvConfig.supabaseEnabled) return null;

    final row = await Supabase.instance.client
        .from('temples')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (row == null) return null;
    return _fromRow(row);
  }

  Temple _fromRow(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    return Temple(
      id: map['id'] as String,
      templeName: map['temple_name'] as String,
      description: map['description'] as String,
      imageUrl: map['image_url'] as String?,
      location: map['location'] as String,
      timings: map['timings'] as String?,
      festivals: map['festivals'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}

class TempleLocalDataSource {
  List<Temple> get all => const [
        Temple(
          id: 'seed-sharanabasveswara',
          templeName: 'Sharanabasveswara Temple',
          description: 'Historic Shiva temple at the heart of Naganoor village.',
          location: 'Main temple street, Naganoor',
          timings: '6:00 AM – 8:00 PM',
          festivals: 'Maha Shivaratri, Karthika Masam',
          latitude: 17.3850,
          longitude: 78.4867,
        ),
        Temple(
          id: 'seed-shoguruveswara',
          templeName: 'Shoguruveswara Temple',
          description:
              'Community temple known for morning abhishekam and local gatherings.',
          location: 'Shoguruveswara Gudi, Naganoor',
          timings: '5:30 AM – 7:30 PM',
          festivals: 'Ugadi, Sankranti',
          latitude: 17.3862,
          longitude: 78.4875,
        ),
        Temple(
          id: 'seed-karappa',
          templeName: 'Karappa Mutta Temple',
          description: 'Sacred mutta with annual jatara and village processions.',
          location: 'Karappa Mutta, Naganoor outskirts',
          timings: '6:00 AM – 7:00 PM',
          festivals: 'Karappa Jatara',
          latitude: 17.3840,
          longitude: 78.4890,
        ),
        Temple(
          id: 'seed-kenchamma',
          templeName: 'Kenchamma Devi Temple',
          description: 'Grama devata shrine visited during harvest season.',
          location: 'Kenchamma Gudi, Ward 3',
          timings: '6:00 AM – 8:30 PM',
          festivals: 'Bonalu, Ashada Masam',
          latitude: 17.3875,
          longitude: 78.4855,
        ),
        Temple(
          id: 'seed-dyvamma',
          templeName: 'Dyvamma Devi Temple',
          description: 'Village deity temple with evening aarti and festival lamps.',
          location: 'Dyvamma Gudi, Naganoor',
          timings: '6:00 AM – 8:00 PM',
          festivals: 'Dussehra, Deepavali',
          latitude: 17.3835,
          longitude: 78.4848,
        ),
        Temple(
          id: 'seed-marayamma',
          templeName: 'Marayamma Devi Temple',
          description: 'Protector goddess temple near the village tank bund.',
          location: 'Marayamma Gudi, tank bund road',
          timings: '5:45 AM – 7:45 PM',
          festivals: 'Bonalu, village fair',
          latitude: 17.3880,
          longitude: 78.4882,
        ),
      ];
}
