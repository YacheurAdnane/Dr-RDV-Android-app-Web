/**
 * The cron tick.
 *
 * This is the part that makes the web version work at all: the browser cannot
 * poll while it is closed, so the polling lives here and the browser only ever
 * receives the result.
 *
 * Three budgets bound a tick, and all three are real:
 *
 *  - Cloudflare's free plan allows 50 outbound subrequests per invocation, so
 *    the tick stops handing out work before it reaches TICK_REQUEST_BUDGET.
 *  - The deployment-wide daily ceiling on Doctolib requests.
 *  - The rate guard's retreat after a 403 or 429.
 *
 * Alerts are not all checked on the same tick. Each carries its own
 * `next_check_at`, so a tick picks up only what is due, and the traffic is a
 * trickle rather than a burst every quarter of an hour. That is better for the
 * subrequest ceiling and much better for not looking like a scraper.
 */

import { BudgetExhausted, DoctolibApi } from './doctolib/api';
import { breathe, estimateRequests, runAlert } from './doctolib/engine';
import {
  isQuietNow, isSilent, isSnoozed, isIgnored, slotId, SlotHit, WatchConfig,
} from './doctolib/models';
import { RateGuard } from './doctolib/rate-guard';
import { Env, mailerOf } from './lib/http';
import * as tz from './lib/tz';
import { addJournal, AlertRow, deferAlert, rowToState, saveState, trimJournal } from './lib/store';
import { AlertDigest, sendDigestEmail } from './notify/email';
import { sendPush } from './notify/webpush';

export interface TickReport {
  due: number;
  checked: number;
  deferred: number;
  notified: number;
  requests: number;
  /** Disabled because no delivery channel was left on. */
  skipped: number;
  /** Paused because the owner stopped coming back. */
  stale: number;
  /** Fresh slots found but not pushed, because of the alert's silent hours. */
  quieted: number;
  /** Digest emails sent, one per user. */
  mailed: number;
  stopped?: string;
}

