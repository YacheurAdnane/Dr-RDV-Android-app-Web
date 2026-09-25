/**
 * Worker entry point.
 *
 * `fetch` serves the PWA and its API; `scheduled` is the part that makes the
 * whole thing possible — the browser cannot poll Doctolib while it is closed,
 * so the cron does it and pushes the result.
 */

import { Env, errorResponse, HttpError, json, notFound } from './lib/http';
import { assertSameOrigin } from './lib/session';
import { runTick } from './scheduler';

import * as admin from './routes/admin';
import * as alerts from './routes/alerts';
import * as auth from './routes/auth';
import * as push from './routes/push';
import * as search from './routes/search';

type Handler = (req: Request, env: Env, ...params: string[]) => Promise<Response>;

interface Route {
  method: string;
  pattern: RegExp;
  handler: Handler;
}

const r = (method: string, path: string, handler: Handler): Route => ({
  method,
  // `:id` becomes a capture group; everything else is literal.
  pattern: new RegExp(`^${path.replace(/:[a-z]+/g, '([^/]+)')}$`),
  handler,
});

const ROUTES: Route[] = [
  // Session
  r('POST', '/api/auth/login', auth.login),
  r('POST', '/api/auth/logout', auth.logout),
  r('GET', '/api/auth/me', auth.me),
  r('POST', '/api/auth/password', auth.changePassword),
  r('POST', '/api/auth/email-alerts', auth.setEmailAlerts),
  r('POST', '/api/auth/bootstrap', auth.bootstrap),

  // The user's own alerts
  r('GET', '/api/alerts', alerts.listAlerts),
  r('POST', '/api/alerts', alerts.createAlert),
  r('GET', '/api/alerts/:id', alerts.getAlert),
  r('PUT', '/api/alerts/:id', alerts.updateAlert),
  r('DELETE', '/api/alerts/:id', alerts.deleteAlert),
  r('POST', '/api/alerts/:id/check', alerts.checkNow),
  r('POST', '/api/alerts/:id/snooze', alerts.snoozeAlert),
  r('POST', '/api/alerts/:id/ignore', alerts.ignore),
  r('GET', '/api/journal', alerts.journal),

  // Doctolib and geocoding lookups, proxied (no CORS on doctolib.fr)
  r('GET', '/api/search/autocomplete', search.autocomplete),
  r('GET', '/api/search/places', search.places),
  r('GET', '/api/search/resolve-place', search.resolvePlace),
  r('GET', '/api/search/motives', search.motives),
  r('GET', '/api/search/resolve-zone', search.resolveZone),
  r('GET', '/api/geo/address', search.geoAddress),
  r('GET', '/api/geo/reverse', search.geoReverse),
  r('GET', '/api/geo/communes', search.geoCommunes),

  // Push
  r('POST', '/api/push/subscribe', push.subscribe),
  r('POST', '/api/push/unsubscribe', push.unsubscribe),
  r('GET', '/api/push/subscriptions', push.listSubs),
  r('POST', '/api/push/test', push.test),
  r('POST', '/api/email/test', push.testEmail),

  // Administration
  r('GET', '/api/admin/users', admin.listUsers),
  r('POST', '/api/admin/users', admin.createUser),
  r('PATCH', '/api/admin/users/:id', admin.updateUser),
  r('POST', '/api/admin/users/:id/password', admin.resetPassword),
  r('DELETE', '/api/admin/users/:id', admin.deleteUser),
  r('GET', '/api/admin/alerts', admin.listAllAlerts),
  r('DELETE', '/api/admin/alerts/:id', admin.deleteAnyAlert),
  r('PATCH', '/api/admin/alerts/:id', admin.setAlertEnabled),
  r('GET', '/api/admin/status', admin.status),
  r('GET', '/api/admin/diagnose', admin.diagnose),
  r('POST', '/api/admin/clear-pause', admin.clearPause),
];

export default {
  async fetch(req: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(req.url);

    if (!url.pathname.startsWith('/api/')) {
      // Static assets: the PWA, the service worker, the manifest.
      return env.ASSETS.fetch(req);
    }

    try {
      assertSameOrigin(req);

      // Every route whose path matches, not just the first. Several verbs share
      // a path (GET and POST on /api/alerts, PATCH and DELETE on
      // /api/admin/users/:id), so bailing out at the first path hit would
      // answer 405 to half the API.
      const allowed: string[] = [];
      for (const route of ROUTES) {
        const m = route.pattern.exec(url.pathname);
        if (!m) continue;
        if (route.method === req.method) {
          return await route.handler(req, env, ...m.slice(1).map(decodeURIComponent));
        }
        allowed.push(route.method);
      }

      if (allowed.length > 0) {
        return json({ error: 'Methode non autorisee.' }, 405, { Allow: allowed.join(', ') });
      }
      throw notFound('Route inconnue.');
    } catch (e) {
      return errorResponse(e);
    }
  },

  async scheduled(event: ScheduledEvent, env: Env, ctx: ExecutionContext): Promise<void> {
    // Notifications need an absolute URL to link back to, and a cron event
    // carries no request to take an origin from. Set APP_URL in wrangler.toml
    // after the first deploy.
    const appUrl = env.APP_URL || 'https://drlib.workers.dev';
    ctx.waitUntil(
      runTick(env, appUrl)
        .then((report) => {
          console.log('tick', JSON.stringify(report));
        })
        .catch((e) => {
          console.error('tick failed', e);
        }),
    );
  },
};

export { HttpError };
