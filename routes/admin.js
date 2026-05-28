const express = require('express');
const http = require('http');
const crypto = require('node:crypto');
const bcrypt = require('bcryptjs');
const db = require('../db');

const router = express.Router();

// Simple in-memory geo cache (IP → {city, country, isp})
const geoCache = new Map();

function geoLookup(ip) {
  if (!ip || ip === '—' || ip.startsWith('127.') || ip.startsWith('::')) {
    return Promise.resolve(null);
  }
  if (geoCache.has(ip)) return Promise.resolve(geoCache.get(ip));
  return new Promise((resolve) => {
    const req = http.get(
      `http://ip-api.com/json/${encodeURIComponent(ip)}?fields=status,country,city,isp`,
      { timeout: 3000 },
      (res) => {
        let data = '';
        res.on('data', (c) => { data += c; });
        res.on('end', () => {
          try {
            const j = JSON.parse(data);
            if (j.status === 'success') {
              const geo = { city: j.city, country: j.country, isp: j.isp };
              geoCache.set(ip, geo);
              resolve(geo);
            } else {
              resolve(null);
            }
          } catch { resolve(null); }
        });
      }
    );
    req.on('error', () => resolve(null));
    req.on('timeout', () => { req.destroy(); resolve(null); });
  });
}

function requireLogin(req, res, next) {
  if (req.session?.admin) return next();
  res.redirect('/sitrep/login');
}

const PERIODES = { vandaag: 1, week: 7, maand: 30, alles: null };

function periodeFilter(periode) {
  const days = PERIODES[periode] ?? null;
  if (!days) return '';
  return `AND answered_at >= NOW() - INTERVAL '${days} days'`;
}

function periodeFilterCol(periode, col) {
  const days = PERIODES[periode] ?? null;
  if (!days) return '';
  return `AND ${col} >= NOW() - INTERVAL '${days} days'`;
}

// GET /sitrep/login
router.get('/login', (req, res) => {
  if (req.session?.admin) return res.redirect('/sitrep');
  res.type('html').send(loginPage());
});

// POST /sitrep/login
router.post('/login', express.urlencoded({ extended: false }), (req, res) => {
  const { username, password } = req.body || {};
  const validUser = process.env.ADMIN_USER;
  const validPass = process.env.ADMIN_PASSWORD;

  if (!validUser || !validPass) {
    return res.type('html').send(loginPage('ADMIN_USER en ADMIN_PASSWORD zijn niet ingesteld op de server.'));
  }
  if (username === validUser && password === validPass) {
    req.session.admin = true;
    return res.redirect('/sitrep');
  }
  res.type('html').send(loginPage('Onjuiste gebruikersnaam of wachtwoord.'));
});

// POST /sitrep/logout
router.post('/logout', (req, res) => {
  req.session.destroy(() => res.redirect('/sitrep/login'));
});

