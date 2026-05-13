import 'package:flutter/foundation.dart';

import '../domain/app_update_offer.dart';
import '../domain/app_update_repository.dart';
import '../domain/app_update_type.dart';

class AppUpdateService {
  AppUpdateService(this._repository);

  final AppUpdateRepository _repository;

  bool get isSupported => _repository.isSupported;

  /// Checks Play Core for updates and applies anti-spam rules.
  Future<AppUpdateOffer?> checkForPromptableUpdate() async {
    if (!isSupported) return null;

    try {
      final offer = await _repository.checkForUpdate();
      if (offer == null || !offer.hasNewerVersion) return null;

      final shouldPrompt =
          await _repository.shouldPromptForVersion(offer.availableVersionCode);
      if (!shouldPrompt) {
        _log('Skipping prompt for version ${offer.availableVersionCode}');
        return null;
      }

      await _repository.recordPromptShown(offer.availableVersionCode);
      return offer;
    } catch (e, st) {
      _log('checkForPromptableUpdate failed: $e\n$st');
      return null;
    }
  }

  Future<void> dismissUpdate(AppUpdateOffer offer) =>
      _repository.recordUpdateDismissed(offer.availableVersionCode);

  Future<void> startUpdate(AppUpdateOffer offer, AppUpdateType type) async {
    switch (type) {
      case AppUpdateType.flexible:
        await _repository.startFlexibleUpdate();
      case AppUpdateType.immediate:
        await _repository.performImmediateUpdate();
    }
  }

  Future<bool> isFlexibleUpdateReadyToInstall() =>
      _repository.isFlexibleUpdateDownloaded();

  Future<void> completeFlexibleUpdate() => _repository.completeFlexibleUpdate();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AppUpdateService] $message');
    }
  }
}
