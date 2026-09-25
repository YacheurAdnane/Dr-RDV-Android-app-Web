/**
 * Administration: who exists, what they watch, and the shared rate budget.
 *
 * There is no self-service sign-up anywhere in this app. An account exists
 * because an admin created it, which is the whole point — the URL can be
 * public because possession of it grants nothing.
 */

import { isIgnored } from '../doctolib/models';
import { generatePassword, hashPassword, newId } from '../lib/crypto';
import { badRequest, bool, Env, HttpError, json, mailerOf, notFound, optStr, readJson, str } from '../lib/http';
import { destroyAllSessions, requireAdmin } from '../lib/session';
import { AlertRow, parseConfig, rowToState } from '../lib/store';
import { publicUser } from './auth';

interface AdminUserRow {
  id: string;
  username: string;
  email: string;
  is_admin: number;
  email_alerts: number;
  active: number;
  must_change: number;
  created_at: string;
  last_login_at: string | null;
  alert_count: number;
  push_count: number;
}

export async function listUsers(req: Request, env: Env): Promise<Response> {
  await requireAdmin(req, env);
  const { results } = await env.DB.prepare(
    `SELECT u.id, u.username, u.email, u.is_admin, u.email_alerts, u.active,
            u.must_change, u.created_at, u.last_login_at,
            (SELECT COUNT(*) FROM alerts a WHERE a.user_id = u.id) AS alert_count,
            (SELECT COUNT(*) FROM push_subs p WHERE p.user_id = u.id) AS push_count
       FROM users u ORDER BY u.created_at ASC`,
  ).all<AdminUserRow>();

  return json({
    users: results.map((r) => ({
      ...publicUser(r as any),
      active: r.active === 1,
      createdAt: r.created_at,
      lastLoginAt: r.last_login_at,
      alertCount: r.alert_count,
      pushCount: r.push_count,
    })),
  });
}

export async function createUser(req: Request, env: Env): Promise<Response> {
  await requireAdmin(req, env);
  const body = await readJson<{
    username?: string;
    email?: string;
    password?: string;
    isAdmin?: boolean;
    emailAlerts?: boolean;
  }>(req);

  const username = str(body.username, 'identifiant', 64).toLowerCase();
  if (!/^[a-z0-9._-]{3,64}$/.test(username)) {
    throw badRequest('Identifiant : 3 a 64 caracteres, lettres, chiffres, . _ - uniquement.');
  }
  const email = optStr(body.email, 200);
  if (email && !isEmail(email)) throw badRequest('Adresse e-mail invalide.');

  const exists = await env.DB.prepare('SELECT id FROM users WHERE username = ?')
    .bind(username)
    .first();
  if (exists) throw new HttpError(409, 'Cet identifiant est deja pris.', 'taken');

  // A supplied password is honoured; otherwise one is generated and shown
  // once. Generated is the better path — it is the only way the admin can be
  // sure the password was never a reused one.
  const supplied = typeof body.password === 'string' ? body.password : '';
  if (supplied && supplied.length < 10) {
    throw badRequest('Le mot de passe doit faire au moins 10 caracteres.');
  }
  const password = supplied || generatePassword();

  const h = await hashPassword(password);
  const id = newId('u_');
  await env.DB.prepare(
    `INSERT INTO users (id, username, email, pw_hash, pw_salt, pw_iter, is_admin,
                        email_alerts, active, must_change, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, 1, ?)`,
  )
    .bind(
      id,
      username,
      email,
      h.hash,
      h.salt,
      h.iterations,
      bool(body.isAdmin) ? 1 : 0,
      // An address given at creation enables email, unless explicitly refused.
      email ? (body.emailAlerts === false ? 0 : 1) : 0,
      new Date().toISOString(),
    )
    .run();

  return json({ id, username, password, mustChange: true }, 201);
}

