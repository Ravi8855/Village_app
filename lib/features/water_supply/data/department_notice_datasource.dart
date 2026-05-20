import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../domain/department_notice.dart';

class DepartmentNoticeDatasource {
  static const table = 'department_notices';

  SupabaseClient? get _client =>
      EnvConfig.supabaseEnabled ? Supabase.instance.client : null;

  Future<List<DepartmentNotice>> fetchByDepartment(String department) async {
    final client = _client;
    if (client == null) return [];

    final rows = await client
        .from(table)
        .select()
        .eq('department', department)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((e) => _fromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Stream<List<DepartmentNotice>> watchByDepartment(String department) {
    final client = _client;
    if (client == null) {
      return Stream.value(const []);
    }

    return client
        .from(table)
        .stream(primaryKey: ['id'])
        .eq('department', department)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map((e) => _fromRow(Map<String, dynamic>.from(e)))
              .toList(),
        );
  }

  Future<DepartmentNotice?> fetchById(String id) async {
    final client = _client;
    if (client == null) return null;

    final row = await client.from(table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return _fromRow(row);
  }

  Future<DepartmentNotice> insert(Map<String, dynamic> row) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured.');
    }

    final inserted = await client.from(table).insert(row).select().single();
    return _fromRow(inserted);
  }

  Future<DepartmentNotice> updateRow(
    String id,
    Map<String, dynamic> row,
  ) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured.');
    }

    final updated =
        await client.from(table).update(row).eq('id', id).select().single();
    return _fromRow(updated);
  }

  Future<void> delete(String id) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured.');
    }
    await client.from(table).delete().eq('id', id);
  }

  DepartmentNotice _fromRow(Map<String, dynamic> map) {
    return DepartmentNotice(
      id: map['id'] as String,
      department: map['department'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      createdBy: map['created_by'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
