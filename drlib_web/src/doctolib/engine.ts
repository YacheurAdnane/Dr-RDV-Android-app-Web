/**
 * Port of lib/src/engine.dart.
 *
 * Runs one alert and decides what deserves a notification. The structure of
 * the original survives intact — filtered search first, exact times second,
 * frugal mode, self-repair on failure — because that structure is what keeps
 * the request count low, and the request count is the whole ball game now that
 * every user's traffic leaves from one address.
 *
 * The one deliberate departure: this module never touches the database. It
 * takes a mutable AlertState, changes it, and hands it back. The scheduler
 * decides what to persist and what to notify, which makes the interesting part
 * testable without a D1 binding.
 */

import { BudgetExhausted, DoctolibApi, DoctolibError } from './api';
import {
  accepts,
  bookingUrl,
  daysToScan,
  DoctorRef,
  doctorDistance,
  inZone,
  isIgnored,
  lastPathSegment,
  PlaceRef,
  SlotHit,
  slotId,
  VisitMotive,
  WatchConfig,
  windowEnd,
  windowStart,
} from './models';
import { jitterMs, sleep } from './rate-guard';
import { zoneDistanceKm } from './zone';

/** Failures before the error is surfaced to the user. */
export const ERROR_THRESHOLD = 3;

/** Everything about an alert that changes as it runs. */
export interface AlertState {
  id: string;
  userId: string;
  title: string;
  config: WatchConfig;
  lastHits: SlotHit[];
  /** Slots already announced, so they are not announced twice. */
  seen: string[];
  /**
   * Practitioners already known to have something inside the window. In frugal
   * mode only the newcomers cost an extra request.
   */
  knownDoctorKeys: string[];
  errorStreak: number;
  lastError: string | null;
  lastCheckedAt: string | null;
  lastRequestCount: number;
}

export interface CheckOutcome {
  alertId: string;
  /** Every slot currently matching the alert. */
  hits: SlotHit[];
  /** The subset that had never been announced before. */
  freshHits: SlotHit[];
  requests: number;
  error?: string;
  /** Doctolib rate-limited us; the whole run stops. */
  blocked: boolean;
  /**
   * A failure the automatic repair is still working on, not yet worth
   * presenting as an error.
   */
  note?: string;
  /** The tick ran out of subrequests. The alert stays due for the next one. */
  deferred: boolean;
}

/**
 * One alert, with self-repair.
 *
 * A failure is retried once straight away after `rebuild` reloads the alert's
 * Doctolib data from scratch (the automatic equivalent of deleting the alert
 * and creating it again). Only when that keeps failing, check after check, is
 * the error shown: from the ERROR_THRESHOLD-th failure in a row, with
 * Doctolib's own explanation attached.
 */
export async function runAlert(
  api: DoctolibApi,
  state: AlertState,
  now = new Date(),
): Promise<CheckOutcome> {
  const requestsBefore = api.guard.requestsToday;
  let failure: unknown = null;

  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      if (attempt === 1) await rebuild(api, state);
      return await checkOne(api, state, requestsBefore, now);
    } catch (e) {
      // Running out of tick budget is not a failure of this alert. Leave
      // everything untouched so the next tick picks it up unchanged.
      if (e instanceof BudgetExhausted) {
        return {
          alertId: state.id,
          hits: state.lastHits,
          freshHits: [],
          requests: api.guard.requestsToday - requestsBefore,
          blocked: false,
          deferred: true,
        };
      }
      // Being rate-limited is about us, not this alert: no repair can help,
      // and trying would only make it worse.
      if (e instanceof DoctolibError && e.isBlocked) {
        return recordFailure(state, api, requestsBefore, e.message, {
          blocked: true,
          surface: true,
          now,
        });
      }
      failure = e;
    }
  }

  state.errorStreak++;
  const cause = failure instanceof Error ? failure.message : `Erreur inattendue : ${failure}`;
  const surface = state.errorStreak >= ERROR_THRESHOLD;
  return recordFailure(
    state,
    api,
    requestsBefore,
    surface ? `Echec ${state.errorStreak} fois de suite — ${cause}` : null,
    { surface, detail: cause, now },
  );
}

