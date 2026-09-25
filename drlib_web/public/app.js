/* Alertes RDV — front-end. No framework, no build step: the whole thing is one
   file the Worker serves straight from the edge. */

const $ = (id) => document.getElementById(id);
const VIEWS = ['login', 'list', 'detail', 'edit', 'settings'];

const state = {
  user: null,
  vapidKey: null,
  emailConfigured: false,
  alerts: [],
  guard: null,
  current: null,   // alert being viewed
  draft: null,     // alert being edited
  freshIds: new Set(),
};

// ---------------------------------------------------------------- helpers --

async function api(path, opts = {}) {
  const res = await fetch(`/api${path}`, {
    credentials: 'same-origin',
    headers: opts.body ? { 'Content-Type': 'application/json' } : {},
    ...opts,
    body: opts.body ? JSON.stringify(opts.body) : undefined,
  });
  let data = {};
  try { data = await res.json(); } catch { /* 204s and the like */ }
  if (!res.ok) {
    const err = new Error(data.error || `Erreur ${res.status}`);
    err.code = data.code;
    err.status = res.status;
    err.hint = data.hint;
    throw err;
  }
  return data;
}

function show(view) {
  for (const v of VIEWS) $(`view-${v}`).hidden = v !== view;
  window.scrollTo(0, 0);
}

let toastTimer;
function toast(msg) {
  let el = document.querySelector('.toast');
  if (!el) {
    el = document.createElement('div');
    el.className = 'toast';
    document.body.appendChild(el);
  }
  el.textContent = msg;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.remove(), 3200);
}

function esc(s) {
  return String(s ?? '').replace(/[&<>"']/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
}

const fmtSlot = new Intl.DateTimeFormat('fr-FR', {
  weekday: 'long', day: 'numeric', month: 'long', hour: '2-digit', minute: '2-digit',
});
const fmtShort = new Intl.DateTimeFormat('fr-FR', {
  day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit',
});

function ago(iso) {
  if (!iso) return 'jamais';
  const mins = Math.round((Date.now() - new Date(iso)) / 60000);
  if (mins < 1) return "a l'instant";
  if (mins < 60) return `il y a ${mins} min`;
  const h = Math.round(mins / 60);
  if (h < 24) return `il y a ${h} h`;
  return `il y a ${Math.round(h / 24)} j`;
}

function until(iso) {
  if (!iso) return '';
  const mins = Math.round((new Date(iso) - Date.now()) / 60000);
  if (mins <= 0) return 'imminent';
  if (mins < 60) return `dans ${mins} min`;
  return `dans ${Math.round(mins / 60)} h`;
}

// A debounce per input, so typing in the search box does not fan out to
// Doctolib on every keystroke — those requests share the daily budget.
function debounce(fn, ms = 320) {
  let t;
  return (...a) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...a), ms);
  };
}

// ------------------------------------------------------------------ login --

$('login-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const btn = e.target.querySelector('button');
  btn.disabled = true;
  $('login-error').hidden = true;
  try {
    const { user } = await api('/auth/login', {
      method: 'POST',
      body: { username: $('login-user').value, password: $('login-pass').value },
    });
    state.user = user;
    $('login-pass').value = '';
    await afterLogin();
  } catch (err) {
    $('login-error').textContent = err.message;
    $('login-error').hidden = false;
  } finally {
    btn.disabled = false;
  }
});

async function afterLogin() {
  const me = await api('/auth/me');
  state.user = me.user;
  state.vapidKey = me.vapidPublicKey;
  state.emailConfigured = me.emailConfigured;
  $('who').textContent = state.user.username;
  $('admin-link').hidden = !state.user.isAdmin;
  if (state.user.mustChange) {
    toast('Votre mot de passe a ete reinitialise — changez-le dans les reglages.');
  }
  await loadAlerts();
  show('list');
  registerServiceWorker();
}

$('btn-logout').addEventListener('click', async () => {
  await api('/auth/logout', { method: 'POST' });
  state.user = null;
  show('login');
});

// ------------------------------------------------------------------- list --

async function loadAlerts() {
  const data = await api('/alerts');
  state.alerts = data.alerts;
  state.guard = data.guard;
  renderList();
}

function renderList() {
  const box = $('alert-list');
  $('list-empty').hidden = state.alerts.length > 0;

  const g = state.guard;
  const gb = $('guard-banner');
  if (g?.paused) {
    gb.textContent = g.message || 'Surveillance en pause : Doctolib a refuse nos requetes.';
    gb.hidden = false;
  } else if (g && g.requestsToday > g.maxPerDay * 0.85) {
    gb.textContent = `Budget de requetes presque atteint (${g.requestsToday} / ${g.maxPerDay} aujourd'hui). Les verifications vont s'espacer.`;
    gb.hidden = false;
  } else {
    gb.hidden = true;
  }

  box.innerHTML = state.alerts.map((a) => {
    const cfg = a.config;
    const badges = [];
    if (!a.enabled) badges.push('<span class="chip">en pause</span>');
    else if (cfg.snoozedUntil && new Date(cfg.snoozedUntil) > new Date()) {
      badges.push(`<span class="chip warn">en veille ${esc(until(cfg.snoozedUntil))}</span>`);
    }
    if (a.lastError) badges.push('<span class="chip bad">erreur</span>');
    if (a.enabled && isQuietNow(cfg)) {
      badges.push(`<span class="chip warn">silencieux jusqu'a ${cfg.quietToHour}h</span>`);
    }
    if (a.slotCount > 0) {
      badges.push(`<span class="chip on">${a.slotCount} creneau${a.slotCount > 1 ? 'x' : ''}</span>`);
    }

    const slots = a.hits.map((h) => `
      <div class="slot">
        <div class="grow">
          <div class="when">${esc(fmtSlot.format(new Date(h.when)))}</div>
          <div class="who2">${esc(h.doctorName)}${h.city ? ` · ${esc(h.city)}` : ''}</div>
        </div>
      </div>`).join('');

    return `
      <div class="card alert-card" data-id="${esc(a.id)}">
        <div class="alert-head">
          <h2>${esc(a.title)}</h2>
          ${badges.join(' ')}
        </div>
        <p class="sub">${esc(subtitleOf(cfg))} · ${esc(windowLabel(cfg))}</p>
        ${a.lastError ? `<div class="banner err">${esc(a.lastError)}</div>` : ''}
        ${slots || '<p class="muted" style="margin:6px 0 0">Aucun creneau pour le moment.</p>'}
        ${a.slotCount > a.hits.length ? `<p class="muted" style="margin:8px 0 0">+ ${a.slotCount - a.hits.length} autre(s)</p>` : ''}
        <p class="muted" style="margin:12px 0 0;font-size:12.5px">
          Verifie ${esc(ago(a.lastCheckedAt))}${a.enabled ? ` · prochaine ${esc(until(a.nextCheckAt))}` : ''}
        </p>
      </div>`;
  }).join('');

  box.querySelectorAll('.alert-card').forEach((el) => {
    el.addEventListener('click', () => openDetail(el.dataset.id));
  });
}

