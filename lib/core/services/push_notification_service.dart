import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'push_notification_utils.dart';

/// Notificaciones push (FCM) + locales + brokers Realtime complementarios.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _initialized = false;
  bool _fcmConfigured = false;
  int _notificationId = 0;

  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _reservationsSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<String>? _tokenRefreshSub;

  String? _activeProfileId;
  bool _messagesStreamPrimed = false;
  final Set<String> _seenMessageIds = {};
  final Set<String> _seenCancelledReservationIds = {};

  bool get isInitialized => _initialized;

  Future<bool> initialize({bool configureFcm = true}) async {
    if (_initialized) return true;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (_) {},
    );

    if (!kIsWeb) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _local
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;

    if (configureFcm && !kIsWeb) {
      await _configureFirebaseMessaging();
    }

    debugPrint('[Push] Servicio de notificaciones inicializado');
    return true;
  }

  Future<void> _configureFirebaseMessaging() async {
    if (_fcmConfigured) return;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    _foregroundSub = FirebaseMessaging.onMessage.listen(handleRemoteMessage);
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
      unawaited(_persistFcmToken(token));
    });

    _fcmConfigured = true;
    await syncFcmTokenToProfile();
  }

  /// Registra el token FCM del dispositivo en `profiles.fcm_token`.
  Future<void> syncFcmTokenToProfile() async {
    if (kIsWeb || !_fcmConfigured) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token == null || token.trim().isEmpty) return;
      await _persistFcmToken(token.trim());
    } catch (e) {
      debugPrint('[Push/FCM] No se pudo sincronizar token: $e');
    }
  }

  Future<void> _persistFcmToken(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
      debugPrint('[Push/FCM] Token registrado en Supabase');
    } catch (e) {
      debugPrint('[Push/FCM] Error guardando token: $e');
    }
  }

  Future<void> clearFcmTokenFromProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': null})
          .eq('id', user.id);
    } catch (_) {}
  }

  /// Procesa payloads FCM remotos (foreground, background o app cerrada).
  Future<void> handleRemoteMessage(RemoteMessage message) async {
    final data = message.data;
    final notification = message.notification;

    var title = (notification?.title ?? data['title'] ?? '').trim();
    var body = (notification?.body ?? data['body'] ?? '').trim();

    if (title.isEmpty) {
      final mapped = _mapPayloadToCopy(data);
      title = mapped.$1;
      body = mapped.$2;
    }

    if (title.isEmpty) return;

    await showLocal(
      title: title,
      body: body.isNotEmpty ? body : title,
    );
  }

  (String title, String body) _mapPayloadToCopy(Map<String, dynamic> data) {
    final type = (data['type'] ?? data['event'] ?? '').toString().trim().toLowerCase();
    return (tituloNotificacionFcm(type), cuerpoNotificacionFcm(type));
  }

  Future<void> startSupabaseBrokers({
    required String role,
    String? tripId,
    String? profileId,
  }) async {
    await stopSupabaseBrokers();

    _activeProfileId = profileId;
    _messagesStreamPrimed = false;
    _seenMessageIds.clear();

    if (tripId == null || tripId.isEmpty) return;

    _messagesSub = Supabase.instance.client
        .from('trip_messages')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .listen(_onTripMessagesStream);

    if (role == 'driver' && profileId != null) {
      _reservationsSub = Supabase.instance.client
          .from('reservations')
          .stream(primaryKey: ['id'])
          .eq('trip_id', tripId)
          .listen(_onReservationsStream);
    }
  }

  Future<void> stopSupabaseBrokers() async {
    await _messagesSub?.cancel();
    await _reservationsSub?.cancel();
    _messagesSub = null;
    _reservationsSub = null;
    _activeProfileId = null;
    _messagesStreamPrimed = false;
    _seenMessageIds.clear();
  }

  void _onTripMessagesStream(List<Map<String, dynamic>> rows) {
    final profileId = _activeProfileId;
    if (profileId == null || profileId.isEmpty) return;

    if (!_messagesStreamPrimed) {
      for (final row in rows) {
        final id = row['id']?.toString();
        if (id != null && id.isNotEmpty) {
          _seenMessageIds.add(id);
        }
      }
      _messagesStreamPrimed = true;
      return;
    }

    for (final row in rows) {
      final id = row['id']?.toString();
      if (id == null || id.isEmpty || _seenMessageIds.contains(id)) continue;
      _seenMessageIds.add(id);

      final passengerId = row['passenger_id']?.toString();
      final senderId =
          row['sender_id']?.toString() ?? row['sender_profile_id']?.toString();

      final involvesUser = passengerId == profileId || senderId == profileId;
      if (!involvesUser || senderId == profileId) continue;

      unawaited(
        showLocal(
          title: 'Nuevo mensaje',
          body: 'Nuevo mensaje en el chat del viaje',
        ),
      );
    }
  }

  void _onReservationsStream(List<Map<String, dynamic>> rows) {
    for (final row in rows) {
      final id = row['id']?.toString();
      if (id == null || id.isEmpty) continue;
      if (row['status']?.toString() != 'cancelada') continue;
      if (_seenCancelledReservationIds.contains(id)) continue;
      _seenCancelledReservationIds.add(id);
      notifyReservationCancelled(passengerName: 'Un pasajero');
    }
  }

  Future<void> showLocal({
    required String title,
    required String body,
    int? id,
  }) async {
    if (!_initialized) {
      debugPrint('[Push/local] $title — $body');
      return;
    }

    final notifId = id ?? ++_notificationId;
    const androidDetails = AndroidNotificationDetails(
      'sdag_events',
      'Eventos SDAG',
      channelDescription: 'Alertas de viaje, reservas y mensajes',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _local.show(notifId, title, body, details);
    debugPrint('[Push/local] $title — $body');
  }

  void notifyInApp({required String title, required String body}) {
    unawaited(showLocal(title: title, body: body));
  }

  void notifyDriverArriving({required String passengerName}) {
    notifyInApp(
      title: 'Conductor cerca',
      body: '$passengerName, el conductor ya está llegando a tu punto de recojo.',
    );
  }

  void notifyVehicleFull() {
    notifyInApp(
      title: 'Vehículo lleno',
      body: 'Todos los asientos están ocupados. El temporizador de salida ha comenzado.',
    );
  }

  void notifyReservationCancelled({required String passengerName}) {
    notifyInApp(
      title: 'Reserva cancelada',
      body: '$passengerName canceló su reserva.',
    );
  }

  void notifyAdminPayoutRequest({required String driverName}) {
    notifyInApp(
      title: 'Solicitud de pago',
      body: '$driverName solicitó el pago de comisión.',
    );
  }

  void notifyDriverBlocked() {
    notifyInApp(
      title: 'Cuenta bloqueada',
      body: 'Tu acceso operativo está suspendido. Contacta al administrador.',
    );
  }

  void notifyForcedDepartureAuthorized({required int votos, required int total}) {
    notifyInApp(
      title: 'Salida anticipada autorizada',
      body: 'Se alcanzó el 50% de votos ($votos/$total). El viaje ha iniciado.',
    );
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _tokenRefreshSub?.cancel();
    await stopSupabaseBrokers();
    _foregroundSub = null;
    _tokenRefreshSub = null;
  }
}
