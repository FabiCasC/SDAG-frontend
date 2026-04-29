import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DriverStop {
  const DriverStop({
    required this.passengerName,
    required this.stopName,
    required this.positionMeters,
    required this.dni,
  });

  final String passengerName;
  final String stopName;
  final Offset positionMeters;
  final String dni;
}

class EmergencyAlert {
  const EmergencyAlert({
    required this.role,
    required this.sourceDni,
    required this.createdAt,
    required this.vehicleMeters,
  });

  final String role;
  final String sourceDni;
  final DateTime createdAt;
  final Offset vehicleMeters;
}

class SpeedInfraction {
  const SpeedInfraction({required this.kmh, required this.at, required this.vehicleMeters});

  final double kmh;
  final DateTime at;
  final Offset vehicleMeters;
}

class OfflineEvent {
  const OfflineEvent({required this.type, required this.at, required this.data});

  final String type;
  final DateTime at;
  final Map<String, Object?> data;
}

class ExpenseEntry {
  const ExpenseEntry({
    required this.amount,
    required this.motive,
    required this.hasVoucher,
    required this.at,
    required this.vehicleMeters,
    required this.placa,
    required this.driverDni,
  });

  final double amount;
  final String motive;
  final bool hasVoucher;
  final DateTime at;
  final Offset vehicleMeters;
  final String placa;
  final String driverDni;
}

class IncidentEntry {
  const IncidentEntry({
    required this.kind,
    required this.description,
    required this.at,
    required this.vehicleMeters,
    required this.placa,
    required this.driverDni,
    required this.count,
  });

  final String kind;
  final String description;
  final DateTime at;
  final Offset vehicleMeters;
  final String placa;
  final String driverDni;
  final int count;
}

class DocumentEntry {
  const DocumentEntry({
    required this.placa,
    required this.docType,
    required this.expiresAt,
  });

  final String placa;
  final String docType;
  final DateTime expiresAt;
}

class TicketEntry {
  const TicketEntry({
    required this.code,
    required this.ruta,
    required this.destino,
    required this.salida,
    required this.seat,
    required this.createdAt,
  });

  final String code;
  final String ruta;
  final String destino;
  final String salida;
  final int seat;
  final DateTime createdAt;
}

class VehicleInfo {
  const VehicleInfo({
    required this.placa,
    required this.model,
    required this.colorName,
  });

  final String placa;
  final String model;
  final String colorName;
}

class UserProfile {
  const UserProfile({
    required this.dni,
    required this.role,
    required this.displayName,
    required this.phone,
    required this.photoSeed,
    required this.doNotDisturb,
  });

  final String dni;
  final String role;
  final String displayName;
  final String phone;
  final int photoSeed;
  final bool doNotDisturb;

  UserProfile copyWith({
    String? displayName,
    String? phone,
    int? photoSeed,
    bool? doNotDisturb,
  }) {
    return UserProfile(
      dni: dni,
      role: role,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      photoSeed: photoSeed ?? this.photoSeed,
      doNotDisturb: doNotDisturb ?? this.doNotDisturb,
    );
  }
}

class PassengerTripRecord {
  const PassengerTripRecord({
    required this.id,
    required this.passengerDni,
    required this.driverDni,
    required this.stopName,
    required this.ruta,
    required this.destino,
    required this.salida,
    required this.seats,
    required this.farePerSeat,
    required this.totalCost,
    required this.placa,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.createdAt,
    required this.status,
    required this.finishedAt,
    required this.ratingStars,
    required this.ratingComment,
    required this.ratingFlagged,
  });

  final String id;
  final String passengerDni;
  final String driverDni;
  final String stopName;
  final String ruta;
  final String destino;
  final String salida;
  final List<int> seats;
  final double farePerSeat;
  final double totalCost;
  final String placa;
  final String vehicleModel;
  final String vehicleColor;
  final DateTime createdAt;
  final String status;
  final DateTime? finishedAt;
  final int? ratingStars;
  final String? ratingComment;
  final bool ratingFlagged;

  PassengerTripRecord copyWith({
    String? status,
    DateTime? finishedAt,
    int? ratingStars,
    String? ratingComment,
    bool? ratingFlagged,
  }) {
    return PassengerTripRecord(
      id: id,
      passengerDni: passengerDni,
      driverDni: driverDni,
      stopName: stopName,
      ruta: ruta,
      destino: destino,
      salida: salida,
      seats: seats,
      farePerSeat: farePerSeat,
      totalCost: totalCost,
      placa: placa,
      vehicleModel: vehicleModel,
      vehicleColor: vehicleColor,
      createdAt: createdAt,
      status: status ?? this.status,
      finishedAt: finishedAt ?? this.finishedAt,
      ratingStars: ratingStars ?? this.ratingStars,
      ratingComment: ratingComment ?? this.ratingComment,
      ratingFlagged: ratingFlagged ?? this.ratingFlagged,
    );
  }
}

class DriverRatingAggregate {
  const DriverRatingAggregate({
    required this.driverDni,
    required this.average,
    required this.count,
  });

  final String driverDni;
  final double average;
  final int count;
}

class FlaggedRatingEntry {
  const FlaggedRatingEntry({
    required this.tripId,
    required this.driverDni,
    required this.passengerDni,
    required this.placa,
    required this.stars,
    required this.comment,
    required this.at,
  });

  final String tripId;
  final String driverDni;
  final String passengerDni;
  final String placa;
  final int stars;
  final String comment;
  final DateTime at;
}

class QuickChatMessage {
  const QuickChatMessage({
    required this.conversationId,
    required this.fromRole,
    required this.fromDni,
    required this.toDni,
    required this.text,
    required this.sentAt,
    required this.readAt,
  });

  final String conversationId;
  final String fromRole;
  final String fromDni;
  final String toDni;
  final String text;
  final DateTime sentAt;
  final DateTime? readAt;

  QuickChatMessage copyWith({DateTime? readAt}) {
    return QuickChatMessage(
      conversationId: conversationId,
      fromRole: fromRole,
      fromDni: fromDni,
      toDni: toDni,
      text: text,
      sentAt: sentAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

class NewsNotification {
  const NewsNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isEmergency,
    required this.createdAt,
    required this.createdByDni,
  });

  final String id;
  final String title;
  final String body;
  final bool isEmergency;
  final DateTime createdAt;
  final String createdByDni;
}

class PunctualityRecord {
  const PunctualityRecord({
    required this.driverDni,
    required this.placa,
    required this.filledAt,
    required this.departedAt,
    required this.trafficHeavy,
  });

  final String driverDni;
  final String placa;
  final DateTime filledAt;
  final DateTime departedAt;
  final bool trafficHeavy;
}

class WeatherInfo {
  const WeatherInfo({
    required this.condition,
    required this.temperatureC,
    required this.updatedAt,
  });

  final String condition;
  final int temperatureC;
  final DateTime updatedAt;
}

class SupportFeedbackEntry {
  const SupportFeedbackEntry({
    required this.id,
    required this.fromDni,
    required this.fromRole,
    required this.message,
    required this.deviceModel,
    required this.appVersion,
    required this.at,
    required this.sent,
  });

