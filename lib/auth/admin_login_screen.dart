import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/admin_login_result.dart';
import '../providers/auth_provider.dart';
import '../shared/utils/form_toast.dart';
import '../shared/utils/form_validators.dart';

/// Super admin and department admin sign-in (email + password).
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  bool _showValidation = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _showValidation = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      final result = await ref.read(authProvider.notifier).loginWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;

      switch (result.outcome) {
        case AdminLoginOutcome.success:
          context.go(ref.read(authProvider).homeRoute);
        case AdminLoginOutcome.requiresOtpActivation:
          context.go(AppRoutePaths.adminActivate);
        case AdminLoginOutcome.awaitingApproval:
          showFormToast(
            context,
            'Your account is awaiting super admin approval.',
            isError: true,
          );
        case AdminLoginOutcome.blocked:
          showFormToast(
            context,
            'This account is blocked. Contact the super admin.',
            isError: true,
          );
        case AdminLoginOutcome.notAdminAccount:
          showFormToast(
            context,
            'This email is for village signup, not admin login.',
            isError: true,
          );
        case AdminLoginOutcome.invalidCredentials:
          showFormToast(
            context,
            'Incorrect email or password. Try again.',
            isError: true,
          );
      }
    } catch (e) {
      if (mounted) showFormError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        title: const Text('Admin sign-in'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: _showValidation
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Administrator access',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.soil,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Super admin and department admins sign in here with email '
                  'and password. Village residents use Village signup instead.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Super admin password is set in dart_defines.json as '
                  'SUPER_ADMIN_PASSWORD (default: Naganoor@Super2025).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                  ),
                  validator: FormValidators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                  validator: FormValidators.password,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _loading ? null : _signIn,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login_rounded),
                  label: const Text('Sign in'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go(AppRoutePaths.signup),
                  child: const Text('Village resident? Go to signup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
