import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../../../core/domain/department.dart';
import '../domain/department_update.dart';

class DepartmentUpdateDatasource {
  SupabaseClient? get _client =>
      EnvConfig.supabaseEnabled ? Supabase.instance.client : null;

  static final List<DepartmentUpdate> _localUpdates = [
    DepartmentUpdate(
      id: 'upd-seed-water-1',
      department: VillageDepartment.waterSupply,
      title: 'Weekly Overhead Tank Cleaning & Disinfection',
      description:
          'Overhead tank maintenance scheduled for Tuesday 9:00 AM – 1:00 PM. Ward 2 and Ward 3 may experience low water pressure during this time.',
      createdBy: 'water.admin@naganoor.village',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    DepartmentUpdate(
      id: 'upd-seed-elec-1',
      department: VillageDepartment.electricity,
      title: '11kV Feeder Line Maintenance Notice',
      description:
          'Scheduled maintenance on Thursday from 10:00 AM to 2:00 PM. Agricultural pump 3-phase supply will resume at 2:30 PM.',
      createdBy: 'power.admin@naganoor.village',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DepartmentUpdate(
      id: 'upd-seed-health-1',
      department: VillageDepartment.hospital,
      title: 'Free Rural Eye & Health Checkup Camp',
      description:
          'Primary Health Centre (PHC) Naganoor is conducting a free eye screening, BP checkup, and medicine distribution camp this Saturday 9 AM – 3 PM.',
      createdBy: 'health.admin@naganoor.village',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    DepartmentUpdate(
      id: 'upd-seed-bank-1',
      department: VillageDepartment.bank,
      title: 'Kisan Credit Card (KCC) & PM-KISAN Helpdesk',
      description:
          'State Bank of India Naganoor branch is hosting an enrollment and renewal camp for farmer credit facilities every Wednesday.',
      createdBy: 'bank.admin@naganoor.village',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    DepartmentUpdate(
      id: 'upd-seed-post-1',
      department: VillageDepartment.postOffice,
      title: 'Aadhaar Mobile Number Linking & Update Drive',
      description:
          'Sub Post Office Naganoor has opened a dedicated counter for Aadhaar biometric updates and postal savings bank accounts.',
      createdBy: 'post.admin@naganoor.village',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      updatedAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    DepartmentUpdate(
      id: 'upd-seed-panchayat-1',
      department: VillageDepartment.panchayat,
      title: 'Gram Sabha Annual Budget & Works Agenda',
      description:
          'All village residents and elders are invited to the Gram Sabha at the Panchayat Hall on Sunday at 4:00 PM.',
      createdBy: 'panchayat.admin@naganoor.village',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    DepartmentUpdate(
      id: 'upd-seed-temple-1',
      department: VillageDepartment.temples,
      title: 'Sharanabasveswara Temple Jathra Preparations',
      description:
          'Annual jathra committee meeting concluded. Procession route, volunteer duties, and anna-prasada timings finalized.',
      createdBy: 'ravivtu12345@gmail.com',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      updatedAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    DepartmentUpdate(
      id: 'upd-seed-anna-1',
      department: VillageDepartment.annabhagya,
      title: 'Monthly Ration Grain Distribution Dates',
      description:
          'Deshapande and Gowdaru angadis will distribute monthly quota of rice, wheat, and sugar starting from 18th of this month.',
      createdBy: 'panchayat.admin@naganoor.village',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  Future<List<DepartmentUpdate>> fetchByDepartment(
    VillageDepartment department,
  ) async {
    final client = _client;
    if (client != null) {
      try {
        final rows = await client
            .from('department_updates')
            .select()
            .eq('department', department.dbValue)
            .order('created_at', ascending: false);
        final list = (rows as List<dynamic>).map(_fromRow).toList();
        if (list.isNotEmpty) return list;
      } catch (_) {
        // Fallback to local updates
      }
    }

    return _localUpdates
        .where((u) => u.department == department)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<DepartmentUpdate>> fetchAll() async {
    final client = _client;
    if (client != null) {
      try {
        final rows = await client
            .from('department_updates')
            .select()
            .order('created_at', ascending: false);
        final list = (rows as List<dynamic>).map(_fromRow).toList();
        if (list.isNotEmpty) return list;
      } catch (_) {
        // Fallback to local updates
      }
    }

    return List.of(_localUpdates)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> insert(Map<String, dynamic> row) async {
    final newId = row['id'] as String? ?? 'upd-${DateTime.now().millisecondsSinceEpoch}';
    final dept = VillageDepartment.fromDbValue(row['department'] as String?) ??
        VillageDepartment.panchayat;
    final item = DepartmentUpdate(
      id: newId,
      department: dept,
      title: (row['title'] as String?) ?? '',
      description: (row['description'] as String?) ?? '',
      imageUrl: row['image_url'] as String?,
      createdBy: row['created_by'] as String?,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    _localUpdates.insert(0, item);

    try {
      await _client?.from('department_updates').insert(row);
    } catch (_) {}
  }

  Future<void> updateRow(String id, Map<String, dynamic> row) async {
    final idx = _localUpdates.indexWhere((u) => u.id == id);
    if (idx >= 0) {
      final old = _localUpdates[idx];
      _localUpdates[idx] = DepartmentUpdate(
        id: old.id,
        department: old.department,
        title: (row['title'] as String?) ?? old.title,
        description: (row['description'] as String?) ?? old.description,
        imageUrl: row.containsKey('image_url') ? (row['image_url'] as String?) : old.imageUrl,
        createdBy: old.createdBy,
        createdAt: old.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
    }

    try {
      await _client?.from('department_updates').update(row).eq('id', id);
    } catch (_) {}
  }

  Future<void> delete(String id) async {
    _localUpdates.removeWhere((u) => u.id == id);
    try {
      await _client?.from('department_updates').delete().eq('id', id);
    } catch (_) {}
  }

  Future<String> uploadImage({
    required VillageDepartment department,
    required String filePath,
  }) async {
    final client = _client;
    if (client == null) {
      return '';
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

