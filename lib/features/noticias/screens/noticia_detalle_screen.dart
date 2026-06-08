import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/mock/mock_data.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';

class NoticiaDetalleScreen extends StatelessWidget {
  const NoticiaDetalleScreen({required this.newsId, this.posts, super.key});

  final String? newsId;
  final List<MockNewsPost>? posts;

  @override
  Widget build(BuildContext context) {
    final source = posts ?? MockData.newsPosts;
    final news = source.where((n) => n.id == newsId).cast<MockNewsPost?>().firstOrNull;
    if (news == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(title: const Text('Noticia')),
        body: const Center(child: Text('No se encontró la noticia.')),
      );
    }

    final theme = Theme.of(context);
    final (badgeBg, badgeFg, badgeLabel) = switch (news.type) {
      MockNewsType.incidencia => (AppColors.seatBadBg, AppColors.error, 'Incidencia'),
      MockNewsType.novedad => (AppColors.infoSurface, AppColors.primaryBlue, 'Novedad'),
    };

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          news.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.p20),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
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
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              news.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              news.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16,
                height: 22 / 16,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.border),
            const SizedBox(height: AppSpacing.lg),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.r16),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryTint12,
                    child: Text(
                      _initials(news.driverName),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          news.driverName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Conductor verificado',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          news.dateLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
                minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
              ),
              child: const Text('← Volver al listado'),
            ),
          ],
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
