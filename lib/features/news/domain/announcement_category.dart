enum AnnouncementCategory {
  panchayat,
  hospital,
  waterSupply,
  farming,
  electricity,
  education,
  emergency,
  temples,
}

extension AnnouncementCategoryX on AnnouncementCategory {
  String get label {
    switch (this) {
      case AnnouncementCategory.panchayat:
        return 'Panchayat';
      case AnnouncementCategory.hospital:
        return 'Hospital';
      case AnnouncementCategory.waterSupply:
        return 'Water Supply';
      case AnnouncementCategory.farming:
        return 'Farming';
      case AnnouncementCategory.electricity:
        return 'Electricity';
      case AnnouncementCategory.education:
        return 'Education';
      case AnnouncementCategory.emergency:
        return 'Emergency';
      case AnnouncementCategory.temples:
        return 'Temples';
    }
  }

  String get slug => name;

  static AnnouncementCategory fromSlug(String? slug) {
    return AnnouncementCategory.values.firstWhere(
      (e) => e.name == slug || e.slug == slug,
      orElse: () => AnnouncementCategory.panchayat,
    );
  }
}