  final String id;
  final String fromDni;
  final String fromRole;
  final String message;
  final String deviceModel;
  final String appVersion;
  final DateTime at;
  final bool sent;

  SupportFeedbackEntry copyWith({bool? sent}) {
    return SupportFeedbackEntry(
      id: id,
      fromDni: fromDni,
      fromRole: fromRole,
      message: message,
      deviceModel: deviceModel,
      appVersion: appVersion,
      at: at,
      sent: sent ?? this.sent,
    );
  }
}

class SatisfactionSurveyResponse {
  const SatisfactionSurveyResponse({
    required this.passengerDni,
    required this.monthKey,
    required this.q1,
    required this.q2,
    required this.q3,
    required this.at,
  });

  final String passengerDni;
  final String monthKey;
  final int q1;
  final int q2;
  final int q3;
  final DateTime at;
}

class EmergencyStopEntry {
  const EmergencyStopEntry({
    required this.id,
    required this.placa,
    required this.driverDni,
    required this.startedAt,
    required this.startMeters,
    required this.endedAt,
    required this.duration,
    required this.note,
    required this.longStopAlerted,
  });

  final String id;
  final String placa;
  final String driverDni;
  final DateTime startedAt;
  final Offset startMeters;
  final DateTime? endedAt;
  final Duration? duration;
  final String note;
  final bool longStopAlerted;

  EmergencyStopEntry copyWith({
    DateTime? endedAt,
    Duration? duration,
    bool? longStopAlerted,
  }) {
    return EmergencyStopEntry(
      id: id,
      placa: placa,
      driverDni: driverDni,
      startedAt: startedAt,
      startMeters: startMeters,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      note: note,
      longStopAlerted: longStopAlerted ?? this.longStopAlerted,
    );
  }
}

class TripSimulationService extends ChangeNotifier {
  TripSimulationService._();

  static final TripSimulationService instance = TripSimulationService._();

  Timer? _timer;
  bool _running = false;

  bool get isRunning => _running;

  Offset _vehicleMeters = const Offset(0, 0);
  Offset get vehicleMeters => _vehicleMeters;

  double _lastSpeedKmh = 0;
  double get lastSpeedKmh => _lastSpeedKmh;

  DateTime _lastMovedAt = DateTime.now();
  DateTime get lastMovedAt => _lastMovedAt;

  final List<Offset> _gpsLogMeters = [];
  List<Offset> get gpsLogMeters => List.unmodifiable(_gpsLogMeters);

  final List<Offset> _pathMeters = const [
    Offset(0, 0),
    Offset(1500, 0),
    Offset(3000, 400),
    Offset(4500, 900),
    Offset(6000, 900),
  ];

  int _pathIndex = 0;
  double _tickSeconds = 5;
  final double _speedMetersPerSecond = 16;

  final Offset passengerStopMeters = const Offset(5000, 900);
  final Offset finalStopMeters = const Offset(6000, 900);

  final Set<String> blockedDriverDnis = {};

  String _currentSessionDni = '';
  String get currentSessionDni => _currentSessionDni;

  String _currentSessionRole = '';
  String get currentSessionRole => _currentSessionRole;

  void setCurrentSession({required String dni, required String role}) {
    _currentSessionDni = dni;
    _currentSessionRole = role;
    _profiles.putIfAbsent(
      dni,
      () => UserProfile(
        dni: dni,
        role: role,
        displayName: role == 'Dueño'
            ? 'Dueño'
            : role == 'Conductor'
                ? 'Conductor'
                : 'Pasajero',
        phone: '',
        photoSeed: dni.hashCode,
        doNotDisturb: false,
      ),
    );
    notifyListeners();
  }

  EmergencyAlert? activeEmergency;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final List<OfflineEvent> _offlineQueue = [];
  List<OfflineEvent> get offlineQueue => List.unmodifiable(_offlineQueue);
  int get pendingSyncCount => _offlineQueue.length;

  final List<OfflineEvent> _syncedEvents = [];
  List<OfflineEvent> get syncedEvents => List.unmodifiable(_syncedEvents);

  final List<SpeedInfraction> _speedInfractions = [];
  List<SpeedInfraction> get speedInfractions => List.unmodifiable(_speedInfractions);
  int _highSpeedTicks = 0;

  final Map<String, bool> _dataSaverByDriver = {};
  bool dataSaverEnabled(String driverDni) => _dataSaverByDriver[driverDni] ?? false;

  final Map<String, String> _alertToneByDriver = {};
  String alertTone(String driverDni) => _alertToneByDriver[driverDni] ?? 'Alerta';

  final Map<String, String> _voiceProfileByDriver = {};
  String voiceProfile(String driverDni) => _voiceProfileByDriver[driverDni] ?? 'Femenino';

  final Map<String, bool> _autoNightModeByDriver = {};
  bool autoNightModeEnabled(String driverDni) => _autoNightModeByDriver[driverDni] ?? false;

  WeatherInfo _weather = WeatherInfo(condition: 'Desconocido', temperatureC: 0, updatedAt: DateTime.now());
  WeatherInfo get weather => _weather;

  final String currentAppVersion = '1.0.0';
  String latestAppVersion = '1.0.1';
  bool updateAvailable = true;
  bool updateCritical = false;
  String updateUrl = 'https://example.com/sdag/update';
  DateTime? lastPaymentAt;
  double lastPaymentAmount = 0;
  String lastPaymentTxId = '';

  ({bool available, bool critical, String latest, String url}) checkForUpdate() {
    return (available: updateAvailable, critical: updateCritical, latest: latestAppVersion, url: updateUrl);
  }

  void setUpdateInfo({
    required String latestVersion,
    required bool available,
    required bool critical,
    required String url,
  }) {
    latestAppVersion = latestVersion;
    updateAvailable = available;
    updateCritical = critical;
    updateUrl = url;
    notifyListeners();
  }

  final Map<String, ({String url, DateTime expiresAt})> _shareLinksByPassenger = {};

  final List<SupportFeedbackEntry> _supportFeedback = [];
  List<SupportFeedbackEntry> get supportFeedback => List.unmodifiable(_supportFeedback);

  final List<SatisfactionSurveyResponse> _surveyResponses = [];
  List<SatisfactionSurveyResponse> get surveyResponses => List.unmodifiable(_surveyResponses);

  bool simulateDeviation = false;
  bool deviationJustified = false;
  double deviationMeters = 0;
  int deviationInfractions = 0;
  int _deviationOver300Ticks = 0;

  final int tripCapacity = 15;
  final Set<int> occupiedSeats = {2, 5, 9};
  final Set<int> releasedSeats = {};

  final List<VehicleInfo> fleetVehicles = const [
    VehicleInfo(placa: 'BJK-102', model: 'Toyota Hiace', colorName: 'Blanco'),
    VehicleInfo(placa: 'SDG-101', model: 'Hyundai H1', colorName: 'Plateado'),
    VehicleInfo(placa: 'SDG-102', model: 'Nissan Urvan', colorName: 'Gris'),
    VehicleInfo(placa: 'XTR-990', model: 'Kia Pregio', colorName: 'Azul'),
  ];

