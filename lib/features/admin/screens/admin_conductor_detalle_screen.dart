import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/mock/mock_data.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../providers/admin_conductores_provider.dart';

class AdminConductorDetalleScreen extends ConsumerStatefulWidget {
  const AdminConductorDetalleScreen({required this.id, super.key});

  final String id;

  @override
  ConsumerState<AdminConductorDetalleScreen> createState() => _AdminConductorDetalleScreenState();
}

class _AdminConductorDetalleScreenState extends ConsumerState<AdminConductorDetalleScreen> {
  Future<void> _openComisionSheet(MockAdminConductor conductor) async {
    final initial = (conductor.comisionPendientePorcentaje ?? conductor.comisionPorcentaje).clamp(0.0, 30.0);
    final result = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _ComisionBottomSheet(initial: initial),
    );
    if (!mounted) return;
    if (result == null) return;

    ref.read(adminConductoresProvider.notifier).actualizarComision(conductor.id, result);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Comisión actualizada. Aplica desde mañana.'),
      ),
    );
  }

  Future<void> _confirmDesbloqueo(MockAdminConductor conductor) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desbloquear acceso'),
        content: const Text(
          'El conductor tiene deuda pendiente.\n'
          '¿Desbloquear de todas formas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok != true) return;

    ref.read(adminConductoresProvider.notifier).desbloquearConductor(conductor.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Acceso desbloqueado. El desbloqueo ha sido registrado.'),
      ),
    );
  }

  Future<void> _confirmDesactivar(MockAdminConductor conductor) async {
    final warning = conductor.estado == MockAdminConductorEstado.enRuta;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar conductor'),
        content: Text(
          warning
              ? 'Este conductor tiene un viaje activo.\n¿Desactivar de todas formas?'
              : '¿Desactivar a este conductor?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok != true) return;

    ref.read(adminConductoresProvider.notifier).desactivarConductor(conductor.id);
  }

  Future<void> _confirmReactivar(MockAdminConductor conductor) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reactivar conductor'),
        content: const Text('¿Reactivar a este conductor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok != true) return;
    ref.read(adminConductoresProvider.notifier).reactivarConductor(conductor.id);
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFF8FAFC);
    ref.watch(adminConductoresProvider);
    final controller = ref.read(adminConductoresProvider.notifier);
    final conductor = controller.getById(widget.id);

    if (conductor == null) {
      return Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(title: const Text('Conductor')),
        body: const Center(child: Text('No se encontró el conductor.')),
      );
    }

    final viajes = controller.viajesDeConductor(conductor.id);
    final recientes = viajes.take(3).toList(growable: false);
    final initials = _initials(conductor.nombres, conductor.apellidos);
    final (chipBg, chipFg, chipLabel) = _statusChip(conductor.estado);
    final showUnlock = conductor.bloqueadoPorPago || conductor.estado == MockAdminConductorEstado.bloqueado;
    final showDeactivate = conductor.estado != MockAdminConductorEstado.inactivo;
    final showReactivate = conductor.estado == MockAdminConductorEstado.inactivo;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: Text(conductor.nombreCompleto),
        actions: [
          PopupMenuButton<_DetalleAction>(
            onSelected: (value) {
              switch (value) {
                case _DetalleAction.editar:
                  context.push('/admin/conductores/${conductor.id}/editar');
                  return;
                case _DetalleAction.historial:
                  context.push('/admin/conductores/${conductor.id}/historial');
                  return;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _DetalleAction.editar, child: Text('Editar conductor')),
              PopupMenuItem(value: _DetalleAction.historial, child: Text('Ver historial')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.p20),
        children: [
          Container(
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E40AF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  conductor.nombreCompleto,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    chipLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: chipFg,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _Stars(rating: conductor.ratingPromedio, count: conductor.ratingCount, big: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Datos del vehículo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Placa: ${conductor.placa}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tipo: ${conductor.vehiculoTipo}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Capacidad: ${conductor.capacidad} asientos',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.lock_rounded, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Solo editable desde 'Editar'",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Comisión configurada',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${conductor.comisionPorcentaje.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: const Color(0xFF2563EB),
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Por cada S/480 recaudados → S/ ${(480 * conductor.comisionPorcentaje / 100).toStringAsFixed(0)} de comisión',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (conductor.comisionPendientePorcentaje != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'Cambio pendiente: ${conductor.comisionPendientePorcentaje!.toStringAsFixed(1)}% (aplica desde mañana)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF92400E),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r12)),
                  ),
                  onPressed: () => _openComisionSheet(conductor),
                  child: const Text('Modificar comisión'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Acciones administrativas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (showUnlock)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: AppColors.white,
                      minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r12)),
                    ),
                    onPressed: () => _confirmDesbloqueo(conductor),
                    child: const Text('Desbloquear acceso'),
                  ),
                if (showUnlock) const SizedBox(height: AppSpacing.sm),
                if (showDeactivate)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r12)),
                    ),
                    onPressed: () => _confirmDesactivar(conductor),
                    child: const Text('Desactivar conductor'),
                  ),
                if (showReactivate)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: AppColors.white,
                      minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r12)),
                    ),
                    onPressed: () => _confirmReactivar(conductor),
                    child: const Text('Reactivar conductor'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Últimos viajes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push('/admin/conductores/${conductor.id}/historial'),
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (recientes.isEmpty)
                  Text(
                    'Sin viajes registrados.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  )
                else
                  Column(
                    children: [
                      for (final v in recientes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.r16),
                            onTap: () => context.push('/admin/historial-viajes/${v.id}'),
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
                                          _formatFecha(v.fecha),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          v.rutaLabel,
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'S/ ${v.monto.toStringAsFixed(0)}',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      _ViajeEstadoChip(estado: v.estado),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      OutlinedButton(
                        onPressed: () => context.push('/admin/conductores/${conductor.id}/historial'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.r12),
                          ),
                        ),
                        child: const Text('Ver historial completo'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: () => context.go(AppRoutes.adminConductores),
            child: const Text('Volver al listado'),
          ),
        ],
      ),
    );
  }
}

