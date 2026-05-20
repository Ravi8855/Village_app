import 'package:equatable/equatable.dart';

import '../../../core/domain/department.dart';

class DepartmentUpdate extends Equatable {
  const DepartmentUpdate({
    required this.id,
    required this.department,
    required this.title,
    required this.description,
    this.imageUrl,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final VillageDepartment department;
  final String title;
  final String description;
  final String? imageUrl;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        department,
        title,
        description,
        imageUrl,
        createdBy,
        createdAt,
        updatedAt,
      ];
}
