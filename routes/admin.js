const express = require('express');
const crypto = require('node:crypto');
const bcrypt = require('bcryptjs');
const db = require('../db');

const router = express.Router();
router.use(express.urlencoded({ extended: false }));

// ── Auth ────────────────────────────────────────────────────────────────────

function requireLogin(req, res, next) {
  if (req.session?.admin) return next();
  res.redirect('/admin/login');
}

// GET /admin/login
router.get('/login', (req, res) => {
  if (req.session?.admin) return res.redirect('/admin');
  res.type('html').send(loginPage());
});

// POST /admin/login
router.post('/login', (req, res) => {
  const { username, password } = req.body || {};
  const validUser = process.env.ADMIN_USER;
  const validPass = process.env.ADMIN_PASSWORD;
  if (!validUser || !validPass)
    return res.type('html').send(loginPage('ADMIN_USER en ADMIN_PASSWORD zijn niet ingesteld.'));
  if (username === validUser && password === validPass) {
    req.session.admin = true;
    return res.redirect('/admin');
  }
  res.type('html').send(loginPage('Onjuiste gebruikersnaam of wachtwoord.'));
});

// POST /admin/logout
router.post('/logout', (req, res) => {
  req.session.destroy(() => res.redirect('/admin/login'));
});

// ── Dashboard (org overview) ────────────────────────────────────────────────

// GET /admin
router.get('/', requireLogin, async (req, res, next) => {
  try {
    const { rows } = await db.query(`
      SELECT o.*,
             COUNT(u.id)::int AS user_count,
             COUNT(u.id) FILTER (WHERE EXISTS (
               SELECT 1 FROM inbox_judgments j WHERE j.org_user_id = u.id
             ))::int AS active_count
      FROM organisations o
      LEFT JOIN org_users u ON u.org_id = o.id
      GROUP BY o.id ORDER BY o.created_at DESC
    `);
    res.type('html').send(overviewPage(rows));
  } catch (err) { next(err); }
});

// ── Org management ──────────────────────────────────────────────────────────

const ALL_LOCALES    = ['nl', 'nl-BE', 'en', 'fr', 'fr-BE', 'de'];
const ALL_AUDIENCES  = ['personal', 'business'];
const ALL_DIFFICULTIES = ['normal', 'advanced'];

function parseArray(body, key, allowed) {
  const val = body[key];
  if (!val) return [];
  const arr = Array.isArray(val) ? val : [val];
  return arr.filter(v => allowed.includes(v));
}

// GET /admin/orgs/new
router.get('/orgs/new', requireLogin, (_req, res) => {
  res.type('html').send(orgFormPage());
});

// POST /admin/orgs
router.post('/orgs', requireLogin, async (req, res, next) => {
  try {
    const { name, slug, max_users, valid_until } = req.body || {};
    const locales     = parseArray(req.body, 'locales', ALL_LOCALES);
    const audiences   = parseArray(req.body, 'audiences', ALL_AUDIENCES);
    const difficulties = parseArray(req.body, 'difficulties', ALL_DIFFICULTIES);

    if (!name || !slug || !valid_until)
      return res.type('html').send(orgFormPage('Naam, slug en geldigheidsdatum zijn verplicht.'));
    if (!/^[a-z0-9-]+$/.test(slug))
      return res.type('html').send(orgFormPage('Slug mag alleen kleine letters, cijfers en koppeltekens bevatten.'));
    if (locales.length === 0 || audiences.length === 0 || difficulties.length === 0)
      return res.type('html').send(orgFormPage('Selecteer minimaal één taal, één doelgroep en één moeilijkheidsgraad.'));

    const admin_token = crypto.randomBytes(24).toString('hex');
    const maxU = Math.max(1, Math.min(5000, parseInt(max_users, 10) || 50));

    const { rows } = await db.query(
      `INSERT INTO organisations (name, slug, locales, audiences, difficulties, max_users, valid_until, admin_token)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id`,
      [name.trim(), slug.trim(), locales, audiences, difficulties, maxU, valid_until, admin_token]
    );
    res.redirect(`/admin/orgs/${rows[0].id}`);
  } catch (err) {
    if (err.code === '23505') return res.type('html').send(orgFormPage('Deze slug is al in gebruik.'));
    next(err);
  }
});

