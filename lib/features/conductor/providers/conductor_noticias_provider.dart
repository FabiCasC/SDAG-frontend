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

  Future<void> reload() => _load();

  Future<void> publicar({
    required MockNewsType type,
    required String title,
    required String description,
  }) async {
    final t = title.trim();
    final d = description.trim();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('No hay una sesión activa.');

    final driver = await Supabase.instance.client
        .from('drivers')
        .select('id, plate, profiles(name)')
        .eq('profile_id', user.id)
        .single();

    await Supabase.instance.client.from('news_posts').insert({
      'type': type.name,
      'title': t,
      'body': d,
      'author_driver_id': driver['id'],
      'driver_profile_id': user.id,
      'driver_name': (driver['profiles'] as Map)['name'],
    });

    await _load();
  }

  MockNewsPost? _fromRow(Map<String, dynamic> r) {
    final id = r['id']?.toString();
    final typeRaw = r['type']?.toString();
    final title = r['title']?.toString();
    final text = (r['body'] ?? r['text'])?.toString();
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
