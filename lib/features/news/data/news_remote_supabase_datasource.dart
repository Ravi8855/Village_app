import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../domain/announcement.dart';
import '../domain/announcement_category.dart';

class NewsRemoteSupabaseDataSource {
  Future<List<Announcement>> fetchAll({bool includeInactive = false}) async {
    if (!EnvConfig.supabaseEnabled) return const [];

    var query = Supabase.instance.client.from('announcements').select();

    if (!includeInactive) {
      query = query.eq('is_active', true);
    }

    final rows = await query.order('created_at', ascending: false);
    return (rows as List<dynamic>).map(_fromRow).toList();
  }

  Future<void> insert(Announcement a) async {
    if (!EnvConfig.supabaseEnabled) return;
    final row = _toRow(a);
    if (!_looksLikeUuid(a.id)) {
      row.remove('id');
    }
    await Supabase.instance.client.from('announcements').insert(row);
  }

  Future<void> update(Announcement a) async {
    if (!EnvConfig.supabaseEnabled) return;
    await Supabase.instance.client
        .from('announcements')
        .update(_toRow(a))
        .eq('id', a.id);
  }

  Future<void> delete(String id) async {
    if (!EnvConfig.supabaseEnabled) return;
    await Supabase.instance.client.from('announcements').delete().eq('id', id);
  }

  Map<String, dynamic> _toRow(Announcement a) => {
        'id': a.id,
        'title': a.title,
        'description': a.description,
        'category': a.category.name,
        'image_url': a.imageUrl,
        'created_by': a.createdBy,
        'created_at': a.createdAt.toIso8601String(),
        'updated_at': (a.updatedAt ?? a.createdAt).toIso8601String(),
        'is_active': a.isActive,
      };

  Announcement _fromRow(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    return Announcement(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ??
          map['body'] as String? ??
          '',
      category: AnnouncementCategoryX.fromSlug(map['category'] as String?),
      imageUrl: map['image_url'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(
        (map['created_at'] ?? map['published_at']) as String,
      ),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  bool _looksLikeUuid(String id) {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return pattern.hasMatch(id);
  }
}
