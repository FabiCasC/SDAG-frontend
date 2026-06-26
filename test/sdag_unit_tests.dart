import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/busqueda/screens/busqueda_service.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/reserva/providers/reserva_provider.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';

void main() {
  group('RF-001 — Registro de pasajero', () {
    test('CP01 — email valido aceptado', () {
      expect(PassengerAuthValidators.isValidEmail('maria@mail.com'), isTrue);
      print('✅ CP01 PASS — email valido aceptado');
    });

    test('CP02 — email invalido rechazado', () {
      expect(PassengerAuthValidators.isValidEmail('correo-invalido'), isFalse);
      print('✅ CP02 PASS — email invalido rechazado');
    });

    test('CP03 — DNI de 8 digitos valido', () {
      expect(PassengerAuthValidators.isValidDni('12345678'), isTrue);
      expect(PassengerAuthValidators.normalizeDniDigits('12.345.678'), '12345678');
      print('✅ CP03 PASS — DNI de 8 digitos valido');
    });

    test('CP04 — DNI con longitud incorrecta rechazado', () {
      expect(PassengerAuthValidators.isValidDni('1234567'), isFalse);
      print('✅ CP04 PASS — DNI con longitud incorrecta rechazado');
    });

    test('CP05 — contrasena minimo 8 caracteres', () {
      expect(PassengerAuthValidators.isValidPassword('12345678'), isTrue);
      expect(PassengerAuthValidators.isValidPassword('1234567'), isFalse);
      print('✅ CP05 PASS — contrasena minimo 8 caracteres');
    });
  });

  group('RF-002 — Inicio de sesion de pasajero', () {
    test('CP01 — normaliza email a minusculas', () {
      expect(PassengerAuthValidators.normalizeEmail('  Usuario@Mail.COM '), 'usuario@mail.com');
      print('✅ CP01 PASS — normaliza email a minusculas');
    });
  });

  group('RF-003 — Telefono peruano', () {
    test('CP01 — celular 9 digitos valido', () {
      expect(PassengerAuthValidators.isValidPeruPhone('987654321'), isTrue);
      print('✅ CP01 PASS — celular 9 digitos valido');
    });

    test('CP02 — formato +51 valido', () {
      expect(PassengerAuthValidators.normalizePeruPhone('+51 987 654 321'), '987654321');
      print('✅ CP02 PASS — formato +51 valido');
    });

    test('CP03 — telefono invalido rechazado', () {
      expect(PassengerAuthValidators.isValidPeruPhone('12345'), isFalse);
      print('✅ CP03 PASS — telefono invalido rechazado');
    });
  });

  group('RF-005 / RF-069 — Busqueda de conductores', () {
    test('CP01 — direccion si_cho espera San Isidro', () {
      expect(expectedFromLabelForDirection('si_cho'), 'San Isidro');
      print('✅ CP01 PASS — direccion si_cho espera San Isidro');
    });

    test('CP02 — direccion cho_si espera Chosica', () {
      expect(expectedFromLabelForDirection('cho_si'), 'Chosica');
      print('✅ CP02 PASS — direccion cho_si espera Chosica');
    });

    test('CP03 — filtra viaje por from_label', () {
      expect(
        matchesTripDirection(fromLabel: 'San Isidro', direction: 'si_cho'),
        isTrue,
      );
      expect(
        matchesTripDirection(fromLabel: 'Chosica', direction: 'si_cho'),
        isFalse,
      );
      print('✅ CP03 PASS — filtra viaje por from_label');
    });

    test('CP04 — conductor inactivo no aparece', () {
      expect(
        isDriverEligibleForListing(cuentaActiva: true, estado: 'inactivo'),
        isFalse,
      );
      print('✅ CP04 PASS — conductor inactivo no aparece');
    });

    test('CP05 — cuenta inactiva no aparece', () {
      expect(
        isDriverEligibleForListing(cuentaActiva: false, estado: 'disponible'),
        isFalse,
      );
      print('✅ CP05 PASS — cuenta inactiva no aparece');
    });

    test('CP06 — calcula asientos disponibles', () {
      final rows = [
        {'seats': [1, 2]},
        {'seats': [3]},
      ];
      expect(countOccupiedSeatsFromReservationRows(rows), 3);
      expect(
        availableSeatsCount(totalSeats: 15, occupiedSeats: 3),
        12,
      );
      expect(hasAvailableSeats(totalSeats: 15, occupiedSeats: 15), isFalse);
      print('✅ CP06 PASS — calcula asientos disponibles');
    });

    test('CP07 — construye etiqueta de ruta', () {
      expect(
        buildRouteLabel(name: 'Ruta Express', from: 'San Isidro', to: 'Chosica'),
        'Ruta Express',
      );
      expect(
        buildRouteLabel(from: 'San Isidro', to: 'Chosica'),
        'San Isidro → Chosica',
      );
      print('✅ CP07 PASS — construye etiqueta de ruta');
    });
  });

  group('RF-008 / RF-053 — Monto de reserva S/15', () {
    test('CP01 — monto total por asientos', () {
      const state = ReservaState(
        reservaId: null,
        conductorSeleccionado: null,
        asientosSeleccionados: [1, 4, 7],
        acompanantes: {},
        puntoRecojo: null,
        vehiculoPartio: false,
        additionalChargePending: false,
        additionalChargeAmount: 0,
      );
      expect(state.montoTotal, 45.0);
      print('✅ CP01 PASS — monto total por asientos');
    });

    test('CP02 — monto con cargo adicional pendiente', () {
      const state = ReservaState(
        reservaId: 'r1',
        conductorSeleccionado: null,
        asientosSeleccionados: [2],
        acompanantes: {},
        puntoRecojo: 'Av. Javier Prado',
        vehiculoPartio: true,
        additionalChargePending: true,
        additionalChargeAmount: 15.0,
      );
      expect(state.montoTotalFinal, 30.0);
      print('✅ CP02 PASS — monto con cargo adicional pendiente');
    });

    test('CP03 — ReservaController normaliza asientos duplicados', () {
      final controller = ReservaController();
      controller.startWithDriver(
        const ReservaDriverInfo(
          tripId: 'trip-1',
          driverId: 'driver-1',
          name: 'Juan',
          plate: 'ABC-123',
          vehicleType: 'Van',
          totalSeats: 15,
          routeLabel: 'San Isidro → Chosica',
          rating: 4.5,
          ratingCount: 10,
          status: 'esperando',
        ),
      );
      controller.setSelectedSeats([5, 2, 5, 9]);
      expect(controller.state.asientosSeleccionados, [2, 5, 9]);
      expect(controller.state.montoTotal, 45.0);
      print('✅ CP03 PASS — ReservaController normaliza asientos duplicados');
    });

    test('CP04 — startWithDriver ignora tripId vacio', () {
      final controller = ReservaController();
      controller.startWithDriver(
        const ReservaDriverInfo(
          tripId: '   ',
          driverId: 'driver-1',
          name: 'Juan',
          plate: 'ABC-123',
          vehicleType: 'Van',
          totalSeats: 15,
          routeLabel: 'Ruta',
          rating: 0,
          ratingCount: 0,
          status: 'esperando',
        ),
      );
      expect(controller.state.conductorSeleccionado, isNull);
      print('✅ CP04 PASS — startWithDriver ignora tripId vacio');
    });
  });

  group('RF-010 / RF-114 — Validacion de pago', () {
    test('CP01 — tarjeta valida pasa validacion', () {
      expect(
        validateCardPaymentFields(
          cardNumber: '4111111111111111',
          cvv: '123',
          expiry: '12/28',
          holder: 'Maria Lopez',
        ),
        isNull,
      );
      print('✅ CP01 PASS — tarjeta valida pasa validacion');
    });

    test('CP02 — tarjeta con numero invalido', () {
      expect(
        validateCardPaymentFields(
          cardNumber: '411111',
          cvv: '123',
          expiry: '12/28',
          holder: 'Maria Lopez',
        ),
        'Número de tarjeta inválido',
      );
      print('✅ CP02 PASS — tarjeta con numero invalido');
    });

    test('CP03 — parseCardExpiry extrae mes y anio', () {
      expect(parseCardExpiry('08/27'), (8, 27));
      expect(parseCardExpiry('bad'), (0, 0));
      print('✅ CP03 PASS — parseCardExpiry extrae mes y anio');
    });

    test('CP04 — monto en centavos Culqi', () {
      expect(paymentAmountCents(2), 3000);
      expect(culqiExpirationYear(27), 2027);
      print('✅ CP04 PASS — monto en centavos Culqi');
    });

    test('CP05 — Yape requiere 9 digitos', () {
      expect(isYapePhoneComplete('987654321'), isTrue);
      expect(isYapePhoneComplete('98765'), isFalse);
      print('✅ CP05 PASS — Yape requiere 9 digitos');
    });

    test('CP06 — formulario tarjeta nueva completo', () {
      expect(
        isNewCardFormComplete(
          cardNumber: '4111 1111 1111 1111',
          cvv: '123',
          expiry: '12/28',
          holder: 'Ana Perez',
        ),
        isTrue,
      );
      print('✅ CP06 PASS — formulario tarjeta nueva completo');
    });
  });

  group('RF-018 / RF-025 / RF-055 — QR de abordaje', () {
    const uuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

    test('CP01 — parsea QR con reservaId y asiento', () {
      final payload = parseQrScanValue('$uuid|7');
      expect(payload.reservaId, uuid);
      expect(payload.seatNumber, 7);
      print('✅ CP01 PASS — parsea QR con reservaId y asiento');
    });

    test('CP02 — parsea QR solo con reservaId', () {
      final payload = parseQrScanValue(uuid);
      expect(payload.reservaId, uuid);
      expect(payload.seatNumber, isNull);
      print('✅ CP02 PASS — parsea QR solo con reservaId');
    });

    test('CP03 — elimina prefijo res_', () {
      final payload = parseQrScanValue('res_$uuid|3');
      expect(payload.reservaId, uuid);
      expect(payload.seatNumber, 3);
      print('✅ CP03 PASS — elimina prefijo res_');
    });

    test('CP04 — valida UUID de reserva', () {
      expect(isValidReservationUuid(uuid), isTrue);
      expect(isValidReservationUuid('no-es-uuid'), isFalse);
      print('✅ CP04 PASS — valida UUID de reserva');
    });

    test('CP05 — genera QR por asiento', () {
      expect(buildPassengerQrData(reservaId: uuid, seatNumber: 4), '$uuid|4');
      print('✅ CP05 PASS — genera QR por asiento');
    });

    test('CP06 — asiento pertenece a reserva', () {
      expect(isSeatInReservation(2, [1, 2, 3]), isTrue);
      expect(isSeatInReservation(9, [1, 2, 3]), isFalse);
      print('✅ CP06 PASS — asiento pertenece a reserva');
    });
  });

  group('RF-065 — Recuperacion de contrasena', () {
    test('CP01 — codigo de verificacion no vacio', () {
      expect(PassengerAuthValidators.isValidVerificationCode('123456'), isTrue);
      expect(PassengerAuthValidators.isValidVerificationCode('   '), isFalse);
      print('✅ CP01 PASS — codigo de verificacion no vacio');
    });
  });

  group('RF-DB — Mapeo de errores Supabase', () {
    test('CP01 — detecta email duplicado', () {
      expect(
        classifyUniqueViolation(message: 'duplicate key email already exists', code: null),
        UniqueViolationKind.email,
      );
      print('✅ CP01 PASS — detecta email duplicado');
    });

    test('CP02 — detecta telefono duplicado', () {
      expect(
        classifyUniqueViolation(message: 'duplicate phone value', code: null),
        UniqueViolationKind.phone,
      );
      print('✅ CP02 PASS — detecta telefono duplicado');
    });

    test('CP03 — detecta DNI duplicado', () {
      expect(
        classifyUniqueViolation(message: 'duplicate dni key', code: null),
        UniqueViolationKind.dni,
      );
      print('✅ CP03 PASS — detecta DNI duplicado');
    });

    test('CP04 — codigo 23505 es duplicado generico', () {
      expect(
        classifyUniqueViolation(message: 'conflict', code: '23505'),
        UniqueViolationKind.duplicateCode,
      );
      print('✅ CP04 PASS — codigo 23505 es duplicado generico');
    });

    test('CP05 — normalizeDbMessage con texto vacio', () {
      expect(normalizeDbMessage(''), 'Error de base de datos');
      expect(normalizeDbMessage('  timeout  '), 'timeout');
      print('✅ CP05 PASS — normalizeDbMessage con texto vacio');
    });
  });

  group('RF-014 — Notificación push llegada conductor', () {
    test('CP01 — push habilitado y datos válidos', () {
      expect(
        puedeNotificarLlegadaConductor(
          haySesion: true,
          tripId: 'trip-1',
          passengerProfileId: 'p-1',
          pushDestinatarioHabilitado: true,
        ),
        isTrue,
      );
      expect(textoNotificacionLlegadaConductor(), contains('llegando'));
      print('✅ CP01 PASS — push habilitado y datos válidos');
    });

    test('CP02 — push desactivado', () {
      expect(
        resultadoEnvioNotificacionPush(
          pushHabilitado: false,
          datosValidos: true,
        ),
        'Notificaciones push desactivadas',
      );
      print('✅ CP02 PASS — push desactivado');
    });
  });

  group('RF-034 — Notificaciones por voz', () {
    test('CP01 — emite banner con voz activa', () {
      expect(
        bannerNotificacionVoz(
          vozHabilitada: true,
          texto: 'Próxima parada: Ana',
        ),
        '🔊 Próxima parada: Ana',
      );
      print('✅ CP01 PASS — emite banner con voz activa');
    });

    test('CP02 — voz desactivada no emite banner', () {
      expect(
        bannerNotificacionVoz(
          vozHabilitada: false,
          texto: 'Pasajero cerca',
        ),
        isNull,
      );
      print('✅ CP02 PASS — voz desactivada no emite banner');
    });
  });

  group('RF-006 — ViajeDisponible a ReservaDriverInfo', () {
    test('CP01 — mapea datos del conductor para reserva', () {
      const viaje = ViajeDisponible(
        tripId: 'trip-99',
        driverId: 'driver-99',
        driverName: 'Carlos Ruiz',
        plate: 'XYZ-999',
        vehicleType: 'Combis',
        totalSeats: 15,
        availableSeats: 10,
        routeLabel: 'San Isidro → Chosica',
        rating: 4.8,
        ratingCount: 20,
        direction: 'si_cho',
        status: 'disponible',
      );
      final info = viaje.toReservaDriverInfo();
      expect(info.tripId, 'trip-99');
      expect(info.driverId, 'driver-99');
      expect(info.name, 'Carlos Ruiz');
      expect(info.plate, 'XYZ-999');
      expect(info.totalSeats, 15);
      print('✅ CP01 PASS — mapea datos del conductor para reserva');
    });
  });
}
