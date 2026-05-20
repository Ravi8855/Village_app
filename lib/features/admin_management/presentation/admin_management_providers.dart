import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_management_datasource.dart';
import '../domain/admin_invite.dart';

final adminManagementDatasourceProvider =
    Provider<AdminManagementDatasource>((ref) {
  return AdminManagementDatasource();
});

final adminInvitesProvider = FutureProvider<List<AdminInvite>>((ref) {
  return ref.watch(adminManagementDatasourceProvider).fetchInvites();
});

final staffUsersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminManagementDatasourceProvider).fetchStaffUsers();
});

final loginActivityProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminManagementDatasourceProvider).fetchLoginActivity();
});
