import 'package:equatable/equatable.dart';

enum PanchayatSectionType {
  waterSupply,
  electricity,
  knowledgeBoard,
}

extension PanchayatSectionTypeX on PanchayatSectionType {
  String get label {
    switch (this) {
      case PanchayatSectionType.waterSupply:
        return 'Water Supply';
      case PanchayatSectionType.electricity:
        return 'Electricity Supply';
      case PanchayatSectionType.knowledgeBoard:
        return 'Gram KB / Knowledge Board';
    }
  }

  String get dbValue {
    switch (this) {
      case PanchayatSectionType.waterSupply:
        return 'water_supply';
      case PanchayatSectionType.electricity:
        return 'electricity';
      case PanchayatSectionType.knowledgeBoard:
        return 'knowledge_board';
    }
  }

  static PanchayatSectionType fromDb(String? value) {
    switch (value) {
      case 'water_supply':
        return PanchayatSectionType.waterSupply;
      case 'electricity':
        return PanchayatSectionType.electricity;
      case 'knowledge_board':
        return PanchayatSectionType.knowledgeBoard;
      default:
        return PanchayatSectionType.waterSupply;
    }
  }
}

enum PanchayatItemStatus { active, scheduled, completed, cancelled, upcoming, closed }

extension PanchayatItemStatusX on PanchayatItemStatus {
  String get label {
    switch (this) {
      case PanchayatItemStatus.active:
        return 'Active';
      case PanchayatItemStatus.scheduled:
        return 'Scheduled';
      case PanchayatItemStatus.completed:
        return 'Completed';
      case PanchayatItemStatus.cancelled:
        return 'Cancelled';
      case PanchayatItemStatus.upcoming:
        return 'Upcoming';
      case PanchayatItemStatus.closed:
        return 'Closed';
    }
  }
}

class PanchayatService extends Equatable {
  const PanchayatService({
    required this.id,
    required this.sectionType,
    required this.title,
    required this.description,
    required this.status,
    this.imageUrl,
    this.eventDate,
    this.createdAt,
  });

  final String id;
  final PanchayatSectionType sectionType;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime? eventDate;
  final PanchayatItemStatus status;
  final DateTime? createdAt;

  @override
  List<Object?> get props =>
      [id, sectionType, title, description, imageUrl, eventDate, status, createdAt];
}

class Yojana extends Equatable {
  const Yojana({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.imageUrl,
    this.eventDate,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime? eventDate;
  final PanchayatItemStatus status;
  final DateTime? createdAt;

  @override
  List<Object?> get props =>
      [id, title, description, imageUrl, eventDate, status, createdAt];
}