  VehicleInfo _assignedVehicle = const VehicleInfo(placa: 'BJK-102', model: 'Toyota Hiace', colorName: 'Blanco');
  VehicleInfo get assignedVehicle => _assignedVehicle;

  void setAssignedVehicle(VehicleInfo vehicle) {
    _assignedVehicle = vehicle;
    notifyListeners();
  }

  bool expressAuthorized = false;
  bool expressPending = false;
  double expressFarePerSeat = 10.0;
  double expressExtraPerPassenger = 0;
  double expressEmptySeatsCost = 0;
  int expressFilledAtRequest = 0;

  String unitStatus = 'Carga';
  bool arrivedAtFinalStop = false;
  DateTime? arrivedAtFinalStopAt;
  bool autoClosed = false;

  double _routeDistanceMeters = 0;
  double get routeDistanceKm => _routeDistanceMeters / 1000.0;
  final Map<String, double> _dailyKmByDriver = {};
  final Map<String, double> _dailyKmByPlaca = {};
  final Map<String, double> _dailyKmEmptyMetersByPlaca = {};

  String _dayKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  double dailyKmForDriver(String driverDni, {DateTime? day}) {
    final key = '${_dayKey(day ?? DateTime.now())}|$driverDni';
    return (_dailyKmByDriver[key] ?? 0) / 1000.0;
  }

  double dailyKmForPlaca(String placa, {DateTime? day}) {
    final key = '${_dayKey(day ?? DateTime.now())}|$placa';
    return (_dailyKmByPlaca[key] ?? 0) / 1000.0;
  }

  double dailyEmptyKmForPlaca(String placa, {DateTime? day}) {
    final key = '${_dayKey(day ?? DateTime.now())}|$placa';
    return (_dailyKmEmptyMetersByPlaca[key] ?? 0) / 1000.0;
  }

  final List<EmergencyStopEntry> _emergencyStops = [];
  List<EmergencyStopEntry> get emergencyStops => List.unmodifiable(_emergencyStops);
  EmergencyStopEntry? _activeEmergencyStop;
  EmergencyStopEntry? get activeEmergencyStop => _activeEmergencyStop;

  bool get isEmergencyStopActive => _activeEmergencyStop != null && _activeEmergencyStop!.endedAt == null;
  Duration get emergencyStopElapsed => _activeEmergencyStop == null ? Duration.zero : DateTime.now().difference(_activeEmergencyStop!.startedAt);

  final List<String> baseQueueDriverDnis = [];

  final List<ExpenseEntry> _expenses = [];
  List<ExpenseEntry> get expenses => List.unmodifiable(_expenses);

  final List<IncidentEntry> _incidents = [];
  List<IncidentEntry> get incidents => List.unmodifiable(_incidents);

  final List<DocumentEntry> _documents = [
    DocumentEntry(placa: 'BJK-102', docType: 'SOAT', expiresAt: DateTime(2026, 5, 1)),
    DocumentEntry(placa: 'BJK-102', docType: 'RT', expiresAt: DateTime(2026, 4, 30)),
    DocumentEntry(placa: 'SDG-101', docType: 'SOAT', expiresAt: DateTime(2026, 6, 20)),
    DocumentEntry(placa: 'SDG-102', docType: 'SOAT', expiresAt: DateTime(2026, 5, 2)),
  ];
  List<DocumentEntry> get documents => List.unmodifiable(_documents);

  final List<TicketEntry> _tickets = [];
  List<TicketEntry> get tickets => List.unmodifiable(_tickets);
  final Set<String> _usedTicketCodes = {};
  Set<String> get usedTicketCodes => Set.unmodifiable(_usedTicketCodes);

  final Map<String, UserProfile> _profiles = {
    '11111111': UserProfile(dni: '11111111', role: 'Dueño', displayName: 'Pablo', phone: '999888777', photoSeed: 11, doNotDisturb: false),
    '22222222': UserProfile(dni: '22222222', role: 'Conductor', displayName: 'Juan Pérez', phone: '988777666', photoSeed: 22, doNotDisturb: false),
  };
  Map<String, UserProfile> get profiles => Map.unmodifiable(_profiles);

  UserProfile profileOf(String dni, {String roleFallback = 'Pasajero'}) {
    return _profiles.putIfAbsent(
      dni,
      () => UserProfile(dni: dni, role: roleFallback, displayName: roleFallback, phone: '', photoSeed: dni.hashCode, doNotDisturb: false),
    );
  }

  final List<String> _bannedNameTokens = const [
    'idiota',
    'imbecil',
    'tonto',
    'puta',
    'mierda',
  ];

  bool isDisplayNameAllowed(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    for (final t in _bannedNameTokens) {
      if (normalized.contains(t)) return false;
    }
    return true;
  }

  bool isPhoneAllowed(String phone) {
    final raw = phone.trim().replaceAll(' ', '');
    final regex = RegExp(r'^9\d{8}$');
    return regex.hasMatch(raw);
  }

  bool updateProfile({
    required String dni,
    required String displayName,
    required String phone,
    required int photoSeed,
    required bool doNotDisturb,
  }) {
    if (!isDisplayNameAllowed(displayName)) return false;
    if (phone.trim().isNotEmpty && !isPhoneAllowed(phone)) return false;
    final current = profileOf(dni);
    _profiles[dni] = current.copyWith(
      displayName: displayName.trim(),
      phone: phone.trim(),
      photoSeed: photoSeed,
      doNotDisturb: doNotDisturb,
    );
    _recordEvent('profile_updated', {'dni': dni});
    notifyListeners();
    return true;
  }

  final Map<String, String> _passwordByDni = {};
  final Map<String, ({String code, int attemptsLeft, bool locked})> _recoveryByDni = {};

  ({bool ok, String message}) startPasswordRecovery({required String dni, required String channel}) {
    final code = (Random().nextInt(900000) + 100000).toString();
    _recoveryByDni[dni] = (code: code, attemptsLeft: 3, locked: false);
    _recordEvent('recovery_started', {'dni': dni, 'via': channel});
    notifyListeners();
    return (ok: true, message: 'Código enviado (demo): $code');
  }

  ({bool ok, String message}) verifyRecoveryCode({required String dni, required String code}) {
    final state = _recoveryByDni[dni];
    if (state == null) return (ok: false, message: 'No hay recuperación activa');
    if (state.locked) return (ok: false, message: 'Recuperación bloqueada por seguridad');
    if (state.code == code.trim()) {
      _recordEvent('recovery_verified', {'dni': dni});
      notifyListeners();
      return (ok: true, message: 'Código verificado');
    }
    final next = state.attemptsLeft - 1;
    final locked = next <= 0;
    _recoveryByDni[dni] = (code: state.code, attemptsLeft: max(0, next), locked: locked);
    _recordEvent('recovery_failed', {'dni': dni, 'left': max(0, next)});
    notifyListeners();
    return locked ? (ok: false, message: 'Bloqueado tras 3 intentos') : (ok: false, message: 'Código incorrecto. Intentos: ${max(0, next)}');
  }

