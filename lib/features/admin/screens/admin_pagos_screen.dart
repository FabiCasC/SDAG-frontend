import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_routes.dart';
import '../../../roles/admin/admin_shell_screen.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../providers/admin_conductores_provider.dart';
import '../providers/admin_pagos_provider.dart';

class AdminPagosScreen extends ConsumerStatefulWidget {
  const AdminPagosScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  ConsumerState<AdminPagosScreen> createState() => _AdminPagosScreenState();
}

class _AdminPagosScreenState extends ConsumerState<AdminPagosScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _pendingScroll = ScrollController();
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab.clamp(0, 1));
  }

  @override
  void dispose() {
    _pendingScroll.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _scrollToSolicitud(String solicitudId) async {
    final state = ref.read(adminPagosProvider);
    final idx = state.solicitudesPendientes.indexWhere((e) => e.id == solicitudId);
    if (idx < 0) return;
    _tabController.index = 0;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!_pendingScroll.hasClients) return;
    _pendingScroll.animateTo(
      (idx * 164).toDouble(),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _showDetalleSolicitud(AdminPagoSolicitud s) async {
    final total = s.totalRecaudado;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalle de solicitud'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${s.conductor} · ${s.placa}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Viajes del día', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              ...s.detalleViajes.map(
                (v) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(v.label)),
                      Text('S/ ${v.monto.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              const Divider(height: AppSpacing.lg),
              _KeyValue(label: 'Total recaudado', value: 'S/ ${total.toStringAsFixed(0)}'),
              _KeyValue(label: 'Porcentaje de comisión', value: '${s.porcentaje.toStringAsFixed(1)}%'),
              _KeyValue(label: 'Monto a pagar', value: 'S/ ${s.monto.toStringAsFixed(0)}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFF8FAFC);

    final state = ref.watch(adminPagosProvider);
    final controller = ref.read(adminPagosProvider.notifier);
    final conductores = ref.watch(adminConductoresProvider).listaConductores;

    final pendientesCount = state.solicitudesPendientes.length;
    final banner = state.banner;

    return AdminShellScreen(
      currentRoute: AppRoutes.adminPagos,
      title: 'Pagos de comisiones',
      backgroundColor: pageBg,
      actions: [
        IconButton(
          onPressed: () async {
            final created = await controller.simularNuevaSolicitud();
            if (!context.mounted || created == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF0F172A),
                content: Text('Solicitud simulada: ${created.conductor} · S/ ${created.monto.toStringAsFixed(0)}'),
              ),
            );
          },
          icon: const Icon(Icons.bug_report_rounded),
          tooltip: 'Simular solicitud (debug)',
        ),
      ],
      appBarBottom: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFFF97316),
        labelColor: AppColors.white,
        unselectedLabelColor: const Color(0xFF94A3B8),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Pendientes'),
                if (pendientesCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '$pendientesCount',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Tab(text: 'Historial'),
        ],
      ),
      body: Column(
        children: [
          if (banner != null)
            Material(
              color: const Color(0xFFF97316),
              child: InkWell(
                onTap: () async {
                  controller.clearBanner();
                  await _scrollToSolicitud(banner.solicitudId);
                },
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p20, vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: AppColors.white),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            banner.message,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: controller.clearBanner,
                          icon: const Icon(Icons.close_rounded, color: AppColors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PendientesTab(
                  scrollController: _pendingScroll,
                  solicitudes: state.solicitudesPendientes,
                  onVerDetalle: _showDetalleSolicitud,
                  onConfirmar: (s) async {
                    if (_confirming) return;
                    if (!context.mounted) return;
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmar pago'),
                        content: Text(
                          '¿Confirmar pago de S/ ${s.monto.toStringAsFixed(0)} a ${s.conductor}?\n\n'
                          'Esta acción notificará al conductor.\n'
                          'La confirmación es irreversible.',
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: AppColors.white,
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Confirmar pago'),
                          ),
                        ],
                      ),
                    );
                    if (!context.mounted) return;
                    if (ok != true) return;

                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);

                    setState(() => _confirming = true);
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(color: Color(0xFF16A34A)),
                      ),
                    );
                    await Future<void>.delayed(const Duration(seconds: 1));
                    if (context.mounted) navigator.pop();

                    await controller.confirmarPago(s.id);
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF16A34A),
                        content: Text('Pago confirmado. ${s.conductor} fue notificado.'),
                      ),
                    );
                    if (mounted) setState(() => _confirming = false);
                  },
                ),
                _HistorialTab(
                  conductores: conductores.map((e) => '${e['nombres']?.toString() ?? ''} ${e['apellidos']?.toString() ?? ''}'.trim()).toList(growable: false),
                  filtroConductor: state.filtroConductor,
                  filtroDesde: state.filtroFechaDesde,
                  filtroHasta: state.filtroFechaHasta,
                  historial: state.historialFiltrado,
                  onChangeConductor: (value) => controller.filtrarHistorial(filtroConductor: value),
                  onChangeRange: (from, to) => controller.filtrarHistorial(filtroFechaDesde: from, filtroFechaHasta: to),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminPagosHistorialScreen extends ConsumerWidget {
  const AdminPagosHistorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AdminPagosScreen(initialTab: 1);
  }
}

class _PendientesTab extends ConsumerWidget {
  const _PendientesTab({
    required this.scrollController,
    required this.solicitudes,
    required this.onVerDetalle,
    required this.onConfirmar,
  });

