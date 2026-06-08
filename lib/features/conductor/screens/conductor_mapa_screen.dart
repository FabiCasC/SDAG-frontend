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
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/conductor_viaje_provider.dart';

class ConductorMapaScreen extends ConsumerStatefulWidget {
  const ConductorMapaScreen({super.key});

  @override
  ConsumerState<ConductorMapaScreen> createState() => _ConductorMapaScreenState();
}

class _ConductorMapaScreenState extends ConsumerState<ConductorMapaScreen> {
  GoogleMapController? _mapController;
  Timer? _moveTimer;
  int _routeIndex = 0;
  LatLng _vehicle = const LatLng(-12.0464, -76.9156);
  bool _routeSheetShown = false;
  BitmapDescriptor? _vehicleIcon;
  BitmapDescriptor? _pendingIcon;
  BitmapDescriptor? _pickedIcon;
  BitmapDescriptor? _absentIcon;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadMarkerIcons();
    }
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadMarkerIcons() async {
    final vehicle = await _circleMarker(const Color(0xFF2563EB), 'C');
    final pending = await _circleMarker(const Color(0xFFF97316), '');
    final picked = await _circleMarker(const Color(0xFF16A34A), '');
    final absent = await _circleMarker(const Color(0xFF62748E), '');
    if (!mounted) return;
    setState(() {
      _vehicleIcon = vehicle;
      _pendingIcon = pending;
      _pickedIcon = picked;
      _absentIcon = absent;
    });
  }

  Future<BitmapDescriptor> _circleMarker(Color color, String label) async {
    const size = 96.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = color;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);

    if (label.trim().isNotEmpty) {
      final pb = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.center,
          fontSize: 44,
          fontWeight: FontWeight.w800,
        ),
      )..pushStyle(ui.TextStyle(color: const Color(0xFFFFFFFF)));
      pb.addText(label);
      final paragraph = pb.build();
      paragraph.layout(const ui.ParagraphConstraints(width: size));
      canvas.drawParagraph(
        paragraph,
        Offset(0, (size - paragraph.height) / 2),
      );
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final data = bytes?.buffer.asUint8List();
    if (data == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(data);
  }

  @override
  Widget build(BuildContext context) {
    final viaje = ref.watch(conductorViajeProvider);
    final controller = ref.read(conductorViajeProvider.notifier);

    final route = viaje.rutaSeleccionada;
    if (route == null && !_routeSheetShown) {
      _routeSheetShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        final selected = await showModalBottomSheet<ConductorRuta>(
          context: context,
          isDismissible: false,
          enableDrag: false,
          showDragHandle: false,
          builder: (context) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.p20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Selecciona tu ruta para este viaje',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: AppColors.white,
                        minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.r12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(ConductorRuta.priale),
                      child: const Text('Vía La Priale (~35 min)'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: AppColors.white,
                        minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.r12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(ConductorRuta.javierPrado),
                      child: const Text('Vía Javier Prado/Santa Mónica (~42 min)'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
        if (selected == null) return;
        controller.seleccionarRuta(selected);
        _resetMovement(selected);
      });
    }

    final routePoints = _routePoints(route);
    if (_moveTimer == null && routePoints.isNotEmpty) {
      _startMovement(routePoints);
    }

    final pasajeros = [...viaje.pasajerosViaje]..sort((a, b) => a.asiento.compareTo(b.asiento));
    final nextStop = pasajeros.where((p) => p.estado == EstadoPasajero.pendiente).cast<PasajeroViaje?>().firstWhere(
          (p) => p != null,
          orElse: () => null,
        );
    final nextEta = nextStop == null ? null : 4 + (nextStop.asiento % 5);

    final markers = <Marker>{};
    markers.add(
      Marker(
        markerId: const MarkerId('vehicle'),
        position: _vehicle,
        icon: _vehicleIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Vehículo'),
      ),
    );

    final pickups = _pickupCoordsBySeat();
    for (final p in pasajeros) {
      final pos = pickups[p.asiento] ?? const LatLng(-12.0464, -76.9156);
      final icon = switch (p.estado) {
        EstadoPasajero.pendiente =>
          _pendingIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        EstadoPasajero.abordo =>
          _pickedIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        EstadoPasajero.noAbordo =>
          _absentIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      };
      markers.add(
        Marker(
          markerId: MarkerId('p_${p.id}'),
          position: pos,
          icon: icon,
          infoWindow: InfoWindow(
            title: '${p.nombre} · #${p.asiento}',
            snippet: p.puntoRecojo,
          ),
        ),
      );
    }

    final polyline = routePoints.isEmpty
        ? const <Polyline>{}
        : {
            Polyline(
              polylineId: const PolylineId('route'),
              color: const Color(0xFF2563EB),
              width: 5,
              points: routePoints,
            ),
          };

    return Scaffold(
      body: Stack(
        children: [
          if (kIsWeb)
            const _WebMapFallback()
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: routePoints.isNotEmpty ? routePoints[(routePoints.length / 2).floor()] : _vehicle,
                zoom: 12,
              ),
              onMapCreated: (c) => _mapController = c,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: markers,
              polylines: polyline,
            ),
          Positioned(
            top: AppSpacing.lg,
            left: AppSpacing.lg,
            child: SafeArea(
              child: InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Ink(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: AppSpacing.shadowBlur,
                        offset: Offset(0, AppSpacing.shadowOffsetY),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: 0.24,
              minChildSize: 0.16,
              maxChildSize: 0.46,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r16)),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: AppSpacing.shadowBlur,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.p20, AppSpacing.sm, AppSpacing.p20, AppSpacing.p20),
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Próxima parada',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (nextStop == null)
                        Text(
                          'No hay paradas pendientes.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '${nextStop.nombre} · Asiento #${nextStop.asiento}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              nextStop.puntoRecojo,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                const Icon(Icons.timer_rounded, color: AppColors.primaryBlue),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'ETA: ~${nextEta ?? 5} min',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Paradas',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 86,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: pasajeros.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, i) {
                            final p = pasajeros[i];
                            final color = switch (p.estado) {
                              EstadoPasajero.pendiente => const Color(0xFFF97316),
                              EstadoPasajero.abordo => const Color(0xFF16A34A),
                              EstadoPasajero.noAbordo => const Color(0xFF62748E),
                            };
                            return Container(
                              width: 150,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(AppRadius.r16),
                                border: Border.all(color: AppColors.border),
                              ),
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: color.withAlpha(34),
                                          borderRadius: BorderRadius.circular(AppRadius.pill),
                                          border: Border.all(color: color),
                                        ),
                                        child: Text(
                                          '${i + 1}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: color,
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Expanded(
                                        child: Text(
                                          _shortName(p.nombre),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Asiento #${p.asiento}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
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
          ),
          Positioned(
            right: AppSpacing.lg,
            bottom: 120,
            child: Column(
              children: [
                _FabCircle(
                  icon: Icons.my_location_rounded,
                  bg: const Color(0xFF2563EB),
                  onTap: _center,
                ),
                const SizedBox(height: AppSpacing.sm),
                _FabCircle(
                  icon: Icons.qr_code_scanner_rounded,
                  bg: const Color(0xFFF97316),
                  onTap: () => context.push(AppRoutes.driverQrScanner),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _center() {
    final c = _mapController;
    if (c == null) return;
    c.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: _vehicle, zoom: 14)));
  }

  void _resetMovement(ConductorRuta route) {
    final points = _routePoints(route);
    if (points.isEmpty) return;
    setState(() {
      _routeIndex = 0;
      _vehicle = points.first;
    });
    _startMovement(points);
    _center();
  }

  void _startMovement(List<LatLng> points) {
    _moveTimer?.cancel();
    if (points.isEmpty) return;
    if (_routeIndex >= points.length) _routeIndex = 0;
    _vehicle = points[_routeIndex];
    _moveTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _routeIndex = (_routeIndex + 1) % points.length;
        _vehicle = points[_routeIndex];
      });
    });
  }
}

class _FabCircle extends StatelessWidget {
  const _FabCircle({required this.icon, required this.bg, required this.onTap});

  final IconData icon;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onTap,
      child: Ink(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: AppSpacing.shadowBlur,
              offset: Offset(0, AppSpacing.shadowOffsetY),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.white),
      ),
    );
  }
}

