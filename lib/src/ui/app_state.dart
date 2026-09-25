import 'package:flutter/foundation.dart';

import '../background.dart';
import '../engine.dart';
import '../models.dart';
import '../notifications.dart';
import '../rate_guard.dart';
import '../store.dart';
import '../i18n.dart';

/// Single source of truth for the UI.
///
/// Held as one object rather than threaded through a state-management package:
/// the app has one list and one settings blob, and the background isolate
/// re-reads the store anyway.
class AppState extends ChangeNotifier {
  AppState({Store? store}) : store = store ?? Store();

  final Store store;

  List<WatchConfig> watches = [];
  AppSettings settings = AppSettings();
  RateGuard guard = RateGuard();

  bool loading = true;
  bool checking = false;
  String? lastMessage;

  Future<void> load() async {
    watches = await store.loadWatches();
    settings = await store.loadSettings();
    guard = await store.loadGuard();
    loading = false;
    notifyListeners();
    await refreshStatus();
  }

  /// Rewrites the permanent status notification.
  ///
  /// Called after anything that changes what it should say, so the badge never
  /// shows a state the user has already moved on from.
  Future<void> refreshStatus() =>
      CheckEngine(store: store).refreshStatus(settings);

  Future<void> reloadFromDisk() async {
    watches = await store.loadWatches();
    guard = await store.loadGuard();
    notifyListeners();
  }

  WatchConfig? byId(String id) {
    for (final w in watches) {
      if (w.id == id) return w;
    }
    return null;
  }

  Future<void> addWatch(WatchConfig w) async {
    watches = [...watches, w];
    await store.saveWatches(watches);
    notifyListeners();
    await checkNow(watchId: w.id, notify: false);
    await refreshStatus();
  }

  Future<void> updateWatch(WatchConfig w) async {
    final i = watches.indexWhere((x) => x.id == w.id);
    if (i >= 0) watches[i] = w;
    await store.saveWatches(watches);
    notifyListeners();
    await refreshStatus();
  }

  Future<void> deleteWatch(String id) async {
    watches = watches.where((w) => w.id != id).toList();
    await store.saveWatches(watches);
    notifyListeners();
    await refreshStatus();
  }

  Future<void> toggleWatch(WatchConfig w, bool enabled) async {
    w.enabled = enabled;
    await updateWatch(w);
  }

  Future<void> saveSettings(AppSettings s) async {
    // Compared with the language in force, not the old settings object: the
    // caller may have edited that very object in place.
    final languageChanged = I18n.resolve(s.language) != I18n.locale;
    settings = s;
    await I18n.apply(s.language);
    await store.saveSettings(s);
    guard.maxRequestsPerDay = s.maxRequestsPerDay;
    await store.saveGuard(guard);
    await BackgroundScheduler.schedule(s.intervalMinutes);
    if (languageChanged) {
      // Recreates the channels so Android settings show the new names too.
      await Notifications.instance.refreshChannels();
    }
    notifyListeners();
    await refreshStatus();
  }

  /// Runs the checks right now. [watchId] limits it to a single alert.
  Future<List<CheckOutcome>> checkNow({String? watchId, bool notify = true}) async {
    if (checking) return const [];
    checking = true;
    lastMessage = null;
    notifyListeners();
    try {
      final engine = CheckEngine(store: store);
      final outcomes = await engine.runAll(
        notify: notify,
        force: true,
        onlyWatchId: watchId,
      );
      await reloadFromDisk();
      final failed = outcomes.where((o) => o.failed).toList();
      final repairing = outcomes.where((o) => o.note != null).toList();
      if (failed.isNotEmpty) {
        lastMessage = failed.first.error;
      } else if (repairing.isNotEmpty) {
        lastMessage = repairing.first.note;
      } else {
        final fresh = outcomes.fold<int>(0, (n, o) => n + o.freshHits.length);
        final total = outcomes.fold<int>(0, (n, o) => n + o.hits.length);
        lastMessage = fresh > 0
            ? tr.msgNewSlots(fresh)
            : total > 0
                ? tr.msgNothingNew(tr.slotsCount(total))
                : tr.msgNoSlots;
      }
      return outcomes;
    } finally {
      checking = false;
      notifyListeners();
    }
  }

  /// Estimated requests a full pass costs, and roughly per day.
  ({int perRun, int perDay}) get requestEstimate {
    final perRun = CheckEngine.estimateRequestsPerRun(watches, settings);
    var activeHours = 24;
    if (settings.quietEnabled) {
      final quiet = settings.quietFromHour < settings.quietToHour
          ? settings.quietToHour - settings.quietFromHour
          : 24 - settings.quietFromHour + settings.quietToHour;
      activeHours = (24 - quiet).clamp(1, 24);
    }
    final runsPerDay = (activeHours * 60 / settings.intervalMinutes).round();
    return (perRun: perRun, perDay: perRun * runsPerDay);
  }
}
