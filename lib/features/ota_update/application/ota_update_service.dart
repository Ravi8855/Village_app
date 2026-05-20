import 'package:flutter/foundation.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Result of a Shorebird update availability check.
enum OtaUpdateCheckOutcome {
  unavailable,
  upToDate,
  updateAvailable,
  restartRequired,
  checkFailed,
}

class OtaUpdateCheckResult {
  const OtaUpdateCheckResult({
    required this.outcome,
    this.message,
    this.isNetworkError = false,
  });

  final OtaUpdateCheckOutcome outcome;
  final String? message;
  final bool isNetworkError;

  bool get shouldPrompt =>
      outcome == OtaUpdateCheckOutcome.updateAvailable ||
      outcome == OtaUpdateCheckOutcome.restartRequired;
}

class OtaUpdateDownloadResult {
  const OtaUpdateDownloadResult._({
    required this.success,
    this.message,
    this.isNetworkError = false,
    this.restartRequired = false,
  });

  final bool success;
  final String? message;
  final bool isNetworkError;
  final bool restartRequired;

  factory OtaUpdateDownloadResult.succeeded({required bool restartRequired}) {
    return OtaUpdateDownloadResult._(
      success: true,
      restartRequired: restartRequired,
    );
  }

  factory OtaUpdateDownloadResult.failed({
    required String message,
    bool isNetworkError = false,
  }) {
    return OtaUpdateDownloadResult._(
      success: false,
      message: message,
      isNetworkError: isNetworkError,
    );
  }
}

/// Shorebird OTA update orchestration (check, download, restart).
class OtaUpdateService {
  OtaUpdateService({ShorebirdUpdater? updater})
      : _updater = updater ?? ShorebirdUpdater();

  final ShorebirdUpdater _updater;

  bool get isSupported {
    if (kIsWeb) return false;
    return _updater.isAvailable;
  }

  Future<void> initialize() async {
    if (!isSupported) {
      _log('Shorebird updater unavailable (debug build or non-Shorebird release).');
      return;
    }

    try {
      final patch = await _updater.readCurrentPatch();
      _log(
        patch == null
            ? 'Initialized with no patch installed.'
            : 'Initialized with patch ${patch.number}.',
      );
    } catch (e, st) {
      _log('initialize readCurrentPatch failed: $e', stackTrace: st);
    }
  }

  Future<OtaUpdateCheckResult> checkForUpdate() async {
    if (!isSupported) {
      _log('checkForUpdate skipped: updater unavailable.');
      return const OtaUpdateCheckResult(outcome: OtaUpdateCheckOutcome.unavailable);
    }

    try {
      _log('Checking for Shorebird patch…');
      final status = await _updater.checkForUpdate();

      switch (status) {
        case UpdateStatus.upToDate:
          _log('Already on latest patch.');
          return const OtaUpdateCheckResult(outcome: OtaUpdateCheckOutcome.upToDate);
        case UpdateStatus.outdated:
          _log('New patch available.');
          return const OtaUpdateCheckResult(
            outcome: OtaUpdateCheckOutcome.updateAvailable,
          );
        case UpdateStatus.restartRequired:
          _log('Downloaded patch pending restart.');
          return const OtaUpdateCheckResult(
            outcome: OtaUpdateCheckOutcome.restartRequired,
          );
        case UpdateStatus.unavailable:
          _log('Update status unavailable.');
          return const OtaUpdateCheckResult(
            outcome: OtaUpdateCheckOutcome.unavailable,
          );
      }
    } catch (e, st) {
      final network = _looksLikeNetworkError(e);
      _log('checkForUpdate failed: $e', stackTrace: st);
      return OtaUpdateCheckResult(
        outcome: OtaUpdateCheckOutcome.checkFailed,
        message: network
            ? 'No internet connection. Could not check for updates.'
            : 'Could not check for updates.',
        isNetworkError: network,
      );
    }
  }

  Future<OtaUpdateDownloadResult> downloadAndInstall() async {
    if (!isSupported) {
      return OtaUpdateDownloadResult.failed(
        message: 'OTA updates are not available in this build.',
      );
    }

    try {
      _log('Downloading and installing Shorebird patch…');
      await _updater.update();
      _log('Patch installed; restart required.');

      final status = await _updater.checkForUpdate();
      final restartRequired = status == UpdateStatus.restartRequired ||
          status == UpdateStatus.upToDate;

      return OtaUpdateDownloadResult.succeeded(restartRequired: restartRequired);
    } on UpdateException catch (e, st) {
      final network = e.reason == UpdateFailureReason.downloadFailed &&
          _looksLikeNetworkError(e);
      _log('downloadAndInstall UpdateException: ${e.message}', stackTrace: st);
      return OtaUpdateDownloadResult.failed(
        message: network
            ? 'No internet connection. Update download failed.'
            : e.message,
        isNetworkError: network,
      );
    } catch (e, st) {
      final network = _looksLikeNetworkError(e);
      _log('downloadAndInstall failed: $e', stackTrace: st);
      return OtaUpdateDownloadResult.failed(
        message: network
            ? 'No internet connection. Update download failed.'
            : 'Update failed. Please try again later.',
        isNetworkError: network,
      );
    }
  }

  Future<void> restartApp() async {
    _log('Restarting app to apply patch…');
    await Restart.restartApp();
  }

  bool _looksLikeNetworkError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('socket') ||
        text.contains('network') ||
        text.contains('internet') ||
        text.contains('connection') ||
        text.contains('host lookup') ||
        text.contains('failed host lookup') ||
        text.contains('timed out') ||
        text.contains('offline');
  }

  void _log(String message, {StackTrace? stackTrace}) {
    debugPrint('[OtaUpdate] $message');
    if (stackTrace != null && kDebugMode) {
      debugPrint('$stackTrace');
    }
  }
}