export async function updateUser(req: Request, env: Env, id: string): Promise<Response> {
  const admin = await requireAdmin(req, env);
  const row = await env.DB.prepare(
    'SELECT id, is_admin, email, email_alerts FROM users WHERE id = ?',
  )
    .bind(id)
    .first<{ id: string; is_admin: number; email: string; email_alerts: number }>();
  if (!row) throw notFound('Utilisateur introuvable.');

  const body = await readJson<{
    email?: string;
    isAdmin?: boolean;
    emailAlerts?: boolean;
    active?: boolean;
  }>(req);

  const email = body.email === undefined ? row.email : optStr(body.email, 200);
  if (email && !isEmail(email)) throw badRequest('Adresse e-mail invalide.');

  // Guard rails against locking yourself out of your own deployment.
  if (id === admin.id && body.isAdmin === false) {
    throw badRequest('Vous ne pouvez pas retirer vos propres droits administrateur.');
  }
  if (id === admin.id && body.active === false) {
    throw badRequest('Vous ne pouvez pas desactiver votre propre compte.');
  }
  if (body.isAdmin === false && row.is_admin === 1) await assertNotLastAdmin(env, id);

  const sets: string[] = [];
  const args: unknown[] = [];
  const set = (col: string, v: unknown) => {
    sets.push(`${col} = ?`);
    args.push(v);
  };

  if (body.email !== undefined) {
    set('email', email);
    if (!email) {
      // Alerts cannot be on with no address to send to.
      set('email_alerts', 0);
    } else if (!row.email && body.emailAlerts === undefined) {
      // Adding an address where there was none is how an admin says "this
      // person can receive mail". Making them flip a second switch afterwards
      // is a trap: the per-alert checkbox stays greyed out and nothing says why.
      set('email_alerts', 1);
    }
  }
  if (body.isAdmin !== undefined) set('is_admin', body.isAdmin ? 1 : 0);
  if (body.emailAlerts !== undefined) set('email_alerts', body.emailAlerts && email ? 1 : 0);
  if (body.active !== undefined) set('active', body.active ? 1 : 0);
  if (sets.length === 0) return json({ ok: true });

  args.push(id);
  await env.DB.prepare(`UPDATE users SET ${sets.join(', ')} WHERE id = ?`)
    .bind(...args)
    .run();

  // A deactivated account should stop working now, not in thirty days.
  if (body.active === false) await destroyAllSessions(env, id);

  return json({ ok: true });
}

/** Sets a new password and logs the user out everywhere. */
export async function resetPassword(req: Request, env: Env, id: string): Promise<Response> {
  await requireAdmin(req, env);
  const row = await env.DB.prepare('SELECT id, username FROM users WHERE id = ?')
    .bind(id)
    .first<{ id: string; username: string }>();
  if (!row) throw notFound('Utilisateur introuvable.');

  const body = await readJson<{ password?: string }>(req).catch(() => ({ password: undefined }));
  const supplied = typeof body.password === 'string' ? body.password : '';
  if (supplied && supplied.length < 10) {
    throw badRequest('Le mot de passe doit faire au moins 10 caracteres.');
  }
  const password = supplied || generatePassword();

  const h = await hashPassword(password);
  await env.DB.prepare(
    `UPDATE users SET pw_hash = ?, pw_salt = ?, pw_iter = ?, must_change = 1,
                      failed_count = 0, locked_until = NULL WHERE id = ?`,
  )
    .bind(h.hash, h.salt, h.iterations, id)
    .run();
  await destroyAllSessions(env, id);

  return json({ username: row.username, password });
}

