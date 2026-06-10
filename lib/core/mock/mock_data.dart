import '../../data/models/manifiesto.dart';
import '../../data/models/comision.dart';

class MockNewsItem {
  const MockNewsItem({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

enum MockTripDirection {
  sanIsidroToChosica,
  chosicaToSanIsidro,
}

enum MockDriverStatus {
  available,
  active,
  inactive,
}

enum MockTripStatus {
  completado,
  cancelado,
}

class MockTripHistoryItem {
  const MockTripHistoryItem({
    required this.id,
    required this.dateLabel,
    required this.routeLabel,
    required this.driverName,
    required this.plate,
    required this.amount,
    required this.status,
    required this.ratingStars,
    required this.seats,
    required this.pickupPoint,
    required this.receiptNumber,
    required this.paymentMethodLabel,
    required this.lastChatMessage,
    required this.chatMessages,
    required this.qrPassengerName,
    required this.qrSeat,
    required this.qrBoarded,
  });

  final String id;
  final String dateLabel;
  final String routeLabel;
  final String driverName;
  final String plate;
  final double amount;
  final MockTripStatus status;
  final int? ratingStars;
  final List<int> seats;
  final String pickupPoint;
  final String receiptNumber;
  final String paymentMethodLabel;
  final String? lastChatMessage;
  final List<MockChatMessage> chatMessages;
  final String qrPassengerName;
  final int qrSeat;
  final bool qrBoarded;
}

class MockChatMessage {
  const MockChatMessage({
    required this.isDriver,
    required this.text,
    required this.timestampLabel,
  });

  final bool isDriver;
  final String text;
  final String timestampLabel;
}

enum MockNewsType {
  incidencia,
  novedad,
}

class MockNewsPost {
  const MockNewsPost({
    required this.id,
    required this.type,
    required this.title,
    required this.text,
    required this.driverName,
    required this.dateLabel,
  });

  final String id;
  final MockNewsType type;
  final String title;
  final String text;
  final String driverName;
  final String dateLabel;
}

class MockDriver {
  const MockDriver({
    required this.id,
    required this.name,
    required this.plate,
    required this.vehicleType,
    required this.totalSeats,
    required this.availableSeats,
    required this.routeLabel,
    required this.rating,
    required this.ratingCount,
    required this.etaMinutes,
    required this.direction,
    required this.status,
  });

  final String id;
  final String name;
  final String plate;
  final String vehicleType;
  final int totalSeats;
  final int availableSeats;
  final String routeLabel;
  final double rating;
  final int ratingCount;
  final int etaMinutes;
  final MockTripDirection direction;
  final MockDriverStatus status;
}

class MockData {
  MockData._();

  static const passengerName = 'María García';
  static const passengerEmail = 'pasajero@sdag.pe';
  static const hasActiveReservation = false;

  static const adminNombre = 'Sr. Mateo Ramos';
  static const adminEmail = 'admin@sdag.pe';
  static const adminPassword = 'admin123';
  static const adminRol = 'administrador';

  static const conductorNombre = 'Carlos Ríos';
  static const conductorEmail = 'conductor@sdag.pe';
  static const conductorPassword = 'password123';
  static const conductorPlaca = 'ABC-123';
  static const conductorVehiculo = 'Toyota Hiace';
  static const conductorCapacidad = 8;
  static const conductorPorcentajeComision = 0.15;
  static const conductorEstado = 'disponible';
  static const conductorPagoConfirmado = true;
  static const conductorCuentaActiva = true;
  static const conductorRatingPromedio = 4.8;
  static const conductorRatingCount = 127;

  static const adminVehiculos = <MockAdminVehiculo>[
    MockAdminVehiculo(
      placa: 'ABC-123',
      vehiculo: 'Toyota Hiace',
      asientos: 8,
      conductor: 'Carlos Ríos',
    ),
    MockAdminVehiculo(
      placa: 'XYZ-456',
      vehiculo: 'Nissan Urvan',
      asientos: 15,
      conductor: 'Jorge Mamani',
    ),
    MockAdminVehiculo(
      placa: 'DEF-789',
      vehiculo: 'Van Sprinter',
      asientos: 6,
      conductor: 'Luis Quispe',
    ),
    MockAdminVehiculo(
      placa: 'GHI-321',
      vehiculo: 'Combi',
      asientos: 15,
      conductor: 'Pedro Huanca',
    ),
    MockAdminVehiculo(
      placa: 'JKL-654',
      vehiculo: 'Sedan',
      asientos: 4,
      conductor: 'Marco Silva',
    ),
    MockAdminVehiculo(
      placa: 'MNO-987',
      vehiculo: 'Van',
      asientos: 8,
      conductor: 'Rosa Torres',
    ),
  ];

  static const adminConductores = <MockAdminConductor>[
    MockAdminConductor(
      id: '71234567',
      nombres: 'Carlos',
      apellidos: 'Ríos',
      dni: '71234567',
      telefono: '987654321',
      correo: 'carlos@sdag.pe',
      placa: 'ABC-123',
      vehiculoTipo: 'Toyota Hiace',
      capacidad: 8,
      comisionPorcentaje: 15.0,
      ratingPromedio: 4.8,
      ratingCount: 127,
      estado: MockAdminConductorEstado.enRuta,
      bloqueadoPorPago: false,
    ),
    MockAdminConductor(
      id: '73456789',
      nombres: 'Jorge',
      apellidos: 'Mamani',
      dni: '73456789',
      telefono: '912345678',
      correo: 'jorge@sdag.pe',
      placa: 'XYZ-456',
      vehiculoTipo: 'Nissan Urvan',
      capacidad: 15,
      comisionPorcentaje: 15.0,
      ratingPromedio: 4.5,
      ratingCount: 98,
      estado: MockAdminConductorEstado.disponible,
      bloqueadoPorPago: false,
    ),
    MockAdminConductor(
      id: '74567890',
      nombres: 'Luis',
      apellidos: 'Quispe',
      dni: '74567890',
      telefono: '976543210',
      correo: 'luis@sdag.pe',
      placa: 'DEF-789',
      vehiculoTipo: 'Van',
      capacidad: 6,
      comisionPorcentaje: 15.0,
      ratingPromedio: 4.3,
      ratingCount: 64,
      estado: MockAdminConductorEstado.bloqueado,
      bloqueadoPorPago: true,
    ),
    MockAdminConductor(
      id: '75678901',
      nombres: 'Pedro',
      apellidos: 'Huanca',
      dni: '75678901',
      telefono: '965432109',
      correo: 'pedro@sdag.pe',
      placa: 'GHI-321',
      vehiculoTipo: 'Combi',
      capacidad: 15,
      comisionPorcentaje: 14.5,
      ratingPromedio: 4.6,
      ratingCount: 88,
      estado: MockAdminConductorEstado.inactivo,
      bloqueadoPorPago: false,
    ),
    MockAdminConductor(
      id: '76789012',
      nombres: 'Marco',
      apellidos: 'Silva',
      dni: '76789012',
      telefono: '954321987',
      correo: 'marco@sdag.pe',
      placa: 'JKL-654',
      vehiculoTipo: 'Auto',
      capacidad: 4,
      comisionPorcentaje: 16.0,
      ratingPromedio: 4.2,
      ratingCount: 41,
      estado: MockAdminConductorEstado.disponible,
      bloqueadoPorPago: false,
    ),
    MockAdminConductor(
      id: '77890123',
      nombres: 'Rosa',
      apellidos: 'Torres',
      dni: '77890123',
      telefono: '943210987',
      correo: 'rosa@sdag.pe',
      placa: 'MNO-987',
      vehiculoTipo: 'Van',
      capacidad: 8,
      comisionPorcentaje: 15.0,
      ratingPromedio: 4.7,
      ratingCount: 73,
      estado: MockAdminConductorEstado.disponible,
      bloqueadoPorPago: false,
    ),
  ];

  static final adminViajes = <MockAdminViaje>[
    MockAdminViaje(
      id: 'viaje-001',
      conductorId: '71234567',
      fecha: DateTime(2025, 5, 4, 8, 20),
      rutaLabel: 'San Isidro → Chosica',
      monto: 36.0,
      estado: MockAdminViajeEstado.completado,
    ),
    MockAdminViaje(
      id: 'viaje-002',
      conductorId: '71234567',
      fecha: DateTime(2025, 5, 3, 18, 10),
      rutaLabel: 'Chosica → San Isidro',
      monto: 36.0,
      estado: MockAdminViajeEstado.completado,
    ),
    MockAdminViaje(
      id: 'viaje-003',
      conductorId: '71234567',
      fecha: DateTime(2025, 5, 2, 7, 50),
      rutaLabel: 'San Isidro → Chosica',
      monto: 36.0,
      estado: MockAdminViajeEstado.cancelado,
    ),
    MockAdminViaje(
      id: 'viaje-004',
      conductorId: '73456789',
      fecha: DateTime(2025, 5, 4, 7, 40),
      rutaLabel: 'San Isidro → Chosica',
      monto: 32.0,
      estado: MockAdminViajeEstado.completado,
    ),
    MockAdminViaje(
      id: 'viaje-005',
      conductorId: '73456789',
      fecha: DateTime(2025, 5, 3, 17, 30),
      rutaLabel: 'Chosica → San Isidro',
      monto: 32.0,
      estado: MockAdminViajeEstado.completado,
    ),
    MockAdminViaje(
      id: 'viaje-006',
      conductorId: '74567890',
      fecha: DateTime(2025, 5, 4, 18, 5),
      rutaLabel: 'Chosica → San Isidro',
      monto: 30.0,
      estado: MockAdminViajeEstado.completado,
    ),
    MockAdminViaje(
      id: 'viaje-007',
      conductorId: '75678901',
      fecha: DateTime(2025, 5, 1, 8, 0),
      rutaLabel: 'San Isidro → Chosica',
      monto: 35.0,
      estado: MockAdminViajeEstado.completado,
    ),
    MockAdminViaje(
      id: 'viaje-008',
      conductorId: '76789012',
      fecha: DateTime(2025, 5, 2, 19, 10),
      rutaLabel: 'Chosica → San Isidro',
      monto: 28.0,
      estado: MockAdminViajeEstado.cancelado,
    ),
    MockAdminViaje(
      id: 'viaje-009',
      conductorId: '77890123',
      fecha: DateTime(2025, 5, 4, 6, 50),
      rutaLabel: 'San Isidro → Chosica',
      monto: 34.0,
      estado: MockAdminViajeEstado.completado,
    ),
  ];

  static const adminSolicitudesPago = <MockAdminSolicitudPago>[
    MockAdminSolicitudPago(
      conductor: 'Carlos Ríos',
      monto: 108.0,
      solicitadoLabel: 'Solicitado hoy 6:00 PM',
    ),
    MockAdminSolicitudPago(
      conductor: 'Jorge Mamani',
      monto: 90.0,
      solicitadoLabel: 'Solicitado hoy 5:45 PM',
    ),
    MockAdminSolicitudPago(
      conductor: 'Luis Quispe',
      monto: 72.0,
      solicitadoLabel: 'Solicitado ayer 7:00 PM',
    ),
  ];

  static const adminPagosConfirmados = <MockAdminPagoConfirmado>[
    MockAdminPagoConfirmado(conductor: 'Pedro Huanca', monto: 108.0, fechaLabel: '04/05/2025', estado: 'Confirmado'),
    MockAdminPagoConfirmado(conductor: 'Rosa Torres', monto: 54.0, fechaLabel: '04/05/2025', estado: 'Confirmado'),
    MockAdminPagoConfirmado(conductor: 'Marco Silva', monto: 63.0, fechaLabel: '03/05/2025', estado: 'Confirmado'),
    MockAdminPagoConfirmado(conductor: 'Carlos Ríos', monto: 90.0, fechaLabel: '03/05/2025', estado: 'Confirmado'),
    MockAdminPagoConfirmado(conductor: 'Jorge Mamani', monto: 72.0, fechaLabel: '02/05/2025', estado: 'Confirmado'),
  ];

  static const adminStats = MockAdminStats(
    viajesHoy: 18,
    ingresosHoy: 2160.0,
    ocupacionPromedio: 0.87,
    comisionesDia: 324.0,
    viajesMes: 412,
    ingresosMes: 49440.0,
    comisionesMes: 7416.0,
  );

  static const latestNews = <MockNewsItem>[
    MockNewsItem(
      id: 'n1',
      title: 'Tráfico moderado en Javier Prado',
      subtitle: 'Posibles demoras de 10–15 min en horas punta.',
    ),
    MockNewsItem(
      id: 'n2',
      title: 'Mejora de flujo en La Priale',
      subtitle: 'Ruta más fluida en el tramo central esta tarde.',
    ),
  ];

  static const newsPosts = <MockNewsPost>[
    MockNewsPost(
      id: 'p1',
      type: MockNewsType.incidencia,
      title: 'Accidente en La Priale km 12',
      text:
          'Se reporta un accidente vehicular en el km 12 de La Priale. Hay demoras de aproximadamente 20 minutos. Los conductores toman ruta alterna.',
      driverName: 'Carlos Ríos',
      dateLabel: 'Hoy 8:15 AM',
    ),
    MockNewsPost(
      id: 'p2',
      type: MockNewsType.incidencia,
      title: 'Operativo policial en Chosica centro',
      text:
          'La PNP realiza un operativo en el centro de Chosica. Se recomienda desvío por Av. Lima.',
      driverName: 'Pedro Huanca',
      dateLabel: 'Hoy 6:45 AM',
    ),
    MockNewsPost(
      id: 'p3',
      type: MockNewsType.novedad,
      title: 'Nuevo paradero disponible en Ate Vitarte',
      text:
          'A partir del lunes 19 de mayo estará disponible un nuevo paradero en la Av. Separadora Industrial cuadra 8, Ate Vitarte.',
      driverName: 'Jorge Mamani',
      dateLabel: 'Ayer 5:30 PM',
    ),
    MockNewsPost(
      id: 'p4',
      type: MockNewsType.incidencia,
      title: 'Lluvia intensa en zona de Chosica',
      text:
          'Se reporta lluvia intensa en la zona de Chosica y Ricardo Palma. Se recomienda ropa de abrigo y salir con tiempo extra.',
      driverName: 'Luis Quispe',
      dateLabel: 'Ayer 3:00 PM',
    ),
    MockNewsPost(
      id: 'p5',
      type: MockNewsType.novedad,
      title: 'Servicio restablecido tras cierre de vía',
      text:
          'Luego del cierre temporal de la Carretera Central por deslizamiento, el servicio se ha restablecido con normalidad desde las 10:00 AM.',
      driverName: 'Marco Silva',
      dateLabel: 'Hace 2 días',
    ),
  ];

  static const sanIsidroLat = -12.0931;
  static const sanIsidroLng = -76.9662;
  static const midLat = -12.0464;
  static const midLng = -76.9156;
  static const chosicaLat = -11.9333;
  static const chosicaLng = -76.7000;

  static const drivers = <MockDriver>[
    MockDriver(
      id: 'd1',
      name: 'Carlos Ríos',
      plate: 'ABC-123',
      vehicleType: 'Toyota Hiace',
      totalSeats: 8,
      availableSeats: 5,
      routeLabel: 'Vía La Priale',
      rating: 4.8,
      ratingCount: 126,
      etaMinutes: 8,
      direction: MockTripDirection.sanIsidroToChosica,
      status: MockDriverStatus.available,
    ),
    MockDriver(
      id: 'd2',
      name: 'Jorge Mamani',
      plate: 'XYZ-456',
      vehicleType: 'Nissan Urvan',
      totalSeats: 15,
      availableSeats: 3,
      routeLabel: 'Vía Javier Prado',
      rating: 4.5,
      ratingCount: 98,
      etaMinutes: 12,
      direction: MockTripDirection.sanIsidroToChosica,
      status: MockDriverStatus.active,
    ),
    MockDriver(
      id: 'd3',
      name: 'Luis Quispe',
      plate: 'DEF-789',
      vehicleType: 'Van',
      totalSeats: 6,
      availableSeats: 1,
      routeLabel: 'Vía La Priale',
      rating: 4.2,
      ratingCount: 54,
      etaMinutes: 5,
      direction: MockTripDirection.sanIsidroToChosica,
      status: MockDriverStatus.available,
    ),
    MockDriver(
      id: 'd4',
      name: 'Pedro Huanca',
      plate: 'GHI-321',
      vehicleType: 'Combi',
      totalSeats: 15,
      availableSeats: 8,
      routeLabel: 'Ruta Directa',
      rating: 4.9,
      ratingCount: 203,
      etaMinutes: 15,
      direction: MockTripDirection.chosicaToSanIsidro,
      status: MockDriverStatus.available,
    ),
    MockDriver(
      id: 'd5',
      name: 'Marco Silva',
      plate: 'JKL-654',
      vehicleType: 'Auto',
      totalSeats: 4,
      availableSeats: 2,
      routeLabel: 'Ruta Ñaña',
      rating: 4.7,
      ratingCount: 142,
      etaMinutes: 10,
      direction: MockTripDirection.chosicaToSanIsidro,
      status: MockDriverStatus.active,
    ),
    MockDriver(
      id: 'd6',
      name: 'Rosa Torres',
      plate: 'MNO-987',
      vehicleType: 'Van',
      totalSeats: 8,
      availableSeats: 4,
      routeLabel: 'Ruta Huachipa',
      rating: 4.3,
      ratingCount: 87,
      etaMinutes: 20,
      direction: MockTripDirection.chosicaToSanIsidro,
      status: MockDriverStatus.available,
    ),
  ];

  static const tripHistory = <MockTripHistoryItem>[
    MockTripHistoryItem(
      id: 't1',
      dateLabel: 'Lunes 5 May, 2025 · 7:30 AM',
      routeLabel: 'San Isidro → Chosica',
      driverName: 'Carlos Ríos',
      plate: 'ABC-123',
      amount: 15.0,
      status: MockTripStatus.completado,
      ratingStars: 5,
      seats: [1],
      pickupPoint: 'Cruce con Av. Javier Prado, frente al grifo',
      receiptNumber: 'RC-20250505-0001',
      paymentMethodLabel: 'Yape •••• 1234',
      lastChatMessage: 'Gracias, ya estoy llegando.',
      chatMessages: [
        MockChatMessage(isDriver: true, text: 'Hola, estoy en camino.', timestampLabel: '07:22'),
        MockChatMessage(isDriver: false, text: 'Perfecto, gracias.', timestampLabel: '07:23'),
        MockChatMessage(isDriver: true, text: 'Gracias, ya estoy llegando.', timestampLabel: '07:28'),
        MockChatMessage(isDriver: false, text: 'Te espero.', timestampLabel: '07:28'),
      ],
      qrPassengerName: 'María García',
      qrSeat: 1,
      qrBoarded: true,
    ),
    MockTripHistoryItem(
      id: 't2',
      dateLabel: 'Sábado 3 May, 2025 · 6:10 PM',
      routeLabel: 'Chosica → San Isidro',
      driverName: 'Pedro Huanca',
      plate: 'GHI-321',
      amount: 30.0,
      status: MockTripStatus.completado,
      ratingStars: 4,
      seats: [3, 4],
      pickupPoint: 'Paradero principal, costado del parque',
      receiptNumber: 'RC-20250503-0008',
      paymentMethodLabel: 'Tarjeta •••• 9876',
      lastChatMessage: 'Listo, ya salimos.',
      chatMessages: [
        MockChatMessage(isDriver: true, text: 'Estoy a 5 min.', timestampLabel: '18:02'),
        MockChatMessage(isDriver: false, text: 'Ok, estoy en el paradero.', timestampLabel: '18:03'),
        MockChatMessage(isDriver: true, text: 'Listo, ya salimos.', timestampLabel: '18:12'),
        MockChatMessage(isDriver: false, text: 'Gracias.', timestampLabel: '18:12'),
      ],
      qrPassengerName: 'María García',
      qrSeat: 3,
      qrBoarded: true,
    ),
    MockTripHistoryItem(
      id: 't3',
      dateLabel: 'Jueves 1 May, 2025 · 8:05 AM',
      routeLabel: 'San Isidro → Chosica',
      driverName: 'Jorge Mamani',
      plate: 'XYZ-456',
      amount: 15.0,
      status: MockTripStatus.cancelado,
      ratingStars: null,
      seats: [2],
      pickupPoint: 'Frente a la estación, puerta 2',
      receiptNumber: 'RC-20250501-0013',
      paymentMethodLabel: 'Yape •••• 5555',
      lastChatMessage: null,
      chatMessages: [],
      qrPassengerName: 'María García',
      qrSeat: 2,
      qrBoarded: false,
    ),
    MockTripHistoryItem(
      id: 't4',
      dateLabel: 'Lunes 28 Abr, 2025 · 9:40 AM',
      routeLabel: 'San Isidro → Chosica',
      driverName: 'Luis Quispe',
      plate: 'DEF-789',
      amount: 15.0,
      status: MockTripStatus.completado,
      ratingStars: null,
      seats: [6],
      pickupPoint: 'Esquina del mercado, entrada principal',
      receiptNumber: 'RC-20250428-0022',
      paymentMethodLabel: 'Tarjeta •••• 1234',
      lastChatMessage: 'Estoy estacionado.',
      chatMessages: [
        MockChatMessage(isDriver: true, text: 'Estoy estacionado.', timestampLabel: '09:36'),
        MockChatMessage(isDriver: false, text: 'Salgo en 1 min.', timestampLabel: '09:37'),
        MockChatMessage(isDriver: true, text: 'Ok.', timestampLabel: '09:37'),
        MockChatMessage(isDriver: false, text: 'Listo.', timestampLabel: '09:38'),
      ],
      qrPassengerName: 'María García',
      qrSeat: 6,
      qrBoarded: true,
    ),
    MockTripHistoryItem(
      id: 't5',
      dateLabel: 'Viernes 25 Abr, 2025 · 5:15 PM',
      routeLabel: 'Chosica → San Isidro',
      driverName: 'Marco Silva',
      plate: 'JKL-654',
      amount: 45.0,
      status: MockTripStatus.completado,
      ratingStars: 3,
      seats: [7, 8, 9],
      pickupPoint: 'Óvalo, al lado del banco',
      receiptNumber: 'RC-20250425-0017',
      paymentMethodLabel: 'Yape •••• 7788',
      lastChatMessage: 'Nos vemos en el óvalo.',
      chatMessages: [
        MockChatMessage(isDriver: true, text: 'Voy por Ñaña.', timestampLabel: '17:03'),
        MockChatMessage(isDriver: false, text: 'Ok, te espero.', timestampLabel: '17:04'),
        MockChatMessage(isDriver: true, text: 'Nos vemos en el óvalo.', timestampLabel: '17:10'),
        MockChatMessage(isDriver: false, text: 'Listo.', timestampLabel: '17:11'),
      ],
      qrPassengerName: 'María García',
      qrSeat: 7,
      qrBoarded: true,
    ),
    MockTripHistoryItem(
      id: 't6',
      dateLabel: 'Martes 22 Abr, 2025 · 7:55 AM',
      routeLabel: 'San Isidro → Chosica',
      driverName: 'Rosa Torres',
      plate: 'MNO-987',
      amount: 15.0,
      status: MockTripStatus.completado,
      ratingStars: 5,
      seats: [5],
      pickupPoint: 'Paradero central, frente a la farmacia',
      receiptNumber: 'RC-20250422-0009',
      paymentMethodLabel: 'Tarjeta •••• 4444',
      lastChatMessage: null,
      chatMessages: [],
      qrPassengerName: 'María García',
      qrSeat: 5,
      qrBoarded: true,
    ),
  ];

  static const pasajerosViajeActivo = <ManifiestoPasajero>[
    ManifiestoPasajero(
      id: 'p1',
      nombres: 'Ana',
      apellidos: 'Pérez',
      dni: '45678901',
      telefono: '987654321',
      asiento: 1,
      puntoRecojo: 'Óvalo Monitor, Av. Javier Prado',
      abordo: false,
    ),
    ManifiestoPasajero(
      id: 'p2',
      nombres: 'Luis',
      apellidos: 'Torres',
      dni: '34567890',
      telefono: '976543210',
      asiento: 2,
      puntoRecojo: 'Cruce Av. Angamos con Arequipa',
      abordo: false,
    ),
    ManifiestoPasajero(
      id: 'p3',
      nombres: 'María',
      apellidos: 'García',
      dni: '23456789',
      telefono: '965432109',
      asiento: 3,
      puntoRecojo: 'Frente al BCP, Av. La Marina',
      abordo: false,
    ),
    ManifiestoPasajero(
      id: 'p4',
      nombres: 'Pedro',
      apellidos: 'Salas',
      dni: '12345678',
      telefono: '954321098',
      asiento: 4,
      puntoRecojo: 'Paradero Puruchuco, La Molina',
      abordo: false,
    ),
    ManifiestoPasajero(
      id: 'p5',
      nombres: 'Rosa',
      apellidos: 'Díaz',
      dni: '56789012',
      telefono: '943210987',
      asiento: 5,
      puntoRecojo: 'Alt. Mall Aventura, Ate',
      abordo: false,
    ),
    ManifiestoPasajero(
      id: 'p6',
      nombres: 'Juan',
      apellidos: 'Quispe',
      dni: '67890123',
      telefono: '932109876',
      asiento: 6,
      puntoRecojo: 'Ingreso Chosica, Av. Lima',
      abordo: false,
    ),
  ];

  static final comisionesHistorial = <Comision>[
    Comision(id: 'c1', fecha: DateTime(2025, 5, 5), recaudado: 720.0, comision: 108.0, estado: 'Pagado'),
    Comision(id: 'c2', fecha: DateTime(2025, 5, 4), recaudado: 600.0, comision: 90.0, estado: 'Pagado'),
    Comision(id: 'c3', fecha: DateTime(2025, 5, 3), recaudado: 480.0, comision: 72.0, estado: 'Pagado'),
    Comision(id: 'c4', fecha: DateTime(2025, 5, 2), recaudado: 720.0, comision: 108.0, estado: 'Pagado'),
    Comision(id: 'c5', fecha: DateTime(2025, 5, 1), recaudado: 360.0, comision: 54.0, estado: 'Pagado'),
  ];
}

class MockAdminVehiculo {
  const MockAdminVehiculo({
    required this.placa,
    required this.vehiculo,
    required this.asientos,
    required this.conductor,
  });

  final String placa;
  final String vehiculo;
  final int asientos;
  final String conductor;
}

class MockAdminSolicitudPago {
  const MockAdminSolicitudPago({
    required this.conductor,
    required this.monto,
    required this.solicitadoLabel,
  });

  final String conductor;
  final double monto;
  final String solicitadoLabel;
}

class MockAdminPagoConfirmado {
  const MockAdminPagoConfirmado({
    required this.conductor,
    required this.monto,
    required this.fechaLabel,
    required this.estado,
  });

  final String conductor;
  final double monto;
  final String fechaLabel;
  final String estado;
}

class MockAdminStats {
  const MockAdminStats({
    required this.viajesHoy,
    required this.ingresosHoy,
    required this.ocupacionPromedio,
    required this.comisionesDia,
    required this.viajesMes,
    required this.ingresosMes,
    required this.comisionesMes,
  });

  final int viajesHoy;
  final double ingresosHoy;
  final double ocupacionPromedio;
  final double comisionesDia;
  final int viajesMes;
  final double ingresosMes;
  final double comisionesMes;
}

enum MockAdminConductorEstado {
  enRuta,
  disponible,
  inactivo,
  bloqueado,
}

class MockAdminConductor {
  const MockAdminConductor({
    required this.id,
    this.driverRecordId,
    required this.nombres,
    required this.apellidos,
    required this.dni,
    required this.telefono,
    required this.correo,
    required this.placa,
    required this.vehiculoTipo,
    required this.capacidad,
    required this.comisionPorcentaje,
    required this.ratingPromedio,
    required this.ratingCount,
    required this.estado,
    required this.bloqueadoPorPago,
    this.comisionPendientePorcentaje,
    this.comisionPendienteDesde,
  });

  final String id;
  final String? driverRecordId;
  final String nombres;
  final String apellidos;
  final String dni;
  final String telefono;
  final String correo;
  final String placa;
  final String vehiculoTipo;
  final int capacidad;
  final double comisionPorcentaje;
  final double ratingPromedio;
  final int ratingCount;
  final MockAdminConductorEstado estado;
  final bool bloqueadoPorPago;
  final double? comisionPendientePorcentaje;
  final DateTime? comisionPendienteDesde;

  String get nombreCompleto => '$nombres $apellidos';

  MockAdminConductor copyWith({
    String? driverRecordId,
    String? nombres,
    String? apellidos,
    String? dni,
    String? telefono,
    String? correo,
    String? placa,
    String? vehiculoTipo,
    int? capacidad,
    double? comisionPorcentaje,
    double? ratingPromedio,
    int? ratingCount,
    MockAdminConductorEstado? estado,
    bool? bloqueadoPorPago,
    double? comisionPendientePorcentaje,
    DateTime? comisionPendienteDesde,
  }) {
    return MockAdminConductor(
      id: id,
      driverRecordId: driverRecordId ?? this.driverRecordId,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      dni: dni ?? this.dni,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      placa: placa ?? this.placa,
      vehiculoTipo: vehiculoTipo ?? this.vehiculoTipo,
      capacidad: capacidad ?? this.capacidad,
      comisionPorcentaje: comisionPorcentaje ?? this.comisionPorcentaje,
      ratingPromedio: ratingPromedio ?? this.ratingPromedio,
      ratingCount: ratingCount ?? this.ratingCount,
      estado: estado ?? this.estado,
      bloqueadoPorPago: bloqueadoPorPago ?? this.bloqueadoPorPago,
      comisionPendientePorcentaje:
          comisionPendientePorcentaje ?? this.comisionPendientePorcentaje,
      comisionPendienteDesde: comisionPendienteDesde ?? this.comisionPendienteDesde,
    );
  }
}

enum MockAdminViajeEstado {
  completado,
  cancelado,
}

class MockAdminViaje {
  const MockAdminViaje({
    required this.id,
    required this.conductorId,
    required this.fecha,
    required this.rutaLabel,
    required this.monto,
    required this.estado,
  });

  final String id;
  final String conductorId;
  final DateTime fecha;
  final String rutaLabel;
  final double monto;
  final MockAdminViajeEstado estado;
}
