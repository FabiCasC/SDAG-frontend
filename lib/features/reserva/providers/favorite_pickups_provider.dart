import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritePickupsController extends StateNotifier<List<String>> {
  FavoritePickupsController() : super(const <String>[]) {
    _load();
  }

  static const _prefsKey = 'sdag_favorite_pickups';

  static const _defaults = <String>[
    'Cruce con Av. Javier Prado, frente al grifo',
    'Paradero principal, costado del parque',
  ];

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey) ?? const <String>[];
    state = _merge(_defaults, stored);
  }

  Future<void> add(String value) async {
    final v = value.trim();
    if (v.length < 3) return;
    final next = _merge(state, [v]);
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, next.where((e) => !_defaults.contains(e)).toList());
  }

  Future<void> remove(String value) async {
    final next = state.where((e) => e != value).toList();
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, next.where((e) => !_defaults.contains(e)).toList());
  }

  static List<String> _merge(List<String> a, List<String> b) {
    final seen = <String>{};
    final out = <String>[];
    for (final item in [...a, ...b]) {
      final v = item.trim();
      if (v.isEmpty) continue;
      if (seen.add(v)) out.add(v);
    }
    return out;
  }
}

final favoritePickupsProvider =
    StateNotifierProvider<FavoritePickupsController, List<String>>(
  (ref) => FavoritePickupsController(),
);

