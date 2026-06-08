import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/conductor_auth_provider.dart';
import '../providers/conductor_viaje_provider.dart';
import '../providers/conductor_voice_provider.dart';

class ConductorGestionViajeScreen extends ConsumerStatefulWidget {
  const ConductorGestionViajeScreen({super.key});

  @override
  ConsumerState<ConductorGestionViajeScreen> createState() => _ConductorGestionViajeScreenState();
}

class _ConductorGestionViajeScreenState extends ConsumerState<ConductorGestionViajeScreen> {
  late final ProviderSubscription<ConductorViajeState> _sub;
  int _lastToastId = 0;
  String? _lastBanner;

  @override
  void initState() {
    super.initState();
    _sub = ref.listenManual<ConductorViajeState>(conductorViajeProvider, (previous, next) {
      if (!mounted) return;

      if (next.toastMessage != null && next.toastId != _lastToastId) {
        _lastToastId = next.toastId;
        final type = next.toastType ?? ConductorToastType.info;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          switch (type) {
            case ConductorToastType.success:
              AppSnackbars.success(context, next.toastMessage!);
            case ConductorToastType.error:
              AppSnackbars.error(context, next.toastMessage!);
            case ConductorToastType.warning:
              AppSnackbars.warning(context, next.toastMessage!);
            case ConductorToastType.info:
              AppSnackbars.info(context, next.toastMessage!);
          }
          ref.read(conductorViajeProvider.notifier).clearToast();
        });
      }

      if (next.bannerText != null && next.bannerText != _lastBanner) {
        _lastBanner = next.bannerText;
      }
    });
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }

  Future<void> _confirmStartRoute(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Iniciar ruta'),
          content: const Text(
            '¿Iniciar la ruta? Esto notificará a todos los pasajeros que el vehículo partió.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sí, iniciar'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    ref.read(conductorViajeProvider.notifier).iniciarRuta();
  }

  Future<void> _confirmComplete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Completar ruta'),
          content: const Text('¿Confirmas que llegaste al destino?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sí, completar'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    ref.read(conductorViajeProvider.notifier).completarRuta();
    if (!context.mounted) return;
    final result = await ref.read(conductorAuthProvider.notifier).activarDisponibilidad();
    if (!context.mounted) return;
    switch (result) {
      case ConductorDisponibilidadResult.ok:
        AppSnackbars.success(context, 'Ruta completada. ¡Buen trabajo!');
        return;
      case ConductorDisponibilidadResult.fueraDeHorario:
        AppSnackbars.success(context, 'Ruta completada. Fuera del horario operativo.');
        return;
      case ConductorDisponibilidadResult.accesoBloqueado:
        AppSnackbars.success(context, 'Ruta completada.');
        return;
    }
  }

  Future<void> _avisarAlternativo(BuildContext context, PasajeroViaje p) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Avisar punto alternativo'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Mensaje',
              hintText: 'Ej: Te recojo en la entrada principal...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
    final text = result?.trim();
    if (text == null || text.isEmpty) return;
    if (!context.mounted) return;
    AppSnackbars.info(context, 'Mensaje enviado a ${p.nombre}');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(conductorAuthProvider);
    final state = ref.watch(conductorViajeProvider);
    final controller = ref.read(conductorViajeProvider.notifier);
    final voice = ref.watch(conductorVoiceProvider);

    if (!auth.conductorLogueado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(AppRoutes.driverLogin);
      });
    }
    if (!auth.pagoConfirmado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(AppRoutes.driverBlocked);
      });
    }

    final banner = state.bannerText;
    final pasajeros = [...state.pasajerosViaje]..sort((a, b) => a.asiento.compareTo(b.asiento));

    final selectedRoute = state.rutaSeleccionada;
    final routeLabel = switch (selectedRoute) {
      ConductorRuta.priale => 'Vía La Priale',
      ConductorRuta.javierPrado => 'Vía Javier Prado',
      null => null,
    };

    final occupied = state.occupiedSeats;
    final total = state.totalSeats;
    final remaining = (total - occupied).clamp(0, total);
    final progress = total == 0 ? 0.0 : (occupied / total).clamp(0.0, 1.0);

    final remainingTextColor = remaining == 1
        ? const Color(0xFFDC2626)
        : remaining <= 3
            ? const Color(0xFFD97706)
            : const Color(0xFF62748E);

    final estado = state.estadoViaje;
    final header = switch (estado) {
      ConductorEstadoViaje.esperando => _HeaderSpec(
          bg: const Color(0xFFFEF9C3),
          fg: const Color(0xFFD97706),
          title: 'Esperando pasajeros',
        ),
      ConductorEstadoViaje.lleno => _HeaderSpec(
          bg: const Color(0xFFDCFCE7),
          fg: const Color(0xFF16A34A),
          title: '¡Vehículo completo! Listo para partir',
        ),
      ConductorEstadoViaje.enRuta => _HeaderSpec(
          bg: const Color(0xFF2563EB),
          fg: AppColors.white,
          title: 'En ruta — San Isidro → Chosica',
        ),
      ConductorEstadoViaje.completado => _HeaderSpec(
          bg: const Color(0xFFE5E7EB),
          fg: const Color(0xFF111827),
          title: 'Ruta completada',
        ),
    };

    return Column(
      children: [
        if (voice.bannerText != null)
          Material(
            color: const Color(0xFFEFF6FF),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p20, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up_rounded, color: Color(0xFF2563EB)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        voice.bannerText!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF2563EB),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.read(conductorVoiceProvider.notifier).clearBanner(),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (banner != null)
          Material(
            color: const Color(0xFFFEF9C3),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p20, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    const Icon(Icons.info_rounded, color: Color(0xFFD97706)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        banner,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFFD97706),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ref.read(conductorViajeProvider.notifier).clearBanner();
                      },
                      icon: const Icon(Icons.close_rounded, color: Color(0xFFD97706)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Container(
          width: double.infinity,
          color: header.bg,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.p20, AppSpacing.md, AppSpacing.p20, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    header.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: header.fg,
                          fontWeight: estado == ConductorEstadoViaje.lleno ? FontWeight.w800 : FontWeight.w700,
                          fontSize: estado == ConductorEstadoViaje.lleno ? 18 : 18,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (estado == ConductorEstadoViaje.enRuta) ...[
                    Text(
                      _formatElapsed(state.elapsedSeconds),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _RouteSelector(
                            selected: selectedRoute,
                            onSelect: controller.seleccionarRuta,
                          ),
                        ),
                        if (routeLabel != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: header.fg.withAlpha(26),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              routeLabel,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: header.fg,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.p20),
            children: [
              if (estado == ConductorEstadoViaje.esperando || estado == ConductorEstadoViaje.lleno) ...[
                Center(
                  child: Text(
                    '$occupied / $total',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 64,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Text(
                    'asientos ocupados',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    color: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFFE2E8F0),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: _RemainingSeatsText(remaining: remaining, color: remainingTextColor),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SeatMapConductor(
                  totalSeats: total,
                  occupiedSeats: state.asientosOcupados.toSet(),
                  passengerBySeat: {for (final p in pasajeros) p.asiento: p},
                  onTapPassenger: (p) => _showPassenger(context, p),
                ),
                const SizedBox(height: AppSpacing.md),
                _EstimacionCard(minutes: state.estimacionMinutos),
                const SizedBox(height: AppSpacing.lg),
                if (estado == ConductorEstadoViaje.lleno) ...[
                  _CountdownCard(seconds: state.secondsToDepart ?? 180),
                  const SizedBox(height: AppSpacing.lg),
                  AppCriticalButton(
                    label: 'Iniciar ruta ahora',
                    onPressed: () => _confirmStartRoute(context),
                  ),
                ] else ...[
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE5E7EB),
                      foregroundColor: const Color(0xFF6B7280),
                      minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.r12),
                      ),
                    ),
                    onPressed: () {
                      AppSnackbars.warning(context, 'El vehículo debe estar completo para partir');
                    },
                    child: const Text('Iniciar ruta'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'El vehículo debe estar completo para partir',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _DebugRow(
                  onSimulateLastSeat: controller.simularUltimoAsiento,
                  onSimulateCancel: pasajeros.isEmpty
                      ? null
                      : () => controller.cancelarReserva(pasajeros.first.id),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (estado == ConductorEstadoViaje.lleno) ...[
                  Text(
                    'Pasajeros y paradas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...pasajeros.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ParadaRow(
                          stop: pasajeros.indexOf(p) + 1,
                          p: p,
                        ),
                      )),
                ],
              ],
              if (estado == ConductorEstadoViaje.enRuta) ...[
                _NextStopCard(
                  passenger: pasajeros.firstWhere(
                    (p) => p.estado == EstadoPasajero.pendiente,
                    orElse: () => pasajeros.isNotEmpty ? pasajeros.first : _dummyPassenger(),
                  ),
                  onAvisar: (p) => _avisarAlternativo(context, p),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Pasajeros',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...pasajeros.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _PassengerStatusRow(
                        p: p,
                        onChat: () => context.push('/conductor/chat/${p.id}'),
                        onMarkBoarded: () => controller.actualizarEstadoPasajero(
                          pasajeroId: p.id,
                          estado: EstadoPasajero.abordo,
                        ),
                        onMarkAbsent: () => controller.actualizarEstadoPasajero(
                          pasajeroId: p.id,
                          estado: EstadoPasajero.noAbordo,
                        ),
                      ),
                    )),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: AppCriticalButton(
                        label: 'Escanear QR',
                        icon: Icons.qr_code_scanner_rounded,
                        onPressed: () => context.push(AppRoutes.driverQrScanner),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppSecondaryButton(
                        label: 'Ver mapa',
                        icon: Icons.map_rounded,
                        onPressed: () => context.push(AppRoutes.driverMapa),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: AppColors.white,
                    minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                  ),
                  onPressed: () => _confirmComplete(context),
                  child: const Text('Marcar ruta como completada'),
                ),
                if (state.revertSecondsLeft != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                    ),
                    onPressed: () {
                      controller.revertirCompletarRuta();
                      AppSnackbars.warning(context, 'Se revirtió la finalización');
                    },
                    child: Text('Revertir (${state.revertSecondsLeft}s)'),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _DebugRow(
                  onSimulateLastSeat: null,
                  onSimulateCancel: pasajeros.isEmpty
                      ? null
                      : () => controller.cancelarReserva(pasajeros.first.id),
                ),
              ],
              if (estado == ConductorEstadoViaje.completado) ...[
                const SizedBox(height: AppSpacing.lg),
                const Icon(Icons.check_circle_rounded, size: 80, color: AppColors.success),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Ruta completada',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppPrimaryButton(
                  label: 'Volver al home',
                  onPressed: () => context.go(AppRoutes.driverHome),
                ),
                if (state.revertSecondsLeft != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                    ),
                    onPressed: () => controller.revertirCompletarRuta(),
                    child: Text('Revertir (${state.revertSecondsLeft}s)'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showPassenger(BuildContext context, PasajeroViaje p) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.p20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                p.nombre,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'DNI: ${p.dni} · Asiento #${p.asiento}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                p.puntoRecojo,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: 'Chat',
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/conductor/chat/${p.id}');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderSpec {
  const _HeaderSpec({
    required this.bg,
    required this.fg,
    required this.title,
  });

  final Color bg;
  final Color fg;
  final String title;
}

class _RouteSelector extends StatelessWidget {
  const _RouteSelector({
    required this.selected,
    required this.onSelect,
  });

  final ConductorRuta? selected;
  final ValueChanged<ConductorRuta> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget button(String label, ConductorRuta value) {
      final isSelected = selected == value;
      return Expanded(
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: isSelected ? AppColors.white : const Color(0xFF1E40AF),
            backgroundColor: isSelected ? const Color(0xFF1E40AF) : AppColors.white,
            side: BorderSide(color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF93C5FD)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
          ),
          onPressed: () => onSelect(value),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      );
    }

    return Row(
      children: [
        button('Vía La Priale', ConductorRuta.priale),
        const SizedBox(width: AppSpacing.sm),
        button('Vía Javier Prado', ConductorRuta.javierPrado),
      ],
    );
  }
}

class _RemainingSeatsText extends StatelessWidget {
  const _RemainingSeatsText({required this.remaining, required this.color});

  final int remaining;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final base = 'Faltan $remaining asientos para partir';
    if (remaining == 1) {
      return _PulseText(text: base, color: color);
    }
    return Text(
      base,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _PulseText extends StatefulWidget {
  const _PulseText({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  State<_PulseText> createState() => _PulseTextState();
}

class _PulseTextState extends State<_PulseText> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _a = Tween<double>(begin: 0.55, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: Text(
        widget.text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: widget.color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _SeatMapConductor extends StatelessWidget {
  const _SeatMapConductor({
    required this.totalSeats,
    required this.occupiedSeats,
    required this.passengerBySeat,
    required this.onTapPassenger,
  });

  final int totalSeats;
  final Set<int> occupiedSeats;
  final Map<int, PasajeroViaje> passengerBySeat;
  final ValueChanged<PasajeroViaje> onTapPassenger;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List.generate(totalSeats, (i) {
        final seat = i + 1;
        final occupied = occupiedSeats.contains(seat);
        final bg = occupied ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9);
        final border = occupied ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0);
        return InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          onTap: !occupied
              ? null
              : () {
                  final p = passengerBySeat[seat];
                  if (p != null) onTapPassenger(p);
                },
          child: Container(
            width: 64,
            height: 56,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.r12),
              border: Border.all(color: border, width: 2),
            ),
            child: Center(
              child: Text(
                '$seat',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: occupied ? const Color(0xFF2563EB) : const Color(0xFF334155),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _EstimacionCard extends StatelessWidget {
  const _EstimacionCard({required this.minutes});

  final int? minutes;

  @override
  Widget build(BuildContext context) {
    final text = minutes == null
        ? 'Sin estimación disponible'
        : minutes == 0
            ? 'Estimación: el vehículo está completo'
            : 'Estimación: el vehículo podría llenarse en ~$minutes min';
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.insights_rounded, color: AppColors.primaryBlue),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final mm = (seconds ~/ 60).clamp(0, 99);
    final ss = (seconds % 60).clamp(0, 59);
    final label = '${mm.toString().padLeft(1, '0')}:${ss.toString().padLeft(2, '0')}';
    final progress = (seconds / 180).clamp(0.0, 1.0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    color: const Color(0xFFDC2626),
                    backgroundColor: const Color(0xFFE5E7EB),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.w900,
                          fontSize: 42,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tienes 3 minutos para dirigirte al primer punto',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ParadaRow extends StatelessWidget {
  const _ParadaRow({required this.stop, required this.p});

  final int stop;
  final PasajeroViaje p;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '$stop',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${p.nombre} · Asiento #${p.asiento}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      if (p.fueraDeRuta)
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFF97316)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    p.puntoRecojo,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF9C3),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'Pendiente de abordaje',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFD97706),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengerStatusRow extends StatelessWidget {
  const _PassengerStatusRow({
    required this.p,
    required this.onChat,
    required this.onMarkBoarded,
    required this.onMarkAbsent,
  });

  final PasajeroViaje p;
  final VoidCallback onChat;
  final VoidCallback onMarkBoarded;
  final VoidCallback onMarkAbsent;

  @override
  Widget build(BuildContext context) {
    final (icon, chipBg, chipFg, chipText) = switch (p.estado) {
      EstadoPasajero.abordo => (Icons.check_circle_rounded, const Color(0xFFDCFCE7), const Color(0xFF16A34A), 'Abordó'),
      EstadoPasajero.pendiente => (Icons.hourglass_top_rounded, const Color(0xFFFEF9C3), const Color(0xFFD97706), 'Pendiente'),
      EstadoPasajero.noAbordo => (Icons.cancel_rounded, const Color(0xFFFEF2F2), const Color(0xFFDC2626), 'No abordó'),
    };

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: chipFg),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${p.nombre} · Asiento #${p.asiento}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    chipText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: chipFg,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              p.puntoRecojo,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Chat',
                    icon: Icons.chat_bubble_rounded,
                    onPressed: onChat,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: p.estado == EstadoPasajero.abordo ? null : onMarkBoarded,
                    child: const Text('Abordó'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                    ),
                    onPressed: p.estado == EstadoPasajero.noAbordo ? null : onMarkAbsent,
                    child: const Text('No abordó'),
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

class _NextStopCard extends StatelessWidget {
  const _NextStopCard({
    required this.passenger,
    required this.onAvisar,
  });

  final PasajeroViaje passenger;
  final ValueChanged<PasajeroViaje> onAvisar;

  @override
  Widget build(BuildContext context) {
    final eta = 6 + (passenger.asiento % 5);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: const Color(0xFF2563EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Próxima parada',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF2563EB),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${passenger.nombre} · Asiento #${passenger.asiento}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              passenger.puntoRecojo,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.timer_rounded, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'ETA aprox: $eta min',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppSecondaryButton(
              label: 'Avisar punto alternativo',
              icon: Icons.edit_location_alt_rounded,
              onPressed: () => onAvisar(passenger),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow({required this.onSimulateLastSeat, required this.onSimulateCancel});

  final VoidCallback? onSimulateLastSeat;
  final VoidCallback? onSimulateCancel;

  @override
  Widget build(BuildContext context) {
    if (onSimulateLastSeat == null && onSimulateCancel == null) return const SizedBox.shrink();
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
            Row(
              children: [
                const Icon(Icons.bug_report_rounded, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Modo debug',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (onSimulateLastSeat != null)
                  TextButton(
                    onPressed: onSimulateLastSeat,
                    child: const Text('Simular último asiento'),
                  ),
                if (onSimulateCancel != null)
                  TextButton(
                    onPressed: onSimulateCancel,
                    child: const Text('Simular cancelación'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

PasajeroViaje _dummyPassenger() {
  return const PasajeroViaje(
    id: 'x',
    nombre: 'Pasajero',
    dni: '00000000',
    asiento: 0,
    puntoRecojo: '-',
    estado: EstadoPasajero.pendiente,
    fueraDeRuta: false,
  );
}

String _formatElapsed(int seconds) {
  final m = (seconds ~/ 60).clamp(0, 999);
  final s = (seconds % 60).clamp(0, 59);
  return 'Tiempo en ruta: ${m}m ${s}s';
}