function subtitleOf(cfg) {
  if (cfg.kind === 'doctor') {
    const d = cfg.doctor;
    if (!d) return 'Praticien';
    return d.city ? `${d.displayName} — ${d.city}` : d.displayName;
  }
  const specs = cfg.specialities.map((s) => s.name).join(' · ');
  return specs ? `${specs} — ${cfg.place?.name ?? ''}` : (cfg.place?.name ?? '');
}

/**
 * Whether this alert's silent hours are running right now, in Paris time.
 *
 * Mirrors isQuietNow() on the server. Duplicated deliberately: the point is to
 * tell the user *before* they conclude push is broken, and asking the server
 * would mean an extra round trip on every render.
 */
function isQuietNow(cfg) {
  if (!cfg.quietEnabled) return false;
  if (cfg.quietFromHour === cfg.quietToHour) return false;
  const h = Number(new Intl.DateTimeFormat('fr-FR', {
    timeZone: 'Europe/Paris', hour: '2-digit', hour12: false,
  }).format(new Date())) % 24;
  return cfg.quietFromHour < cfg.quietToHour
    ? h >= cfg.quietFromHour && h < cfg.quietToHour
    : h >= cfg.quietFromHour || h < cfg.quietToHour;
}

function channelLabel(cfg) {
  const on = [];
  if (cfg.notifyPush) on.push('notification');
  if (cfg.notifyEmail) on.push('e-mail');
  return on.length ? on.join(' + ') : 'aucune notification';
}

function windowLabel(cfg) {
  if (cfg.mode === 'dateRange' && cfg.from && cfg.to) {
    return `${fmtShort.format(new Date(cfg.from)).slice(0, 5)} au ${fmtShort.format(new Date(cfg.to)).slice(0, 5)}`;
  }
  return cfg.horizonDays === 1 ? 'sous 24 h' : `sous ${cfg.horizonDays} jours`;
}

// ----------------------------------------------------------------- detail --

async function openDetail(id) {
  const { alert } = await api(`/alerts/${id}`);
  state.current = alert;
  // Highlighting is per visit: what was new the last time you looked at a
  // different alert should not glow here.
  state.freshIds = new Set();
  $('detail-title').textContent = alert.title;
  renderDetail();
  show('detail');
}

