import 'audit_log_service.dart';

bool eventoAuditoriaValido(String eventType, String actorRole) {
  return isValidAuditEvent(eventType: eventType, actorId: '00000000-0000-0000-0000-000000000001') &&
      actorRole.trim().isNotEmpty;
}
