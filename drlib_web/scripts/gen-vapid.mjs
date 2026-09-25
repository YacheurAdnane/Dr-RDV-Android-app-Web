/**
 * Generates a VAPID keypair for Web Push.
 *
 *   node scripts/gen-vapid.mjs
 *
 * The private key never leaves your machine except as a Wrangler secret; the
 * public one is handed to browsers when they subscribe. Rotating them
 * invalidates every existing subscription, so generate once and keep them.
 */

import { webcrypto } from 'node:crypto';

const { subtle } = webcrypto;

const b64url = (buf) =>
  Buffer.from(buf).toString('base64')
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

const keys = await subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, [
  'sign',
  'verify',
]);

// Raw uncompressed point: 0x04 || X || Y, 65 bytes.
const publicKey = b64url(await subtle.exportKey('raw', keys.publicKey));
// The private scalar `d`, 32 bytes, as the JWK carries it.
const jwk = await subtle.exportKey('jwk', keys.privateKey);
const privateKey = jwk.d;

console.log(`
VAPID_PUBLIC_KEY
${publicKey}

VAPID_PRIVATE_KEY
${privateKey}

Enregistrez-les comme secrets :

  npx wrangler secret put VAPID_PUBLIC_KEY
  npx wrangler secret put VAPID_PRIVATE_KEY

Pour le developpement local, ajoutez-les a .dev.vars (jamais commite).
`);