function renderDetail() {
  const a = state.current;
  const cfg = a.config;
  const snoozed = cfg.snoozedUntil && new Date(cfg.snoozedUntil) > new Date();

  const slots = a.hits.length === 0
    ? '<p class="muted">Aucun creneau ne correspond pour le moment.</p>'
    : a.hits.map((h) => `
      <div class="slot ${state.freshIds.has(`${h.doctorKey}|${h.when}`) ? 'fresh' : ''}">
        <div class="grow">
          <div class="when">${esc(fmtSlot.format(new Date(h.when)))}</div>
          <div class="who2">${esc(h.doctorName)}${h.city ? ` · ${esc(h.city)}` : ''}${h.telehealth ? ' · video' : ''}</div>
          ${h.motive ? `<div class="who2">${esc(h.motive)}</div>` : ''}
          ${h.distanceKm != null ? `<div class="who2">${h.distanceKm.toFixed(1)} km</div>` : ''}
        </div>
        <div class="row tight">
          <a href="${esc(h.bookingUrl)}" target="_blank" rel="noopener">
            <button class="small">Reserver</button></a>
          <button class="ghost small ign" data-kind="slot"
                  data-value="${esc(h.doctorKey)}|${esc(h.when)}" title="Masquer ce creneau">&times;</button>
        </div>
      </div>`).join('');

  const ignoredCount =
    cfg.ignoredSlots.length + cfg.ignoredDates.length + cfg.ignoredDoctors.length;

  const quiet = a.enabled && isQuietNow(cfg)
    ? `<div class="banner warn">
         <strong>Heures silencieuses en cours (${cfg.quietFromHour}h-${cfg.quietToHour}h).</strong>
         La surveillance continue et les creneaux trouves apparaissent ici, mais
         aucune notification ne partira avant ${cfg.quietToHour}h.
       </div>`
    : '';

  $('detail-body').innerHTML = `
    ${a.lastError ? `<div class="banner err">${esc(a.lastError)}</div>` : ''}
    ${quiet}
    <div class="card">
      <h2>${a.slotCount} creneau${a.slotCount > 1 ? 'x' : ''}</h2>
      <p class="sub">${esc(subtitleOf(cfg))} · ${esc(windowLabel(cfg))}</p>
      ${slots}
    </div>

    <div class="card">
      <div class="row">
        <button class="ghost" id="d-check">Verifier maintenant</button>
        <button class="ghost" id="d-toggle">${a.enabled ? 'Mettre en pause' : 'Reactiver'}</button>
        <button class="ghost" id="d-snooze">${snoozed ? 'Reveiller' : 'Veille 2 h'}</button>
      </div>
      <p class="muted" style="margin:12px 0 0">
        Verifiee ${esc(ago(a.lastCheckedAt))} · ${a.lastRequestCount} requete(s) au dernier passage
        · toutes les ${cfg.intervalMinutes} min · ${esc(channelLabel(cfg))}
      </p>
      <p class="muted" style="margin:6px 0 0;font-size:12.5px">
        « Verifier maintenant » n'envoie pas de notification : les resultats
        s'affichent ici. Les notifications viennent des verifications automatiques,
        et uniquement pour un creneau jamais encore annonce.
      </p>
    </div>

    ${ignoredCount ? `
    <div class="card">
      <h2>Masques</h2>
      <p class="sub">${ignoredCount} element(s) ecarte(s) de cette alerte.</p>
      <div class="chips">
        ${cfg.ignoredDoctors.map((d) => `<span class="chip">praticien <button class="unign" data-kind="doctor" data-value="${esc(d)}">&times;</button></span>`).join('')}
        ${cfg.ignoredDates.map((d) => `<span class="chip">${esc(d)} <button class="unign" data-kind="date" data-value="${esc(d)}">&times;</button></span>`).join('')}
        ${cfg.ignoredSlots.length ? `<span class="chip">${cfg.ignoredSlots.length} creneau(x)</span>` : ''}
      </div>
    </div>` : ''}

    <div class="card">
      <div class="row">
        <button class="ghost" id="d-edit">Modifier</button>
        <div class="spacer"></div>
        <button class="danger" id="d-delete">Supprimer</button>
      </div>
    </div>`;

  $('d-check').addEventListener('click', async (e) => {
    e.target.disabled = true;
    e.target.innerHTML = '<span class="spin"></span> Verification';
    try {
      const res = await api(`/alerts/${a.id}/check`, { method: 'POST' });
      state.current = res.alert;
      state.freshIds = new Set(res.fresh);
      if (res.deferred) toast('Budget de requetes epuise — reessayez dans quelques minutes.');
      else if (res.error) toast(res.error);
      else toast(res.fresh.length ? `${res.fresh.length} nouveau(x) creneau(x)` : 'Rien de nouveau');
      renderDetail();
      await loadAlerts();
    } catch (err) {
      toast(err.message);
      e.target.disabled = false;
      e.target.textContent = 'Verifier maintenant';
    }
  });

  $('d-toggle').addEventListener('click', async () => {
    const res = await api(`/alerts/${a.id}`, { method: 'PUT', body: { enabled: !a.enabled } });
    state.current = res.alert;
    renderDetail();
    await loadAlerts();
  });

  $('d-snooze').addEventListener('click', async () => {
    const res = await api(`/alerts/${a.id}/snooze`, {
      method: 'POST',
      body: { minutes: snoozed ? 0 : 120 },
    });
    state.current = res.alert;
    renderDetail();
    await loadAlerts();
  });

  $('d-edit').addEventListener('click', () => openEdit(a));

  $('d-delete').addEventListener('click', async () => {
    if (!confirm(`Supprimer « ${a.title} » ?`)) return;
    await api(`/alerts/${a.id}`, { method: 'DELETE' });
    await loadAlerts();
    show('list');
  });

  $('detail-body').querySelectorAll('.ign').forEach((b) => {
    b.addEventListener('click', async () => {
      const res = await api(`/alerts/${a.id}/ignore`, {
        method: 'POST',
        body: { kind: b.dataset.kind, value: b.dataset.value },
      });
      state.current = res.alert;
      renderDetail();
    });
  });

  $('detail-body').querySelectorAll('.unign').forEach((b) => {
    b.addEventListener('click', async () => {
      const res = await api(`/alerts/${a.id}/ignore`, {
        method: 'POST',
        body: { kind: b.dataset.kind, value: b.dataset.value, undo: true },
      });
      state.current = res.alert;
      renderDetail();
    });
  });
}

$('detail-back').addEventListener('click', () => { show('list'); loadAlerts(); });

// ------------------------------------------------------------------- edit --

const HOURS = Array.from({ length: 25 }, (_, i) => i);
const DAY_NAMES = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

function fillHourSelect(el, upto24) {
  el.innerHTML = HOURS.slice(0, upto24 ? 25 : 24)
    .map((h) => `<option value="${h}">${String(h).padStart(2, '0')}:00</option>`).join('');
}

fillHourSelect($('hour-from'), false);
fillHourSelect($('hour-to'), true);
fillHourSelect($('quiet-from'), false);
fillHourSelect($('quiet-to'), false);

$('daypick').innerHTML = DAY_NAMES
  .map((d, i) => `<button type="button" data-day="${i + 1}">${d}</button>`).join('');

async function openEdit(existing) {
  // Re-read the account before drawing the form: an admin may have added the
  // email address since this tab loaded, and a stale snapshot silently greys
  // out the email checkbox with no explanation.
  try {
    const me = await api('/auth/me');
    if (me.user) state.user = me.user;
    state.emailConfigured = me.emailConfigured;
    state.vapidKey = me.vapidPublicKey;
  } catch { /* keep whatever we already had */ }
  openEditForm(existing);
}