export async function runTick(env: Env, appUrl: string): Promise<TickReport> {
  const maxPerDay = Number(env.MAX_REQUESTS_PER_DAY ?? 800) || 800;
  const tickBudget = Number(env.TICK_REQUEST_BUDGET ?? 42) || 42;
  const guard = await RateGuard.load(env.DB, maxPerDay, tickBudget);

  const report: TickReport = {
    due: 0, checked: 0, deferred: 0, notified: 0, requests: 0,
    skipped: 0, stale: 0, quieted: 0, mailed: 0,
  };

  const gate = guard.canRun();
  if (!gate.ok) {
    report.stopped = gate.reason;
    return report;
  }

  const now = new Date();
  // A generous LIMIT rather than the whole table: the budget will run out long
  // before 60 alerts, and an unbounded read is how a free-tier D1 bill starts.
  const staleDays = Number(env.AUTO_PAUSE_DAYS ?? 0) || 0;
  const { results } = await env.DB.prepare(
    `SELECT a.*, u.last_seen_at, u.email_alerts, u.email
       FROM alerts a JOIN users u ON u.id = a.user_id
      WHERE a.enabled = 1 AND a.next_check_at <= ? AND u.active = 1
      ORDER BY a.next_check_at ASC
      LIMIT 60`,
  )
    .bind(now.toISOString())
    .all<AlertRow & { last_seen_at: string | null; email_alerts: number; email: string }>();

  report.due = results.length;
  if (results.length === 0) {
    await guard.save(env.DB);
    return report;
  }

  const api = new DoctolibApi(guard);
  let first = true;

  // Email is batched per user across the whole tick: three alerts firing in
  // the same minute should arrive as one message, not three. Push stays
  // immediate, because a push that waits is a slot already taken.
  const mailbox = new Map<string, AlertDigest[]>();

  for (const row of results) {
    const state = rowToState(row);
    const cost = estimateRequests(state.config);

    // Stop before starting an alert that cannot finish. A half-checked alert
    // would record "nothing found" and silence a slot that was really there.
    if (guard.tickUsed + cost > guard.tickBudget) {
      report.deferred++;
      continue;
    }
    if (guard.budgetExhausted) {
      report.stopped = `Quota quotidien atteint (${maxPerDay} requetes).`;
      break;
    }

    // A snoozed alert is not checked at all — that is the point of snoozing.
    if (isSnoozed(state.config, now)) {
      await deferAlert(env.DB, state.id, new Date(state.config.snoozedUntil!));
      continue;
    }

    // Nothing to deliver, so nothing to look for. The API normally disables
    // these on save; this catches anything that slipped through.
    if (isSilent(state.config)) {
      await env.DB.prepare('UPDATE alerts SET enabled = 0 WHERE id = ?').bind(state.id).run();
      report.skipped++;
      continue;
    }

    // An alert whose owner has not opened the app in weeks is still spending
    // Doctolib requests every quarter of an hour on news nobody reads. Pause
    // it rather than delete it: logging back in turns it on again.
    if (staleDays > 0 && isStale(row.last_seen_at, staleDays, now)) {
      await env.DB.prepare('UPDATE alerts SET enabled = 0, last_error = ? WHERE id = ?')
        .bind(
          `Mise en pause : aucune connexion depuis ${staleDays} jours. Reactivez-la quand vous voulez.`,
          state.id,
        )
        .run();
      report.stale++;
      continue;
    }

    if (!first) await breathe();
    first = false;

    let outcome;
    try {
      outcome = await runAlert(api, state, now);
    } catch (e) {
      if (e instanceof BudgetExhausted) {
        report.deferred++;
        break;
      }
      throw e;
    }

    report.requests += outcome.requests;

    if (outcome.deferred) {
      report.deferred++;
      break;
    }

    const next = new Date(now.getTime() + state.config.intervalMinutes * 60_000);
    await saveState(env.DB, state, next);
    report.checked++;

    await addJournal(env.DB, {
      userId: state.userId,
      alertId: state.id,
      title: state.title,
      kind: outcome.error
        ? 'error'
        : outcome.hits.filter((h) => !isIgnored(state.config, h)).length > 0
          ? 'found'
          : 'nothing',
      slots: outcome.hits.filter((h) => !isIgnored(state.config, h)).length,
      fresh: outcome.freshHits.length,
      requests: outcome.requests,
      detail: outcome.error ?? outcome.note ?? null,
    });

    if (outcome.freshHits.length > 0) {
      // Found at 3 a.m. is still worth recording; it is just not worth waking
      // anyone for. The slots are already saved, so they are in the list at 7.
      //
      // Silence here used to be indistinguishable from push being broken, which
      // cost an evening of debugging, so the suppression is written down.
      if (isQuietNow(state.config, now)) {
        report.quieted += outcome.freshHits.length;
        await addJournal(env.DB, {
          userId: state.userId,
          alertId: state.id,
          title: state.title,
          kind: 'found',
          slots: outcome.freshHits.length,
          fresh: outcome.freshHits.length,
          requests: 0,
          detail:
            `${outcome.freshHits.length} nouveau(x) creneau(x) trouve(s), mais notification ` +
            `retenue : heures silencieuses (${state.config.quietFromHour}h-${state.config.quietToHour}h).`,
        });
      } else {
        const sent = await notify(env, state.userId, state.title, state.config, outcome.freshHits, appUrl);
        report.notified += sent;

        if (state.config.notifyEmail) {
          // The mail shows the whole picture, not just what is new: what is
          // still open, and what the user muted, exactly as the app does.
          const freshIds = new Set(outcome.freshHits.map(slotId));
          const digest: AlertDigest = {
            title: state.title,
            fresh: outcome.freshHits,
            known: outcome.hits.filter(
              (h) => !freshIds.has(slotId(h)) && !isIgnored(state.config, h),
            ),
            ignored: outcome.hits.filter((h) => isIgnored(state.config, h)),
          };
          const box = mailbox.get(state.userId) ?? [];
          box.push(digest);
          mailbox.set(state.userId, box);
        }
        // Only a complaint when a push was actually asked for. An email-only
        // alert legitimately sends nothing here; its mail goes out with the
        // tick's digest further down.
        if (sent === 0 && state.config.notifyPush) {
          await addJournal(env.DB, {
            userId: state.userId,
            alertId: state.id,
            title: state.title,
            kind: 'error',
            slots: outcome.freshHits.length,
            fresh: outcome.freshHits.length,
            requests: 0,
            detail:
              'Creneaux trouves mais aucune notification envoyee : aucun appareil abonne, ' +
              'ou le service de push les a toutes refusees.',
          });
        }
      }
    }

    // A block stops the whole run: the retreat is about this address, not
    // about one alert, and the next tick will find the guard paused.
    if (outcome.blocked) {
      report.stopped = outcome.error;
      break;
    }
  }

  // One message per user, after every alert of this tick has had its say.
  report.mailed = await flushMailbox(env, mailbox, appUrl);

  await guard.save(env.DB);
  // Cheap, and only ever on a cron tick.
  if (Math.random() < 0.05) await trimJournal(env.DB);
  return report;
}

