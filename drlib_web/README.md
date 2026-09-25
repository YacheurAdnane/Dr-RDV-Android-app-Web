# drlib_web

The Doctolib watcher from the Flutter app, rebuilt as a web app that runs on Cloudflare Workers.

Same engine, different place to run it. The Flutter version polls from the phone with WorkManager. This one polls from a cron trigger in the cloud and pushes the result to whatever browser you registered: iPhone, Android, Windows, Mac. No App Store, no Apple Developer account, no Mac needed to build it.

Accounts are created by an admin. There is no sign-up form, so you can hand out the URL and only the people you made accounts for can do anything with it.

## What actually works, and what doesn't

Web Push reaches Android Chrome and Firefox, and every desktop browser, from a normal tab. On iPhone and iPad it works from iOS 16.4, but only after the site has been added to the home screen through Safari's Share menu. In a plain Safari tab, push does not exist. The app detects this and says so instead of failing quietly.

The `call` alert style cannot ring a browser the way it rings an Android phone. There is no API for that. What you get instead is a notification with `requireInteraction` (it stays on screen until you touch it) and a longer vibration pattern. The `discreet` and `normal` styles map cleanly.

The honest risk: on the phone, checks left from your mobile IP and looked like a person browsing. Here every check for every user leaves from one Cloudflare address, hitting the same endpoints on a schedule. Doctolib treats datacenter ranges much more harshly than mobile ones. Expect this to work for a handful of users and to start collecting 403s if you grow it. The rate guard from the Dart code came across intact and is now deployment-wide rather than per-install, the minimum gap between requests went from 900 ms to 1400 ms, and alerts are staggered across cron ticks instead of all firing at once. That buys you margin. It does not buy you immunity.

## How the pieces fit

`src/doctolib/` is the port of the Dart engine: `api.ts` from `doctolib_api.dart`, `engine.ts` from `engine.dart`, plus models, zone geometry, the rate guard and the government geocoding client. The structure survived on purpose. The filtered search that asks Doctolib "who has something before Thursday" in one request, then frugal mode only pricing calendars for practitioners who were not already matching, is what keeps a check down to two or three requests instead of forty.

`src/scheduler.ts` is the cron tick. It runs every 5 minutes, not every 15. Each alert carries its own `next_check_at`, so a tick picks up only what is due. Three budgets bound it: Cloudflare's 50 outbound subrequests per invocation on the free plan, the deployment-wide daily ceiling, and the rate guard's retreat after a 403 or 429. An alert that will not fit in the remaining budget is left for the next tick rather than cut off half way, because a half-checked alert would record "nothing found" and silence a slot that was really there.

`src/notify/webpush.ts` implements RFC 8291 payload encryption and RFC 8292 VAPID directly against WebCrypto. The usual `web-push` package assumes Node's crypto and will not run in a Worker. `scripts/test-push.mjs` plays the receiving browser: it holds the private half of a subscription, decrypts what `sendPush` produced, and checks it comes back byte for byte. Run it after any change to that file.

`src/lib/tz.ts` exists because the Dart code read the phone's local clock everywhere (`DateTime.now()`, `slot.hour`, `slot.weekday`) and a Worker runs in UTC. Without it, a 9h-18h filter silently becomes 10h-19h in summer. `scripts/test-tz.mjs` pins both sides of both DST transitions.

`public/` is the PWA. Vanilla HTML, CSS and JS, no build step, served from the edge.

## Deploying

You need a Cloudflare account. Free tier is enough. I cannot create it for you, so these are the commands to run yourself.

```bash
cd drlib_web
npm install
npx wrangler login
```

Create the database and put the id it prints into `wrangler.toml` in place of `REPLACE_WITH_YOUR_D1_DATABASE_ID`:

```bash
npx wrangler d1 create drlib
```

Create the tables:

```bash
npm run db:init
```

Generate the VAPID keypair and store both halves as secrets. Keep them: rotating them invalidates every existing push subscription.

```bash
npm run vapid
npx wrangler secret put VAPID_PUBLIC_KEY
npx wrangler secret put VAPID_PRIVATE_KEY
```

Pick a one-time token for creating the first admin account, then deploy:

```bash
npx wrangler secret put ADMIN_BOOTSTRAP
npx wrangler deploy
```

Wrangler prints your URL, something like `https://drlib.<your-subdomain>.workers.dev`. Create the first admin against it, substituting your own token and the username you want:

```bash
curl -X POST https://drlib.YOURNAME.workers.dev/api/auth/bootstrap -H "Content-Type: application/json" -d "{\"token\":\"YOUR_BOOTSTRAP_TOKEN\",\"username\":\"adnane\"}"
```

It replies with a generated password. Write it down, then close the door behind you:

```bash
npx wrangler secret delete ADMIN_BOOTSTRAP
```

Log in at the root URL, go to `/admin`, and create the rest of the accounts from there.

