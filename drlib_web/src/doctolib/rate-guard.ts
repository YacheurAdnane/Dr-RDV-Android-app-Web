/**
 * Port of lib/src/rate_guard.dart, with one change that matters.
 *
 * On the phone the guard was per-install: one person, one mobile IP, polling
 * politely. Here every request for every user leaves from the same Cloudflare
 * address, so the guard is deployment-wide and lives in D1. If Doctolib pushes
 * back it is pushing back on all of us, and the retreat has to be shared.
 *
 * A second ceiling is new: Cloudflare caps a single Worker invocation at 50
 * outbound subrequests on the free plan, so each cron tick also carries a
 * budget it may not exceed. Running out of tick budget is not an error — the
 * remaining alerts simply stay due and are picked up by the next tick.
 */

import * as tz from '../lib/tz';

export interface GuardRow {
  day_key: string;
  requests_today: number;
  consecutive_blocks: number;
  paused_until: string | null;
  last_block_message: string | null;
}

/** 15 min, 30 min, 1 h, 2 h, 4 h, then capped at 6 h. */
const BACKOFF_MINUTES = [15, 30, 60, 120, 240, 360];

export class RateGuard {
  maxRequestsPerDay: number;
  dayKey: string;
  requestsToday: number;
  consecutiveBlocks: number;
  pausedUntil: Date | null;
  lastBlockMessage: string | null;

  /** Subrequests this Worker invocation may still spend. */
  tickBudget: number;
  tickUsed = 0;

  private dirty = false;

  constructor(row: GuardRow, maxRequestsPerDay: number, tickBudget: number) {
    this.maxRequestsPerDay = maxRequestsPerDay;
    this.dayKey = row.day_key ?? '';
    this.requestsToday = row.requests_today ?? 0;
    this.consecutiveBlocks = row.consecutive_blocks ?? 0;
    this.pausedUntil = row.paused_until ? new Date(row.paused_until) : null;
    this.lastBlockMessage = row.last_block_message ?? null;
    this.tickBudget = tickBudget;
  }

  static async load(db: D1Database, maxPerDay: number, tickBudget: number): Promise<RateGuard> {
    const row = await db
      .prepare(
        'SELECT day_key, requests_today, consecutive_blocks, paused_until, last_block_message FROM guard WHERE id = 1',
      )
      .first<GuardRow>();
    return new RateGuard(
      row ?? {
        day_key: '',
        requests_today: 0,
        consecutive_blocks: 0,
        paused_until: null,
        last_block_message: null,
      },
      maxPerDay,
      tickBudget,
    );
  }

  async save(db: D1Database): Promise<void> {
    if (!this.dirty) return;
    await db
      .prepare(
        `UPDATE guard SET day_key = ?, requests_today = ?, consecutive_blocks = ?,
         paused_until = ?, last_block_message = ? WHERE id = 1`,
      )
      .bind(
        this.dayKey,
        this.requestsToday,
        this.consecutiveBlocks,
        this.pausedUntil ? this.pausedUntil.toISOString() : null,
        this.lastBlockMessage,
      )
      .run();
    this.dirty = false;
  }

  private rollDay(): void {
    const today = tz.dateKey(new Date());
    if (this.dayKey !== today) {
      this.dayKey = today;
      this.requestsToday = 0;
      this.dirty = true;
    }
  }

  get isPaused(): boolean {
    return this.pausedUntil != null && new Date() < this.pausedUntil;
  }

  get pauseRemainingMinutes(): number {
    if (!this.isPaused || !this.pausedUntil) return 0;
    return Math.ceil((this.pausedUntil.getTime() - Date.now()) / 60000);
  }

  get budgetExhausted(): boolean {
    this.rollDay();
    return this.requestsToday >= this.maxRequestsPerDay;
  }

  get tickExhausted(): boolean {
    return this.tickUsed >= this.tickBudget;
  }

  get remainingToday(): number {
    this.rollDay();
    return Math.max(0, this.maxRequestsPerDay - this.requestsToday);
  }

  /** Whether a check may run at all right now. */
  canRun(): { ok: boolean; reason?: string } {
    if (this.isPaused) {
      return {
        ok: false,
        reason: `Surveillance en pause encore ${this.pauseRemainingMinutes} min (Doctolib a refuse nos requetes).`,
      };
    }
    if (this.budgetExhausted) {
      return {
        ok: false,
        reason: `Quota quotidien atteint (${this.maxRequestsPerDay} requetes). Reprise demain.`,
      };
    }
    return { ok: true };
  }

  recordRequest(): void {
    this.rollDay();
    this.requestsToday++;
    this.tickUsed++;
    this.dirty = true;
  }

  /** A normal answer: forget any previous push-back. */
  recordSuccess(): void {
    if (this.consecutiveBlocks !== 0 || this.pausedUntil != null) {
      this.consecutiveBlocks = 0;
      this.pausedUntil = null;
      this.lastBlockMessage = null;
      this.dirty = true;
    }
  }

  /** Doctolib said 403 or 429. Retreat, and retreat longer each time. */
  recordBlock(statusCode: number): void {
    this.consecutiveBlocks++;
    const minutes = BACKOFF_MINUTES[Math.min(this.consecutiveBlocks - 1, BACKOFF_MINUTES.length - 1)];
    this.pausedUntil = new Date(Date.now() + minutes * 60_000);
    this.lastBlockMessage =
      statusCode === 429
        ? `Doctolib nous a demande de ralentir. Pause de ${minutes} min.`
        : `Doctolib a refuse la requete (${statusCode}). Pause de ${minutes} min.`;
    this.dirty = true;
  }
}

/** A small random delay so requests never land on a perfect clock tick. */
export function jitterMs(maxMillis = 900): number {
  return Math.floor(Math.random() * maxMillis);
}

export function sleep(ms: number): Promise<void> {
  return new Promise((r) => setTimeout(r, ms));
}
