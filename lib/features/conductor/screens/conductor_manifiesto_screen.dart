import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/passenger/controllers/connectivity_controller.dart';
import '../../../core/mock/mock_data.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/conductor_manifiesto_provider.dart';

class ConductorManifiestoScreen extends ConsumerWidget {
  const ConductorManifiestoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(connectivityProvider);
    final state = ref.watch(conductorManifiestoProvider);
    final passengers = [...state.listaPasajeros]..sort((a, b) => a.asiento.compareTo(b.asiento));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Manifiesto electrónico'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              AppSnackbars.info(context, 'Manifiesto compartido (PDF mock)');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.p20),
          children: [
            if (!connected)
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
            if (!connected) const SizedBox(height: AppSpacing.md),
            _HeaderCard(generadoAt: state.generadoAt),
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
              label: 'Compartir manifiesto',
              onPressed: () => AppSnackbars.info(context, 'Manifiesto compartido (PDF mock)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.generadoAt});

  final DateTime generadoAt;

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
            _row(context, 'Ruta', 'San Isidro → Chosica'),
            _row(context, 'Conductor', '${MockData.conductorNombre} · ${MockData.conductorPlaca}'),
            _row(context, 'Vehículo', '${MockData.conductorVehiculo} · ${MockData.conductorCapacidad} asientos'),
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
            DataColumn(label: Text('Apellido')),
            DataColumn(label: Text('DNI')),
            DataColumn(label: Text('Teléfono')),
            DataColumn(label: Text('Asiento')),
            DataColumn(label: Text('Estado')),
          ],
          rows: [
            for (var i = 0; i < passengers.length; i++)
              DataRow(
                cells: [
                  DataCell(Text('${i + 1}')),
                  DataCell(Text(passengers[i].nombres)),
                  DataCell(Text(passengers[i].apellidos)),
                  DataCell(Text(passengers[i].dni)),
                  DataCell(Text(passengers[i].telefono)),
                  DataCell(Text('${passengers[i].asiento}')),
                  DataCell(_EstadoChip(estado: passengers[i].estado)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estado});

  final ManifiestoEstadoPasajero estado;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (estado) {
      ManifiestoEstadoPasajero.subio => (const Color(0xFFDCFCE7), const Color(0xFF16A34A), 'Subió'),
      ManifiestoEstadoPasajero.noSubio => (const Color(0xFFFEE2E2), const Color(0xFFDC2626), 'No subió'),
      ManifiestoEstadoPasajero.pendiente => (const Color(0xFFFEF9C3), const Color(0xFFD97706), 'Pendiente'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: fg.withAlpha(70)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w900,
            ),
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
