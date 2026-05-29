const express = require('express');
const crypto = require('node:crypto');
const bcrypt = require('bcryptjs');
const db = require('../db');

const router = express.Router();
router.use(express.urlencoded({ extended: false, limit: '20mb' }));

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
    const { name, slug, email_domain, max_users, valid_until } = req.body || {};
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
    const domain = email_domain ? email_domain.trim().toLowerCase().replace(/^@/, '') : null;

    const { rows } = await db.query(
      `INSERT INTO organisations (name, slug, email_domain, locales, audiences, difficulties, max_users, valid_until, admin_token)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING id`,
      [name.trim(), slug.trim(), domain, locales, audiences, difficulties, maxU, valid_until, admin_token]
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

    const { valid_until, max_users, email_domain, name } = req.body || {};
    const locales     = parseArray(req.body, 'locales', ALL_LOCALES);
    const audiences   = parseArray(req.body, 'audiences', ALL_AUDIENCES);
    const difficulties = parseArray(req.body, 'difficulties', ALL_DIFFICULTIES);

    if (locales.length === 0 || audiences.length === 0 || difficulties.length === 0)
      return res.redirect(`/admin/orgs/${org.id}?err=Selecteer+minimaal+%C3%A9%C3%A9n+optie+per+categorie.`);

    const orgName = (name || '').trim() || org.name;
    const domain  = email_domain ? email_domain.trim().toLowerCase().replace(/^@/, '') : null;

    await db.query(
      `UPDATE organisations SET name=$1, locales=$2, audiences=$3, difficulties=$4, valid_until=$5, max_users=$6, email_domain=$7 WHERE id=$8`,
      [orgName, locales, audiences, difficulties, valid_until || org.valid_until,
       Math.max(1, Math.min(5000, parseInt(max_users, 10) || org.max_users)), domain, org.id]
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

// POST /admin/orgs/:id/import — import a list of existing IDs from an HR system
// Streams the CSV response so large batches (tens of thousands) don't time out.
router.post('/orgs/:id/import', requireLogin, async (req, res, next) => {
  try {
    const { rows: [org] } = await db.query(`SELECT * FROM organisations WHERE id = $1`, [req.params.id]);
    if (!org) return res.status(404).end();

    const raw = String(req.body.ids || '');
    const ids = [...new Set(
      raw.split(/[\n,;]+/).map(s => s.trim()).filter(s => s.length > 0 && s.length <= 50)
    )];

    if (ids.length === 0) return res.redirect(`/admin/orgs/${org.id}?err=Geen+geldige+ID%27s+gevonden.`);

    // Stream so the browser starts downloading immediately.
    res.set('Content-Disposition', `attachment; filename="${org.slug}-import.csv"`);
    res.type('text/csv');
    res.write('ID,Pincode,Status\r\n');

    // Cost 8 is fine: 4-digit PINs + account lockout make online brute-force
    // impossible regardless of hash speed. Cost 8 runs ~15ms vs ~100ms for cost 10.
    const BCRYPT_COST = 8;
    const CONCURRENCY = 20; // parallel bcrypt calls per micro-batch
    const DB_BATCH    = 500; // rows per INSERT statement (stays well under pg's 65535-param limit)

    for (let i = 0; i < ids.length; i += DB_BATCH) {
      const chunk = ids.slice(i, i + DB_BATCH);

      // Hash all PINs in this chunk with bounded parallelism.
      const hashed = [];
      for (let j = 0; j < chunk.length; j += CONCURRENCY) {
        const group = chunk.slice(j, j + CONCURRENCY);
        const results = await Promise.all(group.map(async (rawId) => {
          const pin  = String(crypto.randomInt(0, 10000)).padStart(4, '0');
          const hash = await bcrypt.hash(pin, BCRYPT_COST);
          return { rawId, pin, hash };
        }));
        hashed.push(...results);
      }

      // Single multi-row INSERT for the whole chunk.
      // Each row uses ($1, $even, $odd) — org_id is always $1.
      const values = hashed.map((_, k) => `($1,$${k * 2 + 2},$${k * 2 + 3})`).join(',');
      const params = [org.id, ...hashed.flatMap(r => [r.rawId, r.hash])];
      const result = await db.query(
        `INSERT INTO org_users (org_id, numeric_id, pincode_hash)
         VALUES ${values}
         ON CONFLICT (org_id, numeric_id) DO NOTHING
         RETURNING numeric_id`,
        params
      );
      const inserted = new Set(result.rows.map(r => r.numeric_id));

      const csvChunk = hashed
        .map(r => inserted.has(r.rawId)
          ? `${r.rawId},${r.pin},nieuw`
          : `${r.rawId},,al_aanwezig`)
        .join('\r\n');
      res.write(csvChunk + '\r\n');
    }

    res.end();
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
        <div style="display:flex;gap:.5rem">
          <a class="btn btn-sm" style="background:#f3f4f6;color:#374151;border:1px solid #d1d5db" href="/admin/messages">📊 Berichtstatistieken</a>
          <a class="btn btn-sm" href="/admin/orgs/new">+ Nieuw</a>
        </div>
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
          <div><label>E-maildomein (optioneel)</label><input name="email_domain" type="text" placeholder="acme.nl" /></div>
          <div></div>
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
          <div><label>Bedrijfsnaam</label><input name="name" type="text" required placeholder="Acme B.V." value="${e(org.name)}" /></div>
          <div><label>E-maildomein (optioneel)</label><input name="email_domain" type="text" placeholder="acme.nl" value="${e(org.email_domain || '')}" /></div>
        </div>
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
        <h2 style="margin:0">Deelnemers aanmaken</h2>
        <p style="font-size:.8rem;color:#6b7280;flex-basis:100%">Pincodes worden direct als CSV gedownload — worden <strong>niet</strong> opgeslagen.</p>
      </div>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:1.5rem;flex-wrap:wrap">
        <div>
          <p style="font-size:.85rem;font-weight:600;margin-bottom:.5rem">Automatisch nummeren</p>
          <form class="csv-form" method="POST" action="/admin/orgs/${org.id}/generate" style="display:flex;gap:.75rem;flex-wrap:wrap;align-items:flex-end">
            <div><label>Aantal</label><input name="count" type="number" min="1" max="500" value="10" style="width:110px"/></div>
            <button class="btn" type="submit">Genereren + CSV</button>
          </form>
        </div>
        <div>
          <p style="font-size:.85rem;font-weight:600;margin-bottom:.5rem">Importeren uit HR-systeem</p>
          <form class="csv-form" method="POST" action="/admin/orgs/${org.id}/import">
            <label style="font-size:.8rem;color:#6b7280">ID's plakken — één per regel, of komma-gescheiden</label>
            <textarea name="ids" rows="5" style="width:100%;margin-top:.35rem;padding:.5rem .7rem;border:1.5px solid #d1d5db;border-radius:8px;font-family:monospace;font-size:.85rem;resize:vertical" placeholder="1001&#10;1002&#10;1003&#10;..."></textarea>
            <button class="btn" type="submit" style="margin-top:.5rem">Importeren + CSV</button>
          </form>
          <p style="font-size:.75rem;color:#9ca3af;margin-top:.4rem">Bestaande ID's worden overgeslagen (status: al_aanwezig). Grote lijsten worden gestreamd — de download start meteen.</p>
        </div>
      </div>
    </div>

    <script>
    document.querySelectorAll('.csv-form').forEach(form => {
      form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const btn = form.querySelector('button[type=submit]');
        const label = btn.textContent;
        btn.disabled = true;
        btn.textContent = 'Bezig…';
        try {
          const resp = await fetch(form.action, { method: 'POST', body: new URLSearchParams(new FormData(form)) });
          if (!resp.ok) throw new Error('server error');
          const cd = resp.headers.get('Content-Disposition') || '';
          const filename = cd.match(/filename="([^"]+)"/)?.[1] || 'export.csv';
          const blob = await resp.blob();
          const url  = URL.createObjectURL(blob);
          const a    = document.createElement('a');
          a.href = url; a.download = filename; a.click();
          URL.revokeObjectURL(url);
          location.reload();
        } catch {
          btn.disabled = false;
          btn.textContent = label;
          alert('Er ging iets mis. Probeer het opnieuw.');
        }
      });
    });
    </script>

    ${users.length > 0 ? `
    <div class="section">
      <h2>Deelnemers (${users.length})</h2>
      <table>
        <thead><tr><th>ID</th><th>Status</th><th>Herhaling</th><th>Aangemaakt</th></tr></thead>
        <tbody>${userRows}</tbody>
      </table>
    </div>` : ''}`, '/admin');
}

// GET /admin/messages — globale berichtstatistieken
router.get('/messages', requireLogin, async (req, res, next) => {
  try {
    const { locale, audience, difficulty } = req.query;

    const conditions = ['m.active = TRUE'];
    const params = [];
    if (locale)     { params.push(locale);     conditions.push(`m.locale = $${params.length}`); }
    if (audience)   { params.push(audience);   conditions.push(`m.audience = $${params.length}`); }
    if (difficulty) { params.push(difficulty); conditions.push(`m.difficulty = $${params.length}`); }

    const where = conditions.join(' AND ');

    // Gebruik de eerste beoordeling per (session_id, message_id) om hertraining
    // niet mee te tellen. org_user_id=NULL zijn publieke gebruikers.
    const { rows } = await db.query(`
      WITH first_j AS (
        SELECT DISTINCT ON (session_id, message_id)
          message_id, is_correct, clicked_link, org_user_id
        FROM inbox_judgments
        ORDER BY session_id, message_id, answered_at ASC
      )
      SELECT
        m.id, m.subject, m.sender_name, m.sender_address, m.is_phishing,
        m.locale, m.audience, m.difficulty,
        COUNT(j.message_id)::int                                          AS total,
        COUNT(j.message_id) FILTER (WHERE j.is_correct)::int             AS correct,
        COUNT(j.message_id) FILTER (WHERE j.org_user_id IS NOT NULL)::int AS enterprise_total,
        COUNT(j.message_id) FILTER (WHERE j.org_user_id IS NULL)::int     AS public_total
      FROM inbox_messages m
      LEFT JOIN first_j j ON j.message_id = m.id
      WHERE ${where}
      GROUP BY m.id, m.subject, m.sender_name, m.sender_address, m.is_phishing,
               m.locale, m.audience, m.difficulty
      ORDER BY
        CASE WHEN COUNT(j.message_id) = 0 THEN 1 ELSE 0 END ASC,
        (COUNT(j.message_id) FILTER (WHERE j.is_correct)::float / NULLIF(COUNT(j.message_id), 0)) ASC,
        m.is_phishing DESC
    `, params);

    res.type('html').send(messageStatsPage(rows, { locale, audience, difficulty }));
  } catch (err) { next(err); }
});

function messageStatsPage(rows, filters) {
  const locales     = ['nl', 'nl-BE', 'en', 'fr', 'fr-BE', 'de'];
  const audiences   = ['personal', 'business'];
  const difficulties = ['normal', 'advanced'];

  function opt(val, label, current) {
    return `<option value="${e(val)}" ${current === val ? 'selected' : ''}>${e(label)}</option>`;
  }
  function sel(name, options, current) {
    return `<select name="${e(name)}" onchange="this.form.submit()">
      <option value="">— Alle —</option>
      ${options.map(([v, l]) => opt(v, l, current)).join('')}
    </select>`;
  }

  const pct = (r) => r.total > 0 ? Math.round(r.correct / r.total * 100) : null;
  const pctBadge = (r) => {
    const p = pct(r);
    if (p === null) return '<span style="color:#9ca3af">—</span>';
    const color = p >= 80 ? '#16a34a' : p >= 55 ? '#d97706' : '#dc2626';
    return `<span style="color:${color};font-weight:600">${p}%</span>`;
  };

  // Kolommen: id, label, standaard zichtbaar
  const COLS = [
    { id: 'type',       label: 'Type',       def: true  },
    { id: 'subject',    label: 'Onderwerp',  def: true  },
    { id: 'sender',     label: 'Afzender',   def: false },
    { id: 'locale',     label: 'Taal',       def: true  },
    { id: 'audience',   label: 'Doelgroep',  def: false },
    { id: 'difficulty', label: 'Niveau',     def: true  },
    { id: 'total',      label: 'Beoordeeld', def: true  },
    { id: 'ent_pct',    label: 'Ent. %',     def: false },
    { id: 'pub_pct',    label: 'Pub. %',     def: false },
    { id: 'correct',    label: 'Correct %',  def: true  },
  ];

  const entPct  = (r) => r.total > 0 ? Math.round(r.enterprise_total / r.total * 100) + '%' : '—';
  const pubPct  = (r) => r.total > 0 ? Math.round(r.public_total    / r.total * 100) + '%' : '—';

  const cellMap = (r) => ({
    type:       r.is_phishing ? '<span class="badge r">Phish</span>' : '<span class="badge g">Echt</span>',
    subject:    `<span title="${e(r.subject)}">${e(r.subject)}</span>`,
    sender:     `<span style="font-size:.82rem;color:#6b7280" title="${e(r.sender_address)}">${e(r.sender_address)}</span>`,
    locale:     e(r.locale),
    audience:   e(r.audience),
    difficulty: e(r.difficulty),
    total:      String(r.total || '—'),
    ent_pct:    entPct(r),
    pub_pct:    pubPct(r),
    correct:    pctBadge(r),
  });

  const tableRows = rows.map(r => {
    const cells = cellMap(r);
    return '<tr>' + COLS.map(c =>
      `<td data-col="${c.id}" style="${c.id==='subject'?'max-width:260px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;':''
        }${['total','ent_pct','pub_pct','correct'].includes(c.id)?'text-align:right;':''}">${cells[c.id]}</td>`
    ).join('') + '</tr>';
  }).join('');

  const thCells = COLS.map(c =>
    `<th data-col="${c.id}" style="${['total','ent_pct','pub_pct','correct'].includes(c.id)?'text-align:right':''}">${c.label}</th>`
  ).join('');

  const judged = rows.filter(r => r.total > 0).length;

  const colPickerItems = COLS.map(c =>
    `<label style="display:flex;align-items:center;gap:.4rem;cursor:pointer;white-space:nowrap">
      <input type="checkbox" data-toggle-col="${c.id}" ${c.def ? 'checked' : ''}> ${c.label}
    </label>`
  ).join('');

  return shell('Berichtstatistieken', `
    <div class="stat-grid">
      <div class="stat"><div class="val">${rows.length}</div><div class="lbl">Berichten</div></div>
      <div class="stat"><div class="val">${judged}</div><div class="lbl">Al beoordeeld</div></div>
      <div class="stat"><div class="val">${rows.reduce((s,r)=>s+r.total,0)}</div><div class="lbl">Beoordelingen</div></div>
    </div>
    <div class="section">
      <div style="display:flex;gap:.75rem;align-items:flex-start;flex-wrap:wrap;margin-bottom:1rem;justify-content:space-between">
        <form method="GET" action="/admin/messages" style="display:flex;gap:.75rem;align-items:center;flex-wrap:wrap">
          <span style="font-size:.9rem;color:#6b7280">Filter:</span>
          ${sel('locale',     locales.map(l=>[l,l]),          filters.locale)}
          ${sel('audience',   [['personal','Privé'],['business','Zakelijk']], filters.audience)}
          ${sel('difficulty', [['normal','Normaal'],['advanced','Gevorderd']], filters.difficulty)}
          <a href="/admin/messages" style="font-size:.85rem;color:#6b7280">Wissen</a>
        </form>
        <div style="position:relative">
          <button id="col-picker-btn" type="button" class="btn btn-sm"
            style="background:#f3f4f6;color:#374151;border:1px solid #d1d5db">
            ⚙ Kolommen
          </button>
          <div id="col-picker" style="display:none;position:absolute;right:0;top:2.2rem;z-index:20;
            background:#fff;border:1px solid #d1d5db;border-radius:8px;box-shadow:0 4px 16px rgba(0,0,0,.12);
            padding:.75rem 1rem;display:none;flex-direction:column;gap:.5rem;min-width:160px">
            ${colPickerItems}
          </div>
        </div>
      </div>
      ${rows.length === 0 ? '<p style="color:#9ca3af">Geen berichten gevonden.</p>' : `
      <div style="overflow-x:auto;-webkit-overflow-scrolling:touch">
        <table id="msg-stats-table" style="min-width:520px">
          <thead><tr>${thCells}</tr></thead>
          <tbody>${tableRows}</tbody>
        </table>
      </div>`}
    </div>
    <script>
    (function() {
      const STORE_KEY = 'vo_admin_msg_cols';
      const defaults = {${COLS.map(c => `'${c.id}':${c.def}`).join(',')}};

      function loadPrefs() {
        try { return Object.assign({}, defaults, JSON.parse(localStorage.getItem(STORE_KEY) || '{}')); }
        catch(_) { return Object.assign({}, defaults); }
      }
      function savePrefs(p) { localStorage.setItem(STORE_KEY, JSON.stringify(p)); }

      function applyPrefs(prefs) {
        document.querySelectorAll('[data-col]').forEach(el => {
          el.style.display = prefs[el.dataset.col] === false ? 'none' : '';
        });
      }

      const prefs = loadPrefs();
      applyPrefs(prefs);

      // Sync checkboxes to saved prefs
      document.querySelectorAll('[data-toggle-col]').forEach(cb => {
        cb.checked = prefs[cb.dataset.toggleCol] !== false;
        cb.addEventListener('change', () => {
          prefs[cb.dataset.toggleCol] = cb.checked;
          savePrefs(prefs);
          applyPrefs(prefs);
        });
      });

      // Toggle picker dropdown
      const btn = document.getElementById('col-picker-btn');
      const picker = document.getElementById('col-picker');
      picker.style.display = 'none';
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        picker.style.display = picker.style.display === 'none' ? 'flex' : 'none';
      });
      document.addEventListener('click', () => { picker.style.display = 'none'; });
      picker.addEventListener('click', e => e.stopPropagation());
    })();
    </script>`, '/admin');
}

module.exports = router;
