import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'rate_guard.dart';

/// Everything the app persists.
///
/// Deliberately plain JSON in SharedPreferences: the background isolate has no
/// access to the UI's objects and has to re-read the same state from scratch,
/// so the store must work identically from either side.
class Store {
  static const _kWatches = 'watches_v1';
  static const _kSettings = 'settings_v1';
  static const _kGuard = 'rate_guard_v1';

  Future<SharedPreferences> get _prefs async {
    final p = await SharedPreferences.getInstance();
    // The UI isolate and the background isolate each hold their own in-memory
    // cache, so without this a check written in the background would be
    // invisible to the UI until the process restarted.
    await p.reload();
    return p;
  }

  Future<List<WatchConfig>> loadWatches() async {
    final p = await _prefs;
    final raw = p.getStringList(_kWatches) ?? const [];
    final out = <WatchConfig>[];
    for (final s in raw) {
      try {
        out.add(WatchConfig.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // A watch written by an older build: drop it rather than crash.
      }
    }
    return out;
  }

  Future<void> saveWatches(List<WatchConfig> watches) async {
    final p = await _prefs;
    await p.setStringList(_kWatches, watches.map((w) => w.encode()).toList());
  }

  /// Rewrites a single watch in place, leaving the others untouched.
  ///
  /// The background isolate and the UI can both be alive at once, so a check
  /// result must never clobber an edit the user just made to another watch.
  Future<void> upsertWatch(WatchConfig watch) async {
    final all = await loadWatches();
    final i = all.indexWhere((w) => w.id == watch.id);
    if (i >= 0) {
      all[i] = watch;
    } else {
      all.add(watch);
    }
    await saveWatches(all);
  }

  Future<void> deleteWatch(String id) async {
    final all = await loadWatches();
    all.removeWhere((w) => w.id == id);
    await saveWatches(all);
  }

  Future<AppSettings> loadSettings() async {
    final p = await _prefs;
    final raw = p.getString(_kSettings);
    if (raw == null) return AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings s) async {
    final p = await _prefs;
    await p.setString(_kSettings, jsonEncode(s.toJson()));
  }

  Future<RateGuard> loadGuard() async {
    final p = await _prefs;
    final raw = p.getString(_kGuard);
    if (raw == null) return RateGuard();
    try {
      return RateGuard.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return RateGuard();
    }
  }

  Future<void> saveGuard(RateGuard g) async {
    final p = await _prefs;
    await p.setString(_kGuard, g.encode());
  }
}
