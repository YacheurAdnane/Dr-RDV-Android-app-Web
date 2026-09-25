/**
 * Web Push, implemented directly against WebCrypto.
 *
 * The usual `web-push` package assumes Node's crypto and does not run in a
 * Worker, so this does the two things it would have done:
 *
 *  - VAPID (RFC 8292): an ES256 JWT identifying this server to the push
 *    service, so Mozilla/Google/Apple will accept an anonymous push.
 *  - Payload encryption (RFC 8291, `aes128gcm`): the push service relays the
 *    body without being able to read it. Only the browser holds the key.
 *
 * Both are fiddly and both fail silently-ish when wrong (a 400 from the push
 * service with no useful body), so the steps below are numbered against the
 * RFC to make them checkable.
 */

import { b64urlToBytes, bytesToB64url, concat, uint32be, utf8 } from '../lib/bytes';

export interface PushSubscription {
  endpoint: string;
  /** The browser's public key, 65 bytes uncompressed, base64url. */
  p256dh: string;
  /** The browser's auth secret, 16 bytes, base64url. */
  auth: string;
}

export interface VapidKeys {
  publicKey: string;
  privateKey: string;
  subject: string;
}

export interface PushResult {
  ok: boolean;
  status: number;
  /** The subscription is dead and should be deleted (404 / 410). */
  gone: boolean;
  error?: string;
}

/**
 * Sends one notification.
 *
 * Never throws for a rejected push: a broken subscription is an ordinary fact
 * of life (the user cleared site data, the phone was reset) and the caller
 * wants to carry on with the other ones.
 */
export async function sendPush(
  sub: PushSubscription,
  payload: unknown,
  vapid: VapidKeys,
  ttlSeconds = 24 * 3600,
): Promise<PushResult> {
  try {
    const body = await encrypt(utf8(JSON.stringify(payload)), sub);
    const auth = await vapidHeader(sub.endpoint, vapid);

    const res = await fetch(sub.endpoint, {
      method: 'POST',
      headers: {
        Authorization: auth,
        'Content-Encoding': 'aes128gcm',
        'Content-Type': 'application/octet-stream',
        TTL: String(ttlSeconds),
        Urgency: 'high',
      },
      body,
      signal: AbortSignal.timeout(15_000),
    });

    if (res.ok) return { ok: true, status: res.status, gone: false };
    return {
      ok: false,
      status: res.status,
      gone: res.status === 404 || res.status === 410,
      error: (await res.text().catch(() => '')).slice(0, 200),
    };
  } catch (e) {
    return { ok: false, status: 0, gone: false, error: String(e) };
  }
}

// ---------------------------------------------------------------------------
// RFC 8291 — payload encryption
// ---------------------------------------------------------------------------

async function encrypt(plaintext: Uint8Array, sub: PushSubscription): Promise<Uint8Array> {
  const uaPublicRaw = b64urlToBytes(sub.p256dh); // 65 bytes, 0x04 || X || Y
  const authSecret = b64urlToBytes(sub.auth); // 16 bytes

  // 1. An ephemeral keypair for this message alone.
  //
  // The casts here are about @cloudflare/workers-types, not about the runtime.
  // generateKey is typed as CryptoKey | CryptoKeyPair because one signature
  // covers both, exportKey('raw') as ArrayBuffer | JsonWebKey for the same
  // reason, and the ECDH parameter is generated as `$public` because `public`
  // collides with a reserved word in their codegen. The Workers runtime wants
  // plain `public`, exactly as the WebCrypto spec says, which is what the
  // round-trip test in scripts/test-push.mjs confirms.
  const asKeys = (await crypto.subtle.generateKey({ name: 'ECDH', namedCurve: 'P-256' }, true, [
    'deriveBits',
  ])) as CryptoKeyPair;
  const asPublicRaw = new Uint8Array(
    (await crypto.subtle.exportKey('raw', asKeys.publicKey)) as ArrayBuffer,
  );

  const uaPublicKey = await crypto.subtle.importKey(
    'raw',
    uaPublicRaw,
    { name: 'ECDH', namedCurve: 'P-256' },
    false,
    [],
  );

  // 2. ecdh_secret = ECDH(as_private, ua_public)
  const ecdhSecret = new Uint8Array(
    await crypto.subtle.deriveBits(
      { name: 'ECDH', public: uaPublicKey } as unknown as SubtleCryptoDeriveKeyAlgorithm,
      asKeys.privateKey,
      256,
    ),
  );

  // 3-5. IKM = HKDF(salt = auth_secret, ikm = ecdh_secret,
  //                 info = "WebPush: info\0" || ua_public || as_public)
  const keyInfo = concat(utf8('WebPush: info\0'), uaPublicRaw, asPublicRaw);
  const ikm = await hkdf(authSecret, ecdhSecret, keyInfo, 32);

  // 6-9. The content encryption key and nonce, from a fresh random salt.
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const cek = await hkdf(salt, ikm, utf8('Content-Encoding: aes128gcm\0'), 16);
  const nonce = await hkdf(salt, ikm, utf8('Content-Encoding: nonce\0'), 12);

  // 10. One record, so the padding delimiter is 0x02 and no padding follows.
  const padded = concat(plaintext, new Uint8Array([0x02]));

  const aesKey = await crypto.subtle.importKey('raw', cek, { name: 'AES-GCM' }, false, ['encrypt']);
  const ciphertext = new Uint8Array(
    await crypto.subtle.encrypt({ name: 'AES-GCM', iv: nonce, tagLength: 128 }, aesKey, padded),
  );

  // 12. header = salt(16) || record_size(4) || key_id_len(1) || as_public(65)
  return concat(
    salt,
    uint32be(4096),
    new Uint8Array([asPublicRaw.length]),
    asPublicRaw,
    ciphertext,
  );
}

