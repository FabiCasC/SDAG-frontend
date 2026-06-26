/// Clasificación de errores únicos de Postgres/Supabase (extraído del repositorio).
enum UniqueViolationKind {
  email,
  phone,
  dni,
  duplicateCode,
  none,
}

UniqueViolationKind classifyUniqueViolation({
  required String message,
  String? code,
}) {
  final lower = message.toLowerCase();
  if (lower.contains('email')) return UniqueViolationKind.email;
  if (lower.contains('phone')) return UniqueViolationKind.phone;
  if (lower.contains('dni')) return UniqueViolationKind.dni;
  if (code == '23505') return UniqueViolationKind.duplicateCode;
  return UniqueViolationKind.none;
}

String normalizeDbMessage(String message) {
  final msg = message.trim();
  return msg.isEmpty ? 'Error de base de datos' : msg;
}

/// Etiqueta de fallo al registrar (mapeo usado en repositorio Supabase).
String registrationFailureType(String message) {
  final kind = classifyUniqueViolation(message: message);
  if (kind == UniqueViolationKind.email ||
      message.toLowerCase().contains('already')) {
    return 'EmailDuplicadoFailure';
  }
  return 'GenericFailure';
}

String authFailureTypeFromExceptionType(String type) {
  return type == 'AuthException' ? 'InvalidCredentialsFailure' : 'GenericFailure';
}

String placaDuplicateFailureType(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('placa') || lower.contains('plate')) {
    return 'PlacaDuplicadaFailure';
  }
  return 'GenericFailure';
}

String blockedAccountMessage({required bool accountActive}) {
  return accountActive ? '' : 'Cuenta suspendida. Contacta al administrador.';
}