  ({bool ok, String message}) setNewPassword({required String dni, required String newPassword}) {
    if (newPassword.trim().length < 4) return (ok: false, message: 'Clave muy corta');
    final state = _recoveryByDni[dni];
    if (state == null) return (ok: false, message: 'No hay recuperación activa');
    if (state.locked) return (ok: false, message: 'Recuperación bloqueada');
    _passwordByDni[dni] = newPassword.trim();
    _recoveryByDni.remove(dni);
    _recordEvent('password_changed', {'dni': dni});
    notifyListeners();
    return (ok: true, message: 'Clave actualizada');
  }

  final Map<String, Set<String>> _favoriteStopsByPassenger = {};
  Set<String> favoriteStopsOf(String passengerDni) => Set.unmodifiable(_favoriteStopsByPassenger[passengerDni] ?? {});

  bool canFavoriteStop({required String passengerDni, required String stopName}) {
    return _tripHistory.any((t) => t.passengerDni == passengerDni && t.stopName == stopName);
  }

  ({bool ok, String message}) toggleFavoriteStop({required String passengerDni, required String stopName}) {
    if (!canFavoriteStop(passengerDni: passengerDni, stopName: stopName)) {
      return (ok: false, message: 'Debes haber reservado antes en ese paradero');
    }
    final set = _favoriteStopsByPassenger.putIfAbsent(passengerDni, () => <String>{});
    if (set.contains(stopName)) {
      set.remove(stopName);
    } else {
      set.add(stopName);
    }
    _recordEvent('favorite_stop_toggled', {'dni': passengerDni, 'stop': stopName});
    notifyListeners();
    return (ok: true, message: 'Favoritos actualizados');
  }

  final List<PassengerTripRecord> _tripHistory = [];
  List<PassengerTripRecord> tripHistoryOf(String passengerDni) {
    final items = _tripHistory.where((t) => t.passengerDni == passengerDni).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(20).toList();
  }

  PassengerTripRecord? activeTripOf(String passengerDni) {
    final items = _tripHistory.where((t) => t.passengerDni == passengerDni && t.status != 'Finalizado').toList();
    if (items.isEmpty) return null;
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.first;
  }

  PassengerTripRecord? latestFinalizedUnratedTrip(String passengerDni) {
    final items = _tripHistory
        .where((t) => t.passengerDni == passengerDni && t.status == 'Finalizado' && t.ratingStars == null)
        .toList();
    if (items.isEmpty) return null;
    items.sort((a, b) => (b.finishedAt ?? b.createdAt).compareTo(a.finishedAt ?? a.createdAt));
    return items.first;
  }

  List<TicketEntry> ticketsForTransaction(String transactionId) {
    final result = <TicketEntry>[];
    for (final t in _tickets) {
      final parts = t.code.split('|');
      if (parts.length >= 2 && parts.first == 'SDAG' && parts[1] == transactionId) {
        result.add(t);
      }
    }
    result.sort((a, b) => a.seat.compareTo(b.seat));
    return result;
  }

  final Map<String, List<int>> _fullSeatsByPlaca = {};
  final Map<String, DateTime> _filledAtByPlaca = {};
  bool trafficHeavy = false;
  final List<PunctualityRecord> _punctuality = [];
  List<PunctualityRecord> get punctuality => List.unmodifiable(_punctuality);

  void markVehicleFull({required String placa, required String driverDni}) {
    _filledAtByPlaca[placa] = DateTime.now();
    _recordEvent('vehicle_full', {'placa': placa, 'driver': driverDni});
    notifyListeners();
  }

  void markDeparture({required String placa, required String driverDni}) {
    final filledAt = _filledAtByPlaca[placa];
    if (filledAt == null) return;
    final departedAt = DateTime.now();
    _punctuality.add(
      PunctualityRecord(
        driverDni: driverDni,
        placa: placa,
        filledAt: filledAt,
        departedAt: departedAt,
        trafficHeavy: trafficHeavy,
      ),
    );
    if (_punctuality.length > 400) {
      _punctuality.removeRange(0, _punctuality.length - 400);
    }
    _recordEvent('departure_recorded', {'placa': placa, 'driver': driverDni, 'traffic': trafficHeavy});
    notifyListeners();
  }

  final List<FlaggedRatingEntry> _flaggedRatings = [];
  List<FlaggedRatingEntry> get flaggedRatings => List.unmodifiable(_flaggedRatings);
  void markFlaggedRatingReviewed({required String tripId}) {
    _flaggedRatings.removeWhere((r) => r.tripId == tripId);
    notifyListeners();
  }

  DriverRatingAggregate ratingForDriver(String driverDni) {
    final rated = _tripHistory.where((t) => t.driverDni == driverDni && t.ratingStars != null).toList();
    if (rated.isEmpty) return DriverRatingAggregate(driverDni: driverDni, average: 0, count: 0);
    final sum = rated.fold<int>(0, (acc, t) => acc + (t.ratingStars ?? 0));
    final avg = sum / rated.length;
    return DriverRatingAggregate(driverDni: driverDni, average: avg, count: rated.length);
  }

  ({bool ok, String message}) submitRating({
    required String tripId,
    required String passengerDni,
    required int stars,
    required String comment,
  }) {
    final idx = _tripHistory.indexWhere((t) => t.id == tripId && t.passengerDni == passengerDni);
    if (idx < 0) return (ok: false, message: 'Viaje no encontrado');
    if (stars < 1 || stars > 5) return (ok: false, message: 'Calificación inválida');
    final trip = _tripHistory[idx];
    final trimmed = comment.trim();
    final flagged = stars == 1 && trimmed.isEmpty;
    _tripHistory[idx] = trip.copyWith(ratingStars: stars, ratingComment: trimmed.isEmpty ? null : trimmed, ratingFlagged: flagged);
    if (flagged) {
      _flaggedRatings.add(
        FlaggedRatingEntry(
          tripId: tripId,
          driverDni: trip.driverDni,
          passengerDni: passengerDni,
          placa: trip.placa,
          stars: stars,
          comment: trimmed,
          at: DateTime.now(),
        ),
      );
    }
    _recordEvent('rating_submitted', {'trip': tripId, 'stars': stars, 'flagged': flagged});
    notifyListeners();
    return flagged ? (ok: true, message: 'Calificación enviada (en revisión)') : (ok: true, message: 'Calificación enviada');
  }

  final List<QuickChatMessage> _chat = [];
  List<QuickChatMessage> chatFor(String conversationId) {
    final items = _chat.where((m) => m.conversationId == conversationId).toList();
    items.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return items;
  }

  ({bool ok, String message}) sendQuickChat({
    required String conversationId,
    required String fromRole,
    required String fromDni,
    required String toDni,
    required String text,
  }) {
    final now = DateTime.now();
    final recent = _chat.where((m) => m.fromDni == fromDni && now.difference(m.sentAt) <= const Duration(minutes: 1)).toList();
    if (recent.length >= 5) {
      return (ok: false, message: 'Límite: 5 mensajes por minuto');
    }
    _chat.add(
      QuickChatMessage(
        conversationId: conversationId,
        fromRole: fromRole,
        fromDni: fromDni,
        toDni: toDni,
        text: text,
        sentAt: now,
        readAt: null,
      ),
    );
    if (_chat.length > 500) {
      _chat.removeRange(0, _chat.length - 500);
    }
    _recordEvent('chat_sent', {'from': fromDni, 'to': toDni});
    notifyListeners();
    return (ok: true, message: 'Mensaje enviado');
  }

