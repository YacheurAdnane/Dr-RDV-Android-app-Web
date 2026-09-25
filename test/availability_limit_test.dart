import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rdv_watch/src/calls.dart';
import 'package:rdv_watch/src/doctolib_api.dart';
import 'package:rdv_watch/src/i18n.dart';
import 'package:rdv_watch/src/models.dart';

/// Answers like Doctolib's /availabilities.json, including its real 400 for a
/// `limit` above 15, and records every query it receives.
MockClient _fakeDoctolib(
  List<Uri> seen, {
  DateTime? nextSlot,
  Map<String, List<String>> slotsByDay = const {},
}) {
  return MockClient((req) async {
    seen.add(req.url);
    final limit = int.parse(req.url.queryParameters['limit']!);
    if (limit > 15) {
      return http.Response(
        jsonEncode({
          'error': ['limit: must be less than or equal to 15']
        }),
        400,
      );
    }
    final start = DateTime.parse(req.url.queryParameters['start_date']!);
    final days = [
      for (var i = 0; i < limit; i++)
        () {
          final d = start.add(Duration(days: i));
          final key = WatchConfig.dateKey(d);
          return {'date': key, 'slots': slotsByDay[key] ?? const <String>[]};
        }(),
    ];
    return http.Response(
      jsonEncode({
        'availabilities': days,
        if (nextSlot != null) 'next_slot': nextSlot.toIso8601String(),
      }),
      200,
    );
  });
}

DoctolibApi _api(MockClient client) =>
    DoctolibApi(client: client, minGap: Duration.zero);

Future<AvailabilityResult> _fetch(DoctolibApi api, int days) =>
    api.availabilities(
      visitMotiveIds: const [1],
      agendaIds: const [2],
      practiceIds: const [3],
      startDate: DateTime(2030, 1, 1),
      days: days,
    );

