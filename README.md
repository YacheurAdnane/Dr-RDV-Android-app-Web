# Alertes RDV — Doctolib appointment watcher

A Flutter (Android) app that watches Doctolib for appointments and notifies you
when one frees up **inside a window you choose** — "next 3 days", "between the
14th and the 18th", "weekday afternoons only". No account, no server, no push
service: the phone polls doctolib.fr directly and raises a local notification.

## What it does

- **City first, then what you need.** Doctolib's suggestion endpoint is
  nationwide and ignores any location you send it, so the app asks for the city
  up front and uses it to sort practitioners: the ones in your city first,
  everything else set apart under "Ailleurs".
- **Optional zone around you, on a map.** The map zooms onto your point as soon
  as it is found (GPS or address), the zone is drawn in a strong red, and two
  buttons re-centre on the point or show the whole zone.
- **How the zone works.** After the city, an alert can be limited to a
  circle (0.5-30 km) or a travel time (walk, bike, public transport, car,
  5-90 min) from your current position, a point tapped on the map, or an
  address. Doctolib only searches by town, so the app finds every town the zone
  touches and searches each, then keeps the practitioners actually inside it:
  in a live test, 3 km around a Villeurbanne address gave 30 GPs, 17 of them
  in neighbouring towns a city search would have missed. Skip the step and the
  alert covers the city, as before. Travel times are converted with average
  urban speeds (waiting and walking included for public transport) and are
  shown as estimates; exact timetables would need a paid routing API. Each
  slot then shows its distance, the list can be sorted by nearest, and
  "Itineraire" opens your maps app.
- **Search like Doctolib does.** Type `cardio` and you get the same speciality
  suggestions the site gives you (Cardiologue, Bilan cardiologique, Cardiologue
  du sport…), plus matching practitioners and clinics.
- **Watch a whole speciality, or one doctor.** A speciality watch fires for
  *any* practitioner of that speciality in the chosen city. You can pin several
  specialities to one watch (e.g. `Dermatologue` + `Dermatologue esthétique`).
- **Only near-term slots.** The whole point: a slot in four months is not news.
  Every watch has a window, and nothing outside it notifies.
- **At the practice, by video, or either.** Chosen per alert. Video is filtered
  server-side by Doctolib (in one test, 70 paediatricians became 25), so it
  costs nothing extra; "au cabinet" is applied in-app.
- **Filters Doctolib does not offer** — hour range, weekdays, new patients only
  — so you are not woken for a slot you could not take.
- **Mute what you don't want, at three levels.** From any slot: ignore *this
  slot*, ignore *that whole day*, or ignore *that practitioner* entirely. Plus
  "Tout ignorer" to clear the current batch in one tap. Muted things are never
  notified and never counted, but stay listed with an undo — and an ignored
  practitioner is skipped before their calendar is fetched, so it also saves
  requests. Anything genuinely new afterwards appears in red, marked NOUVEAU.
- **A permanent status badge**, the way an antivirus keeps one: silent, low
  priority, showing each alert's state, how many slots are free, and how long
  ago the last search ran. Rewritten after every check.
- **Snooze an alert** for 1 h to 3 days without losing its configuration, and
  **duplicate** one to make a variant.