/** HKDF-SHA256: extract with `salt`, then expand with `info`. */
async function hkdf(
  salt: Uint8Array,
  ikm: Uint8Array,
  info: Uint8Array,
  length: number,
): Promise<Uint8Array> {
  const key = await crypto.subtle.importKey('raw', ikm, 'HKDF', false, ['deriveBits']);
  const bits = await crypto.subtle.deriveBits(
    { name: 'HKDF', hash: 'SHA-256', salt, info },
    key,
    length * 8,
  );
  return new Uint8Array(bits);
}

// ---------------------------------------------------------------------------
// RFC 8292 — VAPID
// ---------------------------------------------------------------------------

async function vapidHeader(endpoint: string, vapid: VapidKeys): Promise<string> {
  const aud = new URL(endpoint).origin;
  const header = { typ: 'JWT', alg: 'ES256' };
  const payload = {
    aud,
    // Twelve hours. Push services reject anything beyond 24.
    exp: Math.floor(Date.now() / 1000) + 12 * 3600,
    sub: vapid.subject,
  };

  const signingInput =
    `${bytesToB64url(utf8(JSON.stringify(header)))}.${bytesToB64url(utf8(JSON.stringify(payload)))}`;

  const key = await importVapidPrivateKey(vapid.privateKey, vapid.publicKey);
  // WebCrypto's ECDSA signatures are already raw r||s, which is what JWS wants
  // — no DER unwrapping needed.
  const sig = await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, key, utf8(signingInput));

  return `vapid t=${signingInput}.${bytesToB64url(sig)}, k=${vapid.publicKey}`;
}

/**
 * VAPID keys are conventionally passed around as raw base64url: 32 bytes of
 * private scalar and a 65-byte uncompressed public point. WebCrypto will only
 * import a JWK, and a JWK needs x and y separately — which the public point
 * already contains, so it is split rather than recomputed.
 */
async function importVapidPrivateKey(privateB64: string, publicB64: string): Promise<CryptoKey> {
  const d = b64urlToBytes(privateB64);
  const pub = b64urlToBytes(publicB64);
  if (pub.length !== 65 || pub[0] !== 0x04) {
    throw new Error('VAPID_PUBLIC_KEY doit faire 65 octets non compresses (prefixe 0x04).');
  }
  if (d.length !== 32) {
    throw new Error('VAPID_PRIVATE_KEY doit faire 32 octets.');
  }
  const jwk: JsonWebKey = {
    kty: 'EC',
    crv: 'P-256',
    d: bytesToB64url(d),
    x: bytesToB64url(pub.slice(1, 33)),
    y: bytesToB64url(pub.slice(33, 65)),
    ext: true,
  };
  return crypto.subtle.importKey('jwk', jwk, { name: 'ECDSA', namedCurve: 'P-256' }, false, [
    'sign',
  ]);
}
