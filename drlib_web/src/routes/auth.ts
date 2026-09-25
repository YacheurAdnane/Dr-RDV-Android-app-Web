import { generatePassword, hashPassword, newId, PW_ITERATIONS, verifyPassword } from '../lib/crypto';
import { badRequest, Env, HttpError, json, mailerOf, readJson, str, unauthorized } from '../lib/http';
import {
  clearCookie,
  createSession,
  currentSession,
  destroyAllSessions,
  destroySession,
  requireUser,
} from '../lib/session';

/** Lock the account after this many wrong passwords in a row. */
const MAX_ATTEMPTS = 8;
const LOCK_MINUTES = 15;

interface UserAuthRow {
  id: string;
  username: string;
  email: string;
  pw_hash: string;
  pw_salt: string;
  pw_iter: number;
  is_admin: number;
  email_alerts: number;
  active: number;
  must_change: number;
  failed_count: number;
  locked_until: string | null;
}

export async function login(req: Request, env: Env): Promise<Response> {
  const body = await readJson<{ username?: string; password?: string }>(req);
  const username = str(body.username, 'identifiant', 64).toLowerCase();
  const password = str(body.password, 'mot de passe', 200);

  const row = await env.DB.prepare(
    `SELECT id, username, email, pw_hash, pw_salt, pw_iter, is_admin, email_alerts,
            active, must_change, failed_count, locked_until
       FROM users WHERE username = ?`,
  )
    .bind(username)
    .first<UserAuthRow>();

  // Same message and roughly the same work whether or not the user exists, so
  // the form cannot be used to enumerate accounts.
  const generic = unauthorized('Identifiant ou mot de passe incorrect.');
  if (!row) {
    await hashPassword(password);
    throw generic;
  }
  if (!row.active) throw new HttpError(403, 'Ce compte a ete desactive.', 'inactive');

  if (row.locked_until && new Date(row.locked_until) > new Date()) {
    const mins = Math.ceil((new Date(row.locked_until).getTime() - Date.now()) / 60_000);
    throw new HttpError(429, `Trop de tentatives. Reessayez dans ${mins} min.`, 'locked');
  }

  const ok = await verifyPassword(password, row.pw_hash, row.pw_salt, row.pw_iter);
  if (!ok) {
    const failed = row.failed_count + 1;
    const lockUntil =
      failed >= MAX_ATTEMPTS ? new Date(Date.now() + LOCK_MINUTES * 60_000).toISOString() : null;
    await env.DB.prepare('UPDATE users SET failed_count = ?, locked_until = ? WHERE id = ?')
      .bind(failed >= MAX_ATTEMPTS ? 0 : failed, lockUntil, row.id)
      .run();
    throw generic;
  }

  await env.DB.prepare(
    'UPDATE users SET failed_count = 0, locked_until = NULL, last_login_at = ? WHERE id = ?',
  )
    .bind(new Date().toISOString(), row.id)
    .run();

  const { cookie } = await createSession(env, row.id, req.headers.get('User-Agent') ?? '');
  return json(
    { user: publicUser(row) },
    200,
    { 'Set-Cookie': cookie },
  );
}

export async function logout(req: Request, env: Env): Promise<Response> {
  const s = await currentSession(req, env);
  if (s) await destroySession(env, s.tokenHash);
  return json({ ok: true }, 200, { 'Set-Cookie': clearCookie() });
}

export async function me(req: Request, env: Env): Promise<Response> {
  const s = await currentSession(req, env);
  if (!s) return json({ user: null });
  return json({
    user: publicUser(s.user as unknown as UserAuthRow),
    vapidPublicKey: env.VAPID_PUBLIC_KEY ?? null,
    emailConfigured: mailerOf(env) !== null,
  });
}

