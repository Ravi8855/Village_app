import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/bootstrap/bootstrap.dart';

/// Entry point.
///
/// EmailJS + optional Supabase via dart_defines.json:
/// `flutter run -d chrome --dart-define-from-file=dart_defines.json`
///
/// Or use: `.\scripts\run_chrome.ps1`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('[FlutterError] ${details.exceptionAsString()}');
    }
  };

  await Bootstrap.init();
  runApp(const ProviderScope(child: NaganoorApp()));
}
