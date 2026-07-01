import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Configuración Firebase generada desde `android/app/google-services.json`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase no está configurado para Web en este build.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase no está configurado para ${defaultTargetPlatform.name}.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBKz6odQOc4VTcX1Erxa1n4qvBUEt2-YiE',
    appId: '1:292669211956:android:cbd153c8fbaa6644f81161',
    messagingSenderId: '292669211956',
    projectId: 'sdag-transport',
    storageBucket: 'sdag-transport.firebasestorage.app',
  );

  /// Placeholder iOS — reemplazar tras registrar la app en Firebase Console.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBKz6odQOc4VTcX1Erxa1n4qvBUEt2-YiE',
    appId: '1:292669211956:ios:0000000000000000000000',
    messagingSenderId: '292669211956',
    projectId: 'sdag-transport',
    storageBucket: 'sdag-transport.firebasestorage.app',
    iosBundleId: 'SDAG.transport',
  );
}