export async function deleteUser(req: Request, env: Env, id: string): Promise<Response> {
  const admin = await requireAdmin(req, env);
  if (id === admin.id) throw badRequest('Vous ne pouvez pas supprimer votre propre compte.');

  const row = await env.DB.prepare('SELECT is_admin FROM users WHERE id = ?')
    .bind(id)
    .first<{ is_admin: number }>();
  if (!row) throw notFound('Utilisateur introuvable.');
  if (row.is_admin === 1) await assertNotLastAdmin(env, id);

  // D1 does not enforce ON DELETE CASCADE unless foreign keys are on for the
  // connection, so the children go explicitly. Cheaper than finding out later.
  await env.DB.batch([
    env.DB.prepare('DELETE FROM alerts WHERE user_id = ?').bind(id),
    env.DB.prepare('DELETE FROM push_subs WHERE user_id = ?').bind(id),
    env.DB.prepare('DELETE FROM sessions WHERE user_id = ?').bind(id),
    env.DB.prepare('DELETE FROM journal WHERE user_id = ?').bind(id),
    env.DB.prepare('DELETE FROM users WHERE id = ?').bind(id),
  ]);

  return json({ ok: true });
}

/** Every alert in the deployment, with who owns it. */
export async function listAllAlerts(req: Request, env: Env): Promise<Response> {
  await requireAdmin(req, env);
  const { results } = await env.DB.prepare(
    `SELECT a.*, u.username FROM alerts a
       JOIN users u ON u.id = a.user_id
      ORDER BY a.created_at DESC LIMIT 200`,
  ).all<AlertRow & { username: string }>();

  return json({
    alerts: results.map((row) => {
      const config = parseConfig(row.config, row.id, row.title);
      const state = rowToState(row);
      const visible = state.lastHits.filter((h) => !isIgnored(config, h));
      return {
        id: row.id,
        username: row.username,
        userId: row.user_id,
        title: row.title,
        enabled: row.enabled === 1,
        kind: config.kind,
        subtitle:
          config.kind === 'doctor'
            ? (config.doctor?.displayName ?? '')
            : `${config.specialities.map((s) => s.name).join(', ')} — ${config.place?.name ?? ''}`,
        intervalMinutes: config.intervalMinutes,
        lastCheckedAt: row.last_checked_at,
        nextCheckAt: row.next_check_at,
        lastError: row.last_error,
        slotCount: visible.length,
        createdAt: row.created_at,
      };
    }),
  });
}

/** An admin can delete anyone's alert — the request budget is shared. */
export async function deleteAnyAlert(req: Request, env: Env, id: string): Promise<Response> {
  await requireAdmin(req, env);
  const row = await env.DB.prepare('SELECT id FROM alerts WHERE id = ?').bind(id).first();
  if (!row) throw notFound('Alerte introuvable.');
  await env.DB.prepare('DELETE FROM alerts WHERE id = ?').bind(id).run();
  return json({ ok: true });
}

export async function setAlertEnabled(req: Request, env: Env, id: string): Promise<Response> {
  await requireAdmin(req, env);
  const body = await readJson<{ enabled?: boolean }>(req);
  await env.DB.prepare('UPDATE alerts SET enabled = ?, updated_at = ? WHERE id = ?')
    .bind(body.enabled ? 1 : 0, new Date().toISOString(), id)
    .run();
  return json({ ok: true });
}

