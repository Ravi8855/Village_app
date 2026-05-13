import 'package:flutter/material.dart';

import '../../domain/app_update_offer.dart';
import '../../domain/app_update_type.dart';

Future<void> showAppUpdateDialog({
  required BuildContext context,
  required AppUpdateOffer offer,
  required Future<void> Function(AppUpdateType type) onUpdate,
  required VoidCallback onDismiss,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _AppUpdateDialog(
        offer: offer,
        onUpdate: (type) async {
          Navigator.of(dialogContext).pop();
          await onUpdate(type);
        },
        onDismiss: () {
          Navigator.of(dialogContext).pop();
          onDismiss();
        },
      );
    },
  );
}

class _AppUpdateDialog extends StatelessWidget {
  const _AppUpdateDialog({
    required this.offer,
    required this.onUpdate,
    required this.onDismiss,
  });

  final AppUpdateOffer offer;
  final Future<void> Function(AppUpdateType type) onUpdate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final canFlexible = offer.flexibleAllowed;
    final canImmediate = offer.immediateAllowed;

    return AlertDialog(
      icon: const Icon(Icons.system_update_rounded),
      title: const Text('Update available'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Version ${offer.currentVersionName} → '
              'build ${offer.availableVersionCode} is on Google Play.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'What\'s new',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(offer.releaseNotes),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('Later'),
        ),
        if (canFlexible)
          OutlinedButton(
            onPressed: () => onUpdate(AppUpdateType.flexible),
            child: const Text('Download'),
          ),
        if (canImmediate)
          FilledButton(
            onPressed: () => onUpdate(AppUpdateType.immediate),
            child: const Text('Update now'),
          ),
        if (!canFlexible && !canImmediate)
          FilledButton(
            onPressed: onDismiss,
            child: const Text('OK'),
          ),
      ],
    );
  }
}