- **Choose how loudly each alert interrupts you.** Per alert, because urgency is
  a property of the appointment:
  - *Discret* — appears in the shade, no sound.
  - *Notification* — the usual sound.
  - *M'appeler* — rings like an incoming call, with a ringtone you pick (the
    phone's own ringtone or alarm, or one of five bundled with the app) on the
    phone's ringtone volume, like a WhatsApp call, so it rings even with
    notification sounds turned off. It takes over the lock screen with a call screen. Green ("Voir le
    RDV") opens the Doctolib booking page directly. Red, or letting it ring out
    (20–90 s, configurable), stops the ring and leaves an ordinary notification,
    so the slot is never lost. Quiet hours still win: nothing rings at 3 a.m.
- **Appointment type at a glance.** Every slot carries small grey tags with a
  dot: speciality, visit motive ("Premiere consultation", "Suivi"...), and
  "Video" for teleconsultations. Same on the call screen and in notifications.
- **French, English and Arabic.** Chosen on the first screen or in Settings
  (or follow the phone). Arabic lays the whole app out right to left. Dates,
  times and distances follow the language (14h30 / 14:30, 2,5 km / 2.5 km).
  Notifications, the call screen and Android's own notification-channel names
  switch too. Doctolib's data (speciality and motive names) stays in French:
  that is what the site returns.
- **Light, dark or automatic theme**, in Settings.
- **Activity log ("Journal").** Every check and every call, with the time and
  whether it ran in the background: the proof the watcher actually runs while
  the phone is in a pocket. Once enough slots have been found it also tells
  you the hour when new slots appear most often (practices tend to release
  cancellations at set times), i.e. when to be ready.
- **Background checks** every 15 min – 6 h, with quiet hours.
- **Test any alert style** from Settings, so you know what "call me" sounds like
  before you trust it with a real appointment.
- **Guided first run** that walks through the two Android permissions the app
  cannot work without, and sets quiet hours before you ever see the main screen.
- Tapping a notification opens the practitioner's Doctolib booking page.

## Getting it on a phone

```bash
flutter build apk --release
```

The APK lands in `build/app/outputs/flutter-apk/app-release.apk`. Copy it to the
phone and install it (Android will ask you to allow installing from this source).

For day-to-day development:

```bash
flutter run
```

The first launch walks you through what has to be granted; both are also
reachable later from the Settings screen.

1. **Notifications** — Android 13+ requires an explicit grant. Without it the
   app keeps searching but cannot tell you anything.
2. **Background running** — the app asks to be exempt from battery
   optimisation. Android otherwise puts it to sleep and the periodic check
   simply stops. **This is the single most common reason a watcher app "stops
   working".** On Samsung, Xiaomi, Huawei, Oppo and OnePlus you usually also
   have to add the app to the manufacturer's own "protected apps" list — the
   onboarding screen says so.
3. *(Only if you use "call me")* **Full-screen notifications** — Android 14+
   gates the lock-screen takeover separately. The app asks the moment you pick
   that style for an alert.

## Not being blocked

Doctolib has no public API and does rate-limit chatty addresses. The app is
built to stay far below that line rather than to hide from it:

| Measure | Where |
|---|---|
| Server-side pre-filter: ask Doctolib *which* practitioners are free before date X, in one request, instead of polling every practitioner in town | `engine.dart`, `availabilitiesBefore` |
| Frugal mode: fetch exact times only for practitioners not already known to match — a routine pass costs 1–3 requests | `engine.dart`, `AppSettings.frugalMode` |
| ≥ 0.9 s between requests, plus random jitter so traffic never looks like a metronome | `doctolib_api.dart`, `RateGuard.jitter` |
| Hard daily ceiling (default 800 requests), counted across all watches | `rate_guard.dart` |
| On a 403/429: stop the whole run immediately and stay away 15 min → 30 → 1 h → 2 h → 4 h → 6 h | `RateGuard.recordBlock` |
| Quiet hours: no requests at all at night, and a "call me" alert demoted to silent if one is found during a manual check | `AppSettings.isQuietNow`, `engine.dart` |
| Exponential backoff on 5xx, timeouts, and WorkManager retries | `doctolib_api.dart`, `background.dart` |

The Settings screen shows a live estimate ("~3 requests per pass, ~100/day") and
today's actual count, so the cost of a configuration is never a surprise.

Sensible use: a handful of watches, a 30 min interval, quiet hours on. That is a
few hundred requests a day — far less than one person browsing the site.

### Why there is no proxy option

The app deliberately does **not** route traffic through proxies, rotate IPs, or
solve CAPTCHAs. Not only as a matter of principle — it would also make blocking
*more* likely, not less:

- Doctolib sits behind commercial bot protection that scores the IP's
  reputation. A home or mobile IP making a few hundred polite requests a day
  scores well. A datacentre or public-proxy IP is a known-bad category before
  the first request is even read, and free proxy pools are exactly the addresses
  those systems already have on file.
- Public proxies terminate TLS. Whoever runs them sees and can alter everything
  passing through. This app sends no password and no health data, so the damage
  is bounded, but "free proxy" is never a security improvement.
- Rotating IPs converts a rate limit — temporary, self-healing, invisible to you
  because the app backs off — into a fingerprinting problem, where the defence
  moves to signals you cannot rotate and the eventual block is harder and
  broader.

What actually protects your address is sending few enough requests to be
uninteresting, which is what every measure in the table above is for. If you
already use a reputable VPN for everything, leaving it on is harmless; adding
one specifically to outrun a rate limit is not the lever you want, because the
limit is on volume, and the app already governs volume.

For context on the real risk: what a limit like this does is return 429 for a
while. The app notices, stops, waits, and resumes. A permanent ban of a private
person's IP for checking appointment availability is not a thing that happens at
this volume.

## How it works

Everything is public JSON that doctolib.fr's own front-end calls while you
browse; no cookie or CSRF token is required.

| Purpose | Endpoint |
|---|---|
| Speciality + practitioner suggestions | `POST /patient-health-search/api/v1/autocomplete` — `{"query":"…"}` |
| City suggestions | `GET /patient_app/place_autocomplete.json?query=…` |
| Resolve a city to the object the search needs | `GET /{speciality}/{city}` → `window.place = {…}` |
| Practitioners for a speciality + city | `POST /patient-health-search/api/v1/hcp/search?page=N` |
| One practitioner's motives and agendas | `GET /online_booking/api/slot_selection_funnel/v1/info.json?profile_slug=…` |
| Address search / reverse (zone only) | `data.geopf.fr/geocodage/search`, `/reverse` (IGN, State-run, keyless) |
| Town containing a point (zone only) | `geo.api.gouv.fr/communes?lat=&lon=` |
| Free slots | `GET /availabilities.json?visit_motive_ids=…&agenda_ids=…&practice_ids=…&start_date=…&limit=N` |

These are undocumented and can change without notice. When a shape moves, the
client raises a `DoctolibException` rather than crashing, carrying Doctolib's
own explanation from the response body.

`/availabilities.json` rejects any `limit` above 15 days with a 400
(`"limit: must be less than or equal to 15"`). The client fetches longer
windows in consecutive 15-day chunks and stops as soon as `next_slot` says the
rest would be empty, so a 30-day window with nothing in it still costs one
request. `test/availability_limit_test.dart` fails if any request asks for more.

### Self-repair

A failing alert is rebuilt from fresh Doctolib data (city search object,
practitioner agendas and practice, list of known practitioners) and retried
straight away. This is the automatic equivalent of deleting the alert and
creating it again, except the user's filters, ignore lists and notification
history are kept. The error is only shown after three failed checks in a row,
with the cause attached; below that the alert shows "Reparation automatique en
cours (1/3)" and keeps its last results. Being rate-limited (403/429) is never
"repaired": that is about volume, and retrying would make it worse.

## Layout

```
lib/
  main.dart                  app shell, theme, French locale
  src/
    models.dart              watches, places, doctors, slots, settings
    doctolib_api.dart        the six endpoints above, parsed defensively
    rate_guard.dart          daily budget, jitter, backoff, pause state
    store.dart               SharedPreferences persistence (UI + background)
    notifications.dart       channels, grouping, tap handling
    engine.dart              the check itself; shared by UI and background
    background.dart          WorkManager periodic task
    ui/                      app_state, onboarding, home, edit watch,
                             detail, settings
test/filters_test.dart       window, filters, alert styles, quiet hours,
                             backoff, persistence
tool/live_check.dart         end-to-end probe against the live site
```

`engine.dart` is the only definition of "a new slot", and both the foreground
refresh and the background task go through it — so what you see when you pull to
refresh is exactly what would have notified you.

## Verifying against the live site

```bash
flutter test tool/live_check.dart --dart-define=ARGS="pediatre~Lyon"
```

Walks the whole chain — autocomplete, city resolution, filtered search,
availabilities, booking sheet, client-side filtering — and prints what each step
returned plus the request count. Run it if something looks wrong; it tells you
within seconds whether Doctolib moved a response shape.

The probes run under `flutter test` (the client uses Flutter's localisation)
but are kept out of `test/`, so a plain `flutter test` never touches the
network. `tool/zone_check.dart` and `tool/chunk_check.dart` probe the zone
pipeline and the 15-day limit the same way.

### Translations

All text lives in `tool/i18n/strings.py`, one line per message with its
French, English and Arabic versions. After editing it:

```bash
python tool/i18n/build_arb.py
```

```bash
flutter gen-l10n
```

The builder refuses a translation that drops or invents a placeholder.
`test/screens_test.dart` renders every screen in the three languages and both
themes at phone size and fails on any overflow.

## Limits worth knowing

- **Android only.** The background scheduler and notification plumbing are
  Android-specific. iOS has no equivalent of a guaranteed periodic background
  task, so an iOS port would only check while the app is open.
- **15 minutes is the floor, not the recommendation.** WorkManager will not run
  periodic work more often, and delays it further while the device dozes — so
  15 min really means "as soon as Android feels like it". It also costs 4× the
  requests of hourly checking for a modest gain. **30 min is the sensible
  default**; use 15 min only for a genuinely urgent search over a few days, and
  1–3 h for a background hunt. The Settings screen says which regime you are in
  as you change it.
- **Booking is not automated.** The app tells you a slot exists and opens the
  Doctolib page; you book it yourself. Popular slots do go in seconds.
- **Location is used once.** "Ma position" asks for location permission when
  tapped, reads one fix, and stores the point in the alert. Nothing tracks you
  in the background, and Doctolib only ever receives town names, never your
  address.
- Personal use. Don't run it on a dozen devices against the same watches.
