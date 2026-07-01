class AppRoutes {
  static const splash = '/';

  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  static const roleSelect = '/role';

  static const passengerHome = '/passenger/home';
  static const passengerTrips = '/passenger/trips';
  static const passengerNews = '/passenger/news';
  static const passengerProfile = '/passenger/profile';
  static const passengerPaymentMethods = '/passenger/payment-methods';
  static const passengerSearch = '/passenger/busqueda';
  static const passengerReservationDetail = '/passenger/reserva-detalle';
  static const passengerDriverDetail = '/passenger/conductor';
  static const passengerSeatMap = '/passenger/asientos';
  static const passengerReservaAcompanantes = '/passenger/reserva/acompanantes';
  static const passengerReservaPickup = '/passenger/reserva/pickup';
  static const passengerReservaResumen = '/passenger/reserva/resumen';
  static const passengerPago = '/passenger/pago';
  static const passengerConfirmacion = '/passenger/confirmacion';
  static const passengerReservaActiva = '/passenger/reserva-activa';
  static const passengerForzarSalida = '/passenger/forzar-salida';
  static const passengerCancelarReserva = '/passenger/cancelar-reserva';
  static const passengerMapaViaje = '/passenger/mapa-viaje';
  static const passengerViajeEnCurso = '/passenger/viaje-en-curso';
  static const passengerChat = '/passenger/chat';
  static const passengerCalificacion = '/passenger/calificacion';
  static const passengerTripDetail = '/passenger/viaje';
  static const passengerQr = '/passenger/qr';
  static const passengerNewsDetail = '/passenger/noticia';
  static const passengerReembolso = '/passenger/reembolso';

  static const driverHome = '/conductor/home';
  static const driverLogin = '/conductor/login';
  static const driverForgotPassword = '/conductor/forgot-password';
  static const driverGestionViaje = '/conductor/gestion-viaje';
  static const driverMapa = '/conductor/mapa';
  static const driverPasajeros = '/conductor/pasajeros';
  static const driverQrScanner = '/conductor/qr-scanner';
  static const driverManifiesto = '/conductor/manifiesto';
  static const driverChat = '/conductor/chat/:pasajeroId';
  static const driverChatGrupal = '/conductor/chat-grupal';
  static const driverComisiones = '/conductor/comisiones';
  static const driverHistorial = '/conductor/historial';
  static const driverHistorialChats = '/conductor/historial-chats';
  static const driverNoticias = '/conductor/noticias';
  static const driverNoticiasDetalle = '/conductor/noticias/:id';
  static const driverNoticiasNueva = '/conductor/noticias/nueva';
  static const driverProfile = '/conductor/perfil';

  static const adminHome = '/admin/home';
  static const adminFleet = '/admin/fleet';
  static const adminSettings = '/admin/settings';

  static const adminLogin = '/admin/login';
  static const adminForgotPassword = '/admin/forgot-password';
  static const adminBloqueado = '/admin/bloqueado';
  static const adminConductores = '/admin/conductores';
  static const adminConductoresNuevo = '/admin/conductores/nuevo';
  static const adminConductoresDetalle = '/admin/conductores/:id';
  static const adminConductoresEditar = '/admin/conductores/:id/editar';
  static const adminConductoresHistorial = '/admin/conductores/:id/historial';
  static const adminVehiculos = '/admin/vehiculos';
  static const adminVehiculosNuevo = '/admin/vehiculos/nuevo';
  static const adminPagos = '/admin/pagos';
  static const adminPagosHistorial = '/admin/pagos/historial';
  static const adminMonitoreo = '/admin/monitoreo';
  static const adminManifiestos = '/admin/manifiestos';
  static const adminManifiestosDetalle = '/admin/manifiestos/:manifestId';
  static const adminAnalitica = '/admin/analitica';
  static const adminCalificaciones = '/admin/calificaciones';
  static const adminHistorialViajes = '/admin/historial-viajes';
  static const adminViajeDetalle = '/admin/historial-viajes/:viajeId';
  static const adminConfiguracion = '/admin/configuracion';
  static const adminPerfil = '/admin/perfil';
  static const adminChatGrupal = '/admin/chat-grupal';
}
