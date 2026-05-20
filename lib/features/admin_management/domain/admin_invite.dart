import 'package:equatable/equatable.dart';

import '../../../core/domain/department.dart';
import '../../../core/domain/staff_role.dart';

class AdminInvite extends Equatable {
  const AdminInvite({
    required this.id,
    required this.mobileNumber,
    required this.fullName,
    required this.role,
    required this.department,
    required this.isApproved,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String mobileNumber;
  final String fullName;
  final StaffRole role;
  final VillageDepartment department;
  final bool isApproved;
  final bool isActive;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        mobileNumber,
        fullName,
        role,
        department,
        isApproved,
        isActive,
        createdAt,
      ];
}
