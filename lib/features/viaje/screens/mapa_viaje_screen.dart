import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../features/reserva/providers/reserva_provider.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/viaje_provider.dart';

class MapaViajeScreen extends ConsumerWidget {
  const MapaViajeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reserva = ref.watch(reservaProvider);
    final viaje = ref.watch(viajeProvider);
    ref.listen<ViajeState>(viajeProvider, (previous, next) {
      if (next.finished && previous?.finished != true) {
        context.go(AppRoutes.passengerCalificacion);
      }
    });

    final driver = reserva.conductorSeleccionado;
    if (driver == null || reserva.reservaId == null) {
      return const AppScaffold(
        title: 'Ubicación',
        body: PlaceholderPage(
          title: 'No hay viaje activo',
          subtitle: 'Confirma una reserva para ver el mapa del viaje.',
        ),
      );
    }

    final pickup = const LatLng(-12.0931, -76.9662);
    final sanIsidro = const LatLng(-12.0931, -76.9662);
    final mid = const LatLng(-12.0464, -76.9156);
    final chosica = const LatLng(-11.9333, -76.7000);

    final vehicle = LatLng(viaje.vehiclePosition.lat, viaje.vehiclePosition.lng);

    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      color: AppColors.primaryBlue,
      width: 5,
      points: [sanIsidro, mid, chosica],
    );

    return Scaffold(
      body: Stack(
        children: [
          if (kIsWeb)
            _WebMapFallback(
              vehicleLabel: '${driver.name} · ${driver.plate}',
            )
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(target: mid, zoom: 11),
              polylines: {polyline},
              markers: {
                Marker(
                  markerId: const MarkerId('vehicle'),
                  position: vehicle,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                ),
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: pickup,
                ),
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          Positioned(
            top: AppSpacing.lg,
            right: AppSpacing.lg,
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
                  child: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.p20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.r16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.82),
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppRadius.r16),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Llegas en ~35 min',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${driver.name} · ${driver.plate}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.energeticOrange,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.r12),
                            ),
                          ),
                          onPressed: () async {
                            final ok = await _confirmDrop(context);
                            if (!context.mounted) return;
                            if (!ok) return;
                            AppSnackbars.success(context, 'Bajada registrada');
                            context.pop();
                          },
                          child: const Text('Bajarme aquí'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDrop(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bajarme aquí'),
          content: const Text('¿Confirmas que bajas aquí?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

class _WebMapFallback extends StatelessWidget {
  const _WebMapFallback({required this.vehicleLabel});

  final String vehicleLabel;

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
                const SizedBox(height: AppSpacing.xs),
                Text(
                  vehicleLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
