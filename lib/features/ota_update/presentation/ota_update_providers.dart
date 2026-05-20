import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ota_update_service.dart';

final otaUpdateServiceProvider = Provider<OtaUpdateService>((ref) {
  return OtaUpdateService();
});

final otaUpdateSupportedProvider = Provider<bool>((ref) {
  return ref.watch(otaUpdateServiceProvider).isSupported;
});