// GET /admin/orgs/:id
router.get('/orgs/:id', requireLogin, async (req, res, next) => {
  try {
    const { rows: [org] } = await db.query(`SELECT * FROM organisations WHERE id = $1`, [req.params.id]);
    if (!org) return res.status(404).type('html').send('<h1>Niet gevonden</h1>');

    const { rows: users } = await db.query(`
      SELECT u.id, u.numeric_id, u.allow_retrain, u.created_at,
             COUNT(DISTINCT j.message_id)::int AS done_count
      FROM org_users u
      LEFT JOIN inbox_judgments j ON j.org_user_id = u.id
      WHERE u.org_id = $1
      GROUP BY u.id ORDER BY u.numeric_id
    `, [org.id]);

    res.type('html').send(orgDetailPage(org, users));
  } catch (err) { next(err); }
});

// POST /admin/orgs/:id — update settings
router.post('/orgs/:id', requireLogin, async (req, res, next) => {
  try {
    const { rows: [org] } = await db.query(`SELECT * FROM organisations WHERE id = $1`, [req.params.id]);
    if (!org) return res.status(404).end();

    const { valid_until, max_users } = req.body || {};
    const locales     = parseArray(req.body, 'locales', ALL_LOCALES);
    const audiences   = parseArray(req.body, 'audiences', ALL_AUDIENCES);
    const difficulties = parseArray(req.body, 'difficulties', ALL_DIFFICULTIES);

    if (locales.length === 0 || audiences.length === 0 || difficulties.length === 0)
      return res.redirect(`/admin/orgs/${org.id}?err=Selecteer+minimaal+%C3%A9%C3%A9n+optie+per+categorie.`);

    await db.query(
      `UPDATE organisations SET locales=$1, audiences=$2, difficulties=$3, valid_until=$4, max_users=$5 WHERE id=$6`,
      [locales, audiences, difficulties, valid_until || org.valid_until,
       Math.max(1, Math.min(5000, parseInt(max_users, 10) || org.max_users)), org.id]
    );
    res.redirect(`/admin/orgs/${org.id}`);
  } catch (err) { next(err); }
});

// POST /admin/orgs/:id/generate
router.post('/orgs/:id/generate', requireLogin, async (req, res, next) => {
  try {
    const { rows: [org] } = await db.query(`SELECT * FROM organisations WHERE id = $1`, [req.params.id]);
    if (!org) return res.status(404).end();

    const count = Math.max(1, Math.min(500, parseInt(req.body.count, 10) || 10));
    const { rows: [maxRow] } = await db.query(
      `SELECT COALESCE(MAX(numeric_id::int), 0)::int AS maxid FROM org_users WHERE org_id = $1`, [org.id]
    );
    const startId = maxRow.maxid + 1;
    const lines = ['ID,Pincode'];

    for (let i = 0; i < count; i++) {
      const numericId = String(startId + i).padStart(5, '0');
      const pin = String(crypto.randomInt(0, 10000)).padStart(4, '0');
      const hash = await bcrypt.hash(pin, 10);
      await db.query(
        `INSERT INTO org_users (org_id, numeric_id, pincode_hash) VALUES ($1,$2,$3) ON CONFLICT DO NOTHING`,
        [org.id, numericId, hash]
      );
      lines.push(`${numericId},${pin}`);
    }

    res.set('Content-Disposition', `attachment; filename="${org.slug}-credentials.csv"`)
       .type('text/csv').send(lines.join('\r\n'));
  } catch (err) { next(err); }
});

// ── HTML helpers ────────────────────────────────────────────────────────────