  final ScrollController scrollController;
  final List<AdminPagoSolicitud> solicitudes;
  final ValueChanged<AdminPagoSolicitud> onVerDetalle;
  final ValueChanged<AdminPagoSolicitud> onConfirmar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (solicitudes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.p20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_rounded, size: 72, color: Color(0xFF94A3B8)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No hay solicitudes pendientes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Todos los pagos al día',
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
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.p20),
      itemCount: solicitudes.length,
      itemBuilder: (context, index) {
        final s = solicitudes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _SolicitudCard(
            solicitud: s,
            onVerDetalle: () => onVerDetalle(s),
            onConfirmar: () => onConfirmar(s),
          ),
        );
      },
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  const _SolicitudCard({
    required this.solicitud,
    required this.onVerDetalle,
    required this.onConfirmar,
  });

  final AdminPagoSolicitud solicitud;
  final VoidCallback onVerDetalle;
  final VoidCallback onConfirmar;

  @override
  Widget build(BuildContext context) {
    const left = Color(0xFFF97316);
    final initials = _initials(solicitud.conductor);
    final totalLabel = 'S/ ${solicitud.totalRecaudado.toStringAsFixed(0)}';
    final pct = solicitud.porcentaje.toStringAsFixed(1);

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
        border: Border(
          left: const BorderSide(color: left, width: 6),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
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
                child: Text(
                  solicitud.conductor,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  solicitud.placa,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'S/ ${solicitud.monto.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF16A34A),
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$pct% de $totalLabel recaudados hoy',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDateTime(solicitud.solicitadoAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF62748E),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onVerDetalle,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r12)),
                  ),
                  child: const Text('Ver detalle'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: onConfirmar,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r12)),
                  ),
                  child: const Text('Confirmar pago'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistorialTab extends StatefulWidget {
  const _HistorialTab({
    required this.conductores,
    required this.filtroConductor,
    required this.filtroDesde,
    required this.filtroHasta,
    required this.historial,
    required this.onChangeConductor,
    required this.onChangeRange,
  });

  final List<String> conductores;
  final String? filtroConductor;
  final DateTime? filtroDesde;
  final DateTime? filtroHasta;
  final List<AdminPagoHistorial> historial;
  final ValueChanged<String?> onChangeConductor;
  final void Function(DateTime? from, DateTime? to) onChangeRange;

  @override
  State<_HistorialTab> createState() => _HistorialTabState();
}

class _HistorialTabState extends State<_HistorialTab> {
  Future<void> _pickRange() async {
    final now = DateTime.now();
    final initialStart = widget.filtroDesde ?? now.subtract(const Duration(days: 7));
    final initialEnd = widget.filtroHasta ?? now;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );
    if (range == null) return;
    final from = DateTime(range.start.year, range.start.month, range.start.day);
    final to = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
    widget.onChangeRange(from, to);
  }

  Future<void> _showDetalle(AdminPagoHistorial p) async {
    final total = p.totalRecaudado;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalle de pago'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${p.conductor} · ${p.placa}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Viajes del día', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              ...p.detalleViajes.map(
                (v) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(v.label)),
                      Text('S/ ${v.monto.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              const Divider(height: AppSpacing.lg),
              _KeyValue(label: 'Total recaudado', value: 'S/ ${total.toStringAsFixed(0)}'),
              _KeyValue(label: 'Porcentaje de comisión', value: '${p.porcentaje.toStringAsFixed(1)}%'),
              _KeyValue(label: 'Monto pagado', value: 'S/ ${p.monto.toStringAsFixed(0)}'),
              _KeyValue(label: 'Confirmado', value: _formatDateTime(p.confirmadoAt)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.historial;
    final totalPagado = items.fold<double>(0, (acc, e) => acc + e.monto);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.p20),
      children: [
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
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Conductor'),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: widget.filtroConductor,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Todos los conductores')),
                            ...widget.conductores.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                          ],
                          onChanged: widget.onChangeConductor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: _pickRange,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r12)),
                    ),
                    child: Text(
                      widget.filtroDesde == null || widget.filtroHasta == null
                          ? 'Rango'
                          : '${_formatDateOnly(widget.filtroDesde!)} - ${_formatDateOnly(widget.filtroHasta!)}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No hay pagos en el período')))
        else
          ...items.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.r16),
                onTap: () => _showDetalle(p),
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
                              '${p.conductor} · ${p.placa}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${p.porcentaje.toStringAsFixed(1)}% · ${_formatDateTime(p.confirmadoAt)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF62748E),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'S/ ${p.monto.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFF16A34A),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              'Confirmado',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _KeyValue(label: 'Total pagado en el período', value: 'S/ ${totalPagado.toStringAsFixed(0)}'),
              _KeyValue(label: 'Número de pagos', value: '${items.length}'),
            ],
          ),
        ),
      ],
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

String _initials(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  String first(String s) => s.characters.first.toUpperCase();
  if (parts.isEmpty) return '—';
  if (parts.length == 1) return first(parts[0]);
  return '${first(parts[0])}${first(parts[1])}';
}

String _formatDateOnly(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
}

String _formatDateTime(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  final date = '${two(dt.day)}/${two(dt.month)}/${dt.year}';
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$date · ${two(h)}:${two(dt.minute)} $ampm';
}
