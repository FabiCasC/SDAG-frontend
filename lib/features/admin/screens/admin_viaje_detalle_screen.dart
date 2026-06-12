import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../providers/admin_conductores_provider.dart';

class AdminViajeDetalleScreen extends ConsumerWidget {
  const AdminViajeDetalleScreen({required this.viajeId, super.key});

  final String viajeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const appBarBg = Color(0xFF0F172A);
    const pageBg = Color(0xFFF8FAFC);

    final controller = ref.read(adminConductoresProvider.notifier);
    final viajes = ref.watch(adminConductoresProvider).viajes;
    final v = viajes.where((e) => e['id']?.toString() == viajeId).cast<Map<String, dynamic>?>().firstWhere(
          (e) => e != null,
          orElse: () => null,
        );
    final conductor = v == null ? null : controller.getById(v['conductorId']?.toString() ?? '');

    final placa = conductor?['placa']?.toString() ?? '—';
    final nombres = conductor?['nombres']?.toString() ?? '';
    final apellidos = conductor?['apellidos']?.toString() ?? '';
    final nombre = conductor == null ? '—' : '$nombres $apellidos'.trim();
    final vehiculo = conductor?['vehiculoTipo']?.toString() ?? '—';
    final capacidad = (conductor?['capacidad'] as num?)?.toInt() ?? 8;
    final ocupados = (capacidad - (viajeId.hashCode.abs() % (capacidad + 1))).clamp(0, capacidad);
    final vacios = (capacidad - ocupados).clamp(0, capacidad);
    final rutaTomada = viajeId.hashCode.isEven ? 'La Priale' : 'Javier Prado';
    final salida = (v?['fecha'] as DateTime?) ?? DateTime.now();
    final duracion = Duration(minutes: 30 + (viajeId.hashCode.abs() % 25));
    final llegada = salida.add(duracion);

    final montoRecaudado = (ocupados * 15.0) + (viajeId.hashCode.abs() % 10);
    final porcentaje = (conductor?['comisionPorcentaje'] as num?)?.toDouble() ?? 15.0;
    final comision = montoRecaudado * porcentaje / 100;

    final pasajeros = List.generate(ocupados, (i) => {
      'nombres': 'Pasajero',
      'apellidos': '${i + 1}',
      'dni': '1234567${i % 10}',
      'asiento': i + 1,
    });
    final abordaron = ocupados;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: AppColors.white,
        title: Text(_formatDateOnly(salida)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.p20),
        children: [
          _Card(
            title: 'Datos del viaje',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E40AF),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _initials(nombre),
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
                            '$nombre · $placa',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$vehiculo · $capacidad asientos',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _KeyValue(label: 'Ruta', value: v?['rutaLabel']?.toString() ?? '—'),
                _KeyValue(label: 'Ruta tomada', value: rutaTomada),
                _KeyValue(label: 'Hora de salida', value: _formatTimeOnly(salida)),
                _KeyValue(label: 'Hora de llegada', value: _formatTimeOnly(llegada)),
                _KeyValue(label: 'Duración total', value: '${duracion.inMinutes} min'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Card(
            title: 'Económico',
            leftBorderColor: const Color(0xFF16A34A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _KeyValue(label: 'Total asientos', value: '$capacidad'),
                _KeyValue(label: 'Asientos ocupados', value: '$ocupados'),
                _KeyValue(label: 'Asientos vacíos', value: '$vacios'),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'S/ ${montoRecaudado.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF16A34A),
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Comisión (${porcentaje.toStringAsFixed(1)}%): S/ ${comision.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFFF97316),
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Card(
            title: 'Pasajeros',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...pasajeros.asMap().entries.map((e) {
                  final i = e.key;
                  final p = e.value;
                  final boarded = i < abordaron;
                  final (chipBg, chipLabel) =
                      boarded ? (const Color(0xFF16A34A), 'Abordó') : (const Color(0xFFDC2626), 'No abordó');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(AppRadius.r16),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${p['nombres']} ${p['apellidos']}',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'DNI: ${p['dni']} · Asiento ${p['asiento']}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              chipLabel,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: AppColors.white,
              minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r12)),
            ),
            onPressed: () => context.push('/admin/manifiestos/$viajeId'),
            child: const Text('Ver manifiesto completo'),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.child,
    this.leftBorderColor,
  });

  final String title;
  final Widget child;
  final Color? leftBorderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border(
          left: BorderSide(color: leftBorderColor ?? AppColors.border, width: leftBorderColor == null ? 1 : 6),
          top: const BorderSide(color: AppColors.border),
          right: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: AppSpacing.shadowBlur,
            offset: Offset(0, AppSpacing.shadowOffsetY),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

String _formatDateOnly(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
}

String _formatTimeOnly(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '${two(h)}:${two(dt.minute)} $ampm';
}

String _initials(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  String first(String s) => s.characters.first.toUpperCase();
  if (parts.isEmpty) return '—';
  if (parts.length == 1) return first(parts[0]);
  return '${first(parts[0])}${first(parts[1])}';
}
