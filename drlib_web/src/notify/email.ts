/**
 * Email alerts, through whichever provider is configured.
 *
 * Two are supported, and the difference between them is the whole reason there
 * are two. Resend verifies a *domain*: until you own one and add its DNS
 * records, it will only deliver to the address the Resend account was opened
 * with, which makes it useless for sending to anyone else. Brevo verifies a
 * single *sender address*: confirm a Gmail you already own and you can write to
 * anybody, no domain required. For a handful of users that is the difference
 * between working and not.
 *
 * Whichever key is present wins; Brevo is tried first because it is the one
 * that works without a domain.
 *
 * One message per user per cron tick, not one per alert and certainly not one
 * per slot: a busy morning would otherwise arrive as a dozen separate mails
 * saying almost the same thing. The digest groups by alert and keeps the three
 * states the app itself uses, so the mail reads like the screen.
 *
 * Optional throughout: with no RESEND_API_KEY the whole path is a no-op and
 * push keeps working, so a deployment is never blocked on a sender domain.
 */

import * as tz from '../lib/tz';
import type { SlotHit } from '../doctolib/models';

export interface MailResult {
  ok: boolean;
  error?: string;
  /**
   * The provider's own id for the message. Worth carrying back: "accepted by
   * the API" and "arrived in the inbox" are different events, and this is the
   * handle you search their delivery log with when only the first happened.
   */
  messageId?: string;
}

/** One alert's contribution to the digest. */
export interface AlertDigest {
  title: string;
  /** Never announced before. Highlighted, as in the app. */
  fresh: SlotHit[];
  /** Still open, already announced on an earlier check. */
  known: SlotHit[];
  /** Matching, but muted by the user. Greyed and struck through. */
  ignored: SlotHit[];
}

export async function sendDigestEmail(opts: {
  cfg: MailerConfig;
  to: string;
  digests: AlertDigest[];
  appUrl: string;
}): Promise<MailResult> {
  const freshTotal = opts.digests.reduce((n, d) => n + d.fresh.length, 0);
  if (freshTotal === 0) return { ok: true };

  const subject =
    opts.digests.length === 1
      ? freshTotal === 1
        ? `1 creneau — ${opts.digests[0].title}`
        : `${freshTotal} creneaux — ${opts.digests[0].title}`
      : `${freshTotal} creneaux sur ${opts.digests.length} alertes`;

  return send({
    cfg: opts.cfg,
    to: opts.to,
    subject,
    html: digestHtml(opts.digests, opts.appUrl, freshTotal),
    text: digestText(opts.digests, opts.appUrl, freshTotal),
  });
}

export async function sendPlainEmail(opts: {
  cfg: MailerConfig;
  to: string;
  subject: string;
  text: string;
}): Promise<MailResult> {
  return send({
    ...opts,
    html: `<pre style="font:14px/1.6 ui-monospace,monospace;white-space:pre-wrap">${escapeHtml(
      opts.text,
    )}</pre>`,
  });
}

export interface MailerConfig {
  resendKey?: string;
  brevoKey?: string;
  from: string;
}

/** Parses `Name <addr@host>` or a bare address. Brevo wants them separate. */
function parseFrom(from: string): { name: string; email: string } {
  const m = /^\s*(.*?)\s*<([^>]+)>\s*$/.exec(from);
  if (m) return { name: m[1].replace(/^"|"$/g, '') || 'Alertes RDV', email: m[2].trim() };
  return { name: 'Alertes RDV', email: from.trim() };
}

export function mailerName(cfg: MailerConfig): string | null {
  if (cfg.brevoKey) return 'Brevo';
  if (cfg.resendKey) return 'Resend';
  return null;
}

async function send(opts: {
  cfg: MailerConfig;
  to: string;
  subject: string;
  html: string;
  text: string;
}): Promise<MailResult> {
  const { cfg } = opts;
  if (cfg.brevoKey) return sendViaBrevo(opts.cfg.brevoKey!, opts);
  if (cfg.resendKey) return sendViaResend(opts.cfg.resendKey!, opts);
  return { ok: false, error: 'Aucun fournisseur e-mail configure.' };
}

