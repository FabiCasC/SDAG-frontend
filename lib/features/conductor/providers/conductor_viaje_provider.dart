import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/audit_log_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../reserva/utils/trip_rules.dart';

enum ConductorEstadoViaje {
  esperando,
  enRuta,
  completado,
}

enum EstadoPasajero {
  pendiente,
  abordo,
  noAbordo,
}

enum ConductorToastType {
  success,
  error,
  warning,
  info,
}

class PasajeroViaje {
  const PasajeroViaje({
    required this.id,
    required this.profileId,
    required this.nombre,
    required this.telefono,
    required this.dni,
    required this.asientos,
    required this.puntoRecojo,
    this.estado = EstadoPasajero.pendiente,
  });

  /// Id de la reserva (fila `reservations`).
  final String id;

  /// Id del perfil del pasajero (`passenger_profile_id`).
  final String profileId;
  final String nombre;
  final String telefono;
  final String dni;
  final List<int> asientos;
  final String puntoRecojo;
  final EstadoPasajero estado;

  int get asiento => asientos.isEmpty ? 0 : asientos.first;

  String get asientosLabel => asientos.map((seat) => '#$seat').join(', ');
}

class ConductorViajeState {
  const ConductorViajeState({
    required this.loading,
    required this.processingAction,
    required this.hasActiveTrip,
    required this.driverId,
    required this.tripId,
    required this.estadoViaje,
    required this.routeName,
    required this.fromLabel,
    required this.toLabel,
    required this.driverPlate,
    required this.vehicleType,
    required this.totalSeats,
    required this.asientosOcupados,
    required this.pasajerosViaje,
    required this.scheduledDepartureAt,
    required this.startedAt,
    required this.etaMinutes,
    required this.amountTotal,
    required this.baseFare,
    required this.errorMessage,
    required this.toastMessage,
    required this.toastType,
    required this.toastId,
  });

  final bool loading;
  final bool processingAction;
  final bool hasActiveTrip;
  final String? driverId;
  final String? tripId;
  final ConductorEstadoViaje estadoViaje;
  final String? routeName;
  final String? fromLabel;
  final String? toLabel;
  final String? driverPlate;
  final String? vehicleType;
  final int totalSeats;
  final List<int> asientosOcupados;
  final List<PasajeroViaje> pasajerosViaje;
  final DateTime? scheduledDepartureAt;
  final DateTime? startedAt;
  final int? etaMinutes;
  final double? amountTotal;
  final double? baseFare;
  final String? errorMessage;
  final String? toastMessage;
  final ConductorToastType? toastType;
  final int toastId;

  bool get isActive => hasActiveTrip && estadoViaje != ConductorEstadoViaje.completado;
  bool get isFull => totalSeats > 0 && occupiedSeats >= totalSeats;
  int get occupiedSeats => asientosOcupados.length;
  bool get canStartTrip =>
      hasActiveTrip &&
      !processingAction &&
      estadoViaje == ConductorEstadoViaje.esperando &&
      isFull;
  bool get canCompleteTrip =>
      hasActiveTrip &&
      !processingAction &&
      estadoViaje == ConductorEstadoViaje.enRuta;
  String get routeLabel {
    final from = fromLabel?.trim();
    final to = toLabel?.trim();
    if (from != null && from.isNotEmpty && to != null && to.isNotEmpty) {
      return '$from -> $to';
    }
    return routeName?.trim().isNotEmpty == true ? routeName!.trim() : 'Ruta no disponible';
  }

