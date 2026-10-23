import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../domain/department_notice.dart';

class DepartmentNoticeDatasource {
  static const table = 'department_notices';

  SupabaseClient? get _client =>
      EnvConfig.supabaseEnabled ? Supabase.instance.client : null;

  static final List<DepartmentNotice> _localNotices = [
    DepartmentNotice(
      id: 'notice-seed-water-1',
      department: DepartmentNotice.waterSupplyDepartment,
      title: 'Weekly Tank Cleaning & Disinfection — Ward 2 Alert',
      description:
          'Overhead tank cleaning scheduled for Tuesday 9:00 AM – 1:00 PM. Ward 2 residents may see reduced water pressure.',
      createdBy: 'water.admin@naganoor.village',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    DepartmentNotice(
      id: 'notice-seed-water-2',
      department: DepartmentNotice.waterSupplyDepartment,
      title: 'Morning Water Supply Timings',
      description:
          'Daily morning drinking water supply: 6:00 AM – 8:30 AM across all village wards. Please store drinking water in clean containers.',
      createdBy: 'water.admin@naganoor.village',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  Future<List<DepartmentNotice>> fetchByDepartment(String department) async {
    final client = _client;
    if (client != null) {
      try {
        final rows = await client
            .from(table)
            .select()
            .eq('department', department)
            .order('created_at', ascending: false);
        final list = (rows as List<dynamic>)
            .map((e) => _fromRow(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }

    return _localNotices
        .where((n) => n.department == department)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Stream<List<DepartmentNotice>> watchByDepartment(String department) async* {
    final client = _client;
    if (client != null) {
      try {
        yield* client
            .from(table)
            .stream(primaryKey: ['id'])
            .eq('department', department)
            .order('created_at', ascending: false)
            .map(
              (rows) => rows
                  .map((e) => _fromRow(Map<String, dynamic>.from(e)))
                  .toList(),
            );
        return;
      } catch (_) {}
    }

    yield await fetchByDepartment(department);
  }

  Future<DepartmentNotice?> fetchById(String id) async {
    final client = _client;
    if (client != null) {
      try {
        final row = await client.from(table).select().eq('id', id).maybeSingle();
        if (row != null) return _fromRow(row);
      } catch (_) {}
    }

    final matches = _localNotices.where((n) => n.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  Future<DepartmentNotice> insert(Map<String, dynamic> row) async {
    final item = DepartmentNotice(
      id: (row['id'] as String?) ?? 'notice-${DateTime.now().millisecondsSinceEpoch}',
      department: (row['department'] as String?) ?? DepartmentNotice.waterSupplyDepartment,
      title: (row['title'] as String?) ?? '',
      description: (row['description'] as String?) ?? '',
      createdBy: row['created_by'] as String?,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    _localNotices.insert(0, item);

    final client = _client;
    if (client != null) {
      try {
        final inserted = await client.from(table).insert(row).select().single();
        return _fromRow(inserted);
      } catch (_) {}
    }

    return item;
  }

  Future<DepartmentNotice> updateRow(
    String id,
    Map<String, dynamic> row,
  ) async {
    final idx = _localNotices.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      final old = _localNotices[idx];
      final updated = DepartmentNotice(
        id: old.id,
        department: old.department,
        title: (row['title'] as String?) ?? old.title,
        description: (row['description'] as String?) ?? old.description,
        createdBy: old.createdBy,
        createdAt: old.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
      _localNotices[idx] = updated;
    }

    final client = _client;
    if (client != null) {
      try {
        final updated =
            await client.from(table).update(row).eq('id', id).select().single();
        return _fromRow(updated);
      } catch (_) {}
    }

    return fetchById(id).then((n) => n!);
  }

  Future<void> delete(String id) async {
    _localNotices.removeWhere((n) => n.id == id);
    final client = _client;
    if (client != null) {
      try {
        await client.from(table).delete().eq('id', id);
      } catch (_) {}
    }
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
