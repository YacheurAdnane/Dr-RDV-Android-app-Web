import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum JournalKind { found, nothing, error, callAccepted, callDeclined, callMissed }

/// One thing the app did. Stored as data, not text, so the log reads in
/// whatever language the app is in when it is opened.
class JournalEntry {
  const JournalEntry({
    required this.at,
    required this.kind,
    this.title = '',
    this.slots = 0,
    this.fresh = 0,
    this.detail,
    this.background = false,
  });

  final DateTime at;
  final JournalKind kind;
  final String title;
  final int slots;
  final int fresh;
  final String? detail;

  /// Run by the periodic task rather than by a tap in the app: the proof
  /// that background checking actually happens on this phone.
  final bool background;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'kind': kind.name,
        'title': title,
        'slots': slots,
        'fresh': fresh,
        'detail': detail,
        'bg': background,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        at: DateTime.parse(j['at'] as String),
        kind: JournalKind.values.firstWhere(
          (k) => k.name == j['kind'],
          orElse: () => JournalKind.nothing,
        ),
        title: j['title'] as String? ?? '',
        slots: (j['slots'] as num?)?.toInt() ?? 0,
        fresh: (j['fresh'] as num?)?.toInt() ?? 0,
        detail: j['detail'] as String?,
        background: j['bg'] as bool? ?? false,
      );
}

/// A bounded log of checks and calls, newest first.
///
/// Shared by the UI and background isolates through SharedPreferences; each
/// write re-reads first so neither side erases the other's entries.
class Journal {
  static const _key = 'journal_v1';

  /// About a week of half-hourly checks for a couple of alerts.
  static const int capacity = 400;

  static Future<SharedPreferences> _prefs() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    return p;
  }

  static Future<List<JournalEntry>> load() async {
    final p = await _prefs();
    final out = <JournalEntry>[];
    for (final s in p.getStringList(_key) ?? const <String>[]) {
      try {
        out.add(JournalEntry.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // An entry from a future build: skip it.
      }
    }
    return out;
  }

  static Future<void> add(JournalEntry e) => addAll([e]);

  static Future<void> addAll(List<JournalEntry> entries) async {
    if (entries.isEmpty) return;
    final p = await _prefs();
    final list = p.getStringList(_key) ?? <String>[];
    list.insertAll(0, entries.reversed.map((e) => jsonEncode(e.toJson())));
    if (list.length > capacity) list.removeRange(capacity, list.length);
    await p.setStringList(_key, list);
  }

  static Future<void> clear() async {
    final p = await _prefs();
    await p.remove(_key);
  }

  /// The hour of day when new slots were found most often, or null when
  /// there is not enough history to say.
  ///
  /// Practices tend to release cancellations at set times (the secretary's
  /// first hour, the evening before); knowing it tells the user when to be
  /// ready, and when a tighter check interval would pay off.
  static int? busiestHour(List<JournalEntry> entries, {int minFinds = 3}) {
    final byHour = <int, int>{};
    var finds = 0;
    for (final e in entries) {
      if (e.kind == JournalKind.found && e.fresh > 0) {
        byHour[e.at.hour] = (byHour[e.at.hour] ?? 0) + e.fresh;
        finds++;
      }
    }
    if (finds < minFinds || byHour.isEmpty) return null;
    return byHour.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }
}
