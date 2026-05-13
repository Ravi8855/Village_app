import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env_config.dart';
import 'app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  });
  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseClient? get _client =>
      EnvConfig.supabaseEnabled ? Supabase.instance.client : null;

  AppUser? _cachedUser;

  @override
  AppUser? get currentUser => _cachedUser;

  @override
  Stream<AppUser?> authStateChanges() async* {
    if (_client == null) {
      _cachedUser = null;
      yield null;
      return;
    }
    _cachedUser = _userFromAuth(_client!.auth.currentUser);
    yield _cachedUser;
    yield* _client!.auth.onAuthStateChange.map((event) {
      _cachedUser = _userFromAuth(event.session?.user);
      return _cachedUser;
    });
  }

  @override
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not configured.');
    }

    _cachedUser = null;

    final response = await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    if (response.session == null) {
      throw const AuthException('Sign-in succeeded but no session was returned.');
    }

    final authUser = client.auth.currentUser ?? response.user;
    if (authUser == null) {
      throw const AuthException('Sign-in succeeded but no authenticated user was returned.');
    }

    if (kDebugMode) {
      debugPrint('[Auth] signInWithPassword ok, auth user id: ${authUser.id}');
    }

    _cachedUser = _userFromAuth(authUser);
    return _cachedUser;
  }

  @override
  Future<void> signOut() async {
    await _client?.auth.signOut();
    _cachedUser = null;
  }

  AppUser? _userFromAuth(User? user) {
    if (user == null) return null;

    final email = _normalizeEmail(user.email) ?? '';
    final isAdmin = _isAdminEmail(email);

    if (kDebugMode) {
      debugPrint('[Auth] auth user id: ${user.id}');
      debugPrint('[Auth] auth user email: $email');
      debugPrint('[Auth] configured ADMIN_EMAIL: ${EnvConfig.adminEmail}');
      debugPrint('[Auth] admin=$isAdmin');
    }

    return AppUser(
      id: user.id,
      email: email,
      fullName: user.userMetadata?['full_name'] as String?,
      role: isAdmin ? UserRole.admin : UserRole.user,
    );
  }

  bool _isAdminEmail(String email) {
    if (!EnvConfig.adminEmailConfigured) return false;
    return email == _normalizeEmail(EnvConfig.adminEmail);
  }

  String? _normalizeEmail(String? email) => email?.trim().toLowerCase();
}

class AuthRepositoryStub implements AuthRepository {
  @override
  AppUser? get currentUser => null;

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(null);

  @override
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      null;

  @override
  Future<void> signOut() async {}
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (EnvConfig.supabaseEnabled) {
    return SupabaseAuthRepository();
  }
  return AuthRepositoryStub();
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return user?.isAdmin ?? false;
});
