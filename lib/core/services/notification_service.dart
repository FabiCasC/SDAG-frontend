import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Escuchar notificaciones en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Notificacion recibida: ${message.notification?.title}');
    });
  }

  // Llamar cuando ETA < 2 minutos
  Future<void> sendEtaAlert({required String token, required String stopName}) async {
    debugPrint('ETA alert enviada a $token para paradero $stopName');
  }

  // Llamar cuando hay una incidencia
  Future<void> sendIncidentAlert({required String token, required String mensaje}) async {
    debugPrint('Incidencia alert enviada: $mensaje');
  }
}