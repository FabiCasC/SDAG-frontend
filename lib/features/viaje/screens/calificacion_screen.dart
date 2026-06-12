import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../features/reserva/providers/reserva_provider.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_navigation_back.dart';
import '../../../shared/widgets/reusable_ui_components.dart';
import '../providers/viaje_provider.dart';

class CalificacionScreen extends ConsumerStatefulWidget {
  const CalificacionScreen({super.key});

  @override
  ConsumerState<CalificacionScreen> createState() => _CalificacionScreenState();
}

class _CalificacionScreenState extends ConsumerState<CalificacionScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reservationId = GoRouterState.of(context).uri.queryParameters['tripId'];
    final reserva = ref.watch(reservaProvider);
    final activeDriverName = reserva.conductorSeleccionado?.name;

    if (reservationId != null && reservationId.trim().isNotEmpty) {
      return FutureBuilder<_RatingTarget?>(
        future: _loadRatingTarget(reservationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppScaffold(
              title: 'Calificación',
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return AppScaffold(
              title: 'Calificación',
              body: PlaceholderPage(
                title: 'Sin conductor',
                subtitle: snapshot.error.toString(),
              ),
            );
          }

          final target = snapshot.data;
          if (target == null) {
            return const AppScaffold(
              title: 'Calificación',
              body: PlaceholderPage(
                title: 'Sin conductor',
                subtitle: 'No hay información del conductor para calificar.',
              ),
            );
          }

          return _buildContent(
            context: context,
            driverName: target.driverName,
            onSubmit: () => _submitRating(context, target: target, resetActiveTrip: false),
            onSkip: () => context.go(AppRoutes.passengerHome),
          );
        },
      );
    }

    if (activeDriverName == null) {
      return const AppScaffold(
        title: 'Calificación',
        body: PlaceholderPage(
          title: 'Sin conductor',
          subtitle: 'No hay información del conductor para calificar.',
        ),
      );
    }

    return _buildContent(
      context: context,
      driverName: activeDriverName,
      onSubmit: () => _submitRating(
        context,
        target: _RatingTarget(
          tripId: reserva.conductorSeleccionado?.tripId ?? '',
          driverId: reserva.conductorSeleccionado?.driverId ?? '',
          driverName: activeDriverName,
        ),
        resetActiveTrip: true,
      ),
      onSkip: () {
        ref.read(reservaProvider.notifier).reset();
        ref.invalidate(viajeProvider);
        context.go(AppRoutes.passengerHome);
      },
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required String driverName,
    required VoidCallback onSkip,
    required Future<void> Function() onSubmit,
  }) {
    final initials = _initials(driverName);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: AppBarLeadingBack(fallbackRoute: AppRoutes.passengerHome),
        title: const Text('Calificación'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.p20),
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: CircleAvatar(
                radius: 54,
                backgroundColor: AppColors.primaryTint12,
                child: Text(
                  initials,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '¿Cómo fue tu viaje con $driverName?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = i < _rating;
                  return IconButton(
                    onPressed: () => setState(() => _rating = i + 1),
                    iconSize: 48,
                    icon: Icon(
                      Icons.star_rounded,
                      color: filled ? AppColors.energeticOrange : AppColors.border,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Enviar calificación',
              loading: _saving,
              onPressed: _rating == 0 || _saving
                  ? null
                  : onSubmit,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: _saving ? null : onSkip,
              child: const Text('Omitir'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRating(
    BuildContext context, {
    required _RatingTarget target,
    required bool resetActiveTrip,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || target.tripId.isEmpty || target.driverId.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('No se pudo enviar la calificación')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('ratings').upsert({
        'trip_id': target.tripId,
        'rater_profile_id': userId,
        'driver_id': target.driverId,
        'stars': _rating,
        'comment': _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      });

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('¡Gracias! Tu calificación fue enviada')),
      );

      if (resetActiveTrip) {
        ref.read(reservaProvider.notifier).reset();
        ref.invalidate(viajeProvider);
      }
      router.go(AppRoutes.passengerHome);
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('No se pudo enviar la calificación: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final p = parts.first;
      return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
    }
    return ('${parts[0][0]}${parts[1][0]}').toUpperCase();
  }
}

Future<_RatingTarget?> _loadRatingTarget(String reservationId) async {
  final row = await Supabase.instance.client
      .from('reservations')
      .select('''
        trip_id,
        trips (
          driver_id,
          drivers (
            profiles (
              name,
              first_name,
              last_name
            )
          )
        )
      ''')
      .eq('id', reservationId)
      .maybeSingle();

  if (row == null) return null;

  final map = Map<String, dynamic>.from(row);
  final tripId = map['trip_id']?.toString() ?? '';
  final trip = map['trips'] is Map ? Map<String, dynamic>.from(map['trips'] as Map) : <String, dynamic>{};
  final driverId = trip['driver_id']?.toString() ?? '';
  final driver = trip['drivers'] is Map ? Map<String, dynamic>.from(trip['drivers'] as Map) : <String, dynamic>{};
  final profile = driver['profiles'] is Map ? Map<String, dynamic>.from(driver['profiles'] as Map) : <String, dynamic>{};
  final firstName = profile['first_name']?.toString().trim() ?? '';
  final lastName = profile['last_name']?.toString().trim() ?? '';
  final fullName = '$firstName $lastName'.trim();
  final driverName = (profile['name']?.toString().trim().isNotEmpty ?? false)
      ? profile['name'].toString().trim()
      : (fullName.isNotEmpty ? fullName : 'Conductor');

  return _RatingTarget(
    tripId: tripId,
    driverId: driverId,
    driverName: driverName,
  );
}

class _RatingTarget {
  const _RatingTarget({
    required this.tripId,
    required this.driverId,
    required this.driverName,
  });

  final String tripId;
  final String driverId;
  final String driverName;
}