function openEditForm(existing) {
  state.draft = existing
    ? JSON.parse(JSON.stringify(existing.config))
    : {
        kind: 'speciality', specialities: [], place: null, zone: null, doctor: null,
        motiveIds: [], mode: 'nextDays', horizonDays: 3, from: null, to: null,
        alertStyle: 'normal', notifyPush: true, notifyEmail: false,
        onlyNewPatients: false, teleconsult: 'any',
        hourFrom: 0, hourTo: 24, weekdays: [1, 2, 3, 4, 5, 6, 7], maxDoctors: 40,
        intervalMinutes: 15, quietEnabled: true, quietFromHour: 22, quietToHour: 7,
        frugalMode: true, snoozedUntil: null,
        ignoredSlots: [], ignoredDates: [], ignoredDoctors: [],
      };
  state.draft._editingId = existing?.id ?? null;
  $('edit-heading').textContent = existing ? 'Modifier l\'alerte' : 'Nouvelle alerte';
  $('edit-title').value = existing?.title ?? '';
  $('edit-error').hidden = true;
  syncEditForm();
  show('edit');
}

function syncEditForm() {
  const d = state.draft;
  $('kind-spec').classList.toggle('on', d.kind === 'speciality');
  $('kind-doc').classList.toggle('on', d.kind === 'doctor');
  $('kind-spec').style.background = d.kind === 'speciality' ? 'var(--accent)' : '';
  $('kind-spec').style.color = d.kind === 'speciality' ? '#fff' : '';
  $('kind-doc').style.background = d.kind === 'doctor' ? 'var(--accent)' : '';
  $('kind-doc').style.color = d.kind === 'doctor' ? '#fff' : '';
  $('mode-spec').hidden = d.kind !== 'speciality';
  $('mode-doc').hidden = d.kind !== 'doctor';

  $('chips-spec').innerHTML = d.specialities.map((s, i) =>
    `<span class="chip on">${esc(s.name)} <button data-rm-spec="${i}">&times;</button></span>`).join('');
  $('chips-city').innerHTML = d.place
    ? `<span class="chip on">${esc(d.place.name)} <button data-rm-city="1">&times;</button></span>` : '';
  $('chips-doc').innerHTML = d.doctor
    ? `<span class="chip on">${esc(d.doctor.displayName)}${d.doctor.city ? ` · ${esc(d.doctor.city)}` : ''} <button data-rm-doc="1">&times;</button></span>` : '';

  $('chips-spec').querySelectorAll('[data-rm-spec]').forEach((b) =>
    b.addEventListener('click', () => {
      d.specialities.splice(Number(b.dataset.rmSpec), 1);
      syncEditForm();
    }));
  $('chips-city').querySelectorAll('[data-rm-city]').forEach((b) =>
    b.addEventListener('click', () => { d.place = null; syncEditForm(); }));
  $('chips-doc').querySelectorAll('[data-rm-doc]').forEach((b) =>
    b.addEventListener('click', () => {
      d.doctor = null; d.motiveIds = [];
      $('motive-box').hidden = true;
      syncEditForm();
    }));

  $('win-days').style.background = d.mode === 'nextDays' ? 'var(--accent)' : '';
  $('win-days').style.color = d.mode === 'nextDays' ? '#fff' : '';
  $('win-range').style.background = d.mode === 'dateRange' ? 'var(--accent)' : '';
  $('win-range').style.color = d.mode === 'dateRange' ? '#fff' : '';
  $('win-days-box').hidden = d.mode !== 'nextDays';
  $('win-range-box').hidden = d.mode !== 'dateRange';

  $('horizon').value = d.horizonDays;
  $('horizon-label').textContent = d.horizonDays === 1 ? '24 heures' : `${d.horizonDays} jours`;
  if (d.from) $('date-from').value = d.from.slice(0, 10);
  if (d.to) $('date-to').value = d.to.slice(0, 10);

  $('daypick').querySelectorAll('button').forEach((b) =>
    b.classList.toggle('on', d.weekdays.includes(Number(b.dataset.day))));

  $('hour-from').value = d.hourFrom;
  $('hour-to').value = d.hourTo;
  $('f-new').checked = d.onlyNewPatients;
  $('f-tele').value = d.teleconsult;
  $('f-style').value = d.alertStyle;
  $('f-interval').value = d.intervalMinutes;
  $('interval-label').textContent = d.intervalMinutes < 60
    ? `${d.intervalMinutes} min`
    : `${Math.round(d.intervalMinutes / 60)} h`;
  $('f-push').checked = d.notifyPush;
  $('f-email').checked = d.notifyEmail;
  syncChannels();

  $('f-quiet').checked = d.quietEnabled;
  $('quiet-box').hidden = !d.quietEnabled;
  $('quiet-from').value = d.quietFromHour;
  $('quiet-to').value = d.quietToHour;
}

$('kind-spec').addEventListener('click', () => { state.draft.kind = 'speciality'; syncEditForm(); });
$('kind-doc').addEventListener('click', () => { state.draft.kind = 'doctor'; syncEditForm(); });
$('win-days').addEventListener('click', () => { state.draft.mode = 'nextDays'; syncEditForm(); });
$('win-range').addEventListener('click', () => { state.draft.mode = 'dateRange'; syncEditForm(); });

$('horizon').addEventListener('input', (e) => {
  state.draft.horizonDays = Number(e.target.value);
  $('horizon-label').textContent =
    state.draft.horizonDays === 1 ? '24 heures' : `${state.draft.horizonDays} jours`;
});

