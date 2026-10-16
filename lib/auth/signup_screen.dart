import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/env_config.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../shared/utils/form_toast.dart';
import '../shared/utils/form_validators.dart';
import 'otp_verification_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();

  String _gender = 'Male';
  bool _otpSent = false;
  bool _sendingOtp = false;
  bool _showValidation = false;

  static const _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _validateSignupFields() {
    setState(() => _showValidation = true);
    return _formKey.currentState?.validate() ?? false;
  }

  String get _recipientName {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    if (first.isEmpty && last.isEmpty) return 'Village user';
    return '$first $last'.trim();
  }

  Future<void> _sendOtp() async {
    if (!_validateSignupFields()) return;

    setState(() => _sendingOtp = true);

    try {
      final email = _emailController.text.trim();
      await ref.read(authProvider.notifier).sendOtp(
            email: email,
            recipientName: _recipientName,
          );
      if (!mounted) return;
      setState(() => _otpSent = true);
      showFormSuccess(
        context,
        'Verification code sent to your email. It expires in 5 minutes.',
      );
    } catch (e) {
      if (mounted) showFormError(context, e);
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _verifySignup(String otp) async {
    if (!_validateSignupFields()) return;
    final mobile = _mobileController.text.replaceAll(RegExp(r'\D'), '');
    try {
      await ref.read(authProvider.notifier).verifySignupAndCreate(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            mobileNumber: mobile,
            email: _emailController.text.trim(),
            gender: _gender,
            otp: otp,
          );
    } catch (e) {
      if (mounted) showFormError(context, e);
      return;
    }
    if (!mounted) return;
    showFormSuccess(
      context,
      'Welcome! You are signed in — no need to verify again unless you sign out.',
    );
    final route = ref.read(authProvider).homeRoute;
    context.go(route);
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.soil.withValues(alpha: 0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.soil.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.leaf, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      errorStyle: const TextStyle(height: 1.1),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!EnvConfig.emailJsConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create account')),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'EmailJS is not configured. Add EMAILJS_SERVICE_ID, '
            'EMAILJS_TEMPLATE_ID, and EMAILJS_PUBLIC_KEY to dart_defines.json.',
          ),
        ),
      );
    }

    final autovalidate = _showValidation
        ? AutovalidateMode.onUserInteraction
        : AutovalidateMode.disabled;

    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        title: const Text('Village signup'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            autovalidateMode: autovalidate,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Village header banner card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.soil.withValues(alpha: 0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.rice,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.location_city_rounded, color: AppColors.leaf, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Naganoor Village',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.soil,
                                      ),
                                ),
                                const Text(
                                  'Resident Registration',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.leaf,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'One-time signup for village residents. After verification, '
                        'you stay signed in on this device.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.soil.withValues(alpha: 0.8),
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _fieldDecoration('First name *'),
                  validator: FormValidators.firstName,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _fieldDecoration('Last name *'),
                  validator: FormValidators.lastName,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: _fieldDecoration('Mobile number (reference) *')
                      .copyWith(prefixText: '+91 '),
                  validator: FormValidators.mobile,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: _fieldDecoration('Email address *'),
                  validator: FormValidators.email,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: _fieldDecoration('Gender *'),
                  items: _genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _gender = value);
                  },
                  validator: FormValidators.gender,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _sendingOtp ? null : _sendOtp,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: AppColors.leaf,
                  ),
                  icon: _sendingOtp
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.mail_outline),
                  label: Text(
                    _otpSent ? 'Resend OTP' : 'Send OTP',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutePaths.adminLogin),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: AppColors.leaf,
                    side: const BorderSide(color: AppColors.leaf),
                  ),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text(
                    'Admin sign-in (password)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              if (_otpSent) ...[
                  const SizedBox(height: 24),
                  OtpVerificationPanel(
                    email: _emailController.text.trim(),
                    recipientName: _recipientName,
                    verifyLabel: 'Verify & create account',
                    onVerified: _verifySignup,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