async function sendViaBrevo(
  apiKey: string,
  opts: { cfg: MailerConfig; to: string; subject: string; html: string; text: string },
): Promise<MailResult> {
  const sender = parseFrom(opts.cfg.from);
  try {
    const res = await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: {
        'api-key': apiKey,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({
        sender,
        to: [{ email: opts.to }],
        subject: opts.subject,
        htmlContent: opts.html,
        textContent: opts.text,
      }),
      signal: AbortSignal.timeout(15_000),
    });
    if (res.ok) {
      const body = (await res.json().catch(() => ({}))) as { messageId?: string };
      return { ok: true, messageId: body.messageId };
    }
    return { ok: false, error: `Brevo ${res.status} ${(await res.text()).slice(0, 300)}` };
  } catch (e) {
    return { ok: false, error: `Brevo: ${e}` };
  }
}

async function sendViaResend(
  apiKey: string,
  opts: { cfg: MailerConfig; to: string; subject: string; html: string; text: string },
): Promise<MailResult> {
  try {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: opts.cfg.from,
        to: [opts.to],
        subject: opts.subject,
        html: opts.html,
        text: opts.text,
      }),
      signal: AbortSignal.timeout(15_000),
    });
    if (res.ok) {
      const body = (await res.json().catch(() => ({}))) as { id?: string };
      return { ok: true, messageId: body.id };
    }
    return { ok: false, error: `Resend ${res.status} ${(await res.text()).slice(0, 300)}` };
  } catch (e) {
    return { ok: false, error: `Resend: ${e}` };
  }
}

// ---------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------

/**
 * Colours are inline and literal rather than CSS variables: mail clients strip
 * <style> blocks, ignore custom properties, and Gmail rewrites class names.
 * Everything here has to survive being pasted into a table cell.
 */
const RED = '#c0392b';
const RED_BG = '#fdecea';
const GREY = '#9aa1af';
const INK = '#16181d';
const MUTED = '#6b7280';
const ACCENT = '#0f7c6c';
const BORDER = '#e3e4e8';

function slotRow(h: SlotHit, kind: 'fresh' | 'known' | 'ignored'): string {
  const when = escapeHtml(tz.humanSlot(new Date(h.when)));
  const who = escapeHtml(h.doctorName) + (h.city ? ` — ${escapeHtml(h.city)}` : '');

  if (kind === 'ignored') {
    return `
      <tr><td style="padding:8px 0;border-bottom:1px solid ${BORDER}">
        <div style="font:14px/1.4 system-ui,sans-serif;color:${GREY};text-decoration:line-through">
          ${when}
        </div>
        <div style="font:13px/1.4 system-ui,sans-serif;color:${GREY}">${who} · masque</div>
      </td></tr>`;
  }

  const isFresh = kind === 'fresh';
  return `
    <tr><td style="padding:12px ${isFresh ? '12px' : '0'};border-bottom:1px solid ${BORDER};${
      isFresh ? `background:${RED_BG};border-left:3px solid ${RED};border-radius:4px` : ''
    }">
      <div style="font:600 15px/1.4 system-ui,sans-serif;color:${isFresh ? RED : INK}">
        ${isFresh ? '&#9679; ' : ''}${when}
      </div>
      <div style="font:14px/1.5 system-ui,sans-serif;color:${MUTED};margin-top:2px">
        ${who}${h.telehealth ? ' · video' : ''}
      </div>
      ${h.motive ? `<div style="font:13px/1.5 system-ui,sans-serif;color:${MUTED}">${escapeHtml(h.motive)}</div>` : ''}
      <a href="${escapeAttr(h.bookingUrl)}"
         style="display:inline-block;margin-top:8px;padding:8px 14px;border-radius:8px;
                background:${isFresh ? RED : ACCENT};color:#fff;font:600 13px system-ui,sans-serif;
                text-decoration:none">Reserver sur Doctolib</a>
    </td></tr>`;
}

