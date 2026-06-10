import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/conductor_auth_provider.dart';
import '../providers/conductor_comisiones_provider.dart';

class ConductorComisionesScreen extends ConsumerWidget {
  const ConductorComisionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conductorComisionesProvider);
    final auth = ref.watch(conductorAuthProvider);

    final date = '${state.hoy.day.toString().padLeft(2, '0')}/'
        '${state.hoy.month.toString().padLeft(2, '0')}/${state.hoy.year}';
    final total = state.totalDia;
    final comision = state.comisionDia;
    final pct = (state.porcentajeComision * 100).round();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.p20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Comisiones',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.driverHistorial),
                child: const Text('Mis viajes'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E40AF),
              borderRadius: BorderRadius.circular(AppRadius.r16),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: AppSpacing.shadowBlur,
                  offset: Offset(0, AppSpacing.shadowOffsetY),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hoy, $date',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'S/ ${total.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 36,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total recaudado',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withAlpha(220),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'S/ ${comision.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFFF97316),
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Comisión ($pct%)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withAlpha(220),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Basado en ${state.viajesCompletadosHoy} viajes completados hoy',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withAlpha(220),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Desglose por viaje',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...state.viajesHoy.map((v) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ViajeCard(
                  hora: v.horaLabel,
                  ruta: v.rutaLabel,
                  pasajeros: '${v.ocupados}/${v.capacidad} asientos',
                  recaudado: v.totalRecaudado,
                  comision: v.totalRecaudado * state.porcentajeComision,
                  porcentaje: state.porcentajeComision,
                ),
              )),
          const SizedBox(height: AppSpacing.lg),
          _SolicitudPagoSection(
            estado: state.estadoSolicitud,
            monto: comision,
            onSolicitar: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Solicitar pago'),
                    content: Text('¿Enviar solicitud de pago por S/ ${comision.toStringAsFixed(0)}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Enviar'),
                      ),
                    ],
                  );
                },
              );
              if (ok != true) return;
              await ref.read(conductorComisionesProvider.notifier).solicitarPago();
              if (!context.mounted) return;
              AppSnackbars.success(context, 'Solicitud enviada');
            },
            onConfirmarRecepcion: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Confirmar recepción'),
                    content: Text(
                      '¿Confirmas que recibiste S/ ${comision.toStringAsFixed(0)} de comisión?\n\n'
                      'Esta acción desbloquea tu acceso operativo para mañana y es irreversible.',
                    ),
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
              if (ok != true) return;
              await ref.read(conductorComisionesProvider.notifier).confirmarRecepcion();
              if (!context.mounted) return;
              AppSnackbars.success(
                context,
                'Recepción confirmada.',
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              'Historial de pagos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            children: [
              const SizedBox(height: AppSpacing.sm),
              ...state.historialPagos.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _PagoRow(
                      fecha: c.fecha,
                      recaudado: c.recaudado,
                      comision: c.comision,
                      estado: c.estado,
                    ),
                  )),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total acumulado del mes: S/ ${state.totalMes.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _ViajeCard extends StatelessWidget {
  const _ViajeCard({
    required this.hora,
    required this.ruta,
    required this.pasajeros,
    required this.recaudado,
    required this.comision,
    required this.porcentaje,
  });

  final String hora;
  final String ruta;
  final String pasajeros;
  final double recaudado;
  final double comision;
  final double porcentaje;

  @override
  Widget build(BuildContext context) {
    final pct = (porcentaje * 100).round();
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            hora,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            ruta,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  pasajeros,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                'S/ ${recaudado.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tu comisión ($pct%)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                'S/ ${comision.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFFF97316),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SolicitudPagoSection extends StatelessWidget {
  const _SolicitudPagoSection({
    required this.estado,
    required this.monto,
    required this.onSolicitar,
    required this.onConfirmarRecepcion,
  });

  final ConductorEstadoSolicitudPago estado;
  final double monto;
  final VoidCallback onSolicitar;
  final VoidCallback onConfirmarRecepcion;

  @override
  Widget build(BuildContext context) {
    if (estado == ConductorEstadoSolicitudPago.confirmadoAdmin) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(color: const Color(0xFF16A34A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '¡Tu pago fue confirmado!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: AppColors.white,
              minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
            ),
            onPressed: onConfirmarRecepcion,
            child: Text('Confirmar recepción (S/ ${monto.toStringAsFixed(0)})'),
          ),
        ],
      );
    }

    if (estado == ConductorEstadoSolicitudPago.recibidoConductor) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: Border.all(color: const Color(0xFF16A34A)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Color(0xFF16A34A)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Recepción confirmada ✓',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF16A34A),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (estado == ConductorEstadoSolicitudPago.pendiente)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                'Solicitud en revisión',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFD97706),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
        if (estado == ConductorEstadoSolicitudPago.pendiente) const SizedBox(height: AppSpacing.md),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF97316),
            foregroundColor: AppColors.white,
            minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
          ),
          onPressed: estado == ConductorEstadoSolicitudPago.sinSolicitud ? onSolicitar : null,
          child: Text(
            estado == ConductorEstadoSolicitudPago.sinSolicitud
                ? 'Solicitar pago al administrador'
                : 'Solicitud enviada ✓',
          ),
        ),
      ],
    );
  }
}

class _PagoRow extends StatelessWidget {
  const _PagoRow({
    required this.fecha,
    required this.recaudado,
    required this.comision,
    required this.estado,
  });

  final DateTime fecha;
  final double recaudado;
  final double comision;
  final String estado;

  @override
  Widget build(BuildContext context) {
    final f = '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              f,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          Text(
            'S/ ${recaudado.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'S/ ${comision.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              estado == 'Pagado' ? 'Confirmado' : estado,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF16A34A),
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
