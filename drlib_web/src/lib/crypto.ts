import { b64urlToBytes, bytesToB64url, bytesToHex, randomBytes, utf8 } from './bytes';

/**
 * Password hashing and session tokens.
 *
 * PBKDF2-SHA256 rather than argon2 or bcrypt because WebCrypto is all a Worker
 * has, and a pure-JS bcrypt would be far slower than the native primitive.
 *
 * The iteration count is deliberately modest. Cloudflare's free plan allows
 * 10 ms of CPU per invocation and PBKDF2 is the one thing here that actually
 * burns CPU (everything else is waiting on the network, which does not count).
 * 20 000 iterations lands inside that budget; 100 000 does not. The count is
 * stored per user row, so raising it later is a matter of changing this
 * constant and re-hashing on next login — old passwords keep working.
 *
 * This is a defensible trade for a private, admin-provisioned app with strong
 * generated passwords. It is not what you would ship for a public sign-up form.
 */
export const PW_ITERATIONS = 20_000;

export async function hashPassword(
  password: string,
  saltB64?: string,
  iterations = PW_ITERATIONS,
): Promise<{ hash: string; salt: string; iterations: number }> {
  const salt = saltB64 ? b64urlToBytes(saltB64) : randomBytes(16);
  const key = await crypto.subtle.importKey('raw', utf8(password), 'PBKDF2', false, [
    'deriveBits',
  ]);
  const bits = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', salt, iterations, hash: 'SHA-256' },
    key,
    256,
  );
  return {
    hash: bytesToB64url(bits),
    salt: bytesToB64url(salt),
    iterations,
  };
}

export async function verifyPassword(
  password: string,
  storedHash: string,
  salt: string,
  iterations: number,
): Promise<boolean> {
  const { hash } = await hashPassword(password, salt, iterations);
  return timingSafeEqual(hash, storedHash);
}

/** Constant-time string compare, so a wrong password cannot be narrowed down. */
export function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

/** A fresh session token. The caller keeps the plaintext; we store the hash. */
export function newSessionToken(): string {
  return bytesToB64url(randomBytes(32));
}

export async function sha256Hex(s: string): Promise<string> {
  const d = await crypto.subtle.digest('SHA-256', utf8(s));
  return bytesToHex(d);
}

/** Short, URL-safe, collision-resistant enough for row ids. */
export function newId(prefix = ''): string {
  return prefix + bytesToB64url(randomBytes(12));
}

/**
 * A readable password an admin can dictate over the phone.
 * No look-alike characters (0/O, 1/l/I), grouped for legibility.
 */
export function generatePassword(): string {
  const alphabet = 'abcdefghijkmnopqrstuvwxyzACDEFGHJKLMNPQRSTUVWXYZ23456789';
  const bytes = randomBytes(18);
  const chars = [...bytes].map((b) => alphabet[b % alphabet.length]);
  return [chars.slice(0, 6), chars.slice(6, 12), chars.slice(12, 18)]
    .map((g) => g.join(''))
    .join('-');
}
