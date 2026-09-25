-- DRlib web — D1 (SQLite) schema.
-- Safe to re-run: every statement is IF NOT EXISTS.

CREATE TABLE IF NOT EXISTS users (
  id            TEXT PRIMARY KEY,
  username      TEXT NOT NULL UNIQUE,
  email         TEXT NOT NULL DEFAULT '',
  pw_hash       TEXT NOT NULL,
  pw_salt       TEXT NOT NULL,
  -- Stored per row so the cost can be raised later without invalidating
  -- passwords hashed under the old setting.
  pw_iter       INTEGER NOT NULL DEFAULT 20000,
  is_admin      INTEGER NOT NULL DEFAULT 0,
  -- The user's own switch for email alerts; the address itself is set by the
  -- admin, so nobody can point the alerts at someone else's inbox.
  email_alerts  INTEGER NOT NULL DEFAULT 0,
  active        INTEGER NOT NULL DEFAULT 1,
  -- Forces a password change on next login (set when an admin resets one).
  must_change   INTEGER NOT NULL DEFAULT 0,
  -- Login throttling. Without it, an admin-provisioned password is one
  -- unlimited guessing loop away from useless.
  failed_count  INTEGER NOT NULL DEFAULT 0,
  locked_until  TEXT,
  created_at    TEXT NOT NULL,
  last_login_at TEXT,
  -- Last time this account actually used the app. The scheduler pauses alerts
  -- whose owner has gone quiet, because an alert nobody reads still spends
  -- Doctolib requests every quarter of an hour.
  last_seen_at  TEXT
);

-- Only the SHA-256 of the token is stored, so a database leak does not hand
-- out live sessions.
CREATE TABLE IF NOT EXISTS sessions (
  token_hash TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL,
  created_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  user_agent TEXT NOT NULL DEFAULT '',
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_exp  ON sessions(expires_at);

CREATE TABLE IF NOT EXISTS alerts (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL,
  title         TEXT NOT NULL,
  -- The whole WatchConfig as JSON. Keeping it in one column means the Dart
  -- model and this one can stay in step without a migration per field.
  config        TEXT NOT NULL,
  enabled       INTEGER NOT NULL DEFAULT 1,
  -- When the scheduler should next look at this alert. This is what spreads
  -- the load across cron ticks instead of checking everything at once.
  next_check_at TEXT NOT NULL,
  last_checked_at TEXT,
  last_error    TEXT,
  last_hits     TEXT NOT NULL DEFAULT '[]',
  seen          TEXT NOT NULL DEFAULT '[]',
  known_doctor_keys TEXT NOT NULL DEFAULT '[]',
  error_streak  INTEGER NOT NULL DEFAULT 0,
  last_request_count INTEGER NOT NULL DEFAULT 0,
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_alerts_user ON alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_alerts_due  ON alerts(enabled, next_check_at);

CREATE TABLE IF NOT EXISTS push_subs (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL,
  endpoint   TEXT NOT NULL UNIQUE,
  p256dh     TEXT NOT NULL,
  auth       TEXT NOT NULL,
  label      TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL,
  last_ok_at TEXT,
  fail_count INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_push_user ON push_subs(user_id);

-- One row. The rate guard is deployment-wide, not per user, because every
-- request leaves from the same Cloudflare egress address: if Doctolib pushes
-- back, it is pushing back on all of us at once.
CREATE TABLE IF NOT EXISTS guard (
  id                   INTEGER PRIMARY KEY CHECK (id = 1),
  day_key              TEXT NOT NULL DEFAULT '',
  requests_today       INTEGER NOT NULL DEFAULT 0,
  consecutive_blocks   INTEGER NOT NULL DEFAULT 0,
  paused_until         TEXT,
  last_block_message   TEXT
);
INSERT OR IGNORE INTO guard (id) VALUES (1);

CREATE TABLE IF NOT EXISTS journal (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  at       TEXT NOT NULL,
  user_id  TEXT NOT NULL,
  alert_id TEXT NOT NULL,
  title    TEXT NOT NULL,
  kind     TEXT NOT NULL,
  slots    INTEGER NOT NULL DEFAULT 0,
  fresh    INTEGER NOT NULL DEFAULT 0,
  requests INTEGER NOT NULL DEFAULT 0,
  detail   TEXT
);
CREATE INDEX IF NOT EXISTS idx_journal_user ON journal(user_id, at DESC);
CREATE INDEX IF NOT EXISTS idx_journal_at   ON journal(at DESC);