// GET /sitrep?periode=vandaag|week|maand|alles
router.get('/', requireLogin, async (req, res, next) => {
  try {
    const periode = Object.keys(PERIODES).includes(req.query.periode) ? req.query.periode : 'alles';
    const jf = periodeFilter(periode);

    const [overzicht, recent, ips, egg, starts] = await Promise.all([
      db.query(`
        SELECT
          COUNT(DISTINCT session_id)::int                                        AS gestart,
          COUNT(*)::int                                                          AS oordelen,
          COUNT(*) FILTER (WHERE is_correct)::int                               AS correct,
          COUNT(*) FILTER (WHERE clicked_link)::int                             AS link_geklikt,
          COALESCE(ROUND(
            COUNT(*) FILTER (WHERE is_correct)::numeric / NULLIF(COUNT(*), 0) * 100
          ), 0)::int                                                             AS gemiddeld_pct,
          COUNT(DISTINCT session_id) FILTER (WHERE difficulty = 'advanced')::int AS gevorderd_sessies,
          COUNT(DISTINCT session_id) FILTER (WHERE difficulty = 'normal')::int   AS normaal_sessies
        FROM inbox_judgments
        WHERE TRUE ${jf}
      `),
      db.query(`
        SELECT
          TO_CHAR(MIN(j.answered_at) AT TIME ZONE 'Europe/Amsterdam', 'DD-MM-YYYY HH24:MI') AS tijdstip,
          COALESCE(MAX(j.ip_address), '—')                                      AS ip,
          COUNT(*)::int                                                          AS oordelen,
          COUNT(*) FILTER (WHERE j.is_correct)::int                             AS correct,
          MAX(j.difficulty)                                                      AS difficulty
        FROM inbox_judgments j
        WHERE TRUE ${jf}
        GROUP BY j.session_id
        ORDER BY MIN(j.answered_at) DESC
        LIMIT 20
      `),
      db.query(`
        SELECT ip_address AS ip, COUNT(*)::int AS bezoeken,
               MAX(answered_at) AS laatste
        FROM inbox_judgments
        WHERE ip_address IS NOT NULL ${jf}
        GROUP BY ip_address
        ORDER BY laatste DESC
        LIMIT 30
      `),
      db.query(`
        SELECT COUNT(*)::int AS totaal FROM easter_egg_views
        WHERE TRUE ${periodeFilterCol(periode, 'viewed_at')}
      `),
      db.query(`
        SELECT COUNT(DISTINCT session_id)::int AS totaal FROM simulator_starts
        WHERE TRUE ${periodeFilterCol(periode, 'started_at')}
      `),
    ]);

    // Geo-lookup for unique IPs (parallel, max 3s each, cached)
    const uniqueIps = [...new Set(ips.rows.map(r => r.ip).filter(Boolean))];
    const geoResults = await Promise.all(uniqueIps.map(ip => geoLookup(ip)));
    const geoMap = Object.fromEntries(uniqueIps.map((ip, i) => [ip, geoResults[i]]));

    res.type('html').send(dashboardPage(overzicht.rows[0], recent.rows, ips.rows, egg.rows[0].totaal, starts.rows[0].totaal, periode, geoMap));
  } catch (err) { next(err); }
});

// ---- HTML helpers ----

function loginPage(error = '') {
  return `<!doctype html>
<html lang="nl">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Beheer · Veilig Online</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: system-ui, sans-serif; background: #f4f6f9; display: flex; align-items: center; justify-content: center; min-height: 100vh; }
    .card { background: #fff; border-radius: 12px; box-shadow: 0 4px 24px rgba(0,0,0,.10); padding: 2.5rem 2rem; width: 100%; max-width: 360px; }
    h1 { font-size: 1.25rem; margin-bottom: 1.5rem; color: #1a1a2e; }
    label { display: block; font-size: .9rem; color: #444; margin-bottom: .25rem; margin-top: 1rem; }
    input { width: 100%; padding: .6rem .8rem; border: 1px solid #ccc; border-radius: 6px; font-size: 1rem; }
    button { margin-top: 1.5rem; width: 100%; padding: .75rem; background: #2563eb; color: #fff; border: none; border-radius: 6px; font-size: 1rem; cursor: pointer; }
    button:hover { background: #1d4ed8; }
    .error { margin-top: 1rem; color: #dc2626; font-size: .9rem; }
  </style>
</head>
<body>
  <div class="card">
    <h1>🛡️ Veilig Online — Beheer</h1>
    <form method="POST" action="/sitrep/login">
      <label for="u">Gebruikersnaam</label>
      <input id="u" name="username" type="text" autocomplete="username" required autofocus />
      <label for="p">Wachtwoord</label>
      <input id="p" name="password" type="password" autocomplete="current-password" required />
      <button type="submit">Inloggen</button>
    </form>
    ${error ? `<p class="error">${error}</p>` : ''}
  </div>
</body>
</html>`;
}

