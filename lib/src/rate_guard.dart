import 'dart:convert';
import 'dart:math';
import 'i18n.dart';

/// Keeps the app a well-behaved visitor of doctolib.fr.
///
/// The goal is not to hide from Doctolib, it is to never be worth blocking:
/// a low, jittered request rate, a hard daily ceiling, and a real retreat when
/// the server pushes back. A single phone polling politely every half hour is
/// a rounding error next to the traffic a browsing human generates; a tight
/// loop is what gets an address throttled.
///
/// The state is persisted so a block survives an app restart or a background
/// isolate being torn down and recreated.
class RateGuard {
  RateGuard({
    this.maxRequestsPerDay = 800,
    this.dayKey = '',
    this.requestsToday = 0,
    this.consecutiveBlocks = 0,
    this.pausedUntil,
    this.lastBlockMessage,
  });

  /// Ceiling for a 24 h period, counted across every watch.
  int maxRequestsPerDay;

  String dayKey;
  int requestsToday;

  /// How many times in a row Doctolib answered 403 / 429.
  int consecutiveBlocks;

  /// Nothing is sent before this instant.
  DateTime? pausedUntil;

  String? lastBlockMessage;

  static final Random _rng = Random();

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  void _rollDay() {
    final today = _todayKey();
    if (dayKey != today) {
      dayKey = today;
      requestsToday = 0;
    }
  }

  bool get isPaused =>
      pausedUntil != null && DateTime.now().isBefore(pausedUntil!);

  Duration get pauseRemaining => isPaused
      ? pausedUntil!.difference(DateTime.now())
      : Duration.zero;

  bool get budgetExhausted {
    _rollDay();
    return requestsToday >= maxRequestsPerDay;
  }

  /// Whether a check may run at all right now.
  ({bool ok, String? reason}) canRun() {
    if (isPaused) {
      final m = pauseRemaining.inMinutes + 1;
      return (ok: false, reason: tr.guardPaused(m));
    }
    if (budgetExhausted) {
      return (ok: false, reason: tr.guardQuota(maxRequestsPerDay));
    }
    return (ok: true, reason: null);
  }

  /// How many requests are still allowed today.
  int get remainingToday {
    _rollDay();
    return (maxRequestsPerDay - requestsToday).clamp(0, maxRequestsPerDay);
  }

  void recordRequest() {
    _rollDay();
    requestsToday++;
  }

  /// A normal answer: forget any previous push-back.
  void recordSuccess() {
    if (consecutiveBlocks != 0 || pausedUntil != null) {
      consecutiveBlocks = 0;
      pausedUntil = null;
      lastBlockMessage = null;
    }
  }

  /// Doctolib said 403 or 429. Retreat, and retreat longer each time.
  ///
  /// 15 min, 30 min, 1 h, 2 h, 4 h, then capped at 6 h.
  void recordBlock(int statusCode) {
    consecutiveBlocks++;
    final steps = [15, 30, 60, 120, 240, 360];
    final minutes = steps[min(consecutiveBlocks - 1, steps.length - 1)];
    pausedUntil = DateTime.now().add(Duration(minutes: minutes));
    lastBlockMessage = statusCode == 429
        ? tr.guardRateLimited(minutes)
        : tr.guardRefused(statusCode, minutes);
  }

  /// A small random delay so requests never land on a perfect clock tick.
  static Duration jitter([int maxMillis = 900]) =>
      Duration(milliseconds: _rng.nextInt(maxMillis));

  Map<String, dynamic> toJson() => {
        'maxRequestsPerDay': maxRequestsPerDay,
        'dayKey': dayKey,
        'requestsToday': requestsToday,
        'consecutiveBlocks': consecutiveBlocks,
        'pausedUntil': pausedUntil?.toIso8601String(),
        'lastBlockMessage': lastBlockMessage,
      };

  factory RateGuard.fromJson(Map<String, dynamic> j) => RateGuard(
        maxRequestsPerDay: (j['maxRequestsPerDay'] as num?)?.toInt() ?? 800,
        dayKey: j['dayKey'] as String? ?? '',
        requestsToday: (j['requestsToday'] as num?)?.toInt() ?? 0,
        consecutiveBlocks: (j['consecutiveBlocks'] as num?)?.toInt() ?? 0,
        pausedUntil: j['pausedUntil'] == null
            ? null
            : DateTime.tryParse(j['pausedUntil'] as String),
        lastBlockMessage: j['lastBlockMessage'] as String?,
      );

  String encode() => jsonEncode(toJson());
}