  void markChatRead({required String conversationId, required String readerDni}) {
    var changed = false;
    for (var i = 0; i < _chat.length; i++) {
      final m = _chat[i];
      if (m.conversationId != conversationId) continue;
      if (m.toDni != readerDni) continue;
      if (m.readAt != null) continue;
      _chat[i] = m.copyWith(readAt: DateTime.now());
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  final List<NewsNotification> _news = [];
  List<NewsNotification> get news => List.unmodifiable(_news);
  final Map<String, Set<String>> _readNewsByDni = {};

  bool isNewsRead({required String dni, required String newsId}) => (_readNewsByDni[dni] ?? {}).contains(newsId);

  void markNewsRead({required String dni, required String newsId}) {
    final set = _readNewsByDni.putIfAbsent(dni, () => <String>{});
    if (set.contains(newsId)) return;
    set.add(newsId);
    notifyListeners();
  }

  NewsNotification createNews({
    required String createdByDni,
    required String title,
    required String body,
    required bool isEmergency,
  }) {
    final id = 'NEWS-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    final item = NewsNotification(
      id: id,
      title: title.trim().isEmpty ? 'Aviso' : title.trim(),
      body: body.trim(),
      isEmergency: isEmergency,
      createdAt: DateTime.now(),
      createdByDni: createdByDni,
    );
    _news.add(item);
    if (_news.length > 200) {
      _news.removeRange(0, _news.length - 200);
    }
    _recordEvent('news_created', {'id': id, 'emergency': isEmergency});
    notifyListeners();
    return item;
  }

  final Map<String, int> stopDemandCounts = {};
  final Map<String, Map<int, int>> stopDemandByHour = {};

  final List<DriverStop> driverStops = [
    DriverStop(
      passengerName: 'María Torres',
      stopName: 'Paradero Plaza',
      positionMeters: Offset(1500, 0),
      dni: '70123456',
    ),
    DriverStop(
      passengerName: 'José Ruiz',
      stopName: 'Paradero Mercado',
      positionMeters: Offset(3000, 400),
      dni: '70999888',
    ),
    DriverStop(
      passengerName: 'Lucía Ramos',
      stopName: 'Paradero Puente',
      positionMeters: Offset(4500, 900),
      dni: '71222333',
    ),
  ];

  final Map<String, List<int>> _seatsByPassengerDni = {};
  List<int> seatsForPassenger(String dni) => List.unmodifiable(_seatsByPassengerDni[dni] ?? const <int>[]);

  Offset? _positionForStopName(String stopName) {
    final match = driverStops.where((s) => s.stopName == stopName).toList();
    if (match.isNotEmpty) return match.first.positionMeters;
    return null;
  }

  void ensurePassengerStop({
    required String passengerDni,
    required String passengerName,
    required String stopName,
  }) {
    if (driverStops.any((s) => s.dni == passengerDni)) return;
    final pos = _positionForStopName(stopName) ?? passengerStopMeters;
    driverStops.add(
      DriverStop(
        passengerName: passengerName,
        stopName: stopName,
        positionMeters: pos,
        dni: passengerDni,
      ),
    );
    notifyListeners();
  }

  bool passengerGeofenceFired = false;
  final Set<String> driverStopGeofenceFired = {};

  void setOnline(bool online) {
    _isOnline = online;
    if (_isOnline) {
      _syncPending();
      _markPendingSupportFeedbackSent();
    }
    notifyListeners();
  }

  void _recordEvent(String type, Map<String, Object?> data) {
    final event = OfflineEvent(type: type, at: DateTime.now(), data: data);
    if (_isOnline) {
      _syncedEvents.add(event);
      if (_syncedEvents.length > 500) {
        _syncedEvents.removeRange(0, _syncedEvents.length - 500);
      }
      return;
    }
    _offlineQueue.add(event);
    if (_offlineQueue.length > 200) {
      _offlineQueue.removeRange(0, _offlineQueue.length - 200);
    }
  }

  void _syncPending() {
    if (_offlineQueue.isEmpty) return;
    _syncedEvents.addAll(_offlineQueue);
    if (_syncedEvents.length > 500) {
      _syncedEvents.removeRange(0, _syncedEvents.length - 500);
    }
    _offlineQueue.clear();
  }

  void startEmergencyStop({
    required String placa,
    required String driverDni,
    String note = 'Parada técnica',
  }) {
    if (_activeEmergencyStop != null && _activeEmergencyStop!.endedAt == null) return;
    final id = 'STOP-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    _activeEmergencyStop = EmergencyStopEntry(
      id: id,
      placa: placa,
      driverDni: driverDni,
      startedAt: DateTime.now(),
      startMeters: _vehicleMeters,
      endedAt: null,
      duration: null,
      note: note.trim(),
      longStopAlerted: false,
    );
    _recordEvent('emergency_stop_started', {'placa': placa, 'driver': driverDni});
    createNews(
      createdByDni: 'SISTEMA',
      title: 'Breve detención',
      body: 'El vehículo realizó una parada técnica. Gracias por su paciencia.',
      isEmergency: false,
    );
    notifyListeners();
  }

  void endEmergencyStop() {
    final current = _activeEmergencyStop;
    if (current == null) return;
    if (current.endedAt != null) return;
    final duration = DateTime.now().difference(current.startedAt);
    final finished = current.copyWith(endedAt: DateTime.now(), duration: duration);
    _emergencyStops.add(finished);
    if (_emergencyStops.length > 200) {
      _emergencyStops.removeRange(0, _emergencyStops.length - 200);
    }
    _activeEmergencyStop = null;
    _recordEvent('emergency_stop_ended', {'sec': duration.inSeconds});
    notifyListeners();
  }

  void finalizeRouteSession({required String placa, required String driverDni, double emptyKmMeters = 0}) {
    final day = _dayKey(DateTime.now());
    final keyDriver = '$day|$driverDni';
    final keyPlaca = '$day|$placa';
    _dailyKmByDriver[keyDriver] = (_dailyKmByDriver[keyDriver] ?? 0) + _routeDistanceMeters;
    _dailyKmByPlaca[keyPlaca] = (_dailyKmByPlaca[keyPlaca] ?? 0) + _routeDistanceMeters;
    _dailyKmEmptyMetersByPlaca[keyPlaca] = (_dailyKmEmptyMetersByPlaca[keyPlaca] ?? 0) + max(0, emptyKmMeters);
    _routeDistanceMeters = 0;
    notifyListeners();
  }

  void setDriverBlocked(String dni, bool blocked) {
    if (blocked) {
      blockedDriverDnis.add(dni);
    } else {
      blockedDriverDnis.remove(dni);
    }
    notifyListeners();
  }

  void activateEmergency({required String role, required String sourceDni}) {
    activeEmergency = EmergencyAlert(
      role: role,
      sourceDni: sourceDni,
      createdAt: DateTime.now(),
      vehicleMeters: _vehicleMeters,
    );
    notifyListeners();
  }

