import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/conductor_auth_provider.dart';
import '../providers/conductor_comisiones_provider.dart';
import '../providers/conductor_voice_provider.dart';
import 'conductor_comisiones_screen.dart';
import 'conductor_gestion_viaje_screen.dart';
import 'conductor_perfil_screen.dart';

class ConductorHomeScreen extends ConsumerStatefulWidget {
  const ConductorHomeScreen({required this.initialRoute, super.key});

  final String initialRoute;

  @override
  ConsumerState<ConductorHomeScreen> createState() => _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends ConsumerState<ConductorHomeScreen>
    with SingleTickerProviderStateMixin {
  late int _index;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _index = _indexFromRoute(widget.initialRoute);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ConductorHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _indexFromRoute(widget.initialRoute);
    if (next != _index) setState(() => _index = next);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int _indexFromRoute(String route) {
    switch (route) {
      case AppRoutes.driverGestionViaje:
        return 1;
      case AppRoutes.driverComisiones:
        return 2;
      case AppRoutes.driverProfile:
        return 3;
      case AppRoutes.driverHome:
      default:
        return 0;
    }
  }

  String _routeFromIndex(int index) {
    switch (index) {
      case 1:
        return AppRoutes.driverGestionViaje;
      case 2:
        return AppRoutes.driverComisiones;
      case 3:
        return AppRoutes.driverProfile;
      case 0:
      default:
        return AppRoutes.driverHome;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(conductorAuthProvider);

    if (!auth.conductorLogueado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(AppRoutes.driverLogin);
      });
    }



    const navBg = Color(0xFF1E40AF);

    const active = Color(0xFFF97316);
    const inactive = Color(0xFF93C5FD);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: IndexedStack(
        index: _index,
        children: [
          _ConductorInicioTab(
            auth: auth,
            pulse: _pulseController,
          ),
          const ConductorGestionViajeScreen(),
          const ConductorComisionesScreen(),
          const ConductorPerfilScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        color: navBg,
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _index,
            type: BottomNavigationBarType.fixed,
            backgroundColor: navBg,
            selectedItemColor: active,
            unselectedItemColor: inactive,
            onTap: (value) {
              setState(() => _index = value);
              context.go(_routeFromIndex(value));
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.directions_bus_rounded),
                label: 'Mi Viaje',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.attach_money_rounded),
                label: 'Comisiones',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConductorInicioTab extends ConsumerStatefulWidget {
  const _ConductorInicioTab({
    required this.auth,
    required this.pulse,
  });

  final ConductorAuthState auth;
  final Animation<double> pulse;

  @override
  ConsumerState<_ConductorInicioTab> createState() => _ConductorInicioTabState();
}

class _ConductorInicioTabState extends ConsumerState<_ConductorInicioTab> {
  StreamSubscription<List<Map<String, dynamic>>>? _reservasSubscription;

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _driverData;
  Map<String, dynamic>? _tripData;
  List<_PassengerReservation> _reservas = const [];
  int _asientosOcupados = 0;
  int _capacidad = 0;
  int _totalViajesHoy = 0;
  double _gananciaHoy = 0;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    _cancelReservasSubscription();
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'No hay una sesión activa.';
        });
        return;
      }

      final driverData = await Supabase.instance.client
          .from('drivers')
          .select('''
            id, plate, vehicle_type, capacity, estado, cuenta_activa,
            profiles(id, name, first_name, last_name, email, phone),
            vehicles(id, plate, vehicle_type, total_seats, active)
          ''')
          .eq('profile_id', user.id)
          .single();

      final driverId = driverData['id'];
      final capacidad = (driverData['capacity'] as num?)?.toInt() ?? 0;

