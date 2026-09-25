/**
 * Generates the PNG icons the manifest and iOS need, with no dependencies.
 *
 * A browser would rasterise icon.svg happily, but iOS insists on a real PNG
 * for the home-screen icon and the manifest wants concrete sizes, so the same
 * design is drawn here with plain arithmetic and encoded with Node's own zlib.
 *
 *   node scripts/gen-icons.mjs
 */

import { deflateSync } from 'node:zlib';
import { writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const OUT = join(dirname(fileURLToPath(import.meta.url)), '..', 'public');

const TEAL = [15, 124, 108];
const MINT = [159, 240, 222];
const WHITE = [255, 255, 255];

/** 4x supersampling: the only thing standing between this and jagged edges. */
const SS = 4;

function draw(size, { maskable = false } = {}) {
  const W = size * SS;
  const px = new Uint8Array(W * W * 4);

  // Geometry in a 512-unit design space, scaled to the target.
  const k = W / 512;
  // A maskable icon may be cropped to a circle, so the art shrinks inside the
  // safe zone and the background runs edge to edge.
  const inset = maskable ? 0.76 : 1;
  const radius = maskable ? 0 : 112 * k;

  const cx = W / 2;
  const cy = W / 2;

  const put = (x, y, [r, g, b]) => {
    const i = (y * W + x) * 4;
    px[i] = r; px[i + 1] = g; px[i + 2] = b; px[i + 3] = 255;
  };

  for (let y = 0; y < W; y++) {
    for (let x = 0; x < W; x++) {
      // Rounded-rect background.
      if (radius > 0 && outsideRoundedRect(x, y, W, radius)) continue;
      put(x, y, TEAL);
    }
  }

  // Clock face: a white ring.
  const ringR = 132 * k * inset;
  const ringW = 30 * k * inset;
  const faceCy = cy + (maskable ? 0 : 12 * k);

  for (let y = 0; y < W; y++) {
    for (let x = 0; x < W; x++) {
      if (radius > 0 && outsideRoundedRect(x, y, W, radius)) continue;
      const d = Math.hypot(x - cx, y - faceCy);
      if (Math.abs(d - ringR) <= ringW / 2) put(x, y, WHITE);
    }
  }

  // Hands: vertical up to 12, horizontal out to 2 o'clock-ish.
  const hw = (30 * k * inset) / 2;
  const up = 78 * k * inset;
  const right = 62 * k * inset;

  for (let y = 0; y < W; y++) {
    for (let x = 0; x < W; x++) {
      const dx = x - cx;
      const dy = y - faceCy;
      const vertical = Math.abs(dx) <= hw && dy <= 0 && dy >= -up;
      const horizontal = Math.abs(dy) <= hw && dx >= 0 && dx <= right;
      if (vertical || horizontal) put(x, y, WHITE);
    }
  }

  // Two mint arcs over the top, the "alert" half of the mark.
  const arcR = 178 * k * inset;
  const arcW = 26 * k * inset;
  for (let y = 0; y < W; y++) {
    for (let x = 0; x < W; x++) {
      if (radius > 0 && outsideRoundedRect(x, y, W, radius)) continue;
      const dx = x - cx;
      const dy = y - faceCy;
      if (dy > 0) continue;
      const d = Math.hypot(dx, dy);
      if (Math.abs(d - arcR) > arcW / 2) continue;
      // Leave a gap straight above, so it reads as two arcs, not a halo.
      const angle = Math.abs(Math.atan2(dx, -dy)); // 0 = straight up
      if (angle < 0.42 || angle > 1.25) continue;
      put(x, y, MINT);
    }
  }

  return downsample(px, W, size);
}

function outsideRoundedRect(x, y, W, r) {
  const nx = Math.min(x, W - 1 - x);
  const ny = Math.min(y, W - 1 - y);
  if (nx >= r || ny >= r) return false;
  return Math.hypot(r - nx, r - ny) > r;
}

/** Box-filter the supersampled buffer down to the target size. */
function downsample(src, W, size) {
  const out = new Uint8Array(size * size * 4);
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      let r = 0, g = 0, b = 0, a = 0;
      for (let sy = 0; sy < SS; sy++) {
        for (let sx = 0; sx < SS; sx++) {
          const i = ((y * SS + sy) * W + (x * SS + sx)) * 4;
          r += src[i]; g += src[i + 1]; b += src[i + 2]; a += src[i + 3];
        }
      }
      const n = SS * SS;
      const o = (y * size + x) * 4;
      out[o] = Math.round(r / n);
      out[o + 1] = Math.round(g / n);
      out[o + 2] = Math.round(b / n);
      out[o + 3] = Math.round(a / n);
    }
  }
  return out;
}

// --------------------------------------------------------------- PNG output --

function crc32(buf) {
  let c = ~0;
  for (let i = 0; i < buf.length; i++) {
    c ^= buf[i];
    for (let k = 0; k < 8; k++) c = (c >>> 1) ^ (0xedb88320 & -(c & 1));
  }
  return ~c >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
}

function encodePng(rgba, size) {
  // Filter type 0 (None) in front of every scanline.
  const raw = Buffer.alloc(size * (size * 4 + 1));
  for (let y = 0; y < size; y++) {
    raw[y * (size * 4 + 1)] = 0;
    Buffer.from(rgba.buffer, y * size * 4, size * 4)
      .copy(raw, y * (size * 4 + 1) + 1);
  }

  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(size, 0);
  ihdr.writeUInt32BE(size, 4);
  ihdr[8] = 8;   // bit depth
  ihdr[9] = 6;   // colour type: RGBA
  ihdr[10] = 0;  // deflate
  ihdr[11] = 0;  // adaptive filtering
  ihdr[12] = 0;  // no interlace

  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

const targets = [
  ['icon-192.png', 192, {}],
  ['icon-512.png', 512, {}],
  ['icon-180.png', 180, {}],     // apple-touch-icon
  ['icon-maskable.png', 512, { maskable: true }],
  ['badge.png', 96, {}],
];

for (const [name, size, opts] of targets) {
  const png = encodePng(draw(size, opts), size);
  writeFileSync(join(OUT, name), png);
  console.log(`${name}  ${size}x${size}  ${(png.length / 1024).toFixed(1)} KB`);
}