/** The shared state: request budget, pauses, recent activity. */
export async function status(req: Request, env: Env): Promise<Response> {
  await requireAdmin(req, env);

  const guard = await env.DB.prepare(
    'SELECT day_key, requests_today, consecutive_blocks, paused_until, last_block_message FROM guard WHERE id = 1',
  ).first<{
    day_key: string;
    requests_today: number;
    consecutive_blocks: number;
    paused_until: string | null;
    last_block_message: string | null;
  }>();

  const counts = await env.DB.prepare(
    `SELECT
       (SELECT COUNT(*) FROM users) AS users,
       (SELECT COUNT(*) FROM alerts) AS alerts,
       (SELECT COUNT(*) FROM alerts WHERE enabled = 1) AS active_alerts,
       (SELECT COUNT(*) FROM push_subs) AS subs`,
  ).first<{ users: number; alerts: number; active_alerts: number; subs: number }>();

  const { results: recent } = await env.DB.prepare(
    `SELECT j.at, j.title, j.kind, j.slots, j.fresh, j.requests, j.detail, u.username
       FROM journal j LEFT JOIN users u ON u.id = j.user_id
      ORDER BY j.id DESC LIMIT 60`,
  ).all();

  const paused = guard?.paused_until && new Date(guard.paused_until) > new Date();
  return json({
    guard: {
      dayKey: guard?.day_key ?? '',
      requestsToday: guard?.requests_today ?? 0,
      maxPerDay: Number(env.MAX_REQUESTS_PER_DAY ?? 800) || 800,
      consecutiveBlocks: guard?.consecutive_blocks ?? 0,
      pausedUntil: paused ? guard?.paused_until : null,
      message: paused ? guard?.last_block_message : null,
    },
    counts,
    recent,
    config: {
      pushConfigured: Boolean(env.VAPID_PUBLIC_KEY && env.VAPID_PRIVATE_KEY),
      emailConfigured: mailerOf(env) !== null,
      bootstrapOpen: Boolean(env.ADMIN_BOOTSTRAP),
      tickBudget: Number(env.TICK_REQUEST_BUDGET ?? 42) || 42,
    },
  });
}

/** Lifts a rate-limit pause early, if the admin believes it was a blip. */
export async function clearPause(req: Request, env: Env): Promise<Response> {
  await requireAdmin(req, env);
  await env.DB.prepare(
    'UPDATE guard SET paused_until = NULL, last_block_message = NULL, consecutive_blocks = 0 WHERE id = 1',
  ).run();
  return json({ ok: true });
}

async function assertNotLastAdmin(env: Env, excludingId: string): Promise<void> {
  const row = await env.DB.prepare(
    'SELECT COUNT(*) AS n FROM users WHERE is_admin = 1 AND active = 1 AND id != ?',
  )
    .bind(excludingId)
    .first<{ n: number }>();
  if ((row?.n ?? 0) === 0) {
    throw badRequest("C'est le dernier administrateur actif : le supprimer fermerait l'administration.");
  }
}

function isEmail(s: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(s);
}

/**
 * Where our requests actually come from, and whether Doctolib answers them.
 *
 * Worth a dedicated route because the answer is invisible from a browser: the
 * page runs on your machine and your connection, the checks run on Cloudflare's
 * and theirs. A geo-block would look exactly like "the app is broken" from the
 * outside. This reports the egress IP, the country Cloudflare thinks it is in,
 * and the raw status of three Doctolib endpoints.
 *
 * Costs a handful of requests, so it is admin-only and never automatic.
 */