  ConductorViajeState copyWith({
    bool? loading,
    bool? processingAction,
    bool? hasActiveTrip,
    String? driverId,
    bool clearDriverId = false,
    String? tripId,
    bool clearTripId = false,
    ConductorEstadoViaje? estadoViaje,
    String? routeName,
    bool clearRouteName = false,
    String? fromLabel,
    bool clearFromLabel = false,
    String? toLabel,
    bool clearToLabel = false,
    String? driverPlate,
    bool clearDriverPlate = false,
    String? vehicleType,
    bool clearVehicleType = false,
    int? totalSeats,
    List<int>? asientosOcupados,
    List<PasajeroViaje>? pasajerosViaje,
    DateTime? scheduledDepartureAt,
    bool clearScheduledDepartureAt = false,
    DateTime? startedAt,
    bool clearStartedAt = false,
    int? etaMinutes,
    bool clearEtaMinutes = false,
    double? amountTotal,
    bool clearAmountTotal = false,
    double? baseFare,
    bool clearBaseFare = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? toastMessage,
    ConductorToastType? toastType,
    bool clearToast = false,
    int? toastId,
  }) {
    return ConductorViajeState(
      loading: loading ?? this.loading,
      processingAction: processingAction ?? this.processingAction,
      hasActiveTrip: hasActiveTrip ?? this.hasActiveTrip,
      driverId: clearDriverId ? null : (driverId ?? this.driverId),
      tripId: clearTripId ? null : (tripId ?? this.tripId),
      estadoViaje: estadoViaje ?? this.estadoViaje,
      routeName: clearRouteName ? null : (routeName ?? this.routeName),
      fromLabel: clearFromLabel ? null : (fromLabel ?? this.fromLabel),
      toLabel: clearToLabel ? null : (toLabel ?? this.toLabel),
      driverPlate: clearDriverPlate ? null : (driverPlate ?? this.driverPlate),
      vehicleType: clearVehicleType ? null : (vehicleType ?? this.vehicleType),
      totalSeats: totalSeats ?? this.totalSeats,
      asientosOcupados: asientosOcupados ?? this.asientosOcupados,
      pasajerosViaje: pasajerosViaje ?? this.pasajerosViaje,
      scheduledDepartureAt: clearScheduledDepartureAt
          ? null
          : (scheduledDepartureAt ?? this.scheduledDepartureAt),
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      etaMinutes: clearEtaMinutes ? null : (etaMinutes ?? this.etaMinutes),
      amountTotal: clearAmountTotal ? null : (amountTotal ?? this.amountTotal),
      baseFare: clearBaseFare ? null : (baseFare ?? this.baseFare),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      toastMessage: clearToast ? null : (toastMessage ?? this.toastMessage),
      toastType: clearToast ? null : (toastType ?? this.toastType),
      toastId: toastId ?? this.toastId,
    );
  }

  static const initial = ConductorViajeState(
    loading: true,
    processingAction: false,
    hasActiveTrip: false,
    driverId: null,
    tripId: null,
    estadoViaje: ConductorEstadoViaje.esperando,
    routeName: null,
    fromLabel: null,
    toLabel: null,
    driverPlate: null,
    vehicleType: null,
    totalSeats: 0,
    asientosOcupados: <int>[],
    pasajerosViaje: <PasajeroViaje>[],
    scheduledDepartureAt: null,
    startedAt: null,
    etaMinutes: null,
    amountTotal: null,
    baseFare: null,
    errorMessage: null,
    toastMessage: null,
    toastType: null,
    toastId: 0,
  );
}

class ConductorViajeController extends StateNotifier<ConductorViajeState> {
  ConductorViajeController() : super(ConductorViajeState.initial) {
    unawaited(refresh());
  }

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  bool _autoStartInFlight = false;
  DateTime? _vehicleFullSince;
  Timer? _departureCountdownTimer;

