import 'app_update_offer.dart';

abstract class AppUpdateRepository {
  bool get isSupported;

  Future<AppUpdateOffer?> checkForUpdate();

  Future<void> startFlexibleUpdate();

  Future<void> performImmediateUpdate();

  Future<void> completeFlexibleUpdate();

  Future<bool> isFlexibleUpdateDownloaded();

  Future<String?> fetchPlayStoreReleaseNotes();

  Future<bool> shouldPromptForVersion(int availableVersionCode);

  Future<void> recordPromptShown(int availableVersionCode);

  Future<void> recordUpdateDismissed(int availableVersionCode);
}
