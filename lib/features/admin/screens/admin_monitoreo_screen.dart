import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../providers/admin_monitoreo_provider.dart';

class AdminMonitoreoScreen extends ConsumerStatefulWidget {
  const AdminMonitoreoScreen({super.key});

  @override
  ConsumerState<AdminMonitoreoScreen> createState() => _AdminMonitoreoScreenState();
}

class _AdminMonitoreoScreenState extends ConsumerState<AdminMonitoreoScreen> {
  GoogleMapController? _mapController;
  BitmapDescriptor? _iconDisponible;
  BitmapDescriptor? _iconEnRuta;
  BitmapDescriptor? _iconActivo;
  BitmapDescriptor? _iconInactivo;
  bool _iconsLoaded = false;
  Timer? _sheetDebounce;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadIcons();
    }
  }

  @override
  void dispose() {
    _sheetDebounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadIcons() async {
    print('>>> Cargando íconos...');
    final disponible = await _combiMarker(const Color(0xFF16A34A));
    final enRuta = await _combiMarker(const Color(0xFF2563EB));
    final activo = await _combiMarker(const Color(0xFFF97316));
    final inactivo = await _combiMarker(const Color(0xFF94A3B8));
    print('>>> Íconos cargados correctamente');
    if (!mounted) return;
    setState(() {
      _iconDisponible = disponible;
      _iconEnRuta = enRuta;
      _iconActivo = activo;
      _iconInactivo = inactivo;
      _iconsLoaded = true;
    });
  }
  BitmapDescriptor _iconFor(AdminVehiculoEstado estado) {
    if (!_iconsLoaded) {
      return switch (estado) {
        AdminVehiculoEstado.disponible => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        AdminVehiculoEstado.enRuta => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        AdminVehiculoEstado.activo => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        AdminVehiculoEstado.inactivo => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      };
    }
    return switch (estado) {
      AdminVehiculoEstado.disponible => _iconDisponible!,
      AdminVehiculoEstado.enRuta => _iconEnRuta!,
      AdminVehiculoEstado.activo => _iconActivo!,
      AdminVehiculoEstado.inactivo => _iconInactivo!,
    };
  }

  void _centerOn(LatLng pos, {double zoom = 14}) {
    final c = _mapController;
    if (c == null) return;
    c.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: zoom)));
  }

  void _centerAll(List<AdminVehiculoActivo> vehiculos) {
    final c = _mapController;
    if (c == null) return;
    if (vehiculos.isEmpty) return;
    if (vehiculos.length == 1) {
      _centerOn(vehiculos.first.posicion);
      return;
    }
    var minLat = vehiculos.first.posicion.latitude;
    var maxLat = vehiculos.first.posicion.latitude;
    var minLng = vehiculos.first.posicion.longitude;
    var maxLng = vehiculos.first.posicion.longitude;
    for (final v in vehiculos) {
      minLat = v.posicion.latitude < minLat ? v.posicion.latitude : minLat;
      maxLat = v.posicion.latitude > maxLat ? v.posicion.latitude : maxLat;
      minLng = v.posicion.longitude < minLng ? v.posicion.longitude : minLng;
      maxLng = v.posicion.longitude > maxLng ? v.posicion.longitude : maxLng;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
  }

  void _onMarkerTap(AdminVehiculoActivo v) {
    _sheetDebounce?.cancel();
    _sheetDebounce = Timer(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => _VehiculoInfoSheet(
          vehiculo: v,
          onVerDetalle: () {
            Navigator.of(context).pop();
            context.push('/admin/conductores/${v.conductorId}');
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFF8FAFC);
    const appBarBg = Color(0xFF0F172A);

    final state = ref.watch(adminMonitoreoProvider);
    final vehiculos = state.vehiculosActivos;
    final activosCount = vehiculos.where((v) => v.estado != AdminVehiculoEstado.inactivo).length;

    if (kIsWeb) {
      return Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: appBarBg,
          foregroundColor: AppColors.white,
          title: const Text('Monitoreo de flota'),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.p20),
              color: const Color(0xFF0F172A),
              child: Row(
                children: [
                  const Icon(Icons.map_rounded, color: AppColors.white),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Mapa no disponible en web (modo mock).',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  _CountBadge(count: activosCount),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.p20),
                itemCount: vehiculos.length,
                itemBuilder: (context, index) {
                  final v = vehiculos[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _VehiculoListTile(
                      vehiculo: v,
                      onCenter: () {},
                      onOpen: () => context.push('/admin/conductores/${v.conductorId}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: const _AdminBottomNav(currentIndex: 3),
      );
    }

    final markers = <Marker>{};
    for (final v in vehiculos) {
      markers.add(
        Marker(
          markerId: MarkerId(v.conductorId),
          position: v.posicion,
          icon: _iconFor(v.estado),
          infoWindow: InfoWindow(title: v.placa),
          onTap: () => _onMarkerTap(v),
        ),
      );
    }

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: AppColors.white,
        title: const Text('Monitoreo de flota'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(-12.0464, -76.9156),
              zoom: 11.5,
            ),
            myLocationButtonEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            markers: markers,
            onMapCreated: (c) => _mapController = c,
          ),
          DraggableScrollableSheet(
            minChildSize: 0.14,
            initialChildSize: 0.18,
            maxChildSize: 0.62,
            builder: (context, scrollController) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r16)),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 18,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.p20, AppSpacing.sm, AppSpacing.p20, AppSpacing.sm),
                      child: Row(
                        children: [
                          Text(
                            'Conductores',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const Spacer(),
                          _CountBadge(count: activosCount),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(AppSpacing.p20, 0, AppSpacing.p20, AppSpacing.p20),
                        itemCount: vehiculos.length,
                        itemBuilder: (context, index) {
                          final v = vehiculos[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _VehiculoListTile(
                              vehiculo: v,
                              onCenter: () => _centerOn(v.posicion),
                              onOpen: () => context.push('/admin/conductores/${v.conductorId}'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            right: AppSpacing.p20,
            bottom: 220,
            child: Column(
              children: [
                _FloatingBadgeButton(
                  icon: Icons.zoom_out_map_rounded,
                  label: 'Centrar todos',
                  badgeCount: activosCount,
                  onTap: () => _centerAll(vehiculos),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _AdminBottomNav(currentIndex: 3),
    );
  }
}

class _VehiculoInfoSheet extends StatelessWidget {
  const _VehiculoInfoSheet({
    required this.vehiculo,
    required this.onVerDetalle,
  });

  final AdminVehiculoActivo vehiculo;
  final VoidCallback onVerDetalle;

  @override
  Widget build(BuildContext context) {
    final (chipBg, chipFg, chipLabel) = _estadoChip(vehiculo.estado);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${vehiculo.conductorNombre} · ${vehiculo.placa}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
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
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (vehiculo.rutaLabel != null)
                  Expanded(
                    child: Text(
                      vehiculo.rutaLabel!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Asientos: ${vehiculo.ocupados}/${vehiculo.capacidad} ocupados',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (vehiculo.etaMinutos != null) ...[
              const SizedBox(height: 6),
              Text(
                'ETA al destino: ~${vehiculo.etaMinutos} min',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: AppColors.white,
                minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r12)),
              ),
              onPressed: onVerDetalle,
              child: const Text('Ver detalle del conductor'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehiculoListTile extends StatelessWidget {
  const _VehiculoListTile({
    required this.vehiculo,
    required this.onCenter,
    required this.onOpen,
  });

  final AdminVehiculoActivo vehiculo;
  final VoidCallback onCenter;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(vehiculo.conductorNombre);
    final (chipBg, chipFg, chipLabel) = _estadoChip(vehiculo.estado);
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF1E40AF),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehiculo.conductorNombre} · ${vehiculo.placa}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          chipLabel,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: chipFg,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (vehiculo.etaMinutos != null)
                        Text(
                          'ETA ~${vehiculo.etaMinutos} min',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: onCenter,
              icon: const Icon(Icons.my_location_rounded, color: Color(0xFF2563EB)),
              tooltip: 'Centrar en mapa',
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingBadgeButton extends StatelessWidget {
  const _FloatingBadgeButton({
    required this.icon,
    required this.label,
    required this.badgeCount,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF0F172A)),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(width: 8),
              _CountBadge(count: badgeCount),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

(Color, Color, String) _estadoChip(AdminVehiculoEstado estado) {
  switch (estado) {
    case AdminVehiculoEstado.disponible:
      return (const Color(0xFF16A34A), AppColors.white, 'Disponible');
    case AdminVehiculoEstado.enRuta:
      return (const Color(0xFF2563EB), AppColors.white, 'En ruta');
    case AdminVehiculoEstado.activo:
      return (const Color(0xFFF97316), const Color(0xFF0F172A), 'Activo');
    case AdminVehiculoEstado.inactivo:
      return (const Color(0xFF94A3B8), const Color(0xFF0F172A), 'Inactivo');
  }
}

String _initials(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  String first(String s) => s.characters.first.toUpperCase();
  if (parts.isEmpty) return '—';
  if (parts.length == 1) return first(parts[0]);
  return '${first(parts[0])}${first(parts[1])}';
}

Future<BitmapDescriptor> _combiMarker(Color color) async {
  const size = 110.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final bgPaint = Paint()..color = color;
  final borderPaint = Paint()
    ..color = const Color(0xFF0F172A).withAlpha(90)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  final windowPaint = Paint()..color = Colors.white.withAlpha(235);
  final wheelPaint = Paint()..color = const Color(0xFF0F172A);

  final base = RRect.fromRectAndRadius(
    const Rect.fromLTWH(18, 22, 74, 54),
    const Radius.circular(14),
  );
  canvas.drawRRect(base, bgPaint);
  canvas.drawRRect(base, borderPaint);

  final w1 = RRect.fromRectAndRadius(const Rect.fromLTWH(28, 32, 18, 14), const Radius.circular(4));
  final w2 = RRect.fromRectAndRadius(const Rect.fromLTWH(50, 32, 18, 14), const Radius.circular(4));
  final w3 = RRect.fromRectAndRadius(const Rect.fromLTWH(72, 32, 12, 14), const Radius.circular(4));
  canvas.drawRRect(w1, windowPaint);
  canvas.drawRRect(w2, windowPaint);
  canvas.drawRRect(w3, windowPaint);

  canvas.drawCircle(const Offset(34, 78), 8, wheelPaint);
  canvas.drawCircle(const Offset(76, 78), 8, wheelPaint);

  final tip = Path()
    ..moveTo(size / 2, size)
    ..lineTo(size / 2 - 12, 78)
    ..lineTo(size / 2 + 12, 78)
    ..close();
  canvas.drawPath(tip, bgPaint);
  canvas.drawPath(tip, borderPaint);

  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(data!.buffer.asUint8List());
}

class _AdminBottomNav extends StatelessWidget {
  const _AdminBottomNav({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0F172A);
    const active = Color(0xFFF97316);
    const inactive = Color(0xFF64748B);

    return Container(
      color: bg,
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: bg,
          selectedItemColor: active,
          unselectedItemColor: inactive,
          onTap: (i) {
            switch (i) {
              case 0:
                context.go(AppRoutes.adminHome);
                return;
              case 1:
                context.go(AppRoutes.adminConductores);
                return;
              case 2:
                context.go(AppRoutes.adminPagos);
                return;
              case 3:
                context.go(AppRoutes.adminMonitoreo);
                return;
              case 4:
              default:
                context.go(AppRoutes.adminAnalitica);
                return;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.directions_bus_rounded), label: 'Conductores'),
            BottomNavigationBarItem(icon: Icon(Icons.attach_money_rounded), label: 'Pagos'),
            BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Monitoreo'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Analítica'),
          ],
        ),
      ),
    );
  }
}
