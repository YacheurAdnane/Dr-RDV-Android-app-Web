import { newId } from '../lib/crypto';
import { badRequest, Env, json, mailerOf, readJson, str } from '../lib/http';
import { requireUser } from '../lib/session';
import { mailerName, sendDigestEmail } from '../notify/email';
import { sendPush } from '../notify/webpush';

/** One entry per browser, so a user can have the phone and the laptop both. */
const MAX_SUBS_PER_USER = 8;

export async function subscribe(req: Request, env: Env): Promise<Response> {
  const user = await requireUser(req, env);
  if (!env.VAPID_PUBLIC_KEY || !env.VAPID_PRIVATE_KEY) {
    throw badRequest("Les notifications ne sont pas configurees sur ce serveur (cles VAPID absentes).");
  }

  const body = await readJson<{
    endpoint?: string;
    keys?: { p256dh?: string; auth?: string };
    label?: string;
  }>(req);

  const endpoint = str(body.endpoint, 'endpoint', 600);
  const p256dh = str(body.keys?.p256dh, 'keys.p256dh', 200);
  const auth = str(body.keys?.auth, 'keys.auth', 100);
  if (!/^https:\/\//.test(endpoint)) throw badRequest('Endpoint invalide.');

  // Re-subscribing from the same browser replaces the old row rather than
  // piling up: the endpoint is unique, and the keys rotate when it changes.
  const existing = await env.DB.prepare('SELECT id FROM push_subs WHERE endpoint = ?')
    .bind(endpoint)
    .first<{ id: string }>();

  if (existing) {
    await env.DB.prepare(
      'UPDATE push_subs SET user_id = ?, p256dh = ?, auth = ?, fail_count = 0 WHERE id = ?',
    )
      .bind(user.id, p256dh, auth, existing.id)
      .run();
    return json({ ok: true, id: existing.id });
  }

  const count = await env.DB.prepare('SELECT COUNT(*) AS n FROM push_subs WHERE user_id = ?')
    .bind(user.id)
    .first<{ n: number }>();
  if ((count?.n ?? 0) >= MAX_SUBS_PER_USER) {
    // Drop the least recently successful one rather than refusing the new
    // device, which is almost always the one the user is holding.
    await env.DB.prepare(
      `DELETE FROM push_subs WHERE id = (
         SELECT id FROM push_subs WHERE user_id = ?
          ORDER BY COALESCE(last_ok_at, created_at) ASC LIMIT 1)`,
    )
      .bind(user.id)
      .run();
  }

  const id = newId('p_');
  await env.DB.prepare(
    'INSERT INTO push_subs (id, user_id, endpoint, p256dh, auth, label, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
  )
    .bind(id, user.id, endpoint, p256dh, auth, (body.label ?? '').slice(0, 80), new Date().toISOString())
    .run();

  return json({ ok: true, id }, 201);
}

export async function unsubscribe(req: Request, env: Env): Promise<Response> {
  const user = await requireUser(req, env);
  const body = await readJson<{ endpoint?: string }>(req);
  const endpoint = str(body.endpoint, 'endpoint', 600);
  await env.DB.prepare('DELETE FROM push_subs WHERE endpoint = ? AND user_id = ?')
    .bind(endpoint, user.id)
    .run();
  return json({ ok: true });
}

export async function listSubs(req: Request, env: Env): Promise<Response> {
  const user = await requireUser(req, env);
  const { results } = await env.DB.prepare(
    'SELECT id, label, created_at, last_ok_at, fail_count FROM push_subs WHERE user_id = ?',
  )
    .bind(user.id)
    .all();
  return json({ subscriptions: results });
}

/**
 * Sends a test notification to every registered browser.
 *
 * Worth its own button: push has four independent ways to fail silently (no
 * permission, no service worker, wrong VAPID key, dead endpoint) and this is
 * the only way a user finds out which one before a real slot goes past.
 */
export async function test(req: Request, env: Env): Promise<Response> {
  const user = await requireUser(req, env);
  if (!env.VAPID_PUBLIC_KEY || !env.VAPID_PRIVATE_KEY) {
    throw badRequest('Cles VAPID absentes sur le serveur.');
  }

  const { results: subs } = await env.DB.prepare(
    'SELECT id, endpoint, p256dh, auth FROM push_subs WHERE user_id = ?',
  )
    .bind(user.id)
    .all<{ id: string; endpoint: string; p256dh: string; auth: string }>();

  if (subs.length === 0) {
    return json({ sent: 0, failed: 0, message: "Aucun navigateur n'est abonne." });
  }

  const appUrl = new URL(req.url).origin;
  let sent = 0;
  const failures: string[] = [];

  for (const sub of subs) {
    const res = await sendPush(
      sub,
      {
        title: 'Notification de test',
        body: 'Si vous lisez ceci, les alertes fonctionneront sur cet appareil.',
        url: appUrl,
        appUrl,
        style: 'normal',
        tag: 'test',
        count: 1,
      },
      {
        publicKey: env.VAPID_PUBLIC_KEY,
        privateKey: env.VAPID_PRIVATE_KEY,
        subject: env.CONTACT_EMAIL || 'mailto:admin@example.com',
      },
    );
    if (res.ok) {
      sent++;
      await env.DB.prepare('UPDATE push_subs SET last_ok_at = ?, fail_count = 0 WHERE id = ?')
        .bind(new Date().toISOString(), sub.id)
        .run();
    } else {
      failures.push(`${res.status} ${res.error ?? ''}`.trim());
      if (res.gone) {
        await env.DB.prepare('DELETE FROM push_subs WHERE id = ?').bind(sub.id).run();
      }
    }
  }

  return json({ sent, failed: failures.length, failures });
}

/**
 * Sends a sample digest to the user's own address.
 *
 * Worth its own button for the same reason the push test is: email has several
 * independent ways to fail (no API key, no address on the account, a sender
 * domain Resend will not deliver from) and waiting for a real slot to discover
 * which one is a bad way to spend an evening. Resend's refusal is passed back
 * verbatim, because its messages are specific and actually useful.
 */
export async function testEmail(req: Request, env: Env): Promise<Response> {
  const user = await requireUser(req, env);

  const cfg = mailerOf(env);
  if (!cfg) {
    throw badRequest(
      "Aucun fournisseur e-mail configure. Ajoutez BREVO_API_KEY (recommande, pas besoin " +
        'de domaine) ou RESEND_API_KEY dans les variables du Worker.',
    );
  }
  if (!user.email) {
    throw badRequest(
      "Aucune adresse enregistree sur votre compte. L'administrateur doit l'ajouter.",
    );
  }
  if (!user.email_alerts) {
    throw badRequest("Les e-mails sont desactives pour votre compte par l'administrateur.");
  }

  const appUrl = new URL(req.url).origin;
  const now = Date.now();
  // Sample slots rather than real ones: the point is to prove delivery and let
  // the user see the three colours, without spending a Doctolib request.
  const slot = (hoursAhead: number, name: string, city: string, motive: string) => ({
    doctorKey: `demo-${name}`,
    doctorName: name,
    city,
    address: '',
    motive,
    bookingUrl: 'https://www.doctolib.fr/',
    when: new Date(now + hoursAhead * 3_600_000).toISOString(),
    speciality: 'Exemple',
    telehealth: false,
    lat: null,
    lng: null,
    distanceKm: null,
  });

  const res = await sendDigestEmail({
    cfg,
    to: user.email,
    appUrl,
    digests: [
      {
        title: 'Exemple — ceci est un test',
        fresh: [
          slot(26, 'Dr Exemple Un', 'Lyon', 'Premiere consultation'),
          slot(31, 'Dr Exemple Deux', 'Villeurbanne', 'Controle'),
        ],
        known: [slot(50, 'Dr Exemple Un', 'Lyon', 'Premiere consultation')],
        ignored: [slot(74, 'Dr Exemple Trois', 'Bron', 'Teleconsultation')],
      },
    ],
  });

  if (!res.ok) {
    return json(
      {
        ok: false,
        to: user.email,
        from: env.MAIL_FROM,
        provider: mailerName(cfg),
        error: res.error,
        // The two failures that are impossible to diagnose from the raw error.
        hint: emailHint(res.error ?? '', cfg.brevoKey),
      },
      502,
    );
  }

  return json({
    ok: true,
    to: user.email,
    from: env.MAIL_FROM,
    provider: mailerName(cfg),
    messageId: res.messageId ?? null,
    note: freeMailWarning(env.MAIL_FROM),
  });
}

/**
 * Turns a provider's rejection into the thing the user should actually do.
 *
 * Both of these read as generic validation errors and give no hint that the
 * fix is a configuration change somewhere else entirely.
 */
function emailHint(error: string, brevoKey?: string): string | undefined {
  // Brevo hands out two kinds of credential on adjacent tabs of the same page,
  // and only one of them works with the REST API. Pasting the wrong one comes
  // back as a bare 401, which says nothing about which tab to go back to.
  if (brevoKey && !brevoKey.startsWith('xkeysib-')) {
    const what = brevoKey.startsWith('xsmtpsib-')
      ? 'Cette cle est une cle SMTP, pas une cle API. '
      : 'Cette cle ne ressemble pas a une cle API Brevo (elles commencent par xkeysib-). ';
    return (
      what +
      'Dans Brevo, ouvrez SMTP & API > onglet API Keys (pas SMTP), generez une cle, ' +
      'et remplacez BREVO_API_KEY par celle-la.'
    );
  }
  if (/Resend/.test(error) && /testing emails|onboarding@resend\.dev|verify a domain/i.test(error)) {
    return (
      "Resend n'accepte d'ecrire a quelqu'un d'autre que vous qu'avec un domaine verifie. " +
      "Sans domaine, passez a Brevo : il ne verifie qu'une adresse expediteur. " +
      'Creez un compte sur brevo.com, validez votre adresse dans Senders & IP > Senders, ' +
      'puis ajoutez BREVO_API_KEY dans les variables du Worker. Brevo est prioritaire sur Resend.'
    );
  }
  if (/Brevo/.test(error) && /sender|not valid|unauthorized/i.test(error)) {
    return (
      "L'adresse expediteur de MAIL_FROM n'est pas validee chez Brevo. " +
      'Ouvrez Brevo > Senders, Domains & Dedicated IPs > Senders, ajoutez cette adresse, ' +
      'puis cliquez le lien de confirmation recu par e-mail.'
    );
  }
  return undefined;
}

/**
 * Warns when MAIL_FROM sits on a free mail provider.
 *
 * Gmail, Outlook and Yahoo publish DMARC policies that forbid third parties
 * sending as them, so a relay rewrites the From to its own domain rather than
 * have the message bounce. The mail still arrives, but it arrives from a
 * stranger's domain, which is both confusing and worse for spam scoring. The
 * delivery log is the only place this is visible, so it is said out loud here.
 */
function freeMailWarning(from: string): string | undefined {
  const domain = (/<([^>]+)>|(\S+@\S+)/.exec(from)?.[1] ?? from).split('@')[1]?.toLowerCase();
  const free = ['gmail.com', 'googlemail.com', 'outlook.com', 'hotmail.com', 'live.com', 'yahoo.com', 'yahoo.fr', 'free.fr', 'orange.fr', 'laposte.net'];
  if (!domain || !free.includes(domain)) return undefined;
  return (
    `L'expediteur est une adresse ${domain}, que votre fournisseur n'a pas le droit ` +
    "d'utiliser telle quelle (politique DMARC). Il la remplace par un domaine a lui, " +
    "ce qui marche mais augmente le risque de spam. Pour un vrai expediteur, il faut " +
    'un domaine a vous, verifie chez le fournisseur.'
  );
}