  Future<void> refresh() async {
    await _cancelReservationSubscription();
    state = state.copyWith(
      loading: true,
      processingAction: false,
      clearErrorMessage: true,
    );

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          loading: false,
          hasActiveTrip: false,
          errorMessage: 'No se encontró una sesión activa.',
        );
        return;
      }

      final driver = await Supabase.instance.client
          .from('drivers')
          .select('id, plate, capacity, vehicle_type, commission_pct')
          .eq('profile_id', user.id)
          .single();

      final driverId = driver['id']?.toString();
      if (driverId == null || driverId.isEmpty) {
        state = state.copyWith(
          loading: false,
          hasActiveTrip: false,
          errorMessage: 'No se pudo identificar tu cuenta de conductor.',
        );
        return;
      }

      final trip = await Supabase.instance.client
          .from('trips')
          .select('''
            id, status, scheduled_departure_at, started_at, eta_minutes, amount_total, base_fare,
            routes(id, name, from_label, to_label),
            vehicles(id, plate, vehicle_type, total_seats)
          ''')
          .eq('driver_id', driverId)
          .inFilter('status', ['esperando', 'en_ruta'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (trip == null) {
        state = state.copyWith(
          loading: false,
          hasActiveTrip: false,
          driverId: driverId,
          driverPlate: _asString(driver['plate']),
          vehicleType: _asString(driver['vehicle_type']),
          totalSeats: _asInt(driver['capacity']),
          asientosOcupados: const <int>[],
          pasajerosViaje: const <PasajeroViaje>[],
          clearTripId: true,
          clearRouteName: true,
          clearFromLabel: true,
          clearToLabel: true,
          clearScheduledDepartureAt: true,
          clearStartedAt: true,
          clearEtaMinutes: true,
          clearAmountTotal: true,
          clearBaseFare: true,
        );
        return;
      }

      await _applyTripData(
        driverId: driverId,
        driver: driver,
        trip: trip,
        subscribeRealtime: true,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        hasActiveTrip: false,
        errorMessage: 'No se pudo cargar tu viaje activo.',
      );
    }
  }

  Future<void> iniciarRuta() async {
    if (!state.canStartTrip || state.tripId == null || state.driverId == null) {
      _toast(ConductorToastType.warning, 'El vehiculo debe estar completo para iniciar el viaje.');
      return;
    }

    try {
      state = state.copyWith(processingAction: true, clearErrorMessage: true);

      await Supabase.instance.client
          .from('trips')
          .update({
            'status': 'en_ruta',
            'started_at': DateTime.now().toIso8601String(),
          })
          .eq('id', state.tripId!);

      await Supabase.instance.client
          .from('drivers')
          .update({'estado': 'en_ruta'})
          .eq('id', state.driverId!);

      state = state.copyWith(
        processingAction: false,
        estadoViaje: ConductorEstadoViaje.enRuta,
        startedAt: DateTime.now(),
      );
      _toast(ConductorToastType.success, 'Viaje iniciado correctamente.');
      await refresh();
    } catch (_) {
      state = state.copyWith(
        processingAction: false,
        errorMessage: 'No se pudo iniciar el viaje.',
      );
      _toast(ConductorToastType.error, 'No se pudo iniciar el viaje.');
    }
  }

  Future<void> completarRuta() async {
    if (!state.canCompleteTrip || state.tripId == null || state.driverId == null) {
      return;
    }

    try {
      state = state.copyWith(processingAction: true, clearErrorMessage: true);

      final manifest = await Supabase.instance.client
          .from('manifests')
          .select('id')
          .eq('trip_id', state.tripId!)
          .maybeSingle();

      if (manifest != null) {
        final manifestId = manifest['id']?.toString();
        if (manifestId != null && manifestId.isNotEmpty) {
          await Supabase.instance.client
              .from('manifest_entries')
              .update({'boarding_status': 'no_abordo'})
              .eq('manifest_id', manifestId)
              .eq('boarding_status', 'pendiente');
        }
      }

      await Supabase.instance.client
          .from('trips')
          .update({
            'status': 'completado',
            'finished_at': DateTime.now().toIso8601String(),
          })
          .eq('id', state.tripId!);

      await Supabase.instance.client
          .from('trip_messages')
          .update({'message_status': 'archivado'})
          .eq('trip_id', state.tripId!);

      await Supabase.instance.client
          .from('drivers')
          .update({'estado': 'disponible'})
          .eq('id', state.driverId!);

      state = state.copyWith(
        processingAction: false,
        estadoViaje: ConductorEstadoViaje.completado,
      );
      _toast(ConductorToastType.success, 'Viaje completado correctamente.');
      await refresh();
    } catch (_) {
      state = state.copyWith(
        processingAction: false,
        errorMessage: 'No se pudo completar el viaje.',
      );
      _toast(ConductorToastType.error, 'No se pudo completar el viaje.');
    }
  }

  void clearToast() {
    state = state.copyWith(clearToast: true);
  }

  Future<void> _applyTripData({
    required String driverId,
    required Map<String, dynamic> driver,
    required Map<String, dynamic> trip,
    required bool subscribeRealtime,
  }) async {
    final tripId = trip['id']?.toString();
    final route = _nestedMap(trip['routes']);
    final vehicle = _nestedMap(trip['vehicles']);
    final totalSeats = _asInt(vehicle['total_seats']) > 0
        ? _asInt(vehicle['total_seats'])
        : _asInt(driver['capacity']);
    final reservas = await _loadReservations(tripId ?? '');
    final occupied = _collectSeats(reservas);
    final tripStatus = _asString(trip['status']);

    state = state.copyWith(
      loading: false,
      processingAction: false,
      hasActiveTrip: tripId != null && tripId.isNotEmpty,
      driverId: driverId,
      tripId: tripId,
      estadoViaje: tripStatus == 'en_ruta'
          ? ConductorEstadoViaje.enRuta
          : ConductorEstadoViaje.esperando,
      routeName: _asString(route['name']),
      fromLabel: _asString(route['from_label']),
      toLabel: _asString(route['to_label']),
      driverPlate: _asString(vehicle['plate']) ?? _asString(driver['plate']),
      vehicleType: _asString(vehicle['vehicle_type']) ?? _asString(driver['vehicle_type']),
      totalSeats: totalSeats,
      asientosOcupados: occupied,
      pasajerosViaje: reservas,
      scheduledDepartureAt: _asDateTime(trip['scheduled_departure_at']),
      startedAt: _asDateTime(trip['started_at']),
      etaMinutes: _asNullableInt(trip['eta_minutes']),
      amountTotal: _asDouble(trip['amount_total']),
      baseFare: _asDouble(trip['base_fare']),
      clearErrorMessage: true,
    );

    if (tripStatus == 'esperando') {
      await _verificarInicioAutomatico(
        tripId: tripId ?? '',
        capacidad: totalSeats,
        driverId: driverId,
      );
    }

    if (subscribeRealtime && tripId != null && tripId.isNotEmpty) {
      _subscription = Supabase.instance.client
          .from('reservations')
          .stream(primaryKey: ['id'])
          .eq('trip_id', tripId)
          .listen((_) async {
        try {
          final reservasActualizadas = await _loadReservations(tripId);
          final seats = _collectSeats(reservasActualizadas);
          state = state.copyWith(
            asientosOcupados: seats,
            pasajerosViaje: reservasActualizadas,
          );
          await _verificarInicioAutomatico(
            tripId: tripId,
            capacidad: state.totalSeats,
            driverId: driverId,
          );
        } catch (_) {
          _toast(ConductorToastType.error, 'No se pudo actualizar la lista de pasajeros.');
        }
      });
    }
  }

  Future<void> _verificarInicioAutomatico({
    required String tripId,
    required int capacidad,
    required String driverId,
  }) async {
    if (_autoStartInFlight || tripId.isEmpty || capacidad <= 0) return;
    if (state.estadoViaje != ConductorEstadoViaje.esperando) return;

    try {
      final reservas = await Supabase.instance.client
          .from('reservations')
          .select('seats')
          .eq('trip_id', tripId)
          .inFilter('status', ['activa', 'completada']);

      final asientosOcupados = (reservas as List)
          .expand((r) => (r['seats'] as List? ?? const []))
          .length;

      if (asientosOcupados < capacidad) {
        _vehicleFullSince = null;
        _departureCountdownTimer?.cancel();
        _departureCountdownTimer = null;
        return;
      }

      _vehicleFullSince ??= DateTime.now();
      PushNotificationService.instance.notifyVehicleFull();

      if (!canDepartAfterCountdown(
        fullSince: _vehicleFullSince,
        now: DateTime.now(),
        isFull: true,
      )) {
        _departureCountdownTimer ??= Timer.periodic(const Duration(seconds: 1), (_) async {
          if (!canDepartAfterCountdown(
            fullSince: _vehicleFullSince,
            now: DateTime.now(),
            isFull: true,
          )) {
            return;
          }
          _departureCountdownTimer?.cancel();
          _departureCountdownTimer = null;
          await _verificarInicioAutomatico(
            tripId: tripId,
            capacidad: capacidad,
            driverId: driverId,
          );
        });
        return;
      }

      _autoStartInFlight = true;
      _departureCountdownTimer?.cancel();
      _departureCountdownTimer = null;

      await Supabase.instance.client.from('trips').update({
        'status': 'en_ruta',
        'started_at': DateTime.now().toIso8601String(),
      }).eq('id', tripId);

      await Supabase.instance.client
          .from('drivers')
          .update({'estado': 'en_ruta'})
          .eq('id', driverId);

      await logAuditEvent(
        eventType: 'trip_auto_start',
        actorId: driverId,
        actorRole: 'conductor',
        metadata: {'trip_id': tripId},
      );

      state = state.copyWith(
        estadoViaje: ConductorEstadoViaje.enRuta,
        startedAt: DateTime.now(),
      );
      _vehicleFullSince = null;
      _toast(
        ConductorToastType.success,
        'Carro lleno. Viaje iniciado tras temporizador de 3 minutos.',
      );
    } catch (_) {
      _toast(ConductorToastType.error, 'No se pudo iniciar el viaje automaticamente.');
    } finally {
      _autoStartInFlight = false;
    }
  }

  Future<List<PasajeroViaje>> _loadReservations(String tripId) async {
    if (tripId.isEmpty) return const <PasajeroViaje>[];

    final rows = await Supabase.instance.client
        .from('reservations')
        .select('''
          id, passenger_profile_id, seats, pickup_point, status, amount,
          profiles:passenger_profile_id(id, name, first_name, last_name, phone, dni)
        ''')
        .eq('trip_id', tripId)
        .inFilter('status', ['activa', 'completada']);

    final reservas = (rows as List)
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .map(_mapPassenger)
        .toList()
      ..sort((a, b) => a.asiento.compareTo(b.asiento));
    return reservas;
  }

  PasajeroViaje _mapPassenger(Map<String, dynamic> row) {
    final profile = _nestedMap(row['profiles']);
    final name = _buildFullName(profile);
    return PasajeroViaje(
      id: _asString(row['id']) ?? '',
      profileId: _asString(row['passenger_profile_id']) ?? '',
      nombre: name.isEmpty ? 'Pasajero sin nombre' : name,
      telefono: _asString(profile['phone']) ?? 'Sin telefono',
      dni: _asString(profile['dni']) ?? 'Sin DNI',
      asientos: _parseSeats(row['seats']),
      puntoRecojo: _asString(row['pickup_point']) ?? 'Punto no definido',
    );
  }

  List<int> _collectSeats(List<PasajeroViaje> reservas) {
    final seats = reservas.expand((passenger) => passenger.asientos).toSet().toList()..sort();
    return seats;
  }

  void _toast(ConductorToastType type, String message) {
    state = state.copyWith(
      toastMessage: message,
      toastType: type,
      toastId: state.toastId + 1,
    );
  }

  Future<void> _cancelReservationSubscription() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Map<String, dynamic> _nestedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return <String, dynamic>{};
  }

  String _buildFullName(Map<String, dynamic> profile) {
    final fullName = _asString(profile['name']);
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    final parts = <String>[
      _asString(profile['first_name']) ?? '',
      _asString(profile['last_name']) ?? '',
    ].where((part) => part.trim().isNotEmpty).toList();
    return parts.join(' ').trim();
  }

  List<int> _parseSeats(dynamic rawSeats) {
    if (rawSeats is! List) return const <int>[];
    final seats = rawSeats
        .map((seat) => seat is int ? seat : int.tryParse(seat.toString()))
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();
    return seats;
  }

  String? _asString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    return _asInt(value);
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final conductorViajeProvider =
    StateNotifierProvider<ConductorViajeController, ConductorViajeState>(
  (ref) => ConductorViajeController(),
);
