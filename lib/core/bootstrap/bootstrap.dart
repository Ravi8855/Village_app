import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env_config.dart';
import '../push/push_notification_coordinator.dart';

class Bootstrap {
  static bool _supabaseReady = false;

  /// True after [Supabase.initialize] succeeds.
  static bool get supabaseReady => _supabaseReady;

  static Future<void> init() async {
    if (EnvConfig.supabaseEnabled) {
      try {
        await Supabase.initialize(
          url: EnvConfig.supabaseUrl,
          anonKey: EnvConfig.supabaseAnonKey,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
        );
        _supabaseReady = true;
        if (kDebugMode) {
          debugPrint('Supabase connected: ${EnvConfig.supabaseUrl}');
        }
      } catch (e, st) {
        _supabaseReady = false;
        debugPrint('Supabase init failed: $e');
        if (kDebugMode) {
          debugPrint('$st');
        }
      }
    } else if (kDebugMode) {
      debugPrint(
        'Supabase skipped. Copy dart_defines.example.json to dart_defines.json '
        'or pass --dart-define=SUPABASE_URL / SUPABASE_ANON_KEY.',
      );
    }

    await pushCoordinator.initialize();
  }
}