class _ComisionBottomSheet extends StatefulWidget {
  const _ComisionBottomSheet({required this.initial});

  final double initial;

  @override
  State<_ComisionBottomSheet> createState() => _ComisionBottomSheetState();
}

class _ComisionBottomSheetState extends State<_ComisionBottomSheet> {
  late final TextEditingController _controller;
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
    _controller = TextEditingController(text: _value.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncFromText() {
    final raw = _controller.text.replaceAll(',', '.').trim();
    final parsed = double.tryParse(raw);
    if (parsed == null) return;
    final clamped = parsed.clamp(0.0, 30.0);
    setState(() => _value = clamped);
  }

  @override
  Widget build(BuildContext context) {
    final sample = 480 * _value / 100;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.p20,
        right: AppSpacing.p20,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.p20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Modificar comisión',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _value,
                  min: 0,
                  max: 30,
                  divisions: 60,
                  onChanged: (v) {
                    setState(() => _value = v);
                    _controller.text = _value.toStringAsFixed(1);
                  },
                ),
              ),
              SizedBox(
                width: 88,
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _syncFromText(),
                  decoration: const InputDecoration(labelText: '%'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Con ${_value.toStringAsFixed(1)}%: si el conductor recauda S/480,\n'
            'su comisión será S/ ${sample.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
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
            onPressed: () => Navigator.of(context).pop(_value),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _ViajeEstadoChip extends StatelessWidget {
  const _ViajeEstadoChip({required this.estado});

  final MockAdminViajeEstado estado;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (estado) {
      MockAdminViajeEstado.completado => (const Color(0xFF16A34A), AppColors.white, 'Completado'),
      MockAdminViajeEstado.cancelado => (const Color(0xFFDC2626), AppColors.white, 'Cancelado'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
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

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, required this.count, this.big = false});

  final double rating;
  final int count;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final full = rating.floor().clamp(0, 5);
    final hasHalf = (rating - full) >= 0.5 && full < 5;
    final stars = <Widget>[];
    final size = big ? 18.0 : 16.0;
    for (var i = 0; i < full; i++) {
      stars.add(Icon(Icons.star_rounded, size: size, color: const Color(0xFFF59E0B)));
    }
    if (hasHalf) {
      stars.add(Icon(Icons.star_half_rounded, size: size, color: const Color(0xFFF59E0B)));
    }
    while (stars.length < 5) {
      stars.add(Icon(Icons.star_border_rounded, size: size, color: const Color(0xFFCBD5E1)));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...stars,
        const SizedBox(width: 6),
        Text(
          '${rating.toStringAsFixed(1)} ($count)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: big ? 13 : 12,
              ),
        ),
      ],
    );
  }
}

String _initials(String nombres, String apellidos) {
  String firstLetter(String s) {
    final t = s.trim();
    if (t.isEmpty) return '';
    return t.characters.first.toUpperCase();
  }

  final n = firstLetter(nombres);
  final a = firstLetter(apellidos);
  final out = '$n$a';
  return out.isEmpty ? '—' : out;
}

(Color, Color, String) _statusChip(MockAdminConductorEstado estado) {
  switch (estado) {
    case MockAdminConductorEstado.enRuta:
      return (const Color(0xFF2563EB), AppColors.white, 'En ruta');
    case MockAdminConductorEstado.disponible:
      return (const Color(0xFF16A34A), AppColors.white, 'Disponible');
    case MockAdminConductorEstado.inactivo:
      return (const Color(0xFF94A3B8), const Color(0xFF0F172A), 'Inactivo');
    case MockAdminConductorEstado.bloqueado:
      return (const Color(0xFFDC2626), AppColors.white, 'Bloqueado');
  }
}

String _formatFecha(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  final date = '${two(dt.day)}/${two(dt.month)}/${dt.year}';
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$date · ${two(h)}:${two(dt.minute)} $ampm';
}

enum _DetalleAction { editar, historial }
