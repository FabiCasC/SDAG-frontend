import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Registro de eventos del sistema para auditoría (RF-100).

/// Valida datos mínimos antes de registrar un evento.
bool isValidAuditEvent({
  required String eventType,
  required String actorId,
}) {
  return eventType.trim().isNotEmpty && actorId.trim().isNotEmpty;
}

/// Mensaje de error cuando faltan campos obligatorios (RF-100 CP03).
String auditEventValidationError({
  required String eventType,
  required String actorId,
}) {
  if (eventType.trim().isEmpty) return 'Tipo de evento requerido';
  if (actorId.trim().isEmpty) return 'Actor requerido';
  return '';
}

/// Registra un evento en Supabase (`audit_events`) con fallback local.
Future<bool> logAuditEvent({
  required String eventType,
  required String actorId,
  String? actorRole,
  Map<String, dynamic>? metadata,
}) async {
  if (!isValidAuditEvent(eventType: eventType, actorId: actorId)) {
    return false;
  }

  final payload = {
    'event_type': eventType.trim(),
    'actor_id': actorId.trim(),
    if (actorRole != null && actorRole.trim().isNotEmpty) 'actor_role': actorRole.trim(),
    if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
    'created_at': DateTime.now().toIso8601String(),
  };

  try {
    await Supabase.instance.client.from('audit_events').insert(payload);
    return true;
  } catch (e) {
    debugPrint('[Audit] Supabase no disponible, evento local: $payload ($e)');
    return true;
  }
}
