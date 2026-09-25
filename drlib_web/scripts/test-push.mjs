/**
 * Round-trips the Web Push encryption against a fake browser.
 *
 * RFC 8291 is the one piece of this project with no useful error message when
 * it goes wrong — a push service answers "400 Bad Request" whether the salt is
 * misplaced, the HKDF info string has the wrong terminator, or the key is not
 * the one the subscription was made with. So this plays the receiving browser:
 * it holds the private half of the subscription, decrypts what sendPush
 * produced, and checks it comes back byte for byte.
 *
 *   node scripts/test-push.mjs      (after `npm install`, which brings esbuild)
 */

import { webcrypto } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const { subtle } = webcrypto;
const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

const b64url = (b) =>
  Buffer.from(b).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
const fromB64url = (s) => Buffer.from(s.replace(/-/g, '+').replace(/_/g, '/'), 'base64');
const utf8 = (s) => new TextEncoder().encode(s);

let pass = 0;
let fail = 0;
function check(name, ok, detail = '') {
  if (ok) { pass++; console.log(`  ok   ${name}`); }
  else { fail++; console.error(`  FAIL ${name}${detail ? ` — ${detail}` : ''}`); }
}

// The Worker source is TypeScript with extensionless imports, which Node's own
// loader will not resolve. esbuild ships with wrangler, so it does the bundling.
const dir = mkdtempSync(join(tmpdir(), 'drlib-'));
const bundle = join(dir, 'webpush.mjs');
execFileSync(
  process.execPath,
  [
    join(ROOT, 'node_modules/esbuild/bin/esbuild'),
    join(ROOT, 'src/notify/webpush.ts'),
    '--bundle', '--format=esm', `--outfile=${bundle}`,
  ],
  { stdio: ['ignore', 'ignore', 'inherit'], cwd: ROOT },
);
const { sendPush } = await import(`file://${bundle.replace(/\\/g, '/')}`);

// --- the fake browser ------------------------------------------------------

const ua = await subtle.generateKey({ name: 'ECDH', namedCurve: 'P-256' }, true, ['deriveBits']);
const uaPublicRaw = Buffer.from(await subtle.exportKey('raw', ua.publicKey));
const authSecret = Buffer.from(webcrypto.getRandomValues(new Uint8Array(16)));

const vapid = await subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, ['sign', 'verify']);
const vapidPublicRaw = Buffer.from(await subtle.exportKey('raw', vapid.publicKey));
const vapidJwk = await subtle.exportKey('jwk', vapid.privateKey);

const subscription = {
  endpoint: 'https://fcm.googleapis.com/fcm/send/fake-endpoint-id',
  p256dh: b64url(uaPublicRaw),
  auth: b64url(authSecret),
};

const payload = {
  title: 'Creneau libre — Dermato Lyon',
  body: 'jeudi 12 juin a 14:30\nDr Zoe Germont, Lyon',
  url: 'https://www.doctolib.fr/dermatologue/lyon/zoe-germont',
  style: 'call',
  count: 1,
  accents: 'eeàéèêç — non-ASCII survives the round trip',
};

// --- intercept the outbound request ---------------------------------------

let captured = null;
globalThis.fetch = async (url, init) => {
  captured = { url, init };
  return new Response('', { status: 201 });
};

const result = await sendPush(subscription, payload, {
  publicKey: b64url(vapidPublicRaw),
  privateKey: vapidJwk.d,
  subject: 'mailto:test@example.com',
});

console.log('\nWeb Push encryption');
check('sendPush reports success', result.ok, JSON.stringify(result));
check('request was made', captured !== null);
check('endpoint is the subscription endpoint', captured?.url === subscription.endpoint);
check('Content-Encoding is aes128gcm', captured?.init.headers['Content-Encoding'] === 'aes128gcm');
check('TTL header present', Boolean(captured?.init.headers.TTL));

// --- decrypt as the browser would -----------------------------------------