/** The user changing their own password. Requires the current one. */
export async function changePassword(req: Request, env: Env): Promise<Response> {
  const user = await requireUser(req, env);
  const body = await readJson<{ current?: string; next?: string }>(req);
  const current = str(body.current, 'mot de passe actuel', 200);
  const next = str(body.next, 'nouveau mot de passe', 200);
  if (next.length < 10) throw badRequest('Le nouveau mot de passe doit faire au moins 10 caracteres.');

  const row = await env.DB.prepare(
    'SELECT pw_hash, pw_salt, pw_iter FROM users WHERE id = ?',
  )
    .bind(user.id)
    .first<{ pw_hash: string; pw_salt: string; pw_iter: number }>();
  if (!row) throw unauthorized();

  if (!(await verifyPassword(current, row.pw_hash, row.pw_salt, row.pw_iter))) {
    throw badRequest('Mot de passe actuel incorrect.');
  }

  const h = await hashPassword(next);
  await env.DB.prepare(
    'UPDATE users SET pw_hash = ?, pw_salt = ?, pw_iter = ?, must_change = 0 WHERE id = ?',
  )
    .bind(h.hash, h.salt, h.iterations, user.id)
    .run();

  // Every other device is logged out; this one gets a fresh cookie.
  await destroyAllSessions(env, user.id);
  const { cookie } = await createSession(env, user.id, req.headers.get('User-Agent') ?? '');
  return json({ ok: true }, 200, { 'Set-Cookie': cookie });
}

/** The user's own switch for email alerts. The address itself is admin-set. */
export async function setEmailAlerts(req: Request, env: Env): Promise<Response> {
  const user = await requireUser(req, env);
  const body = await readJson<{ enabled?: boolean }>(req);
  const enabled = body.enabled === true;
  if (enabled && !user.email) {
    throw badRequest("Aucune adresse e-mail n'est enregistree pour votre compte. Demandez a l'administrateur de l'ajouter.");
  }
  await env.DB.prepare('UPDATE users SET email_alerts = ? WHERE id = ?')
    .bind(enabled ? 1 : 0, user.id)
    .run();
  return json({ ok: true, enabled });
}

/**
 * Creates the very first administrator, once.
 *
 * Guarded by the ADMIN_BOOTSTRAP secret and refused as soon as any user
 * exists, so the route cannot be used twice or left open by accident.
 */
export async function bootstrap(req: Request, env: Env): Promise<Response> {
  if (!env.ADMIN_BOOTSTRAP) {
    throw new HttpError(404, 'Initialisation desactivee.', 'no_bootstrap');
  }
  const body = await readJson<{ token?: string; username?: string; password?: string }>(req);
  const token = str(body.token, 'token', 200);
  if (token !== env.ADMIN_BOOTSTRAP) throw new HttpError(403, 'Token invalide.', 'bad_token');

  const existing = await env.DB.prepare('SELECT COUNT(*) AS n FROM users').first<{ n: number }>();
  if ((existing?.n ?? 0) > 0) {
    throw new HttpError(409, 'Un compte existe deja. Supprimez ADMIN_BOOTSTRAP.', 'already');
  }

  const username = str(body.username, 'identifiant', 64).toLowerCase();
  const password = body.password && String(body.password).length >= 10
    ? String(body.password)
    : generatePassword();

  const h = await hashPassword(password);
  const id = newId('u_');
  await env.DB.prepare(
    `INSERT INTO users (id, username, email, pw_hash, pw_salt, pw_iter, is_admin, active, created_at)
     VALUES (?, ?, '', ?, ?, ?, 1, 1, ?)`,
  )
    .bind(id, username, h.hash, h.salt, h.iterations, new Date().toISOString())
    .run();

  return json({
    ok: true,
    username,
    // Shown once. If the caller supplied their own, this echoes it back so the
    // response is the same shape either way.
    password,
    note: "Notez ce mot de passe, puis supprimez le secret ADMIN_BOOTSTRAP avec : wrangler secret delete ADMIN_BOOTSTRAP",
  });
}

export function publicUser(row: Pick<UserAuthRow, 'id' | 'username' | 'email' | 'is_admin' | 'email_alerts' | 'must_change'>) {
  return {
    id: row.id,
    username: row.username,
    email: row.email,
    isAdmin: row.is_admin === 1,
    emailAlerts: row.email_alerts === 1,
    mustChange: row.must_change === 1,
  };
}

export { PW_ITERATIONS };