function recordFailure(
  state: AlertState,
  api: DoctolibApi,
  requestsBefore: number,
  message: string | null,
  opts: { surface: boolean; blocked?: boolean; detail?: string; now: Date },
): CheckOutcome {
  state.lastCheckedAt = opts.now.toISOString();
  state.lastRequestCount = api.guard.requestsToday - requestsBefore;
  // Below the threshold the previous results stay on screen untouched.
  if (opts.surface) state.lastError = message;
  return {
    alertId: state.id,
    hits: state.lastHits,
    freshHits: [],
    requests: state.lastRequestCount,
    error: opts.surface ? message ?? undefined : undefined,
    blocked: opts.blocked ?? false,
    deferred: false,
    note: opts.surface
      ? undefined
      : `Reparation automatique (${state.errorStreak}/${ERROR_THRESHOLD}) — ${opts.detail ?? ''}`,
  };
}

/**
 * Reloads everything the alert caches from Doctolib, as if it had just been
 * created: the city's search object, the practitioner's agendas and practice,
 * and the list of practitioners already known to match. The user's own choices
 * (filters, ignores, what was already notified) stay.
 */
async function rebuild(api: DoctolibApi, state: AlertState): Promise<void> {
  const w = state.config;
  state.knownDoctorKeys = [];

  if (w.kind === 'speciality') {
    const slug = w.specialities.length === 0 ? 'medecin-generaliste' : w.specialities[0].slug;
    if (w.place) w.place = await api.resolvePlace(w.place.name, slug);
    // The zone's towns too. One that no longer resolves is dropped rather than
    // allowed to fail the whole alert again.
    if (w.zone && w.zone.communes.length > 0) {
      const places: PlaceRef[] = [];
      for (const c of w.zone.communes) {
        try {
          places.push(await api.resolvePlace(c.name, slug));
        } catch (e) {
          if (e instanceof BudgetExhausted) throw e;
          if (e instanceof DoctolibError && e.isBlocked) throw e;
        }
      }
      w.zone.places = places;
    }
    return;
  }

  const doctor = w.doctor;
  if (!doctor) return;
  const info = await api.bookingInfo(lastPathSegment(doctor.link));
  let motives = info.motives.filter((m) => w.motiveIds.includes(m.id));
  if (motives.length === 0 && doctor.visitMotiveName) {
    // The ids moved; find the same motive again by its name.
    motives = info.motives.filter((m) => m.name === doctor.visitMotiveName);
    if (motives.length > 0) w.motiveIds = motives.map((m) => m.id);
  }
  const agendas = [...new Set(motives.flatMap((m) => m.agendaIds))];
  w.doctor = {
    ...doctor,
    practiceId: info.practiceIds.length > 0 ? info.practiceIds[0] : doctor.practiceId,
    specialityName: info.speciality || doctor.specialityName,
    agendaIds: agendas.length > 0 ? agendas : doctor.agendaIds,
    visitMotiveId: motives.length === 0 ? doctor.visitMotiveId : motives[0].id,
    visitMotiveName: motives.length === 0 ? doctor.visitMotiveName : motives[0].name,
  };
}

async function checkOne(
  api: DoctolibApi,
  state: AlertState,
  requestsBefore: number,
  now: Date,
): Promise<CheckOutcome> {
  const w = state.config;
  const hits = w.kind === 'doctor'
    ? await checkDoctor(api, state, now)
    : await checkSpeciality(api, state, now);

  hits.sort((a, b) => a.when.localeCompare(b.when));

  // Anything the user muted never becomes news, at any of the three levels.
  const seen = new Set(state.seen);
  const fresh = hits.filter((h) => !seen.has(slotId(h)) && !isIgnored(w, h));

  state.lastCheckedAt = now.toISOString();
  state.lastError = null;
  state.errorStreak = 0;
  state.lastHits = hits;
  state.lastRequestCount = api.guard.requestsToday - requestsBefore;

  for (const h of fresh) seen.add(slotId(h));
  // Forget slots that have fallen out of the window, otherwise "seen" grows
  // without bound and a slot freed again months later would stay silent.
  state.seen = [...seen].filter((id) => !isPast(id, now)).slice(-600);

  // Muted slots and days expire on their own once they are behind us; muted
  // practitioners are a deliberate choice and stay until undone.
  w.ignoredSlots = w.ignoredSlots.filter((id) => !isPast(id, now));
  const yesterday = new Date(now.getTime() - 86_400_000);
  w.ignoredDates = w.ignoredDates.filter((key) => {
    const d = new Date(key);
    return Number.isNaN(d.getTime()) || d >= yesterday;
  });

  state.knownDoctorKeys = [...new Set(hits.map((h) => h.doctorKey))];

  return {
    alertId: state.id,
    hits,
    freshHits: fresh,
    requests: state.lastRequestCount,
    blocked: false,
    deferred: false,
  };
}

