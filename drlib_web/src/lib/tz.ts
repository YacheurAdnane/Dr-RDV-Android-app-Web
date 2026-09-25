/**
 * Everything in the Flutter app was written against the phone's local clock:
 * `DateTime.now()`, `.toLocal()`, `slot.hour`, `slot.weekday`. A Worker runs in
 * UTC, so a naive port would shift every hour filter by one or two hours
 * depending on the season and quietly hand people 7 a.m. slots they asked not
 * to see.
 *
 * So the wall clock is made explicit: one timezone for the whole deployment,
 * and every "what hour is it there" question goes through here.
 */
export const TZ = 'Europe/Paris';

const PARTS = new Intl.DateTimeFormat('en-GB', {
  timeZone: TZ,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
  hour12: false,
  weekday: 'short',
});

const WEEKDAYS: Record<string, number> = {
  Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6, Sun: 7,
};

export interface Parts {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
  /** 1 = Monday .. 7 = Sunday, matching Dart's DateTime.weekday. */
  weekday: number;
}

/** The wall-clock reading of `d` in [TZ]. */
export function parts(d: Date): Parts {
  const f: Record<string, string> = {};
  for (const p of PARTS.formatToParts(d)) f[p.type] = p.value;
  return {
    year: Number(f.year),
    month: Number(f.month),
    day: Number(f.day),
    // Intl renders midnight as "24" in some ICU versions; normalise it.
    hour: Number(f.hour) % 24,
    minute: Number(f.minute),
    second: Number(f.second),
    weekday: WEEKDAYS[f.weekday] ?? 1,
  };
}

/** Minutes [TZ] is ahead of UTC at instant `d` (+60 in winter, +120 in summer). */
export function offsetMinutes(d: Date): number {
  const p = parts(d);
  const asUtc = Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute, p.second);
  // Round to the minute: the difference is always a whole number of minutes,
  // and the seconds component of `d` cancels out on both sides.
  return Math.round((asUtc - Math.floor(d.getTime() / 1000) * 1000) / 60000);
}

/**
 * The instant at which the [TZ] wall clock reads the given local time.
 *
 * Converting the other way needs the offset, and the offset needs an instant,
 * so this guesses once and corrects — two passes settle every case except the
 * hour that does not exist on a spring-forward morning, which lands on the
 * following hour rather than failing.
 */
export function fromLocal(
  year: number,
  month: number,
  day: number,
  hour = 0,
  minute = 0,
  second = 0,
): Date {
  const naive = Date.UTC(year, month - 1, day, hour, minute, second);
  let guess = new Date(naive - offsetMinutes(new Date(naive)) * 60000);
  guess = new Date(naive - offsetMinutes(guess) * 60000);
  return guess;
}

/** `YYYY-MM-DD` of the [TZ] calendar day containing `d`. */
export function dateKey(d: Date): string {
  const p = parts(d);
  return `${String(p.year).padStart(4, '0')}-${String(p.month).padStart(2, '0')}-${String(
    p.day,
  ).padStart(2, '0')}`;
}

/** Midnight at the start of `d`'s [TZ] day. */
export function startOfDay(d: Date): Date {
  const p = parts(d);
  return fromLocal(p.year, p.month, p.day, 0, 0, 0);
}

/** 23:59:59 on `d`'s [TZ] day. */
export function endOfDay(d: Date): Date {
  const p = parts(d);
  return fromLocal(p.year, p.month, p.day, 23, 59, 59);
}

export function addDays(d: Date, days: number): Date {
  const p = parts(d);
  return fromLocal(p.year, p.month, p.day + days, p.hour, p.minute, p.second);
}

/** Whole [TZ] calendar days from `a`'s day to `b`'s day, inclusive of both. */
export function daysBetween(a: Date, b: Date): number {
  const ms = startOfDay(b).getTime() - startOfDay(a).getTime();
  return Math.round(ms / 86_400_000);
}

/** `YYYY-MM-DD`, the shape Doctolib's `start_date` parameter wants. */
export function isoDate(d: Date): string {
  return dateKey(d);
}

/**
 * ISO 8601 with an explicit offset. Doctolib deserialises
 * `availabilitiesBefore` as a Java OffsetDateTime, so the offset is mandatory
 * and a trailing `Z` is not accepted.
 */
export function isoOffset(d: Date): string {
  const p = parts(d);
  const off = offsetMinutes(d);
  const sign = off < 0 ? '-' : '+';
  const abs = Math.abs(off);
  const pad = (v: number, w = 2) => String(v).padStart(w, '0');
  return (
    `${pad(p.year, 4)}-${pad(p.month)}-${pad(p.day)}` +
    `T${pad(p.hour)}:${pad(p.minute)}:${pad(p.second)}` +
    `${sign}${pad(Math.floor(abs / 60))}:${pad(abs % 60)}`
  );
}

/** "jeudi 12 juin a 14:30" — what goes in a notification. */
export function humanSlot(d: Date, locale = 'fr-FR'): string {
  return new Intl.DateTimeFormat(locale, {
    timeZone: TZ,
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    hour: '2-digit',
    minute: '2-digit',
  }).format(d);
}

export function humanShort(d: Date, locale = 'fr-FR'): string {
  return new Intl.DateTimeFormat(locale, {
    timeZone: TZ,
    weekday: 'short',
    day: 'numeric',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  }).format(d);
}
