import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bootstrap/bootstrap.dart';
import '../config/env_config.dart';
import '../network/http_client.dart';

final httpClientProvider = Provider<HttpClient>((ref) {
  final client = HttpClient();
  ref.onDispose(client.close);
  return client;
});

/// Live Supabase client when [Bootstrap.supabaseReady]; otherwise null.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!EnvConfig.supabaseEnabled || !Bootstrap.supabaseReady) {
    return null;
  }
  return Supabase.instance.client;
});
