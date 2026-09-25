/* Administration panel. Same conventions as app.js: no framework, no build. */

const $ = (id) => document.getElementById(id);

let editingUserId = null;

async function api(path, opts = {}) {
  const res = await fetch(`/api${path}`, {
    credentials: 'same-origin',
    headers: opts.body ? { 'Content-Type': 'application/json' } : {},
    ...opts,
    body: opts.body ? JSON.stringify(opts.body) : undefined,
  });
  let data = {};
  try { data = await res.json(); } catch { /* empty body */ }
  if (!res.ok) {
    const err = new Error(data.error || `Erreur ${res.status}`);
    err.status = res.status;
    throw err;
  }
  return data;
}

function esc(s) {
  return String(s ?? '').replace(/[&<>"']/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
}

function ago(iso) {
  if (!iso) return '—';
  const mins = Math.round((Date.now() - new Date(iso)) / 60000);
  if (mins < 1) return "a l'instant";
  if (mins < 60) return `il y a ${mins} min`;
  const h = Math.round(mins / 60);
  if (h < 24) return `il y a ${h} h`;
  return `il y a ${Math.round(h / 24)} j`;
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
  toastTimer = setTimeout(() => el.remove(), 3500);
}

// -------------------------------------------------------------- overview --

async function loadStatus() {
  const s = await api('/admin/status');
  const g = s.guard;
  const pct = Math.round((g.requestsToday / g.maxPerDay) * 100);

  $('status-sub').textContent =
    `${g.requestsToday} / ${g.maxPerDay} requetes Doctolib aujourd'hui (${pct} %).`;

  $('status-chips').innerHTML = [
    `<span class="chip">${s.counts.users} compte(s)</span>`,
    `<span class="chip">${s.counts.active_alerts} / ${s.counts.alerts} alertes actives</span>`,
    `<span class="chip">${s.counts.subs} navigateur(s) abonne(s)</span>`,
    s.config.pushConfigured
      ? '<span class="chip on">push configure</span>'
      : '<span class="chip bad">push non configure</span>',
    s.config.emailConfigured
      ? '<span class="chip on">e-mail configure</span>'
      : '<span class="chip">e-mail non configure</span>',
    s.config.bootstrapOpen
      ? '<span class="chip bad">ADMIN_BOOTSTRAP encore actif</span>'
      : '',
  ].join(' ');

  const warn = $('guard-warn');
  if (g.pausedUntil) {
    warn.textContent = g.message || 'Surveillance en pause.';
    warn.hidden = false;
    $('btn-clear-pause').hidden = false;
  } else if (pct > 85) {
    warn.textContent = 'Le budget quotidien est presque epuise : augmentez MAX_REQUESTS_PER_DAY, '
      + 'espacez les alertes, ou attendez demain.';
    warn.hidden = false;
    $('btn-clear-pause').hidden = true;
  } else {
    warn.hidden = true;
    $('btn-clear-pause').hidden = true;
  }

  $('recent').innerHTML = s.recent.length === 0
    ? '<p class="muted">Rien encore. La verification tourne toutes les 5 minutes.</p>'
    : s.recent.map((e) => {
        const color = e.kind === 'found' ? 'var(--accent)'
          : e.kind === 'error' ? 'var(--danger)' : 'var(--muted)';
        const icon = e.kind === 'found' ? '&#9679;' : e.kind === 'error' ? '&#9888;' : '&#9675;';
        return `<div class="slot">
          <span style="color:${color}">${icon}</span>
          <div class="grow">
            <div class="who2"><strong>${esc(e.title)}</strong>
              <span class="muted">· ${esc(e.username ?? '?')}</span></div>
            <div class="who2">${e.kind === 'found'
              ? `${e.slots} creneau(x)${e.fresh ? `, ${e.fresh} nouveau(x)` : ''}`
              : e.kind === 'error' ? 'erreur' : 'rien'} · ${e.requests} requete(s)</div>
            ${e.detail ? `<div class="who2 muted">${esc(e.detail)}</div>` : ''}
          </div>
          <span class="muted" style="font-size:12px;white-space:nowrap">${esc(ago(e.at))}</span>
        </div>`;
      }).join('');
}

$('btn-refresh').addEventListener('click', loadAll);

$('btn-diagnose').addEventListener('click', async (e) => {
  const box = $('diag');
  e.target.disabled = true;
  box.hidden = false;
  box.innerHTML = '<p class="muted"><span class="spin"></span> Test en cours...</p>';
  try {
    const d = await api('/admin/diagnose');
    const fromFrance = d.egress.country === 'FR';
    const rows = Object.entries(d.probes).map(([name, p]) => `
      <div class="slot">
        <span style="color:${p.ok ? 'var(--accent)' : 'var(--danger)'}">
          ${p.ok ? '&#9679;' : '&#9888;'}</span>
        <div class="grow">
          <div class="who2"><strong>${esc(name)}</strong> — HTTP ${p.status} · ${p.ms} ms</div>
          ${p.error ? `<div class="who2 muted">${esc(p.error)}</div>` : ''}
          ${p.cfMitigated ? `<div class="who2 muted">cf-mitigated: ${esc(p.cfMitigated)}</div>` : ''}
          ${p.preview ? `<div class="who2 muted mono" style="font-size:11.5px">${esc(p.preview)}</div>` : ''}
        </div>
      </div>`).join('');

    const refused = Object.values(d.probes).some((p) => p.status === 403 || p.status === 429);

    const guard = d.guard.lastBlockMessage
      ? `<div class="banner err">
           <strong>Dernier blocage enregistre :</strong> ${esc(d.guard.lastBlockMessage)}<br>
           ${d.guard.consecutiveBlocks} blocage(s) d'affilee${
             d.guard.pausedUntil ? ` · en pause jusqu'a ${esc(d.guard.pausedUntil)}` : ' · plus en pause'
           }
         </div>`
      : '';

    const errs = (d.recentErrors ?? []).length
      ? `<div class="card tight" style="margin:12px 0;background:var(--surface-2)">
           <div class="muted" style="font-size:12px;margin-bottom:6px">Dernieres erreurs des alertes</div>
           ${d.recentErrors.map((e) => `
             <div class="who2" style="font-size:12.5px">
               <strong>${esc(e.title)}</strong> — ${esc(e.detail ?? '')}
             </div>`).join('')}
         </div>`
      : '';

    box.innerHTML = `
      <div class="banner ${refused ? 'err' : fromFrance ? 'ok' : 'warn'}">
        <strong>${esc(d.reading)}</strong><br>
        IP de sortie ${esc(d.egress.ip ?? '?')} · pays ${esc(d.egress.country ?? '?')}
        · datacentre ${esc(d.egress.colo ?? '?')}
      </div>
      ${guard}
      ${errs}
      ${rows}`;
  } catch (err) {
    box.innerHTML = `<div class="banner err">${esc(err.message)}</div>`;
  } finally {
    e.target.disabled = false;
  }
});

$('btn-clear-pause').addEventListener('click', async () => {
  await api('/admin/clear-pause', { method: 'POST' });
  toast('Pause levee.');
  loadStatus();
});

// ----------------------------------------------------------------- users --

async function loadUsers() {
  const { users } = await api('/admin/users');
  $('users-body').innerHTML = users.map((u) => `
    <tr data-id="${esc(u.id)}">
      <td>
        <strong>${esc(u.username)}</strong>
        ${u.isAdmin ? '<span class="chip on" style="margin-left:6px">admin</span>' : ''}
        ${!u.active ? '<span class="chip bad" style="margin-left:6px">desactive</span>' : ''}
        ${u.mustChange ? '<span class="chip warn" style="margin-left:6px">mdp a changer</span>' : ''}
      </td>
      <td>
        ${u.email ? esc(u.email) : '<span class="muted">—</span>'}
        ${u.emailAlerts ? '<span class="chip on" style="margin-left:6px">mails on</span>' : ''}
      </td>
      <td>${u.alertCount} · ${u.pushCount} appareil(s)</td>
      <td class="muted">${esc(ago(u.lastLoginAt))}</td>
      <td>
        <div class="row tight">
          <button class="ghost small act" data-act="edit">Modifier</button>
          <button class="ghost small act" data-act="pass">Mot de passe</button>
          <button class="ghost small act" data-act="toggle">${u.active ? 'Desactiver' : 'Activer'}</button>
          <button class="ghost small act" data-act="del" style="color:var(--danger)">Suppr.</button>
        </div>
      </td>
    </tr>`).join('');

  $('users-body').querySelectorAll('.act').forEach((b) => {
    b.addEventListener('click', () => {
      const id = b.closest('tr').dataset.id;
      const u = users.find((x) => x.id === id);
      if (b.dataset.act === 'edit') openUserDialog(u);
      if (b.dataset.act === 'pass') resetPassword(u);
      if (b.dataset.act === 'toggle') toggleUser(u);
      if (b.dataset.act === 'del') deleteUser(u);
    });
  });
}

function openUserDialog(user) {
  editingUserId = user?.id ?? null;
  $('dlg-user-title').textContent = user ? `Modifier ${user.username}` : 'Nouvel utilisateur';
  $('dlg-user-sub').textContent = user
    ? "L'identifiant ne peut pas changer."
    : 'Le mot de passe est genere et affiche une seule fois.';
  $('field-username').hidden = Boolean(user);
  $('u-name').required = !user;
  $('u-name').value = user?.username ?? '';
  $('u-email').value = user?.email ?? '';
  $('u-mail-alerts').checked = user?.emailAlerts ?? false;
  $('u-admin').checked = user?.isAdmin ?? false;
  $('dlg-user-save').textContent = user ? 'Enregistrer' : 'Creer';
  $('dlg-user-error').hidden = true;
  $('dlg-user').showModal();
}

$('btn-add-user').addEventListener('click', () => openUserDialog(null));
$('dlg-user-cancel').addEventListener('click', () => $('dlg-user').close());

$('dlg-user-save').addEventListener('click', async () => {
  const errBox = $('dlg-user-error');
  errBox.hidden = true;
  const body = {
    email: $('u-email').value.trim(),
    emailAlerts: $('u-mail-alerts').checked,
    isAdmin: $('u-admin').checked,
  };
  try {
    if (editingUserId) {
      await api(`/admin/users/${editingUserId}`, { method: 'PATCH', body });
      $('dlg-user').close();
      toast('Compte modifie.');
    } else {
      const username = $('u-name').value.trim();
      if (!/^[a-zA-Z0-9._-]{3,64}$/.test(username)) {
        throw new Error('Identifiant : 3 a 64 caracteres, lettres, chiffres, . _ - uniquement.');
      }
      const res = await api('/admin/users', { method: 'POST', body: { ...body, username } });
      $('dlg-user').close();
      showPassword(res.username, res.password);
    }
    await loadAll();
  } catch (err) {
    errBox.textContent = err.message;
    errBox.hidden = false;
  }
});

async function resetPassword(u) {
  if (!confirm(`Generer un nouveau mot de passe pour ${u.username} ?\n\n`
    + 'Toutes ses sessions seront fermees.')) return;
  const res = await api(`/admin/users/${u.id}/password`, { method: 'POST', body: {} });
  showPassword(res.username, res.password);
  await loadUsers();
}

async function toggleUser(u) {
  try {
    await api(`/admin/users/${u.id}`, { method: 'PATCH', body: { active: !u.active } });
    toast(u.active ? 'Compte desactive.' : 'Compte reactive.');
    await loadUsers();
  } catch (err) {
    toast(err.message);
  }
}

async function deleteUser(u) {
  if (!confirm(`Supprimer definitivement ${u.username} ?\n\n`
    + `Ses ${u.alertCount} alerte(s) et son historique seront effaces.`)) return;
  try {
    await api(`/admin/users/${u.id}`, { method: 'DELETE' });
    toast('Compte supprime.');
    await loadAll();
  } catch (err) {
    toast(err.message);
  }
}

function showPassword(username, password) {
  $('pass-user').textContent = username;
  $('pass-value').textContent = password;
  $('dlg-pass').showModal();
}

$('pass-close').addEventListener('click', () => $('dlg-pass').close());
$('pass-copy').addEventListener('click', async () => {
  try {
    await navigator.clipboard.writeText($('pass-value').textContent);
    toast('Copie.');
  } catch {
    toast('Copie impossible — selectionnez le texte.');
  }
});

// ---------------------------------------------------------------- alerts --

async function loadAlerts() {
  const { alerts } = await api('/admin/alerts');
  $('alerts-body').innerHTML = alerts.length === 0
    ? '<tr><td colspan="5" class="muted">Aucune alerte.</td></tr>'
    : alerts.map((a) => `
      <tr data-id="${esc(a.id)}">
        <td>
          <strong>${esc(a.title)}</strong>
          <div class="muted" style="font-size:12.5px">${esc(a.subtitle)}</div>
        </td>
        <td>${esc(a.username)}</td>
        <td>${a.intervalMinutes} min</td>
        <td>
          ${a.enabled ? '' : '<span class="chip">en pause</span>'}
          ${a.lastError ? '<span class="chip bad">erreur</span>' : ''}
          ${a.slotCount > 0 ? `<span class="chip on">${a.slotCount}</span>` : ''}
          <div class="muted" style="font-size:12px">${esc(ago(a.lastCheckedAt))}</div>
        </td>
        <td>
          <div class="row tight">
            <button class="ghost small aact" data-act="toggle">${a.enabled ? 'Pause' : 'Activer'}</button>
            <button class="ghost small aact" data-act="del" style="color:var(--danger)">Suppr.</button>
          </div>
        </td>
      </tr>`).join('');

  $('alerts-body').querySelectorAll('.aact').forEach((b) => {
    b.addEventListener('click', async () => {
      const id = b.closest('tr').dataset.id;
      const a = alerts.find((x) => x.id === id);
      if (b.dataset.act === 'toggle') {
        await api(`/admin/alerts/${id}`, { method: 'PATCH', body: { enabled: !a.enabled } });
      } else {
        if (!confirm(`Supprimer l'alerte « ${a.title} » de ${a.username} ?`)) return;
        await api(`/admin/alerts/${id}`, { method: 'DELETE' });
      }
      await loadAll();
    });
  });
}

// ------------------------------------------------------------------ boot --

async function loadAll() {
  await Promise.all([loadStatus(), loadUsers(), loadAlerts()]);
}

(async function boot() {
  try {
    const me = await api('/auth/me');
    if (!me.user) {
      $('denied-msg').textContent = 'Connectez-vous depuis la page principale.';
      $('denied').hidden = false;
      return;
    }
    if (!me.user.isAdmin) {
      $('denied').hidden = false;
      return;
    }
    $('who').textContent = me.user.username;
    $('panel').hidden = false;
    await loadAll();
  } catch (err) {
    $('denied-msg').textContent = err.message;
    $('denied').hidden = false;
  }
})();
