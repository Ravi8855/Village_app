import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class InAppUpdateDataSource {
  Future<AppUpdateInfo> checkForUpdate() => InAppUpdate.checkForUpdate();

  Future<AppUpdateResult> startFlexibleUpdate() =>
      InAppUpdate.startFlexibleUpdate();

  Future<AppUpdateResult> performImmediateUpdate() =>
      InAppUpdate.performImmediateUpdate();

  Future<void> completeFlexibleUpdate() => InAppUpdate.completeFlexibleUpdate();

  bool isUpdateAvailable(AppUpdateInfo info) =>
      info.updateAvailability == UpdateAvailability.updateAvailable;

  bool isFlexibleDownloaded(AppUpdateInfo info) =>
      info.installStatus == InstallStatus.downloaded;

  void logDebug(String message) {
    if (kDebugMode) {
      debugPrint('[AppUpdate] $message');
    }
  }
}