$('f-interval').addEventListener('input', (e) => {
  state.draft.intervalMinutes = Number(e.target.value);
  $('interval-label').textContent = state.draft.intervalMinutes < 60
    ? `${state.draft.intervalMinutes} min`
    : `${Math.round(state.draft.intervalMinutes / 60)} h`;
});

$('daypick').addEventListener('click', (e) => {
  const b = e.target.closest('button');
  if (!b) return;
  const day = Number(b.dataset.day);
  const d = state.draft;
  d.weekdays = d.weekdays.includes(day)
    ? d.weekdays.filter((x) => x !== day)
    : [...d.weekdays, day];
  if (d.weekdays.length === 0) d.weekdays = [day];
  syncEditForm();
});

/**
 * Keeps the channel checkboxes honest about what will actually happen.
 *
 * Email can only be promised when the server has a sender configured and the
 * account has an address, so the box says why rather than silently doing
 * nothing. Both off is allowed, and means the alert stops being checked.
 */
function syncChannels() {
  const d = state.draft;
  const emailPossible =
    state.emailConfigured && Boolean(state.user?.email) && state.user?.emailAlerts !== false;
  $('f-email').disabled = !emailPossible;
  if (!emailPossible && d.notifyEmail) {
    d.notifyEmail = false;
    $('f-email').checked = false;
  }
  // Three things have to be true, and they fail in different places. Naming
  // the one that is missing saves a round trip through the administrator.
  $('f-email-hint').textContent = !state.emailConfigured
    ? "Le serveur n'a pas de cle Resend (RESEND_API_KEY) : l'envoi d'e-mails est desactive."
    : !state.user?.email
      ? "Aucune adresse enregistree sur votre compte — l'administrateur doit l'ajouter."
      : state.user?.emailAlerts === false
        ? "L'administrateur a desactive les e-mails pour votre compte."
        : `Un seul e-mail recapitulatif par verification, vers ${state.user.email}.`;
  $('f-silent-warn').hidden = d.notifyPush || d.notifyEmail;
}

$('f-push').addEventListener('change', (e) => {
  state.draft.notifyPush = e.target.checked;
  syncChannels();
});

$('f-email').addEventListener('change', (e) => {
  state.draft.notifyEmail = e.target.checked;
  syncChannels();
});

$('f-quiet').addEventListener('change', (e) => {
  state.draft.quietEnabled = e.target.checked;
  $('quiet-box').hidden = !e.target.checked;
});

for (const [id, key, num] of [
  ['hour-from', 'hourFrom', true], ['hour-to', 'hourTo', true],
  ['quiet-from', 'quietFromHour', true], ['quiet-to', 'quietToHour', true],
  ['f-tele', 'teleconsult', false], ['f-style', 'alertStyle', false],
]) {
  $(id).addEventListener('change', (e) => {
    state.draft[key] = num ? Number(e.target.value) : e.target.value;
  });
}

$('f-new').addEventListener('change', (e) => { state.draft.onlyNewPatients = e.target.checked; });
$('date-from').addEventListener('change', (e) => { state.draft.from = e.target.value || null; });
$('date-to').addEventListener('change', (e) => { state.draft.to = e.target.value || null; });

// --- autocompletes ---------------------------------------------------------

function wireSuggest(inputId, boxId, fetcher, render, pick) {
  const input = $(inputId);
  const box = $(boxId);
  const run = debounce(async () => {
    const q = input.value.trim();
    if (q.length < 2) { box.hidden = true; return; }
    box.innerHTML = '<div><span class="spin"></span> Recherche...</div>';
    box.hidden = false;
    try {
      const items = await fetcher(q);
      if (items.length === 0) {
        box.innerHTML = '<div class="muted">Aucun resultat</div>';
        return;
      }
      box.innerHTML = items.map((it, i) => `<div data-i="${i}">${render(it)}</div>`).join('');
      box.querySelectorAll('[data-i]').forEach((el) => {
        el.addEventListener('click', () => {
          pick(items[Number(el.dataset.i)]);
          box.hidden = true;
          input.value = '';
        });
      });
    } catch (err) {
      box.innerHTML = `<div class="muted">${esc(err.message)}</div>`;
    }
  });
  input.addEventListener('input', run);
}

wireSuggest('q-spec', 'sug-spec',
  async (q) => (await api(`/search/autocomplete?q=${encodeURIComponent(q)}`)).specialities,
  (s) => esc(s.name),
  (s) => {
    if (!state.draft.specialities.some((x) => x.slug === s.slug)) state.draft.specialities.push(s);
    syncEditForm();
  });

wireSuggest('q-city', 'sug-city',
  async (q) => (await api(`/search/places?q=${encodeURIComponent(q)}`)).places,
  (p) => `${esc(p.city)}<small>${esc(p.label)}</small>`,
  async (p) => {
    $('sug-city').hidden = false;
    $('sug-city').innerHTML = '<div><span class="spin"></span> Resolution de la ville...</div>';
    try {
      const spec = state.draft.specialities[0]?.slug ?? 'medecin-generaliste';
      const { place } = await api(
        `/search/resolve-place?city=${encodeURIComponent(p.city)}&spec=${encodeURIComponent(spec)}`);
      state.draft.place = place;
      $('sug-city').hidden = true;
      syncEditForm();
    } catch (err) {
      $('sug-city').innerHTML = `<div class="muted">${esc(err.message)}</div>`;
    }
  });