function e(s) {
  return String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

const css = `
  *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
  body{font-family:system-ui,sans-serif;background:#f4f6f9;color:#1a1a2e;padding:2rem 1rem}
  .wrap{max-width:900px;margin:0 auto}
  .topbar{display:flex;justify-content:space-between;align-items:center;margin-bottom:1.5rem;flex-wrap:wrap;gap:.75rem}
  h1{font-size:1.25rem} h2{font-size:1rem;color:#374151;margin-bottom:1rem}
  a{color:#2563eb}
  .btn{display:inline-block;padding:.4rem .9rem;background:#2563eb;color:#fff;text-decoration:none;
       border-radius:6px;font-size:.9rem;border:none;cursor:pointer;font-weight:500}
  .btn:hover{background:#1d4ed8}
  .btn-sec{background:#e5e7eb;color:#374151}
  .btn-sec:hover{background:#d1d5db}
  .btn-sm{padding:.25rem .6rem;font-size:.8rem;border-radius:5px}
  .section{background:#fff;border-radius:10px;box-shadow:0 2px 10px rgba(0,0,0,.07);padding:1.5rem;margin-bottom:1.5rem}
  table{width:100%;border-collapse:collapse;font-size:.9rem}
  th{text-align:left;padding:.5rem .75rem;border-bottom:2px solid #e5e7eb;color:#6b7280;font-weight:600}
  td{padding:.5rem .75rem;border-bottom:1px solid #f3f4f6;vertical-align:middle}
  tr:last-child td{border-bottom:none}
  label{display:block;font-size:.9rem;color:#444;margin:.75rem 0 .3rem}
  input[type=text],input[type=date],input[type=number],input[type=password]{
    width:100%;padding:.5rem .75rem;border:1.5px solid #d1d5db;border-radius:6px;font-size:.95rem}
  input:focus{outline:none;border-color:#2563eb}
  .err{color:#dc2626;background:#fef2f2;border-radius:6px;padding:.5rem .75rem;margin-bottom:1rem;font-size:.9rem}
  .form-row{display:grid;grid-template-columns:1fr 1fr;gap:1rem}
  @media(max-width:520px){.form-row{grid-template-columns:1fr}}
  .check-group{display:flex;flex-wrap:wrap;gap:.5rem .75rem;margin-top:.4rem}
  .check-group label{margin:0;display:flex;align-items:center;gap:.35rem;cursor:pointer;
    font-size:.9rem;background:#f3f4f6;padding:.3rem .65rem;border-radius:20px;font-weight:normal;color:#374151}
  .check-group input[type=checkbox]{width:auto;accent-color:#2563eb}
  .badge{padding:.15rem .5rem;border-radius:4px;font-size:.8rem;font-weight:600}
  .badge.g{background:#dcfce7;color:#166534} .badge.r{background:#fee2e2;color:#991b1b}
  .badge.n{background:#f3f4f6;color:#6b7280}
  .pill{display:inline-block;padding:.1rem .5rem;border-radius:20px;font-size:.8rem;
        background:#e0e7ff;color:#3730a3;margin:.1rem}
  .stat-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(130px,1fr));gap:1rem;margin-bottom:1.5rem}
  .stat{background:#fff;border-radius:8px;box-shadow:0 2px 8px rgba(0,0,0,.06);padding:1rem 1.25rem}
  .stat .val{font-size:1.9rem;font-weight:700;color:#2563eb}
  .stat .lbl{font-size:.8rem;color:#6b7280;margin-top:.2rem}
`;

function shell(title, body, backHref = null) {
  return `<!doctype html><html lang="nl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${e(title)} — Beheer</title><style>${css}</style></head>
<body><div class="wrap">
  <div class="topbar">
    <h1>🛡️ ${e(title)}</h1>
    <div style="display:flex;gap:.5rem;align-items:center">
      ${backHref ? `<a class="btn btn-sec btn-sm" href="${backHref}">← Terug</a>` : ''}
      <form method="POST" action="/admin/logout" style="display:inline">
        <button class="btn btn-sec btn-sm" type="submit">Uitloggen</button>
      </form>
    </div>
  </div>
  ${body}
</div></body></html>`;
}

function loginPage(error = '') {
  return `<!doctype html><html lang="nl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Beheer — inloggen</title><style>${css}
  body{display:flex;align-items:center;justify-content:center;min-height:100vh}
  .card{background:#fff;border-radius:12px;box-shadow:0 4px 24px rgba(0,0,0,.10);padding:2.5rem 2rem;width:100%;max-width:360px}
</style></head>
<body><div class="card">
  <h1 style="margin-bottom:1.5rem">🛡️ Beheer</h1>
  ${error ? `<p class="err">${e(error)}</p>` : ''}
  <form method="POST" action="/admin/login">
    <label for="u">Gebruikersnaam</label>
    <input id="u" name="username" type="text" autocomplete="username" required autofocus />
    <label for="p">Wachtwoord</label>
    <input id="p" name="password" type="password" autocomplete="current-password" required />
    <br><br>
    <button class="btn" type="submit" style="width:100%">Inloggen</button>
  </form>
</div></body></html>`;
}

function overviewPage(orgs) {
  const total = orgs.length;
  const active = orgs.filter(o => new Date(o.valid_until) >= new Date()).length;

  const rows = orgs.map(o => {
    const expired = new Date(o.valid_until) < new Date();
    return `<tr>
      <td><a href="/admin/orgs/${o.id}">${e(o.name)}</a></td>
      <td><code>${e(o.slug)}</code></td>
      <td>${(o.locales || []).map(l => `<span class="pill">${e(l)}</span>`).join('')}</td>
      <td>${o.active_count} / ${o.user_count}</td>
      <td><span class="badge ${expired ? 'r' : 'g'}">${new Date(o.valid_until).toLocaleDateString('nl-NL')}</span></td>
      <td><a href="/portal/${e(o.admin_token)}" target="_blank" style="font-size:.85rem">Portaal ↗</a></td>
    </tr>`;
  }).join('');

  return shell('Organisaties', `
    <div class="stat-grid">
      <div class="stat"><div class="val">${total}</div><div class="lbl">Organisaties</div></div>
      <div class="stat"><div class="val">${active}</div><div class="lbl">Actief</div></div>
    </div>
    <div class="section">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:1rem">
        <h2 style="margin:0">Alle organisaties</h2>
        <a class="btn btn-sm" href="/admin/orgs/new">+ Nieuw</a>
      </div>
      ${orgs.length === 0 ? '<p style="color:#9ca3af">Nog geen organisaties.</p>' : `
      <table>
        <thead><tr><th>Naam</th><th>Slug</th><th>Talen</th><th>Actief/Totaal</th><th>Geldig tot</th><th></th></tr></thead>
        <tbody>${rows}</tbody>
      </table>`}
    </div>`);
}

function checkboxGroup(name, options, selected) {
  return `<div class="check-group">${options.map(([val, label]) => `
    <label>
      <input type="checkbox" name="${e(name)}" value="${e(val)}" ${selected.includes(val) ? 'checked' : ''}>
      ${e(label)}
    </label>`).join('')}</div>`;
}

const LOCALE_LABELS = [
  ['nl','🇳🇱 Nederlands'],['nl-BE','🇧🇪 Nederlands (BE)'],['en','🇬🇧 English'],
  ['fr','🇫🇷 Français'],['fr-BE','🇧🇪 Français (BE)'],['de','🇩🇪 Deutsch'],
];
const AUDIENCE_LABELS = [['personal','👤 Privé'],['business','💼 Zakelijk']];
const DIFFICULTY_LABELS = [['normal','Normaal'],['advanced','Gevorderd']];

function orgFormPage(error = '') {
  const tomorrow = new Date(Date.now() + 365 * 86400000).toISOString().slice(0, 10);
  return shell('Nieuwe organisatie', `
    ${error ? `<p class="err">${e(error)}</p>` : ''}
    <div class="section">
      <form method="POST" action="/admin/orgs">
        <div class="form-row">
          <div><label>Naam</label><input name="name" type="text" required placeholder="Acme B.V." /></div>
          <div><label>Slug (URL-deel)</label><input name="slug" type="text" required placeholder="acme-bv" pattern="[a-z0-9-]+" /></div>
        </div>
        <div class="form-row">
          <div><label>Max. deelnemers</label><input name="max_users" type="number" min="1" max="5000" value="50" /></div>
          <div><label>Geldig tot</label><input name="valid_until" type="date" required value="${tomorrow}" /></div>
        </div>
        <label>Talen</label>
        ${checkboxGroup('locales', LOCALE_LABELS, ALL_LOCALES)}
        <label>Doelgroep</label>
        ${checkboxGroup('audiences', AUDIENCE_LABELS, ALL_AUDIENCES)}
        <label>Moeilijkheidsgraad</label>
        ${checkboxGroup('difficulties', DIFFICULTY_LABELS, ALL_DIFFICULTIES)}
        <br>
        <button class="btn" type="submit">Aanmaken</button>
      </form>
    </div>`, '/admin');
}

function orgDetailPage(org, users) {
  const locales     = org.locales     || ALL_LOCALES;
  const audiences   = org.audiences   || ALL_AUDIENCES;
  const difficulties = org.difficulties || ALL_DIFFICULTIES;
  const expired = new Date(org.valid_until) < new Date();

  const userRows = users.map(u => `<tr>
    <td><code>${e(u.numeric_id)}</code></td>
    <td>${u.done_count > 0 ? '<span class="badge g">Actief</span>' : '<span class="badge n">—</span>'}</td>
    <td>${u.allow_retrain ? '🔓' : '🔒'}</td>
    <td style="color:#9ca3af;font-size:.85rem">${new Date(u.created_at).toLocaleDateString('nl-NL')}</td>
  </tr>`).join('');

  return shell(org.name, `
    ${expired ? '<div style="background:#fff7ed;border:1px solid #fed7aa;color:#c2410c;border-radius:6px;padding:.75rem 1rem;margin-bottom:1rem">⚠️ Verlopen</div>' : ''}

    <div class="section">
      <h2>Instellingen</h2>
      <form method="POST" action="/admin/orgs/${org.id}">
        <div class="form-row">
          <div><label>Max. deelnemers</label><input name="max_users" type="number" min="1" max="5000" value="${org.max_users}" /></div>
          <div><label>Geldig tot</label><input name="valid_until" type="date" value="${new Date(org.valid_until).toISOString().slice(0,10)}" /></div>
        </div>
        <label>Talen</label>
        ${checkboxGroup('locales', LOCALE_LABELS, locales)}
        <label>Doelgroep</label>
        ${checkboxGroup('audiences', AUDIENCE_LABELS, audiences)}
        <label>Moeilijkheidsgraad</label>
        ${checkboxGroup('difficulties', DIFFICULTY_LABELS, difficulties)}
        <br>
        <button class="btn" type="submit">Opslaan</button>
      </form>
    </div>

    <div class="section">
      <h2>Portaallink (voor HR)</h2>
      <code style="font-size:.9rem;word-break:break-all">/portal/${e(org.admin_token)}</code>
      &nbsp;<a href="/portal/${e(org.admin_token)}" target="_blank" class="btn btn-sm">Openen ↗</a>
    </div>

    <div class="section">
      <div style="display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:1rem;flex-wrap:wrap;gap:.5rem">
        <h2 style="margin:0">Deelnemers genereren</h2>
        <p style="font-size:.8rem;color:#6b7280;flex-basis:100%">Pincodes worden direct als CSV gedownload — worden <strong>niet</strong> opgeslagen.</p>
      </div>
      <form method="POST" action="/admin/orgs/${org.id}/generate" style="display:flex;gap:.75rem;flex-wrap:wrap;align-items:flex-end">
        <div><label>Aantal</label><input name="count" type="number" min="1" max="500" value="10" style="width:110px"/></div>
        <button class="btn" type="submit">Genereren + CSV</button>
      </form>
    </div>

    ${users.length > 0 ? `
    <div class="section">
      <h2>Deelnemers (${users.length})</h2>
      <table>
        <thead><tr><th>ID</th><th>Status</th><th>Herhaling</th><th>Aangemaakt</th></tr></thead>
        <tbody>${userRows}</tbody>
      </table>
    </div>` : ''}`, '/admin');
}

module.exports = router;
