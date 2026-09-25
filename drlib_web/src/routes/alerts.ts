import { DoctolibApi } from '../doctolib/api';
import { runAlert } from '../doctolib/engine';
import {
  defaultWatch,
  isIgnored,
  isSilent,
  normaliseWatch,
  slotId,
  WatchConfig,
} from '../doctolib/models';
import { RateGuard } from '../doctolib/rate-guard';
import { normaliseZone } from '../doctolib/zone';
import { newId } from '../lib/crypto';
import { badRequest, Env, json, notFound, readJson, str } from '../lib/http';
import { requireUser, User } from '../lib/session';
import { addJournal, AlertRow, parseConfig, rowToState, saveState } from '../lib/store';

/** How many alerts one account may keep. Each one costs requests forever. */
const MAX_ALERTS_PER_USER = 10;

/**
 * Budget for a "check now" button. Lower than the cron's, because a user who
 * taps it five times should not be able to spend the whole day's allowance.
 */
const MANUAL_TICK_BUDGET = 18;

export async function listAlerts(req: Request, env: Env): Promise<Response> {
  const user = await requireUser(req, env);

  // Opening the alert list is what "still using this" means. Recorded here
  // rather than on every API call so a background push-subscription refresh
  // does not keep a dormant account looking alive.
  await env.DB.prepare('UPDATE users SET last_seen_at = ? WHERE id = ?')
    .bind(new Date().toISOString(), user.id)
    .run();

  const { results } = await env.DB.prepare(
    'SELECT * FROM alerts WHERE user_id = ? ORDER BY created_at ASC',
  )
    .bind(user.id)
    .all<AlertRow>();

  const guard = await guardRow(env);
  return json({
    alerts: results.map((r) => publicAlert(r)),
    guard,
  });
}

export async function getAlert(req: Request, env: Env, id: string): Promise<Response> {
  const user = await requireUser(req, env);
  const row = await ownedAlert(env, user, id);
  return json({ alert: publicAlert(row, true) });
}

