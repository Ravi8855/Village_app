import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user_model.dart';

/// Supabase-backed global user store (`village_app_users` table).
class UserSupabaseDataSource {
  UserSupabaseDataSource(this._client);

  final SupabaseClient _client;

  static const table = 'village_app_users';

  /// True when `public.village_app_users` exists and is reachable.
  Future<bool> isTableReady() async {
    try {
      await _client.from(table).select('uid').limit(1);
      return true;
    } on PostgrestException catch (e) {
      if (isMissingTableError(e)) return false;
      rethrow;
    }
  }

  static bool isMissingTableError(PostgrestException e) {
    if (e.code == 'PGRST205') return true;
    final msg = e.message;
    return msg.contains('village_app_users') ||
        msg.contains('PGRST205') ||
        (e.code == '404' && msg.contains('Could not find the table'));
  }

  Future<AppUserModel?> getByEmail(String email) async {
    final rows = await _client
        .from(table)
        .select()
        .eq('email', email)
        .maybeSingle();
    if (rows == null) return null;
    return AppUserModel.fromSupabaseRow(rows);
  }

  Future<AppUserModel?> getByUid(String uid) async {
    final rows = await _client.from(table).select().eq('uid', uid).maybeSingle();
    if (rows == null) return null;
    return AppUserModel.fromSupabaseRow(rows);
  }

  Future<bool> emailExists(String email) async =>
      (await getByEmail(email)) != null;

  Future<AppUserModel> insert(AppUserModel user) async {
    final row = user.toSupabaseRow();
    final inserted = await _client.from(table).insert(row).select().single();
    return AppUserModel.fromSupabaseRow(inserted);
  }

  Future<AppUserModel> update(AppUserModel user) async {
    final updated = await _client
        .from(table)
        .update(user.toSupabaseRow())
        .eq('uid', user.uid)
        .select()
        .single();
    return AppUserModel.fromSupabaseRow(updated);
  }

  Future<void> deleteByUid(String uid) async {
    await _client.from(table).delete().eq('uid', uid);
  }

  Future<List<AppUserModel>> getAllUsers() async {
    final rows = await _client
        .from(table)
        .select()
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((e) => AppUserModel.fromSupabaseRow(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AppUserModel>> getDeptAdmins() async {
    final rows = await _client
        .from(table)
        .select()
        .eq('role', 'dept_admin')
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((e) => AppUserModel.fromSupabaseRow(e as Map<String, dynamic>))
        .toList();
  }

  /// Live updates for super admin dashboard (insert/update/delete).
  Stream<List<AppUserModel>> watchAllUsers() {
    return _client
        .from(table)
        .stream(primaryKey: ['uid'])
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map(
                (e) => AppUserModel.fromSupabaseRow(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(),
        );
  }
}
