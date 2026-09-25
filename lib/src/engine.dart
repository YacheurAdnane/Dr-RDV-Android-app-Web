import 'dart:math';

import 'doctolib_api.dart';
import 'journal.dart';
import 'models.dart';
import 'notifications.dart';
import 'rate_guard.dart';
import 'store.dart';
import 'zone.dart';
import 'i18n.dart';

class CheckOutcome {
  CheckOutcome({
    required this.watchId,
    required this.hits,
    required this.freshHits,
    required this.requests,
    this.error,
    this.blocked = false,
    this.note,
  });

  /// Doctolib rate-limited us; the whole run stops.
  final bool blocked;

  /// A failure the automatic repair is still working on, not yet worth
  /// presenting as an error.
  final String? note;

  final String watchId;

  /// Every slot currently matching the watch.
  final List<SlotHit> hits;

  /// The subset that had never been announced before.
  final List<SlotHit> freshHits;

  final int requests;
  final String? error;

  bool get failed => error != null;
}

/// Runs the watches and decides what deserves a notification.
///
/// The same code path serves the foreground refresh and the background task,
/// so there is only one definition of "a new slot".
class CheckEngine {
  CheckEngine({required this.store});

  final Store store;

  /// Checks every enabled watch, notifies, and writes the results back.
  ///
  /// Returns one outcome per watch that actually ran.
  ///
  /// [awaitCalls] makes the run wait until every "call me" ring it started has
  /// been answered or has timed out, so the missed-call fallback is posted.
  /// The background task needs that (its isolate dies when it returns); the UI
  /// does not, and would otherwise spin for the length of a ring.
  Future<List<CheckOutcome>> runAll({
    bool notify = true,
    bool force = false,
    String? onlyWatchId,
    bool awaitCalls = false,
    bool background = false,
  }) async {
    final settings = await store.loadSettings();
    final guard = await store.loadGuard();
    guard.maxRequestsPerDay = settings.maxRequestsPerDay;

    if (!force && settings.isQuietNow) {
      // Silent hours are also a free way to halve the daily request count.
      await refreshStatus(settings);
      return const [];
    }

    final gate = guard.canRun();
    if (!gate.ok) {
      await store.saveGuard(guard);
      if (notify && guard.lastBlockMessage != null) {
        await Notifications.instance
            .notifyStatus(tr.monitoringPaused, guard.lastBlockMessage!);
      }
      return [
        CheckOutcome(
          watchId: onlyWatchId ?? '',
          hits: const [],
          freshHits: const [],
          requests: 0,
          error: gate.reason,
        )
      ];
    }

    final watches = await store.loadWatches();
    final todo = watches
        .where((w) => onlyWatchId == null ? w.isActive : w.id == onlyWatchId)
        .toList();
    if (todo.isEmpty) {
      await refreshStatus(settings);
      return const [];
    }

    final api = DoctolibApi(guard: guard);
    final outcomes = <CheckOutcome>[];
    final rings = <Future<void>>[];
    try {
      for (final watch in todo) {
        final before = guard.requestsToday;
        final outcome = await _runOne(
          api: api,
          watch: watch,
          settings: settings,
          notify: notify,
          requestsBefore: before,
          rings: rings,
        );
        outcomes.add(outcome);
        await Journal.add(_journalEntry(watch, outcome, background));

        if (outcome.blocked) {
          if (notify) {
            await Notifications.instance
                .notifyStatus(tr.monitoringPaused, outcome.error!);
          }
          break;
        }

        // Breathe between watches rather than firing them back to back.
        if (watch != todo.last) {
          await Future.delayed(
            const Duration(seconds: 2) + RateGuard.jitter(1500),
          );
        }
      }
    } finally {
      api.close();
      await store.saveGuard(guard);
      await refreshStatus(settings);
    }
    if (awaitCalls && rings.isNotEmpty) await Future.wait(rings);
    return outcomes;
  }

  static JournalEntry _journalEntry(
    WatchConfig watch,
    CheckOutcome o,
    bool background,
  ) {
    final visible = o.hits.where((h) => !watch.isIgnored(h)).length;
    return JournalEntry(
      at: DateTime.now(),
      title: watch.title,
      background: background,
      kind: o.error != null
          ? JournalKind.error
          : visible > 0
              ? JournalKind.found
              : JournalKind.nothing,
      slots: visible,
      fresh: o.freshHits.length,
      detail: o.error ?? o.note,
    );
  }

