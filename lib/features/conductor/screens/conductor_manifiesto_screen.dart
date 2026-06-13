import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../app/providers/passenger/controllers/connectivity_controller.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/widgets/app_navigation_back.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/conductor_manifiesto_provider.dart';
import '../providers/perfil_conductor_provider.dart';

class ConductorManifiestoScreen extends ConsumerStatefulWidget {
  const ConductorManifiestoScreen({super.key});

  @override
  ConsumerState<ConductorManifiestoScreen> createState() => _ConductorManifiestoScreenState();
}

class _ConductorManifiestoScreenState extends ConsumerState<ConductorManifiestoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conductorManifiestoProvider.notifier).reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(connectivityProvider);
    final state = ref.watch(conductorManifiestoProvider);
    final perfil = ref.watch(perfilConductorProvider);
    final passengers = [...state.listaPasajeros]..sort((a, b) => a.asiento.compareTo(b.asiento));

    Future<void> exportPdf() async {
      if (state.status != ConductorManifiestoLoadStatus.ready) {
        AppSnackbars.info(context, 'No hay manifiesto para exportar');
        return;
      }
      if (passengers.isEmpty) {
        AppSnackbars.info(context, 'No hay pasajeros para exportar');
        return;
      }

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          build: (context) {
            return pw.Table.fromTextArray(
              headers: const ['Asiento', 'Nombre', 'DNI', 'Teléfono', 'Punto recojo', 'Estado'],
              data: passengers
                  .map(
                    (e) => [
                      e.asiento.toString(),
                      e.nombreCompleto,
                      e.dni,
                      e.telefono,
                      e.puntoRecojo,
                      switch (e.estado) {
                        ManifiestoEstadoPasajero.subio => 'Ya abordó',
                        ManifiestoEstadoPasajero.noSubio => 'No subió',
                        ManifiestoEstadoPasajero.pendiente => 'Pendiente',
                        ManifiestoEstadoPasajero.cancelado => 'Canceló',
                      },
                    ],
                  )
                  .toList(),
            );
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'manifiesto.pdf',
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Manifiesto electrónico'),
        leading: AppBarLeadingBack(fallbackRoute: AppRoutes.driverHome),
        actions: [
          TextButton(
            onPressed: exportPdf,
            child: const Text('Exportar PDF'),
          )
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (state.status == ConductorManifiestoLoadStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == ConductorManifiestoLoadStatus.noActiveTrip) {
              return const Center(
                child: Text(
                  'No hay manifiesto activo',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800),
                ),
              );
            }
            if (state.status == ConductorManifiestoLoadStatus.noPassengersYet) {
              return const Center(
                child: Text(
                  'No hay pasajeros en este viaje',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800),
                ),
              );
            }
            if (state.status == ConductorManifiestoLoadStatus.error) {
              return Center(
                child: Text(
                  state.errorMessage ?? 'No se pudo cargar el manifiesto',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w800),
                ),
              );
            }

            final conductorLabel = perfil.name.isNotEmpty
                ? (perfil.plate.isNotEmpty ? '${perfil.name} · ${perfil.plate}' : perfil.name)
                : (perfil.plate.isNotEmpty ? perfil.plate : '—');
            final vehicleLabel = perfil.vehicleType.isNotEmpty
                ? (perfil.plate.isNotEmpty ? '${perfil.vehicleType} · ${perfil.plate}' : perfil.vehicleType)
                : '—';

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.p20),
              children: [
                if (!connected && state.offlineCached)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF9C3),
                      borderRadius: BorderRadius.circular(AppRadius.r16),
                      border: Border.all(color: const Color(0xFFD97706)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Color(0xFFD97706)),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Mostrando manifiesto guardado — sin conexión',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFFD97706),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!connected && state.offlineCached) const SizedBox(height: AppSpacing.md),
                _HeaderCard(
                  generadoAt: state.generadoAt,
                  tripStatus: state.tripStatus,
                  conductorLabel: conductorLabel,
                  vehicleLabel: vehicleLabel,
                ),
                const SizedBox(height: AppSpacing.lg),
                _TableCard(passengers: passengers),
                const SizedBox(height: AppSpacing.lg),
                _TotalsCard(
                  total: state.total,
                  abordaron: state.abordaron,
                  noAbordaron: state.noAbordaron,
                  pendientes: state.pendientes,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  label: 'Exportar PDF',
                  onPressed: exportPdf,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.generadoAt,
    required this.tripStatus,
    required this.conductorLabel,
    required this.vehicleLabel,
  });

  final DateTime generadoAt;
  final String? tripStatus;
  final String conductorLabel;
  final String vehicleLabel;

  @override
  Widget build(BuildContext context) {
    final date =
        '${generadoAt.day.toString().padLeft(2, '0')}/${generadoAt.month.toString().padLeft(2, '0')}/${generadoAt.year}';
    final time =
        '${generadoAt.hour.toString().padLeft(2, '0')}:${generadoAt.minute.toString().padLeft(2, '0')}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Datos del viaje',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _row(context, 'Generado', '$date $time'),
            _row(context, 'Estado', tripStatus ?? '—'),
            _row(context, 'Conductor', conductorLabel),
            _row(context, 'Vehículo', vehicleLabel),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.passengers});

  final List<ManifiestoItem> passengers;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFEFF6FF)),
          columns: const [
            DataColumn(label: Text('N°')),
            DataColumn(label: Text('Nombre')),
            DataColumn(label: Text('DNI')),
            DataColumn(label: Text('Teléfono')),
            DataColumn(label: Text('Asiento')),
            DataColumn(label: Text('Estado')),
          ],
          rows: [
            for (var i = 0; i < passengers.length; i++)
              DataRow(
                color: WidgetStateProperty.all(_rowColor(passengers[i].reservationStatus)),
                cells: [
                  DataCell(Text('${i + 1}')),
                  DataCell(Text(passengers[i].nombreCompleto)),
                  DataCell(Text(passengers[i].dni)),
                  DataCell(Text(passengers[i].telefono)),
                  DataCell(Text('${passengers[i].asiento}')),
                  DataCell(
                    _EstadoChip(
                      estado: passengers[i].estado,
                      reservationStatus: passengers[i].reservationStatus,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

Color? _rowColor(String reservationStatus) {
  return switch (reservationStatus) {
    'completada' => const Color(0xFFF0FDF4),
    'cancelada' => const Color(0xFFFEF2F2),
    _ => AppColors.white,
  };
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({
    required this.estado,
    required this.reservationStatus,
  });

  final ManifiestoEstadoPasajero estado;
  final String reservationStatus;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label, icon) = switch (reservationStatus) {
      'completada' => (
          const Color(0xFFDCFCE7),
          const Color(0xFF16A34A),
          'Ya abordó',
          Icons.check_circle_rounded,
        ),
      'cancelada' => (
          const Color(0xFFFEE2E2),
          const Color(0xFFDC2626),
          'Canceló',
          Icons.cancel_rounded,
        ),
      _ => switch (estado) {
          ManifiestoEstadoPasajero.subio => (
              const Color(0xFFDCFCE7),
              const Color(0xFF16A34A),
              'Subió',
              Icons.check_circle_outline_rounded,
            ),
          ManifiestoEstadoPasajero.noSubio => (
              const Color(0xFFFEE2E2),
              const Color(0xFFDC2626),
              'No subió',
              Icons.close_rounded,
            ),
          ManifiestoEstadoPasajero.cancelado => (
              const Color(0xFFFEE2E2),
              const Color(0xFFDC2626),
              'Canceló',
              Icons.cancel_rounded,
            ),
          ManifiestoEstadoPasajero.pendiente => (
              const Color(0xFFFEF9C3),
              const Color(0xFFD97706),
              'Pendiente',
              Icons.schedule_rounded,
            ),
        },
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: fg.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.total,
    required this.abordaron,
    required this.noAbordaron,
    required this.pendientes,
  });

  final int total;
  final int abordaron;
  final int noAbordaron;
  final int pendientes;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Totales',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _line(context, 'Total pasajeros', '$total'),
            _line(context, 'Abordaron', '$abordaron'),
            _line(context, 'No abordaron', '$noAbordaron'),
            _line(context, 'Pendientes', '$pendientes'),
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}