void main() {
  // Labels are translated; the assertions below are written in French.
  setUpAll(() => I18n.apply('fr'));

  group('the 15-day limit that caused the 400 errors', () {
    test('a long window never asks for more than 15 days at once', () async {
      final seen = <Uri>[];
      final api = _api(_fakeDoctolib(
        seen,
        // Something free near the end, so every chunk has to be fetched.
        slotsByDay: {'2030-01-28': ['2030-01-28T10:00:00.000+01:00']},
        nextSlot: DateTime(2030, 1, 28, 10),
      ));

      final r = await _fetch(api, 30);

      expect(seen, isNotEmpty);
      for (final u in seen) {
        expect(int.parse(u.queryParameters['limit']!), lessThanOrEqualTo(15));
      }
      expect(seen.length, 2, reason: '30 days = two 15-day chunks');
      expect(seen[1].queryParameters['start_date'], '2030-01-16');
      expect(r.slots, hasLength(1));
    });

    test('an empty window stops after one request when Doctolib says the '
        'next slot is further away', () async {
      final seen = <Uri>[];
      final api = _api(_fakeDoctolib(seen, nextSlot: DateTime(2030, 6, 1)));

      final r = await _fetch(api, 45);

      expect(seen, hasLength(1));
      expect(r.slots, isEmpty);
    });

    test('short windows are still a single request', () async {
      final seen = <Uri>[];
      final api = _api(_fakeDoctolib(seen));
      await _fetch(api, 7);
      await _fetch(api, 15);
      expect(seen, hasLength(2));
    });

    test("Doctolib's own explanation ends up in the error message", () async {
      final api = _api(MockClient((_) async => http.Response(
            jsonEncode({
              'error': ['limit: must be less than or equal to 15']
            }),
            400,
          )));
      expect(
        () => _fetch(api, 7),
        throwsA(isA<DoctolibException>().having(
          (e) => e.message,
          'message',
          allOf(contains('400'), contains('less than or equal to 15')),
        )),
      );
    });
  });

  group('window length', () {
    test('a date range is measured from its own start, not from today', () {
      final from = DateTime.now().add(const Duration(days: 20));
      final w = WatchConfig(
        id: 'r',
        title: 'r',
        kind: WatchKind.speciality,
        mode: WindowMode.dateRange,
        from: DateTime(from.year, from.month, from.day),
        to: DateTime(from.year, from.month, from.day).add(const Duration(days: 4)),
      );
      expect(w.daysToScan, 5);
    });

    test('never exceeds 60 days', () {
      final w = WatchConfig(
        id: 'r',
        title: 'r',
        kind: WatchKind.speciality,
        horizonDays: 400,
      );
      expect(w.daysToScan, 60);
    });
  });

  group('self-repair bookkeeping', () {
    test('the error streak and last repair survive a restart', () {
      final w = WatchConfig(id: 'a', title: 'a', kind: WatchKind.speciality)
        ..errorStreak = 2
        ..lastRepairAt = DateTime(2030, 1, 1, 12);
      final back = WatchConfig.fromJson(w.toJson());
      expect(back.errorStreak, 2);
      expect(back.lastRepairAt, DateTime(2030, 1, 1, 12));
    });

    test('errors are only shown from the third failure', () {
      expect(WatchConfig.errorThreshold, 3);
    });
  });

  group('appointment type', () {
    test('speciality and video flag survive a round trip', () {
      final h = SlotHit(
        doctorKey: 'k',
        doctorName: 'Dr X',
        city: 'Lyon',
        address: '',
        motive: 'Premiere consultation',
        speciality: 'Medecin generaliste',
        telehealth: true,
        bookingUrl: 'https://www.doctolib.fr/x',
        when: DateTime(2030, 1, 1, 9),
      );
      final back = SlotHit.fromJson(h.toJson());
      expect(back.speciality, 'Medecin generaliste');
      expect(back.motive, 'Premiere consultation');
      expect(back.telehealth, isTrue);
    });

    test('slots saved by an older build still load', () {
      final back = SlotHit.fromJson({
        'doctorKey': 'k',
        'doctorName': 'Dr X',
        'when': '2030-01-01T09:00:00.000',
      });
      expect(back.speciality, isEmpty);
      expect(back.telehealth, isFalse);
    });
  });

  group('calls', () {
    test('a call carries everything the fallback notification needs', () {
      final c = IncomingCall(
        callId: 1789999999,
        watchId: 'w',
        watchTitle: 'Generaliste Lyon',
        url: 'https://www.doctolib.fr/x',
        doctorName: 'Dr X',
        speciality: 'Medecin generaliste',
        motive: 'Premiere consultation',
        city: 'Lyon',
        when: DateTime(2030, 1, 1, 9),
        telehealth: false,
        slotCount: 3,
        fallbackTitle: 'Generaliste Lyon — 3 creneaux disponibles',
        fallbackBody: 'demain 09h00 · Dr X',
      );
      final json = c.toJson();
      expect(IncomingCall.isCallPayload(json), isTrue);
      final back = IncomingCall.fromJson(json);
      expect(back.callId, c.callId);
      expect(back.url, c.url);
      expect(back.motive, 'Premiere consultation');
      expect(back.slotCount, 3);
      expect(back.fallbackTitle, c.fallbackTitle);
    });

    test('an ordinary notification payload is not mistaken for a call', () {
      expect(IncomingCall.isCallPayload({'watchId': 'w', 'url': ''}), isFalse);
    });

    test('an unknown ringtone falls back to the phone ringtone', () {
      expect(CallSound.byId('does-not-exist').id, 'system_ringtone');
      expect(CallSound.byId('urgent').raw, 'ring_urgent');
    });

    test('every bundled ringtone has a file name', () {
      for (final s in CallSound.all) {
        expect(s.raw != null || s.uri != null, isTrue, reason: s.id);
      }
    });

    test('ringtone choice and duration are remembered', () {
      final s = AppSettings(callSound: 'marimba', callSeconds: 60);
      final back = AppSettings.fromJson(s.toJson());
      expect(back.callSound, 'marimba');
      expect(back.callSeconds, 60);
    });
  });
}
