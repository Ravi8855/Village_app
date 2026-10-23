import 'dart:async';
import 'dart:convert';

import '../models/app_auth_type.dart';
import '../models/app_role.dart';
import '../models/app_user_model.dart';
import '../services/password_service.dart';
import 'session_manager.dart';

/// Device-local user store (fallback when `village_app_users` is not in Supabase).
class LocalUserDataSource {
  LocalUserDataSource(this._session);

  final SessionManager _session;
  final _usersStreamController = StreamController<List<AppUserModel>>.broadcast();

  static List<AppUserModel> get defaultSeedUsers => [
        AppUserModel(
          uid: 'user-seed-super-admin',
          firstName: 'Ravi',
          lastName: 'Admin',
          mobileNumber: '8855025560',
          email: 'ravivtu12345@gmail.com',
          gender: 'Male',
          role: AppRole.superAdmin,
          authType: AppAuthType.superAdminPassword,
          passwordHash: PasswordService.hashPassword('Naganoor@Super2025'),
          isApproved: true,
          isOtpVerified: true,
          signupCompleted: true,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        // Department Admins
        AppUserModel(
          uid: 'user-seed-water-admin',
          firstName: 'Suresh',
          lastName: 'Patil',
          mobileNumber: '9845012341',
          email: 'water.admin@naganoor.village',
          gender: 'Male',
          role: AppRole.deptAdmin,
          department: 'water_supply',
          authType: AppAuthType.deptAdminPassword,
          passwordHash: PasswordService.hashPassword('Water@1234'),
          isApproved: true,
          isOtpVerified: true,
          signupCompleted: true,
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
        AppUserModel(
          uid: 'user-seed-power-admin',
          firstName: 'Ramesh',
          lastName: 'Gowda',
          mobileNumber: '9845012342',
          email: 'power.admin@naganoor.village',
          gender: 'Male',
          role: AppRole.deptAdmin,
          department: 'electricity',
          authType: AppAuthType.deptAdminPassword,
          passwordHash: PasswordService.hashPassword('Power@1234'),
          isApproved: true,
          isOtpVerified: true,
          signupCompleted: true,
          createdAt: DateTime.now().subtract(const Duration(days: 18)),
        ),
        AppUserModel(
          uid: 'user-seed-health-admin',
          firstName: 'Dr. Anitha',
          lastName: 'Kulkarni',
          mobileNumber: '9845012343',
          email: 'health.admin@naganoor.village',
          gender: 'Female',
          role: AppRole.deptAdmin,
          department: 'hospital',
          authType: AppAuthType.deptAdminPassword,
          passwordHash: PasswordService.hashPassword('Health@1234'),
          isApproved: true,
          isOtpVerified: true,
          signupCompleted: true,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
        AppUserModel(
          uid: 'user-seed-bank-admin',
          firstName: 'Basavaraj',
          lastName: 'Hiremath',
          mobileNumber: '9845012344',
          email: 'bank.admin@naganoor.village',
          gender: 'Male',
          role: AppRole.deptAdmin,
          department: 'bank',
          authType: AppAuthType.deptAdminPassword,
          passwordHash: PasswordService.hashPassword('Bank@1234'),
          isApproved: true,
          isOtpVerified: true,
          signupCompleted: true,
          createdAt: DateTime.now().subtract(const Duration(days: 12)),
        ),
        AppUserModel(
          uid: 'user-seed-post-admin',
          firstName: 'Mallikarjun',
          lastName: 'Biradar',
          mobileNumber: '9845012345',
          email: 'post.admin@naganoor.village',
          gender: 'Male',
          role: AppRole.deptAdmin,
          department: 'post_office',
          authType: AppAuthType.deptAdminPassword,
          passwordHash: PasswordService.hashPassword('Post@1234'),
          isApproved: true,
          isOtpVerified: true,
          signupCompleted: true,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        AppUserModel(
          uid: 'user-seed-panchayat-admin',
          firstName: 'Sharanappa',
          lastName: 'Deshmukh',
          mobileNumber: '9845012346',
          email: 'panchayat.admin@naganoor.village',
          gender: 'Male',
          role: AppRole.deptAdmin,
          department: 'panchayat',
          authType: AppAuthType.deptAdminPassword,
          passwordHash: PasswordService.hashPassword('Panchayat@1234'),
          isApproved: false,
          isOtpVerified: false,
          signupCompleted: false,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        // Village Resident Users
        AppUserModel(
          uid: 'user-seed-res-1',
          firstName: 'Anand',
          lastName: 'Kumar',
          mobileNumber: '9845098701',
          email: 'anand.kumar@naganoor.village',
          gender: 'Male',
          role: AppRole.user,
          authType: AppAuthType.otpUser,
          isApproved: true,
          isOtpVerified: true,
          signupCompleted: true,
          createdAt: DateTime.now().subtract(const Duration(days: 25)),
        ),
        AppUserModel(
          uid: 'user-seed-res-2',
          firstName: 'Lakshmi',
          lastName: 'Devi',
          mobileNumber: '9845098702',
          email: 'lakshmi.devi@naganoor.village',
          gender: 'Female',
          role: AppRole.user,
          authType: AppAuthType.otpUser,
          isApproved: true,
          isOtpVerified: true,
          signupCompleted: true,
          createdAt: DateTime.now().subtract(const Duration(days: 22)),
        ),
        AppUserModel(
          uid: 'user-seed-res-3',
          firstName: 'Shivakumar',
          lastName: 'Pujari',
          mobileNumber: '9845098703',
          email: 'shivakumar.p@naganoor.village',
          gender: 'Male',
          role: AppRole.user,
          authType: AppAuthType.otpUser,
          isApproved: true,
          isOtpVerified: true,
          signupCompleted: true,
          createdAt: DateTime.now().subtract(const Duration(days: 19)),
        ),
        AppUserModel(
          uid: 'user-seed-res-4',
          firstName: 'Renuka',
          lastName: 'Chalmar',
          mobileNumber: '9845098704',
          email: 'renuka.chalmar@naganoor.village',
          gender: 'Female',
          role: AppRole.user,
          authType: AppAuthType.otpUser,
          isApproved: true,
          isOtpVerified: true,
          signupCompleted: true,
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
        ),
        AppUserModel(
          uid: 'user-seed-res-5',
          firstName: 'Chandrashekhar',
          lastName: 'Patil',
          mobileNumber: '9845098705',
          email: 'chandra.patil@naganoor.village',
          gender: 'Male',
          role: AppRole.user,
          authType: AppAuthType.otpUser,
          isApproved: true,
          isOtpVerified: true,
          signupCompleted: true,
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ];

  Future<List<AppUserModel>> _loadAll() async {
    final raw = _session.legacyUsersJson;
    List<AppUserModel> list = [];
    if (raw == null || raw.isEmpty) {
      list = List.of(defaultSeedUsers);
      await _saveAll(list);
      return list;
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      list = decoded
          .map((e) => AppUserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      list = List.of(defaultSeedUsers);
      await _saveAll(list);
      return list;
    }

    // Ensure default seed users exist if no residents or dept admins are present
    final hasResidents = list.any((u) => u.role == AppRole.user);
    if (!hasResidents) {
      for (final seed in defaultSeedUsers) {
        if (!list.any((u) => u.email.toLowerCase() == seed.email.toLowerCase())) {
          list.add(seed);
        }
      }
      await _saveAll(list);
    }

    return list;
  }

  Future<void> _saveAll(List<AppUserModel> users) async {
    final encoded = jsonEncode(users.map((u) => u.toJson()).toList());
    await _session.saveLocalUsersJson(encoded);
    _usersStreamController.add(users);
  }

  Future<AppUserModel?> getByEmail(String email) async {
    final users = await _loadAll();
    final normalized = email.toLowerCase().trim();
    for (final user in users) {
      if (user.email.toLowerCase().trim() == normalized) return user;
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
    yield* _usersStreamController.stream;
  }
}