function digestHtml(digests: AlertDigest[], appUrl: string, freshTotal: number): string {
  const CAP = 12;

  const blocks = digests.map((d) => {
    const parts: string[] = [];

    if (d.fresh.length > 0) {
      parts.push(
        `<tr><td style="padding:14px 0 4px;font:700 12px system-ui,sans-serif;
           letter-spacing:.06em;text-transform:uppercase;color:${RED}">
           Nouveau (${d.fresh.length})</td></tr>`,
        ...d.fresh.slice(0, CAP).map((h) => slotRow(h, 'fresh')),
      );
      if (d.fresh.length > CAP) {
        parts.push(more(d.fresh.length - CAP));
      }
    }

    if (d.known.length > 0) {
      parts.push(
        `<tr><td style="padding:16px 0 4px;font:700 12px system-ui,sans-serif;
           letter-spacing:.06em;text-transform:uppercase;color:${MUTED}">
           Deja signale (${d.known.length})</td></tr>`,
        ...d.known.slice(0, CAP).map((h) => slotRow(h, 'known')),
      );
      if (d.known.length > CAP) parts.push(more(d.known.length - CAP));
    }

    if (d.ignored.length > 0) {
      parts.push(
        `<tr><td style="padding:16px 0 4px;font:700 12px system-ui,sans-serif;
           letter-spacing:.06em;text-transform:uppercase;color:${GREY}">
           Masque par vous (${d.ignored.length})</td></tr>`,
        ...d.ignored.slice(0, 6).map((h) => slotRow(h, 'ignored')),
      );
      if (d.ignored.length > 6) parts.push(more(d.ignored.length - 6));
    }

    return `
      <tr><td style="padding-top:22px">
        <div style="font:700 17px/1.3 system-ui,sans-serif;color:${INK}">${escapeHtml(d.title)}</div>
      </td></tr>
      ${parts.join('')}`;
  });

  return `<!doctype html><html lang="fr"><body style="margin:0;background:#f4f5f7;padding:24px">
  <table role="presentation" cellpadding="0" cellspacing="0"
         style="max-width:600px;margin:0 auto;background:#fff;border-radius:14px;padding:28px;width:100%">
    <tr><td>
      <div style="font:700 19px/1.3 system-ui,sans-serif;color:${INK}">
        ${freshTotal === 1 ? '1 nouveau creneau' : `${freshTotal} nouveaux creneaux`}
      </div>
      <div style="font:14px/1.5 system-ui,sans-serif;color:${MUTED};margin-top:4px">
        ${digests.length === 1 ? 'Sur votre alerte' : `Sur ${digests.length} de vos alertes`}
      </div>
    </td></tr>
    ${blocks.join('')}
    <tr><td style="padding-top:24px;border-top:1px solid ${BORDER}">
      <a href="${escapeAttr(appUrl)}"
         style="font:600 14px system-ui,sans-serif;color:${ACCENT};text-decoration:none">
        Ouvrir toutes mes alertes &rarr;
      </a>
      <p style="font:12px/1.6 system-ui,sans-serif;color:#999;margin:16px 0 0">
        Les creneaux partent vite. Ce message dit seulement qu'un creneau etait
        libre au moment de la verification.
      </p>
    </td></tr>
  </table></body></html>`;
}

function more(n: number): string {
  return `<tr><td style="padding:8px 0;font:13px system-ui,sans-serif;color:${MUTED}">
    + ${n} autre(s)</td></tr>`;
}

function digestText(digests: AlertDigest[], appUrl: string, freshTotal: number): string {
  const lines: string[] = [
    freshTotal === 1 ? '1 nouveau creneau' : `${freshTotal} nouveaux creneaux`,
    '',
  ];

  for (const d of digests) {
    lines.push(`== ${d.title} ==`, '');
    const section = (label: string, hits: SlotHit[], mark: string, cap: number) => {
      if (hits.length === 0) return;
      lines.push(`${label} (${hits.length})`);
      for (const h of hits.slice(0, cap)) {
        lines.push(
          `${mark} ${tz.humanSlot(new Date(h.when))}`,
          `   ${h.doctorName}${h.city ? `, ${h.city}` : ''}`,
          `   ${h.bookingUrl}`,
        );
      }
      if (hits.length > cap) lines.push(`   + ${hits.length - cap} autre(s)`);
      lines.push('');
    };
    section('NOUVEAU', d.fresh, '*', 12);
    section('Deja signale', d.known, '-', 12);
    section('Masque par vous', d.ignored, 'x', 6);
  }

  lines.push(`Toutes vos alertes : ${appUrl}`, '');
  lines.push(
    "Les creneaux partent vite : ce message dit seulement qu'un creneau etait",
    'libre au moment de la verification.',
  );
  return lines.join('\n');
}

function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!,
  );
}

function escapeAttr(s: string): string {
  // Only http(s) links ever reach an href here; anything else is dropped rather
  // than escaped, so a malformed bookingUrl cannot become a javascript: link in
  // someone's mail client.
  return /^https?:\/\//i.test(s) ? escapeHtml(s) : '#';
}
