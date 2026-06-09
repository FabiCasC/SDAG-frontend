import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers/passenger/controllers/connectivity_controller.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/reusable_ui_components.dart';

class QrScreen extends ConsumerStatefulWidget {
  const QrScreen({required this.tripId, super.key});

  final String? tripId;

  @override
  ConsumerState<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends ConsumerState<QrScreen> {
  double? _previousBrightness;
  String? _cachedQrData;

  @override
  void initState() {
    super.initState();
    _prepareBrightness();
  }

  @override
  void dispose() {
    _restoreBrightness();
    super.dispose();
  }

  Future<void> _prepareBrightness() async {
    if (kIsWeb) return;
    try {
      _previousBrightness = await ScreenBrightness().application;
      await ScreenBrightness().setApplicationScreenBrightness(1.0);
    } catch (_) {}
  }

  Future<void> _restoreBrightness() async {
    if (kIsWeb) return;
    final prev = _previousBrightness;
    if (prev == null) return;
    try {
      await ScreenBrightness().setApplicationScreenBrightness(prev);
    } catch (_) {}
  }

  Future<void> _loadCached(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(key);
    if (!mounted) return;
    setState(() => _cachedQrData = v);
  }

  Future<void> _saveCached(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(connectivityProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('QR')),
      body: FutureBuilder<_QrTripData?>(
        future: _loadQrTripData(widget.tripId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.p20),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final trip = snapshot.data;
          if (trip == null) {
            return const AppScaffold(
              title: 'QR',
              body: PlaceholderPage(
                title: 'QR no disponible',
                subtitle: 'No se encontró el viaje.',
              ),
            );
          }

          final firstSeat = trip.seats.isEmpty ? 0 : trip.seats.first;
          final cacheKey = 'qr_cache_${trip.id}_$firstSeat';
          final qrData = 'res_${trip.id}|trip_${trip.tripId}|seats_${trip.seats.join(',')}';

          if (!online && _cachedQrData == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadCached(cacheKey);
            });
          }

          if (online) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _saveCached(cacheKey, qrData);
            });
          }

          final effectiveQr = online ? qrData : (_cachedQrData ?? qrData);
          final (chipBg, chipFg, label) = trip.boarded
              ? (AppColors.seatOkBg, AppColors.success, 'Abordado')
              : (AppColors.seatWarnBg, AppColors.warning, 'Pendiente');

          return SafeArea(
            child: Column(
              children: [
                if (!online)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    color: AppColors.seatWarnBg,
                    child: Text(
                      'Sin conexión - mostrando QR guardado',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.p20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
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
                            child: QrImageView(
                              data: effectiveQr,
                              size: 200,
                              backgroundColor: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            trip.passengerName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            trip.seatsLabel,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: chipFg,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<_QrTripData?> _loadQrTripData(String? reservationId) async {
  if (reservationId == null || reservationId.trim().isEmpty) return null;

  final row = await Supabase.instance.client
      .from('reservations')
      .select('''
        id,
        trip_id,
        seats,
        vehiculo_partio,
        profiles (
          name,
          first_name,
          last_name
        )
      ''')
      .eq('id', reservationId)
      .maybeSingle();

  if (row == null) return null;

  final map = Map<String, dynamic>.from(row);
  final profile = map['profiles'] is Map ? Map<String, dynamic>.from(map['profiles'] as Map) : <String, dynamic>{};
  final firstName = profile['first_name']?.toString().trim() ?? '';
  final lastName = profile['last_name']?.toString().trim() ?? '';
  final fullName = '$firstName $lastName'.trim();

  return _QrTripData(
    id: map['id'].toString(),
    tripId: map['trip_id']?.toString() ?? '',
    seats: ((map['seats'] as List?) ?? const <dynamic>[]).whereType<int>().toList(),
    boarded: (map['vehiculo_partio'] as bool?) ?? false,
    passengerName: (profile['name']?.toString().trim().isNotEmpty ?? false)
        ? profile['name'].toString().trim()
        : (fullName.isNotEmpty ? fullName : 'Pasajero'),
  );
}

class _QrTripData {
  const _QrTripData({
    required this.id,
    required this.tripId,
    required this.seats,
    required this.boarded,
    required this.passengerName,
  });

  final String id;
  final String tripId;
  final List<int> seats;
  final bool boarded;
  final String passengerName;

  String get seatsLabel => seats.isEmpty ? 'Sin asiento' : seats.map((s) => 'Asiento #$s').join(', ');
}