  void clearEmergency() {
    activeEmergency = null;
    notifyListeners();
  }

  void setDataSaverEnabled({required String driverDni, required bool enabled}) {
    _dataSaverByDriver[driverDni] = enabled;
    final nextTick = enabled ? 10.0 : 5.0;
    if (_tickSeconds != nextTick) {
      _tickSeconds = nextTick;
      _restartTimerIfRunning();
    }
    notifyListeners();
  }

  void setAlertTone({required String driverDni, required String tone}) {
    _alertToneByDriver[driverDni] = tone;
    notifyListeners();
  }

  void setVoiceProfile({required String driverDni, required String profile}) {
    _voiceProfileByDriver[driverDni] = profile;
    notifyListeners();
  }

  void setAutoNightMode({required String driverDni, required bool enabled}) {
    _autoNightModeByDriver[driverDni] = enabled;
    notifyListeners();
  }

  String createShareLink({required String passengerDni, Duration validFor = const Duration(hours: 1)}) {
    final baseLat = -12.0464;
    final baseLng = -77.0428;
    final lat = baseLat + (_vehicleMeters.dy / 900.0) * 0.05;
    final lng = baseLng + (_vehicleMeters.dx / 6000.0) * 0.05;
    final token = 'SH-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    final url = 'https://www.google.com/maps?q=$lat,$lng&z=15&sdg_token=$token';
    _shareLinksByPassenger[passengerDni] = (url: url, expiresAt: DateTime.now().add(validFor));
    _recordEvent('share_link_created', {'dni': passengerDni, 'expires_sec': validFor.inSeconds});
    notifyListeners();
    return url;
  }

  ({bool ok, String url, String message}) latestShareLink(String passengerDni) {
    final entry = _shareLinksByPassenger[passengerDni];
    if (entry == null) return (ok: false, url: '', message: 'No hay enlace activo');
    if (DateTime.now().isAfter(entry.expiresAt)) return (ok: false, url: '', message: 'Enlace expirado');
    return (ok: true, url: entry.url, message: 'Enlace listo');
  }

  SupportFeedbackEntry submitSupportFeedback({
    required String fromDni,
    required String fromRole,
    required String message,
    String deviceModel = 'Web',
    String appVersion = '1.0.0',
  }) {
    final id = 'SUP-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    final entry = SupportFeedbackEntry(
      id: id,
      fromDni: fromDni,
      fromRole: fromRole,
      message: message.trim(),
      deviceModel: deviceModel,
      appVersion: appVersion,
      at: DateTime.now(),
      sent: _isOnline,
    );
    _supportFeedback.add(entry);
    if (_supportFeedback.length > 200) {
      _supportFeedback.removeRange(0, _supportFeedback.length - 200);
    }
    _recordEvent('support_feedback', {'id': id, 'dni': fromDni});
    notifyListeners();
    return entry;
  }

  void _markPendingSupportFeedbackSent() {
    var changed = false;
    for (var i = 0; i < _supportFeedback.length; i += 1) {
      final e = _supportFeedback[i];
      if (e.sent) continue;
      _supportFeedback[i] = e.copyWith(sent: true);
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  String _monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

  bool shouldShowSurvey(String passengerDni) {
    final key = _monthKey(DateTime.now());
    return !_surveyResponses.any((r) => r.passengerDni == passengerDni && r.monthKey == key);
  }

  bool submitSurvey({
    required String passengerDni,
    required int q1,
    required int q2,
    required int q3,
  }) {
    final key = _monthKey(DateTime.now());
    if (_surveyResponses.any((r) => r.passengerDni == passengerDni && r.monthKey == key)) return false;
    _surveyResponses.add(
      SatisfactionSurveyResponse(
        passengerDni: passengerDni,
        monthKey: key,
        q1: q1,
        q2: q2,
        q3: q3,
        at: DateTime.now(),
      ),
    );
    if (_surveyResponses.length > 400) {
      _surveyResponses.removeRange(0, _surveyResponses.length - 400);
    }
    _recordEvent('survey_submitted', {'dni': passengerDni, 'month': key});
    notifyListeners();
    return true;
  }

  void _restartTimerIfRunning() {
    if (!_running) return;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: (_tickSeconds * 1000).round()), (_) {
      _tick();
    });
  }

  void setDeviationJustified(bool justified) {
    deviationJustified = justified;
    if (justified) {
      deviationMeters = 0;
      _deviationOver300Ticks = 0;
    }
    notifyListeners();
  }

  void releaseSeat(int seat) {
    if (occupiedSeats.contains(seat)) {
      occupiedSeats.remove(seat);
      releasedSeats.add(seat);
      notifyListeners();
    }
  }

  void restoreSeat(int seat) {
    if (releasedSeats.contains(seat)) {
      releasedSeats.remove(seat);
      occupiedSeats.add(seat);
      notifyListeners();
    }
  }

  void requestExpressDeparture({required int filledSeats, double farePerSeat = 10.0}) {
    if (filledSeats <= 0) return;
    expressPending = true;
    expressAuthorized = false;
    expressFarePerSeat = farePerSeat;
    expressFilledAtRequest = filledSeats;
    final empty = max(0, tripCapacity - filledSeats);
    expressEmptySeatsCost = empty * farePerSeat;
    expressExtraPerPassenger = filledSeats == 0 ? 0 : (expressEmptySeatsCost / filledSeats);
    _recordEvent('express_requested', {
      'filled': filledSeats,
      'capacity': tripCapacity,
      'empty_cost': expressEmptySeatsCost,
      'extra_per_passenger': expressExtraPerPassenger,
    });
    notifyListeners();
  }

  void cancelExpressDeparture({bool dueToDisagreement = false}) {
    if (!expressPending && !expressAuthorized) return;
    expressPending = false;
    expressAuthorized = false;
    _recordEvent('express_cancelled', {
      'disagreement': dueToDisagreement,
    });
    notifyListeners();
  }

  void confirmExpressDeparturePaid() {
    if (!expressPending) return;
    expressPending = false;
    expressAuthorized = true;
    unitStatus = 'En ruta';
    markDeparture(placa: _assignedVehicle.placa, driverDni: '22222222');
    _recordEvent('express_confirmed', {
      'empty_cost': expressEmptySeatsCost,
      'extra_per_passenger': expressExtraPerPassenger,
    });
    notifyListeners();
  }

  TicketEntry createTicket({
    required String ruta,
    required String destino,
    required String salida,
    required int seat,
    String? transactionId,
    String? passengerDni,
    String? placa,
  }) {
    final stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final tx = transactionId ?? '-';
    final dni = passengerDni ?? '-';
    final plate = placa ?? _assignedVehicle.placa;
    final code = 'SDAG|$tx|$dni|$plate|$ruta|$destino|$salida|$seat|$stamp';
    final ticket = TicketEntry(
      code: code,
      ruta: ruta,
      destino: destino,
      salida: salida,
      seat: seat,
      createdAt: DateTime.now(),
    );
    _tickets.add(ticket);
    if (_tickets.length > 100) {
      _tickets.removeRange(0, _tickets.length - 100);
    }
    _recordEvent('ticket_created', {
      'seat': seat,
      'ruta': ruta,
      'destino': destino,
      'salida': salida,
    });
    notifyListeners();
    return ticket;
  }

