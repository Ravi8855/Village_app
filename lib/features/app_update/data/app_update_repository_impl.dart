import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../domain/app_update_offer.dart';
import '../domain/app_update_repository.dart';
import '../domain/app_update_type.dart';
import 'app_update_preferences_store.dart';
import 'in_app_update_datasource.dart';
import 'play_store_metadata_datasource.dart';

class AppUpdateRepositoryImpl implements AppUpdateRepository {
  AppUpdateRepositoryImpl({
    required InAppUpdateDataSource playCoreDataSource,
    required PlayStoreMetadataDataSource playStoreMetadataDataSource,
    required AppUpdatePreferencesStore preferencesStore,
  })  : _playCore = playCoreDataSource,
        _playStore = playStoreMetadataDataSource,
        _preferences = preferencesStore;

  final InAppUpdateDataSource _playCore;
  final PlayStoreMetadataDataSource _playStore;
  final AppUpdatePreferencesStore _preferences;

  @override
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  @override
  Future<AppUpdateOffer?> checkForUpdate() async {
    if (!isSupported) return null;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;
      final info = await _playCore.checkForUpdate();

      if (!_playCore.isUpdateAvailable(info)) {
        _playCore.logDebug('No update available from Play Core.');
        return null;
      }

      final availableVersionCode = info.availableVersionCode;
      if (availableVersionCode == null ||
          availableVersionCode <= currentVersionCode) {
        _playCore.logDebug(
          'Store version $availableVersionCode is not newer than local $currentVersionCode.',
        );
        return null;
      }

      final releaseNotes = await fetchPlayStoreReleaseNotes();
      final recommendedType = _recommendedUpdateType(info);

      _playCore.logDebug(
        'Update available: $availableVersionCode (current $currentVersionCode), '
        'flexible=${info.flexibleUpdateAllowed}, '
        'immediate=${info.immediateUpdateAllowed}, '
        'recommended=$recommendedType',
      );

      return AppUpdateOffer(
        currentVersionName: packageInfo.version,
        currentVersionCode: currentVersionCode,
        availableVersionCode: availableVersionCode,
        releaseNotes: releaseNotes ??
            'A newer version of Naganoor Village App is available on Google Play.',
        flexibleAllowed: info.flexibleUpdateAllowed,
        immediateAllowed: info.immediateUpdateAllowed,
        recommendedType: recommendedType,
        updatePriority: info.updatePriority,
        clientVersionStalenessDays: info.clientVersionStalenessDays,
      );
    } catch (e, st) {
      _playCore.logDebug('checkForUpdate failed: $e\n$st');
      return null;
    }
  }

  @override
  Future<void> startFlexibleUpdate() async {
    final result = await _playCore.startFlexibleUpdate();
    if (result != AppUpdateResult.success) {
      throw AppUpdateActionException(
        'Flexible update could not be started ($result).',
      );
    }
  }

  @override
  Future<void> performImmediateUpdate() async {
    final result = await _playCore.performImmediateUpdate();
    if (result != AppUpdateResult.success) {
      throw AppUpdateActionException(
        'Immediate update could not be started ($result).',
      );
    }
  }

  @override
  Future<void> completeFlexibleUpdate() => _playCore.completeFlexibleUpdate();

  @override
  Future<bool> isFlexibleUpdateDownloaded() async {
    if (!isSupported) return false;
    try {
      final info = await _playCore.checkForUpdate();
      return _playCore.isFlexibleDownloaded(info);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> fetchPlayStoreReleaseNotes() =>
      _playStore.fetchReleaseNotes();

  @override
  Future<bool> shouldPromptForVersion(int availableVersionCode) async {
    final dismissed = await _preferences.getDismissedVersionCode();
    if (dismissed >= availableVersionCode) {
      return false;
    }

    final lastPromptVersion = await _preferences.getLastPromptVersionCode();
    final lastPromptAt = await _preferences.getLastPromptAt();

    if (lastPromptVersion == availableVersionCode && lastPromptAt != null) {
      final elapsed = DateTime.now().difference(lastPromptAt);
      if (elapsed < AppUpdatePreferencesStore.promptCooldown) {
        return false;
      }
    }

    return true;
  }

  @override
  Future<void> recordPromptShown(int availableVersionCode) =>
      _preferences.recordPrompt(availableVersionCode);

  @override
  Future<void> recordUpdateDismissed(int availableVersionCode) =>
      _preferences.setDismissedVersionCode(availableVersionCode);

  AppUpdateType _recommendedUpdateType(AppUpdateInfo info) {
    final highPriority = info.updatePriority >= 4;
    final stale = (info.clientVersionStalenessDays ?? 0) >= 7;

    if ((highPriority || stale) && info.immediateUpdateAllowed) {
      return AppUpdateType.immediate;
    }
    if (info.flexibleUpdateAllowed) {
      return AppUpdateType.flexible;
    }
    if (info.immediateUpdateAllowed) {
      return AppUpdateType.immediate;
    }
    return AppUpdateType.flexible;
  }
}

class AppUpdateActionException implements Exception {
  AppUpdateActionException(this.message);
  final String message;

  @override
  String toString() => message;
}
