/** Port of lib/src/zone.dart — the geometry half, without the UI labels. */

import type { PlaceRef } from './models';

export type RangeMode = 'radius' | 'travel';
export type TravelMode = 'walk' | 'bike' | 'transit' | 'car';

/**
 * Average door-to-door speed in km/h along the actual route, in a French city.
 * Deliberately conservative: better to include a practitioner who turns out
 * five minutes further than to miss one.
 */
const SPEED_KMH: Record<TravelMode, number> = {
  walk: 4.5,
  bike: 14,
  transit: 15,
  car: 28,
};

/**
 * Fixed minutes lost regardless of distance: walking to the stop and waiting
 * for the bus, parking the car, locking the bike.
 */
const OVERHEAD_MIN: Record<TravelMode, number> = {
  walk: 0,
  bike: 2,
  transit: 10,
  car: 5,
};

/**
 * Streets are not straight lines. Road distance is typically 1.2-1.4 times the
 * straight-line distance in a French city.
 */
export const DETOUR_FACTOR = 1.3;

/** Estimated minutes to cover a straight-line distance. */
export function estimateMinutes(straightKm: number, mode: TravelMode): number {
  return OVERHEAD_MIN[mode] + (straightKm * DETOUR_FACTOR) / SPEED_KMH[mode] * 60;
}

/**
 * Straight-line radius reachable within `minutes`, the inverse of
 * [estimateMinutes]. Never below 300 m, so a very short budget still means
 * "around here" rather than "nowhere".
 */
export function radiusForMinutes(minutes: number, mode: TravelMode): number {
  const usable = minutes - OVERHEAD_MIN[mode];
  const km = (usable * SPEED_KMH[mode]) / 60 / DETOUR_FACTOR;
  return Math.max(0.3, km);
}

/** Great-circle distance in kilometres. */
export function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371.0;
  const rad = (d: number) => (d * Math.PI) / 180;
  const dLat = rad(lat2 - lat1);
  const dLng = rad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

/** The point `km` away from (lat, lng) in the direction `bearingDeg`. */
export function offsetPoint(
  lat: number,
  lng: number,
  km: number,
  bearingDeg: number,
): { lat: number; lng: number } {
  const R = 6371.0;
  const d = km / R;
  const b = (bearingDeg * Math.PI) / 180;
  const p1 = (lat * Math.PI) / 180;
  const l1 = (lng * Math.PI) / 180;
  const p2 = Math.asin(Math.sin(p1) * Math.cos(d) + Math.cos(p1) * Math.sin(d) * Math.cos(b));
  const l2 =
    l1 +
    Math.atan2(
      Math.sin(b) * Math.sin(d) * Math.cos(p1),
      Math.cos(d) - Math.sin(p1) * Math.sin(p2),
    );
  return { lat: (p2 * 180) / Math.PI, lng: (l2 * 180) / Math.PI };
}

/** A town searched on behalf of the zone, before it is resolved to a place. */
export interface Commune {
  name: string;
  code: string;
  lat: number;
  lng: number;
  population: number;
}

/**
 * An optional area around the user. Without one, an alert covers the whole city
 * it was created for; with one, it covers exactly the practitioners inside the
 * area, even across town borders.
 */
export interface Zone {
  lat: number;
  lng: number;
  label: string;
  mode: RangeMode;
  radiusKm: number;
  minutes: number;
  travel: TravelMode;
  /** Doctolib places searched for this zone, one per town it touches. */
  places: PlaceRef[];
  /** The towns themselves, kept for display. */
  communes: Commune[];
}

/** The straight-line radius actually enforced. */
export function effectiveRadiusKm(z: Zone): number {
  return z.mode === 'radius' ? z.radiusKm : radiusForMinutes(z.minutes, z.travel);
}

export function zoneContains(z: Zone, lat: number, lng: number): boolean {
  return haversineKm(z.lat, z.lng, lat, lng) <= effectiveRadiusKm(z);
}

export function zoneDistanceKm(z: Zone, lat: number, lng: number): number {
  return haversineKm(z.lat, z.lng, lat, lng);
}

export function normaliseZone(raw: any): Zone | null {
  if (!raw || typeof raw !== 'object') return null;
  const lat = Number(raw.lat);
  const lng = Number(raw.lng);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  const travel: TravelMode = ['walk', 'bike', 'transit', 'car'].includes(raw.travel)
    ? raw.travel
    : 'transit';
  return {
    lat,
    lng,
    label: String(raw.label ?? ''),
    mode: raw.mode === 'travel' ? 'travel' : 'radius',
    radiusKm: Number.isFinite(Number(raw.radiusKm)) ? Math.min(50, Math.max(0.3, Number(raw.radiusKm))) : 3,
    minutes: Number.isFinite(Number(raw.minutes)) ? Math.min(180, Math.max(5, Number(raw.minutes))) : 30,
    travel,
    places: Array.isArray(raw.places) ? raw.places : [],
    communes: Array.isArray(raw.communes) ? raw.communes : [],
  };
}
