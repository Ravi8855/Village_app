/// Shared field validators returning a user-facing error message, or null if ok.
class FormValidators {
  FormValidators._();

  static String? firstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter first name';
    }
    return null;
  }

  static String? lastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter last name';
    }
    return null;
  }

  static String? mobile(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Please enter mobile number';
    if (digits.length != 10) {
      return 'Please enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter email';
    if (!email.contains('@')) return 'Email must contain @';
    final pattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!pattern.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? gender(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select gender';
    }
    return null;
  }

  static String? temporaryPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a temporary password';
    }
    if (value.trim().length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }
}
