/**
 * Port of lib/src/models.dart.
 *
 * Kept as plain interfaces plus free functions rather than classes: these
 * objects live in a D1 TEXT column as JSON, and a shape that survives
 * `JSON.parse` without a revive step is one less thing to get wrong.
 *
 * The field names match the Dart `toJson()` output exactly, so an alert
 * exported from the phone app can be pasted straight in.
 */

import * as tz from '../lib/tz';
import { haversineKm, Zone, zoneContains, zoneDistanceKm } from './zone';

// ---------------------------------------------------------------------------
// Doctolib reference objects
// ---------------------------------------------------------------------------

export interface PlaceRef {
  id: number;
  name: string;
  slug: string;
  country: string;
  type: string;
  lat: number;
  lng: number;
  neLat: number;
  neLng: number;
  swLat: number;
  swLng: number;
}

/** The `location.place` payload of POST /patient-health-search/api/v1/hcp/search. */
export function placeSearchPayload(p: PlaceRef): unknown {
  return {
    id: p.id,
    name: p.name,
    slug: p.slug,
    country: p.country,
    type: p.type,
    gpsPoint: { lat: p.lat, lng: p.lng },
    viewport: {
      northeast: { lat: p.neLat, lng: p.neLng },
      southwest: { lat: p.swLat, lng: p.swLng },
    },
  };
}

/** Parses the `window.place = {...}` blob embedded in a Doctolib search page. */
export function placeFromWindowPlace(j: any): PlaceRef | null {
  const gps = j?.gpsPoint;
  const vp = j?.viewport;
  if (!gps || !vp) return null;
  const ne = vp.northeast;
  const sw = vp.southwest;
  if (!ne || !sw) return null;
  return {
    id: Number(j.id),
    name: String(j.name ?? ''),
    slug: String(j.slug ?? ''),
    country: String(j.country ?? 'fr'),
    type: String(j.type ?? 'locality'),
    lat: Number(gps.lat),
    lng: Number(gps.lng),
    neLat: Number(ne.lat),
    neLng: Number(ne.lng),
    swLat: Number(sw.lat),
    swLng: Number(sw.lng),
  };
}

export interface PlaceSuggestion {
  label: string;
  city: string;
  country: string;
  isLocality: boolean;
}

export interface SpecialityRef {
  id: string;
  slug: string;
  name: string;
}

export interface ProfileSuggestion {
  profileId: string;
  displayName: string;
  speciality: string;
  city: string;
  link: string;
  isOrganization: boolean;
}

export interface DoctorRef {
  key: string;
  profileId: number;
  practiceId: number;
  displayName: string;
  specialityName: string;
  city: string;
  address: string;
  link: string;
  agendaIds: number[];
  visitMotiveId: number | null;
  visitMotiveName: string;
  allowNewPatients: boolean;
  telehealth: boolean;
  lat?: number | null;
  lng?: number | null;
}

export function bookingUrl(d: { link: string }): string {
  return d.link.startsWith('http') ? d.link : `https://www.doctolib.fr${d.link}`;
}

/** `/pediatre/lyon/zoe-germont` becomes `zoe-germont`. */
export function lastPathSegment(link: string): string {
  const clean = link.split('?')[0];
  const partsList = clean.split('/').filter((p) => p !== '');
  return partsList.length === 0 ? '' : partsList[partsList.length - 1];
}

export interface VisitMotive {
  id: number;
  name: string;
  categoryName: string;
  agendaIds: number[];
  practiceIds: number[];
  telehealth: boolean;
}

export interface SlotHit {
  doctorKey: string;
  doctorName: string;
  city: string;
  address: string;
  motive: string;
  bookingUrl: string;
  /** ISO 8601 with offset. Stored as a string so the row round-trips as JSON. */
  when: string;
  speciality: string;
  telehealth: boolean;
  lat?: number | null;
  lng?: number | null;
  distanceKm?: number | null;
}

/** Stable identity, used to remember which slots were already announced. */
export function slotId(h: SlotHit): string {
  return `${h.doctorKey}|${h.when}`;
}

// ---------------------------------------------------------------------------
// The user's watches
// ---------------------------------------------------------------------------