function dashboardPage(overzicht, recent, ips, easterEggCount, simulatorStartCount, periode, geoMap = {}) {
  const diffLabel = d => d === 'advanced' ? '<span style="background:#f59e0b;color:#fff;padding:.1rem .4rem;border-radius:4px;font-size:.8rem">Gevorderd</span>'
                                          : '<span style="background:#6b7280;color:#fff;padding:.1rem .4rem;border-radius:4px;font-size:.8rem">Normaal</span>';

  const geoStr = (ip) => {
    const g = geoMap[ip];
    if (!g) return '—';
    const parts = [g.city, g.country].filter(Boolean).join(', ');
    return parts || '—';
  };

  const rows = recent.map(r => `
    <tr>
      <td>${r.tijdstip}</td>
      <td><code>${r.ip}</code></td>
      <td>${r.oordelen}</td>
      <td>${r.oordelen > 0 ? Math.round(r.correct / r.oordelen * 100) : '—'}%</td>
      <td>${diffLabel(r.difficulty)}</td>
    </tr>`).join('');

  const ipRows = ips.map(r => {
    const g = geoMap[r.ip];
    return `
    <tr>
      <td><code>${r.ip}</code></td>
      <td>${geoStr(r.ip)}</td>
      <td style="color:#6b7280;font-size:.85rem">${g?.isp || '—'}</td>
      <td>${r.bezoeken}</td>
      <td>${new Date(r.laatste).toLocaleString('nl-NL', { timeZone: 'Europe/Amsterdam' })}</td>
    </tr>`;
  }).join('');

  const filterLinks = [
    ['vandaag', 'Vandaag'],
    ['week',    '7 dagen'],
    ['maand',   '30 dagen'],
    ['alles',   'Alles'],
  ].map(([key, label]) => `
    <a href="/sitrep?periode=${key}" class="filter-btn ${periode === key ? 'active' : ''}">${label}</a>
  `).join('');

  return `<!doctype html>
<html lang="nl">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Beheer · Veilig Online</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: system-ui, sans-serif; background: #f4f6f9; color: #1a1a2e; padding: 2rem 1rem; }
    .topbar { display: flex; justify-content: space-between; align-items: center; max-width: 860px; margin: 0 auto 1.5rem; }
    h1 { font-size: 1.3rem; }
    .logout button { padding: .4rem .9rem; background: #e5e7eb; border: none; border-radius: 6px; cursor: pointer; font-size: .9rem; }
    .logout button:hover { background: #d1d5db; }
    .filters { display: flex; gap: .5rem; max-width: 860px; margin: 0 auto 1.5rem; }
    .filter-btn { padding: .4rem 1rem; border-radius: 6px; text-decoration: none; font-size: .9rem; background: #fff; color: #374151; box-shadow: 0 1px 4px rgba(0,0,0,.08); }
    .filter-btn:hover { background: #f3f4f6; }
    .filter-btn.active { background: #2563eb; color: #fff; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 1rem; max-width: 860px; margin: 0 auto 2rem; }
    .stat { background: #fff; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,.07); padding: 1.25rem 1.5rem; }
    .stat .val { font-size: 2rem; font-weight: 700; color: #2563eb; }
    .stat .lbl { font-size: .85rem; color: #6b7280; margin-top: .25rem; }
    .section { max-width: 860px; margin: 0 auto; background: #fff; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,.07); padding: 1.5rem; }
    .section + .section { margin-top: 1.5rem; }
    h2 { font-size: 1rem; margin-bottom: 1rem; color: #374151; }
    table { width: 100%; border-collapse: collapse; font-size: .9rem; }
    th { text-align: left; padding: .5rem .75rem; border-bottom: 2px solid #e5e7eb; color: #6b7280; font-weight: 600; }
    td { padding: .5rem .75rem; border-bottom: 1px solid #f3f4f6; }
    tr:last-child td { border-bottom: none; }
  </style>
</head>
<body>
  <div class="topbar">
    <h1>🛡️ Veilig Online — Beheer</h1>
    <form class="logout" method="POST" action="/sitrep/logout"><button type="submit">Uitloggen</button></form>
  </div>

  <div class="filters">${filterLinks}</div>

  <div class="grid">
    <div class="stat"><div class="val">${simulatorStartCount}</div><div class="lbl">Simulator gestart</div></div>
    <div class="stat"><div class="val">${overzicht.gestart}</div><div class="lbl">Berichten beoordeeld (uniek)</div></div>
    <div class="stat"><div class="val">${overzicht.oordelen}</div><div class="lbl">Berichten beoordeeld</div></div>
    <div class="stat"><div class="val">${overzicht.correct}</div><div class="lbl">Correct beoordeeld</div></div>
    <div class="stat"><div class="val">${overzicht.gemiddeld_pct}%</div><div class="lbl">Gemiddelde score</div></div>
    <div class="stat"><div class="val">${overzicht.link_geklikt}</div><div class="lbl">Link geklikt</div></div>
    <div class="stat"><div class="val">${overzicht.normaal_sessies}</div><div class="lbl">Sessies Normaal</div></div>
    <div class="stat"><div class="val">${overzicht.gevorderd_sessies}</div><div class="lbl">Sessies Gevorderd</div></div>
    <div class="stat"><div class="val">${easterEggCount}</div><div class="lbl">Easter egg gezien 👑</div></div>
  </div>

  <div class="section">
    <h2>Laatste 20 sessies</h2>
    ${recent.length === 0 ? '<p style="color:#9ca3af">Geen sessies in deze periode.</p>' : `
    <table>
      <thead><tr><th>Tijdstip</th><th>IP-adres</th><th>Oordelen</th><th>Score</th><th>Niveau</th></tr></thead>
      <tbody>${rows}</tbody>
    </table>`}
  </div>

  <div class="section">
    <h2>IP-adressen (uniek, meest recent)</h2>
    ${ips.length === 0 ? '<p style="color:#9ca3af">Geen data in deze periode.</p>' : `
    <table>
      <thead><tr><th>IP-adres</th><th>Locatie</th><th>ISP</th><th>Acties</th><th>Laatste activiteit</th></tr></thead>
      <tbody>${ipRows}</tbody>
    </table>`}
  </div>
</body>
</html>`;
}