  ({String transactionId, List<TicketEntry> tickets, PassengerTripRecord tripRecord}) confirmPassengerBooking({
    required String passengerDni,
    required String stopName,
    required String ruta,
    required String destino,
    required String salida,
    required List<int> seats,
    required double farePerSeat,
    required String driverDni,
  }) {
    final cleanSeats = seats.toSet().toList()..sort();
    final txId = 'TX-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
    final total = farePerSeat * cleanSeats.length;
    _seatsByPassengerDni[passengerDni] = cleanSeats;
    final passengerName = profileOf(passengerDni).displayName;
    ensurePassengerStop(passengerDni: passengerDni, passengerName: passengerName, stopName: stopName);
    for (final s in cleanSeats) {
      releasedSeats.remove(s);
      occupiedSeats.add(s);
    }
    _fullSeatsByPlaca[_assignedVehicle.placa] = cleanSeats;

    final createdTickets = <TicketEntry>[];
    for (final seat in cleanSeats) {
      createdTickets.add(
        createTicket(
          ruta: ruta,
          destino: destino,
          salida: salida,
          seat: seat,
          transactionId: txId,
          passengerDni: passengerDni,
          placa: _assignedVehicle.placa,
        ),
      );
    }

    final record = PassengerTripRecord(
      id: txId,
      passengerDni: passengerDni,
      driverDni: driverDni,
      stopName: stopName,
      ruta: ruta,
      destino: destino,
      salida: salida,
      seats: cleanSeats,
      farePerSeat: farePerSeat,
      totalCost: total,
      placa: _assignedVehicle.placa,
      vehicleModel: _assignedVehicle.model,
      vehicleColor: _assignedVehicle.colorName,
      createdAt: DateTime.now(),
      status: 'Pendiente',
      finishedAt: null,
      ratingStars: null,
      ratingComment: null,
      ratingFlagged: false,
    );
    _tripHistory.add(record);
    if (_tripHistory.length > 500) {
      _tripHistory.removeRange(0, _tripHistory.length - 500);
    }
    lastPaymentAt = DateTime.now();
    lastPaymentAmount = total;
    lastPaymentTxId = txId;
    _recordEvent('booking_confirmed', {'tx': txId, 'dni': passengerDni, 'seats': cleanSeats.length});
    notifyListeners();
    return (transactionId: txId, tickets: createdTickets, tripRecord: record);
  }

  void finalizeTripsForPlaca({required String placa}) {
    var changed = false;
    for (var i = 0; i < _tripHistory.length; i++) {
      final t = _tripHistory[i];
      if (t.placa != placa) continue;
      if (t.status == 'Finalizado') continue;
      _tripHistory[i] = t.copyWith(status: 'Finalizado', finishedAt: DateTime.now());
      changed = true;
    }
    if (changed) {
      _recordEvent('trips_finalized', {'placa': placa});
      notifyListeners();
    }
  }

  ({bool ok, String message, TicketEntry? ticket}) validateTicket(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return (ok: false, message: 'Código vacío', ticket: null);
    final match = _tickets.where((t) => t.code == trimmed).toList();
    if (match.isEmpty) return (ok: false, message: 'QR inválido', ticket: null);
    if (_usedTicketCodes.contains(trimmed)) return (ok: false, message: 'QR ya fue usado', ticket: match.first);
    _usedTicketCodes.add(trimmed);
    _recordEvent('ticket_validated', {'code': trimmed});
    notifyListeners();
    return (ok: true, message: 'Abordaje verificado', ticket: match.first);
  }

  void recordStopBoarding({required String stopName}) {
    stopDemandCounts[stopName] = (stopDemandCounts[stopName] ?? 0) + 1;
    final hour = DateTime.now().hour;
    stopDemandByHour.putIfAbsent(stopName, () => {});
    stopDemandByHour[stopName]![hour] = (stopDemandByHour[stopName]![hour] ?? 0) + 1;
    _recordEvent('stop_boarding', {'stop': stopName, 'hour': hour});
    notifyListeners();
  }

  void arriveAtBase({required String driverDni}) {
    baseQueueDriverDnis.remove(driverDni);
    baseQueueDriverDnis.add(driverDni);
    _recordEvent('base_arrival', {'driver': driverDni, 'pos': baseQueueDriverDnis.length});
    notifyListeners();
  }

  void leaveBase({required String driverDni}) {
    baseQueueDriverDnis.remove(driverDni);
    _recordEvent('base_leave', {'driver': driverDni});
    notifyListeners();
  }

  int queuePosition({required String driverDni}) {
    final idx = baseQueueDriverDnis.indexOf(driverDni);
    return idx < 0 ? -1 : idx + 1;
  }

  void addExpense({
    required double amount,
    required String motive,
    required bool hasVoucher,
    required String placa,
    required String driverDni,
  }) {
    final entry = ExpenseEntry(
      amount: amount,
      motive: motive,
      hasVoucher: hasVoucher,
      at: DateTime.now(),
      vehicleMeters: _vehicleMeters,
      placa: placa,
      driverDni: driverDni,
    );
    _expenses.add(entry);
    if (_expenses.length > 300) {
      _expenses.removeRange(0, _expenses.length - 300);
    }
    _recordEvent('expense_added', {
      'amount': amount,
      'motive': motive,
      'voucher': hasVoucher,
      'placa': placa,
      'driver': driverDni,
    });
    notifyListeners();
  }

  void addIncident({
    required String kind,
    required String description,
    required String placa,
    required String driverDni,
  }) {
    final now = DateTime.now();
    if (_incidents.isNotEmpty) {
      final last = _incidents.last;
      final withinTime = now.difference(last.at).inMinutes <= 2;
      final withinDist = distanceMeters(last.vehicleMeters, _vehicleMeters) <= 50;
      final sameKind = last.kind == kind;
      if (withinTime && withinDist && sameKind) {
        _incidents.removeLast();
        _incidents.add(
          IncidentEntry(
            kind: last.kind,
            description: last.description,
            at: now,
            vehicleMeters: last.vehicleMeters,
            placa: last.placa,
            driverDni: last.driverDni,
            count: last.count + 1,
          ),
        );
        _recordEvent('incident_grouped', {'kind': kind, 'placa': placa, 'count': last.count + 1});
        notifyListeners();
        return;
      }
    }

    _incidents.add(
      IncidentEntry(
        kind: kind,
        description: description,
        at: now,
        vehicleMeters: _vehicleMeters,
        placa: placa,
        driverDni: driverDni,
        count: 1,
      ),
    );
    if (_incidents.length > 300) {
      _incidents.removeRange(0, _incidents.length - 300);
    }
    _recordEvent('incident_added', {'kind': kind, 'placa': placa});
    notifyListeners();
  }

  List<DocumentEntry> expiringDocuments({int withinHours = 48}) {
    final now = DateTime.now();
    final limit = now.add(Duration(hours: withinHours));
    return _documents.where((d) => d.expiresAt.isBefore(limit)).toList();
  }

