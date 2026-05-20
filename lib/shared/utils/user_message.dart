import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Converts thrown errors into short, user-facing copy (no class names or dumps).
String formatUserMessage(Object error) {
  if (error is StateError) {
    return _stripPrefix(error.message);
  }
  if (error is ClientException ||
      error.toString().toLowerCase().contains('failed to fetch')) {
    return 'Cannot reach Supabase. Check your internet, project URL, and '
        'that the project is not paused. You can still sign in if your '
        'password matches SUPER_ADMIN_PASSWORD in dart_defines.json.';
  }
  if (error is PostgrestException) {
    return _postgrestMessage(error);
  }
  final raw = error.toString();
  return _stripPrefix(raw);
}

String _stripPrefix(String raw) {
  var text = raw.trim();
  const prefixes = [
    'StateError: ',
    'Exception: ',
    'FormatException: ',
    'PostgrestException: ',
  ];
  for (final prefix in prefixes) {
    if (text.startsWith(prefix)) {
      text = text.substring(prefix.length).trim();
    }
  }
  if (text.startsWith('{') && text.contains('message')) {
    try {
      final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(text);
      if (match != null) return match.group(1)!;
    } catch (_) {}
  }
  return text.isEmpty ? 'Something went wrong. Please try again.' : text;
}

String _postgrestMessage(PostgrestException e) {
  if (e.message.contains('village_app_users') ||
      e.code == 'PGRST205' ||
      e.message.contains('PGRST205')) {
    return 'User database is not set up yet. Ask your admin to run '
        'apply_village_app_users.sql in Supabase.';
  }
  final cleaned = _stripPrefix(e.message);
  if (cleaned.isNotEmpty && !cleaned.startsWith('{')) return cleaned;
  return 'Could not save your details. Please try again.';
}
