#!/usr/bin/env python3
"""Conecta los RF de notificaciones a notification_utils / sdag_validators."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# (RF id, CP title substring, body lines without outer indent beyond 6 spaces)
MOMENTO3_BODIES: dict[str, dict[str, list[str]]] = {
    "RF-014": {
        "CP01": [
            "// PRECONDICIÓN: Pasajero con push habilitado y viaje activo con datos válidos.",
            "const pushHabilitado = true;",
            "const tripId = 'trip-001';",
            "const passengerId = 'passenger-001';",
            "// ACCIÓN: Se evalúa si puede enviarse la notificación de llegada del conductor.",
            "final puedeEnviar = puedeNotificarLlegadaConductor(",
            "  haySesion: true,",
            "  tripId: tripId,",
            "  passengerProfileId: passengerId,",
            "  pushDestinatarioHabilitado: pushHabilitado,",
            ");",
            "final texto = textoNotificacionLlegadaConductor();",
            "// RESULTADO ESPERADO: El sistema permite enviar la notificación con el texto de llegada.",
            "expect(puedeEnviar, isTrue);",
            "expect(texto, contains('llegando'));",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP01 PASS — Flujo exitoso — notificar llegada del conductor');",
        ],
        "CP02": [
            "// PRECONDICIÓN: El pasajero tiene desactivadas las notificaciones push.",
            "const pushHabilitado = false;",
            "// ACCIÓN: Se intenta enviar la notificación push de llegada.",
            "final resultado = resultadoEnvioNotificacionPush(",
            "  pushHabilitado: pushHabilitado,",
            "  datosValidos: true,",
            ");",
            "// RESULTADO ESPERADO: El envío se rechaza por push desactivado.",
            "expect(resultado, equals('Notificaciones push desactivadas'));",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP02 PASS — Notificaciones desactivadas (E1)');",
        ],
        "CP03": [
            "// PRECONDICIÓN: Faltan identificadores obligatorios del viaje o pasajero.",
            "// ACCIÓN: Se validan los datos mínimos de la notificación de llegada.",
            "final datosVacios = datosNotificacionLlegadaCompletos(",
            "  tripId: '',",
            "  passengerProfileId: 'passenger-001',",
            ");",
            "final sinPasajero = datosNotificacionLlegadaCompletos(",
            "  tripId: 'trip-001',",
            "  passengerProfileId: '',",
            ");",
            "// RESULTADO ESPERADO: Los datos incompletos impiden la notificación.",
            "expect(datosVacios, isFalse);",
            "expect(sinPasajero, isFalse);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP03 PASS — Campos requeridos incompletos (E2)');",
        ],
    },
    "RF-034": {
        "CP01": [
            "// PRECONDICIÓN: El conductor tiene activadas las notificaciones por voz.",
            "const vozHabilitada = true;",
            "const mensaje = 'Próxima parada: María';",
            "// ACCIÓN: Se emite el banner de voz como en el provider del conductor.",
            "final banner = bannerNotificacionVoz(",
            "  vozHabilitada: vozHabilitada,",
            "  texto: mensaje,",
            ");",
            "// RESULTADO ESPERADO: Se genera el banner audible con el prefijo 🔊.",
            "expect(banner, equals('🔊 Próxima parada: María'));",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP01 PASS — Flujo exitoso — leer notificaciones por voz');",
        ],
        "CP02": [
            "// PRECONDICIÓN: Las notificaciones por voz están desactivadas (volumen en cero).",
            "const vozHabilitada = false;",
            "// ACCIÓN: Se intenta leer una notificación por voz.",
            "final banner = bannerNotificacionVoz(",
            "  vozHabilitada: vozHabilitada,",
            "  texto: 'Pasajero cerca del punto de recojo',",
            ");",
            "// RESULTADO ESPERADO: No se emite banner de voz.",
            "expect(banner, isNull);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP02 PASS — Volumen del dispositivo en cero (E1)');",
        ],
        "CP03": [
            "// PRECONDICIÓN: El mensaje de voz está vacío.",
            "const vozHabilitada = true;",
            "// ACCIÓN: Se intenta emitir un banner sin texto.",
            "final banner = bannerNotificacionVoz(",
            "  vozHabilitada: vozHabilitada,",
            "  texto: '',",
            ");",
            "// RESULTADO ESPERADO: No se emite banner sin contenido.",
            "expect(banner, isNull);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP03 PASS — Campos requeridos incompletos (E2)');",
        ],
    },
    "RF-058": {
        "CP01": [
            "// PRECONDICIÓN: Vehículo lleno y push del conductor habilitado.",
            "const pushConductor = true;",
            "// ACCIÓN: Se evalúa si debe notificarse el llenado del vehículo.",
            "final debeNotificar = debeNotificarVehiculoLleno(",
            "  ocupados: 4,",
            "  capacidad: 4,",
            "  pushConductorHabilitado: pushConductor,",
            ");",
            "// RESULTADO ESPERADO: Se debe notificar al conductor.",
            "expect(debeNotificar, isTrue);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP01 PASS — Flujo exitoso — notificar llenado del vehículo');",
        ],
        "CP02": [
            "// PRECONDICIÓN: Vehículo lleno pero push del conductor desactivado.",
            "const pushConductor = false;",
            "// ACCIÓN: Se evalúa el envío de notificación de llenado.",
            "final debeNotificar = debeNotificarVehiculoLleno(",
            "  ocupados: 4,",
            "  capacidad: 4,",
            "  pushConductorHabilitado: pushConductor,",
            ");",
            "final resultado = resultadoEnvioNotificacionPush(",
            "  pushHabilitado: pushConductor,",
            "  datosValidos: true,",
            ");",
            "// RESULTADO ESPERADO: No se notifica con push desactivado.",
            "expect(debeNotificar, isFalse);",
            "expect(resultado, equals('Notificaciones push desactivadas'));",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP02 PASS — Notificaciones desactivadas (E1)');",
        ],
        "CP03": [
            "// PRECONDICIÓN: El vehículo aún no está lleno.",
            "// ACCIÓN: Se evalúa notificación de llenado con asientos libres.",
            "final debeNotificar = debeNotificarVehiculoLleno(",
            "  ocupados: 2,",
            "  capacidad: 4,",
            "  pushConductorHabilitado: true,",
            ");",
            "// RESULTADO ESPERADO: No corresponde notificar llenado.",
            "expect(debeNotificar, isFalse);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP03 PASS — Campos requeridos incompletos (E2)');",
        ],
    },
    "RF-059": {
        "CP01": [
            "// PRECONDICIÓN: El vehículo inicia viaje con pasajeros a bordo.",
            "const estadoViaje = 'en_ruta';",
            "const hayPasajeros = true;",
            "// ACCIÓN: Se evalúa notificación de salida a pasajeros.",
            "final debeNotificar = debeNotificarSalidaVehiculo(",
            "  estadoViaje: estadoViaje,",
            "  hayPasajeros: hayPasajeros,",
            ");",
            "// RESULTADO ESPERADO: Se debe notificar la salida del vehículo.",
            "expect(debeNotificar, isTrue);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP01 PASS — Flujo exitoso — notificar salida del vehículo');",
        ],
        "CP02": [
            "// PRECONDICIÓN: Pasajero sin conexión de red.",
            "const hayConexion = false;",
            "// ACCIÓN: Se consulta estrategia offline ante falta de conexión.",
            "final resultado = resultadoSinConexion(hayConexion);",
            "// RESULTADO ESPERADO: Se usa el último estado conocido.",
            "expect(resultado, equals('último estado conocido'));",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP02 PASS — Pasajero sin conexión (E1)');",
        ],
        "CP03": [
            "// PRECONDICIÓN: Viaje en espera sin pasajeros registrados.",
            "// ACCIÓN: Se evalúa notificación de salida sin pasajeros.",
            "final debeNotificar = debeNotificarSalidaVehiculo(",
            "  estadoViaje: 'esperando',",
            "  hayPasajeros: false,",
            ");",
            "// RESULTADO ESPERADO: No se envía notificación de salida.",
            "expect(debeNotificar, isFalse);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP03 PASS — Campos requeridos incompletos (E2)');",
        ],
    },
    "RF-060": {
        "CP01": [
            "// PRECONDICIÓN: Hay una solicitud activa de forzar salida.",
            "// ACCIÓN: Se evalúa si debe notificarse a los pasajeros.",
            "final debeNotificar = debeNotificarSolicitudForzarSalida(solicitudActiva: true);",
            "// RESULTADO ESPERADO: Se notifica la solicitud de forzar salida.",
            "expect(debeNotificar, isTrue);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP01 PASS — Flujo exitoso — notificar solicitud de forzar salida');",
        ],
        "CP02": [
            "// PRECONDICIÓN: Al menos un pasajero rechazó la salida forzada.",
            "// ACCIÓN: Se evalúa el resultado de la votación.",
            "final rechazada = forzarSalidaRechazadaPorPasajero(rechazos: 1);",
            "// RESULTADO ESPERADO: La solicitud queda rechazada.",
            "expect(rechazada, isTrue);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP02 PASS — Algún pasajero rechaza (E1)');",
        ],
        "CP03": [
            "// PRECONDICIÓN: Expiró el tiempo de respuesta de los pasajeros.",
            "// ACCIÓN: Se evalúa timeout de la solicitud.",
            "final expirada = forzarSalidaTiempoExpirado(",
            "  tiempoExpirado: true,",
            "  respuestasRecibidas: 1,",
            "  totalPasajeros: 3,",
            ");",
            "// RESULTADO ESPERADO: La solicitud expira sin consenso.",
            "expect(expirada, isTrue);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP03 PASS — Tiempo expirado sin respuesta (E2)');",
        ],
    },
    "RF-068": {
        "CP01": [
            "// PRECONDICIÓN: Solicitud de pago válida y administrador con conexión.",
            "// ACCIÓN: Se evalúa notificación al administrador.",
            "final puedeNotificar = puedeNotificarAdminSolicitudPago(",
            "  solicitudValida: true,",
            "  adminConectado: true,",
            ");",
            "// RESULTADO ESPERADO: Se puede notificar al admin.",
            "expect(puedeNotificar, isTrue);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP01 PASS — Flujo exitoso — notificar solicitud de pago al admin');",
        ],
        "CP02": [
            "// PRECONDICIÓN: Administrador sin conexión.",
            "const hayConexion = false;",
            "// ACCIÓN: Se evalúa entrega offline y regla de conexión del admin.",
            "final offline = resultadoSinConexion(hayConexion);",
            "final puedeNotificar = puedeNotificarAdminSolicitudPago(",
            "  solicitudValida: true,",
            "  adminConectado: false,",
            ");",
            "// RESULTADO ESPERADO: No se notifica al admin sin conexión.",
            "expect(offline, equals('último estado conocido'));",
            "expect(puedeNotificar, isFalse);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP02 PASS — Admin sin conexión (E1)');",
        ],
        "CP03": [
            "// PRECONDICIÓN: Solicitud de pago con datos incompletos.",
            "// ACCIÓN: Se evalúa notificación con solicitud inválida.",
            "final puedeNotificar = puedeNotificarAdminSolicitudPago(",
            "  solicitudValida: false,",
            "  adminConectado: true,",
            ");",
            "// RESULTADO ESPERADO: No se notifica con solicitud inválida.",
            "expect(puedeNotificar, isFalse);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP03 PASS — Campos requeridos incompletos (E2)');",
        ],
    },
    "RF-088": {
        "CP01": [
            "// PRECONDICIÓN: Cuenta del conductor suspendida con push habilitado.",
            "// ACCIÓN: Se evalúa notificación de bloqueo.",
            "final debeNotificar = debeNotificarBloqueoConductor(",
            "  cuentaActiva: false,",
            "  pushConductorHabilitado: true,",
            ");",
            "final mensaje = mensajeNotificacionBloqueoConductor();",
            "// RESULTADO ESPERADO: Se notifica el bloqueo con mensaje de cuenta suspendida.",
            "expect(debeNotificar, isTrue);",
            "expect(mensaje, contains('suspendida'));",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP01 PASS — Flujo exitoso — notificar bloqueo al conductor');",
        ],
        "CP02": [
            "// PRECONDICIÓN: Conductor sin conexión de red.",
            "const hayConexion = false;",
            "// ACCIÓN: Se consulta estrategia offline.",
            "final resultado = resultadoSinConexion(hayConexion);",
            "// RESULTADO ESPERADO: Se conserva el último estado conocido.",
            "expect(resultado, equals('último estado conocido'));",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP02 PASS — Sin conexión (E1)');",
        ],
        "CP03": [
            "// PRECONDICIÓN: Cuenta activa — no aplica bloqueo.",
            "// ACCIÓN: Se evalúa notificación de bloqueo con cuenta activa.",
            "final debeNotificar = debeNotificarBloqueoConductor(",
            "  cuentaActiva: true,",
            "  pushConductorHabilitado: true,",
            ");",
            "// RESULTADO ESPERADO: No se envía notificación de bloqueo.",
            "expect(debeNotificar, isFalse);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP03 PASS — Campos requeridos incompletos (E2)');",
        ],
    },
    "RF-122": {
        "CP01": [
            "// PRECONDICIÓN: Reserva activa, viaje en espera y conductor conectado.",
            "// ACCIÓN: Se evalúa notificación de cancelación al conductor.",
            "final puedeNotificar = puedeNotificarCancelacionAlConductor(",
            "  hayReserva: true,",
            "  estadoViaje: 'esperando',",
            "  conductorConectado: true,",
            ");",
            "// RESULTADO ESPERADO: Se puede notificar la cancelación.",
            "expect(puedeNotificar, isTrue);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP01 PASS — Flujo exitoso — notificar cancelación de reserva al con');",
        ],
        "CP02": [
            "// PRECONDICIÓN: Conductor sin conexión.",
            "const hayConexion = false;",
            "// ACCIÓN: Se evalúa entrega offline y regla de conexión.",
            "final offline = resultadoSinConexion(hayConexion);",
            "final puedeNotificar = puedeNotificarCancelacionAlConductor(",
            "  hayReserva: true,",
            "  estadoViaje: 'esperando',",
            "  conductorConectado: false,",
            ");",
            "// RESULTADO ESPERADO: No se notifica sin conexión del conductor.",
            "expect(offline, equals('último estado conocido'));",
            "expect(puedeNotificar, isFalse);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP02 PASS — Conductor sin conexión (E1)');",
        ],
        "CP03": [
            "// PRECONDICIÓN: El vehículo ya partió (viaje en ruta).",
            "// ACCIÓN: Se evalúa cancelación tardía.",
            "final puedeNotificar = puedeNotificarCancelacionAlConductor(",
            "  hayReserva: true,",
            "  estadoViaje: 'en_ruta',",
            "  conductorConectado: true,",
            ");",
            "// RESULTADO ESPERADO: No se notifica cancelación si el viaje ya inició.",
            "expect(puedeNotificar, isFalse);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP03 PASS — Cancelación mientras el vehículo ya partió (E2)');",
        ],
    },
    "RF-126": {
        "CP01": [
            "// PRECONDICIÓN: Ruta completada, pasajero a bordo y con conexión.",
            "// ACCIÓN: Se evalúa notificación de llegada al destino.",
            "final puedeNotificar = puedeNotificarRutaCompletadaAlPasajero(",
            "  rutaCompletada: true,",
            "  pasajeroSigueEnViaje: true,",
            "  pasajeroConectado: true,",
            ");",
            "// RESULTADO ESPERADO: Se notifica al pasajero la finalización de ruta.",
            "expect(puedeNotificar, isTrue);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP01 PASS — Flujo exitoso — notificar llegada al destino al pasajer');",
        ],
        "CP02": [
            "// PRECONDICIÓN: Pasajero que bajó anticipadamente (RF-021).",
            "// ACCIÓN: Se evalúa notificación con pasajero ya no en viaje.",
            "final puedeNotificar = puedeNotificarRutaCompletadaAlPasajero(",
            "  rutaCompletada: true,",
            "  pasajeroSigueEnViaje: false,",
            "  pasajeroConectado: true,",
            ");",
            "// RESULTADO ESPERADO: No se notifica a quien ya bajó.",
            "expect(puedeNotificar, isFalse);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP02 PASS — Pasajero que bajó anticipadamente (RF-021) (E1)');",
        ],
        "CP03": [
            "// PRECONDICIÓN: Pasajero sin conexión al completar la ruta.",
            "// ACCIÓN: Se evalúa notificación con pasajero offline.",
            "final puedeNotificar = puedeNotificarRutaCompletadaAlPasajero(",
            "  rutaCompletada: true,",
            "  pasajeroSigueEnViaje: true,",
            "  pasajeroConectado: false,",
            ");",
            "// RESULTADO ESPERADO: No se entrega push sin conexión del pasajero.",
            "expect(puedeNotificar, isFalse);",
            "// RESULTADO OBTENIDO: se completa al correr el test",
            "print('  ✅ CP03 PASS — Pasajero sin conexión (E2)');",
        ],
    },
}


def cp_key(title: str) -> str:
    m = re.match(r"(CP\d+)", title)
    return m.group(1) if m else ""


def rf_key(group: str) -> str:
    m = re.match(r"(RF-\d+)", group)
    return m.group(1) if m else ""


def patch_file(path: Path, momento3: bool) -> int:
    content = path.read_text(encoding="utf-8")
    changed = 0
    lines = content.split("\n")
    out: list[str] = []
    current_group = ""
    i = 0
    while i < len(lines):
        gm = re.match(r"\s*group\('([^']+)'", lines[i])
        if gm:
            current_group = gm.group(1)
        tm = re.match(r"(\s*)test\('([^']+)',\s*\(\)\s*\{", lines[i])
        if tm:
            indent = tm.group(1)
            title = tm.group(2)
            rf = rf_key(current_group)
            cp = cp_key(title)
            block = [lines[i]]
            i += 1
            depth = 1
            while i < len(lines) and depth > 0:
                block.append(lines[i])
                if re.search(r"\(\)\s*\{", lines[i]) and "test(" in lines[i]:
                    depth += 1
                if lines[i].strip() == "});":
                    depth -= 1
                i += 1
            body_spec = MOMENTO3_BODIES.get(rf, {}).get(cp)
            if body_spec and momento3:
                out.append(f"{indent}test('{title}', () {{")
                for line in body_spec:
                    out.append(f"      {line}")
                out.append(f"{indent}}});")
                changed += 1
            elif body_spec and not momento3:
                out.append(f"{indent}test('{title}', () {{")
                phase = "arrange"
                for line in body_spec:
                    if line.startswith("// PRECONDICIÓN"):
                        out.append(
                            f"      // Arrange — {line.split(':', 1)[1].strip()}"
                        )
                        phase = "arrange"
                    elif line.startswith("// ACCIÓN"):
                        out.append("      // Act — ejecutar la validación / regla de la app")
                        phase = "act"
                    elif line.startswith("// RESULTADO ESPERADO"):
                        out.append("      // Assert — verificar el resultado esperado del CP")
                        phase = "assert"
                    elif line.startswith("// RESULTADO OBTENIDO") or line.startswith("print("):
                        out.append(f"      {line}")
                    elif line.startswith("expect("):
                        if phase != "assert":
                            out.append("      // Assert — verificar el resultado esperado del CP")
                            phase = "assert"
                        out.append(f"      {line}")
                    elif line.startswith("//"):
                        continue
                    else:
                        out.append(f"      {line}")
                out.append(f"{indent}}});")
                changed += 1
            else:
                out.extend(block)
            continue
        out.append(lines[i])
        i += 1
    path.write_text("\n".join(out) + ("\n" if content.endswith("\n") else ""), encoding="utf-8")
    return changed


def main() -> None:
    m3 = ROOT / "test" / "sdag_tdd_momento3_test.dart"
    todos = ROOT / "test" / "sdag_todos_los_rf_test.dart"
    c1 = patch_file(m3, momento3=True)
    c2 = patch_file(todos, momento3=False)
    print(f"sdag_tdd_momento3_test.dart: {c1} tests de notificación actualizados")
    print(f"sdag_todos_los_rf_test.dart: {c2} tests de notificación actualizados")


if __name__ == "__main__":
    main()