  void updateDocumentExpiry({required String placa, required String docType, required DateTime expiresAt}) {
    final idx = _documents.indexWhere((d) => d.placa == placa && d.docType == docType);
    if (idx >= 0) {
      _documents[idx] = DocumentEntry(placa: placa, docType: docType, expiresAt: expiresAt);
    } else {
      _documents.add(DocumentEntry(placa: placa, docType: docType, expiresAt: expiresAt));
    }
    _recordEvent('doc_updated', {'placa': placa, 'doc': docType});
    notifyListeners();
  }

  void resetTrip() {
    stop();
    _pathIndex = 0;
    _vehicleMeters = _pathMeters.first;
    _gpsLogMeters
      ..clear()
      ..add(_vehicleMeters);
    passengerGeofenceFired = false;
    driverStopGeofenceFired.clear();
    _lastSpeedKmh = 0;
    _highSpeedTicks = 0;
    _deviationOver300Ticks = 0;
    deviationMeters = 0;
    expressAuthorized = false;
    expressPending = false;
    expressExtraPerPassenger = 0;
    expressEmptySeatsCost = 0;
    expressFilledAtRequest = 0;
    unitStatus = 'Carga';
    arrivedAtFinalStop = false;
    arrivedAtFinalStopAt = null;
    autoClosed = false;
    _routeDistanceMeters = 0;
    _activeEmergencyStop = null;
    _lastMovedAt = DateTime.now();
    notifyListeners();
  }

  void start() {
    if (_running) return;
    if (_gpsLogMeters.isEmpty) {
      _gpsLogMeters.add(_vehicleMeters);
    }
    _running = true;
    _timer = Timer.periodic(Duration(milliseconds: (_tickSeconds * 1000).round()), (_) {
      _tick();
    });
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    notifyListeners();
  }

  double distanceMeters(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;
    return sqrt(dx * dx + dy * dy);
  }

  Duration etaTo(Offset targetMeters) {
    final dist = distanceMeters(_vehicleMeters, targetMeters);
    final seconds = (dist / _speedMetersPerSecond).ceil();
    final base = Duration(seconds: max(0, seconds));
    if (isEmergencyStopActive) {
      return base + emergencyStopElapsed;
    }
    return base;
  }

  void _tick() {
    if (!_running) return;
    if (_pathIndex >= _pathMeters.length - 1) {
      stop();
      return;
    }

    if (isEmergencyStopActive) {
      _lastSpeedKmh = 0;
      final current = _activeEmergencyStop!;
      if (!current.longStopAlerted && emergencyStopElapsed >= const Duration(minutes: 15)) {
        _activeEmergencyStop = current.copyWith(longStopAlerted: true);
        addIncident(
          kind: 'Parada larga',
          description: 'Detenido > 15 min sin completar parada técnica',
          placa: current.placa,
          driverDni: current.driverDni,
        );
        createNews(
          createdByDni: 'SISTEMA',
          title: 'Demora en ruta',
          body: 'El vehículo presenta una detención prolongada. Estamos verificando.',
          isEmergency: true,
        );
      }
      _weather = _computeWeather();
      notifyListeners();
      return;
    }

    final from = _vehicleMeters;
    final to = _pathMeters[_pathIndex + 1];
    final dist = distanceMeters(from, to);
    if (dist <= 0.001) {
      _pathIndex += 1;
      notifyListeners();
      return;
    }

    final step = _speedMetersPerSecond * _tickSeconds;
    final t = min(1.0, step / dist);
    var next = Offset(
      from.dx + (to.dx - from.dx) * t,
      from.dy + (to.dy - from.dy) * t,
    );

    if (distanceMeters(next, from) >= 0.5) {
      _lastMovedAt = DateTime.now();
    }

    final moved = distanceMeters(next, from);
    _lastSpeedKmh = (moved / _tickSeconds) * 3.6;
    if (moved <= (_speedMetersPerSecond * _tickSeconds * 2.2)) {
      _routeDistanceMeters += moved;
    }
    if (_lastSpeedKmh > 90) {
      _highSpeedTicks += 1;
      if (_highSpeedTicks >= 3) {
        _speedInfractions.add(
          SpeedInfraction(kmh: _lastSpeedKmh, at: DateTime.now(), vehicleMeters: next),
        );
        if (_speedInfractions.length > 50) {
          _speedInfractions.removeRange(0, _speedInfractions.length - 50);
        }
        _highSpeedTicks = 0;
      }
    } else {
      _highSpeedTicks = 0;
    }

    if (simulateDeviation && !deviationJustified) {
      deviationMeters = 350;
      next = Offset(next.dx, next.dy + deviationMeters);
      if (deviationMeters > 300) {
        _deviationOver300Ticks += 1;
        if (_deviationOver300Ticks >= 3) {
          deviationInfractions += 1;
          _deviationOver300Ticks = 0;
        }
      }
    } else {
      deviationMeters = 0;
      _deviationOver300Ticks = 0;
    }

    _vehicleMeters = next;
    _gpsLogMeters.add(_vehicleMeters);
    if (_gpsLogMeters.length > 300) {
      _gpsLogMeters.removeRange(0, _gpsLogMeters.length - 300);
    }

    if (distanceMeters(_vehicleMeters, passengerStopMeters) <= 500) {
      passengerGeofenceFired = true;
    }

    for (final s in driverStops) {
      if (distanceMeters(_vehicleMeters, s.positionMeters) <= 500) {
        driverStopGeofenceFired.add(s.dni);
      }
    }

    if (!arrivedAtFinalStop && distanceMeters(_vehicleMeters, finalStopMeters) <= 120) {
      arrivedAtFinalStop = true;
      arrivedAtFinalStopAt = DateTime.now();
      _recordEvent('final_stop_reached', {});
    }
    if (arrivedAtFinalStop && !autoClosed) {
      final reachedAt = arrivedAtFinalStopAt;
      if (reachedAt != null && DateTime.now().difference(reachedAt) >= const Duration(minutes: 10)) {
        autoClosed = true;
        unitStatus = 'Disponible';
        stop();
        finalizeTripsForPlaca(placa: _assignedVehicle.placa);
        finalizeRouteSession(placa: _assignedVehicle.placa, driverDni: '22222222');
        _recordEvent('trip_autoclosed', {});
      }
    }

    if (t >= 1.0) {
      _pathIndex += 1;
    }

    _weather = _computeWeather();
    notifyListeners();
  }

  WeatherInfo _computeWeather() {
    final now = DateTime.now();
    final seed = (_vehicleMeters.dx.round() * 31) + (_vehicleMeters.dy.round() * 17) + (now.hour * 13);
    final rng = Random(seed);
    final conditions = ['Soleado', 'Nublado', 'Lluvia', 'Neblina'];
    final condition = conditions[rng.nextInt(conditions.length)];
    final base = now.month >= 6 && now.month <= 9 ? 16 : 19;
    final temp = base + rng.nextInt(10);
    return WeatherInfo(condition: condition, temperatureC: temp, updatedAt: now);
  }
}
