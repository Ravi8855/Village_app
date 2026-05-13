class AnnabhagyaAngadi {
  const AnnabhagyaAngadi({
    required this.id,
    required this.name,
    required this.location,
  });

  final String id;
  final String name;
  final String location;
}

class GrainItem {
  const GrainItem({
    required this.itemName,
    required this.itemNameKn,
  });

  final String itemName;
  final String itemNameKn;
}

class DistributionSchedule {
  const DistributionSchedule({
    required this.distributionDate,
    required this.timeSlot,
    required this.items,
  });

  final DateTime distributionDate;
  final String timeSlot;
  final List<GrainItem> items;
}
