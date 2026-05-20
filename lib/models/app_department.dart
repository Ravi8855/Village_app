/// Departments assignable to department administrators.
enum AppDepartment {
  electricity('electricity', 'Electricity'),
  waterSupply('water_supply', 'Water Supply'),
  hospital('hospital', 'Hospital'),
  bank('bank', 'Bank'),
  postOffice('post_office', 'Post Office');

  const AppDepartment(this.value, this.label);

  final String value;
  final String label;

  static AppDepartment? fromValue(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final dept in AppDepartment.values) {
      if (dept.value == raw) return dept;
    }
    return null;
  }
}
