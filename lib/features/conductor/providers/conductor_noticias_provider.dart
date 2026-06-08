import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/mock/mock_data.dart';

class ConductorNoticiasState {
  const ConductorNoticiasState({required this.items});

  final List<MockNewsPost> items;

  static ConductorNoticiasState initial() => const ConductorNoticiasState(items: []);

  ConductorNoticiasState copyWith({List<MockNewsPost>? items}) =>
      ConductorNoticiasState(items: items ?? this.items);
}

class ConductorNoticiasController extends StateNotifier<ConductorNoticiasState> {
  ConductorNoticiasController() : super(ConductorNoticiasState.initial()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await Supabase.instance.client
          .from('news_posts')
          .select()
          .order('created_at', ascending: false);
      final posts = <MockNewsPost>[];
      for (final r in (rows as List).cast<Map<String, dynamic>>()) {
        final mapped = _fromRow(r);
        if (mapped != null) posts.add(mapped);
      }
      state = state.copyWith(items: posts);
    } catch (_) {}
  }

  Future<void> publicar({
    required MockNewsType type,
    required String title,
    required String description,
  }) async {
    final t = title.trim();
    final d = description.trim();
    final now = DateTime.now();
    final user = Supabase.instance.client.auth.currentUser;
    final profile = user == null
        ? null
        : await Supabase.instance.client
            .from('profiles')
            .select('name')
            .eq('id', user.id)
            .maybeSingle();
    final driverName = profile?['name']?.toString() ?? 'Conductor';

    try {
      final row = await Supabase.instance.client.from('news_posts').insert({
        'type': type.name,
        'title': t,
        'text': d,
        'driver_profile_id': user?.id,
        'driver_name': driverName,
        'created_at': now.toIso8601String(),
      }).select().single();

      final post = _fromRow(row);
      if (post != null) state = state.copyWith(items: [post, ...state.items]);
    } catch (_) {
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');
      final post = MockNewsPost(
        id: 'c_${now.microsecondsSinceEpoch}',
        type: type,
        title: t,
        text: d,
        driverName: driverName,
        dateLabel: 'Hoy $hh:$mm',
      );
      state = state.copyWith(items: [post, ...state.items]);
    }
  }

  MockNewsPost? _fromRow(Map<String, dynamic> r) {
    final id = r['id']?.toString();
    final typeRaw = r['type']?.toString();
    final title = r['title']?.toString();
    final text = r['text']?.toString();
    final driverName = r['driver_name']?.toString();
    final createdAt = DateTime.tryParse(r['created_at']?.toString() ?? '');

    if (id == null || typeRaw == null || title == null || text == null) return null;
    final type = MockNewsType.values
        .where((e) => e.name == typeRaw)
        .cast<MockNewsType?>()
        .firstWhere((e) => e != null, orElse: () => null);
    if (type == null) return null;

    String dateLabel = '—';
    if (createdAt != null) {
      final hh = createdAt.hour.toString().padLeft(2, '0');
      final mm = createdAt.minute.toString().padLeft(2, '0');
      dateLabel = 'Hoy $hh:$mm';
    }

    return MockNewsPost(
      id: id,
      type: type,
      title: title,
      text: text,
      driverName: driverName ?? 'Conductor',
      dateLabel: dateLabel,
    );
  }
}

final conductorNoticiasProvider =
    StateNotifierProvider<ConductorNoticiasController, ConductorNoticiasState>(
  (ref) => ConductorNoticiasController(),
);
