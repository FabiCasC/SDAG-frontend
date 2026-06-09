import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';

class NoticiasScreen extends ConsumerWidget {
  const NoticiasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticiasAsync = ref.watch(passengerNewsPostsProvider);

    return Column(
      children: [
        Material(
          color: Theme.of(context).appBarTheme.backgroundColor,
          child: SafeArea(
            bottom: false,
            child: AppBar(
              title: const Text('Noticias e incidencias'),
              automaticallyImplyLeading: false,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
          ),
        ),
        Expanded(
          child: noticiasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _NewsError(message: error.toString()),
            data: (items) {
              if (items.isEmpty) return const _EmptyNews();
              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.p20),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final n = items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _NewsCard(
                      news: n,
                      onTap: () => context.push(
                        '${AppRoutes.passengerNewsDetail}?id=${n.id}',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.news, required this.onTap});

  final _PassengerNewsPost news;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (badgeBg, badgeFg, badgeLabel) = switch (news.type) {
      'incidencia' => (AppColors.seatBadBg, AppColors.error, 'Incidencia'),
      _ => (AppColors.infoSurface, AppColors.primaryBlue, 'Novedad'),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r16),
      onTap: onTap,
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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      badgeLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: badgeFg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    news.dateLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                news.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                news.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primaryTint12,
                    child: Text(
                      _initials(news.driverName),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      news.driverName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final p = parts.first;
      return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
    }
    return ('${parts[0][0]}${parts[1][0]}').toUpperCase();
  }
}

final passengerNewsPostsProvider = FutureProvider.autoDispose<List<_PassengerNewsPost>>((ref) async {
  final noticias = await Supabase.instance.client
      .from('news_posts')
      .select('*, profiles(name)')
      .order('created_at', ascending: false);

  return (noticias as List)
      .cast<Map<String, dynamic>>()
      .map(_PassengerNewsPost.fromMap)
      .toList();
});

class _PassengerNewsPost {
  const _PassengerNewsPost({
    required this.id,
    required this.type,
    required this.title,
    required this.text,
    required this.driverName,
    required this.dateLabel,
  });

  final String id;
  final String type;
  final String title;
  final String text;
  final String driverName;
  final String dateLabel;

  factory _PassengerNewsPost.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] is Map ? Map<String, dynamic>.from(map['profiles'] as Map) : <String, dynamic>{};
    final createdAt = map['created_at']?.toString() ?? '';
    return _PassengerNewsPost(
      id: map['id'].toString(),
      type: map['type']?.toString() ?? 'novedad',
      title: map['title']?.toString() ?? 'Sin titulo',
      text: (map['text'] ?? map['body'] ?? '').toString(),
      driverName: profile['name']?.toString().trim().isNotEmpty == true
          ? profile['name'].toString().trim()
          : (map['driver_name']?.toString().trim().isNotEmpty == true
              ? map['driver_name'].toString().trim()
              : 'SDAG'),
      dateLabel: _formatNewsDate(createdAt),
    );
  }
}

String _formatNewsDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return 'Fecha no disponible';
  final local = parsed.toLocal();
  final dd = local.day.toString().padLeft(2, '0');
  final mm = local.month.toString().padLeft(2, '0');
  final yyyy = local.year.toString();
  return '$dd/$mm/$yyyy';
}

class _EmptyNews extends StatelessWidget {
  const _EmptyNews();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.newspaper_rounded, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No hay noticias aún',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsError extends StatelessWidget {
  const _NewsError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No se pudieron cargar las noticias',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
