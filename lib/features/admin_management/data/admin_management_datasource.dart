import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env_config.dart';
import '../../../core/domain/department.dart';
import '../../../core/domain/staff_role.dart';
import '../domain/admin_invite.dart';

class AdminManagementDatasource {
  SupabaseClient? get _client =>
      EnvConfig.supabaseEnabled ? Supabase.instance.client : null;

  Future<List<AdminInvite>> fetchInvites() async {
    final client = _client;
    if (client == null) return [];

    final rows = await client
        .from('admin_invites')
        .select()
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).map(_inviteFromRow).toList();
  }

  Future<List<Map<String, dynamic>>> fetchStaffUsers() async {
    final client = _client;
    if (client == null) return [];

    final rows = await client
        .from('users')
        .select()
        .neq('role', 'user')
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchLoginActivity({int limit = 50}) async {
    final client = _client;
    if (client == null) return [];

    final rows = await client
        .from('login_activity')
        .select('*, users(full_name, mobile_number, role)')
        .order('login_time', ascending: false)
        .limit(limit);

    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> createInvite({
    required String mobileNumber,
    required String fullName,
    required StaffRole role,
    required VillageDepartment department,
    required String createdBy,
  }) async {
    await _client?.from('admin_invites').insert({
      'mobile_number': _normalizeMobile(mobileNumber),
      'full_name': fullName,
      'role': role.dbValue,
      'department': department.dbValue,
      'is_approved': false,
      'is_active': true,
      'created_by': createdBy,
    });
  }

  Future<void> updateInvite({
    required String id,
    String? fullName,
    bool? isApproved,
    bool? isActive,
  }) async {
    final patch = <String, dynamic>{};
    if (fullName != null) patch['full_name'] = fullName;
    if (isApproved != null) patch['is_approved'] = isApproved;
    if (isActive != null) patch['is_active'] = isActive;
    if (patch.isEmpty) return;
    await _client?.from('admin_invites').update(patch).eq('id', id);
  }

  Future<void> deleteInvite(String id) async {
    await _client?.from('admin_invites').delete().eq('id', id);
  }

  Future<void> updateUserFlags({
    required String userId,
    bool? isApproved,
    bool? isActive,
  }) async {
    final patch = <String, dynamic>{};
    if (isApproved != null) patch['is_approved'] = isApproved;
    if (isActive != null) patch['is_active'] = isActive;
    if (patch.isEmpty) return;
    await _client?.from('users').update(patch).eq('id', userId);
  }

  static String _normalizeMobile(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return digits;
    if (digits.length == 12 && digits.startsWith('91')) {
      return digits.substring(2);
    }
    return digits;
  }

  AdminInvite _inviteFromRow(dynamic row) {
    final map = Map<String, dynamic>.from(row as Map);
    final role = StaffRole.fromDbValue(map['role'] as String?)!;
    final dept = VillageDepartment.fromDbValue(map['department'] as String?)!;
    return AdminInvite(
      id: map['id'] as String,
      mobileNumber: map['mobile_number'] as String,
      fullName: map['full_name'] as String,
      role: role,
      department: dept,
      isApproved: map['is_approved'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