// ── Org management ──────────────────────────────────────────────────────────

router.use(express.urlencoded({ extended: false }));

// GET /sitrep/orgs
router.get('/orgs', requireLogin, async (req, res, next) => {
  try {
    const { rows } = await db.query(`
      SELECT o.*,
             COUNT(u.id)::int AS user_count
      FROM organisations o
      LEFT JOIN org_users u ON u.org_id = o.id
      GROUP BY o.id ORDER BY o.created_at DESC
    `);
    res.type('html').send(orgsPage(rows));
  } catch (err) { next(err); }
});

// GET /sitrep/orgs/new
router.get('/orgs/new', requireLogin, (_req, res) => {
  res.type('html').send(orgFormPage());
});

// POST /sitrep/orgs
router.post('/orgs', requireLogin, async (req, res, next) => {
  try {
    const { name, slug, difficulty, max_users, valid_until } = req.body || {};
    if (!name || !slug || !valid_until) return res.type('html').send(orgFormPage('Naam, slug en geldigheidsdatum zijn verplicht.'));
    if (!/^[a-z0-9-]+$/.test(slug)) return res.type('html').send(orgFormPage('Slug mag alleen kleine letters, cijfers en koppeltekens bevatten.'));

    const admin_token = crypto.randomBytes(24).toString('hex');
    const diff = difficulty === 'advanced' ? 'advanced' : 'normal';
    const maxU = Math.max(1, Math.min(5000, parseInt(max_users, 10) || 50));

    const { rows } = await db.query(
      `INSERT INTO organisations (name, slug, difficulty, max_users, valid_until, admin_token)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
      [name.trim(), slug.trim(), diff, maxU, valid_until, admin_token]
    );
    res.redirect(`/sitrep/orgs/${rows[0].id}`);
  } catch (err) {
    if (err.code === '23505') return res.type('html').send(orgFormPage('Deze slug is al in gebruik.'));
    next(err);
  }
});

// GET /sitrep/orgs/:id
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

// POST /sitrep/orgs/:id/generate — generate N users, return CSV immediately
router.post('/orgs/:id/generate', requireLogin, async (req, res, next) => {
  try {
    const { rows: [org] } = await db.query(`SELECT * FROM organisations WHERE id = $1`, [req.params.id]);
    if (!org) return res.status(404).end();

    const count = Math.max(1, Math.min(500, parseInt(req.body.count, 10) || 10));

    // Get current max numeric_id for this org
    const { rows: [maxRow] } = await db.query(
      `SELECT COALESCE(MAX(numeric_id::int), 0)::int AS maxid FROM org_users WHERE org_id = $1`,
      [org.id]
    );
    const startId = maxRow.maxid + 1;

    const lines = ['ID,Pincode'];
    for (let i = 0; i < count; i++) {
      const numericId = String(startId + i).padStart(5, '0');
      const pin = String(crypto.randomInt(0, 10000)).padStart(4, '0');
      const hash = await bcrypt.hash(pin, 10);
      await db.query(
        `INSERT INTO org_users (org_id, numeric_id, pincode_hash) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING`,
        [org.id, numericId, hash]
      );
      lines.push(`${numericId},${pin}`);
    }

    res.set('Content-Disposition', `attachment; filename="${org.slug}-credentials.csv"`)
       .type('text/csv').send(lines.join('\r\n'));
  } catch (err) { next(err); }
});

// ── Org HTML helpers ─────────────────────────────────────────────────────────

function adminEsc(s) {
  return String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

const adminStyle = `
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: system-ui, sans-serif; background: #f4f6f9; color: #1a1a2e; padding: 2rem 1rem; }
  .wrap { max-width: 860px; margin: 0 auto; }
  .topbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; }
  h1 { font-size: 1.3rem; }
  a { color: #2563eb; }
  .btn { display: inline-block; padding: .4rem .9rem; background: #2563eb; color: #fff;
         text-decoration: none; border-radius: 6px; font-size: .9rem; border: none; cursor: pointer; }
  .btn:hover { background: #1d4ed8; }
  .btn-sec { background: #e5e7eb; color: #374151; }
  .btn-sec:hover { background: #d1d5db; }
  .section { background: #fff; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,.07);
             padding: 1.5rem; margin-bottom: 1.5rem; }
  h2 { font-size: 1rem; color: #374151; margin-bottom: 1rem; }
  table { width: 100%; border-collapse: collapse; font-size: .9rem; }
  th { text-align: left; padding: .5rem .75rem; border-bottom: 2px solid #e5e7eb; color: #6b7280; font-weight: 600; }
  td { padding: .5rem .75rem; border-bottom: 1px solid #f3f4f6; }
  tr:last-child td { border-bottom: none; }
  label { display: block; font-size: .9rem; color: #444; margin: .75rem 0 .25rem; }
  input, select { width: 100%; padding: .5rem .75rem; border: 1.5px solid #d1d5db; border-radius: 6px; font-size: .95rem; }
  input:focus, select:focus { outline: none; border-color: #2563eb; }
  .err { color: #dc2626; background: #fef2f2; border-radius: 6px; padding: .5rem .75rem; margin-bottom: 1rem; font-size: .9rem; }
  .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
  @media (max-width: 500px) { .form-row { grid-template-columns: 1fr; } }
`;

function orgsPage(orgs) {
  const rows = orgs.map(o => `
    <tr>
      <td><a href="/sitrep/orgs/${o.id}">${adminEsc(o.name)}</a></td>
      <td><code>${adminEsc(o.slug)}</code></td>
      <td>${o.difficulty === 'advanced' ? 'Gevorderd' : 'Normaal'}</td>
      <td>${o.user_count} / ${o.max_users}</td>
      <td>${new Date(o.valid_until).toLocaleDateString('nl-NL')}</td>
      <td><a href="/portal/${adminEsc(o.admin_token)}" target="_blank">Portaal ↗</a></td>
    </tr>`).join('');

  return `<!doctype html><html lang="nl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Organisaties — Beheer</title><style>${adminStyle}</style></head>
<body><div class="wrap">
  <div class="topbar">
    <h1>🏢 Organisaties</h1>
    <div style="display:flex;gap:.5rem">
      <a class="btn btn-sec" href="/sitrep">← Beheer</a>
      <a class="btn" href="/sitrep/orgs/new">+ Nieuwe organisatie</a>
    </div>
  </div>
  <div class="section">
    ${orgs.length === 0 ? '<p style="color:#9ca3af">Nog geen organisaties.</p>' : `
    <table>
      <thead><tr><th>Naam</th><th>Slug</th><th>Niveau</th><th>Deelnemers</th><th>Geldig tot</th><th>Portaal</th></tr></thead>
      <tbody>${rows}</tbody>
    </table>`}
  </div>
</div></body></html>`;
}

function orgFormPage(error = '') {
  const tomorrow = new Date(Date.now() + 365 * 86400000).toISOString().slice(0, 10);
  return `<!doctype html><html lang="nl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Nieuwe organisatie — Beheer</title><style>${adminStyle}</style></head>
<body><div class="wrap">
  <div class="topbar"><h1>Nieuwe organisatie</h1><a class="btn btn-sec" href="/sitrep/orgs">← Terug</a></div>
  ${error ? `<p class="err">${adminEsc(error)}</p>` : ''}
  <div class="section">
    <form method="POST" action="/sitrep/orgs">
      <div class="form-row">
        <div>
          <label>Naam</label>
          <input name="name" type="text" required placeholder="Acme B.V." />
        </div>
        <div>
          <label>Slug (URL)</label>
          <input name="slug" type="text" required placeholder="acme-bv" pattern="[a-z0-9-]+" />
        </div>
      </div>
      <div class="form-row">
        <div>
          <label>Moeilijkheidsgraad</label>
          <select name="difficulty">
            <option value="normal">Normaal</option>
            <option value="advanced">Gevorderd</option>
          </select>
        </div>
        <div>
          <label>Max. deelnemers</label>
          <input name="max_users" type="number" min="1" max="5000" value="50" />
        </div>
      </div>
      <div>
        <label>Geldig tot</label>
        <input name="valid_until" type="date" required value="${tomorrow}" />
      </div>
      <br>
      <button class="btn" type="submit">Aanmaken</button>
    </form>
  </div>
</div></body></html>`;
}

function orgDetailPage(org, users) {
  const portalUrl = `/portal/${org.admin_token}`;
  const userRows = users.map(u => `
    <tr>
      <td><code>${adminEsc(u.numeric_id)}</code></td>
      <td>${u.done_count > 0 ? '✅' : '—'}</td>
      <td>${u.allow_retrain ? '🔓' : '🔒'}</td>
      <td>${new Date(u.created_at).toLocaleDateString('nl-NL')}</td>
    </tr>`).join('');

  return `<!doctype html><html lang="nl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${adminEsc(org.name)} — Beheer</title><style>${adminStyle}</style></head>
<body><div class="wrap">
  <div class="topbar">
    <h1>${adminEsc(org.name)}</h1>
    <div style="display:flex;gap:.5rem">
      <a class="btn btn-sec" href="/sitrep/orgs">← Organisaties</a>
      <a class="btn" href="${adminEsc(portalUrl)}" target="_blank">Portaal ↗</a>
    </div>
  </div>

  <div class="section">
    <h2>Details</h2>
    <table>
      <tr><th>Slug</th><td><code>${adminEsc(org.slug)}</code></td></tr>
      <tr><th>Niveau</th><td>${org.difficulty === 'advanced' ? 'Gevorderd' : 'Normaal'}</td></tr>
      <tr><th>Deelnemers</th><td>${users.length} / ${org.max_users}</td></tr>
      <tr><th>Geldig tot</th><td>${new Date(org.valid_until).toLocaleDateString('nl-NL')}</td></tr>
      <tr><th>Portaallink</th><td><a href="${adminEsc(portalUrl)}" target="_blank">/portal/${adminEsc(org.admin_token)}</a></td></tr>
    </table>
  </div>

  <div class="section">
    <h2>Deelnemers genereren</h2>
    <p style="font-size:.9rem;color:#6b7280;margin-bottom:1rem">
      De pincode wordt direct als CSV-download geretourneerd — hij wordt <strong>niet opgeslagen</strong>.
      Bewaar het bestand op een veilige plek.
    </p>
    <form method="POST" action="/sitrep/orgs/${org.id}/generate" style="display:flex;gap:.75rem;align-items:flex-end;flex-wrap:wrap">
      <div>
        <label>Aantal nieuwe IDs</label>
        <input name="count" type="number" min="1" max="500" value="10" style="width:120px" />
      </div>
      <button class="btn" type="submit">Genereren + downloaden CSV</button>
    </form>
  </div>

  ${users.length > 0 ? `
  <div class="section">
    <h2>Bestaande deelnemers (${users.length})</h2>
    <table>
      <thead><tr><th>ID</th><th>Actief</th><th>Herhaling</th><th>Aangemaakt</th></tr></thead>
      <tbody>${userRows}</tbody>
    </table>
  </div>` : ''}
</div></body></html>`;
}

module.exports = router;