// ---------------------------------------------------------------------------
// "Any doctor of these specialities, in this city"
// ---------------------------------------------------------------------------

async function checkSpeciality(
  api: DoctolibApi,
  state: AlertState,
  now: Date,
): Promise<SlotHit[]> {
  const w = state.config;
  const place = w.place;
  if (!place || w.specialities.length === 0) {
    throw new DoctolibError('Alerte incomplete : il manque une specialite ou une ville.');
  }

  // Doctolib only searches by town. With a zone, every town the zone touches
  // is searched, so a practitioner 800 m away across the town border is not
  // missed; without one, just the chosen city, as always.
  const zone = w.zone;
  const places = new Map<number, PlaceRef>([[place.id, place]]);
  for (const p of zone?.places ?? []) {
    if (!places.has(p.id)) places.set(p.id, p);
  }

  // Step 1 — one request per speciality and town asks Doctolib directly for
  // the practitioners who already have something before the end of the window.
  // Without this filter we would have to poll every practitioner in town.
  const candidates = new Map<string, DoctorRef>();
  const ignoredDoctors = new Set(w.ignoredDoctors);
  for (const spec of w.specialities) {
    for (const searchPlace of places.values()) {
      let page = 0;
      while (candidates.size < w.maxDoctors * places.size && page < 3) {
        const res = await api.searchDoctors({
          keyword: spec.slug,
          place: searchPlace,
          page,
          availableBefore: windowEnd(w, now),
          // Doctolib can filter for video consultations server-side; there is
          // no inverse filter, so "au cabinet" is applied below.
          telehealth: w.teleconsult === 'online' ? true : null,
        });
        if (res.doctors.length === 0) break;
        for (const d of res.doctors) {
          if (w.onlyNewPatients && !d.allowNewPatients) continue;
          if (w.teleconsult === 'inPerson' && d.telehealth) continue;
          // An ignored practitioner is dropped here, so we never spend a
          // request on their calendar either.
          if (ignoredDoctors.has(d.key)) continue;
          if (zone && !inZone(zone, d)) continue;
          if (!candidates.has(d.key)) candidates.set(d.key, d);
        }
        if (res.doctors.length < 20 || (page + 1) * 20 >= res.total) break;
        page++;
      }
    }
  }

  if (candidates.size === 0) return [];

  // Step 2 — exact times. In frugal mode we only ask for practitioners that
  // were not already matching last time: the ones we already know about are
  // reported from the previous run's slots, refreshed on the next newcomer.
  const known = new Set(state.knownDoctorKeys);
  let targets = [...candidates.values()];
  if (zone) {
    // When the cap bites, keep the closest practitioners.
    targets.sort((a, b) => doctorDistance(zone, a) - doctorDistance(zone, b));
  }
  if (w.frugalMode) {
    const newcomers = targets.filter((d) => !known.has(d.key));
    // Always re-check a couple of known ones so stale slots get retired.
    const stale = targets.filter((d) => known.has(d.key)).slice(0, 2);
    targets = [...newcomers, ...stale];
  }
  targets = targets.slice(0, w.maxDoctors);

  const hits: SlotHit[] = [];
  const refreshedKeys = new Set<string>();
  let failures = 0;
  let lastFailure: DoctolibError | null = null;

  for (const d of targets) {
    if (d.visitMotiveId == null) continue;
    let avail;
    try {
      avail = await api.availabilities({
        visitMotiveIds: [d.visitMotiveId],
        agendaIds: d.agendaIds,
        practiceIds: d.practiceId === 0 ? [] : [d.practiceId],
        startDate: windowStart(w, now),
        days: daysToScan(w, now),
      });
    } catch (e) {
      // Out of tick budget: keep what we have rather than losing the pass.
      if (e instanceof BudgetExhausted) break;
      // A block is about us, not this practitioner: stop everything.
      if (e instanceof DoctolibError && e.isBlocked) throw e;
      // Anything else (a practitioner who closed an agenda, a motive that was
      // withdrawn) is about this one calendar. Skip it and keep going rather
      // than failing the whole alert over one bad entry.
      failures++;
      lastFailure = e instanceof DoctolibError ? e : new DoctolibError(String(e));
      continue;
    }
    refreshedKeys.add(d.key);
    for (const slot of avail.slots) {
      if (!accepts(w, slot, now)) continue;
      hits.push({
        doctorKey: d.key,
        doctorName: d.displayName,
        city: d.city,
        address: d.address,
        motive: d.visitMotiveName,
        speciality: d.specialityName,
        telehealth: d.telehealth,
        bookingUrl: bookingUrl(d),
        when: slot.toISOString(),
        lat: d.lat ?? null,
        lng: d.lng ?? null,
        distanceKm:
          zone && d.lat != null && d.lng != null ? zoneDistanceKm(zone, d.lat, d.lng) : null,
      });
    }
  }

  // Only an alert where *every* calendar failed is reported as broken.
  if (failures > 0 && refreshedKeys.size === 0 && lastFailure) throw lastFailure;

  // Carry forward slots of known practitioners we deliberately did not
  // re-query, as long as they are still inside the window.
  if (w.frugalMode) {
    for (const old of state.lastHits) {
      if (refreshedKeys.has(old.doctorKey)) continue;
      if (!candidates.has(old.doctorKey)) continue;
      if (!accepts(w, new Date(old.when), now)) continue;
      hits.push(old);
    }
  }

  return hits;
}

