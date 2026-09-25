/**
 * Port of lib/src/geo_api.dart.
 *
 * French government geocoding: the national address base (BAN) served by the
 * IGN Geoplateforme, and the official list of communes. Free, keyless, and run
 * by the State rather than an ad company, which matters for a home address.
 *
 * Only reached while a user sets up a zone; the routine checks never send a
 * location anywhere.
 */

import { Commune, offsetPoint } from './zone';

export interface GeoAddress {
  label: string;
  lat: number;
  lng: number;
  city: string;
}

export class GeoError extends Error {}

const HEADERS = { 'User-Agent': 'DRlibAlertes/1.0 (application web)' };

async function get(url: string): Promise<any> {
  const res = await fetch(url, { headers: HEADERS, signal: AbortSignal.timeout(15_000) });
  if (res.status !== 200) throw new GeoError(`Service de geocodage indisponible (${res.status}).`);
  return res.json();
}

function features(j: any): GeoAddress[] {
  const out: GeoAddress[] = [];
  for (const f of j?.features ?? []) {
    const coords = f?.geometry?.coordinates;
    const p = f?.properties ?? {};
    if (!Array.isArray(coords)) continue;
    out.push({
      label: String(p.label ?? ''),
      lng: Number(coords[0]),
      lat: Number(coords[1]),
      city: String(p.city ?? ''),
    });
  }
  return out;
}

/** Addresses matching what the user typed. */
export async function searchAddress(query: string): Promise<GeoAddress[]> {
  if (query.trim().length < 3) return [];
  const url = `https://data.geopf.fr/geocodage/search?q=${encodeURIComponent(query.trim())}&limit=6`;
  return features(await get(url));
}

/** The closest address to a point, for a readable label under a map pin. */
export async function reverse(lat: number, lng: number): Promise<GeoAddress | null> {
  const url = `https://data.geopf.fr/geocodage/reverse?lat=${lat}&lon=${lng}&limit=1`;
  const list = features(await get(url));
  return list.length === 0 ? null : list[0];
}

/** The commune containing a point, or null at sea or abroad. */
export async function communeAt(lat: number, lng: number): Promise<Commune | null> {
  const url =
    `https://geo.api.gouv.fr/communes?lat=${lat}&lon=${lng}` +
    '&fields=nom,code,centre,population';
  const list = await get(url);
  if (!Array.isArray(list) || list.length === 0) return null;
  const m = list[0];
  const centre = m?.centre?.coordinates;
  return {
    name: String(m.nom),
    code: String(m.code ?? ''),
    lng: Array.isArray(centre) ? Number(centre[0]) : lng,
    lat: Array.isArray(centre) ? Number(centre[1]) : lat,
    population: Number(m.population ?? 0),
  };
}

/**
 * The communes a circle overlaps, found by probing points across it.
 *
 * Rings at a third, two thirds and the full radius, denser further out, so no
 * town wider than roughly the spacing between probes slips through. Capped at
 * `max` (each town costs one Doctolib request per check): the origin's own town
 * first, then by population, since that is where practitioners are.
 */
export async function communesInZone(
  lat: number,
  lng: number,
  radiusKm: number,
  max = 8,
): Promise<Commune[]> {
  const probes: { lat: number; lng: number }[] = [{ lat, lng }];
  for (const [frac, count] of [
    [1 / 3, 6],
    [2 / 3, 10],
    [1.0, 14],
  ] as const) {
    for (let i = 0; i < count; i++) {
      probes.push(offsetPoint(lat, lng, radiusKm * frac, (360 / count) * i));
    }
  }

  const found = new Map<string, Commune>();
  let home: Commune | null = null;
  // Small batches: polite to the service and still quick.
  for (let i = 0; i < probes.length; i += 6) {
    const batch = probes.slice(i, i + 6);
    const results = await Promise.all(
      batch.map(async (p) => {
        try {
          return await communeAt(p.lat, p.lng);
        } catch {
          return null;
        }
      }),
    );
    for (const c of results) {
      if (c && !found.has(c.code)) found.set(c.code, c);
    }
    if (i === 0 && results.length > 0) home = results[0];
  }

  const rest = [...found.values()]
    .filter((c) => c.code !== home?.code)
    .sort((a, b) => b.population - a.population);
  return [...(home ? [home] : []), ...rest].slice(0, max);
}
