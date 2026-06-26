/// Validadores y reglas de negocio puras de SDAG (Momento 3 TDD — UTP).
///
/// Funciones extraídas de la app sin dependencia de UI, Supabase ni providers:
/// - [PassengerAuthValidators] — registro, login, perfil
/// - [validateCardPaymentFields] — pago en pasarela
/// - [qr_scan_utils] — QR por asiento
/// - [busqueda_utils] — conductores y asientos disponibles
/// - [passenger_db_error_mapping] — errores duplicados en BD
import '../../app/providers/passenger/utils/passenger_db_error_mapping.dart';
import '../../app/providers/passenger/validators/passenger_auth_validators.dart';
import '../../features/busqueda/utils/busqueda_utils.dart';
import '../../features/conductor/utils/qr_scan_utils.dart';
import '../../features/conductor/utils/notification_utils.dart';
import '../../features/reserva/utils/payment_validation.dart';

export '../../features/conductor/utils/notification_utils.dart';

/// Tarifa fija por asiento (S/15), alineada con [ReservaState.montoTotal].
const double kTarifaPorAsiento = 15.0;

// ── Validación de campos de registro / perfil ───────────────────────────────

String? validarCampoRequerido(String? v) {
  if (v == null || v.trim().isEmpty) return 'Campo requerido';
  return null;
}

String? validarEmail(String? v) {
  final required = validarCampoRequerido(v);
  if (required != null) return required;
  if (!PassengerAuthValidators.isValidEmail(v!)) return 'Correo inválido';
  return null;
}

String? validarTelefono(String? v) {
  final required = validarCampoRequerido(v);
  if (required != null) return required;
  if (!PassengerAuthValidators.isValidPeruPhone(v!)) return 'Teléfono inválido';
  return null;
}

String? validarDNI(String? v) {
  final required = validarCampoRequerido(v);
  if (required != null) return required;
  if (!PassengerAuthValidators.isValidDni(v!)) return 'DNI inválido';
  return null;
}

String? validarPassword(String? v) {
  final required = validarCampoRequerido(v);
  if (required != null) return required;
  if (!PassengerAuthValidators.isValidPassword(v!)) return 'Mínimo 8 caracteres';
  return null;
}

String? validarPuntoRecojo(String? v) {
  if (v == null || v.trim().isEmpty) return 'Campo vacío';
  if (v.trim().length < 3) return 'Texto demasiado corto';
  return null;
}

String? validarCodigoVerificacion(String? v) {
  final required = validarCampoRequerido(v);
  if (required != null) return required;
  if (!PassengerAuthValidators.isValidVerificationCode(v!)) {
    return 'Código inválido';
  }
  return null;
}

// ── Mapeo de errores de autenticación / registro ────────────────────────────

String mapRegistroErrorDuplicado(String message) {
  final kind = classifyUniqueViolation(message: message);
  if (kind == UniqueViolationKind.email ||
      message.toLowerCase().contains('already')) {
    return 'EmailDuplicadoFailure';
  }
  return 'GenericFailure';
}

String mapAuthExceptionError(String type) {
  return type == 'AuthException' ? 'InvalidCredentialsFailure' : 'GenericFailure';
}

String mapPlacaDuplicadaError(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('placa') || lower.contains('plate')) {
    return 'PlacaDuplicadaFailure';
  }
  return 'GenericFailure';
}

String mensajeCuentaBloqueada(bool bloqueada) {
  return bloqueada ? 'Cuenta suspendida. Contacta al administrador.' : '';
}

// ── Pago ────────────────────────────────────────────────────────────────────

bool validarNumeroTarjeta(String n) {
  return n.replaceAll(RegExp(r'\D'), '').length == 16;
}

bool validarCVV(String c) {
  return c.replaceAll(RegExp(r'\D'), '').length == 3;
}

String? validarCamposPagoTarjeta({
  required String cardNumber,
  required String cvv,
  required String expiry,
  required String holder,
}) {
  return validateCardPaymentFields(
    cardNumber: cardNumber,
    cvv: cvv,
    expiry: expiry,
    holder: holder,
  );
}

String resultadoPagoCulqi(int statusCode, String? message) {
  return statusCode != 201 ? (message ?? 'Tarjeta rechazada') : 'ok';
}

double calcularMontoPago(int asientos) => asientos * kTarifaPorAsiento;

int calcularMontoCentimos(int asientos) => paymentAmountCents(asientos);

bool pagoReservaCompletado(bool pagoExitoso) => pagoExitoso;

// ── QR ──────────────────────────────────────────────────────────────────────

String generarQRData(String reservaId, int asiento) {
  return buildPassengerQrData(reservaId: reservaId, seatNumber: asiento);
}

bool puedeEscanearQR(String qrValue) {
  final payload = parseQrScanValue(qrValue);
  return isValidReservationUuid(payload.reservaId);
}

// ── Asientos ────────────────────────────────────────────────────────────────

bool asientoPuedeSeleccionarse(int asiento, Set<int> ocupados) {
  return !ocupados.contains(asiento);
}

