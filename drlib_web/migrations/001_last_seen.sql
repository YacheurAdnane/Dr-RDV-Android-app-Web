-- Adds activity tracking, so the scheduler can pause alerts whose owner has
-- stopped coming back. Run once against an existing database:
--
--   npx wrangler d1 execute drlib --remote --file=./migrations/001_last_seen.sql
--
-- A fresh database gets this from schema.sql and does not need it.
ALTER TABLE users ADD COLUMN last_seen_at TEXT;

-- Existing accounts start as "seen now" rather than NULL, so nobody's alerts
-- are paused the moment this ships.
UPDATE users SET last_seen_at = datetime('now') WHERE last_seen_at IS NULL;