// ---------------------------------------------------------------------------
// "This practitioner in particular"
// ---------------------------------------------------------------------------

async function checkDoctor(api: DoctolibApi, state: AlertState, now: Date): Promise<SlotHit[]> {
  const w = state.config;
  const doctor = w.doctor;
  if (!doctor) throw new DoctolibError('Alerte incomplete : aucun praticien choisi.');

  let motiveIds = w.motiveIds;
  let agendaIds = doctor.agendaIds;
  let practiceIds = doctor.practiceId === 0 ? [] : [doctor.practiceId];
  let motiveName = doctor.visitMotiveName;
  let isVideo = doctor.telehealth;

  if (motiveIds.length === 0) {
    // No motive chosen: fall back to whatever the search result matched.
    if (doctor.visitMotiveId == null) {
      throw new DoctolibError('Aucun motif de consultation selectionne.');
    }
    motiveIds = [doctor.visitMotiveId];
  } else {
    // Re-read the funnel so agendas stay correct if the practice changed.
    const info = await api.bookingInfo(lastPathSegment(doctor.link));
    let selected: VisitMotive[] = info.motives.filter((m) => motiveIds.includes(m.id));
    if (w.teleconsult === 'online') selected = selected.filter((m) => m.telehealth);
    if (w.teleconsult === 'inPerson') selected = selected.filter((m) => !m.telehealth);
    if (selected.length === 0) {
      throw new DoctolibError("Les motifs suivis n'existent plus chez ce praticien.");
    }
    agendaIds = [...new Set(selected.flatMap((m) => m.agendaIds))];
    practiceIds = [...new Set(selected.flatMap((m) => m.practiceIds))];
    motiveName =
      selected.length === 1 ? selected[0].name : selected.map((m) => m.name).join(' / ');
    isVideo = selected.every((m) => m.telehealth);
  }

  const avail = await api.availabilities({
    visitMotiveIds: motiveIds,
    agendaIds,
    practiceIds,
    startDate: windowStart(w, now),
    days: daysToScan(w, now),
  });

  return avail.slots
    .filter((slot) => accepts(w, slot, now))
    .map((slot) => ({
      doctorKey: doctor.key,
      doctorName: doctor.displayName,
      city: doctor.city,
      address: doctor.address,
      motive: motiveName,
      speciality: doctor.specialityName,
      telehealth: isVideo,
      bookingUrl: bookingUrl(doctor),
      when: slot.toISOString(),
      lat: doctor.lat ?? null,
      lng: doctor.lng ?? null,
      distanceKm: null,
    }));
}

/** True for a `doctorKey|isoDate` identity whose moment has passed. */
function isPast(id: string, now: Date): boolean {
  const parts = id.split('|');
  const dt = new Date(parts[parts.length - 1]);
  return !Number.isNaN(dt.getTime()) && dt < now;
}

/**
 * Rough estimate of the requests one pass of this alert costs.
 *
 * The scheduler uses it to decide whether an alert still fits in the tick's
 * remaining budget, so that an alert is either run properly or left for the
 * next tick rather than cut off half way through.
 */
export function estimateRequests(w: WatchConfig): number {
  if (w.kind === 'doctor') return w.motiveIds.length === 0 ? 1 : 2;
  const towns = 1 + (w.zone?.places.length ?? 0);
  const search = Math.max(1, w.specialities.length) * towns;
  return search + (w.frugalMode ? 3 : Math.min(w.maxDoctors, 20));
}

/** Breathing room between two alerts, so a tick is not one tight burst. */
export async function breathe(): Promise<void> {
  await sleep(1500 + jitterMs(1500));
}