export async function createAlert(req: Request, env: Env): Promise<Response> {
  const user = await requireUser(req, env);

  const count = await env.DB.prepare('SELECT COUNT(*) AS n FROM alerts WHERE user_id = ?')
    .bind(user.id)
    .first<{ n: number }>();
  if ((count?.n ?? 0) >= MAX_ALERTS_PER_USER) {
    throw badRequest(`Maximum ${MAX_ALERTS_PER_USER} alertes par compte.`);
  }

  const body = await readJson<{ title?: string; config?: unknown }>(req);
  const title = str(body.title, 'titre', 80);
  const id = newId('a_');
  const config = buildConfig(body.config, id, title);
  validate(config);

  const now = new Date().toISOString();
  // No delivery channel means no reason to spend requests on it.
  const enabled = isSilent(config) ? 0 : 1;
  await env.DB.prepare(
    `INSERT INTO alerts (id, user_id, title, config, enabled, next_check_at, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
  )
    // Due immediately: the first check is what tells the user the alert works.
    .bind(id, user.id, title, JSON.stringify(config), enabled, now, now, now)
    .run();

  const row = await ownedAlert(env, user, id);
  return json({ alert: publicAlert(row, true) }, 201);
}

export async function updateAlert(req: Request, env: Env, id: string): Promise<Response> {
  const user = await requireUser(req, env);
  const row = await ownedAlert(env, user, id);

  const body = await readJson<{ title?: string; config?: unknown; enabled?: boolean }>(req);
  const title = body.title === undefined ? row.title : str(body.title, 'titre', 80);
  const config =
    body.config === undefined
      ? parseConfig(row.config, id, title)
      : buildConfig(body.config, id, title);
  validate(config);

  let enabled = body.enabled === undefined ? row.enabled : body.enabled ? 1 : 0;
  // Turning both channels off is how a user says "stop checking this", so it
  // is honoured even when they did not touch the enabled switch.
  if (isSilent(config)) enabled = 0;

  await env.DB.prepare(
    `UPDATE alerts SET title = ?, config = ?, enabled = ?, updated_at = ?,
       next_check_at = CASE WHEN ? = 1 AND enabled = 0 THEN ? ELSE next_check_at END
     WHERE id = ?`,
  )
    .bind(
      title,
      JSON.stringify(config),
      enabled,
      new Date().toISOString(),
      enabled,
      new Date().toISOString(),
      id,
    )
    .run();

  return json({ alert: publicAlert(await ownedAlert(env, user, id), true) });
}

export async function deleteAlert(req: Request, env: Env, id: string): Promise<Response> {
  const user = await requireUser(req, env);
  await ownedAlert(env, user, id);
  await env.DB.prepare('DELETE FROM alerts WHERE id = ?').bind(id).run();
  return json({ ok: true });
}

/** Runs one alert right now, on the user's behalf. */
export async function checkNow(req: Request, env: Env, id: string): Promise<Response> {
  const user = await requireUser(req, env);
  const row = await ownedAlert(env, user, id);

  const guard = await RateGuard.load(
    env.DB,
    Number(env.MAX_REQUESTS_PER_DAY ?? 800) || 800,
    MANUAL_TICK_BUDGET,
  );
  const gate = guard.canRun();
  if (!gate.ok) return json({ error: gate.reason, code: 'paused' }, 429);

  const state = rowToState(row);
  const api = new DoctolibApi(guard);
  const now = new Date();
  const outcome = await runAlert(api, state, now);

  const next = new Date(now.getTime() + state.config.intervalMinutes * 60_000);
  await saveState(env.DB, state, next);
  await guard.save(env.DB);

  await addJournal(env.DB, {
    userId: user.id,
    alertId: id,
    title: state.title,
    kind: outcome.error ? 'error' : outcome.hits.length > 0 ? 'found' : 'nothing',
    slots: outcome.hits.filter((h) => !isIgnored(state.config, h)).length,
    fresh: outcome.freshHits.length,
    requests: outcome.requests,
    detail: outcome.error ?? outcome.note ?? 'Verification manuelle',
  });

  // Deliberately no push here: the user is looking at the screen. The fresh
  // slots come back in the response and the page highlights them.
  return json({
    alert: publicAlert(await ownedAlert(env, user, id), true),
    fresh: outcome.freshHits.map(slotId),
    error: outcome.error ?? null,
    note: outcome.note ?? null,
    deferred: outcome.deferred,
    requests: outcome.requests,
  });
}

export async function snoozeAlert(req: Request, env: Env, id: string): Promise<Response> {
  const user = await requireUser(req, env);
  const row = await ownedAlert(env, user, id);
  const body = await readJson<{ minutes?: number }>(req);
  const minutes = Number(body.minutes ?? 0);

  const config = parseConfig(row.config, id, row.title);
  config.snoozedUntil =
    minutes > 0 ? new Date(Date.now() + Math.min(minutes, 7 * 24 * 60) * 60_000).toISOString() : null;

  await env.DB.prepare('UPDATE alerts SET config = ?, updated_at = ? WHERE id = ?')
    .bind(JSON.stringify(config), new Date().toISOString(), id)
    .run();
  return json({ alert: publicAlert(await ownedAlert(env, user, id), true) });
}

/** The three levels of "not this one": a slot, a whole day, a practitioner. */
export async function ignore(req: Request, env: Env, id: string): Promise<Response> {
  const user = await requireUser(req, env);
  const row = await ownedAlert(env, user, id);
  const body = await readJson<{ kind?: string; value?: string; undo?: boolean }>(req);
  const kind = str(body.kind, 'type', 20);
  const value = str(body.value, 'valeur', 200);

  const config = parseConfig(row.config, id, row.title);
  const field =
    kind === 'slot'
      ? 'ignoredSlots'
      : kind === 'date'
        ? 'ignoredDates'
        : kind === 'doctor'
          ? 'ignoredDoctors'
          : null;
  if (!field) throw badRequest('Type d\'exclusion inconnu.');

  const set = new Set(config[field]);
  if (body.undo) set.delete(value);
  else set.add(value);
  config[field] = [...set];

  await env.DB.prepare('UPDATE alerts SET config = ?, updated_at = ? WHERE id = ?')
    .bind(JSON.stringify(config), new Date().toISOString(), id)
    .run();
  return json({ alert: publicAlert(await ownedAlert(env, user, id), true) });
}

export async function journal(req: Request, env: Env): Promise<Response> {
  const user = await requireUser(req, env);
  const { results } = await env.DB.prepare(
    'SELECT at, alert_id, title, kind, slots, fresh, requests, detail FROM journal WHERE user_id = ? ORDER BY id DESC LIMIT 100',
  )
    .bind(user.id)
    .all();
  return json({ entries: results });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function ownedAlert(env: Env, user: User, id: string): Promise<AlertRow> {
  const row = await env.DB.prepare('SELECT * FROM alerts WHERE id = ? AND user_id = ?')
    .bind(id, user.id)
    .first<AlertRow>();
  if (!row) throw notFound('Alerte introuvable.');
  return row;
}

async function guardRow(env: Env) {
  const g = await env.DB.prepare(
    'SELECT requests_today, paused_until, last_block_message FROM guard WHERE id = 1',
  ).first<{ requests_today: number; paused_until: string | null; last_block_message: string | null }>();
  const paused = g?.paused_until && new Date(g.paused_until) > new Date();
  return {
    requestsToday: g?.requests_today ?? 0,
    maxPerDay: Number(env.MAX_REQUESTS_PER_DAY ?? 800) || 800,
    paused: Boolean(paused),
    message: paused ? g?.last_block_message ?? null : null,
  };
}

/**
 * Builds a config from whatever the client sent.
 *
 * Client input is never trusted into the config wholesale: everything goes
 * through normaliseWatch, which clamps the numbers and drops unknown enum
 * values, and the zone through normaliseZone. A user cannot, for instance,
 * set intervalMinutes to 1 and make the deployment hammer Doctolib.
 */
function buildConfig(raw: unknown, id: string, title: string): WatchConfig {
  const base = defaultWatch(id, title);
  const w = normaliseWatch({ ...base, ...(raw as object) }, id, title);
  w.zone = normaliseZone((raw as any)?.zone);
  // Server-side state is never client-writable.
  w.snoozedUntil = typeof (raw as any)?.snoozedUntil === 'string' ? (raw as any).snoozedUntil : null;
  return w;
}

function validate(w: WatchConfig): void {
  if (w.kind === 'speciality') {
    if (!w.place) throw badRequest('Choisissez une ville.');
    if (w.specialities.length === 0) throw badRequest('Choisissez au moins une specialite.');
  } else if (!w.doctor) {
    throw badRequest('Choisissez un praticien.');
  }
  if (w.mode === 'dateRange') {
    if (!w.from || !w.to) throw badRequest('Indiquez les deux dates.');
    if (new Date(w.from) > new Date(w.to)) throw badRequest('La date de fin precede la date de debut.');
  }
}

function publicAlert(row: AlertRow, full = false) {
  const config = parseConfig(row.config, row.id, row.title);
  const state = rowToState(row);
  const visible = state.lastHits.filter((h) => !isIgnored(config, h));
  return {
    id: row.id,
    title: row.title,
    enabled: row.enabled === 1,
    config,
    lastCheckedAt: row.last_checked_at,
    nextCheckAt: row.next_check_at,
    lastError: row.last_error,
    lastRequestCount: row.last_request_count,
    slotCount: visible.length,
    hits: full ? visible : visible.slice(0, 3),
    hiddenCount: full ? state.lastHits.length - visible.length : 0,
  };
}
