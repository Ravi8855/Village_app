import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/annabhagya_models.dart';

class AngadiCard extends StatelessWidget {
  const AngadiCard({
    super.key,
    required this.angadi,
    required this.onTap,
  });

  final AnnabhagyaAngadi angadi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.leaf.withValues(alpha: 0.12),
                foregroundColor: AppColors.leaf,
                child: const Icon(Icons.storefront_rounded),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      angadi.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      angadi.location,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'View rice & grain distribution dates',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.leaf,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
