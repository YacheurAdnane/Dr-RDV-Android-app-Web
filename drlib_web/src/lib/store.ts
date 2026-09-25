/** D1 row <-> AlertState mapping, in one place so the shape is defined once. */

import type { AlertState } from '../doctolib/engine';
import { normaliseWatch, SlotHit, WatchConfig } from '../doctolib/models';
import { normaliseZone } from '../doctolib/zone';

export interface AlertRow {
  id: string;
  user_id: string;
  title: string;
  config: string;
  enabled: number;
  next_check_at: string;
  last_checked_at: string | null;
  last_error: string | null;
  last_hits: string;
  seen: string;
  known_doctor_keys: string;
  error_streak: number;
  last_request_count: number;
  created_at: string;
  updated_at: string;
}

export function rowToState(row: AlertRow): AlertState {
  const config = parseConfig(row.config, row.id, row.title);
  return {
    id: row.id,
    userId: row.user_id,
    title: row.title,
    config,
    lastHits: parseArray<SlotHit>(row.last_hits),
    seen: parseArray<string>(row.seen),
    knownDoctorKeys: parseArray<string>(row.known_doctor_keys),
    errorStreak: row.error_streak,
    lastError: row.last_error,
    lastCheckedAt: row.last_checked_at,
    lastRequestCount: row.last_request_count,
  };
}

export function parseConfig(raw: string, id: string, title: string): WatchConfig {
  let parsed: any = {};
  try {
    parsed = JSON.parse(raw);
  } catch {
    parsed = {};
  }
  const w = normaliseWatch(parsed, id, title);
  w.zone = normaliseZone(parsed?.zone);
  return w;
}

function parseArray<T>(raw: string): T[] {
  try {
    const v = JSON.parse(raw);
    return Array.isArray(v) ? v : [];
  } catch {
    return [];
  }
}

/** Writes back everything a check may have changed. */
export async function saveState(
  db: D1Database,
  state: AlertState,
  nextCheckAt: Date,
): Promise<void> {
  await db
    .prepare(
      `UPDATE alerts SET
         config = ?, last_hits = ?, seen = ?, known_doctor_keys = ?,
         error_streak = ?, last_error = ?, last_checked_at = ?,
         last_request_count = ?, next_check_at = ?, updated_at = ?
       WHERE id = ?`,
    )
    .bind(
      JSON.stringify(state.config),
      JSON.stringify(state.lastHits),
      JSON.stringify(state.seen),
      JSON.stringify(state.knownDoctorKeys),
      state.errorStreak,
      state.lastError,
      state.lastCheckedAt,
      state.lastRequestCount,
      nextCheckAt.toISOString(),
      new Date().toISOString(),
      state.id,
    )
    .run();
}

/** Pushes an alert's next check back without touching its results. */
export async function deferAlert(db: D1Database, id: string, nextCheckAt: Date): Promise<void> {
  await db
    .prepare('UPDATE alerts SET next_check_at = ? WHERE id = ?')
    .bind(nextCheckAt.toISOString(), id)
    .run();
}

export async function addJournal(
  db: D1Database,
  entry: {
    userId: string;
    alertId: string;
    title: string;
    kind: 'found' | 'nothing' | 'error' | 'skipped';
    slots: number;
    fresh: number;
    requests: number;
    detail?: string | null;
  },
): Promise<void> {
  await db
    .prepare(
      `INSERT INTO journal (at, user_id, alert_id, title, kind, slots, fresh, requests, detail)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    )
    .bind(
      new Date().toISOString(),
      entry.userId,
      entry.alertId,
      entry.title,
      entry.kind,
      entry.slots,
      entry.fresh,
      entry.requests,
      entry.detail ?? null,
    )
    .run();
}

/**
 * Keeps the journal from growing without bound. Called from the cron tick, so
 * it costs nothing on a user-facing request.
 */
export async function trimJournal(db: D1Database, keep = 2000): Promise<void> {
  await db
    .prepare(
      `DELETE FROM journal WHERE id NOT IN (
         SELECT id FROM journal ORDER BY id DESC LIMIT ?
       )`,
    )
    .bind(keep)
    .run();
}
