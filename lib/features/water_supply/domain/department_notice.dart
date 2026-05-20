import 'package:equatable/equatable.dart';

/// A department-scoped notice (e.g. water_supply).
class DepartmentNotice extends Equatable {
  const DepartmentNotice({
    required this.id,
    required this.department,
    required this.title,
    required this.description,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  static const waterSupplyDepartment = 'water_supply';

  final String id;
  final String department;
  final String title;
  final String description;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        department,
        title,
        description,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