wireSuggest('q-doc', 'sug-doc',
  async (q) => (await api(`/search/autocomplete?q=${encodeURIComponent(q)}`)).profiles,
  (p) => `${esc(p.displayName)}<small>${esc(p.speciality)}${p.city ? ` · ${esc(p.city)}` : ''}</small>`,
  async (p) => {
    state.draft.doctor = {
      key: `profile-${p.profileId}`,
      profileId: Number(p.profileId) || 0,
      practiceId: 0,
      displayName: p.displayName,
      specialityName: p.speciality,
      city: p.city,
      address: '',
      link: p.link,
      agendaIds: [],
      visitMotiveId: null,
      visitMotiveName: '',
      allowNewPatients: true,
      telehealth: false,
      lat: null, lng: null,
    };
    state.draft.motiveIds = [];
    syncEditForm();
    await loadMotives(p.link);
  });

async function loadMotives(link) {
  const box = $('motive-list');
  $('motive-box').hidden = false;
  box.innerHTML = '<p class="muted"><span class="spin"></span> Chargement des motifs...</p>';
  try {
    const info = await api(`/search/motives?link=${encodeURIComponent(link)}`);
    const d = state.draft;
    // The funnel is the authoritative source for agendas and the practice, so
    // what came out of the search bar is upgraded here.
    if (info.practiceIds?.length) d.doctor.practiceId = info.practiceIds[0];
    if (info.speciality) d.doctor.specialityName = info.speciality;
    if (info.profileName) d.doctor.displayName = info.profileName;

    if (info.motives.length === 0) {
      box.innerHTML = '<p class="muted">Ce praticien ne propose pas de reservation en ligne.</p>';
      return;
    }
    box.innerHTML = info.motives.map((m) => `
      <label class="toggle">
        <input type="checkbox" value="${m.id}" ${d.motiveIds.includes(m.id) ? 'checked' : ''}>
        <span><span class="tt">${esc(m.name)}</span>
        <span class="td">${esc(m.categoryName)}${m.telehealth ? ' · teleconsultation' : ''}</span></span>
      </label>`).join('');
    box.querySelectorAll('input').forEach((cb) => {
      cb.addEventListener('change', () => {
        const id = Number(cb.value);
        d.motiveIds = cb.checked
          ? [...d.motiveIds, id]
          : d.motiveIds.filter((x) => x !== id);
      });
    });
    syncEditForm();
  } catch (err) {
    box.innerHTML = `<p class="banner err">${esc(err.message)}</p>`;
  }
}

// --- save ------------------------------------------------------------------

async function saveDraft() {
  const d = state.draft;
  const title = $('edit-title').value.trim()
    || (d.kind === 'doctor' ? (d.doctor?.displayName ?? 'Alerte') : subtitleOf(d))
    || 'Alerte';

  const { _editingId, ...config } = d;
  $('edit-error').hidden = true;
  $('edit-save').disabled = true;
  try {
    if (_editingId) await api(`/alerts/${_editingId}`, { method: 'PUT', body: { title, config } });
    else await api('/alerts', { method: 'POST', body: { title, config } });
    await loadAlerts();
    show('list');
    if (!config.notifyPush && !config.notifyEmail) {
      toast('Alerte enregistree en pause : aucun moyen de notification choisi.');
    } else {
      toast(_editingId ? 'Alerte modifiee' : 'Alerte creee — premiere verification en cours');
    }
  } catch (err) {
    $('edit-error').textContent = err.message;
    $('edit-error').hidden = false;
    window.scrollTo(0, 0);
  } finally {
    $('edit-save').disabled = false;
  }
}

$('edit-save').addEventListener('click', saveDraft);
$('btn-new').addEventListener('click', () => { openEdit(null); });
$('edit-cancel').addEventListener('click', () => show('list'));
$('edit-cancel-2').addEventListener('click', () => show('list'));

// --------------------------------------------------------------- settings --

$('btn-settings').addEventListener('click', async () => {
  show('settings');
  refreshPushState();
  $('email-toggle').checked = state.user.emailAlerts;
  $('email-state').textContent = !state.emailConfigured
    ? "L'envoi d'e-mails n'est pas configure sur ce serveur."
    : state.user.email
      ? `Les alertes partiront vers ${state.user.email}.`
      : "Aucune adresse enregistree — demandez a l'administrateur de l'ajouter.";
  $('email-toggle').disabled = !state.emailConfigured || !state.user.email;
  loadJournal();
});

$('settings-back').addEventListener('click', () => show('list'));

$('email-toggle').addEventListener('change', async (e) => {
  try {
    await api('/auth/email-alerts', { method: 'POST', body: { enabled: e.target.checked } });
    state.user.emailAlerts = e.target.checked;
    toast(e.target.checked ? 'E-mails actives' : 'E-mails desactives');
  } catch (err) {
    e.target.checked = !e.target.checked;
    toast(err.message);
  }
});

$('pw-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const msg = $('pw-msg');
  msg.hidden = true;
  try {
    await api('/auth/password', {
      method: 'POST',
      body: { current: $('pw-cur').value, next: $('pw-new').value },
    });
    msg.className = 'banner ok';
    msg.textContent = 'Mot de passe change. Les autres appareils ont ete deconnectes.';
    msg.hidden = false;
    e.target.reset();
    state.user.mustChange = false;
  } catch (err) {
    msg.className = 'banner err';
    msg.textContent = err.message;
    msg.hidden = false;
  }
});

async function loadJournal() {
  const { entries } = await api('/journal');
  $('journal').innerHTML = entries.length === 0
    ? '<p class="muted">Rien encore.</p>'
    : entries.slice(0, 30).map((e) => {
        const icon = e.kind === 'found' ? '&#9679;' : e.kind === 'error' ? '&#9888;' : '&#9675;';
        const color = e.kind === 'found' ? 'var(--accent)'
          : e.kind === 'error' ? 'var(--danger)' : 'var(--muted)';
        return `<div class="slot">
          <span style="color:${color}">${icon}</span>
          <div class="grow">
            <div class="who2"><strong>${esc(e.title)}</strong> — ${e.kind === 'found'
              ? `${e.slots} creneau(x)${e.fresh ? `, ${e.fresh} nouveau(x)` : ''}`
              : e.kind === 'error' ? 'erreur' : 'rien'}</div>
            ${e.detail ? `<div class="who2">${esc(e.detail)}</div>` : ''}
          </div>
          <span class="muted" style="font-size:12px">${esc(ago(e.at))}</span>
        </div>`;
      }).join('');
}

