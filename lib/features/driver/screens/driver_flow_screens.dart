import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/trip_simulation_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';

class DriverMonitorCargaScreen extends StatefulWidget {
  const DriverMonitorCargaScreen({
    super.key,
    this.onFullChanged,
    this.onGoToCommission,
    this.capacity = 15,
    this.initialFilled = 9,
    this.routeSession = 0,
  });

  final ValueChanged<bool>? onFullChanged;
  final VoidCallback? onGoToCommission;
  final int capacity;
  final int initialFilled;
  final int routeSession;

  @override
  State<DriverMonitorCargaScreen> createState() => _DriverMonitorCargaScreenState();
}

class _DriverMonitorCargaScreenState extends State<DriverMonitorCargaScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;
  late final int _capacity;
  late int _filled;
  bool _fullAlertShown = false;
  late int _routeSession;

  @override
  void initState() {
    super.initState();
    _capacity = widget.capacity;
    _filled = widget.initialFilled.clamp(0, _capacity);
    _routeSession = widget.routeSession;
    _trip.addListener(_onTripChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onFullChanged?.call(_filled >= _capacity);
    });
  }

  Future<void> _openQuickChat(DriverStop stop) async {
    final conversationId = 'chat|${stop.dni}|22222222';
    _trip.markChatRead(conversationId: conversationId, readerDni: '22222222');
    final displayName = _trip.profileOf(stop.dni).displayName;

    const phrases = [
      'Ya llegué',
      'Esperando',
      'Estoy en el paradero',
      'En 2 minutos llego',
    ];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: AnimatedBuilder(
            animation: _trip,
            builder: (context, _) {
              final messages = _trip.chatFor(conversationId);
              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Chat rápido • $displayName', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView(
                        shrinkWrap: true,
                        children: messages.map((m) {
                          final mine = m.fromDni == '22222222';
                          final bg = mine ? AppColors.primaryBlue.withOpacity(0.12) : Colors.grey.shade200;
                          final align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
                          final status = mine ? (m.readAt == null ? 'Enviado' : 'Leído') : '';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: align,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                                  child: Text(m.text),
                                ),
                                if (status.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(status, style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: phrases.map((p) {
                        return ActionChip(
                          label: Text(p),
                          onPressed: () {
                            final r = _trip.sendQuickChat(
                              conversationId: conversationId,
                              fromRole: 'Conductor',
                              fromDni: '22222222',
                              toDni: stop.dni,
                              text: p,
                            );
                            if (!r.ok) {
                              CustomSnackbar.show(context, message: r.message, isError: true);
                            } else {
                              CustomSnackbar.show(context, message: r.message, isSuccess: true);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _trip.removeListener(_onTripChanged);
    super.dispose();
  }

  void _onTripChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant DriverMonitorCargaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.routeSession != _routeSession) {
      _routeSession = widget.routeSession;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _filled = 0;
          _fullAlertShown = false;
        });
        widget.onFullChanged?.call(false);
      });
    }
  }

  Future<void> _requestExpress() async {
    if (_filled <= 0 || _filled >= _capacity) return;
    _trip.requestExpressDeparture(filledSeats: _filled);
    final empty = (_capacity - _filled).clamp(0, _capacity);

    final accepted = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Salida express'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Asientos vacíos: $empty'),
              const SizedBox(height: 8),
              Text('Costo vacíos: S/ ${_trip.expressEmptySeatsCost.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('Extra por pasajero: S/ ${_trip.expressExtraPerPassenger.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              const Text('¿Confirmar pago extra para autorizar salida incompleta?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('disagree'),
              child: const Text('Desacuerdo'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('confirm'),
              child: const Text('Confirmar pago'),
            ),
          ],
        );
      },
    );

    if (accepted == 'confirm') {
      _trip.confirmExpressDeparturePaid();
      CustomSnackbar.show(
        context,
        message: 'Salida express autorizada.',
        isSuccess: true,
      );
      return;
    }
    if (accepted == 'disagree') {
      _trip.cancelExpressDeparture(dueToDisagreement: true);
      CustomSnackbar.show(
        context,
        message: 'Salida express cancelada por desacuerdo.',
        isError: true,
      );
      return;
    }
    _trip.cancelExpressDeparture();
  }

  void _setFilled(int value) {
    final next = value.clamp(0, _capacity);
    setState(() {
      _filled = next;
    });
    widget.onFullChanged?.call(_filled >= _capacity);
    _maybeShowFullAlert();
  }

  void _goToCommission() {
    if (widget.onGoToCommission != null) {
      widget.onGoToCommission!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DriverManifestScreen(unlocked: true)),
    );
  }

  void _maybeShowFullAlert() {
    if (_filled < _capacity) {
      _fullAlertShown = false;
      return;
    }
    if (_fullAlertShown) return;
    _fullAlertShown = true;
    _trip.markVehicleFull(placa: _trip.assignedVehicle.placa, driverDni: '22222222');

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.energeticOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: AppColors.energeticOrange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Unidad completa',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'La unidad llegó al 100% de ocupación. Continúa con la liquidación de comisión para desbloquear la hoja de ruta.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Ver hoja de ruta',
                  onPressed: () {
                    Navigator.of(context).pop();
                    _goToCommission();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_filled / _capacity).clamp(0.0, 1.0);
    final isFull = _filled >= _capacity;
    final remaining = (_capacity - _filled).clamp(0, _capacity);
    final seats = List.generate(_capacity, (i) => i + 1);
    final canOpenRoute = isFull || _trip.expressAuthorized;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor de carga'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_trip.expressAuthorized)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.flash_on_rounded, color: AppColors.primaryBlue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Salida express autorizada. Extra por pasajero: S/ ${_trip.expressExtraPerPassenger.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: _trip.cancelExpressDeparture,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isFull
                      ? [
                          AppColors.energeticOrange.withOpacity(0.18),
                          AppColors.energeticOrange.withOpacity(0.06),
                        ]
                      : [
                          AppColors.primaryBlue.withOpacity(0.16),
                          AppColors.primaryBlue.withOpacity(0.04),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (isFull ? AppColors.energeticOrange : AppColors.primaryBlue).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isFull ? Icons.check_circle_rounded : Icons.timelapse_rounded,
                        color: isFull ? AppColors.energeticOrange : AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFull ? 'Unidad completa' : 'Cargando unidad',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isFull ? 'Puedes pagar la comisión y desbloquear hoja de ruta.' : 'Faltan $remaining pasajeros para completar.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(pct * 100).round()}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Ocupación', style: Theme.of(context).textTheme.titleMedium)),
                        Text(
                          '$_filled/$_capacity',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isFull ? AppColors.energeticOrange : AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth >= 560 ? 6 : 5;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: seats.map((seat) {
                            final isFilled = seat <= _filled;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isFilled ? AppColors.energeticOrange : AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isFilled ? AppColors.energeticOrange : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$seat',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: isFilled ? AppColors.white : AppColors.textSecondary,
                                      ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _setFilled(_filled - 1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.textPrimary,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('-1'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _setFilled(_filled + 1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('+1'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _setFilled(_capacity),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.energeticOrange,
                          foregroundColor: AppColors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Llenar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Ver hoja de ruta',
              onPressed: canOpenRoute ? _goToCommission : null,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: (!isFull && _filled > 0) ? _requestExpress : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.energeticOrange,
                foregroundColor: AppColors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Solicitar salida express'),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverCommissionScreen extends StatefulWidget {
  const DriverCommissionScreen({
    super.key,
    required this.completedRoutes,
    required this.commissionPerRoute,
    required this.daySettled,
    this.onDaySettledChanged,
  });

  final int completedRoutes;
  final double commissionPerRoute;
  final bool daySettled;
  final ValueChanged<bool>? onDaySettledChanged;

  @override
  State<DriverCommissionScreen> createState() => _DriverCommissionScreenState();
}

class _DriverCommissionScreenState extends State<DriverCommissionScreen> {
  bool _isProcessing = false;
  bool _hasPaymentError = false;
  String _method = 'Saldo';
  double _driverBalance = 35.00;
  double get _totalAmount => widget.completedRoutes * widget.commissionPerRoute;

  Future<void> _payDigital() async {
    if (_isProcessing || widget.daySettled) return;
    if (widget.completedRoutes <= 0) return;

    if (_method == 'Saldo') {
      if (_driverBalance < _totalAmount) {
        CustomSnackbar.show(
          context,
          message: 'Saldo insuficiente. Use pago QR o validación por el dueño.',
          isError: true,
        );
        return;
      }
      setState(() {
        _isProcessing = true;
      });
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        _driverBalance -= _totalAmount;
        _isProcessing = false;
        _hasPaymentError = false;
      });
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.heavyImpact();
      widget.onDaySettledChanged?.call(true);
      CustomSnackbar.show(
        context,
        message: 'Cierre del día pagado.',
        isSuccess: true,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (!_hasPaymentError) {
      setState(() {
        _isProcessing = false;
        _hasPaymentError = true;
      });
      CustomSnackbar.show(
        context,
        message: 'Error en pago digital. Puedes solicitar validación por el dueño.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isProcessing = false;
      _hasPaymentError = false;
    });
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.heavyImpact();
    widget.onDaySettledChanged?.call(true);
    CustomSnackbar.show(
      context,
      message: 'Cierre del día confirmado.',
      isSuccess: true,
    );
  }

  void _requestOnsite() {
    if (_isProcessing || widget.daySettled) return;
    CustomSnackbar.show(
      context,
      message: 'Solicitud enviada a auditoría (demo)',
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = TripSimulationService.instance;
    final kmDriverToday = trip.dailyKmForDriver('22222222');
    final kmVehicleToday = trip.dailyKmForPlaca(trip.assignedVehicle.placa);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cierre del día'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (widget.daySettled
                                ? AppColors.success
                                : (_hasPaymentError ? AppColors.error : AppColors.warning))
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        widget.daySettled
                            ? Icons.check_circle_rounded
                            : (_hasPaymentError ? Icons.error_rounded : Icons.warning_amber_rounded),
                        color: widget.daySettled
                            ? AppColors.success
                            : (_hasPaymentError ? AppColors.error : AppColors.warning),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.daySettled
                                ? 'Cierre pagado'
                                : (_hasPaymentError ? 'Pago rechazado' : 'Pendiente de pago'),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.daySettled
                                ? 'Se registró el pago del día.'
                                : 'Se calcula según las rutas completadas.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'S/ ${_totalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.route_rounded, color: AppColors.primaryBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kilometraje del día',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Conductor: ${kmDriverToday.toStringAsFixed(1)} km • Unidad: ${kmVehicleToday.toStringAsFixed(1)} km',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${trip.routeDistanceKm.toStringAsFixed(1)} km',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.route_rounded, color: AppColors.primaryBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rutas completadas',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.completedRoutes} rutas • S/ ${widget.commissionPerRoute.toStringAsFixed(2)} por ruta',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${widget.completedRoutes}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Método de pago', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ChoiceChip(
                  label: Text('Saldo (S/ ${_driverBalance.toStringAsFixed(2)})'),
                  selected: _method == 'Saldo',
                  onSelected: widget.daySettled || _isProcessing
                      ? null
                      : (_) {
                          setState(() {
                            _method = 'Saldo';
                            _hasPaymentError = false;
                          });
                        },
                  selectedColor: AppColors.primaryBlue.withOpacity(0.12),
                  backgroundColor: AppColors.white,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _method == 'Saldo' ? AppColors.primaryBlue : AppColors.textPrimary,
                  ),
                  side: BorderSide(
                    color: _method == 'Saldo' ? AppColors.primaryBlue : Colors.grey.shade300,
                  ),
                ),
                ChoiceChip(
                  label: const Text('QR (Yape/Plin)'),
                  selected: _method == 'QR',
                  onSelected: widget.daySettled || _isProcessing
                      ? null
                      : (_) {
                          setState(() {
                            _method = 'QR';
                          });
                        },
                  selectedColor: AppColors.primaryBlue.withOpacity(0.12),
                  backgroundColor: AppColors.white,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _method == 'QR' ? AppColors.primaryBlue : AppColors.textPrimary,
                  ),
                  side: BorderSide(
                    color: _method == 'QR' ? AppColors.primaryBlue : Colors.grey.shade300,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_method == 'QR')
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceGrey,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Center(
                          child: Icon(Icons.qr_code_2_rounded, size: 110, color: AppColors.primaryBlue),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Escanea el QR para pagar el cierre del día.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (widget.completedRoutes <= 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.info_outline, color: AppColors.warning),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Aún no hay rutas finalizadas para cerrar el día.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_isProcessing)
              const Center(child: BrandLoadingPanel(message: 'Procesando cierre...'))
            else
              CustomButton(
                text: widget.daySettled ? 'Cierre registrado' : 'Pagar cierre del día',
                onPressed: widget.daySettled ? null : _payDigital,
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _hasPaymentError && !widget.daySettled ? _requestOnsite : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.energeticOrange,
                foregroundColor: AppColors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Validación por el dueño'),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverManifestScreen extends StatefulWidget {
  const DriverManifestScreen({super.key, this.unlocked = true, this.onRouteCompleted});

  final bool unlocked;
  final VoidCallback? onRouteCompleted;

  @override
  State<DriverManifestScreen> createState() => _DriverManifestScreenState();
}

class _DriverManifestScreenState extends State<DriverManifestScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;
  bool _locationEnabled = true;
  bool _audioEnabled = true;
  bool _voiceListening = false;
  bool _routeStarted = false;
  bool _noiseMode = false;
  bool _finalizePromptShown = false;
  DateTime? _lastPaymentSeenAt;
  bool _panicHolding = false;
  double _panicProgress = 0;
  Timer? _panicTimer;
  final TextEditingController _qrController = TextEditingController();
  final TextEditingController _incidentController = TextEditingController();
  final TextEditingController _expenseAmountController = TextEditingController();
  String _expenseMotive = 'Peaje';
  bool _expenseHasVoucher = false;
  final Set<String> _promptedStops = {};
  final Map<String, DateTime> _nearStopSince = {};
  late final Map<String, String> _statusByDni;
  final Map<String, int> _seatByDni = const {
    '70123456': 2,
    '70999888': 5,
    '71222333': 9,
  };
  late final Map<int, String> _dniBySeat;

  SystemSoundType? _selectedToneType() {
    final tone = _trip.alertTone('22222222');
    switch (tone) {
      case 'Click':
        return SystemSoundType.click;
      case 'Alerta':
        return SystemSoundType.alert;
      case 'Silencio':
        return null;
      default:
        return SystemSoundType.alert;
    }
  }

  void _playTone() {
    final type = _selectedToneType();
    if (type == null) return;
    SystemSound.play(type);
  }

  void _applyAutoNightIfEnabled() {
    if (!_trip.autoNightModeEnabled('22222222')) return;
    final hour = DateTime.now().hour;
    final shouldDark = hour >= 18 || hour < 6;
    AppTheme.themeMode.value = shouldDark ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  void initState() {
    super.initState();
    _statusByDni = {for (final s in _trip.driverStops) s.dni: 'Pendiente'};
    _dniBySeat = {for (final e in _seatByDni.entries) e.value: e.key};
    _lastPaymentSeenAt = _trip.lastPaymentAt;
    _trip.addListener(_onTripChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyAutoNightIfEnabled());
  }

  @override
  void dispose() {
    _panicTimer?.cancel();
    _qrController.dispose();
    _incidentController.dispose();
    _expenseAmountController.dispose();
    _trip.removeListener(_onTripChanged);
    super.dispose();
  }

  void _onTripChanged() {
    if (!mounted) return;
    _applyAutoNightIfEnabled();
    final payAt = _trip.lastPaymentAt;
    if (payAt != null && payAt != _lastPaymentSeenAt) {
      _lastPaymentSeenAt = payAt;
      if (_audioEnabled) {
        SemanticsService.announce('Pago recibido', TextDirection.ltr);
        SystemSound.play(SystemSoundType.alert);
      } else {
        HapticFeedback.heavyImpact();
      }
      CustomSnackbar.show(
        context,
        message: 'Pago recibido: S/ ${_trip.lastPaymentAmount.toStringAsFixed(2)}',
        isSuccess: true,
      );
    }
    for (final s in _trip.driverStops) {
      _statusByDni.putIfAbsent(s.dni, () => 'Pendiente');
    }
    if (_routeStarted) {
      _maybePromptNextPickup();
    }
    final next = _nextStop();
    if (_routeStarted && next != null) {
      final dist = _trip.distanceMeters(_trip.vehicleMeters, next.positionMeters);
      if (dist <= 500) {
        _nearStopSince.putIfAbsent(next.dni, () => DateTime.now());
      } else {
        _nearStopSince.remove(next.dni);
      }
    }
    if (_trip.arrivedAtFinalStop && _routeStarted && !_finalizePromptShown && !_trip.autoClosed) {
      _finalizePromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _promptFinalize();
      });
    }
    if (_trip.autoClosed && _routeStarted) {
      _routeStarted = false;
    }
    setState(() {});
  }

  DriverStop? _nextStop() {
    for (final s in _trip.driverStops) {
      final status = _statusByDni[s.dni];
      if (status != 'Abordado' && status != 'No-show') return s;
    }
    return null;
  }

  Future<void> _promptFinalize() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Terminal alcanzado'),
          content: const Text('¿Finalizar servicio y marcar la unidad como Disponible?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Aún no')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Finalizar')),
          ],
        );
      },
    );
    if (ok != true) return;
    _trip.unitStatus = 'Disponible';
    _trip.stop();
    _trip.finalizeTripsForPlaca(placa: _trip.assignedVehicle.placa);
    _trip.finalizeRouteSession(placa: _trip.assignedVehicle.placa, driverDni: '22222222');
    setState(() {
      _routeStarted = false;
    });
    CustomSnackbar.show(
      context,
      message: 'Viaje finalizado. Unidad disponible.',
      isSuccess: true,
    );
  }

  void _maybePromptNextPickup() {
    final next = _nextStop();
    if (next == null) return;
    if (_promptedStops.contains(next.dni)) return;
    if (!_trip.driverStopGeofenceFired.contains(next.dni)) return;

    _promptedStops.add(next.dni);
    final text = 'Recoger a ${next.passengerName} en ${next.stopName}';
    if (_audioEnabled) {
      SemanticsService.announce(text, TextDirection.ltr);
      _playTone();
    } else {
      HapticFeedback.vibrate();
      CustomSnackbar.show(
        context,
        message: text,
        isSuccess: true,
      );
    }
  }

  void _toggleRoute() {
    if (!_routeStarted) {
      if (!_locationEnabled) {
        CustomSnackbar.show(
          context,
          message: 'Ubicación desactivada. Actívala para iniciar la ruta.',
          isError: true,
        );
        return;
      }
      _trip.resetTrip();
      _trip.unitStatus = 'En ruta';
      _trip.start();
      _trip.markDeparture(placa: _trip.assignedVehicle.placa, driverDni: '22222222');
      setState(() {
        _routeStarted = true;
      });
      CustomSnackbar.show(
        context,
        message: 'Ruta iniciada. GPS registrando cada 5s (demo).',
        isSuccess: true,
      );
      return;
    }

    _trip.stop();
    setState(() {
      _routeStarted = false;
    });
    CustomSnackbar.show(
      context,
      message: 'Ruta detenida.',
      isSuccess: true,
    );
  }

  void _toggleOnline(bool v) {
    _trip.setOnline(v);
    CustomSnackbar.show(
      context,
      message: v ? 'Conectado. Sincronización completada.' : 'Sin conexión. Guardando en caché.',
      isSuccess: v,
      isError: !v,
    );
  }

  Future<void> _pickAlertTone() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Tono de alerta', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...['Alerta', 'Click', 'Silencio'].map((tone) {
                  final selected = _trip.alertTone('22222222') == tone;
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
                      title: Text(tone),
                      trailing: IconButton(
                        icon: const Icon(Icons.volume_up_rounded),
                        onPressed: () {
                          _trip.setAlertTone(driverDni: '22222222', tone: tone);
                          _playTone();
                        },
                      ),
                      onTap: () {
                        _trip.setAlertTone(driverDni: '22222222', tone: tone);
                        Navigator.of(context).pop();
                        CustomSnackbar.show(context, message: 'Tono actualizado', isSuccess: true);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickVoiceProfile() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Voz del asistente (TTS demo)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...['Femenino', 'Masculino'].map((profile) {
                  final selected = _trip.voiceProfile('22222222') == profile;
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
                      title: Text(profile),
                      trailing: IconButton(
                        icon: const Icon(Icons.record_voice_over_rounded),
                        onPressed: () {
                          _trip.setVoiceProfile(driverDni: '22222222', profile: profile);
                          SemanticsService.announce('Voz $profile activada', TextDirection.ltr);
                        },
                      ),
                      onTap: () {
                        _trip.setVoiceProfile(driverDni: '22222222', profile: profile);
                        Navigator.of(context).pop();
                        CustomSnackbar.show(context, message: 'Voz actualizada', isSuccess: true);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openQuickChat(DriverStop stop) async {
    final conversationId = 'chat|${stop.dni}|22222222';
    _trip.markChatRead(conversationId: conversationId, readerDni: '22222222');
    final displayName = _trip.profileOf(stop.dni).displayName;

    const phrases = [
      'Ya llegué',
      'Esperando',
      'Estoy en el paradero',
      'En 2 minutos llego',
    ];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: AnimatedBuilder(
            animation: _trip,
            builder: (context, _) {
              final messages = _trip.chatFor(conversationId);
              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Chat rápido • $displayName', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView(
                        shrinkWrap: true,
                        children: messages.map((m) {
                          final mine = m.fromDni == '22222222';
                          final bg = mine ? AppColors.primaryBlue.withOpacity(0.12) : Colors.grey.shade200;
                          final align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
                          final status = mine ? (m.readAt == null ? 'Enviado' : 'Leído') : '';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: align,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                                  child: Text(m.text),
                                ),
                                if (status.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(status, style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: phrases.map((p) {
                        return ActionChip(
                          label: Text(p),
                          onPressed: () {
                            final r = _trip.sendQuickChat(
                              conversationId: conversationId,
                              fromRole: 'Conductor',
                              fromDni: '22222222',
                              toDni: stop.dni,
                              text: p,
                            );
                            if (!r.ok) {
                              CustomSnackbar.show(context, message: r.message, isError: true);
                            } else {
                              CustomSnackbar.show(context, message: r.message, isSuccess: true);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _validateQr() {
    final raw = _qrController.text.trim();
    final result = _trip.validateTicket(raw);
    if (!result.ok) {
      CustomSnackbar.show(context, message: result.message, isError: true);
      return;
    }
    final ticket = result.ticket;
    if (ticket == null) return;
    String? dni;
    final parts = raw.split('|');
    if (parts.length >= 4 && parts.first == 'SDAG') {
      dni = parts[2];
    }
    final dniValue = dni;
    if (dniValue != null) {
      setState(() {
        _statusByDni[dniValue] = 'Validado';
      });
      final stop = _trip.driverStops.where((s) => s.dni == dniValue).toList();
      if (stop.isNotEmpty) {
        _trip.recordStopBoarding(stopName: stop.first.stopName);
      }
    }
    CustomSnackbar.show(context, message: result.message, isSuccess: true);
  }

  Future<void> _openExpenseSheet() async {
    _expenseAmountController.clear();
    _expenseMotive = 'Peaje';
    _expenseHasVoucher = false;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setLocalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Gasto rápido', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _expenseAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixText: 'S/ ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Motivo', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Peaje', 'Combustible', 'Reparación', 'Otro'].map((m) {
                      final selected = _expenseMotive == m;
                      return ChoiceChip(
                        label: Text(m),
                        selected: selected,
                        onSelected: (_) => setLocalState(() => _expenseMotive = m),
                        selectedColor: AppColors.primaryBlue.withOpacity(0.12),
                        backgroundColor: AppColors.white,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected ? AppColors.primaryBlue : AppColors.textPrimary,
                        ),
                        side: BorderSide(
                          color: selected ? AppColors.primaryBlue : Colors.grey.shade300,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _expenseHasVoucher,
                    onChanged: (v) => setLocalState(() => _expenseHasVoucher = v),
                    title: const Text('Adjuntar voucher (demo)'),
                    subtitle: const Text('Simula foto del comprobante'),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Guardar gasto',
                    onPressed: () {
                      final raw = _expenseAmountController.text.trim().replaceAll(',', '.');
                      final amount = double.tryParse(raw) ?? 0;
                      if (amount <= 0) {
                        CustomSnackbar.show(
                          context,
                          message: 'Monto inválido',
                          isError: true,
                        );
                        return;
                      }
                      _trip.addExpense(
                        amount: amount,
                        motive: _expenseMotive,
                        hasVoucher: _expenseHasVoucher,
                        placa: 'BJK-102',
                        driverDni: '22222222',
                      );
                      Navigator.of(context).pop();
                      CustomSnackbar.show(
                        this.context,
                        message: _trip.isOnline ? 'Gasto registrado' : 'Gasto guardado offline',
                        isSuccess: true,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openIncidentDialog() async {
    var kind = 'Tráfico';
    _incidentController.clear();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Reportar incidencia'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButton<String>(
                    value: kind,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Tráfico', child: Text('Tráfico')),
                      DropdownMenuItem(value: 'Retraso', child: Text('Retraso')),
                      DropdownMenuItem(value: 'Avería', child: Text('Avería')),
                      DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                    ],
                    onChanged: (v) => setLocalState(() => kind = v ?? 'Tráfico'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _incidentController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      hintText: 'Ej: tráfico pesado en km 12',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Guardar')),
              ],
            );
          },
        );
      },
    );
    if (ok != true) return;

    _trip.addIncident(
      kind: kind,
      description: _incidentController.text.trim(),
      placa: 'BJK-102',
      driverDni: '22222222',
    );
    CustomSnackbar.show(
      context,
      message: _trip.isOnline ? 'Incidencia registrada' : 'Incidencia guardada offline',
      isSuccess: true,
    );
  }

  void _arriveBase() {
    _trip.arriveAtBase(driverDni: '22222222');
    final pos = _trip.queuePosition(driverDni: '22222222');
    CustomSnackbar.show(
      context,
      message: pos == 1 ? 'Estás #1 en la cola' : 'Llegada registrada. Posición: #$pos',
      isSuccess: true,
    );
  }

  void _leaveBase() {
    _trip.leaveBase(driverDni: '22222222');
    CustomSnackbar.show(
      context,
      message: 'Saliste de la cola de base',
      isError: true,
    );
  }

  void _markBoarded(DriverStop stop) {
    setState(() {
      _statusByDni[stop.dni] = 'Abordado';
    });
    _trip.recordStopBoarding(stopName: stop.stopName);
    CustomSnackbar.show(
      context,
      message: '${stop.passengerName} marcado como abordado.',
      isSuccess: true,
    );
  }

  void _markNoShow(DriverStop stop) {
    setState(() {
      _statusByDni[stop.dni] = 'No-show';
    });
    final seat = _seatByDni[stop.dni];
    if (seat != null) {
      _trip.releaseSeat(seat);
    }
    CustomSnackbar.show(
      context,
      message: 'No-show registrado. Asiento ${seat ?? '-'} liberado.',
      isSuccess: true,
    );
  }

  void _undoNoShow(DriverStop stop) {
    setState(() {
      _statusByDni[stop.dni] = 'Pendiente';
    });
    final seat = _seatByDni[stop.dni];
    if (seat != null) {
      _trip.restoreSeat(seat);
    }
    CustomSnackbar.show(
      context,
      message: 'No-show revertido.',
      isSuccess: true,
    );
  }

  Future<void> _voiceCommandAbordado() async {
    final next = _nextStop();
    if (next == null) {
      CustomSnackbar.show(
        context,
        message: 'No hay pasajeros pendientes.',
        isError: true,
      );
      return;
    }

    if (_noiseMode) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Ruido alto detectado'),
            content: const Text('Confirma manualmente el abordaje.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmar')),
            ],
          );
        },
      );
      if (ok != true) return;
    }

    _markBoarded(next);
  }

  void _startPanicHold() {
    if (_panicHolding) return;
    setState(() {
      _panicHolding = true;
      _panicProgress = 0;
    });
    _panicTimer?.cancel();
    _panicTimer = Timer.periodic(const Duration(milliseconds: 50), (t) async {
      if (!mounted) return;
      final next = _panicProgress + (50 / 3000);
      if (next >= 1) {
        t.cancel();
        _panicTimer = null;
        setState(() {
          _panicProgress = 1;
          _panicHolding = false;
        });
        await _triggerPanic();
        return;
      }
      setState(() {
        _panicProgress = next;
      });
    });
  }

  void _cancelPanicHold() {
    _panicTimer?.cancel();
    _panicTimer = null;
    if (!_panicHolding && _panicProgress == 0) return;
    setState(() {
      _panicHolding = false;
      _panicProgress = 0;
    });
  }

  Future<void> _triggerPanic() async {
    _trip.activateEmergency(role: 'Conductor', sourceDni: '22222222');
    _playTone();

    final TextEditingController codeController = TextEditingController();
    var secondsLeft = 5;
    Timer? timer;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (secondsLeft <= 1) {
                t.cancel();
                Navigator.of(context).pop();
                return;
              }
              setLocalState(() {
                secondsLeft -= 1;
              });
            });

            return AlertDialog(
              title: const Text('SOS activado'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Puedes cancelar en $secondsLeft s con el código de seguridad.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Código',
                      hintText: 'Ej: 1234',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (codeController.text.trim() == '1234') {
                      _trip.clearEmergency();
                      timer?.cancel();
                      Navigator.of(context).pop();
                      return;
                    }
                    CustomSnackbar.show(
                      this.context,
                      message: 'Código incorrecto',
                      isError: true,
                    );
                  },
                  child: const Text('Cancelar SOS'),
                ),
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Continuar'),
                ),
              ],
            );
          },
        );
      },
    );

    timer?.cancel();
  }

  void _finishRoute() {
    _trip.stop();
    _trip.unitStatus = 'Disponible';
    _trip.finalizeRouteSession(placa: _trip.assignedVehicle.placa, driverDni: '22222222');
    if (widget.onRouteCompleted != null) {
      widget.onRouteCompleted!();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.unlocked) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manifiesto electrónico'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.energeticOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.lock_rounded, color: AppColors.energeticOrange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hoja de ruta bloqueada. La unidad debe estar completa.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final next = _nextStop();
    final nextDistance = next == null ? null : _trip.distanceMeters(_trip.vehicleMeters, next.positionMeters);
    final gpsPoints = _trip.gpsLogMeters.length;
    final deviationAlert = _trip.deviationMeters > 200 && !_trip.deviationJustified;
    final lastSpeed = _trip.lastSpeedKmh;
    final waitedAt = next == null ? null : _nearStopSince[next.dni];
    final waitedOk = waitedAt != null && DateTime.now().difference(waitedAt) >= const Duration(minutes: 2);
    final canNoShow = _routeStarted && next != null && nextDistance != null && nextDistance <= 500 && waitedOk;
    final queuePos = _trip.queuePosition(driverDni: '22222222');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manifiesto electrónico'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_trip.activeEmergency != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.sos_rounded, color: AppColors.error),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'SOS activo. Ubicación enviada a la central (demo).',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: _trip.clearEmergency,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Lima → Chosica',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (_trip.isRunning ? AppColors.success : AppColors.warning).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _trip.isRunning ? 'En ruta' : 'Detenido',
                            style: TextStyle(
                              color: _trip.isRunning ? AppColors.success : AppColors.warning,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(icon: Icons.gps_fixed_rounded, text: 'GPS: $gpsPoints puntos'),
                        if (next != null) _InfoChip(icon: Icons.place_rounded, text: 'Próximo: ${next.stopName}'),
                        if (nextDistance != null) _InfoChip(icon: Icons.social_distance_rounded, text: '${nextDistance.round()} m'),
                        _InfoChip(icon: Icons.speed_rounded, text: '${lastSpeed.toStringAsFixed(0)} km/h'),
                        _InfoChip(icon: Icons.cloud_rounded, text: '${_trip.weather.condition} ${_trip.weather.temperatureC}°C'),
                        if (_trip.expressAuthorized) const _InfoChip(icon: Icons.flash_on_rounded, text: 'Express'),
                        if (!_trip.isOnline) _InfoChip(icon: Icons.wifi_off_rounded, text: 'Offline ${_trip.pendingSyncCount}'),
                        if (_trip.dataSaverEnabled('22222222')) const _InfoChip(icon: Icons.data_saver_on_rounded, text: 'Ahorro datos'),
                      ],
                    ),
                    if (deviationAlert) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.energeticOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.energeticOrange.withOpacity(0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.energeticOrange),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Alerta: desvío detectado (${_trip.deviationMeters.toStringAsFixed(0)} m)',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _trip.setDeviationJustified(true),
                              child: const Text('Justificar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: _routeStarted ? 'Detener ruta' : 'Iniciar ruta',
                            onPressed: _toggleRoute,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: _locationEnabled,
                    onChanged: (v) => setState(() => _locationEnabled = v),
                    title: const Text('Ubicación activa'),
                    subtitle: const Text('Requerido para iniciar ruta (demo)'),
                    secondary: const Icon(Icons.location_on_rounded),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _audioEnabled,
                    onChanged: (v) => setState(() => _audioEnabled = v),
                    title: const Text('Copiloto por voz (TTS demo)'),
                    subtitle: Text(_audioEnabled ? 'Audio activado' : 'Audio desactivado (vibración)'),
                    secondary: const Icon(Icons.volume_up_rounded),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _voiceListening,
                    onChanged: (v) => setState(() => _voiceListening = v),
                    title: const Text('Escucha de voz (STT demo)'),
                    subtitle: const Text('Comando: "Abordado"'),
                    secondary: const Icon(Icons.mic_rounded),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _noiseMode,
                    onChanged: (v) => setState(() => _noiseMode = v),
                    title: const Text('Ruido ambiental alto'),
                    subtitle: const Text('Solicita confirmación manual'),
                    secondary: const Icon(Icons.noise_aware_rounded),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _trip.simulateDeviation,
                    onChanged: (v) {
                      setState(() {});
                      _trip.simulateDeviation = v;
                      if (!v) _trip.setDeviationJustified(false);
                      _trip.notifyListeners();
                    },
                    title: const Text('Simular desvío (demo)'),
                    subtitle: const Text('Genera alerta al dueño'),
                    secondary: const Icon(Icons.alt_route_rounded),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _trip.trafficHeavy,
                    onChanged: (v) {
                      setState(() {});
                      _trip.trafficHeavy = v;
                      _trip.notifyListeners();
                    },
                    title: const Text('Tráfico pesado (demo)'),
                    subtitle: const Text('Ajusta puntualidad para el reporte mensual'),
                    secondary: const Icon(Icons.traffic_rounded),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _trip.autoNightModeEnabled('22222222'),
                    onChanged: (v) {
                      _trip.setAutoNightMode(driverDni: '22222222', enabled: v);
                      _applyAutoNightIfEnabled();
                      setState(() {});
                    },
                    title: const Text('Modo nocturno automático'),
                    subtitle: const Text('Se activa al anochecer (demo)'),
                    secondary: const Icon(Icons.dark_mode_rounded),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _trip.dataSaverEnabled('22222222'),
                    onChanged: (v) {
                      _trip.setDataSaverEnabled(driverDni: '22222222', enabled: v);
                      setState(() {});
                      CustomSnackbar.show(
                        context,
                        message: v ? 'Ahorro de datos activado' : 'Ahorro de datos desactivado',
                        isSuccess: true,
                      );
                    },
                    title: const Text('Ahorro de datos'),
                    subtitle: const Text('Reduce frecuencia de actualización (demo)'),
                    secondary: const Icon(Icons.data_saver_on_rounded),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_active_rounded),
                    title: const Text('Tono de alerta'),
                    subtitle: Text(_trip.alertTone('22222222')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickAlertTone,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.record_voice_over_rounded),
                    title: const Text('Voz del asistente'),
                    subtitle: Text(_trip.voiceProfile('22222222')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickVoiceProfile,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.support_agent_rounded),
                    title: const Text('Soporte técnico'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const DriverSupportFeedbackScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _trip.isOnline,
                    onChanged: _toggleOnline,
                    title: const Text('Conectividad'),
                    subtitle: Text(
                      _trip.isOnline
                          ? 'En línea • ${_trip.pendingSyncCount} pendientes'
                          : 'Sin señal • ${_trip.pendingSyncCount} en caché',
                    ),
                    secondary: Icon(_trip.isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Parada técnica', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Text(
                      _trip.isEmergencyStopActive
                          ? 'Activa • ${_trip.emergencyStopElapsed.inMinutes}m ${_trip.emergencyStopElapsed.inSeconds % 60}s'
                          : 'Sin paradas registradas en este momento.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: _trip.isEmergencyStopActive ? 'Finalizar parada' : 'Iniciar parada',
                            onPressed: !_routeStarted
                                ? null
                                : () {
                                    if (_trip.isEmergencyStopActive) {
                                      _trip.endEmergencyStop();
                                      CustomSnackbar.show(context, message: 'Parada registrada', isSuccess: true);
                                      return;
                                    }
                                    _trip.startEmergencyStop(
                                      placa: _trip.assignedVehicle.placa,
                                      driverDni: '22222222',
                                      note: 'Parada técnica',
                                    );
                                    CustomSnackbar.show(context, message: 'Parada iniciada. Aviso enviado al pasajero.', isSuccess: true);
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _trip.isEmergencyStopActive ? null : (!_routeStarted ? null : _openIncidentDialog),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.energeticOrange,
                              foregroundColor: AppColors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Reportar motivo'),
                          ),
                        ),
                      ],
                    ),
                    if (_trip.isEmergencyStopActive && _trip.emergencyStopElapsed >= const Duration(minutes: 15)) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Advertencia: parada > 15 min. El dueño será alertado (demo).',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Verificación de abordaje (QR)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _qrController,
                      decoration: const InputDecoration(
                        labelText: 'Pegar código QR (demo)',
                        prefixIcon: Icon(Icons.qr_code_scanner_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Validar ticket',
                      onPressed: _validateQr,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Gastos rápidos', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    if (_trip.expenses.isEmpty)
                      Text('Sin gastos registrados.', style: Theme.of(context).textTheme.bodyMedium)
                    else
                      ..._trip.expenses.reversed.take(3).map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text('S/ ${e.amount.toStringAsFixed(2)} • ${e.motive}${e.hasVoucher ? ' • Voucher' : ''}'),
                        );
                      }),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Registrar gasto',
                      onPressed: _openExpenseSheet,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Incidencias operativas', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    if (_trip.incidents.isEmpty)
                      Text('Sin incidencias registradas.', style: Theme.of(context).textTheme.bodyMedium)
                    else
                      ..._trip.incidents.reversed.take(3).map((i) {
                        final count = i.count > 1 ? ' • x${i.count}' : '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text('${i.kind}$count • ${i.description.isEmpty ? 'Sin detalle' : i.description}'),
                        );
                      }),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Reportar incidencia',
                      onPressed: _openIncidentDialog,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Turno (cochera)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Text(
                      queuePos > 0 ? 'Tu posición en cola: #$queuePos' : 'Aún no estás en la cola.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Llegada a base',
                            onPressed: _arriveBase,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: queuePos > 0 ? _leaveBase : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.energeticOrange,
                              foregroundColor: AppColors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Salir de cola'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Pasajeros', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ..._trip.driverStops.asMap().entries.expand((e) {
              final index = e.key;
              final s = e.value;
              final status = _statusByDni[s.dni] ?? 'Pendiente';
              final boarded = status == 'Abordado';
              final noShow = status == 'No-show';
              final validated = status == 'Validado';
              final isNext = next?.dni == s.dni;
              final dist = _trip.distanceMeters(_trip.vehicleMeters, s.positionMeters).round();
              final bookedSeats = _trip.seatsForPassenger(s.dni);
              final seat = bookedSeats.isEmpty ? _seatByDni[s.dni] : null;
              final seatLabel = bookedSeats.isEmpty ? (seat?.toString() ?? '-') : bookedSeats.join(',');
              final displayName = _trip.profileOf(s.dni).displayName;
              return [
                if (index > 0) const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (boarded
                                ? AppColors.success
                                : (noShow ? AppColors.error : (validated ? AppColors.energeticOrange : AppColors.primaryBlue)))
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        boarded
                            ? Icons.check_rounded
                            : (noShow ? Icons.person_off_rounded : (validated ? Icons.verified_rounded : Icons.person_rounded)),
                        color: boarded
                            ? AppColors.success
                            : (noShow ? AppColors.error : (validated ? AppColors.energeticOrange : AppColors.primaryBlue)),
                      ),
                    ),
                    title: Text('$displayName • DNI ${s.dni}'),
                    subtitle: Text(
                      '${s.stopName}${isNext ? ' • Próximo' : ''}\n'
                      'Asiento: $seatLabel • Estado: $status • Distancia: ${_trip.isRunning ? '$dist m' : '-'}',
                    ),
                    isThreeLine: true,
                    trailing: boarded
                        ? Wrap(
                            spacing: 4,
                            children: [
                              const Icon(Icons.verified_rounded, color: AppColors.success),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline_rounded),
                                onPressed: () => _openQuickChat(s),
                              ),
                            ],
                          )
                        : (noShow
                            ? IconButton(
                                icon: const Icon(Icons.undo_rounded),
                                onPressed: () => _undoNoShow(s),
                              )
                            : Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                                    onPressed: () => _openQuickChat(s),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.how_to_reg_rounded),
                                    onPressed: () => _markBoarded(s),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.person_off_rounded),
                                    onPressed: (isNext && canNoShow) ? () => _markNoShow(s) : null,
                                  ),
                                ],
                              )),
                  ),
                ),
              ];
            }).toList(),
            const SizedBox(height: 12),
            if (_voiceListening)
              CustomButton(
                text: 'Comando: "Abordado"',
                onPressed: _voiceCommandAbordado,
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Activa la escucha de voz para marcar abordaje por comando (demo).',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Emergencia', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTapDown: (_) => _startPanicHold(),
                      onTapUp: (_) => _cancelPanicHold(),
                      onTapCancel: _cancelPanicHold,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.error.withOpacity(0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.sos_rounded, color: AppColors.error),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _panicHolding ? 'Mantén presionado...' : 'Mantén 3s para activar SOS',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: _panicHolding ? _panicProgress : 0,
                                minHeight: 8,
                                backgroundColor: AppColors.white,
                                valueColor: const AlwaysStoppedAnimation(AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Finalizar ruta',
              onPressed: _finishRoute,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class DriverLowBatteryAlertScreen extends StatelessWidget {
  const DriverLowBatteryAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerta de batería baja'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.energeticOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.battery_alert_rounded, color: AppColors.energeticOrange, size: 40),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Batería baja',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Conecta el cargador para evitar interrupciones durante la operación.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Entendido',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DriverSupportFeedbackScreen extends StatefulWidget {
  const DriverSupportFeedbackScreen({super.key});

  @override
  State<DriverSupportFeedbackScreen> createState() => _DriverSupportFeedbackScreenState();
}

class _DriverSupportFeedbackScreenState extends State<DriverSupportFeedbackScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final msg = _controller.text.trim();
    if (msg.isEmpty) {
      CustomSnackbar.show(context, message: 'Escribe un mensaje', isError: true);
      return;
    }
    final dni = _trip.currentSessionDni.isEmpty ? '22222222' : _trip.currentSessionDni;
    final role = _trip.currentSessionRole.isEmpty ? 'Conductor' : _trip.currentSessionRole;
    final entry = _trip.submitSupportFeedback(fromDni: dni, fromRole: role, message: msg, deviceModel: 'Web', appVersion: '1.0.0');
    _controller.clear();
    CustomSnackbar.show(
      context,
      message: entry.sent ? 'Enviado a soporte' : 'Guardado sin conexión. Se enviará al volver internet.',
      isSuccess: true,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soporte técnico'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _trip,
          builder: (context, _) {
            final dni = _trip.currentSessionDni.isEmpty ? '22222222' : _trip.currentSessionDni;
            final items = _trip.supportFeedback.where((e) => e.fromDni == dni).toList()..sort((a, b) => b.at.compareTo(a.at));
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Enviar reporte', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            labelText: 'Describe el problema o sugerencia',
                            prefixIcon: Icon(Icons.support_agent_rounded),
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(icon: Icons.wifi_rounded, text: _trip.isOnline ? 'Online' : 'Offline'),
                            const _InfoChip(icon: Icons.info_outline_rounded, text: 'Adjunta log (demo)'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Enviar',
                          onPressed: _send,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Historial', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                if (items.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Sin reportes.', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  )
                else
                  ...items.take(20).map((e) {
                    final color = e.sent ? AppColors.success : AppColors.warning;
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                          child: Icon(e.sent ? Icons.check_rounded : Icons.schedule_rounded, color: color),
                        ),
                        title: Text(e.message, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${e.at} • ${e.sent ? 'Enviado' : 'Pendiente'}'),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}