      final tripData = await Supabase.instance.client
          .from('trips')
          .select('''
            id, status, scheduled_departure_at, eta_minutes, amount_total,
            routes(id, name, from_label, to_label)
          ''')
          .eq('driver_id', driverId)
          .inFilter('status', ['esperando', 'en_ruta'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final stats = await _loadTodayStats(driverId);

      if (!mounted) return;
      setState(() {
        _driverData = driverData;
        _tripData = tripData;
        _capacidad = capacidad;
        _totalViajesHoy = stats.totalViajes;
        _gananciaHoy = stats.ganancia;
        _reservas = const [];
        _asientosOcupados = 0;
        _errorMessage = null;
      });

      if (tripData != null) {
        final tripId = tripData['id'];
        final reservasIniciales = await Supabase.instance.client
            .from('reservations')
            .select('''
              id, passenger_profile_id, seats, pickup_point, status, amount,
              profiles:passenger_profile_id(id, name, first_name, last_name, phone, dni)
            ''')
            .eq('trip_id', tripId)
            .eq('status', 'activa');

        await _applyReservations(
          (reservasIniciales as List).cast<Map<String, dynamic>>(),
        );
        _subscribeReservas(tripId);
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudo cargar la home del conductor: $e';
      });
    }
  }

  Future<_ConductorHoyStats> _loadTodayStats(dynamic driverId) async {
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day).toIso8601String();
    final finDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59).toIso8601String();

    final viajesHoy = await Supabase.instance.client
        .from('trips')
        .select('id')
        .eq('driver_id', driverId)
        .eq('status', 'completado')
        .gte('finished_at', inicioDia)
        .lte('finished_at', finDia);

    final viajesConMonto = await Supabase.instance.client
        .from('trips')
        .select('amount_total, drivers(commission_pct)')
        .eq('driver_id', driverId)
        .eq('status', 'completado')
        .gte('finished_at', inicioDia)
        .lte('finished_at', finDia);

    final ganancia = (viajesConMonto as List).fold<double>(0.0, (sum, raw) {
      final row = (raw as Map).cast<String, dynamic>();
      final monto = ((row['amount_total'] as num?) ?? 0).toDouble();
      final drivers = row['drivers'];
      Map<String, dynamic>? driverMap;
      if (drivers is Map<String, dynamic>) driverMap = drivers;
      if (drivers is Map) driverMap = drivers.cast<String, dynamic>();
      if (drivers is List && drivers.isNotEmpty) {
        final first = drivers.first;
        if (first is Map<String, dynamic>) driverMap = first;
        if (first is Map) driverMap = first.cast<String, dynamic>();
      }
      final pct = ((driverMap?['commission_pct'] as num?) ?? 0).toDouble();
      return sum + monto * (1 - pct / 100);
    });

    return _ConductorHoyStats(
      totalViajes: (viajesHoy as List).length,
      ganancia: ganancia,
    );
  }

  void _subscribeReservas(dynamic tripId) {
    _cancelReservasSubscription();
    final tid = tripId.toString();
    _reservasSubscription = Supabase.instance.client
        .from('reservations')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tid)
        .listen((_) async {
      try {
        final reservasIniciales = await Supabase.instance.client
            .from('reservations')
            .select('''
              id, passenger_profile_id, seats, pickup_point, status, amount,
              profiles:passenger_profile_id(id, name, first_name, last_name, phone, dni)
            ''')
            .eq('trip_id', tid)
            .eq('status', 'activa');

        await _applyReservations((reservasIniciales as List).cast<Map<String, dynamic>>());
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'No se pudo actualizar las reservas: $e';
        });
      }
    });
  }

  Future<void> _applyReservations(List<Map<String, dynamic>> data) async {
    final reservasActivas = data.where((r) => r['status'] == 'activa').toList();

    final pasajerosConPerfil = <_PassengerReservation>[];
    for (final reserva in reservasActivas) {
      final embeddedProfile = _asMap(reserva['profiles']) ?? _asMap(reserva['perfil']);
      final passengerId = reserva['passenger_profile_id']?.toString();
      Map<String, dynamic>? perfil = embeddedProfile;

      if (perfil == null && passengerId != null && passengerId.isNotEmpty) {
        final fetched = await Supabase.instance.client
            .from('profiles')
            .select('id, name, first_name, last_name, phone, dni')
            .eq('id', passengerId)
            .maybeSingle();
        perfil = _asMap(fetched);
      }

      final seats = _parseSeats(reserva['seats']);
      pasajerosConPerfil.add(
        _PassengerReservation(
          id: reserva['id']?.toString() ?? '',
          passengerProfileId: passengerId ?? '',
          fullName: _fullNameFromProfile(perfil),
          phone: perfil?['phone']?.toString() ?? '—',
          dni: perfil?['dni']?.toString() ?? '—',
          seats: seats,
          pickupPoint: reserva['pickup_point']?.toString() ?? '—',
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _reservas = pasajerosConPerfil;
      _asientosOcupados = pasajerosConPerfil.expand((r) => r.seats).length;
    });
  }

  void _cancelReservasSubscription() {
    _reservasSubscription?.cancel();
    _reservasSubscription = null;
  }

  @override
  void dispose() {
    _reservasSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const headerBg = Color(0xFF1E40AF);
    const badgeBg = Color(0xFFF97316);

    final voice = ref.watch(conductorVoiceProvider);
    final comisiones = ref.watch(conductorComisionesProvider);
    final conductorName = _fullNameFromProfile(_asMap(_driverData?['profiles']));
    final driverPlate = _driverPlate(_driverData);
    final driverEstado = _normalizeDriverEstado(_driverData?['estado']?.toString());
    final tripStatus = _tripData?['status']?.toString();
    final isEnRuta = driverEstado == 'en_ruta' || tripStatus == 'en_ruta';
    final (chipBg, chipFg, chipLabel) = isEnRuta
        ? (const Color(0xFFFFEDD5), const Color(0xFFF97316), 'En ruta')
        : (const Color(0xFFDCFCE7), const Color(0xFF16A34A), 'Disponible');

    final isDisponible = driverEstado == 'disponible';
    final cuentaActiva = (_driverData?['cuenta_activa'] as bool?) ?? true;
    final canGroupChat = cuentaActiva;
    final activePassengers = _asientosOcupados;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        Container(
          height: 160,
          width: double.infinity,
          color: headerBg,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.p20, AppSpacing.md, AppSpacing.p20, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _saludoLine(conductorName),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        driverPlate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        chipLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: chipFg,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.p20),
            children: [
              if (voice.bannerText != null)
                _VoiceBanner(
                  text: voice.bannerText!,
                  onClose: () => ref.read(conductorVoiceProvider.notifier).clearBanner(),
                ),
              if (voice.bannerText != null) const SizedBox(height: AppSpacing.md),
              if (_errorMessage != null)
                _ErrorCard(
                  message: _errorMessage!,
                  onRetry: _loadHomeData,
                ),
              if (_errorMessage != null) const SizedBox(height: AppSpacing.md),
              _DisponibilidadCard(
                isOn: isDisponible,
                accesoOperativo: widget.auth.accesoOperativo,
                activePassengers: activePassengers,
                onTurnOn: () async {
                  if (!widget.auth.accesoOperativo) {
                    AppSnackbars.error(context, 'Acceso operativo bloqueado');
                    return;
                  }
                  final result = await ref.read(conductorAuthProvider.notifier).activarDisponibilidad();
                  if (!context.mounted) return;
                  switch (result) {
                    case ConductorDisponibilidadResult.ok:
                      await _loadHomeData();
                      AppSnackbars.success(context, 'Ahora eres visible para los pasajeros');
                      return;
                    case ConductorDisponibilidadResult.fueraDeHorario:
                      AppSnackbars.warning(context, 'Fuera del horario operativo');
                      return;
                    case ConductorDisponibilidadResult.accesoBloqueado:
                      AppSnackbars.error(context, 'Acceso operativo bloqueado');
                      return;
                  }
                },
                onTurnOff: () async {
                  if (activePassengers > 0) {
                    await showDialog<void>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('No puedes pausar'),
                          content: Text(
                            'Tienes $activePassengers pasajero(s) con reserva. No puedes pausar hasta completar el viaje.',
                          ),
                          actions: [
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Entendido'),
                            ),
                          ],
                        );
                      },
                    );
                    return;
                  }
                  await ref.read(conductorAuthProvider.notifier).desactivarDisponibilidad();
                  await _loadHomeData();
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _ResumenCard(
                      title: 'Estado',
                      value: isEnRuta ? 'En ruta' : 'Disponible',
                      icon: isEnRuta ? Icons.route_rounded : Icons.check_circle_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ResumenCard(
                      title: 'Placa',
                      value: driverPlate,
                      icon: Icons.confirmation_number_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _ResumenCard(
                      title: 'Viajes del día',
                      value: 'Viajes hoy: $_totalViajesHoy',
                      icon: Icons.directions_bus_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ResumenCard(
                      title: 'Ganancia del día',
                      value: 'Ganancia hoy: S/ ${_gananciaHoy.toStringAsFixed(2)}',
                      icon: Icons.payments_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_tripData != null)
                _PassengersSection(
                  passengers: _reservas,
                  occupiedSeats: _asientosOcupados,
                  capacity: _capacidad,
                  pulse: widget.pulse,
                  routeLabel: _routeLabel(_tripData),
                  showPassengerChat: _tripData != null,
                )
              else
                const _NoActiveTripCard(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Accesos rápidos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _QuickActionCard(
                    title: 'Chat grupal',
                    color: canGroupChat ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                    icon: Icons.forum_rounded,
                    iconColor: canGroupChat ? null : const Color(0xFF94A3B8),
                    textColor: canGroupChat ? null : const Color(0xFF94A3B8),
                    onTap: canGroupChat ? () => context.push(AppRoutes.driverChatGrupal) : null,
                  ),
                  _QuickActionCard(
                    title: 'Escanear QR',
                    color: const Color(0xFFF97316),
                    icon: Icons.qr_code_scanner_rounded,
                    onTap: () => context.push(AppRoutes.driverQrScanner),
                  ),
                  _QuickActionCard(
                    title: 'Manifiesto',
                    color: const Color(0xFF2563EB),
                    icon: Icons.list_alt_rounded,
                    onTap: () => context.push(AppRoutes.driverManifiesto),
                  ),
                  _QuickActionCard(
                    title: 'Noticias',
                    color: const Color(0xFFE5E7EB),
                    icon: Icons.newspaper_rounded,
                    iconColor: const Color(0xFF1E40AF),
                    textColor: const Color(0xFF1E40AF),
                    onTap: () => context.push(AppRoutes.driverNoticias),
                  ),
                  _QuickActionCard(
                    title: 'Mis comisiones',
                    color: const Color(0xFF2563EB),
                    icon: Icons.attach_money_rounded,
                    onTap: () => context.go(AppRoutes.driverComisiones),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Historial de comisiones',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...comisiones.historialPagos.take(3).map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              const Icon(Icons.attach_money_rounded, color: AppColors.primaryBlue),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  '${c.fecha.day.toString().padLeft(2, '0')}/${c.fecha.month.toString().padLeft(2, '0')}/${c.fecha.year}',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              Text(
                                'S/ ${c.comision.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

String getSaludo() {
  final hora = DateTime.now().hour;
  if (hora < 12) return 'Buenos días';
  if (hora < 18) return 'Buenas tardes';
  return 'Buenas noches';
}

String _saludoLine(String name) {
  final saludo = getSaludo();
  final n = name.trim();
  if (n.isEmpty) return saludo;
  return '$saludo, $n';
}

class _ConductorHoyStats {
  const _ConductorHoyStats({
    required this.totalViajes,
    required this.ganancia,
  });

  final int totalViajes;
  final double ganancia;
}

class _PassengerReservation {
  const _PassengerReservation({
    required this.id,
    required this.passengerProfileId,
    required this.fullName,
    required this.phone,
    required this.dni,
    required this.seats,
    required this.pickupPoint,
  });

  final String id;
  final String passengerProfileId;
  final String fullName;
  final String phone;
  final String dni;
  final List<int> seats;
  final String pickupPoint;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

String _fullNameFromProfile(Map<String, dynamic>? profile) {
  if (profile == null) return 'Conductor';
  final name = profile['name']?.toString().trim() ?? '';
  if (name.isNotEmpty) return name;
  final firstName = profile['first_name']?.toString().trim() ?? '';
  final lastName = profile['last_name']?.toString().trim() ?? '';
  final fullName = '$firstName $lastName'.trim();
  if (fullName.isNotEmpty) return fullName;
  return 'Conductor';
}

String _normalizeDriverEstado(String? raw) {
  return raw == 'en_ruta' ? 'en_ruta' : 'disponible';
}

String _driverPlate(Map<String, dynamic>? driverData) {
  final ownPlate = driverData?['plate']?.toString().trim() ?? '';
  if (ownPlate.isNotEmpty) return ownPlate;
  final vehicle = _asMap(driverData?['vehicles']);
  final vehiclePlate = vehicle?['plate']?.toString().trim() ?? '';
  if (vehiclePlate.isNotEmpty) return vehiclePlate;
  final vehiclesRaw = driverData?['vehicles'];
  if (vehiclesRaw is List && vehiclesRaw.isNotEmpty) {
    final first = _asMap(vehiclesRaw.first);
    final plate = first?['plate']?.toString().trim() ?? '';
    if (plate.isNotEmpty) return plate;
  }
  return '—';
}

String _routeLabel(Map<String, dynamic>? tripData) {
  final route = _asMap(tripData?['routes']);
  if (route != null) {
    final name = route['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;
    final fromLabel = route['from_label']?.toString().trim() ?? '';
    final toLabel = route['to_label']?.toString().trim() ?? '';
    final label = '$fromLabel → $toLabel'.trim();
    if (label.replaceAll('→', '').trim().isNotEmpty) return label;
  }
  final routesRaw = tripData?['routes'];
  if (routesRaw is List && routesRaw.isNotEmpty) {
    final first = _asMap(routesRaw.first);
    final name = first?['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;
  }
  return 'Ruta activa';
}

List<int> _parseSeats(dynamic rawSeats) {
  if (rawSeats is! List) return const [];
  final out = <int>[];
  for (final seat in rawSeats) {
    if (seat is int) out.add(seat);
    if (seat is num) out.add(seat.toInt());
    if (seat is String) {
      final parsed = int.tryParse(seat);
      if (parsed != null) out.add(parsed);
    }
  }
  out.sort();
  return out;
}

class _DisponibilidadCard extends StatelessWidget {
  const _DisponibilidadCard({
    required this.isOn,
    required this.accesoOperativo,
    required this.activePassengers,
    required this.onTurnOn,
    required this.onTurnOff,
  });

  final bool isOn;
  final bool accesoOperativo;
  final int activePassengers;
  final VoidCallback onTurnOn;
  final VoidCallback onTurnOff;

  @override
  Widget build(BuildContext context) {
    final onLabel = 'Estoy disponible — recibiendo reservas';
    final offLabel = 'Estoy inactivo — no recibo reservas';
    final label = isOn ? onLabel : offLabel;
    final color = isOn ? const Color(0xFF16A34A) : const Color(0xFF6B7280);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: AppSpacing.shadowBlur,
            offset: Offset(0, AppSpacing.shadowOffsetY),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Transform.scale(
              scale: 1.2,
              child: Switch(
                value: isOn,
                activeThumbColor: const Color(0xFF16A34A),
                activeTrackColor: const Color(0xFFDCFCE7),
                inactiveThumbColor: const Color(0xFF6B7280),
                inactiveTrackColor: const Color(0xFFE5E7EB),
                onChanged: (v) {
                  if (v) {
                    if (!accesoOperativo) {
                      onTurnOn();
                      return;
                    }
                    onTurnOn();
                    return;
                  }
                  onTurnOff();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  const _ResumenCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: const Color(0xFFDC2626)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFB91C1C),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoActiveTripCard extends StatelessWidget {
  const _NoActiveTripCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.directions_bus_rounded, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Sin viaje activo hoy',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengersSection extends StatelessWidget {
  const _PassengersSection({
    required this.passengers,
    required this.occupiedSeats,
    required this.capacity,
    required this.pulse,
    required this.routeLabel,
    this.showPassengerChat = false,
  });

  final List<_PassengerReservation> passengers;
  final int occupiedSeats;
  final int capacity;
  final Animation<double> pulse;
  final String routeLabel;
  final bool showPassengerChat;

  @override
  Widget build(BuildContext context) {
    final safeCapacity = capacity <= 0 ? 1 : capacity;
    final progress = (occupiedSeats / safeCapacity).clamp(0.0, 1.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: AppSpacing.shadowBlur,
            offset: Offset(0, AppSpacing.shadowOffsetY),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pasajeros confirmados',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              routeLabel,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$occupiedSeats / $capacity asientos ocupados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: progress,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (passengers.isEmpty) _WaitingReservationsCard(pulse: pulse),
            if (passengers.isNotEmpty)
              ...passengers.map(
                (passenger) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _PassengerTile(
                    passenger: passenger,
                    showChat: showPassengerChat,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WaitingReservationsCard extends StatelessWidget {
  const _WaitingReservationsCard({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final t = pulse.value;
        final alpha = (80 + (t * 120)).round().clamp(0, 255);
        final border = Color.fromARGB(alpha, 22, 163, 74);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: border, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top_rounded, color: Color(0xFF16A34A)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Esperando reservas...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PassengerTile extends StatelessWidget {
  const _PassengerTile({
    required this.passenger,
    this.showChat = false,
  });

  final _PassengerReservation passenger;
  final bool showChat;

  @override
  Widget build(BuildContext context) {
    final seatsLabel = passenger.seats.isEmpty
        ? '—'
        : passenger.seats.map((seat) => '#$seat').join(', ');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        passenger.fullName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        passenger.phone,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Asientos: $seatsLabel',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Punto de recojo: ${passenger.pickupPoint}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                if (showChat && passenger.passengerProfileId.isNotEmpty)
                  IconButton(
                    tooltip: 'Chat con pasajero',
                    onPressed: () => context.push('/conductor/chat/${passenger.passengerProfileId}'),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    color: const Color(0xFF2563EB),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceBanner extends StatelessWidget {
  const _VoiceBanner({required this.text, required this.onClose});

  final String text;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: const Color(0xFF2563EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: Color(0xFF2563EB)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF2563EB),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: Color(0xFF2563EB)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.color,
    required this.icon,
    this.onTap,
    this.iconColor,
    this.textColor,
  });

  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = textColor ?? AppColors.white;
    final ic = iconColor ?? AppColors.white;
    final bg = enabled ? color : color.withAlpha(140);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r16),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withAlpha(max(20, (0.18 * 255).round())),
              blurRadius: AppSpacing.shadowBlur,
              offset: const Offset(0, AppSpacing.shadowOffsetY),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: ic),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