export async function diagnose(req: Request, env: Env): Promise<Response> {
  await requireAdmin(req, env);

  const headers = {
    'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
      '(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
  };

  // Cloudflare's own trace endpoint reports the address this Worker leaves
  // from, which is the number that decides whether Doctolib serves us.
  let egress: Record<string, string> = {};
  try {
    const res = await fetch('https://www.cloudflare.com/cdn-cgi/trace', {
      signal: AbortSignal.timeout(10_000),
    });
    for (const line of (await res.text()).split('\n')) {
      const [k, v] = line.split('=');
      if (k && v) egress[k] = v;
    }
  } catch (e) {
    egress = { error: String(e) };
  }


  // The two endpoints a real check actually spends its requests on, plus the
  // cheap ones. Probing only the cheap ones was how the first version of this
  // route reported "all clear" while the scheduler was being refused.
  const probes: Record<string, unknown> = {};

  probes['1. place_autocomplete (GET)'] = await probe(
    'https://www.doctolib.fr/patient_app/place_autocomplete.json?query=lyon',
    { headers },
  );

  probes['2. search page (GET html)'] = await probe(
    'https://www.doctolib.fr/dermatologue/lyon',
    { headers: { ...headers, Accept: 'text/html' } },
  );

  probes['3. autocomplete (POST)'] = await probe(
    'https://www.doctolib.fr/patient-health-search/api/v1/autocomplete',
    {
      method: 'POST',
      headers: { ...headers, 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify({ query: 'dermatologue' }),
    },
  );

  // The real speciality search. This is the request every speciality alert
  // makes first, with the place object scraped from the HTML page.
  probes['4. hcp/search (POST) <- real'] = await probe(
    'https://www.doctolib.fr/patient-health-search/api/v1/hcp/search?page=0',
    {
      method: 'POST',
      headers: { ...headers, 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify({
        keyword: 'dermatologue',
        location: {
          place: {
            id: 6903,
            name: 'Lyon',
            slug: 'lyon',
            country: 'fr',
            type: 'locality',
            gpsPoint: { lat: 45.764043, lng: 4.835659 },
            viewport: {
              northeast: { lat: 45.8084251, lng: 4.898393 },
              southwest: { lat: 45.707486, lng: 4.771849 },
            },
          },
        },
        filters: {},
      }),
    },
  );

  // The calendar endpoint, with deliberately meaningless ids. A 400 here is a
  // good result: it means Doctolib read our request and disliked the
  // parameters. Only a 403 or 429 means it refused to talk to us at all.
  const today = new Date().toISOString().slice(0, 10);
  probes['5. availabilities (GET) <- real'] = await probe(
    `https://www.doctolib.fr/availabilities.json?start_date=${today}` +
      '&visit_motive_ids=1&agenda_ids=1&insurance_sector=public' +
      '&destroy_temporary=true&limit=3',
    { headers },
  );

  // What the guard currently believes, so a pause can be read next to the
  // probes that would explain it. Note this whole route bypasses the guard on
  // purpose: a diagnostic that goes silent exactly when something is wrong is
  // worth nothing.
  const g = await env.DB.prepare(
    'SELECT consecutive_blocks, paused_until, last_block_message FROM guard WHERE id = 1',
  ).first<{
    consecutive_blocks: number;
    paused_until: string | null;
    last_block_message: string | null;
  }>();

  // The most recent failures the scheduler recorded, which name the alert and
  // carry Doctolib's own explanation.
  const { results: errors } = await env.DB.prepare(
    `SELECT at, title, detail FROM journal WHERE kind = 'error' ORDER BY id DESC LIMIT 5`,
  ).all();

  const refused = Object.entries(probes)
    .filter(([, p]) => (p as { status: number }).status === 403 || (p as { status: number }).status === 429)
    .map(([name]) => name);

  return json({
    egress: {
      ip: egress.ip ?? null,
      country: egress.loc ?? null,
      colo: egress.colo ?? null,
      error: egress.error ?? null,
    },
    guard: {
      consecutiveBlocks: g?.consecutive_blocks ?? 0,
      pausedUntil: g?.paused_until ?? null,
      lastBlockMessage: g?.last_block_message ?? null,
    },
    recentErrors: errors,
    probes,
    reading: refused.length > 0
      ? `Doctolib refuse : ${refused.join(', ')}`
      : egress.loc && egress.loc !== 'FR'
        ? `Aucun refus, mais nos requetes partent de ${egress.loc}.`
        : 'Aucun refus. Tous les endpoints repondent depuis la France.',
  });
}

async function probe(url: string, init: RequestInit): Promise<unknown> {
  const started = Date.now();
  try {
    const res = await fetch(url, { ...init, signal: AbortSignal.timeout(20_000) });
    const body = await res.text();
    return {
      status: res.status,
      ok: res.status === 200 || res.status === 206,
      ms: Date.now() - started,
      bytes: body.length,
      // Enough to tell a real answer from a DataDome challenge page.
      preview: body.slice(0, 200).replace(/\s+/g, ' '),
      server: res.headers.get('server'),
      cfMitigated: res.headers.get('cf-mitigated'),
    };
  } catch (e) {
    return { status: 0, ok: false, ms: Date.now() - started, error: String(e) };
  }
}
