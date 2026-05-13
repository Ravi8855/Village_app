import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/app_update_service.dart';
import '../../data/app_update_repository_impl.dart';
import '../../domain/app_update_offer.dart';
import '../../domain/app_update_type.dart';
import '../app_update_providers.dart';
import 'app_update_dialog.dart';

/// Android-only host that checks for Play Store updates after first frame
/// and when the app returns to foreground.
class AppUpdateHost extends ConsumerStatefulWidget {
  const AppUpdateHost({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<AppUpdateHost> createState() => _AppUpdateHostState();
}

class _AppUpdateHostState extends ConsumerState<AppUpdateHost>
    with WidgetsBindingObserver {
  bool _checking = false;
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
      _checkFlexibleDownloadReady();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkFlexibleDownloadReady();
      _checkForUpdates();
    }
  }

  Future<void> _checkForUpdates() async {
    if (!ref.read(appUpdateSupportedProvider) || _checking || _dialogVisible) {
      return;
    }

    _checking = true;
    try {
      final service = ref.read(appUpdateServiceProvider);
      final offer = await service.checkForPromptableUpdate();
      if (!mounted || offer == null) return;

      _dialogVisible = true;
      await showAppUpdateDialog(
        context: context,
        offer: offer,
        onDismiss: () => service.dismissUpdate(offer),
        onUpdate: (type) => _performUpdate(service, offer, type),
      );
    } finally {
      _dialogVisible = false;
      _checking = false;
    }
  }

  Future<void> _performUpdate(
    AppUpdateService service,
    AppUpdateOffer offer,
    AppUpdateType type,
  ) async {
    try {
      await service.startUpdate(offer, type);
      if (!mounted) return;

      if (type == AppUpdateType.flexible) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Downloading update in the background…'),
          ),
        );
      }
    } on AppUpdateActionException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start the update. Try again from Google Play.'),
        ),
      );
    }
  }

  Future<void> _checkFlexibleDownloadReady() async {
    if (!ref.read(appUpdateSupportedProvider)) return;

    final service = ref.read(appUpdateServiceProvider);
    final ready = await service.isFlexibleUpdateReadyToInstall();
    if (!mounted || !ready) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Update downloaded. Restart to install.'),
        action: SnackBarAction(
          label: 'Install',
          onPressed: () async {
            try {
              await service.completeFlexibleUpdate();
            } catch (_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not install the downloaded update.'),
                ),
              );
            }
          },
        ),
        duration: const Duration(days: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