/** Sends the collected digests, one per user. */
async function flushMailbox(
  env: Env,
  mailbox: Map<string, AlertDigest[]>,
  appUrl: string,
): Promise<number> {
  const cfg = mailerOf(env);
  if (mailbox.size === 0 || !cfg) return 0;
  let sent = 0;

  for (const [userId, digests] of mailbox) {
    const user = await env.DB.prepare(
      'SELECT email, email_alerts FROM users WHERE id = ?',
    )
      .bind(userId)
      .first<{ email: string; email_alerts: number }>();

    if (!user?.email || !user.email_alerts) continue;

    const res = await sendDigestEmail({ cfg, to: user.email, digests, appUrl });

    if (res.ok) {
      sent++;
    } else {
      // A rejected mail is worth a journal line: a wrong sender domain fails
      // every time and is otherwise completely silent.
      await addJournal(env.DB, {
        userId,
        alertId: '',
        title: digests[0]?.title ?? 'E-mail',
        kind: 'error',
        slots: 0,
        fresh: 0,
        requests: 0,
        detail: `Envoi e-mail refuse : ${res.error ?? 'raison inconnue'}`,
      });
    }
  }
  return sent;
}

/**
 * Pushes to every browser the user has registered. Email is not sent here:
 * it is collected into the tick's mailbox and flushed once per user.
 */
async function notify(
  env: Env,
  userId: string,
  title: string,
  config: WatchConfig,
  hits: SlotHit[],
  appUrl: string,
): Promise<number> {
  let sent = 0;
  const style = config.alertStyle;

  if (config.notifyPush && env.VAPID_PUBLIC_KEY && env.VAPID_PRIVATE_KEY) {
    const { results: subs } = await env.DB.prepare(
      'SELECT id, endpoint, p256dh, auth FROM push_subs WHERE user_id = ?',
    )
      .bind(userId)
      .all<{ id: string; endpoint: string; p256dh: string; auth: string }>();

    const first = hits[0];
    const payload = {
      title:
        hits.length === 1
          ? `Creneau libre — ${title}`
          : `${hits.length} creneaux — ${title}`,
      body:
        hits.length === 1
          ? `${tz.humanSlot(new Date(first.when))}\n${first.doctorName}${first.city ? `, ${first.city}` : ''}`
          : hits
              .slice(0, 3)
              .map((h) => `${tz.humanShort(new Date(h.when))} — ${h.doctorName}`)
              .join('\n'),
      url: hits.length === 1 ? first.bookingUrl : appUrl,
      appUrl,
      // 'call' cannot ring a browser the way it rings an Android phone. The
      // closest honest equivalent is a notification that does not auto-dismiss
      // and vibrates insistently.
      style,
      tag: `alert-${title}`,
      count: hits.length,
    };

    for (const sub of subs) {
      const res = await sendPush(sub, payload, {
        publicKey: env.VAPID_PUBLIC_KEY,
        privateKey: env.VAPID_PRIVATE_KEY,
        subject: env.CONTACT_EMAIL || 'mailto:admin@example.com',
      });
      if (res.ok) {
        sent++;
        await env.DB.prepare('UPDATE push_subs SET last_ok_at = ?, fail_count = 0 WHERE id = ?')
          .bind(new Date().toISOString(), sub.id)
          .run();
      } else if (res.gone) {
        // The browser threw the subscription away; so do we.
        await env.DB.prepare('DELETE FROM push_subs WHERE id = ?').bind(sub.id).run();
      } else {
        await env.DB.prepare('UPDATE push_subs SET fail_count = fail_count + 1 WHERE id = ?')
          .bind(sub.id)
          .run();
      }
    }
  }

  return sent;
}

/** True when the owner has not opened the app for `days` days. */
function isStale(lastSeenAt: string | null, days: number, now: Date): boolean {
  // Never seen is not stale: the account was only just created, and its first
  // alert deserves to run before anyone has had a chance to come back.
  if (!lastSeenAt) return false;
  const seen = new Date(lastSeenAt);
  if (Number.isNaN(seen.getTime())) return false;
  return now.getTime() - seen.getTime() > days * 86_400_000;
}
