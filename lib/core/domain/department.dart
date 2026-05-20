/// Village departments managed by department admins.
enum VillageDepartment {
  waterSupply('water_supply', 'Water Supply'),
  hospital('hospital', 'Hospital'),
  panchayat('panchayat', 'Panchayat'),
  temples('temples', 'Temples'),
  annabhagya('annabhagya', 'ಅನ್ನಭಾಗ್ಯ ಯೋಜನೆ'),
  bank('bank', 'Bank'),
  postOffice('post_office', 'Post Office'),
  electricity('electricity', 'Electricity');

  const VillageDepartment(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static VillageDepartment? fromDbValue(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final d in VillageDepartment.values) {
      if (d.dbValue == value) return d;
    }
    return null;
  }
}