$('btn-test-email').addEventListener('click', async (e) => {
  const box = $('email-result');
  e.target.disabled = true;
  box.hidden = false;
  box.innerHTML = '<p class="muted"><span class="spin"></span> Envoi en cours...</p>';
  try {
    const res = await api('/email/test', { method: 'POST' });
    // "Accepted by the API" is not "arrived". Say which one this is, and hand
    // over the id needed to look up the other.
    box.innerHTML = `<div class="banner ok">
      <strong>Accepte par ${esc(res.provider || 'le fournisseur')}</strong>
      pour <strong>${esc(res.to)}</strong>, depuis ${esc(res.from)}.
      ${res.messageId ? `<br><span class="mono" style="font-size:12px">id ${esc(res.messageId)}</span>` : ''}
      <br><br>
      Accepte ne veut pas dire arrive. S'il ne vient pas :
      regardez les indesirables, verifiez que l'adresse ci-dessus est bien la votre,
      et ouvrez le journal d'envoi de ${esc(res.provider || 'votre fournisseur')}
      (Brevo : Transactional &rarr; Email &rarr; Logs) pour voir le statut reel.
    </div>
    ${res.note ? `<div class="banner warn" style="margin-top:8px">${esc(res.note)}</div>` : ''}`;
  } catch (err) {
    // Resend's refusals name the actual problem, so they are shown verbatim
    // rather than replaced by something reassuring and useless.
    const extra = err.hint ? `<br><br>${esc(err.hint)}` : '';
    box.innerHTML = `<div class="banner err">${esc(err.message)}${extra}</div>`;
  } finally {
    e.target.disabled = false;
  }
});

// ------------------------------------------------------------------- push --

function isIOS() {
  return /iPad|iPhone|iPod/.test(navigator.userAgent) ||
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
}

function isStandalone() {
  return window.matchMedia('(display-mode: standalone)').matches ||
    window.navigator.standalone === true;
}

async function registerServiceWorker() {
  if (!('serviceWorker' in navigator)) return;
  try {
    await navigator.serviceWorker.register('/sw.js');
  } catch (e) {
    console.warn('service worker', e);
  }
  checkPushBanner();
}

async function checkPushBanner() {
  const banner = $('push-banner');
  if (!('Notification' in window)) { banner.hidden = true; return; }

  // The one case worth interrupting for: on iOS, push is simply unavailable
  // until the site is installed, and nothing in the UI hints at that.
  if (isIOS() && !isStandalone()) {
    banner.innerHTML = 'Sur iPhone, les notifications exigent d\'ajouter ce site a l\'ecran ' +
      'd\'accueil : menu Partager de Safari &rarr; « Sur l\'ecran d\'accueil ».';
    banner.hidden = false;
    return;
  }
  if (Notification.permission !== 'granted') {
    banner.innerHTML = 'Les notifications ne sont pas activees. ' +
      '<button class="link" id="banner-push">Activer maintenant</button>';
    banner.hidden = false;
    $('banner-push')?.addEventListener('click', enablePush);
    return;
  }
  banner.hidden = true;
}

async function refreshPushState() {
  const el = $('push-state');
  $('ios-hint').hidden = !(isIOS() && !isStandalone());

  if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
    el.textContent = 'Ce navigateur ne gere pas les notifications push.';
    $('btn-enable-push').disabled = true;
    return;
  }
  if (!state.vapidKey) {
    el.textContent = "Le serveur n'a pas de cles VAPID configurees.";
    $('btn-enable-push').disabled = true;
    return;
  }
  const reg = await navigator.serviceWorker.getRegistration();
  const sub = await reg?.pushManager.getSubscription();
  if (Notification.permission === 'denied') {
    el.textContent = 'Notifications bloquees pour ce site. Autorisez-les dans les reglages du navigateur.';
  } else if (sub) {
    el.textContent = 'Actives sur cet appareil.';
    $('btn-enable-push').textContent = 'Reactiver';
  } else {
    el.textContent = 'Pas encore activees sur cet appareil.';
  }
}

function urlBase64ToUint8Array(base64) {
  const padded = (base64 + '='.repeat((4 - (base64.length % 4)) % 4))
    .replace(/-/g, '+').replace(/_/g, '/');
  const raw = atob(padded);
  return Uint8Array.from([...raw].map((c) => c.charCodeAt(0)));
}

async function enablePush() {
  try {
    if (isIOS() && !isStandalone()) {
      toast("Ajoutez d'abord le site a l'ecran d'accueil.");
      return;
    }
    const perm = await Notification.requestPermission();
    if (perm !== 'granted') { toast('Permission refusee.'); return; }

    const reg = await navigator.serviceWorker.ready;
    let sub = await reg.pushManager.getSubscription();
    if (sub) await sub.unsubscribe();
    sub = await reg.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(state.vapidKey),
    });

    const json = sub.toJSON();
    await api('/push/subscribe', {
      method: 'POST',
      body: {
        endpoint: json.endpoint,
        keys: json.keys,
        label: navigator.userAgent.slice(0, 60),
      },
    });
    toast('Notifications activees.');
    refreshPushState();
    checkPushBanner();
  } catch (err) {
    toast(`Echec : ${err.message}`);
  }
}