export type WatchKind = 'speciality' | 'doctor';
export type AlertStyle = 'discreet' | 'normal' | 'call';
export type TeleconsultMode = 'any' | 'inPerson' | 'online';
export type WindowMode = 'nextDays' | 'dateRange';

export interface WatchConfig {
  id: string;
  title: string;
  kind: WatchKind;
  specialities: SpecialityRef[];
  place: PlaceRef | null;
  zone: Zone | null;
  doctor: DoctorRef | null;
  motiveIds: number[];
  mode: WindowMode;
  horizonDays: number;
  /** ISO date strings, or null in `nextDays` mode. */
  from: string | null;
  to: string | null;
  alertStyle: AlertStyle;
  /**
   * Where this alert's news is delivered. Both off means the alert is not
   * worth checking at all, and the API disables it: an alert nobody will hear
   * about still costs Doctolib requests every quarter of an hour.
   */
  notifyPush: boolean;
  notifyEmail: boolean;
  onlyNewPatients: boolean;
  teleconsult: TeleconsultMode;
  hourFrom: number;
  hourTo: number;
  /** 1 = Monday .. 7 = Sunday. */
  weekdays: number[];
  maxDoctors: number;
  /** Minutes between checks for this alert. Never below 5. */
  intervalMinutes: number;
  /** Per-alert silent hours; a slot found then is recorded but not pushed. */
  quietEnabled: boolean;
  quietFromHour: number;
  quietToHour: number;
  frugalMode: boolean;
  snoozedUntil: string | null;
  ignoredSlots: string[];
  ignoredDates: string[];
  ignoredDoctors: string[];
}

export function defaultWatch(id: string, title: string): WatchConfig {
  return {
    id,
    title,
    kind: 'speciality',
    specialities: [],
    place: null,
    zone: null,
    doctor: null,
    motiveIds: [],
    mode: 'nextDays',
    horizonDays: 3,
    from: null,
    to: null,
    alertStyle: 'normal',
    notifyPush: true,
    notifyEmail: false,
    onlyNewPatients: false,
    teleconsult: 'any',
    hourFrom: 0,
    hourTo: 24,
    weekdays: [1, 2, 3, 4, 5, 6, 7],
    maxDoctors: 40,
    intervalMinutes: 15,
    quietEnabled: true,
    quietFromHour: 22,
    quietToHour: 7,
    frugalMode: true,
    snoozedUntil: null,
    ignoredSlots: [],
    ignoredDates: [],
    ignoredDoctors: [],
  };
}

/** Fills in anything a stored row is missing, so old rows keep loading. */
export function normaliseWatch(raw: any, id: string, title: string): WatchConfig {
  const d = defaultWatch(id, title);
  const w: WatchConfig = { ...d, ...(raw ?? {}), id, title };
  w.kind = w.kind === 'doctor' ? 'doctor' : 'speciality';
  w.mode = w.mode === 'dateRange' ? 'dateRange' : 'nextDays';
  w.alertStyle = ['discreet', 'normal', 'call'].includes(w.alertStyle) ? w.alertStyle : 'normal';
  w.teleconsult = ['any', 'inPerson', 'online'].includes(w.teleconsult) ? w.teleconsult : 'any';
  w.specialities = Array.isArray(w.specialities) ? w.specialities : [];
  // Rows written before these fields existed default to push-only, which is
  // what they were doing.
  w.notifyPush = w.notifyPush !== false;
  w.notifyEmail = w.notifyEmail === true;
  w.motiveIds = Array.isArray(w.motiveIds) ? w.motiveIds.map(Number) : [];
  w.weekdays = Array.isArray(w.weekdays) && w.weekdays.length ? w.weekdays.map(Number) : d.weekdays;
  w.ignoredSlots = Array.isArray(w.ignoredSlots) ? w.ignoredSlots : [];
  w.ignoredDates = Array.isArray(w.ignoredDates) ? w.ignoredDates : [];
  w.ignoredDoctors = Array.isArray(w.ignoredDoctors) ? w.ignoredDoctors : [];
  w.horizonDays = clamp(w.horizonDays, 1, 60);
  w.hourFrom = clamp(w.hourFrom, 0, 23);
  w.hourTo = clamp(w.hourTo, 1, 24);
  if (w.hourTo <= w.hourFrom) w.hourTo = 24;
  w.maxDoctors = clamp(w.maxDoctors, 1, 60);
  // 5 minutes is the cron granularity; anything finer would silently round up.
  w.intervalMinutes = clamp(w.intervalMinutes, 5, 720);
  return w;
}

