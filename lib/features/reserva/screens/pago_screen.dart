import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

import '../../../app/router/app_routes.dart';
import '../../../app/providers/passenger/controllers/passenger_session_controller.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_navigation_back.dart';
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
  static const _prefsCardNumberKey = 'sdag_card_number';
  static const _prefsCardCvvKey = 'sdag_card_cvv';
  static const _prefsCardExpiryKey = 'sdag_card_expiry';
  static const _prefsCardHolderKey = 'sdag_card_holder';
  static const _prefsCardLast4Key = 'sdag_card_last4';
  static const _culqiPublicKeyFallback = 'pk_test_121t6Q3w2iXFBFDF';

  final _yapeController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  bool _saveForFuture = false;
  bool _paying = false;
  _PaymentOption? _selectedOption;
  bool _cvvObscure = true;

  String? _savedLast4;
  String? _savedCardNumber;
  String? _savedCardCvv;
  String? _savedCardExpiry;
  String? _savedCardHolder;

  @override
  void initState() {
    super.initState();
    _loadSaved();
    void refreshPayButton() {
      if (mounted) setState(() {});
    }
    _yapeController.addListener(refreshPayButton);
    _cardNumberController.addListener(refreshPayButton);
    _cardExpiryController.addListener(refreshPayButton);
    _cardCvvController.addListener(refreshPayButton);
    _cardHolderController.addListener(refreshPayButton);
  }

  bool _puedeContinuar(_PaymentOption option) {
    if (option == _PaymentOption.saved) {
      return _savedCardNumber != null;
    }
    if (option == _PaymentOption.card) {
      return _cardNumberController.text.replaceAll(' ', '').length == 16 &&
          _cardCvvController.text.length == 3 &&
          _cardExpiryController.text.length == 5 &&
          _cardHolderController.text.trim().length >= 3;
    }
    if (option == _PaymentOption.yape) {
      return _yapeController.text.replaceAll(RegExp(r'\D'), '').length == 9;
    }
    return false;
  }

  Future<void> _persistSavedCard({
    required String cardNumber,
    required String cvv,
    required String expiry,
    required String holder,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsCardNumberKey, cardNumber);
    await prefs.setString(_prefsCardCvvKey, cvv);
    await prefs.setString(_prefsCardExpiryKey, expiry);
    await prefs.setString(_prefsCardHolderKey, holder);
    await prefs.setString(_prefsCardLast4Key, cardNumber.substring(cardNumber.length - 4));
    debugPrint('[Tarjeta] guardada — last4=${cardNumber.substring(cardNumber.length - 4)}');
    if (!mounted) return;
    setState(() {
      _savedCardNumber = cardNumber;
      _savedCardCvv = cvv;
      _savedCardExpiry = expiry;
      _savedCardHolder = holder;
      _savedLast4 = cardNumber.substring(cardNumber.length - 4);
    });
  }

  @override
  void dispose() {
    _yapeController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final cardNumber = prefs.getString(_prefsCardNumberKey);
    final cvv = prefs.getString(_prefsCardCvvKey);
    final expiry = prefs.getString(_prefsCardExpiryKey);
    final holder = prefs.getString(_prefsCardHolderKey);
    final last4 = prefs.getString(_prefsCardLast4Key);

    debugPrint('[Tarjeta] cargada — last4=$last4 hayDatos=${cardNumber != null}');

    if (!mounted) return;
    setState(() {
      _savedCardNumber = cardNumber;
      _savedCardCvv = cvv;
      _savedCardExpiry = expiry;
      _savedCardHolder = holder;
      _savedLast4 = last4;
      _selectedOption = cardNumber != null ? _PaymentOption.saved : _PaymentOption.yape;
      if (cardNumber != null) _saveForFuture = true;
    });
  }

  Future<void> _persistSavedYape({
    required String last4,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsTypeKey, 'yape');
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

    final hasSaved = _savedCardNumber != null;
    final option = _selectedOption ?? (hasSaved ? _PaymentOption.saved : _PaymentOption.yape);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: AppBarLeadingBack(fallbackRoute: AppRoutes.passengerReservaResumen),
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
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${seats.length} × S/ 15.00 = S/ ${(seats.length * 15.0).toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                decoration: const InputDecoration(
                  labelText: 'Número Yape',
                  hintText: '9 dígitos (ej. 987654321)',
                ),
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
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  _CardNumberFormatter(),
                ],
                decoration: const InputDecoration(labelText: 'Número de tarjeta'),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cardExpiryController,
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryFormatter(),
                      ],
                      decoration: const InputDecoration(labelText: 'MM/AA'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _cardCvvController,
                      keyboardType: TextInputType.number,
                      obscureText: _cvvObscure,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _cvvObscure = !_cvvObscure),
                          icon: Icon(_cvvObscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _cardHolderController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre del titular'),
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
              onPressed: !_paying && _puedeContinuar(option)
                  ? () async {
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
                    }
                  : null,
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

    try {
      if (payingAdditional) {
        if (option == _PaymentOption.yape) {
          final digits = _yapeController.text.replaceAll(RegExp(r'\D'), '');
          if (digits.length < 9) {
            if (!mounted) return;
            setState(() => _paying = false);
            AppSnackbars.error(context, 'Ingresa un número Yape válido (9 dígitos).');
            return;
          }
          await Future.delayed(const Duration(seconds: 2));
        } else if (option == _PaymentOption.saved) {
          if (!mounted) return;
          setState(() => _paying = false);
          AppSnackbars.error(
            context,
            'Para el pago adicional usa Yape o Tarjeta con datos completos.',
          );
          return;
        }
        await _persistSavedIfNeeded(option);
        ref.read(reservaProvider.notifier).setVehiculoPartio(true);
        ref.read(reservaProvider.notifier).clearAdditionalCharge();
        if (!mounted) return;
        setState(() => _paying = false);
        context.go('${AppRoutes.passengerReservaActiva}?extraPaid=1');
        return;
      }

      await _persistSavedIfNeeded(option);

      if (option == _PaymentOption.saved) {
        if (_savedCardNumber == null ||
            _savedCardCvv == null ||
            _savedCardExpiry == null ||
            _savedCardHolder == null) {
          if (!mounted) return;
          setState(() => _paying = false);
          AppSnackbars.error(context, 'No hay tarjeta guardada valida');
          return;
        }
        try {
          final reservaId = await _payWithCulqi(ref, usingSavedCard: true);
          ref.read(reservaProvider.notifier).markPaid(reservaId: reservaId);
          if (!mounted) return;
          setState(() => _paying = false);
          context.go('${AppRoutes.passengerConfirmacion}?reservaId=$reservaId');
        } catch (e) {
          if (!mounted) return;
          setState(() => _paying = false);
          debugPrint('[PAY ERROR] ${e.runtimeType}: $e');
          final message = switch (e) {
            AuthException(:final message) => message,
            FunctionException(:final details, :final reasonPhrase) =>
              details?.toString() ?? reasonPhrase ?? 'Error en el pago.',
            _ => 'Error: ${e.toString()}',
          };
          if (onRetry != null) {
            _showRetrySnack(message, () => onRetry());
          } else {
            AppSnackbars.error(context, message);
          }
        }
        return;
      }

      if (option == _PaymentOption.yape) {
        final digits = _yapeController.text.replaceAll(RegExp(r'\D'), '');
        if (digits.length < 9) {
          if (!mounted) return;
          setState(() => _paying = false);
          AppSnackbars.error(context, 'Ingresa un número Yape válido (9 dígitos).');
          return;
        }
        await Future.delayed(const Duration(seconds: 2));
        final reservaId = await _payWithYapeSimulated(ref, yapeDigits: digits);
        ref.read(reservaProvider.notifier).markPaid(reservaId: reservaId);
        if (!mounted) return;
        setState(() => _paying = false);
        context.go('${AppRoutes.passengerConfirmacion}?reservaId=$reservaId');
        return;
      }

      if (option == _PaymentOption.card) {
        final reservaId = await _payWithCulqi(ref, usingSavedCard: false);
        ref.read(reservaProvider.notifier).markPaid(reservaId: reservaId);

        if (!mounted) return;
        setState(() => _paying = false);
        context.go('${AppRoutes.passengerConfirmacion}?reservaId=$reservaId');
        return;
      }

      if (!mounted) return;
      setState(() => _paying = false);
      AppSnackbars.error(context, 'Selecciona un metodo de pago valido.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      debugPrint('[PAY ERROR] ${e.runtimeType}: $e');
      final message = switch (e) {
        AuthException(:final message) => message,
        FunctionException(:final details, :final reasonPhrase) =>
          details?.toString() ?? reasonPhrase ?? 'Error en el pago.',
        _ => 'Error: ${e.toString()}',
      };
      if (onRetry != null) {
        _showRetrySnack(message, () => onRetry());
      } else {
        AppSnackbars.error(context, message);
      }
    }
  }

  Future<String> _payWithCulqi(WidgetRef ref, {required bool usingSavedCard}) async {
    final user = Supabase.instance.client.auth.currentUser;
    final email = (user?.email ?? ref.read(passengerSessionProvider).account?.email ?? '').trim();
    final userId = user?.id ?? ref.read(passengerSessionProvider).account?.id;
    final reserva = ref.read(reservaProvider);
    final seats = [...reserva.asientosSeleccionados]..sort();
    final driver = reserva.conductorSeleccionado;

    if (email.isEmpty || userId == null) {
      throw const AuthException('Sesión inválida');
    }
    if (seats.isEmpty || driver == null) {
      throw const AuthException('Reserva inválida');
    }

    final String cardNumberDigits;
    final String cvv;
    final int mm;
    final int yy;
    final String holder;
    final String expiryForPersist;

    if (usingSavedCard) {
      if (_savedCardNumber == null ||
          _savedCardCvv == null ||
          _savedCardExpiry == null ||
          _savedCardHolder == null) {
        throw const AuthException('No hay tarjeta guardada disponible');
      }
      cardNumberDigits = _savedCardNumber!;
      cvv = _savedCardCvv!;
      final (parsedMm, parsedYy) = _parseExpiry(_savedCardExpiry!);
      mm = parsedMm;
      yy = parsedYy;
      holder = _savedCardHolder!;
      expiryForPersist = _savedCardExpiry!;
      debugPrint(
        '[Pago] usando tarjeta guardada last4=${cardNumberDigits.substring(cardNumberDigits.length - 4)}',
      );
    } else {
      cardNumberDigits = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
      cvv = _cardCvvController.text.replaceAll(RegExp(r'\D'), '');
      expiryForPersist = _cardExpiryController.text.trim();
      final (parsedMm, parsedYy) = _parseExpiry(expiryForPersist);
      mm = parsedMm;
      yy = parsedYy;
      holder = _cardHolderController.text.trim();
    }

    if (cardNumberDigits.length != 16) {
      throw const AuthException('Número de tarjeta inválido');
    }
    if (cvv.length != 3) {
      throw const AuthException('CVV inválido');
    }
    if (mm < 1 || mm > 12) {
      throw const AuthException('Fecha de vencimiento inválida');
    }
    if (yy < 0 || yy > 99) {
      throw const AuthException('Fecha de vencimiento inválida');
    }
    if (holder.length < 3) {
      throw const AuthException('Nombre del titular inválido');
    }

    final publicKey = (dotenv.env['CULQI_PUBLIC_KEY'] ?? _culqiPublicKeyFallback).trim();
    if (publicKey.isEmpty) {
      throw const AuthException('Falta configurar CULQI_PUBLIC_KEY');
    }

    final tokenRes = await http.post(
      Uri.parse('https://secure.culqi.com/v2/tokens'),
      headers: {
        'Authorization': 'Bearer $publicKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'card_number': cardNumberDigits,
        'cvv': cvv,
        'expiration_month': mm,
        'expiration_year': yy < 100 ? 2000 + yy : yy,
        'email': email,
      }),
    );

    final tokenJson = _tryDecodeJson(tokenRes.body);
    if (tokenRes.statusCode != 201) {
      debugPrint('[Culqi][token] status=${tokenRes.statusCode} body=${tokenRes.body}');
      final msg = tokenJson?['user_message']?.toString() ??
          tokenJson?['merchant_message']?.toString() ??
          tokenJson?['message']?.toString() ??
          'Tarjeta rechazada. Verifica los datos e intenta de nuevo.';
      throw AuthException(msg);
    }
    final token = tokenJson?['id']?.toString();
    if (token == null || token.isEmpty) {
      throw const AuthException('Token inválido');
    }

    final amountCents = seats.length * 1500;
    String? chargeId;
    try {
      final chargeResp = await Supabase.instance.client.functions.invoke(
        'culqi-charge',
        body: {
          'source_id': token,
          'email': email,
          'amount': amountCents,
          'description': 'Reserva SDAG - ${seats.length} asiento(s)',
        },
      );
      final chargeData = chargeResp.data;
      chargeId = (chargeData is Map && chargeData['charge_id'] != null)
          ? chargeData['charge_id'].toString()
          : null;
      if (chargeId == null || chargeId.isEmpty) {
        debugPrint('[Culqi][charge] missing charge_id data=$chargeData');
      }
    } on FunctionException catch (e) {
      debugPrint('[Culqi][charge] status=${e.status} reason=${e.reasonPhrase} details=${e.details}');
      final details = e.details;
      String msg = 'No se pudo procesar el pago.';
      if (details is Map) {
        final inner = details['details'];
        if (inner is Map) {
          msg = inner['user_message']?.toString() ?? inner['merchant_message']?.toString() ?? msg;
        } else {
          msg = details['error']?.toString() ?? msg;
        }
      }
      throw AuthException(msg);
    }
    if (chargeId == null || chargeId.isEmpty) {
      throw const AuthException('Cargo fallido');
    }

    if (!usingSavedCard && _saveForFuture) {
      await _persistSavedCard(
        cardNumber: cardNumberDigits,
        cvv: cvv,
        expiry: expiryForPersist,
        holder: holder,
      );
    }

    return _insertReservationAndPayment(
      ref: ref,
      userId: userId,
      receiptNumber: chargeId,
      provider: 'culqi',
    );
  }

  Future<String> _insertReservationAndPayment({
    required WidgetRef ref,
    required String userId,
    required String receiptNumber,
    required String provider,
  }) async {
    final reserva = ref.read(reservaProvider);
    final seats = [...reserva.asientosSeleccionados]..sort();
    final pickup = reserva.puntoRecojo?.trim();
    final driver = reserva.conductorSeleccionado;

    if (seats.isEmpty || driver == null) {
      throw const AuthException('Reserva inválida');
    }

    final amountTotal = seats.length * 15.0;
    final tripId = driver.tripId;
    if (tripId.trim().isEmpty) {
      throw const AuthException('No se encontró el viaje del conductor');
    }

    final row = await Supabase.instance.client.from('reservations').insert({
      'trip_id': tripId,
      'passenger_profile_id': userId,
      'pickup_point': pickup,
      'seats': seats,
      'status': 'activa',
      'amount': amountTotal,
      'vehiculo_partio': false,
    }).select().single();

    final reservaId = row['id']?.toString();
    if (reservaId == null || reservaId.isEmpty) {
      throw const AuthException('Reserva inválida');
    }

    await Supabase.instance.client.from('payments').insert({
      'reservation_id': reservaId,
      'amount': amountTotal,
      'status': 'confirmado',
      'receipt_number': receiptNumber,
      'provider': provider,
    });

    try {
      await Supabase.instance.client.from('profiles').update({'has_active_reservation': true}).eq('id', userId);
    } catch (_) {}

    if (pickup != null && pickup.isNotEmpty) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('preferred_pickup')
            .eq('id', userId)
            .maybeSingle();
        final existing = profile?['preferred_pickup']?.toString().trim();
        if (existing == null || existing.isEmpty) {
          await Supabase.instance.client
              .from('profiles')
              .update({'preferred_pickup': pickup})
              .eq('id', userId);
        }
      } catch (_) {}
    }

    return reservaId;
  }

  Future<String> _payWithYapeSimulated(WidgetRef ref, {required String yapeDigits}) async {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? ref.read(passengerSessionProvider).account?.id;
    if (userId == null) {
      throw const AuthException('Sesión inválida');
    }
    final receipt = 'yape_${userId}_${DateTime.now().millisecondsSinceEpoch}_$yapeDigits';
    return _insertReservationAndPayment(
      ref: ref,
      userId: userId,
      receiptNumber: receipt,
      provider: 'yape',
    );
  }

  Future<void> _persistSavedIfNeeded(_PaymentOption option) async {
    if (!_saveForFuture) return;
    if (option == _PaymentOption.yape) {
      final digits = _yapeController.text.replaceAll(RegExp(r'\D'), '');
      final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
      await _persistSavedYape(last4: last4);
    }
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final text = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)}/${digits.substring(2, digits.length.clamp(2, 4))}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

(int, int) _parseExpiry(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return (0, 0);
  final mm = int.tryParse(digits.substring(0, 2)) ?? 0;
  final yy = int.tryParse(digits.substring(2, 4)) ?? 0;
  return (mm, yy);
}

Map<String, dynamic>? _tryDecodeJson(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  } catch (_) {
    return null;
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
