import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/news/domain/announcement_category.dart';

class AnnouncementCategoryChip extends StatelessWidget {
  const AnnouncementCategoryChip({super.key, required this.category});

  final AnnouncementCategory category;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        category.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

Color _colorFor(AnnouncementCategory category) {
  switch (category) {
    case AnnouncementCategory.panchayat:
      return AppColors.leaf;
    case AnnouncementCategory.hospital:
      return AppColors.clay;
    case AnnouncementCategory.waterSupply:
      return AppColors.sky;
    case AnnouncementCategory.farming:
      return const Color(0xFF6D4C41);
    case AnnouncementCategory.electricity:
      return const Color(0xFFF9A825);
    case AnnouncementCategory.education:
      return const Color(0xFF1565C0);
    case AnnouncementCategory.emergency:
      return const Color(0xFFC62828);
    case AnnouncementCategory.temples:
      return const Color(0xFF6A1B9A);
  }
}
