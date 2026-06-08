class PassengerAuthValidators {
  PassengerAuthValidators._();

  static bool isValidEmail(String value) {
    final v = value.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(v);
  }

  static String? normalizePeruPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    if (digits.length == 9 && digits.startsWith('9')) return digits;
    if (digits.length == 11 && digits.startsWith('51') && digits.substring(2).startsWith('9')) {
      return digits.substring(2);
    }
    return null;
  }

  static bool isValidPeruPhone(String value) => normalizePeruPhone(value) != null;
}
