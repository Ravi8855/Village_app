import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../../../core/domain/department.dart';
import '../domain/department_update.dart';

class DepartmentUpdateDatasource {
  SupabaseClient? get _client =>
      EnvConfig.supabaseEnabled ? Supabase.instance.client : null;

  Future<List<DepartmentUpdate>> fetchByDepartment(
    VillageDepartment department,
  ) async {
    final client = _client;
    if (client == null) return [];

    final rows = await client
        .from('department_updates')
        .select()
        .eq('department', department.dbValue)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).map(_fromRow).toList();
  }

  Future<List<DepartmentUpdate>> fetchAll() async {
    final client = _client;
    if (client == null) return [];

    final rows = await client
        .from('department_updates')
        .select()
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).map(_fromRow).toList();
  }

  Future<void> insert(Map<String, dynamic> row) async {
    await _client?.from('department_updates').insert(row);
  }

  Future<void> updateRow(String id, Map<String, dynamic> row) async {
    await _client?.from('department_updates').update(row).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client?.from('department_updates').delete().eq('id', id);
  }

  Future<String> uploadImage({
    required VillageDepartment department,
    required String filePath,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured.');
    }

    final file = File(filePath);
    final name =
        '${department.dbValue}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await client.storage.from('department-media').upload(name, file);
    return client.storage.from('department-media').getPublicUrl(name);
  }

  DepartmentUpdate _fromRow(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    final dept = VillageDepartment.fromDbValue(map['department'] as String?) ??
        VillageDepartment.panchayat;
    return DepartmentUpdate(
      id: map['id'] as String,
      department: dept,
      title: map['title'] as String,
      description: map['description'] as String,
      imageUrl: map['image_url'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
