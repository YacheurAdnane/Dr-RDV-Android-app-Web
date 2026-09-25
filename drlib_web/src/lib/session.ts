import { newSessionToken, sha256Hex } from './crypto';
import { Env, forbidden, unauthorized } from './http';

export const COOKIE = 'drlib_session';
const SESSION_DAYS = 30;

export interface User {
  id: string;
  username: string;
  email: string;
  is_admin: number;
  email_alerts: number;
  active: number;
  must_change: number;
}

export interface Session {
  user: User;
  tokenHash: string;
}

/** Resolves the session cookie, or null when there is no valid session. */
export async function currentSession(req: Request, env: Env): Promise<Session | null> {
  const token = readCookie(req, COOKIE);
  if (!token) return null;
  const tokenHash = await sha256Hex(token);

  const row = await env.DB.prepare(
    `SELECT u.id, u.username, u.email, u.is_admin, u.email_alerts, u.active, u.must_change,
            s.expires_at
       FROM sessions s JOIN users u ON u.id = s.user_id
      WHERE s.token_hash = ?`,
  )
    .bind(tokenHash)
    .first<User & { expires_at: string }>();

  if (!row) return null;
  if (new Date(row.expires_at) < new Date()) {
    await env.DB.prepare('DELETE FROM sessions WHERE token_hash = ?').bind(tokenHash).run();
    return null;
  }
  // A deactivated account keeps its rows but stops being able to act.
  if (!row.active) return null;

  return { user: row, tokenHash };
}

export async function requireUser(req: Request, env: Env): Promise<User> {
  const s = await currentSession(req, env);
  if (!s) throw unauthorized();
  return s.user;
}

export async function requireAdmin(req: Request, env: Env): Promise<User> {
  const u = await requireUser(req, env);
  if (!u.is_admin) throw forbidden("Reserve a l'administrateur.");
  return u;
}

export async function createSession(
  env: Env,
  userId: string,
  userAgent: string,
): Promise<{ token: string; cookie: string }> {
  const token = newSessionToken();
  const tokenHash = await sha256Hex(token);
  const now = new Date();
  const expires = new Date(now.getTime() + SESSION_DAYS * 86_400_000);

  await env.DB.prepare(
    'INSERT INTO sessions (token_hash, user_id, created_at, expires_at, user_agent) VALUES (?, ?, ?, ?, ?)',
  )
    .bind(tokenHash, userId, now.toISOString(), expires.toISOString(), userAgent.slice(0, 200))
    .run();

  // Housekeeping on the way past: expired rows would otherwise accumulate
  // forever, and there is no cron worth spending on it.
  await env.DB.prepare('DELETE FROM sessions WHERE expires_at < ?')
    .bind(now.toISOString())
    .run();

  return { token, cookie: sessionCookie(token, SESSION_DAYS * 86_400) };
}

export async function destroySession(env: Env, tokenHash: string): Promise<void> {
  await env.DB.prepare('DELETE FROM sessions WHERE token_hash = ?').bind(tokenHash).run();
}

/** Ends every session of a user — used when a password changes. */
export async function destroyAllSessions(env: Env, userId: string): Promise<void> {
  await env.DB.prepare('DELETE FROM sessions WHERE user_id = ?').bind(userId).run();
}

export function sessionCookie(token: string, maxAgeSeconds: number): string {
  return [
    `${COOKIE}=${token}`,
    'Path=/',
    'HttpOnly',
    'Secure',
    // Lax rather than Strict: the notification click opens the app from the
    // service worker, and Strict would drop the cookie on that navigation.
    'SameSite=Lax',
    `Max-Age=${maxAgeSeconds}`,
  ].join('; ');
}

export function clearCookie(): string {
  return sessionCookie('', 0);
}

function readCookie(req: Request, name: string): string | null {
  const header = req.headers.get('Cookie');
  if (!header) return null;
  for (const part of header.split(';')) {
    const eq = part.indexOf('=');
    if (eq < 0) continue;
    if (part.slice(0, eq).trim() === name) return part.slice(eq + 1).trim();
  }
  return null;
}

/**
 * Rejects a state-changing request that did not come from our own page.
 *
 * The session cookie is SameSite=Lax, which already stops cross-site POSTs
 * from carrying it, but Lax has enough edge cases across browser versions that
 * an explicit Origin check is worth the four lines.
 */
export function assertSameOrigin(req: Request): void {
  if (req.method === 'GET' || req.method === 'HEAD') return;
  const origin = req.headers.get('Origin');
  if (!origin) return; // Same-origin fetches may omit it entirely.
  if (origin !== new URL(req.url).origin) throw forbidden('Origine non autorisee.');
}