class _WebMapFallback extends StatelessWidget {
  const _WebMapFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fieldFill,
      child: Center(
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map_rounded, color: AppColors.primaryBlue, size: 42),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Mapa no disponible en Web',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<LatLng> _routePoints(ConductorRuta? route) {
  if (route == null) return const [];
  const sanIsidro = LatLng(-12.0931, -76.9662);
  const mid1 = LatLng(-12.0670, -76.9450);
  const mid2 = LatLng(-12.0464, -76.9156);
  const mid3 = LatLng(-12.0000, -76.8600);
  const chosica = LatLng(-11.9333, -76.7000);

  switch (route) {
    case ConductorRuta.priale:
      return const [sanIsidro, mid2, mid3, chosica];
    case ConductorRuta.javierPrado:
      return const [sanIsidro, mid1, mid2, chosica];
  }
}

Map<int, LatLng> _pickupCoordsBySeat() {
  return const {
    1: LatLng(-12.0829, -76.9635),
    2: LatLng(-12.1142, -77.0306),
    3: LatLng(-12.0762, -77.0903),
    4: LatLng(-12.0469, -76.9434),
    5: LatLng(-12.0360, -76.8990),
    6: LatLng(-11.9348, -76.7078),
    7: LatLng(-12.0540, -76.8900),
    8: LatLng(-12.0100, -76.8200),
  };
}

String _shortName(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return name;
  if (parts.length == 1) return parts.first;
  return '${parts.first} ${parts[1][0]}.';
}
