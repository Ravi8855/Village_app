import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

typedef OtaUpdateDialogAction = Future<void> Function();

/// Modern Shorebird OTA prompt with auto-countdown.
Future<void> showOtaUpdateDialog({
  required BuildContext context,
  required bool restartOnly,
  required OtaUpdateDialogAction onUpdateNow,
  required VoidCallback onLater,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _OtaUpdateDialog(
        restartOnly: restartOnly,
        onUpdateNow: () async {
          Navigator.of(dialogContext).pop();
          await onUpdateNow();
        },
        onLater: () {
          Navigator.of(dialogContext).pop();
          onLater();
        },
      );
    },
  );
}

class _OtaUpdateDialog extends StatefulWidget {
  const _OtaUpdateDialog({
    required this.restartOnly,
    required this.onUpdateNow,
    required this.onLater,
  });

  final bool restartOnly;
  final OtaUpdateDialogAction onUpdateNow;
  final VoidCallback onLater;

  @override
  State<_OtaUpdateDialog> createState() => _OtaUpdateDialogState();
}

class _OtaUpdateDialogState extends State<_OtaUpdateDialog> {
  static const _autoDelay = Duration(seconds: 3);

  late int _secondsRemaining;
  Timer? _timer;
  bool _handedOff = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = _autoDelay.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted || _handedOff) return;

    setState(() {
      _secondsRemaining =
          (_secondsRemaining - 1).clamp(0, _autoDelay.inSeconds);
    });

    if (_secondsRemaining == 0) {
      unawaited(_handOffUpdate());
    }
  }

  Future<void> _handOffUpdate() async {
    if (_handedOff) return;
    _handedOff = true;
    _timer?.cancel();
    await widget.onUpdateNow();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !_handedOff,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.rice,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.system_update_alt_rounded,
            color: colorScheme.primary,
            size: 30,
          ),
        ),
        title: const Text('New Update Available'),
        content: Text(
          widget.restartOnly
              ? 'A downloaded update is ready. The app will restart in $_secondsRemaining second${_secondsRemaining == 1 ? '' : 's'}.'
              : 'The app will update automatically in $_secondsRemaining second${_secondsRemaining == 1 ? '' : 's'}.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: _handedOff ? null : widget.onLater,
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: _handedOff ? null : _handOffUpdate,
            child: Text(widget.restartOnly ? 'Restart Now' : 'Update Now'),
          ),
        ],
      ),
    );
  }
}