function clamp(v: any, lo: number, hi: number): number {
  const n = Number(v);
  if (!Number.isFinite(n)) return lo;
  return Math.min(hi, Math.max(lo, Math.round(n)));
}

/** Start of the window the user cares about; never in the past. */
export function windowStart(w: WatchConfig, now = new Date()): Date {
  if (w.mode === 'dateRange' && w.from) {
    const f = new Date(w.from);
    if (!Number.isNaN(f.getTime()) && f > now) return f;
  }
  return now;
}

/** End of the window the user cares about. */
export function windowEnd(w: WatchConfig, now = new Date()): Date {
  if (w.mode === 'dateRange' && w.to) {
    const t = new Date(w.to);
    if (!Number.isNaN(t.getTime())) return tz.endOfDay(t);
  }
  return tz.endOfDay(tz.addDays(now, w.horizonDays));
}

/**
 * Calendar days from windowStart to windowEnd, inclusive.
 *
 * Measured from the start of the window, not from today, so a date range three
 * weeks out scans those days only instead of everything in between.
 */
export function daysToScan(w: WatchConfig, now = new Date()): number {
  const span = tz.daysBetween(windowStart(w, now), windowEnd(w, now)) + 1;
  return Math.min(60, Math.max(1, span));
}

/** True when the slot passes every client-side filter of this watch. */
export function accepts(w: WatchConfig, slot: Date, now = new Date()): boolean {
  if (slot < windowStart(w, now) || slot > windowEnd(w, now)) return false;
  const p = tz.parts(slot);
  if (!w.weekdays.includes(p.weekday)) return false;
  if (p.hour < w.hourFrom || p.hour >= w.hourTo) return false;
  return true;
}

/** True when the user has explicitly told us not to hear about this one. */
export function isIgnored(w: WatchConfig, h: SlotHit): boolean {
  return (
    w.ignoredSlots.includes(slotId(h)) ||
    w.ignoredDates.includes(tz.dateKey(new Date(h.when))) ||
    w.ignoredDoctors.includes(h.doctorKey)
  );
}

/** Nothing to deliver, so nothing to check. */
export function isSilent(w: WatchConfig): boolean {
  return !w.notifyPush && !w.notifyEmail;
}

export function isSnoozed(w: WatchConfig, now = new Date()): boolean {
  return w.snoozedUntil != null && now < new Date(w.snoozedUntil);
}

/**
 * Per-alert silent hours.
 *
 * Unlike the phone app this does not skip the check — the check is cheap to us
 * and expensive to skip, since a slot found at 3 a.m. should still be sitting
 * in the list at 7. It only suppresses the push.
 */
export function isQuietNow(w: WatchConfig, now = new Date()): boolean {
  if (!w.quietEnabled) return false;
  if (w.quietFromHour === w.quietToHour) return false;
  const h = tz.parts(now).hour;
  if (w.quietFromHour < w.quietToHour) return h >= w.quietFromHour && h < w.quietToHour;
  return h >= w.quietFromHour || h < w.quietToHour;
}

export function watchSubtitle(w: WatchConfig): string {
  if (w.kind === 'doctor') {
    const d = w.doctor;
    if (!d) return 'Praticien';
    return d.city ? `${d.displayName} — ${d.city}` : d.displayName;
  }
  const specs = w.specialities.map((s) => s.name).join(' · ');
  const city = w.place?.name ?? '';
  return specs ? `${specs} — ${city}` : city;
}

/**
 * Whether a practitioner falls inside the zone.
 *
 * A video consultation has no journey, so distance does not apply to it. A
 * practice with no coordinates cannot be placed, so it is left out rather than
 * let through by default.
 */
export function inZone(zone: Zone, d: DoctorRef): boolean {
  if (d.telehealth) return true;
  if (d.lat == null || d.lng == null) return false;
  return zoneContains(zone, d.lat, d.lng);
}

export function doctorDistance(zone: Zone, d: DoctorRef): number {
  if (d.lat == null || d.lng == null) return Number.POSITIVE_INFINITY;
  return zoneDistanceKm(zone, d.lat, d.lng);
}

export { haversineKm };
