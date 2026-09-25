/**
 * Checks the Europe/Paris wall clock helpers.
 *
 * The Flutter app read the phone's own clock, so hour and weekday filters were
 * free. A Worker runs in UTC, and getting this wrong is silent: a 9h-18h alert
 * would quietly become 10h-19h in summer and hand people slots they asked not
 * to see. These cases pin both sides of both DST transitions.
 *
 *   node scripts/test-tz.mjs
 */

import { execFileSync } from 'node:child_process';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const dir = mkdtempSync(join(tmpdir(), 'drlib-tz-'));
const bundle = join(dir, 'tz.mjs');

// Node itself runs esbuild's CLI entry point. Going through npx would need a
// shell on Windows, which spawnSync refuses for .cmd files.
execFileSync(
  process.execPath,
  [
    join(ROOT, 'node_modules/esbuild/bin/esbuild'),
    join(ROOT, 'src/lib/tz.ts'),
    '--bundle', '--format=esm', `--outfile=${bundle}`,
  ],
  { stdio: ['ignore', 'ignore', 'inherit'], cwd: ROOT },
);

const tz = await import(`file://${bundle.replace(/\\/g, '/')}`);

let pass = 0;
let fail = 0;
function eq(name, got, want) {
  const ok = JSON.stringify(got) === JSON.stringify(want);
  if (ok) { pass++; console.log(`  ok   ${name}`); }
  else { fail++; console.error(`  FAIL ${name} — got ${JSON.stringify(got)}, want ${JSON.stringify(want)}`); }
}

console.log('offsetMinutes');
// CET (winter) is UTC+1, CEST (summer) UTC+2.
eq('midwinter', tz.offsetMinutes(new Date('2026-01-15T12:00:00Z')), 60);
eq('midsummer', tz.offsetMinutes(new Date('2026-07-15T12:00:00Z')), 120);
// 2026: clocks go forward 29 March, back 25 October, both at 01:00 UTC.
eq('minute before spring forward', tz.offsetMinutes(new Date('2026-03-29T00:59:00Z')), 60);
eq('minute after spring forward', tz.offsetMinutes(new Date('2026-03-29T01:00:00Z')), 120);
eq('minute before fall back', tz.offsetMinutes(new Date('2026-10-25T00:59:00Z')), 120);
eq('minute after fall back', tz.offsetMinutes(new Date('2026-10-25T01:00:00Z')), 60);

console.log('\nparts');
eq('summer hour is local, not UTC', tz.parts(new Date('2026-07-15T12:00:00Z')).hour, 14);
eq('winter hour is local, not UTC', tz.parts(new Date('2026-01-15T12:00:00Z')).hour, 13);
// 2026-07-13 is a Monday.
eq('weekday Monday = 1', tz.parts(new Date('2026-07-13T10:00:00Z')).weekday, 1);
eq('weekday Sunday = 7', tz.parts(new Date('2026-07-19T10:00:00Z')).weekday, 7);
// 23:30 UTC in summer is already the next day in Paris.
eq('late UTC rolls the Paris date', tz.dateKey(new Date('2026-07-15T23:30:00Z')), '2026-07-16');
eq('midnight normalises to hour 0', tz.parts(new Date('2026-07-15T22:00:00Z')).hour, 0);

console.log('\nfromLocal round trip');
eq('summer noon Paris is 10:00 UTC',
  tz.fromLocal(2026, 7, 15, 12, 0, 0).toISOString(), '2026-07-15T10:00:00.000Z');
eq('winter noon Paris is 11:00 UTC',
  tz.fromLocal(2026, 1, 15, 12, 0, 0).toISOString(), '2026-01-15T11:00:00.000Z');
eq('round trips through parts', tz.parts(tz.fromLocal(2026, 3, 29, 14, 30, 0)).hour, 14);

console.log('\nday boundaries');
eq('endOfDay in summer', tz.endOfDay(new Date('2026-07-15T08:00:00Z')).toISOString(),
  '2026-07-15T21:59:59.000Z');
eq('endOfDay in winter', tz.endOfDay(new Date('2026-01-15T08:00:00Z')).toISOString(),
  '2026-01-15T22:59:59.000Z');
eq('startOfDay in summer', tz.startOfDay(new Date('2026-07-15T08:00:00Z')).toISOString(),
  '2026-07-14T22:00:00.000Z');

console.log('\naddDays across DST');
// Adding a day keeps the wall-clock hour even though 29 March is 23 h long.
eq('28 -> 29 March keeps 14:00 local',
  tz.parts(tz.addDays(tz.fromLocal(2026, 3, 28, 14, 0, 0), 1)).hour, 14);
eq('24 -> 25 October keeps 14:00 local',
  tz.parts(tz.addDays(tz.fromLocal(2026, 10, 24, 14, 0, 0), 1)).hour, 14);

console.log('\ndaysBetween');
eq('same day', tz.daysBetween(new Date('2026-07-15T08:00:00Z'), new Date('2026-07-15T20:00:00Z')), 0);
eq('three days', tz.daysBetween(new Date('2026-07-15T08:00:00Z'), new Date('2026-07-18T08:00:00Z')), 3);
eq('across spring forward',
  tz.daysBetween(new Date('2026-03-28T08:00:00Z'), new Date('2026-03-30T08:00:00Z')), 2);
eq('across fall back',
  tz.daysBetween(new Date('2026-10-24T08:00:00Z'), new Date('2026-10-26T08:00:00Z')), 2);

console.log('\nisoOffset (what Doctolib parses as a Java OffsetDateTime)');
eq('summer carries +02:00', tz.isoOffset(new Date('2026-07-15T10:00:00Z')), '2026-07-15T12:00:00+02:00');
eq('winter carries +01:00', tz.isoOffset(new Date('2026-01-15T11:00:00Z')), '2026-01-15T12:00:00+01:00');

console.log('\nisoDate');
eq('plain calendar day', tz.isoDate(new Date('2026-07-15T10:00:00Z')), '2026-07-15');

rmSync(dir, { recursive: true, force: true });
console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail === 0 ? 0 : 1);
