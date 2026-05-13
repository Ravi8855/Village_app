import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/auth/auth_repository.dart';
import '../../../../core/config/env_config.dart';
import '../../presentation/news_providers.dart';

class AdminLoginPage extends ConsumerStatefulWidget {
  const AdminLoginPage({super.key});

  @override
  ConsumerState<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends ConsumerState<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (EnvConfig.adminEmailConfigured) {
      _emailController.text = EnvConfig.adminEmail.trim();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin sign in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Panchayat administrators can sign in to manage village announcements.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            if (!EnvConfig.supabaseEnabled) ...[
              const Icon(Icons.cloud_off_rounded, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Supabase is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
              ),
            ] else if (!EnvConfig.adminEmailConfigured) ...[
              const Icon(Icons.admin_panel_settings_outlined, size: 40),
              const SizedBox(height: 12),
              const Text(
                'ADMIN_EMAIL is not configured. Add it to dart_defines.json.',
              ),
            ] else ...[
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: EnvConfig.adminEmail,
                  border: const OutlineInputBorder(),
                  helperText: 'Must match ADMIN_EMAIL in dart_defines.json',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _signIn,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim().toLowerCase();
    final adminEmail = EnvConfig.adminEmail.trim().toLowerCase();

    setState(() {
      _loading = true;
      _error = null;
    });

    if (email != adminEmail) {
      setState(() {
        _loading = false;
        _error =
            'Email must be exactly $adminEmail. Check spelling (you entered: $email).';
      });
      return;
    }

    try {
      final user = await ref.read(authRepositoryProvider).signInWithEmail(
            email: email,
            password: _passwordController.text,
          );
      if (!mounted) return;
      if (user == null || !user.isAdmin) {
        await ref.read(authRepositoryProvider).signOut();
        ref.invalidate(authStateProvider);
        setState(() => _error = 'Not authorized as admin');
      } else {
        ref.invalidate(authStateProvider);
        ref.invalidate(isAdminProvider);
        ref.invalidate(newsListNotifierProvider);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      ref.invalidate(authStateProvider);
      if (mounted) setState(() => _error = _formatSignInError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatSignInError(Object error) {
    if (error is AuthException) {
      final code = error.code?.toLowerCase() ?? '';
      final message = error.message.toLowerCase();
      if (code == 'invalid_credentials' ||
          message.contains('invalid login credentials')) {
        return 'Invalid email or password. Sign in with the exact Supabase Auth '
            'account for ${EnvConfig.adminEmail}.';
      }
      return error.message;
    }
    return error.toString();
  }
}
