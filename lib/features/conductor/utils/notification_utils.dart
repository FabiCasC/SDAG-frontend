/// Reglas puras de notificaciones (push, voz y mensajes de viaje).
///
/// Alineado con:
/// - [PerfilConductorController.togglePush] — preferencia push del conductor
/// - [ConductorVoiceController._emit] — lectura por voz
/// - `_notificarLlegando` en pantallas de conductor
library;

/// Texto enviado al pasajero cuando el conductor pulsa «Ya estoy llegando».
String textoNotificacionLlegadaConductor() =>
    'El conductor ya esta llegando a tu punto de recojo. Preparate.';

/// Indica si el usuario tiene habilitadas las notificaciones push
/// ([PerfilConductorState.pushEnabled]).
bool pushNotificacionesHabilitado({required bool pushEnabled}) => pushEnabled;

/// Indica si el conductor tiene habilitada la lectura por voz
/// ([ConductorVoiceState.enabled]).
bool vozNotificacionesHabilitada({required bool vozHabilitada}) => vozHabilitada;

/// Emite banner de voz como en [ConductorVoiceController._emit].
String? bannerNotificacionVoz({
  required bool vozHabilitada,
  required String texto,
}) {
  if (!vozHabilitada) return null;
  if (texto.trim().isEmpty) return null;
  return '🔊 $texto';
}

/// RF-014 — datos mínimos para notificar llegada del conductor.
bool datosNotificacionLlegadaCompletos({
  required String tripId,
  required String passengerProfileId,
}) {
  return tripId.trim().isNotEmpty && passengerProfileId.trim().isNotEmpty;
}

/// RF-014 — puede enviarse la notificación de llegada.
bool puedeNotificarLlegadaConductor({
  required bool haySesion,
  required String tripId,
  required String passengerProfileId,
  required bool pushDestinatarioHabilitado,
}) {
  if (!haySesion) return false;
  if (!pushDestinatarioHabilitado) return false;
  return datosNotificacionLlegadaCompletos(
    tripId: tripId,
    passengerProfileId: passengerProfileId,
  );
}

/// Resultado al intentar enviar push: `null` = éxito, texto = motivo de fallo.
String? resultadoEnvioNotificacionPush({
  required bool pushHabilitado,
  required bool datosValidos,
}) {
  if (!datosValidos) return 'Datos incompletos';
  if (!pushHabilitado) return 'Notificaciones push desactivadas';
  return null;
}

/// RF-058 — notificar al conductor que el vehículo está lleno.
bool debeNotificarVehiculoLleno({
  required int occupiedSeats,
  required int capacity,
  required bool pushConductorHabilitado,
}) {
  return occupiedSeats >= capacity && pushConductorHabilitado;
}

/// RF-059 — notificar a pasajeros que el vehículo salió.
bool debeNotificarSalidaVehiculo({
  required String estadoViaje,
  required bool hayPasajeros,
}) {
  return estadoViaje == 'en_ruta' && hayPasajeros;
}

/// RF-060 — notificar solicitud de forzar salida.
bool debeNotificarSolicitudForzarSalida({required bool solicitudActiva}) =>
    solicitudActiva;

bool forzarSalidaRechazadaPorPasajero({
  required int rechazos,
}) =>
    rechazos > 0;

bool forzarSalidaTiempoExpirado({
  required bool tiempoExpirado,
  required int respuestasRecibidas,
  required int totalPasajeros,
}) =>
    tiempoExpirado && respuestasRecibidas < totalPasajeros;

/// RF-068 — notificar al admin sobre nueva solicitud de pago de comisión.
bool puedeNotificarAdminSolicitudPago({
  required bool solicitudValida,
  required bool adminConectado,
}) =>
    solicitudValida && adminConectado;

/// RF-088 — notificar bloqueo al conductor.
bool debeNotificarBloqueoConductor({
  required bool cuentaActiva,
  required bool pushConductorHabilitado,
}) =>
    !cuentaActiva && pushConductorHabilitado;

String mensajeNotificacionBloqueoConductor() =>
    'Cuenta suspendida. Contacta al administrador.';

/// RF-122 — notificar al conductor que un pasajero canceló.
bool puedeNotificarCancelacionAlConductor({
  required bool hayReserva,
  required String estadoViaje,
  required bool conductorConectado,
}) {
  if (!hayReserva) return false;
  if (estadoViaje == 'en_ruta') return false;
  return conductorConectado;
}

/// RF-126 — notificar al pasajero que el conductor completó la ruta.
bool puedeNotificarRutaCompletadaAlPasajero({
  required bool rutaCompletada,
  required bool pasajeroSigueEnViaje,
  required bool pasajeroConectado,
}) {
  if (!rutaCompletada) return false;
  if (!pasajeroSigueEnViaje) return false;
  return pasajeroConectado;
}
