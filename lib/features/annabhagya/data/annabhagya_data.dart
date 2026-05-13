import '../domain/annabhagya_models.dart';

/// Village Annabhagya Yojane — angadis and shared distribution schedule.
class AnnabhagyaData {
  static const schemeTitle = 'ಅನ್ನಭಾಗ್ಯ ಯೋಜನೆ';
  static const schemeSubtitle =
      'Rice and grains distribution for eligible ration card holders in Naganoor.';

  static const angadis = <AnnabhagyaAngadi>[
    AnnabhagyaAngadi(
      id: 'deshapande',
      name: 'Deshapande Angadi',
      location: 'Ward 1, near Naganoor main road',
    ),
    AnnabhagyaAngadi(
      id: 'gowdaru',
      name: 'Gowdaru Angadi',
      location: 'Ward 3, Gowdaru street junction',
    ),
  ];

  /// Same schedule at both angadis — update date here when Panchayat publishes new dates.
  static DistributionSchedule get distributionSchedule {
    final now = DateTime.now();
    return DistributionSchedule(
      distributionDate: DateTime(now.year, now.month, 18),
      timeSlot: '9:00 AM – 8:00 PM',
      items: const [
        GrainItem(itemName: 'Sugar', itemNameKn: 'ಸಕ್ಕರೆ'),
        GrainItem(itemName: 'Wheat', itemNameKn: 'ಗೋಧಿ'),
        GrainItem(itemName: 'Jowar', itemNameKn: 'ಜೋಳ'),
        GrainItem(itemName: 'Rice', itemNameKn: 'ಅಕ್ಕಿ'),
        GrainItem(itemName: 'Ragi flour', itemNameKn: 'ರಾಗಿ ಹಿಟ್ಟು'),
      ],
    );
  }

  static AnnabhagyaAngadi? angadiById(String id) {
    for (final angadi in angadis) {
      if (angadi.id == id) return angadi;
    }
    return null;
  }
}
