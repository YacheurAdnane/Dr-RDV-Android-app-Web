import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notifications.dart';
import 'store.dart';
import 'i18n.dart';

/// Everything needed to ring for a slot, and to fall back to an ordinary
/// notification if the call is refused or goes unanswered.
///
/// Travels inside the notification payload, so it must survive the app being
/// killed between the ring and the user's answer.
class IncomingCall {
  const IncomingCall({
    required this.callId,
    required this.watchId,
    required this.watchTitle,
    required this.url,
    required this.doctorName,
    required this.speciality,
    required this.motive,
    required this.city,
    required this.when,
    required this.telehealth,
    required this.slotCount,
    required this.fallbackTitle,
    required this.fallbackBody,
  });

  /// Doubles as the Android notification id.
  final int callId;
  final String watchId;
  final String watchTitle;
  final String url;
  final String doctorName;
  final String speciality;
  final String motive;
  final String city;
  final DateTime when;
  final bool telehealth;

  /// How many new slots this call stands for (the first one is shown).
  final int slotCount;

  /// The ordinary notification left behind when the call is not taken.
  final String fallbackTitle;
  final String fallbackBody;

  Map<String, dynamic> toJson() => {
        'type': 'call',
        'callId': callId,
        'watchId': watchId,
        'watchTitle': watchTitle,
        'url': url,
        'doctorName': doctorName,
        'speciality': speciality,
        'motive': motive,
        'city': city,
        'when': when.toIso8601String(),
        'telehealth': telehealth,
        'slotCount': slotCount,
        'fallbackTitle': fallbackTitle,
        'fallbackBody': fallbackBody,
      };

  factory IncomingCall.fromJson(Map<String, dynamic> j) => IncomingCall(
        callId: (j['callId'] as num).toInt(),
        watchId: j['watchId'] as String? ?? '',
        watchTitle: j['watchTitle'] as String? ?? '',
        url: j['url'] as String? ?? '',
        doctorName: j['doctorName'] as String? ?? '',
        speciality: j['speciality'] as String? ?? '',
        motive: j['motive'] as String? ?? '',
        city: j['city'] as String? ?? '',
        when: DateTime.tryParse(j['when'] as String? ?? '') ?? DateTime.now(),
        telehealth: j['telehealth'] as bool? ?? false,
        slotCount: (j['slotCount'] as num?)?.toInt() ?? 1,
        fallbackTitle: j['fallbackTitle'] as String? ?? tr.callAvailable,
        fallbackBody: j['fallbackBody'] as String? ?? '',
      );

  static bool isCallPayload(Map<String, dynamic> j) => j['type'] == 'call';
}

/// Which calls have already been answered or refused.
///
/// Kept in SharedPreferences because the answer can come from three different
/// isolates (UI, notification-action background isolate, WorkManager), and the
/// missed-call check must see all of them.
class CallLedger {
  static const _prefix = 'call_handled_';

  static Future<bool> isHandled(int callId) async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    return p.getBool('$_prefix$callId') ?? false;
  }

  /// Marks the call as dealt with. Returns false when someone else got there
  /// first, so each outcome (accept, refuse, missed) happens exactly once.
  static Future<bool> claim(int callId) async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    if (p.getBool('$_prefix$callId') ?? false) return false;
    await p.setBool('$_prefix$callId', true);
    await _prune(p);
    return true;
  }

  /// Keeps the ledger from growing forever: call ids are epoch seconds, so
  /// anything older than a day is safe to forget.
  static Future<void> _prune(SharedPreferences p) async {
    final cutoff =
        DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch ~/
            1000;
    for (final key in p.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
      final id = int.tryParse(key.substring(_prefix.length));
      if (id != null && id < cutoff) await p.remove(key);
    }
  }
}

/// "Refuser" tapped while the app is not in the foreground.
///
/// Runs in a fresh background isolate spawned by the notification plugin, so
/// it re-initialises what it needs from scratch.
@pragma('vm:entry-point')
Future<void> onBackgroundNotificationAction(NotificationResponse response) async {
  DartPluginRegistrant.ensureInitialized();
  // A fresh isolate starts in the default language: load the user's choice.
  await I18n.apply((await Store().loadSettings()).language);
  await Notifications.instance.handleResponse(response, background: true);
}
