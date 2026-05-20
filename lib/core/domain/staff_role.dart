import 'department.dart';

/// Staff roles stored in [public.users.role]. Legacy [admin]/[user] unchanged.
enum StaffRole {
  user('user'),
  legacyAdmin('admin'),
  superAdmin('super_admin'),
  waterAdmin('water_admin'),
  hospitalAdmin('hospital_admin'),
  panchayatAdmin('panchayat_admin'),
  templeAdmin('temple_admin'),
  annabhagyaAdmin('annabhagya_admin'),
  bankAdmin('bank_admin'),
  postOfficeAdmin('postoffice_admin'),
  electricityAdmin('electricity_admin');

  const StaffRole(this.dbValue);

  final String dbValue;

  bool get isSuperAdmin => this == StaffRole.superAdmin;

  bool get isDepartmentAdmin =>
      this != StaffRole.user &&
      this != StaffRole.legacyAdmin &&
      this != StaffRole.superAdmin;

  bool get isStaff => isSuperAdmin || isDepartmentAdmin || this == StaffRole.legacyAdmin;

  VillageDepartment? get department {
    return switch (this) {
      StaffRole.waterAdmin => VillageDepartment.waterSupply,
      StaffRole.hospitalAdmin => VillageDepartment.hospital,
      StaffRole.panchayatAdmin => VillageDepartment.panchayat,
      StaffRole.templeAdmin => VillageDepartment.temples,
      StaffRole.annabhagyaAdmin => VillageDepartment.annabhagya,
      StaffRole.bankAdmin => VillageDepartment.bank,
      StaffRole.postOfficeAdmin => VillageDepartment.postOffice,
      StaffRole.electricityAdmin => VillageDepartment.electricity,
      _ => null,
    };
  }

  static StaffRole? fromDbValue(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final r in StaffRole.values) {
      if (r.dbValue == value) return r;
    }
    return null;
  }

  static StaffRole forDepartment(VillageDepartment department) {
    return switch (department) {
      VillageDepartment.waterSupply => StaffRole.waterAdmin,
      VillageDepartment.hospital => StaffRole.hospitalAdmin,
      VillageDepartment.panchayat => StaffRole.panchayatAdmin,
      VillageDepartment.temples => StaffRole.templeAdmin,
      VillageDepartment.annabhagya => StaffRole.annabhagyaAdmin,
      VillageDepartment.bank => StaffRole.bankAdmin,
      VillageDepartment.postOffice => StaffRole.postOfficeAdmin,
      VillageDepartment.electricity => StaffRole.electricityAdmin,
    };
  }
}
