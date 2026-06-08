import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/mock/mock_data.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';
import '../providers/admin_conductores_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminCalificacionesScreen extends ConsumerWidget {
  const AdminCalificacionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const appBarBg = Color(0xFF0F172A);
    const pageBg = Color(0xFFF8FAFC);

    final conductores = ref.watch(adminConductoresProvider).listaConductores;
    final sorted = [...conductores]
      ..sort((a, b) {
        final r = b.ratingPromedio.compareTo(a.ratingPromedio);
        if (r != 0) return r;
        return b.ratingCount.compareTo(a.ratingCount);
      });

    final totalRatings = sorted.fold<int>(0, (a, b) => a + b.ratingCount);
    final weightedSum = sorted.fold<double>(0, (a, b) => a + (b.ratingPromedio * b.ratingCount));
    final avg = totalRatings == 0 ? 0.0 : (weightedSum / totalRatings);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: AppColors.white,
        title: const Text('Calificaciones de conductores'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.p20),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border(
                left: const BorderSide(color: Color(0xFFF97316), width: 6),
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
                  'Promedio general de la flota: ${avg.toStringAsFixed(1)} ★',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Basado en $totalRatings calificaciones de pasajeros',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < sorted.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ConductorRatingCard(
                rank: i + 1,
                conductor: sorted[i],
              ),
            ),
        ],
      ),
      bottomNavigationBar: const _AdminBottomNav(currentIndex: 4),
    );
  }
}

class _ConductorRatingCard extends StatelessWidget {
  const _ConductorRatingCard({
    required this.rank,
    required this.conductor,
  });

  final int rank;
  final MockAdminConductor conductor;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(conductor.nombres, conductor.apellidos);
    final dist = _distributionFor(conductor.ratingPromedio, conductor.ratingCount);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r16),
      onTap: conductor.ratingCount == 0
          ? null
          : () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Últimas calificaciones'),
                  content: SizedBox(
                    width: 520,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${conductor.nombreCompleto} · ${conductor.placa}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Consumer(
                          builder: (context, ref, child) {
                            final ratingsAsync = ref.watch(driverRatingsProvider(conductor.id));
                            return ratingsAsync.when(
                              data: (ratings) {
                                if (ratings.isEmpty) return const Text('No hay comentarios recientes.');
                                return Column(
                                  children: [
                                    for (final r in ratings)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: 110,
                                              child: Text(
                                                r.dateLabel,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: AppColors.textSecondary,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _Stars(rating: r.stars.toDouble(), count: 0, showCount: false),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                r.comment,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: AppColors.textPrimary,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (_, __) => const Text('Error al cargar comentarios.'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
                  ],
                ),
              );
            },
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${conductor.nombreCompleto} · ${conductor.placa}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _Stars(rating: conductor.ratingPromedio, count: conductor.ratingCount),
                          const SizedBox(width: 8),
                          Text(
                            conductor.ratingCount == 0 ? '0 valoraciones' : '${conductor.ratingCount} valoraciones',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: conductor.ratingCount == 0 ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final row in dist)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${row.stars}★',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: row.percent / 100,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFFF59E0B)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${row.percent.toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
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

class _Stars extends StatelessWidget {
  const _Stars({
    required this.rating,
    required this.count,
    this.showCount = true,
  });

  final double rating;
  final int count;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final full = rating.floor().clamp(0, 5);
    final hasHalf = (rating - full) >= 0.5 && full < 5;
    final stars = <Widget>[];
    for (var i = 0; i < full; i++) {
      stars.add(const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)));
    }
    if (hasHalf) {
      stars.add(const Icon(Icons.star_half_rounded, size: 16, color: Color(0xFFF59E0B)));
    }
    while (stars.length < 5) {
      stars.add(const Icon(Icons.star_border_rounded, size: 16, color: Color(0xFFCBD5E1)));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...stars,
        const SizedBox(width: 6),
        Text(
          showCount ? rating.toStringAsFixed(1) : '',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _DistRow {
  const _DistRow({required this.stars, required this.percent});
  final int stars;
  final double percent;
}

List<_DistRow> _distributionFor(double rating, int count) {
  if (count == 0) {
    return const [
      _DistRow(stars: 5, percent: 0),
      _DistRow(stars: 4, percent: 0),
      _DistRow(stars: 3, percent: 0),
      _DistRow(stars: 2, percent: 0),
      _DistRow(stars: 1, percent: 0),
    ];
  }

  final List<double> p = switch (rating) {
    >= 4.7 => [80, 15, 3, 1, 1],
    >= 4.4 => [65, 23, 8, 2, 2],
    >= 4.0 => [50, 28, 14, 5, 3],
    _ => [35, 28, 20, 9, 8],
  };

  return [
    _DistRow(stars: 5, percent: p[0]),
    _DistRow(stars: 4, percent: p[1]),
    _DistRow(stars: 3, percent: p[2]),
    _DistRow(stars: 2, percent: p[3]),
    _DistRow(stars: 1, percent: p[4]),
  ];
}

class _LastRating {
  const _LastRating({required this.dateLabel, required this.stars, required this.comment});
  final String dateLabel;
  final int stars;
  final String comment;
}

final driverRatingsProvider = FutureProvider.family<List<_LastRating>, String>((ref, profileId) async {
  final driverResp = await Supabase.instance.client.from('drivers').select('id').eq('profile_id', profileId).maybeSingle();
  if (driverResp == null) return [];
  final driverId = driverResp['id'];

  final resp = await Supabase.instance.client
      .from('ratings')
      .select('stars, comment, created_at')
      .eq('driver_id', driverId)
      .order('created_at', ascending: false)
      .limit(5);

  final list = <_LastRating>[];
  for (final r in (resp as List).cast<Map<String, dynamic>>()) {
      final created = DateTime.tryParse(r['created_at'].toString()) ?? DateTime.now();
      list.add(_LastRating(
        dateLabel: _formatDateOnly(created),
        stars: (r['stars'] as num?)?.toInt() ?? 5,
        comment: r['comment']?.toString() ?? '',
      ));
  }
  return list;
});

String _formatDateOnly(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
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

class _AdminBottomNav extends StatelessWidget {
  const _AdminBottomNav({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0F172A);
    const active = Color(0xFFF97316);
    const inactive = Color(0xFF64748B);

    return Container(
      color: bg,
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: bg,
          selectedItemColor: active,
          unselectedItemColor: inactive,
          onTap: (i) {
            switch (i) {
              case 0:
                context.go(AppRoutes.adminHome);
                return;
              case 1:
                context.go(AppRoutes.adminConductores);
                return;
              case 2:
                context.go(AppRoutes.adminPagos);
                return;
              case 3:
                context.go(AppRoutes.adminMonitoreo);
                return;
              case 4:
              default:
                context.go(AppRoutes.adminAnalitica);
                return;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.directions_bus_rounded), label: 'Conductores'),
            BottomNavigationBarItem(icon: Icon(Icons.attach_money_rounded), label: 'Pagos'),
            BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Monitoreo'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Analítica'),
          ],
        ),
      ),
    );
  }
}
