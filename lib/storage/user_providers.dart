import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/di/core_providers.dart';
import '../models/app_user_model.dart';
import 'session_manager.dart';
import 'user_repository.dart';
import 'user_supabase_datasource.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final sessionManagerProvider = FutureProvider<SessionManager>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SessionManager(prefs);
});

/// Supabase user datasource when client is ready.
final userSupabaseDataSourceProvider = Provider<UserSupabaseDataSource?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return UserSupabaseDataSource(client);
});

final userRepositoryProvider = FutureProvider<UserRepository>((ref) async {
  final session = await ref.watch(sessionManagerProvider.future);
  final supabase = ref.watch(userSupabaseDataSourceProvider);
  final repo = UserRepository(session: session, supabase: supabase);
  await repo.initBackend();
  if (repo.usesSupabaseTable) {
    await repo.migrateLegacyLocalUsersIfNeeded();
  }
  return repo;
});

/// Real-time user list for super admin dashboard (global Supabase sync).
final allUsersStreamProvider = StreamProvider<List<AppUserModel>>((ref) async* {
  final repo = await ref.watch(userRepositoryProvider.future);
  yield* repo.watchAllUsers();
});
