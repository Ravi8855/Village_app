import 'package:flutter/foundation.dart';

/// Hook point for FCM / APNs. Wire [FirebaseMessaging] here when keys are configured.
abstract class PushNotificationCoordinator {
  Future<void> initialize();
}

class NoOpPushNotificationCoordinator implements PushNotificationCoordinator {
  @override
  Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint(
        'PushNotificationCoordinator: no-op (add FCM/APNs wiring when backend is ready).',
      );
    }
  }
}

final PushNotificationCoordinator pushCoordinator =
    NoOpPushNotificationCoordinator();