Two settings in `wrangler.toml` you will want to set before you have users: `CONTACT_EMAIL` (goes in the VAPID `sub` claim, so push services have someone to contact) and `APP_URL`, which the cron uses to build the "see my alerts" link inside notifications. Add `APP_URL` under `[vars]` with your real deployed URL, because the fallback in `src/index.ts` is a guess.

## Email

Optional. With no provider key the whole email path is skipped and push keeps working, so nothing is blocked on it.

Two providers are supported and the difference matters. **Resend verifies a domain**: until you own one and add its DNS records, it refuses to write to anyone except the address the Resend account was opened with. **Brevo verifies a single sender address**: confirm a Gmail you already own and you can write to anybody. For a handful of users, Brevo is the one that works.

Brevo, the recommended route:

1. Sign up at brevo.com (free: 300 emails/day)
2. Senders, Domains & Dedicated IPs → **Senders** → add your own address, click the confirmation link
3. SMTP & API → **API Keys** → create one
4. Set `MAIL_FROM` in `wrangler.toml` to that same address
5. Add `BREVO_API_KEY` as a Worker secret

Resend works the same way once you own a domain; set `RESEND_API_KEY` instead. If both keys are present Brevo wins, because it is the one that does not need a domain.

Secrets can go in through the Cloudflare dashboard (Workers & Pages → drlib → Settings → Variables and Secrets) rather than the CLI, which is useful if antivirus blocks wrangler.

The address is set by the admin when creating or editing a user, and giving someone an address is what enables email for them. Requiring a second toggle afterwards was a trap: the per-alert checkbox stayed greyed out and nothing said why. The user cannot change their own address, so nobody can point alerts at somebody else's inbox.

One message per user per tick, never one per alert and never one per slot. The digest groups by alert and keeps the three states the app uses: new slots in red, already-signalled in plain text, and anything the user muted greyed out and struck through. Push stays immediate; a push that waits is a slot already taken.

## Running it locally

```bash
npm run db:init:local
npm run dev
```

Put `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY` and `ADMIN_BOOTSTRAP` in a `.dev.vars` file (never commit it). Push will not work over plain `http://localhost` in every browser; Chrome treats localhost as a secure origin so it usually does.

To fire a cron tick by hand instead of waiting:

```bash
curl "http://127.0.0.1:8787/cdn-cgi/local/scheduled"
```

## Tests

```bash
npm test            # 27 timezone cases + 20 push crypto cases
npm run typecheck
```

Both test scripts bundle the TypeScript with the esbuild that ships inside wrangler, so there is nothing else to install.

## Notification channels, and not checking for nothing

Each alert carries `notifyPush` and `notifyEmail`. Both off is allowed and means the alert is saved but disabled, because an alert nobody will hear about still costs Doctolib requests every quarter of an hour. The API enforces that on save and the scheduler double-checks it.

Email also needs the account to have an address, which only an admin can set. Two switches have to agree before a mail goes out.

`AUTO_PAUSE_DAYS` (default 14) pauses a user's alerts when they have not opened the app for that long. `last_seen_at` is written when the alert list loads, not on every API call, so a background push refresh does not keep a dormant account looking alive. A paused alert keeps its configuration and its results; the owner logs in, sees why, and clicks Reactiver. Set it to "0" to never pause.

An existing database needs the column added once:

```bash
npx wrangler d1 execute drlib --remote --file=./migrations/001_last_seen.sql
```

## Things worth knowing before you change something

Passwords are PBKDF2-SHA256 at 20,000 iterations, which is low. Cloudflare's free plan allows 10 ms of CPU per invocation and PBKDF2 is the only thing in this codebase that actually burns CPU (everything else is waiting on the network, which does not count). 100,000 iterations does not fit. The count is stored per user row, so if you move to a paid plan you can raise the constant in `src/lib/crypto.ts` and hashes re-cost on the next password change without breaking old ones. For a private app with generated 18-character passwords this is a defensible trade. For a public sign-up form it would not be.

Client input never goes into an alert config wholesale. Everything passes through `normaliseWatch`, which clamps the numbers and drops unknown enum values, so a user cannot set `intervalMinutes` to 1 and make the deployment hammer Doctolib. `intervalMinutes` floors at 5 because that is the cron granularity.

Alert limits: 10 per account, 8 registered browsers per user, 60 alerts read per tick. All arbitrary, all in one place each.

The rate guard is a single row in the `guard` table, shared by the cron and by anything a user does in the UI. A user typing in the search box and the scheduler are the same IP address as far as Doctolib is concerned, so they share a budget.

## What is not ported yet

Zone search works server-side (`src/doctolib/zone.ts` and the `/api/geo/*` routes are complete) but the creation form in `public/app.js` has no map UI, so there is no way to draw a zone from the browser. An alert created with a zone in its config will be honoured by the engine. You just cannot make one from the web UI yet.

The journal is per user and capped at 2,000 rows globally. The Flutter app's `journal_page.dart` had a richer view.

Insurance sector is hardcoded to `public` in the availabilities query, same as the Dart code.
