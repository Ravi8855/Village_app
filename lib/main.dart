import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/bootstrap/bootstrap.dart';

/// Entry point.
///
/// Supabase is configured via compile-time defines:
/// `flutter run -d chrome --dart-define-from-file=dart_defines.json`
///
/// Or use: `.\scripts\run_chrome.ps1`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Bootstrap.init();
  runApp(const ProviderScope(child: NaganoorApp()));
}
