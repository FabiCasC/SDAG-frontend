/// Mapeo puro de payloads FCM para tests TDD (RF-014, RF-058, RF-122).

String tituloNotificacionFcm(String type) {
  switch (type.trim().toLowerCase()) {
    case 'trip_started':
    case 'viaje_en_marcha':
    case 'viaje_iniciado':
      return '¡Tu viaje ha iniciado!';
    case 'new_reservation':
    case 'nueva_reserva':
      return 'Nueva reserva';
    case 'trip_completed':
    case 'ruta_completada':
      return 'Ruta completada';
    case 'trip_message':
    case 'nuevo_mensaje':
      return 'Nuevo mensaje';
    default:
      return '';
  }
}

String cuerpoNotificacionFcm(String type) {
  switch (type.trim().toLowerCase()) {
    case 'trip_started':
    case 'viaje_en_marcha':
    case 'viaje_iniciado':
      return 'El vehículo está en marcha';
    case 'new_reservation':
    case 'nueva_reserva':
      return 'Tienes una nueva reserva en tu viaje';
    case 'trip_completed':
    case 'ruta_completada':
      return 'Gracias por viajar con SDAG. ¡No olvides calificar a tu conductor!';
    case 'trip_message':
    case 'nuevo_mensaje':
      return 'Nuevo mensaje en el chat del viaje';
    default:
      return '';
  }
}

bool payloadFcmReconocido(String type) {
  return tituloNotificacionFcm(type).isNotEmpty;
}
