export interface Env {
  DB: D1Database;
  ASSETS: Fetcher;
  /** The deployed origin. The cron has no request to derive one from. */
  APP_URL: string;
  CONTACT_EMAIL: string;
  MAIL_FROM: string;
  MAX_REQUESTS_PER_DAY: string;
  TICK_REQUEST_BUDGET: string;
  /** Pause a user's alerts after this many days without opening the app. 0 = never. */
  AUTO_PAUSE_DAYS?: string;
  VAPID_PUBLIC_KEY?: string;
  VAPID_PRIVATE_KEY?: string;
  /**
   * Email providers. Brevo wins when both are present: it verifies a single
   * sender address, so it works without owning a domain.
   */
  BREVO_API_KEY?: string;
  RESEND_API_KEY?: string;
  ADMIN_BOOTSTRAP?: string;
}

const SECURITY_HEADERS: Record<string, string> = {
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'Referrer-Policy': 'same-origin',
};

/** The mail configuration, or null when no provider is set up. */
export function mailerOf(env: Env): { resendKey?: string; brevoKey?: string; from: string } | null {
  if (!env.BREVO_API_KEY && !env.RESEND_API_KEY) return null;
  return {
    brevoKey: env.BREVO_API_KEY,
    resendKey: env.RESEND_API_KEY,
    from: env.MAIL_FROM,
  };
}

export function json(data: unknown, status = 200, headers: HeadersInit = {}): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
      ...SECURITY_HEADERS,
      ...headers,
    },
  });
}

/** A failure the client is meant to show the user as-is. */
export class HttpError extends Error {
  constructor(
    readonly status: number,
    message: string,
    readonly code?: string,
  ) {
    super(message);
  }
}

export const badRequest = (m: string) => new HttpError(400, m, 'bad_request');
export const unauthorized = (m = 'Connexion requise.') => new HttpError(401, m, 'unauthorized');
export const forbidden = (m = 'Acces refuse.') => new HttpError(403, m, 'forbidden');
export const notFound = (m = 'Introuvable.') => new HttpError(404, m, 'not_found');

export function errorResponse(e: unknown): Response {
  if (e instanceof HttpError) {
    return json({ error: e.message, code: e.code }, e.status);
  }
  console.error('unhandled', e);
  return json({ error: 'Erreur interne du serveur.', code: 'internal' }, 500);
}

export async function readJson<T>(req: Request): Promise<T> {
  const ct = req.headers.get('Content-Type') ?? '';
  if (!ct.includes('application/json')) throw badRequest('JSON attendu.');
  try {
    return (await req.json()) as T;
  } catch {
    throw badRequest('Corps de requete illisible.');
  }
}

/** Reads a field that must be a non-empty string. */
export function str(v: unknown, field: string, max = 200): string {
  if (typeof v !== 'string' || v.trim() === '') throw badRequest(`Champ « ${field} » manquant.`);
  const s = v.trim();
  if (s.length > max) throw badRequest(`Champ « ${field} » trop long.`);
  return s;
}

export function optStr(v: unknown, max = 200): string {
  if (typeof v !== 'string') return '';
  return v.trim().slice(0, max);
}

export function bool(v: unknown, fallback = false): boolean {
  return typeof v === 'boolean' ? v : fallback;
}

export function int(v: unknown, fallback: number, min: number, max: number): number {
  const n = typeof v === 'number' ? v : Number(v);
  if (!Number.isFinite(n)) return fallback;
  return Math.min(max, Math.max(min, Math.round(n)));
}
