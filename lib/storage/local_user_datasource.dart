import 'dart:convert';

import '../models/app_role.dart';
import '../models/app_user_model.dart';
import 'session_manager.dart';

/// Device-local user store (fallback when `village_app_users` is not in Supabase).
class LocalUserDataSource {
  LocalUserDataSource(this._session);

  final SessionManager _session;

  Future<List<AppUserModel>> _loadAll() async {
    final raw = _session.legacyUsersJson;
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => AppUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAll(List<AppUserModel> users) async {
    final encoded = jsonEncode(users.map((u) => u.toJson()).toList());
    await _session.saveLocalUsersJson(encoded);
  }

  Future<AppUserModel?> getByEmail(String email) async {
    final users = await _loadAll();
    for (final user in users) {
      if (user.email == email) return user;
    }
    return null;
  }

  Future<AppUserModel?> getByUid(String uid) async {
    final users = await _loadAll();
    for (final user in users) {
      if (user.uid == uid) return user;
    }
    return null;
  }

  Future<bool> emailExists(String email) async => (await getByEmail(email)) != null;

  Future<AppUserModel> insert(AppUserModel user) async {
    final users = await _loadAll();
    users.add(user);
    await _saveAll(users);
    return user;
  }

  Future<AppUserModel> update(AppUserModel user) async {
    final users = await _loadAll();
    final index = users.indexWhere((u) => u.uid == user.uid);
    if (index >= 0) {
      users[index] = user;
    } else {
      users.add(user);
    }
    await _saveAll(users);
    return user;
  }

  Future<void> deleteByUid(String uid) async {
    final users = await _loadAll();
    users.removeWhere((u) => u.uid == uid);
    await _saveAll(users);
  }

  Future<List<AppUserModel>> getAllUsers() => _loadAll();

  Future<List<AppUserModel>> getDeptAdmins() async {
    final all = await _loadAll();
    return all.where((u) => u.role == AppRole.deptAdmin).toList();
  }

  Stream<List<AppUserModel>> watchAllUsers() async* {
    yield await getAllUsers();
  }
}
