import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/env_config.dart';

/// Sends OTP emails through the EmailJS REST API.
class EmailAuthService {
  static const _endpoint = 'https://api.emailjs.com/api/v1.0/email/send';

  Future<void> sendOtpEmail({
    required String toEmail,
    required String otp,
    required String recipientName,
  }) async {
    if (!EnvConfig.emailJsConfigured) {
      throw StateError(
        'EmailJS is not configured. Add EMAILJS_* keys to dart_defines.json.',
      );
    }

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_id': EnvConfig.emailJsServiceId,
        'template_id': EnvConfig.emailJsTemplateId,
        'user_id': EnvConfig.emailJsPublicKey,
        'template_params': {
          'to_email': toEmail,
          'user_email': toEmail,
          'email': toEmail,
          'otp': otp,
          'otp_code': otp,
          'user_name': recipientName,
          'name': recipientName,
          'message': 'Your Naganoor Village verification code is $otp. '
              'It expires in 5 minutes.',
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'EmailJS failed (${response.statusCode}): ${response.body}',
      );
    }
  }
}
