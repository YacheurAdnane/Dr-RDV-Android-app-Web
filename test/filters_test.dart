import 'package:flutter_test/flutter_test.dart';
import 'package:rdv_watch/src/doctolib_api.dart';
import 'package:rdv_watch/src/i18n.dart';
import 'package:rdv_watch/src/models.dart';
import 'package:rdv_watch/src/rate_guard.dart';

WatchConfig _watch({
  int horizonDays = 3,
  int hourFrom = 0,
  int hourTo = 24,
  Set<int>? weekdays,
}) =>
    WatchConfig(
      id: 't',
      title: 't',
      kind: WatchKind.speciality,
      horizonDays: horizonDays,
      hourFrom: hourFrom,
      hourTo: hourTo,
      weekdays: weekdays,
    );

void main() {
  // Labels are translated; the assertions below are written in French.
  setUpAll(() => I18n.apply('fr'));

  group('slugify', () {
    test('folds accents and punctuation the way Doctolib URLs do', () {
      expect(DoctolibApi.slugify('Lyon'), 'lyon');
      expect(DoctolibApi.slugify('Saint-Étienne'), 'saint-etienne');
      expect(DoctolibApi.slugify('Aix-en-Provence'), 'aix-en-provence');
      expect(DoctolibApi.slugify('Lyon 8'), 'lyon-8');
      expect(DoctolibApi.slugify("Cournon-d'Auvergne"), 'cournon-d-auvergne');
      expect(DoctolibApi.slugify('  Nîmes  '), 'nimes');
    });
  });

  group('window', () {
    test('a slot past the horizon is rejected', () {
      final w = _watch(horizonDays: 3);
      expect(w.accepts(DateTime.now().add(const Duration(days: 1))), isTrue);
      expect(w.accepts(DateTime.now().add(const Duration(days: 10))), isFalse);
    });

    test('a slot already in the past is rejected', () {
      final w = _watch();
      expect(w.accepts(DateTime.now().subtract(const Duration(hours: 2))), isFalse);
    });

    test('an explicit range overrides the horizon', () {
      final start = DateTime.now().add(const Duration(days: 10));
      final end = DateTime.now().add(const Duration(days: 12));
      final w = WatchConfig(
        id: 't',
        title: 't',
        kind: WatchKind.speciality,
        mode: WindowMode.dateRange,
        from: start,
        to: end,
      );
      expect(w.accepts(start.add(const Duration(hours: 2))), isTrue);
      expect(w.accepts(DateTime.now().add(const Duration(days: 1))), isFalse);
      expect(w.accepts(DateTime.now().add(const Duration(days: 20))), isFalse);
    });
  });

  group('client-side filters', () {
    test('hour range keeps only slots inside it', () {
      final w = _watch(hourFrom: 14, hourTo: 18);
      final base = DateTime.now().add(const Duration(days: 1));
      DateTime at(int h) => DateTime(base.year, base.month, base.day, h);
      expect(w.accepts(at(9)), isFalse);
      expect(w.accepts(at(14)), isTrue);
      expect(w.accepts(at(17)), isTrue);
      expect(w.accepts(at(18)), isFalse, reason: 'upper bound is exclusive');
    });

    test('weekday filter drops the days the user cannot attend', () {
      // Keep only Saturdays.
      final w = _watch(horizonDays: 30, weekdays: {DateTime.saturday});
      var d = DateTime.now().add(const Duration(days: 1));
      while (d.weekday != DateTime.saturday) {
        d = d.add(const Duration(days: 1));
      }
      expect(w.accepts(DateTime(d.year, d.month, d.day, 10)), isTrue);
      final sunday = d.add(const Duration(days: 1));
      expect(
        w.accepts(DateTime(sunday.year, sunday.month, sunday.day, 10)),
        isFalse,
      );
    });

    test('filterLabel summarises only the active filters', () {
      expect(_watch().filterLabel, isEmpty);
      final w = _watch(hourFrom: 8, hourTo: 12, weekdays: {1, 2});
      expect(w.filterLabel, contains('8h-12h'));
      expect(w.filterLabel, contains('lun'));
    });
  });

  group('rate guard', () {
    test('backs off further on each consecutive block', () {
      final g = RateGuard();
      g.recordBlock(429);
      final first = g.pauseRemaining;
      g.recordBlock(429);
      final second = g.pauseRemaining;
      expect(second, greaterThan(first));
      expect(g.isPaused, isTrue);
    });

    test('a success clears the pause', () {
      final g = RateGuard()..recordBlock(403);
      expect(g.isPaused, isTrue);
      g.recordSuccess();
      expect(g.isPaused, isFalse);
      expect(g.lastBlockMessage, isNull);
    });

    test('the daily budget is enforced', () {
      final g = RateGuard(maxRequestsPerDay: 3);
      for (var i = 0; i < 3; i++) {
        g.recordRequest();
      }
      expect(g.budgetExhausted, isTrue);
      expect(g.canRun().ok, isFalse);
    });
  });

  group('persistence', () {
    test('a watch survives a JSON round trip with all its filters', () {
      final w = WatchConfig(
        id: 'abc',
        title: 'Pediatre Lyon',
        kind: WatchKind.speciality,
        specialities: const [
          SpecialityRef(id: '3', slug: 'pediatre', name: 'Pediatre')
        ],
        place: const PlaceRef(
          id: 6903,
          name: 'Lyon',
          slug: 'lyon',
          country: 'fr',
          type: 'locality',
          lat: 45.76,
          lng: 4.83,
          neLat: 45.8,
          neLng: 4.9,
          swLat: 45.7,
          swLng: 4.77,
        ),
        horizonDays: 5,
        hourFrom: 9,
        hourTo: 17,
        weekdays: {1, 3, 5},
        onlyNewPatients: true,
      );
      w.seen.add('k|2030-01-01T10:00:00.000');

      final back = WatchConfig.fromJson(
        WatchConfig.fromJson(w.toJson()).toJson(),
      );
      expect(back.title, w.title);
      expect(back.specialities.single.slug, 'pediatre');
      expect(back.place!.lat, closeTo(45.76, 0.001));
      expect(back.horizonDays, 5);
      expect(back.hourFrom, 9);
      expect(back.hourTo, 17);
      expect(back.weekdays, {1, 3, 5});
      expect(back.onlyNewPatients, isTrue);
      expect(back.seen, contains('k|2030-01-01T10:00:00.000'));
    });

    test('the place payload carries the GPS point the search API demands', () {
      const p = PlaceRef(
        id: 6903,
        name: 'Lyon',
        slug: 'lyon',
        country: 'fr',
        type: 'locality',
        lat: 45.76,
        lng: 4.83,
        neLat: 45.8,
        neLng: 4.9,
        swLat: 45.7,
        swLng: 4.77,
      );
      final payload = p.toSearchPayload();
      expect(payload['gpsPoint'], {'lat': 45.76, 'lng': 4.83});
      expect(payload['viewport'], isA<Map<String, dynamic>>());
      expect(payload.containsKey('zipcodes'), isFalse);
    });
  });

  group('alert style', () {
    test('defaults to a normal notification and survives a round trip', () {
      final w = WatchConfig(id: 'a', title: 'a', kind: WatchKind.speciality);
      expect(w.alertStyle, AlertStyle.normal);

      w.alertStyle = AlertStyle.call;
      final back = WatchConfig.fromJson(w.toJson());
      expect(back.alertStyle, AlertStyle.call);
    });

    test('an unknown style from a future build falls back to normal', () {
      final w = WatchConfig(id: 'a', title: 'a', kind: WatchKind.speciality);
      final json = w.toJson()..['alertStyle'] = 'telepathy';
      expect(WatchConfig.fromJson(json).alertStyle, AlertStyle.normal);
    });

    test('every style has a label and an explanation', () {
      for (final s in AlertStyle.values) {
        expect(s.label, isNotEmpty);
        expect(s.description, isNotEmpty);
      }
    });
  });

  group('quiet hours', () {
    AppSettings at(int from, int to) =>
        AppSettings(quietEnabled: true, quietFromHour: from, quietToHour: to);

    test('a window that wraps past midnight covers both sides of it', () {
      final h = DateTime.now().hour;
      // Quiet for every hour except the current one: "now" must be loud.
      expect(at((h + 1) % 24, h).isQuietNow, isFalse);
      // Quiet for a window that certainly contains the current hour.
      expect(at(h, (h + 1) % 24).isQuietNow, isTrue);
    });

    test('disabling it silences the whole mechanism', () {
      final h = DateTime.now().hour;
      final s = at(h, (h + 1) % 24)..quietEnabled = false;
      expect(s.isQuietNow, isFalse);
    });

    test('an empty window is never quiet', () {
      expect(at(9, 9).isQuietNow, isFalse);
    });
  });

  group('friendly wording', () {
    test('the interval reads as a person would say it', () {
      expect(AppSettings(intervalMinutes: 30).intervalLabel,
          'toutes les 30 minutes');
      expect(AppSettings(intervalMinutes: 60).intervalLabel, 'toutes les heures');
      expect(AppSettings(intervalMinutes: 180).intervalLabel,
          'toutes les 3 heures');
    });

    test('the request ceiling has a plain-language name', () {
      expect(AppSettings(maxRequestsPerDay: 200).budgetLabel, 'Très prudent');
      expect(AppSettings(maxRequestsPerDay: 800).budgetLabel, 'Équilibré');
      expect(AppSettings(maxRequestsPerDay: 3000).budgetLabel, 'Maximum');
    });

    test('onboarding is remembered once done', () {
      final s = AppSettings()..onboardingDone = true;
      expect(AppSettings.fromJson(s.toJson()).onboardingDone, isTrue);
      expect(AppSettings().onboardingDone, isFalse);
    });
  });

  group('ignore lists', () {
    SlotHit hit(String doctor, DateTime when) => SlotHit(
          doctorKey: doctor,
          doctorName: doctor,
          city: '',
          address: '',
          motive: '',
          bookingUrl: '',
          when: when,
        );

    test('ignoring one slot leaves its siblings alone', () {
      final w = _watch(horizonDays: 30);
      final a = hit('dr-a', DateTime.now().add(const Duration(days: 1)));
      final b = hit('dr-a', DateTime.now().add(const Duration(days: 2)));
      w.lastHits = [a, b];

      w.ignoredSlots.add(a.id);
      expect(w.isIgnored(a), isTrue);
      expect(w.isIgnored(b), isFalse);
      expect(w.visibleHits, [b]);
    });

    test('ignoring a date hides every slot that day, whoever the doctor', () {
      final w = _watch(horizonDays: 30);
      final day = DateTime.now().add(const Duration(days: 2));
      final a = hit('dr-a', DateTime(day.year, day.month, day.day, 9));
      final b = hit('dr-b', DateTime(day.year, day.month, day.day, 16));
      final other = hit('dr-a', day.add(const Duration(days: 1)));
      w.lastHits = [a, b, other];

      w.ignoredDates.add(WatchConfig.dateKey(day));
      expect(w.visibleHits, [other]);
    });

    test('ignoring a doctor hides them on every date', () {
      final w = _watch(horizonDays: 30);
      final a = hit('dr-a', DateTime.now().add(const Duration(days: 1)));
      final b = hit('dr-a', DateTime.now().add(const Duration(days: 4)));
      final c = hit('dr-b', DateTime.now().add(const Duration(days: 2)));
      w.lastHits = [a, b, c];

      w.ignoredDoctors.add('dr-a');
      expect(w.visibleHits, [c]);
      expect(w.ignoredCount, 1);
    });

    test('ignore state survives a round trip', () {
      final w = _watch();
      w.ignoredSlots.add('dr-a|2030-01-01T10:00:00.000');
      w.ignoredDates.add('2030-01-02');
      w.ignoredDoctors.add('dr-b');
      w.freshIds.add('dr-c|2030-01-03T10:00:00.000');

      final back = WatchConfig.fromJson(w.toJson());
      expect(back.ignoredSlots, w.ignoredSlots);
      expect(back.ignoredDates, w.ignoredDates);
      expect(back.ignoredDoctors, w.ignoredDoctors);
      expect(back.freshIds, w.freshIds);
      expect(back.hasIgnores, isTrue);
    });
  });

  group('teleconsultation', () {
    test('defaults to accepting either kind', () {
      expect(_watch().teleconsult, TeleconsultMode.any);
      expect(_watch().filterLabel, isEmpty);
    });

    test('a chosen mode shows up in the filter summary', () {
      final w = _watch()..teleconsult = TeleconsultMode.online;
      expect(w.filterLabel, contains('vidéo'));
    });

    test('the old excludeTelehealth flag migrates to "au cabinet"', () {
      final legacy = _watch().toJson()
        ..remove('teleconsult')
        ..['excludeTelehealth'] = true;
      expect(WatchConfig.fromJson(legacy).teleconsult, TeleconsultMode.inPerson);

      final legacyOff = _watch().toJson()
        ..remove('teleconsult')
        ..['excludeTelehealth'] = false;
      expect(WatchConfig.fromJson(legacyOff).teleconsult, TeleconsultMode.any);
    });
  });

  group('snooze', () {
    test('a snoozed watch is enabled but not active', () {
      final w = _watch()..snoozedUntil = DateTime.now().add(const Duration(hours: 2));
      expect(w.enabled, isTrue);
      expect(w.isSnoozed, isTrue);
      expect(w.isActive, isFalse);
    });

    test('an elapsed snooze wakes the watch on its own', () {
      final w = _watch()
        ..snoozedUntil = DateTime.now().subtract(const Duration(minutes: 1));
      expect(w.isSnoozed, isFalse);
      expect(w.isActive, isTrue);
    });

    test('a disabled watch is never active', () {
      final w = _watch()..enabled = false;
      expect(w.isActive, isFalse);
    });
  });
}
