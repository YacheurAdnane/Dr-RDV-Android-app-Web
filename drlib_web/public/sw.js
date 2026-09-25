/* Service worker.
 *
 * This is the only part of the app that runs while the page is closed, and it
 * runs only when the push service wakes it. It cannot poll, so it does not
 * try: it renders what the server sent and gets out of the way.
 */

const CACHE = 'drlib-v1';
const SHELL = ['/', '/index.html', '/styles.css', '/app.js', '/icon.svg', '/manifest.webmanifest'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

/**
 * Network first, cache as a fallback.
 *
 * The other way round would be faster, but this app's whole value is freshness
 * — showing a cached list of slots that were taken an hour ago is worse than
 * showing nothing. The cache only exists so the shell opens offline.
 */
self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;
  // API responses are never cached: stale alerts would be actively misleading.
  if (url.pathname.startsWith('/api/')) return;

  event.respondWith(
    fetch(request)
      .then((res) => {
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put(request, copy)).catch(() => {});
        return res;
      })
      .catch(() => caches.match(request).then((hit) => hit || caches.match('/index.html'))),
  );
});

self.addEventListener('push', (event) => {
  let data = {};
  try {
    data = event.data ? event.data.json() : {};
  } catch {
    data = { title: 'Alertes RDV', body: event.data ? event.data.text() : '' };
  }

  const style = data.style || 'normal';
  const options = {
    body: data.body || '',
    icon: '/icon-192.png',
    badge: '/badge.png',
    tag: data.tag || 'drlib',
    // Replace the previous notification for the same alert rather than
    // stacking five of them, but still buzz for the new one.
    renotify: Boolean(data.tag),
    data: { url: data.url || data.appUrl || '/', appUrl: data.appUrl || '/' },
    // 'discreet' is the only style that should slip by unnoticed.
    silent: style === 'discreet',
    // A browser cannot ring like a phone call. The closest honest equivalent
    // is a notification that will not dismiss itself and vibrates insistently.
    requireInteraction: style === 'call',
    vibrate: style === 'call'
      ? [300, 150, 300, 150, 300, 150, 300]
      : style === 'discreet' ? undefined : [200, 100, 200],
    actions: [
      { action: 'book', title: 'Reserver' },
      { action: 'open', title: 'Mes alertes' },
    ],
  };

  event.waitUntil(
    self.registration.showNotification(data.title || 'Creneau disponible', options),
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const d = event.notification.data || {};
  const target = event.action === 'open' ? (d.appUrl || '/') : (d.url || '/');

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clients) => {
      // Reuse an open tab when the target is our own app; a Doctolib booking
      // link always gets a fresh one so the app is not navigated away from.
      const sameOrigin = target.startsWith(self.location.origin) || target.startsWith('/');
      if (sameOrigin) {
        for (const c of clients) {
          if ('focus' in c) {
            c.navigate(target).catch(() => {});
            return c.focus();
          }
        }
      }
      return self.clients.openWindow(target);
    }),
  );
});
