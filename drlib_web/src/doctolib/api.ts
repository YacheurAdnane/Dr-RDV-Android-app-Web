/**
 * Port of lib/src/doctolib_api.dart.
 *
 * A thin client over the JSON endpoints doctolib.fr's own web front-end calls.
 * None of these need a session cookie or a CSRF token; they are the same
 * requests the public website issues while you browse it. They are also
 * undocumented, so every response is parsed defensively and a shape change
 * surfaces as a DoctolibError rather than a crash.
 */

import * as tz from '../lib/tz';
import { jitterMs, RateGuard, sleep } from './rate-guard';
import {
  DoctorRef,
  PlaceRef,
  PlaceSuggestion,
  placeFromWindowPlace,
  placeSearchPayload,
  ProfileSuggestion,
  SpecialityRef,
  VisitMotive,
} from './models';

export class DoctolibError extends Error {
  constructor(
    message: string,
    readonly statusCode?: number,
  ) {
    super(message);
    this.name = 'DoctolibError';
  }

  get isBlocked(): boolean {
    return this.statusCode === 403 || this.statusCode === 429;
  }
}

/** Raised when the invocation's subrequest budget runs out. Not a failure. */
export class BudgetExhausted extends Error {
  constructor() {
    super('Budget de requetes epuise pour ce cycle.');
    this.name = 'BudgetExhausted';
  }
}

export interface HcpSearchPage {
  total: number;
  doctors: DoctorRef[];
}

export interface BookingInfo {
  profileName: string;
  speciality: string;
  motives: VisitMotive[];
  practiceIds: number[];
}

export interface AvailabilityResult {
  /** Every free slot inside the scanned window, in chronological order. */
  slots: Date[];
  /** The first slot after the scanned window, when Doctolib volunteers it. */
  nextSlot: Date | null;
}

const BASE = 'https://www.doctolib.fr';

const HEADERS: Record<string, string> = {
  'User-Agent':
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
    '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
  'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
};

export class DoctolibApi {
  /**
   * Floor between two requests. A random jitter is added on top so the traffic
   * never looks like a metronome. Wider than the phone app's 900 ms: this is
   * one address serving everybody, so it should look slower, not faster.
   */
  readonly minGapMs = 1400;

  private lastCall = 0;
  /** Resolved places are stable, so we only pay for the HTML page once. */
  private placeCache = new Map<string, PlaceRef>();

  constructor(readonly guard: RateGuard) {}

  private async throttle(): Promise<void> {
    const wait = this.minGapMs + jitterMs();
    const since = Date.now() - this.lastCall;
    if (this.lastCall > 0 && since < wait) await sleep(wait - since);
    this.lastCall = Date.now();
  }

  private async send(path: string, init: RequestInit, accept: string): Promise<Response> {
    if (this.guard.isPaused) {
      throw new DoctolibError(
        this.guard.lastBlockMessage ??
          `Surveillance en pause encore ${this.guard.pauseRemainingMinutes} min.`,
      );
    }
    if (this.guard.budgetExhausted) {
      throw new DoctolibError(`Quota quotidien atteint (${this.guard.maxRequestsPerDay} requetes).`);
    }
    if (this.guard.tickExhausted) throw new BudgetExhausted();

    await this.throttle();

    let last: Response | null = null;
    for (let attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        // Exponential backoff with jitter between retries of one request.
        await sleep(900 * attempt * attempt + jitterMs(600));
        if (this.guard.tickExhausted) throw new BudgetExhausted();
      }
      this.guard.recordRequest();
      try {
        last = await fetch(`${BASE}${path}`, {
          ...init,
          headers: { ...HEADERS, Accept: accept, ...(init.headers as Record<string, string>) },
          redirect: 'follow',
          signal: AbortSignal.timeout(25_000),
        });
      } catch (e) {
        if (attempt === 2) throw new DoctolibError(`Reseau indisponible : ${e}`);
        continue;
      }

      // 206 is what the paginated search returns for a partial result set.
      if (last.status === 200 || last.status === 206) {
        this.guard.recordSuccess();
        return last;
      }
      // Being told to slow down is the one signal worth obeying immediately:
      // stop the whole run and stay away for a while.
      if (last.status === 403 || last.status === 429) {
        this.guard.recordBlock(last.status);
        throw new DoctolibError(this.guard.lastBlockMessage!, last.status);
      }
      if (last.status >= 500) continue;
      break;
    }

