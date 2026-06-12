import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../roles/admin/admin_shell_screen.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../providers/admin_auth_provider.dart';
import '../providers/admin_monitoreo_provider.dart';
import '../providers/admin_pagos_provider.dart';
import '../providers/admin_analitica_provider.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const caption = Color(0xFF64748B);
    const datetimeColor = Color(0xFF94A3B8);
    const pageBg = Color(0xFFF8FAFC);
    const headerHeight = 240.0;
    final bottomPadding = MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + AppSpacing.p20;

    final auth = ref.watch(adminAuthProvider);
    final pagos = ref.watch(adminPagosProvider);
    final monitoreo = ref.watch(adminMonitoreoProvider);
    final analitica = ref.watch(adminAnaliticaProvider);
    final stats = analitica.estadisticas;

    final fleetItems = _buildFleet(monitoreo.vehiculosActivos);
    final conductoresActivos = fleetItems.where((e) => e.status != _FleetStatus.inactivo).length;

    return AdminShellScreen(
      currentRoute: AppRoutes.adminHome,
      title: 'Panel de administración',
      backgroundColor: pageBg,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.adminPerfil),
          icon: const Icon(Icons.person_rounded),
          tooltip: 'Perfil',
        ),
      ],
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: headerHeight,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF0F172A),
                          Color(0xFF1E293B),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.p20, AppSpacing.md, AppSpacing.p20, AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              'Panel de administración',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: caption,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Buenos días, ${_adminSaludoNombre('Administrador')}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _formatDateTime(_now),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: datetimeColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                            const Spacer(),
                            if (auth.adminLogueado)
                              Text(
                                'Sesión activa',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: caption),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.p20,
                      headerHeight - 50,
                      AppSpacing.p20,
                      bottomPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _QuickSummaryGrid(
                          viajesHoy: stats.viajesCompletados,
                          ingresosHoy: stats.ingresosTotales,
                          ocupacionPromedio: stats.ocupacionPromedio,
                          conductoresActivos: conductoresActivos,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _PagosPendientesSection(
                          solicitudes: pagos.solicitudesPendientes,
                          onVerTodas: () => context.go(AppRoutes.adminPagos),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _FlotaSection(
                          items: fleetItems,
                          onVerMapa: () => context.go(AppRoutes.adminMonitoreo),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _AccesosRapidos(
                          onNuevoConductor: () => context.go(AppRoutes.adminConductoresNuevo),
                          onManifiestos: () => context.go(AppRoutes.adminManifiestos),
                          onAnalitica: () => context.go(AppRoutes.adminAnalitica),
                          onConfiguracion: () => context.go(AppRoutes.adminConfiguracion),
                          onChatGrupal: () => context.go(AppRoutes.adminChatGrupal),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_FleetItem> _buildFleet(List<AdminVehiculoActivo> vehiculos) {
    final items = <_FleetItem>[];
    for (var i = 0; i < vehiculos.length; i++) {
      final v = vehiculos[i];
      final status = switch (v.estado) {
        AdminVehiculoEstado.enRuta => _FleetStatus.enRuta,
        AdminVehiculoEstado.disponible => _FleetStatus.disponible,
      };
      items.add(_FleetItem(
        conductor: v.conductorNombre,
        placa: v.placa,
        status: status,
      ));
    }
    return items;
  }
}

class _QuickSummaryGrid extends StatelessWidget {
  const _QuickSummaryGrid({
    required this.viajesHoy,
    required this.ingresosHoy,
    required this.ocupacionPromedio,
    required this.conductoresActivos,
  });

  final int viajesHoy;
  final double ingresosHoy;
  final double ocupacionPromedio;
  final int conductoresActivos;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryCard(
        title: 'Viajes hoy',
        subtitle: 'viajes completados hoy',
        value: '$viajesHoy',
        color: const Color(0xFF2563EB),
        icon: Icons.directions_bus_rounded,
      ),
      _SummaryCard(
        title: 'Ingresos hoy',
        subtitle: 'recaudado hoy',
        value: 'S/ ${_formatNumber(ingresosHoy.round())}',
        color: const Color(0xFF16A34A),
        icon: Icons.attach_money_rounded,
      ),
      _SummaryCard(
        title: 'Ocupación',
        subtitle: 'promedio de asientos',
        value: '${(ocupacionPromedio * 100).round()}%',
        color: const Color(0xFFF97316),
        icon: Icons.people_rounded,
      ),
      _SummaryCard(
        title: 'Conductores activos',
        subtitle: 'conductores en operación',
        value: '$conductoresActivos',
        color: const Color(0xFF9333EA),
        icon: Icons.person_pin_rounded,
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        mainAxisExtent: 120,
      ),
      itemBuilder: (context, index) => items[index],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: AppSpacing.shadowBlur,
            offset: Offset(0, AppSpacing.shadowOffsetY),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 6,
            color: color,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                height: 1.0,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF62748E),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(icon, color: color, size: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PagosPendientesSection extends StatelessWidget {
  const _PagosPendientesSection({
    required this.solicitudes,
    required this.onVerTodas,
  });

  final List<AdminPagoSolicitud> solicitudes;
  final VoidCallback onVerTodas;

  @override
  Widget build(BuildContext context) {
    final pendingCount = solicitudes.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Pagos pendientes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (pendingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$pendingCount',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            const Spacer(),
            if (pendingCount > 0)
              TextButton(
                onPressed: onVerTodas,
                child: const Text('Ver todas'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (pendingCount == 0)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                'Al día',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          )
        else
          Column(
            children: List<Widget>.generate(
              solicitudes.length.clamp(0, 3),
              (i) {
                final req = solicitudes[i];
                final placa = req.placa;
                final tiempo = _relativeFromDate(req.solicitadoAt);

                return Padding(
                  padding: EdgeInsets.only(bottom: i == 2 || i == solicitudes.length - 1 ? 0 : AppSpacing.sm),
                  child: Container(
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
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${req.conductor} · $placa',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'S/ ${_formatNumber(req.monto.round())} · $tiempo',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.r12),
                            ),
                          ),
                          onPressed: onVerTodas,
                          child: const Text('Revisar'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _FlotaSection extends StatelessWidget {
  const _FlotaSection({
    required this.items,
    required this.onVerMapa,
  });

  final List<_FleetItem> items;
  final VoidCallback onVerMapa;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Estado de la flota',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onVerMapa,
              child: const Text('Ver mapa completo'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _FleetChip(item: e),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _FleetChip extends StatelessWidget {
  const _FleetChip({required this.item});

  final _FleetItem item;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (item.status) {
      _FleetStatus.enRuta => (const Color(0xFF16A34A), AppColors.white, 'En ruta'),
      _FleetStatus.disponible => (const Color(0xFF2563EB), AppColors.white, 'Disponible'),
      _FleetStatus.inactivo => (const Color(0xFF94A3B8), const Color(0xFF0F172A), 'Inactivo'),
      _FleetStatus.activo => (const Color(0xFFF97316), const Color(0xFF0F172A), 'Activo'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '${_shortName(item.conductor)} · $label',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _AccesosRapidos extends StatelessWidget {
  const _AccesosRapidos({
    required this.onNuevoConductor,
    required this.onManifiestos,
    required this.onAnalitica,
    required this.onConfiguracion,
    required this.onChatGrupal,
  });

  final VoidCallback onNuevoConductor;
  final VoidCallback onManifiestos;
  final VoidCallback onAnalitica;
  final VoidCallback onConfiguracion;
  final VoidCallback onChatGrupal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Accesos rápidos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: onNuevoConductor,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
          ),
          child: const Text('Registrar nuevo conductor'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: onManifiestos,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
          ),
          child: const Text('Ver manifiestos del día'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: onAnalitica,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
          ),
          child: const Text('Estadísticas detalladas'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: onConfiguracion,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
          ),
          child: const Text('Configuración general'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: onChatGrupal,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
          ),
          child: const Text('Chat grupal con conductores'),
        ),
      ],
    );
  }
}

String _formatDateTime(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  final date = '${two(dt.day)}/${two(dt.month)}/${dt.year}';
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  final time = '${two(hour)}:${two(dt.minute)} $ampm';
  return '$date · $time';
}

String _formatNumber(int value) {
  final s = value.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    b.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) b.write(',');
  }
  return b.toString();
}

String _adminSaludoNombre(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) return '${parts[0]} ${parts[1]}';
  return fullName;
}

String _shortName(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return fullName;
  if (parts.length == 1) return parts[0];
  return '${parts[0]} ${parts[1]}';
}

String _relativeFromDate(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Hace 1 min';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} horas';
  return 'Hace ${diff.inDays} días';
}

enum _FleetStatus { enRuta, disponible, inactivo, activo }

class _FleetItem {
  const _FleetItem({
    required this.conductor,
    required this.placa,
    required this.status,
  });

  final String conductor;
  final String placa;
  final _FleetStatus status;
}
