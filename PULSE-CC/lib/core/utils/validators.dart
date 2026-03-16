class Validators {
  Validators._();

  static String? validateAuthorityId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Authority ID is required';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateOfficerId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Officer ID is required';
    }
    return null;
  }
}
