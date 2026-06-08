import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/providers/passenger/controllers/passenger_session_controller.dart';
import '../../../core/mock/mock_data.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/reserva_provider.dart';

enum _PaymentOption { saved, yape, card }

class PagoScreen extends ConsumerStatefulWidget {
  const PagoScreen({super.key});

  @override
  ConsumerState<PagoScreen> createState() => _PagoScreenState();
}

class _PagoScreenState extends ConsumerState<PagoScreen> {
  static const _prefsTypeKey = 'sdag_payment_type';
  static const _prefsLast4Key = 'sdag_payment_last4';

  final _yapeController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  bool _saveForFuture = false;
  bool _paying = false;
  _PaymentOption? _selectedOption;

  String? _savedLast4;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _yapeController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString(_prefsTypeKey);
    final last4 = prefs.getString(_prefsLast4Key);

    if (!mounted) return;
    setState(() {
      _savedLast4 = last4;
      if (type != null && last4 != null) {
        _selectedOption = _PaymentOption.saved;
        _saveForFuture = true;
      } else {
        _selectedOption = _PaymentOption.yape;
      }
    });
  }

  Future<void> _persistSaved({required String type, required String last4}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsTypeKey, type);
    await prefs.setString(_prefsLast4Key, last4);
  }

  void _showRetrySnack(String message, VoidCallback onRetry) {
    final snack = SnackBar(
      backgroundColor: AppColors.error,
      content: Text(message, style: const TextStyle(color: AppColors.white)),
      action: SnackBarAction(
        label: 'Reintentar',
        textColor: AppColors.white,
        onPressed: onRetry,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  @override
  Widget build(BuildContext context) {
    final reserva = ref.watch(reservaProvider);
    final mode = GoRouterState.of(context).uri.queryParameters['mode'];

    final driver = reserva.conductorSeleccionado;
    final seats = [...reserva.asientosSeleccionados]..sort();

    if (driver == null || seats.isEmpty) {
      return const AppScaffold(
        title: 'Pago seguro',
        body: PlaceholderPage(
          title: 'Reserva incompleta',
          subtitle: 'Vuelve a seleccionar asientos y completa la reserva.',
        ),
      );
    }

    final payingAdditional =
        mode == 'additional' && reserva.additionalChargePending;
    final total = payingAdditional ? reserva.additionalChargeAmount : reserva.montoTotal;
    final title = payingAdditional ? 'Pago adicional' : 'Pago seguro';

    final hasSaved = _savedLast4 != null;
    final option = _selectedOption ?? (hasSaved ? _PaymentOption.saved : _PaymentOption.yape);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.lock_rounded),
            const SizedBox(width: AppSpacing.sm),
            Text(title),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.p20),
          children: [
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${driver.name} · ${driver.plate}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Asientos: ${seats.map((s) => '#$s').join(', ')}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'S/ ${total.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                    ),
                    if (payingAdditional) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Pago adicional por salida anticipada',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Método de pago',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (hasSaved)
              _PaymentOptionCard(
                selected: option == _PaymentOption.saved,
                title: 'Tarjeta guardada',
                subtitle: '•••• $_savedLast4',
                icon: Icons.credit_card_rounded,
                onTap: _paying ? null : () => setState(() => _selectedOption = _PaymentOption.saved),
              ),
            if (hasSaved) const SizedBox(height: AppSpacing.md),
            _PaymentOptionCard(
              selected: option == _PaymentOption.yape,
              title: 'Yape',
              subtitle: 'Paga con tu número de Yape',
              icon: Icons.qr_code_2_rounded,
              onTap: _paying ? null : () => setState(() => _selectedOption = _PaymentOption.yape),
            ),
            if (option == _PaymentOption.yape) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _yapeController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Número Yape'),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _PaymentOptionCard(
              selected: option == _PaymentOption.card,
              title: 'Tarjeta',
              subtitle: 'Ingresa los datos de tu tarjeta',
              icon: Icons.credit_card,
              onTap: _paying ? null : () => setState(() => _selectedOption = _PaymentOption.card),
            ),
            if (option == _PaymentOption.card) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Número de tarjeta'),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cardExpiryController,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(labelText: 'MM/AA'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _cardCvvController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'CVV'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _saveForFuture,
              onChanged: _paying ? null : (v) => setState(() => _saveForFuture = v ?? false),
              title: const Text('Guardar este método para futuras compras'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.energeticOrange,
                foregroundColor: AppColors.white,
                minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                textStyle:
                    Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              onPressed: _paying
                  ? null
                  : () async {
                      Future<void> retry() async {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        await _pay(option: option, total: total, payingAdditional: payingAdditional);
                      }

                      await _pay(
                        option: option,
                        total: total,
                        payingAdditional: payingAdditional,
                        onRetry: retry,
                      );
                    },
              child: _paying
                  ? const SizedBox(
                      width: AppSpacing.lg,
                      height: AppSpacing.lg,
                      child: CircularProgressIndicator(strokeWidth: AppSpacing.progressStrokeWidth),
                    )
                  : Text('Pagar S/ ${total.toStringAsFixed(0)}'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pay({
    required _PaymentOption option,
    required double total,
    required bool payingAdditional,
    Future<void> Function()? onRetry,
  }) async {
    setState(() => _paying = true);

    final simulateFail = option == _PaymentOption.yape &&
        _yapeController.text.trim().isNotEmpty &&
        _yapeController.text.trim().endsWith('000');

    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    if (simulateFail) {
      setState(() => _paying = false);
      if (onRetry != null) {
        _showRetrySnack('No se pudo procesar el pago con Yape.', () => onRetry());
      } else {
        AppSnackbars.error(context, 'No se pudo procesar el pago con Yape.');
      }
      return;
    }

    if (_saveForFuture) {
      if (option == _PaymentOption.yape) {
        final digits = _yapeController.text.replaceAll(RegExp(r'\D'), '');
        final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
        await _persistSaved(type: 'yape', last4: last4);
      } else if (option == _PaymentOption.card || option == _PaymentOption.saved) {
        final digits = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
        final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : (_savedLast4 ?? '0000');
        await _persistSaved(type: 'card', last4: last4);
      }
    }

    if (payingAdditional) {
      ref.read(reservaProvider.notifier).setVehiculoPartio(true);
      ref.read(reservaProvider.notifier).clearAdditionalCharge();
      if (!mounted) return;
      setState(() => _paying = false);
      context.go('${AppRoutes.passengerReservaActiva}?extraPaid=1');
      return;
    }

    final reservaId = await _crearReservaSupabase(ref, option: option);
    ref.read(reservaProvider.notifier).markPaid(reservaId: reservaId);

    if (!mounted) return;
    setState(() => _paying = false);
    context.go('${AppRoutes.passengerConfirmacion}?reservaId=$reservaId');
  }

  Future<String> _crearReservaSupabase(WidgetRef ref, {required _PaymentOption option}) async {
    final accountId = ref.read(passengerSessionProvider).account?.id;
    final reserva = ref.read(reservaProvider);
    final seats = [...reserva.asientosSeleccionados]..sort();
    final pickup = reserva.puntoRecojo?.trim();
    final selectedDriver = reserva.conductorSeleccionado;
    final total = seats.length * 15.0;

    if (accountId == null) {
      return 'r_${DateTime.now().millisecondsSinceEpoch}';
    }

    try {
      String? tripId;
      if (selectedDriver != null) {
        tripId = await _getOrCreateTripIdForDriver(
          driverPlate: selectedDriver.plate,
          direction: selectedDriver.direction,
          amount: total,
        );
      }

      final row = await Supabase.instance.client.from('reservations').insert({
        'trip_id': tripId,
        'passenger_profile_id': accountId,
        'pickup_point': pickup,
        'seats': seats,
        'status': 'activa',
      }).select('id').single();
      final id = row['id'];
      final reservaId = id?.toString() ?? 'r_${DateTime.now().millisecondsSinceEpoch}';

      try {
        await Supabase.instance.client.from('payments').insert({
          'reservation_id': reservaId,
          'amount': total,
          'status': 'pagado',
          'provider': option.name,
        });
      } catch (_) {}

      try {
        await Supabase.instance.client
            .from('profiles')
            .update({'has_active_reservation': true})
            .eq('id', accountId);
      } catch (_) {}

      return reservaId;
    } catch (_) {
      return 'r_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<String?> _getOrCreateTripIdForDriver({
    required String driverPlate,
    required MockTripDirection direction,
    required double amount,
  }) async {
    try {
      final driver = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('plate', driverPlate)
          .maybeSingle();
      final driverId = driver?['id']?.toString();
      if (driverId == null) return null;

      final existing = await Supabase.instance.client
          .from('trips')
          .select('id, status')
          .eq('driver_id', driverId)
          .neq('status', 'completado')
          .neq('status', 'cancelado')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final existingId = existing?['id']?.toString();
      if (existingId != null) return existingId;

      final routeName = direction == MockTripDirection.sanIsidroToChosica
          ? 'San Isidro → Chosica'
          : 'Chosica → San Isidro';
      final route = await Supabase.instance.client
          .from('routes')
          .select('id')
          .eq('name', routeName)
          .maybeSingle();
      final routeId = route?['id']?.toString();

      final created = await Supabase.instance.client.from('trips').insert({
        'route_id': routeId,
        'driver_id': driverId,
        'status': 'pendiente',
        'amount': amount,
      }).select('id').single();
      return created['id']?.toString();
    } catch (_) {
      return null;
    }
  }
}

class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.primaryBlue : AppColors.border;
    final bg = AppColors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r16),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: AppSpacing.shadowBlur,
              offset: Offset(0, AppSpacing.shadowOffsetY),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: selected,
                onChanged: onTap == null ? null : (_) => onTap?.call(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