    const reason = last ? await explain(last) : '';
    throw new DoctolibError(
      `Doctolib a repondu ${last?.status ?? '?'}${reason}`,
      last?.status,
    );
  }

  private get(path: string, accept = 'application/json'): Promise<Response> {
    return this.send(path, { method: 'GET' }, accept);
  }

  private post(path: string, body: unknown): Promise<Response> {
    return this.send(
      path,
      {
        method: 'POST',
        body: JSON.stringify(body),
        headers: { 'Content-Type': 'application/json' },
      },
      'application/json',
    );
  }

  // -------------------------------------------------------------------------
  // Search bar
  // -------------------------------------------------------------------------

  /**
   * What the Doctolib search bar suggests as you type: specialities on one
   * side, named practitioners and clinics on the other.
   */
  async autocomplete(
    query: string,
  ): Promise<{ specialities: SpecialityRef[]; profiles: ProfileSuggestion[] }> {
    if (query.trim().length < 2) return { specialities: [], profiles: [] };
    const res = await this.post('/patient-health-search/api/v1/autocomplete', {
      query: query.trim(),
    });
    const j: any = await res.json();

    const specialities: SpecialityRef[] = [];
    for (const e of j.searchEntries ?? []) {
      if (e?.kind !== 'SPECIALITY') continue;
      specialities.push({
        id: `${e.id}`,
        slug: String(e.slug ?? ''),
        name: String(e.name ?? ''),
      });
    }

    const profiles: ProfileSuggestion[] = [];
    for (const m of j.profiles ?? []) {
      const first = String(m?.firstName ?? '').trim();
      const name = String(m?.name ?? '').trim();
      profiles.push({
        profileId: `${m?.profileId}`,
        displayName: first ? `${first} ${name}` : name,
        speciality: String(m?.speciality ?? m?.organizationStatus ?? ''),
        city: String(m?.city ?? ''),
        link: String(m?.link ?? ''),
        isOrganization: m?.type === 'ORGANIZATION',
      });
    }
    return { specialities, profiles };
  }

  /** City suggestions for the "Ou ?" field. */
  async placeAutocomplete(query: string): Promise<PlaceSuggestion[]> {
    if (query.trim().length < 2) return [];
    const res = await this.get(
      `/patient_app/place_autocomplete.json?query=${encodeURIComponent(query.trim())}`,
    );
    const list: any = await res.json();
    if (!Array.isArray(list)) return [];
    return list
      .map((m: any) => ({
        label: String(m?.label ?? m?.description ?? ''),
        city: String(m?.city ?? ''),
        country: String(m?.country ?? ''),
        isLocality: (m?.types ?? []).includes('locality'),
      }))
      .filter((p) => p.city !== '');
  }

  /**
   * Turns a city name into the full place object the search endpoint demands.
   *
   * Doctolib never exposes that object through an API; it only ships it inside
   * the `window.place = {...}` script of a search results page. So we load one
   * such page and read it out. Results are cached for the life of the client.
   */
  async resolvePlace(cityName: string, specialitySlug = 'medecin-generaliste'): Promise<PlaceRef> {
    const citySlug = slugify(cityName);
    const cached = this.placeCache.get(citySlug);
    if (cached) return cached;

    // The speciality half of the URL only has to exist; try the caller's
    // first, then a speciality available in every French town.
    for (const spec of new Set([specialitySlug, 'medecin-generaliste'])) {
      let html: string;
      try {
        const res = await this.get(`/${spec}/${citySlug}`, 'text/html');
        html = await res.text();
      } catch (e) {
        if (e instanceof BudgetExhausted) throw e;
        if (e instanceof DoctolibError && e.isBlocked) throw e;
        continue;
      }
      const match = /window\.place\s*=\s*(\{[\s\S]*?\});/.exec(html);
      if (!match) continue;
      try {
        const place = placeFromWindowPlace(JSON.parse(match[1]));
        if (place) {
          this.placeCache.set(citySlug, place);
          return place;
        }
      } catch {
        continue;
      }
    }
    throw new DoctolibError(`Ville « ${cityName} » introuvable sur Doctolib.`);
  }

  // -------------------------------------------------------------------------
  // Practitioner search
  // -------------------------------------------------------------------------

  /**
   * One page (20 results) of practitioners for a speciality in a city.
   *
   * `availableBefore` is the interesting one: Doctolib filters server-side on
   * it, so asking for "someone bookable in the next 3 days" costs a single
   * request instead of polling every practitioner in town.
   */
  async searchDoctors(opts: {
    keyword: string;
    place: PlaceRef;
    page?: number;
    availableBefore?: Date | null;
    telehealth?: boolean | null;
  }): Promise<HcpSearchPage> {
    const filters: Record<string, unknown> = {};
    if (opts.availableBefore) filters.availabilitiesBefore = tz.isoOffset(opts.availableBefore);
    if (opts.telehealth === true) filters.telehealth = true;

    const res = await this.post(
      `/patient-health-search/api/v1/hcp/search?page=${opts.page ?? 0}`,
      {
        keyword: opts.keyword,
        location: { place: placeSearchPayload(opts.place) },
        filters,
      },
    );
    const j: any = await res.json();
    const doctors: DoctorRef[] = [];
    for (const e of j.healthcareProviders ?? []) {
      const d = parseDoctor(e);
      if (d) doctors.push(d);
    }
    return { total: Number(j.total ?? doctors.length), doctors };
  }

  // -------------------------------------------------------------------------
  // One practitioner's booking configuration
  // -------------------------------------------------------------------------

  /**
   * The motives, agendas and practices of a single practitioner: what the
   * booking funnel loads when you open their Doctolib page.
   */
  async bookingInfo(profileSlug: string): Promise<BookingInfo> {
    const res = await this.get(
      '/online_booking/api/slot_selection_funnel/v1/info.json' +
        `?profile_slug=${encodeURIComponent(profileSlug)}&locale=fr`,
    );
    const j: any = await res.json();
    const data = j?.data;
    if (!data) throw new DoctolibError('Page praticien illisible.');

    const categories = new Map<number, string>();
    for (const m of data.visit_motive_categories ?? []) {
      categories.set(Number(m.id), String(m.name ?? ''));
    }

    // agenda id -> the motives that agenda accepts, and where.
    const agendasByMotive = new Map<number, number[]>();
    const practicesByMotive = new Map<number, Set<number>>();
    for (const a of data.agendas ?? []) {
      if (a?.booking_temporary_disabled === true) continue;
      const agendaId = Number(a.id);
      const practiceId = a.practice_id == null ? null : Number(a.practice_id);
      for (const v of a.visit_motive_ids ?? []) {
        const vid = Number(v);
        if (!agendasByMotive.has(vid)) agendasByMotive.set(vid, []);
        agendasByMotive.get(vid)!.push(agendaId);
        if (practiceId != null) {
          if (!practicesByMotive.has(vid)) practicesByMotive.set(vid, new Set());
          practicesByMotive.get(vid)!.add(practiceId);
        }
      }
    }

    const motives: VisitMotive[] = [];
    for (const m of data.visit_motives ?? []) {
      const id = Number(m.id);
      const agendas = agendasByMotive.get(id) ?? [];
      if (agendas.length === 0) continue;
      motives.push({
        id,
        name: String(m.name ?? 'Motif'),
        categoryName: categories.get(Number(m.visit_motive_category_id ?? -1)) ?? '',
        agendaIds: agendas,
        practiceIds: [...(practicesByMotive.get(id) ?? [])],
        telehealth: m.telehealth === true,
      });
    }

    const practiceIds = new Set<number>();
    for (const e of data.places ?? []) {
      for (const p of e?.practice_ids ?? []) practiceIds.add(Number(p));
    }

    const profile = data.profile ?? {};
    return {
      profileName: String(profile.name_with_title ?? profileSlug),
      speciality: String(profile.subtitle ?? ''),
      motives,
      practiceIds: [...practiceIds],
    };
  }

  // -------------------------------------------------------------------------
  // Availabilities
  // -------------------------------------------------------------------------

  /**
   * Doctolib refuses any `limit` above this with a 400
   * ("limit: must be less than or equal to 15").
   */
  static readonly maxDaysPerCall = 15;

  /**
   * Free slots for a given motive / agenda / practice combination.
   *
   * Covers `days` days from `startDate`. The endpoint serves at most
   * maxDaysPerCall days per request, so longer windows are fetched in
   * consecutive chunks. The loop stops early when Doctolib reports that the
   * next free slot lies beyond the window, so a long window with nothing in it
   * still costs a single request.
   */
  async availabilities(opts: {
    visitMotiveIds: number[];
    agendaIds: number[];
    practiceIds: number[];
    startDate: Date;
    days?: number;
  }): Promise<AvailabilityResult> {
    const total = Math.min(60, Math.max(1, opts.days ?? 7));
    const firstDay = tz.startOfDay(opts.startDate);
    const windowEnd = tz.addDays(firstDay, total);

    const slots: Date[] = [];
    let next: Date | null = null;
    let offset = 0;
    while (offset < total) {
      const chunk = Math.min(DoctolibApi.maxDaysPerCall, total - offset);
      const res = await this.availabilityChunk({
        ...opts,
        start: tz.addDays(firstDay, offset),
        days: chunk,
      });
      slots.push(...res.slots);
      next = res.nextSlot;
      offset += chunk;
      // Nothing more until after the window: the remaining chunks would come
      // back empty.
      if (res.slots.length === 0 && (next == null || next >= windowEnd)) break;
    }
    slots.sort((a, b) => a.getTime() - b.getTime());
    return { slots, nextSlot: next };
  }

  private async availabilityChunk(opts: {
    visitMotiveIds: number[];
    agendaIds: number[];
    practiceIds: number[];
    start: Date;
    days: number;
  }): Promise<AvailabilityResult> {
    const q: Record<string, string> = {
      start_date: tz.isoDate(opts.start),
      visit_motive_ids: opts.visitMotiveIds.join('-'),
      agenda_ids: opts.agendaIds.join('-'),
      insurance_sector: 'public',
      destroy_temporary: 'true',
      limit: String(Math.min(DoctolibApi.maxDaysPerCall, Math.max(1, opts.days))),
    };
    if (opts.practiceIds.length > 0) q.practice_ids = opts.practiceIds.join('-');

    const query = Object.entries(q)
      .map(([k, v]) => `${k}=${encodeURIComponent(v)}`)
      .join('&');
    const res = await this.get(`/availabilities.json?${query}`);
    const j: any = await res.json();

    const slots: Date[] = [];
    for (const e of j.availabilities ?? []) {
      for (const s of e?.slots ?? []) {
        // Slots are either plain ISO strings or objects carrying a start_date.
        const raw = typeof s === 'string' ? s : s?.start_date;
        if (typeof raw !== 'string') continue;
        const dt = new Date(raw);
        if (!Number.isNaN(dt.getTime())) slots.push(dt);
      }
    }

    const nextRaw = j.next_slot;
    const next = typeof nextRaw === 'string' ? new Date(nextRaw) : null;
    return {
      slots,
      nextSlot: next && !Number.isNaN(next.getTime()) ? next : null,
    };
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function parseDoctor(m: any): DoctorRef | null {
  const refs = m?.references;
  const motive = m?.matchedVisitMotive;
  const booking = m?.onlineBooking;
  if (!refs) return null;

  const agendaIds: number[] = (motive?.agendaIds ?? booking?.agendaIds ?? []).map(Number);
  if (agendaIds.length === 0) return null;

  const loc = m.location ?? {};
  const first = String(m.firstName ?? '').trim();
  const last = String(m.name ?? '').trim();
  const title = String(m.title ?? '').trim();
  const display = [title, first, last].filter(Boolean).join(' ').replace(/\s+/g, ' ');

  return {
    key: String(m.id ?? `${refs.id}-${refs.practiceId}`),
    profileId: Number(refs.id),
    practiceId: Number(refs.practiceId ?? 0),
    displayName: display || 'Praticien',
    specialityName: String(m.speciality?.name ?? ''),
    city: String(loc.city ?? ''),
    address: String(loc.address ?? ''),
    link: String(m.link ?? ''),
    agendaIds,
    visitMotiveId: motive?.visitMotiveId == null ? null : Number(motive.visitMotiveId),
    visitMotiveName: String(motive?.name ?? ''),
    allowNewPatients: motive?.allowNewPatients !== false,
    telehealth: booking?.telehealth === true,
    lat: loc.lat == null ? null : Number(loc.lat),
    lng: loc.lng == null ? null : Number(loc.lng),
  };
}

/**
 * Doctolib usually explains a 4xx in the body (`{"error": ["..."]}`).
 * Surfacing it turns "400" into something that says what to fix.
 */
async function explain(res: Response): Promise<string> {
  try {
    const j: any = await res.json();
    const err = j?.error ?? j?.errors ?? j?.message;
    const text = Array.isArray(err) ? err.join(', ') : err == null ? null : String(err);
    if (!text) return '';
    return ` : ${text.length > 120 ? `${text.slice(0, 120)}...` : text}`;
  } catch {
    return '';
  }
}

/**
 * Doctolib city slugs are accent-free, lowercase and hyphenated:
 * "Saint-Etienne" -> "saint-etienne", "Lyon 8" -> "lyon-8".
 */
export function slugify(input: string): string {
  const from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿœæ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyyoa';
  let out = '';
  for (const ch of input.toLowerCase()) {
    const idx = from.indexOf(ch);
    out += idx >= 0 ? to[idx] : ch;
  }
  return out
    .replace(/['’]/g, '-')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}
