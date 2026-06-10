import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/mock/mock_data.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/conductor_auth_provider.dart';
import '../providers/conductor_comisiones_provider.dart';
import '../providers/conductor_viaje_provider.dart';
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
    final viaje = ref.watch(conductorViajeProvider);
    final comisiones = ref.watch(conductorComisionesProvider);

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
            viaje: viaje,
            comisiones: comisiones,
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

class _ConductorInicioTab extends ConsumerWidget {
  const _ConductorInicioTab({
    required this.auth,
    required this.viaje,
    required this.comisiones,
    required this.pulse,
  });

  final ConductorAuthState auth;
  final ConductorViajeState viaje;
  final ConductorComisionesState comisiones;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const headerBg = Color(0xFF1E40AF);
    const badgeBg = Color(0xFFF97316);

    final voice = ref.watch(conductorVoiceProvider);
    final (chipBg, chipFg, chipLabel) = switch (auth.estadoActual) {
      ConductorEstadoActual.disponible => (const Color(0xFFDCFCE7), const Color(0xFF16A34A), 'Disponible'),
      ConductorEstadoActual.activo => (const Color(0xFFDBEAFE), const Color(0xFF2563EB), 'Activo'),
      ConductorEstadoActual.enRuta => (const Color(0xFFFFEDD5), const Color(0xFFF97316), 'En ruta'),
      ConductorEstadoActual.finalizado => (const Color(0xFFE5E7EB), const Color(0xFF6B7280), 'Finalizado'),
    };

    final isDisponible = auth.estadoActual == ConductorEstadoActual.disponible;
    final canGroupChat = auth.estadoActual == ConductorEstadoActual.enRuta;
    final activePassengers = viaje.isActive ? viaje.occupiedSeats : 0;
    final viajesHoy = viaje.isActive ? 1 : 0;
    final asientos = viaje.occupiedSeats;
    final comisionHoy = viaje.recaudacionTotal * MockData.conductorPorcentajeComision;

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
                  'Buenos días, Carlos 👋',
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
                        MockData.conductorPlaca,
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
              _DisponibilidadCard(
                isOn: isDisponible,
                accesoOperativo: auth.accesoOperativo,
                activePassengers: activePassengers,
                onTurnOn: () async {
                  if (!auth.accesoOperativo) {
                    AppSnackbars.error(context, 'Acceso operativo bloqueado');
                    return;
                  }
                  final result = await ref.read(conductorAuthProvider.notifier).activarDisponibilidad();
                  if (!context.mounted) return;
                  switch (result) {
                    case ConductorDisponibilidadResult.ok:
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
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _ResumenCard(
                      title: 'Viajes',
                      value: '$viajesHoy',
                      icon: Icons.directions_bus_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ResumenCard(
                      title: 'Asientos',
                      value: '$asientos',
                      icon: Icons.people_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ResumenCard(
                      title: 'Comisión',
                      value: 'S/ ${comisionHoy.toStringAsFixed(0)}',
                      icon: Icons.attach_money_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (viaje.isActive)
                _ViajeActivoCard(
                  occupied: viaje.occupiedSeats,
                  total: viaje.totalSeats,
                  onManage: () => context.go(AppRoutes.driverGestionViaje),
                )
              else if (isDisponible)
                _EsperandoReservasCard(pulse: pulse),
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

class _ViajeActivoCard extends StatelessWidget {
  const _ViajeActivoCard({
    required this.occupied,
    required this.total,
    required this.onManage,
  });

  final int occupied;
  final int total;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: const Color(0xFF2563EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tienes un viaje activo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF2563EB),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$occupied/$total asientos ocupados',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(
              label: 'Gestionar viaje',
              onPressed: onManage,
            ),
          ],
        ),
      ),
    );
  }
}

class _EsperandoReservasCard extends StatelessWidget {
  const _EsperandoReservasCard({required this.pulse});

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
