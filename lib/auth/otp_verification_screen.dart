import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../shared/utils/form_toast.dart';

/// OTP entry panel with resend cooldown and verification actions.
class OtpVerificationPanel extends ConsumerStatefulWidget {
  const OtpVerificationPanel({
    super.key,
    required this.email,
    required this.recipientName,
    required this.onVerified,
    this.verifyLabel = 'Verify OTP',
    this.forDeptAdminActivation = false,
  });

  final String email;
  final String recipientName;
  final Future<void> Function(String otp) onVerified;
  final String verifyLabel;
  final bool forDeptAdminActivation;

  @override
  ConsumerState<OtpVerificationPanel> createState() =>
      _OtpVerificationPanelState();
}

class _OtpVerificationPanelState extends ConsumerState<OtpVerificationPanel> {
  final _otpController = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  int _cooldown = 0;

  @override
  void initState() {
    super.initState();
    _refreshCooldown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _refreshCooldown() async {
    final seconds = await ref
        .read(authProvider.notifier)
        .resendCooldownSeconds(widget.email);
    if (!mounted) return;
    setState(() => _cooldown = seconds);
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resending) return;
    setState(() => _resending = true);
    try {
      await ref.read(authProvider.notifier).sendOtp(
            email: widget.email,
            recipientName: widget.recipientName,
            forDeptAdminActivation: widget.forDeptAdminActivation,
          );
      if (!mounted) return;
      showFormSuccess(context, 'Verification code sent to your email.');
      await _refreshCooldown();
    } catch (e) {
      if (!mounted) return;
      showFormError(context, e);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      showFormToast(
        context,
        'Please enter the 6-digit code from your email.',
        isError: true,
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.onVerified(otp);
    } catch (e) {
      if (!mounted) return;
      showFormError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter OTP sent to ${widget.email}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: '6-digit OTP',
            border: OutlineInputBorder(),
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: _cooldown > 0 || _resending ? null : _resend,
              child: _resending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _cooldown > 0
                          ? 'Resend in ${_cooldown}s'
                          : 'Resend OTP',
                    ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.verifyLabel),
            ),
          ],
        ),
      ],
    );
  }
}

/// Standalone OTP verification route (optional second step).
class OtpVerificationScreen extends ConsumerWidget {
  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.recipientName,
    required this.onVerified,
  });

  final String email;
  final String recipientName;
  final Future<void> Function(String otp) onVerified;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: OtpVerificationPanel(
            email: email,
            recipientName: recipientName,
            onVerified: onVerified,
          ),
        ),
      ),
    );
  }
}