int contarAsientosDisponibles({
  required int capacidad,
  required int ocupados,
}) {
  return availableSeatsCount(totalSeats: capacidad, occupiedSeats: ocupados);
}

bool hayAsientosDisponibles({
  required int capacidad,
  required int ocupados,
}) {
  return hasAvailableSeats(totalSeats: capacidad, occupiedSeats: ocupados);
}

// ── Estado de viaje / abordaje ──────────────────────────────────────────────

bool reembolsoPosible(String tripStatus) => tripStatus == 'esperando';

bool bajadaPermitida(String boardingStatus) => boardingStatus == 'abordo';

String mensajeConductorNoDisponible(String tripStatus) {
  return tripStatus != 'esperando' ? 'Conductor no disponible' : '';
}

bool conductorDisponibleParaReserva(String tripStatus) => tripStatus == 'esperando';

bool vehiculoLlenoParaSalir({
  required int ocupados,
  required int capacidad,
  bool salidaForzadaAceptada = false,
}) {
  if (salidaForzadaAceptada) return true;
  return ocupados >= capacidad;
}

String resultadoSinConexion(bool conectado) {
  return conectado ? 'datos frescos' : 'último estado conocido';
}

String accionSesionExpirada(bool sesionActiva) {
  return sesionActiva ? 'continuar' : 'solicitar login';
}

// ── Comisiones ──────────────────────────────────────────────────────────────

bool validarPorcentajeComision(double p) => p >= 0 && p <= 100;

double calcularComisionConductor(double recaudado, double porcentaje) {
  return recaudado * porcentaje / 100;
}

double calcularRecaudadoConductor(int asientosOcupados) {
  return asientosOcupados * kTarifaPorAsiento;
}

// ── Búsqueda / conductores ──────────────────────────────────────────────────

bool conductorElegibleParaListado({
  required bool? cuentaActiva,
  required String? estado,
}) {
  return isDriverEligibleForListing(cuentaActiva: cuentaActiva, estado: estado);
}

bool rutaCoincideDireccion({
  required String? fromLabel,
  required String direction,
}) {
  return matchesTripDirection(fromLabel: fromLabel, direction: direction);
}

String etiquetaOrigenEsperada(String direction) {
  return expectedFromLabelForDirection(direction);
}

// ── Helpers para flujos exitosos en tests ───────────────────────────────────

bool flujoRegistroPasajeroValido() {
  return validarEmail('pasajero@test.com') == null &&
      validarTelefono('987654321') == null &&
      validarDNI('12345678') == null &&
      validarPassword('password123') == null;
}

bool flujoLoginValido() {
  return validarEmail('pasajero@test.com') == null &&
      validarPassword('password123') == null;
}

bool flujoPuntoRecojoValido() {
  return validarPuntoRecojo('Av. Principal 123, Chosica') == null;
}

bool flujoPerfilValido() {
  return validarEmail('editado@test.com') == null &&
      validarTelefono('912345678') == null;
}

bool flujoTarifaValida() {
  return calcularMontoPago(1) == kTarifaPorAsiento &&
      calcularMontoCentimos(2) == 3000;
}

bool flujoQRValido() {
  const uuid = '9b4020ff-4a93-48e4-9931-b861b5dfa482';
  final qr = generarQRData(uuid, 1);
  return puedeEscanearQR(qr);
}

bool flujoPagoTarjetaValido() {
  return validarNumeroTarjeta('4111111111111111') &&
      validarCVV('123') &&
      validarCamposPagoTarjeta(
            cardNumber: '4111111111111111',
            cvv: '123',
            expiry: '12/28',
            holder: 'Juan Perez',
          ) ==
          null;
}

bool validacionCamposIncompletos(String? campo) {
  return validarCampoRequerido(campo) != null;
}

bool validacionFormatoEmailInvalido() {
  return validarEmail('correo-sin-arroba') != null;
}

bool validacionFormatoTelefonoInvalido() {
  return validarTelefono('12345') == 'Teléfono inválido';
}

bool validacionFormatoDniInvalido() {
  return validarDNI('1234') == 'DNI inválido';
}

bool validacionFormatoPagoInvalido() {
  return validarCamposPagoTarjeta(
        cardNumber: '1234',
        cvv: '12',
        expiry: '00/00',
        holder: 'X',
      ) !=
      null;
}

// ── Notificaciones (push / voz / mensajes de viaje) ───────────────────────

bool flujoNotificacionLlegadaValido() => puedeNotificarLlegadaConductor(
      haySesion: true,
      tripId: 'trip-001',
      passengerProfileId: 'passenger-001',
      pushDestinatarioHabilitado: true,
    );

bool flujoNotificacionVozValido() =>
    bannerNotificacionVoz(vozHabilitada: true, texto: 'Próxima parada: Juan') !=
    null;

bool flujoNotificacionVehiculoLlenoValido() => debeNotificarVehiculoLleno(
      ocupados: 4,
      capacidad: 4,
      pushConductorHabilitado: true,
    );
