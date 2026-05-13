import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

class EmergencyContactRow extends StatelessWidget {
  const EmergencyContactRow({
    super.key,
    required this.label,
    required this.number,
  });

  final String label;
  final String number;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.clay.withValues(alpha: 0.15),
        foregroundColor: AppColors.clay,
        child: const Icon(Icons.emergency_share_rounded),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(number),
      trailing: IconButton.filledTonal(
        onPressed: () async {
          final uri = Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
        icon: const Icon(Icons.call),
      ),
    );
  }
}
