import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_radius.dart';
import '../../../shared/design/app_spacing.dart';

class NoticiaDetalleScreen extends StatelessWidget {
  const NoticiaDetalleScreen({required this.newsId, super.key});

  final String? newsId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Noticia')),
      body: FutureBuilder<_NewsDetailItem?>(
        future: _loadNews(newsId),
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

          final news = snapshot.data;
          if (news == null) {
            return const Center(child: Text('No se encontró la noticia.'));
          }

          final theme = Theme.of(context);
          final (badgeBg, badgeFg, badgeLabel) = switch (news.type) {
            'incidencia' => (AppColors.seatBadBg, AppColors.error, 'Incidencia'),
            _ => (AppColors.infoSurface, AppColors.primaryBlue, 'Novedad'),
          };

          return SafeArea(
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
                          _initials(news.authorName),
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
                              news.authorName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
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
          );
        },
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

Future<_NewsDetailItem?> _loadNews(String? newsId) async {
  if (newsId == null || newsId.trim().isEmpty) return null;
  final row = await Supabase.instance.client
      .from('news_posts')
      .select('*, profiles(name)')
      .eq('id', newsId)
      .maybeSingle();
  if (row == null) return null;
  return _NewsDetailItem.fromMap(Map<String, dynamic>.from(row));
}

class _NewsDetailItem {
  const _NewsDetailItem({
    required this.type,
    required this.title,
    required this.text,
    required this.authorName,
    required this.dateLabel,
  });

  final String type;
  final String title;
  final String text;
  final String authorName;
  final String dateLabel;

  factory _NewsDetailItem.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] is Map ? Map<String, dynamic>.from(map['profiles'] as Map) : <String, dynamic>{};
    final createdAt = DateTime.tryParse(map['created_at']?.toString() ?? '')?.toLocal();
    final dateLabel = createdAt == null
        ? 'Fecha no disponible'
        : '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
    return _NewsDetailItem(
      type: map['type']?.toString() ?? 'novedad',
      title: map['title']?.toString() ?? 'Sin titulo',
      text: (map['text'] ?? map['body'] ?? '').toString(),
      authorName: profile['name']?.toString().trim().isNotEmpty == true
          ? profile['name'].toString().trim()
          : (map['driver_name']?.toString().trim().isNotEmpty == true
              ? map['driver_name'].toString().trim()
              : 'SDAG'),
      dateLabel: dateLabel,
    );
  }
}