const body = Buffer.from(captured.init.body);
const salt = body.subarray(0, 16);
const recordSize = body.readUInt32BE(16);
const idLen = body[20];
const asPublicRaw = body.subarray(21, 21 + idLen);
const ciphertext = body.subarray(21 + idLen);

check('record size is 4096', recordSize === 4096, String(recordSize));
check('key id is a 65-byte uncompressed point', idLen === 65 && asPublicRaw[0] === 0x04);

async function hkdf(saltBytes, ikm, info, length) {
  const key = await subtle.importKey('raw', ikm, 'HKDF', false, ['deriveBits']);
  return Buffer.from(
    await subtle.deriveBits({ name: 'HKDF', hash: 'SHA-256', salt: saltBytes, info }, key, length * 8),
  );
}

const asPublicKey = await subtle.importKey(
  'raw', asPublicRaw, { name: 'ECDH', namedCurve: 'P-256' }, false, [],
);
const ecdhSecret = Buffer.from(
  await subtle.deriveBits({ name: 'ECDH', public: asPublicKey }, ua.privateKey, 256),
);

const keyInfo = Buffer.concat([utf8('WebPush: info\0'), uaPublicRaw, asPublicRaw]);
const ikm = await hkdf(authSecret, ecdhSecret, keyInfo, 32);
const cek = await hkdf(salt, ikm, utf8('Content-Encoding: aes128gcm\0'), 16);
const nonce = await hkdf(salt, ikm, utf8('Content-Encoding: nonce\0'), 12);

let decrypted = null;
try {
  const aesKey = await subtle.importKey('raw', cek, { name: 'AES-GCM' }, false, ['decrypt']);
  decrypted = Buffer.from(
    await subtle.decrypt({ name: 'AES-GCM', iv: nonce, tagLength: 128 }, aesKey, ciphertext),
  );
} catch (e) {
  check('ciphertext decrypts', false, String(e));
}

if (decrypted) {
  check('ciphertext decrypts', true);
  check('padding delimiter is 0x02', decrypted[decrypted.length - 1] === 0x02);
  const text = decrypted.subarray(0, decrypted.length - 1).toString('utf8');
  let parsed = null;
  try { parsed = JSON.parse(text); } catch { /* reported below */ }
  check('plaintext is valid JSON', parsed !== null, text.slice(0, 80));
  check('payload round-trips exactly',
    JSON.stringify(parsed) === JSON.stringify(payload),
    `got ${text.slice(0, 120)}`);
}

// --- VAPID -----------------------------------------------------------------

console.log('\nVAPID');
const authHeader = captured.init.headers.Authorization;
check('scheme is vapid', authHeader?.startsWith('vapid t='), authHeader?.slice(0, 20));

const m = /^vapid t=([^,]+), k=(.+)$/.exec(authHeader ?? '');
check('header parses', m !== null);

if (m) {
  const [, jwt, k] = m;
  check('k is the public key', k === b64url(vapidPublicRaw));

  const [h, p, s] = jwt.split('.');
  const header = JSON.parse(fromB64url(h).toString());
  const claims = JSON.parse(fromB64url(p).toString());

  check('alg is ES256', header.alg === 'ES256');
  check('aud is the endpoint origin', claims.aud === 'https://fcm.googleapis.com', claims.aud);
  check('sub is our contact', claims.sub === 'mailto:test@example.com');
  check('exp is within 24 h', claims.exp > Date.now() / 1000 && claims.exp < Date.now() / 1000 + 86400);

  const sig = fromB64url(s);
  check('signature is raw r||s (64 bytes)', sig.length === 64, String(sig.length));

  const verified = await subtle.verify(
    { name: 'ECDSA', hash: 'SHA-256' }, vapid.publicKey, sig, utf8(`${h}.${p}`),
  );
  check('signature verifies against the public key', verified);
}

rmSync(dir, { recursive: true, force: true });

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail === 0 ? 0 : 1);