/**
 * Why a notification did not arrive.
 *
 * Push has four independent failure points and the browser reports none of
 * them to the page: permission, a registered service worker, a subscription
 * in that worker, and a matching row on the server. Three of the four look
 * identical from the outside ("nothing happens"), so each one is checked and
 * named separately.
 */
$('btn-push-diag').addEventListener('click', async (e) => {
  const box = $('push-diag');
  e.target.disabled = true;
  box.hidden = false;
  box.innerHTML = '<p class="muted"><span class="spin"></span> Verification...</p>';

  const checks = [];
  const add = (ok, label, detail = '') => checks.push({ ok, label, detail });

  try {
    add('serviceWorker' in navigator, 'Service worker supporte par le navigateur');
    add('PushManager' in window, 'API Push supportee');
    add(window.isSecureContext, 'Contexte securise (HTTPS)');

    const standalone = isStandalone();
    if (isIOS()) {
      add(standalone, "Installe sur l'ecran d'accueil",
        standalone ? '' : "Obligatoire sur iPhone pour recevoir des notifications.");
    }

    add(Notification.permission === 'granted',
      `Permission du navigateur : ${Notification.permission}`,
      Notification.permission === 'denied'
        ? "Bloquee. Cliquez sur le cadenas dans la barre d'adresse pour la reautoriser."
        : Notification.permission === 'default'
          ? "Jamais demandee. Cliquez sur « Activer sur cet appareil »."
          : '');

    const reg = await navigator.serviceWorker.getRegistration();
    add(Boolean(reg), 'Service worker enregistre',
      reg ? `portee ${reg.scope}` : 'Rechargez la page.');

    const sub = reg ? await reg.pushManager.getSubscription() : null;
    add(Boolean(sub), 'Abonnement push dans ce navigateur',
      sub ? sub.endpoint.slice(0, 60) + '...' : "Cliquez sur « Activer sur cet appareil ».");

    add(Boolean(state.vapidKey), 'Cle VAPID publique recue du serveur',
      state.vapidKey ? '' : "Le serveur n'a pas de cles VAPID configurees.");

    // The subscription can exist in the browser and be missing on the server,
    // which is the one failure the browser will never tell you about.
    const { subscriptions } = await api('/push/subscriptions');
    add(subscriptions.length > 0,
      `Appareils connus du serveur : ${subscriptions.length}`,
      subscriptions.length === 0
        ? "Le navigateur a un abonnement mais le serveur ne l'a pas : reactivez."
        : subscriptions.map((s) => `${s.label || 'appareil'} · ${s.fail_count} echec(s)`).join(' | '));

    // Fire a notification locally, bypassing the server entirely. If this one
    // shows and a pushed one does not, the problem is delivery, not display.
    if (reg && Notification.permission === 'granted') {
      await reg.showNotification('Test local', {
        body: 'Affichee par le navigateur, sans passer par le serveur.',
        icon: '/icon-192.png',
        tag: 'local-test',
      });
      add(true, 'Notification locale affichee',
        "Si vous ne la voyez pas a l'ecran, le systeme la masque (mode Concentration, Ne pas deranger, notifications Chrome desactivees dans Windows).");
    }
  } catch (err) {
    add(false, 'Erreur pendant le diagnostic', String(err));
  }

  box.innerHTML = checks.map((c) => `
    <div class="slot">
      <span style="color:${c.ok ? 'var(--accent)' : 'var(--danger)'}">
        ${c.ok ? '&#10003;' : '&#10007;'}</span>
      <div class="grow">
        <div class="who2">${esc(c.label)}</div>
        ${c.detail ? `<div class="who2 muted" style="font-size:12px">${esc(c.detail)}</div>` : ''}
      </div>
    </div>`).join('');

  e.target.disabled = false;
});

$('btn-enable-push').addEventListener('click', enablePush);

$('btn-test-push').addEventListener('click', async (e) => {
  const box = $('push-diag');
  e.target.disabled = true;
  box.hidden = false;
  box.innerHTML = '<p class="muted"><span class="spin"></span> Envoi en cours...</p>';
  try {
    const res = await api('/push/test', { method: 'POST' });
    if (res.sent > 0) {
      box.innerHTML = `<div class="banner ok">
        Envoye a ${res.sent} appareil(s). Le service de push l'a accepte.<br>
        Si rien n'apparait a l'ecran dans les secondes qui suivent, c'est le
        systeme qui la masque : Assistant de concentration ou Ne pas deranger
        sous Windows, ou les notifications de Chrome desactivees dans les
        parametres Windows.
      </div>`;
    } else if (res.failed > 0) {
      box.innerHTML = `<div class="banner err">
        Refuse par le service de push.<br>
        <span class="mono" style="font-size:12px">${esc((res.failures || []).join(' | '))}</span>
      </div>`;
    } else {
      box.innerHTML = `<div class="banner warn">${esc(res.message || 'Aucun appareil abonne.')}</div>`;
    }
  } catch (err) {
    box.innerHTML = `<div class="banner err">${esc(err.message)}</div>`;
  } finally {
    e.target.disabled = false;
  }
});

// ------------------------------------------------------------------- boot --

(async function boot() {
  try {
    const me = await api('/auth/me');
    if (me.user) {
      state.user = me.user;
      state.vapidKey = me.vapidPublicKey;
      state.emailConfigured = me.emailConfigured;
      $('who').textContent = me.user.username;
      $('admin-link').hidden = !me.user.isAdmin;
      await loadAlerts();
      show('list');
      registerServiceWorker();
    } else {
      show('login');
    }
  } catch {
    show('login');
  }
})();
