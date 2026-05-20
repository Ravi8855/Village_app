import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../shared/utils/form_toast.dart';
import 'otp_verification_screen.dart';

/// One-time email OTP activation for department admins (after password check).
class DeptAdminActivateScreen extends ConsumerStatefulWidget {
  const DeptAdminActivateScreen({super.key});

  @override
  ConsumerState<DeptAdminActivateScreen> createState() =>
      _DeptAdminActivateScreenState();
}

class _DeptAdminActivateScreenState
    extends ConsumerState<DeptAdminActivateScreen> {
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendInitialOtp());
  }

  Future<void> _sendInitialOtp() async {
    final pending = ref.read(authProvider).pendingActivationUser;
    if (pending == null) {
      if (mounted) context.go(AppRoutePaths.adminLogin);
      return;
    }
    try {
      await ref.read(authProvider.notifier).sendOtp(
            email: pending.email,
            recipientName: pending.fullName,
            forDeptAdminActivation: true,
          );
      if (mounted) setState(() => _otpSent = true);
    } catch (e) {
      if (mounted) showFormError(context, e);
    }
  }

  Future<void> _verify(String otp) async {
    try {
      await ref.read(authProvider.notifier).completeDeptAdminActivation(
            otp: otp,
          );
      if (!mounted) return;
      showFormSuccess(
        context,
        'Account activated. You can now sign in with email and password only.',
      );
      context.go(ref.read(authProvider).homeRoute);
    } catch (e) {
      if (mounted) showFormError(context, e);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(authProvider).pendingActivationUser;

    if (pending == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Activate account')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sign in with your temporary password first, then complete '
                  'email verification here.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(AppRoutePaths.adminLogin),
                  child: const Text('Go to admin sign-in'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        title: const Text('Verify your email'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'One-time activation',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hi ${pending.fullName}, enter the verification code sent to '
                '${pending.email}. After this step you will only need your '
                'password to sign in.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Department: ${pending.departmentEnum?.label ?? pending.department ?? '—'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (!_otpSent) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_otpSent) ...[
                const SizedBox(height: 24),
                OtpVerificationPanel(
                  email: pending.email,
                  recipientName: pending.fullName,
                  verifyLabel: 'Activate account',
                  onVerified: _verify,
                  forDeptAdminActivation: true,
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ref.read(authProvider.notifier).clearPendingActivation();
                  context.go(AppRoutePaths.adminLogin);
                },
                child: const Text('Back to admin sign-in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