  /// One watch, with self-repair.
  ///
  /// A failure is retried once straight away after [_rebuild] reloads the
  /// alert's Doctolib data from scratch (the automatic equivalent of deleting
  /// the alert and creating it again). Only when that keeps failing, check
  /// after check, is the error shown: from the [WatchConfig.errorThreshold]th
  /// failure in a row, with Doctolib's own explanation attached.
  Future<CheckOutcome> _runOne({
    required DoctolibApi api,
    required WatchConfig watch,
    required AppSettings settings,
    required bool notify,
    required int requestsBefore,
    required List<Future<void>> rings,
  }) async {
    Object? failure;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        if (attempt == 1) {
          await _rebuild(api, watch);
          watch.lastRepairAt = DateTime.now();
        }
        final outcome = await _checkWatch(
          api: api,
          watch: watch,
          settings: settings,
          notify: notify,
          requestsBefore: requestsBefore,
          rings: rings,
        );
        return outcome;
      } on DoctolibException catch (e) {
        // Being rate-limited is about us, not this alert: no repair can help,
        // and trying would only make it worse.
        if (e.isBlocked) {
          return _recordFailure(watch, requestsBefore, api, e.message,
              blocked: true, surface: true);
        }
        failure = e;
      } catch (e) {
        failure = e;
      }
    }

    watch.errorStreak++;
    final cause = failure is DoctolibException
        ? failure.message
        : tr.unexpectedError('$failure');
    final surface = watch.errorStreak >= WatchConfig.errorThreshold;
    return _recordFailure(
      watch,
      requestsBefore,
      api,
      surface
          ? tr.failedStreak(watch.errorStreak, cause)
          : null,
      detail: cause,
      surface: surface,
    );
  }

  Future<CheckOutcome> _recordFailure(
    WatchConfig watch,
    int requestsBefore,
    DoctolibApi api,
    String? message, {
    String? detail,
    bool blocked = false,
    required bool surface,
  }) async {
    watch.lastCheckedAt = DateTime.now();
    watch.lastRequestCount = api.guard.requestsToday - requestsBefore;
    // Below the threshold the previous results stay on screen untouched.
    if (surface) watch.lastError = message;
    await store.upsertWatch(watch);
    return CheckOutcome(
      watchId: watch.id,
      hits: watch.lastHits,
      freshHits: const [],
      requests: watch.lastRequestCount,
      error: surface ? message : null,
      blocked: blocked,
      note: surface
          ? null
          : tr.repairing(watch.errorStreak, WatchConfig.errorThreshold, detail ?? ''),
    );
  }

  /// Reloads everything the alert caches from Doctolib, as if it had just
  /// been created: the city's search object, the practitioner's agendas and
  /// practice, and the list of practitioners already known to match. The
  /// user's own choices (filters, ignores, what was already notified) stay.
  Future<void> _rebuild(DoctolibApi api, WatchConfig watch) async {
    watch.knownDoctorKeys = const [];

    if (watch.kind == WatchKind.speciality) {
      final slug = watch.specialities.isEmpty
          ? 'medecin-generaliste'
          : watch.specialities.first.slug;
      final place = watch.place;
      if (place != null) {
        watch.place = await api.resolvePlace(place.name, specialitySlug: slug);
      }
      // The zone's towns too. One that no longer resolves is dropped rather
      // than allowed to fail the whole alert again.
      final zone = watch.zone;
      if (zone != null && zone.communes.isNotEmpty) {
        final places = <PlaceRef>[];
        for (final c in zone.communes) {
          try {
            places.add(await api.resolvePlace(c.name, specialitySlug: slug));
          } on DoctolibException catch (e) {
            if (e.isBlocked) rethrow;
          }
        }
        zone.places = places;
      }
      return;
    }

    final doctor = watch.doctor;
    if (doctor == null) return;
    final info = await api.bookingInfo(doctor.slug);
    var motives = info.motives.where((m) => watch.motiveIds.contains(m.id));
    if (motives.isEmpty && doctor.visitMotiveName.isNotEmpty) {
      // The ids moved; find the same motive again by its name.
      motives = info.motives.where((m) => m.name == doctor.visitMotiveName);
      if (motives.isNotEmpty) {
        watch.motiveIds = motives.map((m) => m.id).toList();
      }
    }
    final agendas = motives.expand((m) => m.agendaIds).toSet().toList();
    watch.doctor = DoctorRef(
      key: doctor.key,
      profileId: doctor.profileId,
      practiceId: info.practiceIds.isNotEmpty
          ? info.practiceIds.first
          : doctor.practiceId,
      displayName: doctor.displayName,
      specialityName:
          info.speciality.isEmpty ? doctor.specialityName : info.speciality,
      city: doctor.city,
      address: doctor.address,
      link: doctor.link,
      agendaIds: agendas.isEmpty ? doctor.agendaIds : agendas,
      visitMotiveId: motives.isEmpty ? doctor.visitMotiveId : motives.first.id,
      visitMotiveName:
          motives.isEmpty ? doctor.visitMotiveName : motives.first.name,
      allowNewPatients: doctor.allowNewPatients,
      telehealth: doctor.telehealth,
    );
  }

  /// Rewrites the permanent status notification from whatever is on disk.
  Future<void> refreshStatus(AppSettings settings) async {
    if (!settings.statusNotification) {
      await Notifications.instance.hideStatus();
      return;
    }
    final all = await store.loadWatches();
    final guard = await store.loadGuard();

    DateTime? latest;
    var slots = 0;
    final lines = <String>[];
    for (final w in all) {
      if (w.lastCheckedAt != null &&
          (latest == null || w.lastCheckedAt!.isAfter(latest))) {
        latest = w.lastCheckedAt;
      }
      final visible = w.visibleHits.length;
      slots += visible;
      final state = !w.enabled
          ? tr.stateDisabled
          : w.isSnoozed
              ? tr.statePaused
              : w.lastError != null
                  ? tr.stateError
                  : visible == 0
                      ? tr.stateNothing
                      : tr.slotsCount(visible);
      lines.add('${w.title} — $state');
    }

    await Notifications.instance.showStatus(
      activeWatches: all.where((w) => w.isActive).length,
      totalWatches: all.length,
      slotCount: slots,
      lastCheck: latest,
      problem: guard.isPaused ? guard.lastBlockMessage : null,
      lines: lines.take(6).toList(),
    );
  }

  Future<CheckOutcome> _checkWatch({
    required DoctolibApi api,
    required WatchConfig watch,
    required AppSettings settings,
    required bool notify,
    required int requestsBefore,
    required List<Future<void>> rings,
  }) async {
    final hits = watch.kind == WatchKind.doctor
        ? await _checkDoctor(api, watch)
        : await _checkSpeciality(api, watch, settings);

    hits.sort((a, b) => a.when.compareTo(b.when));

    // Anything the user muted never becomes news, at any of the three levels.
    final fresh = hits
        .where((h) => !watch.seen.contains(h.id) && !watch.isIgnored(h))
        .toList();

    watch.lastCheckedAt = DateTime.now();
    watch.lastError = null;
    watch.errorStreak = 0;
    watch.lastHits = hits;
    watch.lastRequestCount = api.guard.requestsToday - requestsBefore;
    watch.seen.addAll(fresh.map((h) => h.id));
    // Keep highlighting whatever is still unread, and add this round's finds.
    watch.freshIds
      ..removeWhere((id) => !hits.any((h) => h.id == id))
      ..addAll(fresh.map((h) => h.id));
    // Forget slots that have fallen out of the window, otherwise "seen" grows
    // without bound and a slot freed again months later would stay silent.
    watch.seen.removeWhere(_isPast);
    // Muted slots and days expire on their own once they are behind us; muted
    // practitioners are a deliberate choice and stay until undone.
    watch.ignoredSlots.removeWhere(_isPast);
    watch.ignoredDates.removeWhere((key) {
      final d = DateTime.tryParse(key);
      return d != null &&
          d.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    });
    watch.knownDoctorKeys = hits.map((h) => h.doctorKey).toSet().toList();

    await store.upsertWatch(watch);

    if (notify && fresh.isNotEmpty) {
      // A manual refresh can happen inside the quiet window. Finding slots is
      // still useful then, but ringing like a phone call at 3 a.m. is not, so the
      // loudest style is quietly demoted rather than honoured.
      final ringing =
          watch.alertStyle == AlertStyle.call && settings.isQuietNow;
      final call = await Notifications.instance.notifySlots(
        watch: watch,
        hits: fresh,
        grouped: settings.groupNotifications,
        styleOverride: ringing ? AlertStyle.discreet : null,
        sound: CallSound.byId(settings.callSound),
        callSeconds: settings.callSeconds,
      );
      if (call != null) {
        rings.add(
          Notifications.instance.awaitMissedCall(call, settings.callSeconds),
        );
      }
    }

    return CheckOutcome(
      watchId: watch.id,
      hits: hits,
      freshHits: fresh,
      requests: watch.lastRequestCount,
    );
  }

  // -------------------------------------------------------------------------
  // "Any doctor of these specialities, in this city"
  // -------------------------------------------------------------------------

  Future<List<SlotHit>> _checkSpeciality(
    DoctolibApi api,
    WatchConfig watch,
    AppSettings settings,
  ) async {
    final place = watch.place;
    if (place == null || watch.specialities.isEmpty) {
      throw DoctolibException(
          tr.incompleteSpeciality);
    }

    // Doctolib only searches by town. With a zone, every town the zone
    // touches is searched, so a practitioner 800 m away across the town border
    // is not missed; without one, just the chosen city, as always.
    final zone = watch.zone;
    final places = <int, PlaceRef>{place.id: place};
    for (final p in zone?.places ?? const <PlaceRef>[]) {
      places.putIfAbsent(p.id, () => p);
    }

    // Step 1 — one request per speciality and town asks Doctolib directly for
    // the practitioners who already have something before the end of the
    // window. Without this filter we would have to poll every practitioner.
    final candidates = <String, DoctorRef>{};
    for (final spec in watch.specialities) {
      for (final searchPlace in places.values) {
        var page = 0;
        while (
            candidates.length < watch.maxDoctors * places.length && page < 3) {
          final res = await api.searchDoctors(
            keyword: spec.slug,
            place: searchPlace,
            page: page,
            availableBefore: watch.windowEnd,
            // Doctolib can filter for video consultations server-side; there is
            // no inverse filter, so "au cabinet" is applied below.
            telehealth:
                watch.teleconsult == TeleconsultMode.online ? true : null,
          );
          if (res.doctors.isEmpty) break;
          for (final d in res.doctors) {
            if (watch.onlyNewPatients && !d.allowNewPatients) continue;
            if (watch.teleconsult == TeleconsultMode.inPerson && d.telehealth) {
              continue;
            }
            // An ignored practitioner is dropped here, so we never spend a
            // request on their calendar either.
            if (watch.ignoredDoctors.contains(d.key)) continue;
            if (zone != null && !_inZone(zone, d)) continue;
            candidates.putIfAbsent(d.key, () => d);
          }
          if (res.doctors.length < 20 || (page + 1) * 20 >= res.total) break;
          page++;
        }
      }
    }

    if (candidates.isEmpty) return [];

    // Step 2 — exact times. In frugal mode we only ask for practitioners that
    // were not already matching last time: the ones we already know about are
    // reported from the previous run's slots, refreshed on the next newcomer.
    final known = watch.knownDoctorKeys.toSet();
    var targets = candidates.values.toList();
    if (zone != null) {
      // When the cap bites, keep the closest practitioners.
      targets.sort((a, b) => _distance(zone, a).compareTo(_distance(zone, b)));
    }
    if (settings.frugalMode) {
      final newcomers = targets.where((d) => !known.contains(d.key)).toList();
      // Always re-check a couple of known ones so stale slots get retired.
      final stale = targets.where((d) => known.contains(d.key)).take(2);
      targets = [...newcomers, ...stale];
    }
    targets = targets.take(watch.maxDoctors).toList();

    final hits = <SlotHit>[];
    final refreshedKeys = <String>{};
    var failures = 0;
    DoctolibException? lastFailure;
    for (final d in targets) {
      if (d.visitMotiveId == null) continue;
      final AvailabilityResult avail;
      try {
        avail = await api.availabilities(
          visitMotiveIds: [d.visitMotiveId!],
          agendaIds: d.agendaIds,
          practiceIds: d.practiceId == 0 ? const [] : [d.practiceId],
          startDate: watch.windowStart,
          days: watch.daysToScan,
        );
      } on DoctolibException catch (e) {
        // A block is about us, not this practitioner: stop everything.
        if (e.isBlocked) rethrow;
        // Anything else (a practitioner who closed an agenda, a motive that
        // was withdrawn) is about this one calendar. Skip it and keep going
        // rather than failing the whole alert over one bad entry.
        failures++;
        lastFailure = e;
        continue;
      }
      refreshedKeys.add(d.key);
      for (final slot in avail.slots) {
        if (!watch.accepts(slot)) continue;
        hits.add(SlotHit(
          doctorKey: d.key,
          doctorName: d.displayName,
          city: d.city,
          address: d.address,
          motive: d.visitMotiveName,
          speciality: d.specialityName,
          telehealth: d.telehealth,
          bookingUrl: d.bookingUrl,
          when: slot,
          lat: d.lat,
          lng: d.lng,
          distanceKm: zone == null || d.lat == null || d.lng == null
              ? null
              : zone.distanceKm(d.lat!, d.lng!),
        ));
      }
    }
    // Only an alert where *every* calendar failed is reported as broken.
    if (failures > 0 && refreshedKeys.isEmpty && lastFailure != null) {
      throw lastFailure;
    }

    // Carry forward slots of known practitioners we deliberately did not
    // re-query, as long as they are still inside the window.
    if (settings.frugalMode) {
      for (final old in watch.lastHits) {
        if (refreshedKeys.contains(old.doctorKey)) continue;
        if (!candidates.containsKey(old.doctorKey)) continue;
        if (!watch.accepts(old.when)) continue;
        hits.add(old);
      }
    }

    return hits;
  }

  // -------------------------------------------------------------------------
  // "This practitioner in particular"
  // -------------------------------------------------------------------------

  Future<List<SlotHit>> _checkDoctor(DoctolibApi api, WatchConfig watch) async {
    final doctor = watch.doctor;
    if (doctor == null) {
      throw DoctolibException(tr.incompleteDoctor);
    }

    var motiveIds = watch.motiveIds;
    var agendaIds = doctor.agendaIds;
    var practiceIds = doctor.practiceId == 0 ? <int>[] : [doctor.practiceId];
    var motiveName = doctor.visitMotiveName;
    var isVideo = doctor.telehealth;

    if (motiveIds.isEmpty) {
      // No motive chosen: fall back to whatever the search result matched.
      if (doctor.visitMotiveId == null) {
        throw DoctolibException(tr.noMotiveSelected);
      }
      motiveIds = [doctor.visitMotiveId!];
    } else {
      // Re-read the funnel so agendas stay correct if the practice changed.
      final info = await api.bookingInfo(doctor.slug);
      var selected =
          info.motives.where((m) => motiveIds.contains(m.id)).toList();
      selected = switch (watch.teleconsult) {
        TeleconsultMode.online => selected.where((m) => m.telehealth).toList(),
        TeleconsultMode.inPerson =>
          selected.where((m) => !m.telehealth).toList(),
        TeleconsultMode.any => selected,
      };
      if (selected.isEmpty) {
        throw DoctolibException(tr.motivesGone);
      }
      agendaIds = selected.expand((m) => m.agendaIds).toSet().toList();
      practiceIds = selected.expand((m) => m.practiceIds).toSet().toList();
      motiveName = selected.length == 1
          ? selected.first.name
          : selected.map((m) => m.name).join(' / ');
      isVideo = selected.every((m) => m.telehealth);
    }

    final avail = await api.availabilities(
      visitMotiveIds: motiveIds,
      agendaIds: agendaIds,
      practiceIds: practiceIds,
      startDate: watch.windowStart,
      days: watch.daysToScan,
    );

    return [
      for (final slot in avail.slots)
        if (watch.accepts(slot))
          SlotHit(
            doctorKey: doctor.key,
            doctorName: doctor.displayName,
            city: doctor.city,
            address: doctor.address,
            motive: motiveName,
            speciality: doctor.specialityName,
            telehealth: isVideo,
            bookingUrl: doctor.bookingUrl,
            when: slot,
          )
    ];
  }

  /// Whether a practitioner falls inside the zone.
  ///
  /// A video consultation has no journey, so distance does not apply to it.
  /// A practice with no coordinates cannot be placed, so it is left out
  /// rather than let through by default.
  static bool _inZone(Zone zone, DoctorRef d) {
    if (d.telehealth) return true;
    if (d.lat == null || d.lng == null) return false;
    return zone.contains(d.lat!, d.lng!);
  }

  static double _distance(Zone zone, DoctorRef d) =>
      d.lat == null || d.lng == null
          ? double.infinity
          : zone.distanceKm(d.lat!, d.lng!);

  /// True for a `doctorKey|isoDate` identity whose moment has passed.
  static bool _isPast(String id) {
    final dt = DateTime.tryParse(id.split('|').last);
    return dt != null && dt.isBefore(DateTime.now());
  }

  /// Rough estimate of the requests one full pass costs, used by the UI to
  /// tell the user what an interval means in practice.
  static int estimateRequestsPerRun(List<WatchConfig> watches, AppSettings s) {
    var total = 0;
    for (final w in watches.where((w) => w.enabled)) {
      if (w.kind == WatchKind.doctor) {
        total += w.motiveIds.isEmpty ? 1 : 2;
      } else {
        // The filtered search calls: one per speciality and searched town.
        final towns = 1 + (w.zone?.places.length ?? 0);
        total += w.specialities.length * towns;
        total += s.frugalMode ? 2 : min(w.maxDoctors, 20);
      }
    }
    return total;
  }
}
