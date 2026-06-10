import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:async';

import '../../roles/passenger/passenger_shell_screen.dart';
import '../../roles/passenger/screens/profile/payment_methods_screen.dart';
import '../../features/busqueda/screens/busqueda_screen.dart';
import '../../features/busqueda/screens/conductor_detalle_screen.dart';
import '../../features/reserva/screens/seat_map_screen.dart';
import '../../features/reserva/screens/acompanantes_screen.dart';
import '../../features/reserva/screens/pickup_reserva_screen.dart';
import '../../features/reserva/screens/reserva_resumen_screen.dart';
import '../../features/reserva/screens/pago_screen.dart';
import '../../features/reserva/screens/confirmacion_screen.dart';
import '../../features/reserva/screens/reembolso_screen.dart';
import '../../features/viaje/screens/reserva_activa_screen.dart';
import '../../features/reserva/screens/forzar_salida_screen.dart';
import '../../features/reserva/screens/cancelar_reserva_screen.dart';
import '../../features/viaje/screens/mapa_viaje_screen.dart';
import '../../features/viaje/screens/chat_screen.dart';
import '../../features/viaje/screens/calificacion_screen.dart';
import '../../features/viaje/screens/viaje_detalle_screen.dart';
import '../../features/viaje/screens/qr_screen.dart';
import '../../features/noticias/screens/noticia_detalle_screen.dart';
import '../../features/reservations/screens/reserva_detalle_screen.dart';
import '../../features/conductor/screens/conductor_bloqueado_screen.dart';
import '../../features/conductor/screens/conductor_forgot_password_screen.dart';
import '../../features/conductor/screens/conductor_home_screen.dart';
import '../../features/conductor/screens/conductor_chat_grupal_screen.dart';
import '../../features/conductor/screens/conductor_chat_screen.dart';
import '../../features/conductor/screens/conductor_historial_screen.dart';
import '../../features/conductor/screens/conductor_manifiesto_screen.dart';
import '../../features/conductor/screens/conductor_mapa_screen.dart';
import '../../features/conductor/screens/conductor_noticias_screen.dart';
import '../../features/conductor/screens/conductor_qr_scanner_screen.dart';
import '../../features/conductor/screens/nueva_noticia_screen.dart';
import '../../features/admin/screens/admin_analitica_screen.dart';
import '../../features/admin/screens/admin_calificaciones_screen.dart';
import '../../features/admin/screens/admin_conductor_crear_screen.dart';
import '../../features/admin/screens/admin_conductor_detalle_screen.dart';
import '../../features/admin/screens/admin_conductor_editar_screen.dart';
import '../../features/admin/screens/admin_conductores_screen.dart';
import '../../features/admin/screens/admin_configuracion_screen.dart';
import '../../features/admin/screens/admin_vehiculo_crear_screen.dart';
import '../../features/admin/screens/admin_vehiculos_screen.dart';
import '../../features/admin/screens/admin_historial_viajes_screen.dart';
import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/admin/screens/admin_bloqueado_screen.dart';
import '../../features/admin/screens/admin_forgot_password_screen.dart';
import '../../features/admin/screens/admin_manifiestos_screen.dart';
import '../../features/admin/screens/admin_monitoreo_screen.dart';
import '../../features/admin/screens/admin_pagos_screen.dart';
import '../../features/admin/screens/admin_perfil_screen.dart';
import '../../features/admin/screens/admin_viaje_detalle_screen.dart';
import '../../features/admin/screens/admin_chat_grupal_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/splash_screen.dart';
import 'app_routes.dart';
import '../../data/models/app_role.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier();
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.passengerHome,
        builder: (context, state) =>
            PassengerShellScreen(initialRoute: state.uri.path),
      ),
      GoRoute(
        path: AppRoutes.passengerTrips,
        builder: (context, state) =>
            PassengerShellScreen(initialRoute: state.uri.path),
      ),
      GoRoute(
        path: AppRoutes.passengerNews,
        builder: (context, state) =>
            PassengerShellScreen(initialRoute: state.uri.path),
      ),
      GoRoute(
        path: AppRoutes.passengerProfile,
        builder: (context, state) =>
            PassengerShellScreen(initialRoute: state.uri.path),
      ),
      GoRoute(
        path: AppRoutes.passengerPaymentMethods,
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: AppRoutes.passengerSearch,
        builder: (context, state) => BusquedaScreen(
          initialDirection: state.uri.queryParameters['direction'],
        ),
      ),
      GoRoute(
        path: AppRoutes.passengerDriverDetail,
        builder: (context, state) => ConductorDetalleScreen(
          driverId: state.uri.queryParameters['id'],
          tripId: state.uri.queryParameters['tripId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.passengerSeatMap,
        builder: (context, state) => SeatMapScreen(
          driverId: state.uri.queryParameters['id'],
          tripId: state.uri.queryParameters['tripId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.passengerReservaAcompanantes,
        builder: (context, state) => const AcompanantesScreen(),
      ),
      GoRoute(
        path: AppRoutes.passengerReservaPickup,
        builder: (context, state) => const PickupReservaScreen(),
      ),
      GoRoute(
        path: AppRoutes.passengerReservaResumen,
        builder: (context, state) => const ReservaResumenScreen(),
      ),
      GoRoute(
        path: AppRoutes.passengerPago,
        builder: (context, state) => const PagoScreen(),
      ),
      GoRoute(
        path: AppRoutes.passengerConfirmacion,
        builder: (context, state) => const ConfirmacionScreen(),
      ),
      GoRoute(
        path: AppRoutes.passengerReservaActiva,
        builder: (context, state) => const ReservaActivaScreen(),
      ),
      GoRoute(
        path: AppRoutes.passengerForzarSalida,
        builder: (context, state) => const ForzarSalidaScreen(),
      ),
      GoRoute(
        path: AppRoutes.passengerCancelarReserva,
        builder: (context, state) => const CancelarReservaScreen(),
      ),
      GoRoute(
        path: AppRoutes.passengerReembolso,
        builder: (context, state) => ReembolsoScreen(
          amount: double.tryParse(state.uri.queryParameters['amount'] ?? '') ?? 0.0,
        ),
      ),
      GoRoute(
        path: AppRoutes.passengerMapaViaje,
        builder: (context, state) => const MapaViajeScreen(),
      ),
      GoRoute(
        path: AppRoutes.passengerChat,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.passengerCalificacion,
        builder: (context, state) => const CalificacionScreen(),
      ),
      GoRoute(
        path: AppRoutes.passengerTripDetail,
        builder: (context, state) => ViajeDetalleScreen(
          tripId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: AppRoutes.passengerQr,
        builder: (context, state) => QrScreen(
          tripId: state.uri.queryParameters['tripId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.passengerNewsDetail,
        builder: (context, state) => NoticiaDetalleScreen(
          newsId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: AppRoutes.passengerReservationDetail,
        builder: (context, state) => const ReservaDetalleScreen(),
      ),
      GoRoute(
        path: AppRoutes.driverHome,
        builder: (context, state) => ConductorHomeScreen(initialRoute: state.uri.path),
      ),
      GoRoute(
        path: AppRoutes.driverLogin,
        redirect: (context, state) => AppRoutes.login,
      ),
      GoRoute(
        path: AppRoutes.driverForgotPassword,
        builder: (context, state) => const ConductorForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.driverBlocked,
        builder: (context, state) => const ConductorBloqueadoScreen(),
      ),
      GoRoute(
        path: AppRoutes.driverGestionViaje,
        builder: (context, state) => ConductorHomeScreen(initialRoute: state.uri.path),
      ),
      GoRoute(
        path: AppRoutes.driverMapa,
        builder: (context, state) => const ConductorMapaScreen(),
      ),
      GoRoute(
        path: AppRoutes.driverPasajeros,
        builder: (context, state) => const Scaffold(body: Center(child: Text('Pasajeros'))),
      ),
      GoRoute(
        path: AppRoutes.driverQrScanner,
        builder: (context, state) => const ConductorQrScannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.driverManifiesto,
        builder: (context, state) => const ConductorManifiestoScreen(),
      ),
      GoRoute(
        path: AppRoutes.driverChat,
        builder: (context, state) => ConductorChatScreen(
          pasajeroId: state.pathParameters['pasajeroId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.driverChatGrupal,
        builder: (context, state) => const ConductorChatGrupalScreen(),
      ),
      GoRoute(
        path: AppRoutes.driverComisiones,
        builder: (context, state) => ConductorHomeScreen(initialRoute: state.uri.path),
      ),
      GoRoute(
        path: AppRoutes.driverHistorial,
        builder: (context, state) => const ConductorHistorialScreen(),
      ),
      GoRoute(
        path: AppRoutes.driverNoticias,
        builder: (context, state) => const ConductorNoticiasScreen(),
      ),
      GoRoute(
        path: AppRoutes.driverNoticiasNueva,
        builder: (context, state) => const NuevaNoticiaScreen(),
      ),
      GoRoute(
        path: AppRoutes.driverNoticiasDetalle,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return NoticiaDetalleScreen(newsId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.driverProfile,
        builder: (context, state) => ConductorHomeScreen(initialRoute: state.uri.path),
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminLogin,
        redirect: (context, state) => AppRoutes.login,
      ),
      GoRoute(
        path: AppRoutes.adminForgotPassword,
        builder: (context, state) => const AdminForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminBloqueado,
        builder: (context, state) => const AdminBloqueadoScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminConductores,
        builder: (context, state) => const AdminConductoresScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminConductoresNuevo,
        builder: (context, state) => const AdminConductorCrearScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminConductoresDetalle,
        builder: (context, state) => AdminConductorDetalleScreen(
          id: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.adminConductoresEditar,
        builder: (context, state) => AdminConductorEditarScreen(
          id: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.adminConductoresHistorial,
        builder: (context, state) => AdminHistorialViajesScreen(
          conductorId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: AppRoutes.adminVehiculos,
        builder: (context, state) => const AdminVehiculosScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminVehiculosNuevo,
        builder: (context, state) => const AdminVehiculoCrearScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPagos,
        builder: (context, state) => const AdminPagosScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPagosHistorial,
        builder: (context, state) => const AdminPagosHistorialScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminMonitoreo,
        builder: (context, state) => const AdminMonitoreoScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminManifiestos,
        builder: (context, state) => const AdminManifiestosScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminManifiestosDetalle,
        builder: (context, state) => AdminManifiestoDetalleScreen(
          viajeId: state.pathParameters['viajeId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.adminAnalitica,
        builder: (context, state) => const AdminAnaliticaScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCalificaciones,
        builder: (context, state) => const AdminCalificacionesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminHistorialViajes,
        builder: (context, state) => const AdminHistorialViajesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminViajeDetalle,
        builder: (context, state) => AdminViajeDetalleScreen(
          viajeId: state.pathParameters['viajeId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.adminConfiguracion,
        builder: (context, state) => const AdminConfiguracionScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPerfil,
        builder: (context, state) => const AdminPerfilScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminChatGrupal,
        builder: (context, state) => const AdminChatGrupalScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminFleet,
        redirect: (context, state) => AppRoutes.adminConductores,
      ),
      GoRoute(
        path: AppRoutes.adminSettings,
        redirect: (context, state) => AppRoutes.adminConfiguracion,
      ),
    ],
    redirect: (context, state) {
      final location = state.uri.path;

      if (location == '/reset-password') return null;

      final isPassengerArea = location.startsWith('/passenger');
      final isDriverArea = location.startsWith('/conductor');
      final isAdminArea = location.startsWith('/admin');

      final hasSupabaseSession = Supabase.instance.client.auth.currentSession != null;
      final role = refresh.role;
      final isRoleLoading = refresh.isRoleLoading;

      final isAuthRoute = location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.forgotPassword ||
          location == '/reset-password' ||
          location == AppRoutes.driverLogin ||
          location == AppRoutes.driverForgotPassword ||
          location == AppRoutes.adminLogin ||
          location == AppRoutes.adminForgotPassword;

      if (location == AppRoutes.splash) {
        if (!hasSupabaseSession) return AppRoutes.login;
        if (isRoleLoading || role == null) return null;
        return _homeForRole(role);
      }

      if (!hasSupabaseSession) {
        if (isAuthRoute) return null;
        return AppRoutes.login;
      }

      if (isRoleLoading || role == null) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (isAuthRoute) return _homeForRole(role);

      if (isPassengerArea && role != AppRole.passenger) return _homeForRole(role);
      if (isDriverArea && role != AppRole.driver) return _homeForRole(role);
      if (isAdminArea && role != AppRole.admin) return _homeForRole(role);

      return null;
    },
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier() {
    _updateRole();
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      _updateRole();
      notifyListeners();
    });
  }

  StreamSubscription<AuthState>? _sub;

  AppRole? _role;
  bool _isRoleLoading = false;

  AppRole? get role => _role;
  bool get isRoleLoading => _isRoleLoading;

  Future<void> _updateRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _role = null;
      _isRoleLoading = false;
      notifyListeners();
      return;
    }

    _isRoleLoading = true;
    notifyListeners();
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      final roleStr = row?['role']?.toString();
      _role = _parseRole(roleStr);
    } catch (_) {
      _role = null;
    } finally {
      _isRoleLoading = false;
      notifyListeners();
    }
  }

  AppRole? _parseRole(String? role) {
    if (role == null) return null;
    for (final r in AppRole.values) {
      if (r.name == role) return r;
    }
    return null;
  }

  void refresh() => notifyListeners();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

String _homeForRole(AppRole role) {
  switch (role) {
    case AppRole.passenger:
      return AppRoutes.passengerHome;
    case AppRole.driver:
      return AppRoutes.driverHome;
    case AppRole.admin:
      return AppRoutes.adminHome;
  }
}
