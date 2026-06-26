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

  static String normalizeEmail(String value) => value.trim().toLowerCase();

  static String normalizeDniDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  static bool isValidDni(String value) => normalizeDniDigits(value).length == 8;

  static bool isValidPassword(String value) => value.trim().length >= 8;

  static bool isValidVerificationCode(String value) => value.trim().isNotEmpty;

  /// Validación de campo obligatorio (formularios de registro/perfil).
  static String? validateRequiredField(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo requerido';
    return null;
  }

  static String? validateEmailField(String? value) {
    final required = validateRequiredField(value);
    if (required != null) return required;
    return isValidEmail(value!) ? null : 'Correo inválido';
  }

  static String? validatePhoneField(String? value) {
    final required = validateRequiredField(value);
    if (required != null) return required;
    return isValidPeruPhone(value!) ? null : 'Teléfono inválido';
  }

  static String? validateDniField(String? value) {
    final required = validateRequiredField(value);
    if (required != null) return required;
    return isValidDni(value!) ? null : 'DNI inválido';
  }

  static String? validatePasswordField(String? value) {
    final required = validateRequiredField(value);
    if (required != null) return required;
    return isValidPassword(value!) ? null : 'Mínimo 8 caracteres';
  }
}
