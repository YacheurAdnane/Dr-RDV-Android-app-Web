/**
 * The search half of the Doctolib client, exposed to the page.
 *
 * The browser cannot call doctolib.fr directly (no CORS headers there), so
 * every lookup the creation form needs is proxied here. These are interactive
 * requests, so they get a tight per-request budget and share the same rate
 * guard as the cron: a user typing in the search box and the scheduler are the
 * same address as far as Doctolib is concerned.
 */

import { BudgetExhausted, DoctolibApi, DoctolibError } from '../doctolib/api';
import { communesInZone, reverse, searchAddress } from '../doctolib/geo';
import { lastPathSegment } from '../doctolib/models';
import { RateGuard } from '../doctolib/rate-guard';
import { badRequest, Env, json } from '../lib/http';
import { requireUser } from '../lib/session';

const INTERACTIVE_BUDGET = 8;

async function client(env: Env): Promise<{ api: DoctolibApi; guard: RateGuard }> {
  const guard = await RateGuard.load(
    env.DB,
    Number(env.MAX_REQUESTS_PER_DAY ?? 800) || 800,
    INTERACTIVE_BUDGET,
  );
  return { api: new DoctolibApi(guard), guard };
}

/** Wraps a lookup so a Doctolib failure reads as a message, not a 500. */
async function run<T>(env: Env, fn: (api: DoctolibApi) => Promise<T>): Promise<Response> {
  const { api, guard } = await client(env);
  const gate = guard.canRun();
  if (!gate.ok) return json({ error: gate.reason, code: 'paused' }, 429);
  try {
    const data = await fn(api);
    return json(data);
  } catch (e) {
    // The interactive budget is small on purpose, and hitting it while typing
    // in the search box is ordinary. Say so rather than returning a 500.
    if (e instanceof BudgetExhausted) {
      return json(
        { error: 'Trop de recherches d\'affilee. Patientez quelques secondes.', code: 'budget' },
        429,
      );
    }
    if (e instanceof DoctolibError) {
      return json({ error: e.message, code: e.isBlocked ? 'blocked' : 'doctolib' }, 502);
    }
    throw e;
  } finally {
    await guard.save(env.DB);
  }
}

export async function autocomplete(req: Request, env: Env): Promise<Response> {
  await requireUser(req, env);
  const q = new URL(req.url).searchParams.get('q') ?? '';
  if (q.trim().length < 2) return json({ specialities: [], profiles: [] });
  return run(env, (api) => api.autocomplete(q));
}

export async function places(req: Request, env: Env): Promise<Response> {
  await requireUser(req, env);
  const q = new URL(req.url).searchParams.get('q') ?? '';
  if (q.trim().length < 2) return json({ places: [] });
  return run(env, async (api) => ({ places: await api.placeAutocomplete(q) }));
}

/** Turns a city name into the full place object the search endpoint demands. */
export async function resolvePlace(req: Request, env: Env): Promise<Response> {
  await requireUser(req, env);
  const url = new URL(req.url);
  const city = url.searchParams.get('city');
  if (!city) throw badRequest('Parametre « city » manquant.');
  const spec = url.searchParams.get('spec') ?? 'medecin-generaliste';
  return run(env, async (api) => ({ place: await api.resolvePlace(city, spec) }));
}

/** The visit motives of one practitioner, for the doctor-watch form. */
export async function motives(req: Request, env: Env): Promise<Response> {
  await requireUser(req, env);
  const link = new URL(req.url).searchParams.get('link');
  if (!link) throw badRequest('Parametre « link » manquant.');
  const slug = lastPathSegment(link);
  if (!slug) throw badRequest('Lien praticien illisible.');
  return run(env, async (api) => {
    const info = await api.bookingInfo(slug);
    return {
      profileName: info.profileName,
      speciality: info.speciality,
      practiceIds: info.practiceIds,
      motives: info.motives.map((m) => ({
        id: m.id,
        name: m.name,
        categoryName: m.categoryName,
        telehealth: m.telehealth,
      })),
    };
  });
}

// ---------------------------------------------------------------------------
// Geocoding (French government services, not Doctolib — no rate guard needed)
// ---------------------------------------------------------------------------

export async function geoAddress(req: Request, env: Env): Promise<Response> {
  await requireUser(req, env);
  const q = new URL(req.url).searchParams.get('q') ?? '';
  if (q.trim().length < 3) return json({ addresses: [] });
  try {
    return json({ addresses: await searchAddress(q) });
  } catch (e) {
    return json({ error: String(e), addresses: [] }, 502);
  }
}

export async function geoReverse(req: Request, env: Env): Promise<Response> {
  await requireUser(req, env);
  const url = new URL(req.url);
  const lat = Number(url.searchParams.get('lat'));
  const lng = Number(url.searchParams.get('lng'));
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) throw badRequest('Coordonnees invalides.');
  try {
    return json({ address: await reverse(lat, lng) });
  } catch (e) {
    return json({ error: String(e), address: null }, 502);
  }
}

/** The towns a zone circle overlaps — one Doctolib search each, later. */
export async function geoCommunes(req: Request, env: Env): Promise<Response> {
  await requireUser(req, env);
  const url = new URL(req.url);
  const lat = Number(url.searchParams.get('lat'));
  const lng = Number(url.searchParams.get('lng'));
  const radius = Number(url.searchParams.get('radius'));
  if (!Number.isFinite(lat) || !Number.isFinite(lng) || !Number.isFinite(radius)) {
    throw badRequest('Parametres de zone invalides.');
  }
  try {
    // Capped at 6 rather than the app's 8: every town is a recurring cost.
    return json({ communes: await communesInZone(lat, lng, Math.min(radius, 40), 6) });
  } catch (e) {
    return json({ error: String(e), communes: [] }, 502);
  }
}

/**
 * Resolves each town of a zone to a Doctolib place, in one call, so the client
 * does not have to fan out. Bounded by the interactive budget above.
 */
export async function resolveZone(req: Request, env: Env): Promise<Response> {
  await requireUser(req, env);
  const url = new URL(req.url);
  const names = (url.searchParams.get('towns') ?? '').split('|').filter(Boolean).slice(0, 6);
  const spec = url.searchParams.get('spec') ?? 'medecin-generaliste';
  if (names.length === 0) return json({ places: [] });

  return run(env, async (api) => {
    const out = [];
    for (const name of names) {
      try {
        out.push(await api.resolvePlace(name, spec));
      } catch {
        // A town Doctolib does not know is dropped, not fatal: the zone still
        // works, it just covers one town less.
      }
    }
    return { places: out };
  });
}
