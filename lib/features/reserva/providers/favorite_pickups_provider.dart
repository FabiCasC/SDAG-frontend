import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritePickupsController extends StateNotifier<List<String>> {
  FavoritePickupsController() : super(const <String>[]) {
    _load();
  }

  static const _prefsKey = 'sdag_favorite_pickups';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey) ?? const <String>[];
    state = stored.map((e) => e.trim()).where((e) => e.length >= 3).toList();
  }

  Future<void> add(String value) async {
    final v = value.trim();
    if (v.length < 3) return;
    final next = [...state];
    if (!next.contains(v)) next.add(v);
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, next);
  }

  Future<void> remove(String value) async {
    final next = state.where((e) => e != value).toList();
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, next);
  }
}

final favoritePickupsProvider =
    StateNotifierProvider<FavoritePickupsController, List<String>>(
  (ref) => FavoritePickupsController(),
);
