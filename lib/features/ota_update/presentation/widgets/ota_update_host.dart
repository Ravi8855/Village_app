import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ota_update_service.dart';
import '../ota_update_providers.dart';
import 'ota_update_dialog.dart';

/// Checks for Shorebird patches after first frame (post-splash) and on resume.
class OtaUpdateHost extends ConsumerStatefulWidget {
  const OtaUpdateHost({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<OtaUpdateHost> createState() => _OtaUpdateHostState();
}

class _OtaUpdateHostState extends ConsumerState<OtaUpdateHost>
    with WidgetsBindingObserver {
  bool _checking = false;
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForOtaUpdate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForOtaUpdate();
    }
  }

  Future<void> _checkForOtaUpdate() async {
    if (_checking || _dialogVisible) return;

    final service = ref.read(otaUpdateServiceProvider);
    if (!service.isSupported) return;

    _checking = true;
    try {
      final result = await service.checkForUpdate();
      if (!mounted) return;

      switch (result.outcome) {
        case OtaUpdateCheckOutcome.unavailable:
        case OtaUpdateCheckOutcome.upToDate:
          return;
        case OtaUpdateCheckOutcome.checkFailed:
          if (result.message != null) {
            _showTransientMessage(result.message!);
          }
          return;
        case OtaUpdateCheckOutcome.updateAvailable:
          await _showUpdateDialog(restartOnly: false);
        case OtaUpdateCheckOutcome.restartRequired:
          await _showUpdateDialog(restartOnly: true);
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> _showUpdateDialog({required bool restartOnly}) async {
    if (!mounted || _dialogVisible) return;

    _dialogVisible = true;
    try {
      await showOtaUpdateDialog(
        context: context,
        restartOnly: restartOnly,
        onLater: () {},
        onUpdateNow: () => _performUpdate(restartOnly: restartOnly),
      );
    } finally {
      _dialogVisible = false;
    }
  }

  Future<void> _performUpdate({required bool restartOnly}) async {
    final service = ref.read(otaUpdateServiceProvider);

    if (restartOnly) {
      await service.restartApp();
      return;
    }

    if (!mounted) return;
    _showBlockingLoader();

    try {
      final result = await service.downloadAndInstall();
      if (!mounted) return;

      _hideBlockingLoader();

      if (result.success) {
        await service.restartApp();
        return;
      }

      _showTransientMessage(
        result.message ?? 'Update failed. Please try again later.',
      );
    } catch (_) {
      if (!mounted) return;
      _hideBlockingLoader();
      _showTransientMessage('Update failed. Please try again later.');
    }
  }

  void _showBlockingLoader() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Downloading update…'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _hideBlockingLoader() {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _showTransientMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
