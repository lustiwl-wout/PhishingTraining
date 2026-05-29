const express = require('express');
const crypto = require('node:crypto');
const bcrypt = require('bcryptjs');
const db = require('../db');

// ── shared helpers ──────────────────────────────────────────────────────────

function esc(s) {
  return String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function fmtDate(d) {
  return d ? new Date(d).toLocaleDateString('nl-NL') : '—';
}

function isExpired(org) {
  return org.valid_until && new Date(org.valid_until) < new Date();
}

function notFound(res) {
  res.status(404).type('html').send(`<!doctype html><html lang="nl"><head><meta charset="utf-8">
<title>Niet gevonden</title></head><body style="font-family:system-ui;padding:2rem">
<h1>Pagina niet gevonden</h1><p><a href="/">Terug naar de training</a></p></body></html>`);
}

async function getOrgBy(field, value) {
  const col = field === 'slug' ? 'slug' : 'admin_token';
  const { rows } = await db.query(`SELECT * FROM organisations WHERE ${col} = $1`, [value]);
  return rows[0] || null;
}

async function countActiveMessages(difficulty) {
  const { rows } = await db.query(
    `SELECT COUNT(*)::int AS total FROM inbox_messages WHERE active = TRUE AND difficulty = $1`,
    [difficulty]
  );
  return rows[0].total;
}

async function countJudgedByUser(orgUserId) {
  const { rows } = await db.query(
    `SELECT COUNT(DISTINCT message_id)::int AS done FROM inbox_judgments WHERE org_user_id = $1`,
    [orgUserId]
  );
  return rows[0].done;
}

// ── LOGIN ROUTER  (mounted at /e) ───────────────────────────────────────────

const loginRouter = express.Router();
loginRouter.use(express.urlencoded({ extended: false }));

// GET /e/:slug
loginRouter.get('/:slug', async (req, res) => {
  const org = await getOrgBy('slug', req.params.slug).catch(() => null);
  if (!org || isExpired(org)) {
    // Als dit via subdomain-routing is binnengekomen (bv. onbekend.seethephish.com),
    // stuur door naar de algemene training in plaats van een 404 te tonen.
    const canonical = (process.env.CANONICAL_URL || '').replace(/\/$/, '');
    if (canonical) return res.redirect(canonical + '/');
    return notFound(res);
  }
  if (req.session.enterpriseOrgUserId) return res.redirect('/');
  res.type('html').send(loginPage(org));
});

// POST /e/:slug/login
loginRouter.post('/:slug/login', async (req, res) => {
  const org = await getOrgBy('slug', req.params.slug).catch(() => null);
  if (!org || isExpired(org)) return notFound(res);

  const { numeric_id, pincode } = req.body || {};
  const fail = (msg) => res.type('html').send(loginPage(org, msg));

  if (!numeric_id || !pincode) return fail('Vul uw ID en pincode in.');

  const { rows } = await db.query(
    `SELECT * FROM org_users WHERE org_id = $1 AND numeric_id = $2`,
    [org.id, String(numeric_id).trim()]
  );
  const user = rows[0];

  // Always run bcrypt to prevent timing attacks
  const hashToCheck = user?.pincode_hash || '$2a$10$invalidhashfortimingXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
  const match = await bcrypt.compare(String(pincode).trim(), hashToCheck);

  if (!user || !match) {
    if (user) {
      const attempts = (user.failed_attempts || 0) + 1;
      const locked = attempts >= 5 ? new Date(Date.now() + 15 * 60 * 1000) : null;
      await db.query(
        `UPDATE org_users SET failed_attempts = $1, locked_until = $2 WHERE id = $3`,
        [attempts, locked, user.id]
      );
    }
    return fail('Onjuist ID of pincode. Probeer het opnieuw.');
  }

  if (user.locked_until && new Date(user.locked_until) > new Date()) {
    return fail('Dit account is tijdelijk geblokkeerd. Probeer over 15 minuten opnieuw.');
  }

  await db.query(`UPDATE org_users SET failed_attempts = 0, locked_until = NULL WHERE id = $1`, [user.id]);

  // Check retrain block
  const total = await countActiveMessages(org.difficulty);
  const done = await countJudgedByUser(user.id);
  if (done >= total && total > 0 && !user.allow_retrain) {
    return res.type('html').send(completedPage(org));
  }

  // Regenerate session to prevent fixation
  await new Promise((resolve, reject) =>
    req.session.regenerate((err) => err ? reject(err) : resolve())
  );

  const sid = crypto.randomUUID();
  req.session.enterpriseOrgUserId = user.id;
  req.session.enterpriseSessionId = sid;

  await db.query(
    `INSERT INTO org_sessions (org_user_id, session_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
    [user.id, sid]
  );

  res.redirect('/');
});

// POST /e/logout
loginRouter.post('/logout', async (req, res) => {
  if (req.session.enterpriseSessionId) {
    await db.query(`DELETE FROM org_sessions WHERE session_id = $1`, [req.session.enterpriseSessionId]).catch(() => {});
  }
  req.session.destroy(() => res.redirect('/'));
});

// ── PORTAL ROUTER  (mounted at /portal) ─────────────────────────────────────

const portalRouter = express.Router();
portalRouter.use(express.urlencoded({ extended: false }));

// GET /portal/:token
portalRouter.get('/:token', async (req, res) => {
  const org = await getOrgBy('admin_token', req.params.token).catch(() => null);
  if (!org) return notFound(res);

  const total = await countActiveMessages(org.difficulty);
  const { rows } = await db.query(`
    SELECT
      u.id, u.numeric_id, u.allow_retrain,
      COUNT(DISTINCT j.message_id)::int              AS done_count,
      COUNT(j.id) FILTER (WHERE j.is_correct)::int   AS correct_count,
      MIN(j.answered_at)                             AS first_judged_at,
      MAX(j.answered_at)                             AS last_judged_at
    FROM org_users u
    LEFT JOIN inbox_judgments j ON j.org_user_id = u.id
    WHERE u.org_id = $1
    GROUP BY u.id, u.numeric_id, u.allow_retrain
    ORDER BY u.numeric_id
  `, [org.id]);

  res.type('html').send(portalPage(org, rows, total, req.params.token));
});

// POST /portal/:token/toggle/:userId
portalRouter.post('/:token/toggle/:userId', async (req, res) => {
  const org = await getOrgBy('admin_token', req.params.token).catch(() => null);
  if (!org) return notFound(res);

  await db.query(
    `UPDATE org_users SET allow_retrain = $1 WHERE id = $2 AND org_id = $3`,
    [req.body.allow_retrain === '1', parseInt(req.params.userId, 10), org.id]
  );
  res.redirect(`/portal/${req.params.token}`);
});

// GET /portal/:token/export.csv
portalRouter.get('/:token/export.csv', async (req, res) => {
  const org = await getOrgBy('admin_token', req.params.token).catch(() => null);
  if (!org) return notFound(res);

  const total = await countActiveMessages(org.difficulty);
  const { rows } = await db.query(`
    SELECT u.numeric_id,
           COUNT(DISTINCT j.message_id)::int            AS done_count,
           COUNT(j.id) FILTER (WHERE j.is_correct)::int AS correct_count,
           MIN(j.answered_at)                           AS first_judged_at
    FROM org_users u
    LEFT JOIN inbox_judgments j ON j.org_user_id = u.id
    WHERE u.org_id = $1
    GROUP BY u.id, u.numeric_id ORDER BY u.numeric_id
  `, [org.id]);

  const lines = ['ID,Training afgerond,Score (%),Datum'];
  for (const r of rows) {
    const isDone = r.done_count >= total && total > 0;
    const score = r.done_count > 0 ? Math.round(r.correct_count / r.done_count * 100) : '';
    lines.push(`${r.numeric_id},${isDone ? 'Ja' : 'Nee'},${score},${r.first_judged_at ? fmtDate(r.first_judged_at) : ''}`);
  }

  res.set('Content-Disposition', `attachment; filename="${org.slug}-resultaten.csv"`)
     .type('text/csv').send(lines.join('\r\n'));
});

// ── HTML helpers ────────────────────────────────────────────────────────────

function loginPage(org, error = '') {
  return `<!doctype html>
<html lang="nl">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Training — ${esc(org.name)}</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: system-ui, sans-serif; background: #f4f6f9;
           display: flex; flex-direction: column; align-items: center;
           justify-content: center; min-height: 100vh; padding: 1rem; }
    .card { background: #fff; border-radius: 12px;
            box-shadow: 0 4px 24px rgba(0,0,0,.10);
            padding: 2.5rem 2rem; width: 100%; max-width: 380px; }
    .org { font-size: .85rem; color: #6b7280; margin-bottom: 1.25rem; }
    h1 { font-size: 1.2rem; color: #1a1a2e; }
    label { display: block; font-size: .9rem; color: #444; margin: 1rem 0 .3rem; }
    input { width: 100%; padding: .65rem .8rem; border: 1.5px solid #d1d5db;
            border-radius: 8px; font-size: 1.1rem; letter-spacing: .1em; }
    input:focus { outline: none; border-color: #2563eb; }
    button { margin-top: 1.5rem; width: 100%; padding: .75rem;
             background: #2563eb; color: #fff; border: none; border-radius: 8px;
             font-size: 1rem; cursor: pointer; font-weight: 600; }
    button:hover { background: #1d4ed8; }
    .err { margin-top: 1rem; color: #dc2626; font-size: .9rem;
           background: #fef2f2; border-radius: 6px; padding: .6rem .8rem; }
    footer { margin-top: 2rem; font-size: .8rem; color: #9ca3af; }
    .domain { font-size: .8rem; font-weight: 400; color: #6b7280; letter-spacing: 0; }
  </style>
</head>
<body>
  <div class="card">
    <p class="org">${esc(org.name)}</p>
    <h1>🛡️ Phishing-training</h1>
    <form method="POST" action="/e/${esc(org.slug)}/login" autocomplete="off">
      <label for="nid">Uw ID-nummer${org.email_domain ? ` <span class="domain">@${esc(org.email_domain)}</span>` : ''}</label>
      <input id="nid" name="numeric_id" type="text" inputmode="numeric"
             pattern="[0-9]+" maxlength="10" required autofocus placeholder="bv. 00142" />
      <label for="pin">Pincode (4 cijfers)</label>
      <input id="pin" name="pincode" type="password" inputmode="numeric"
             pattern="[0-9]{4}" maxlength="4" required placeholder="····" />
      <button type="submit">Inloggen →</button>
    </form>
    ${error ? `<p class="err">${esc(error)}</p>` : ''}
  </div>
  <footer>Veilig Online</footer>
</body>
</html>`;
}

function completedPage(org) {
  return `<!doctype html>
<html lang="nl">
<head>
  <meta charset="utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Training afgerond</title>
  <style>
    body { font-family: system-ui; background: #f4f6f9; display: flex;
           align-items: center; justify-content: center; min-height: 100vh; padding: 1rem; }
    .card { background: #fff; border-radius: 12px; box-shadow: 0 4px 24px rgba(0,0,0,.10);
            padding: 2.5rem 2rem; max-width: 420px; text-align: center; }
    h1 { font-size: 1.4rem; color: #1a1a2e; margin-bottom: 1rem; }
    p { color: #6b7280; line-height: 1.6; }
  </style>
</head>
<body>
  <div class="card">
    <h1>✅ Training afgerond</h1>
    <p>U heeft deze training al voltooid. Neem contact op met uw leidinggevende of HR-afdeling als u de training opnieuw wilt doen.</p>
  </div>
</body>
</html>`;
}

function portalPage(org, users, totalMessages, token) {
  const isDone = (r) => r.done_count >= totalMessages && totalMessages > 0;
  const score  = (r) => r.done_count > 0 ? Math.round(r.correct_count / r.done_count * 100) + '%' : '—';

  const userRows = users.map(r => `
    <tr>
      <td><code>${esc(r.numeric_id)}</code></td>
      <td>${isDone(r) ? '<span class="badge green">Ja</span>' : '<span class="badge grey">Nee</span>'}</td>
      <td>${score(r)}</td>
      <td>${fmtDate(r.first_judged_at)}</td>
      <td>${fmtDate(r.last_judged_at)}</td>
      <td>
        <form method="POST" action="/portal/${esc(token)}/toggle/${r.id}" style="display:inline">
          <input type="hidden" name="allow_retrain" value="${r.allow_retrain ? '0' : '1'}">
          <button class="btn-sm${r.allow_retrain ? ' on' : ''}" title="Herhaling ${r.allow_retrain ? 'uitschakelen' : 'inschakelen'}">
            ${r.allow_retrain ? '🔓 Aan' : '🔒 Uit'}
          </button>
        </form>
      </td>
    </tr>`).join('');

  const done   = users.filter(r => isDone(r)).length;
  const busy   = users.filter(r => !isDone(r) && r.done_count > 0).length;
  const notyet = users.filter(r => r.done_count === 0).length;

  return `<!doctype html>
<html lang="nl">
<head>
  <meta charset="utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="referrer" content="no-referrer" />
  <title>Portaal — ${esc(org.name)}</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: system-ui, sans-serif; background: #f4f6f9; color: #1a1a2e; padding: 2rem 1rem; }
    .wrap { max-width: 900px; margin: 0 auto; }
    .topbar { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 1.5rem; }
    h1 { font-size: 1.3rem; }
    .sub { font-size: .85rem; color: #6b7280; margin-top: .3rem; }
    .btn-export { padding: .45rem 1rem; background: #2563eb; color: #fff;
                  text-decoration: none; border-radius: 6px; font-size: .9rem; white-space: nowrap; }
    .btn-export:hover { background: #1d4ed8; }
    .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px,1fr));
             gap: 1rem; margin-bottom: 1.5rem; }
    .stat { background: #fff; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,.06);
            padding: 1rem 1.25rem; }
    .stat .val { font-size: 1.9rem; font-weight: 700; color: #2563eb; }
    .stat .lbl { font-size: .8rem; color: #6b7280; margin-top: .2rem; }
    .section { background: #fff; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,.07); padding: 1.5rem; }
    h2 { font-size: 1rem; color: #374151; margin-bottom: 1rem; }
    table { width: 100%; border-collapse: collapse; font-size: .88rem; }
    th { text-align: left; padding: .5rem .75rem; border-bottom: 2px solid #e5e7eb; color: #6b7280; font-weight: 600; }
    td { padding: .5rem .75rem; border-bottom: 1px solid #f3f4f6; vertical-align: middle; }
    tr:last-child td { border-bottom: none; }
    .badge { padding: .15rem .5rem; border-radius: 4px; font-size: .8rem; font-weight: 600; }
    .badge.green { background: #dcfce7; color: #166534; }
    .badge.grey  { background: #f3f4f6; color: #6b7280; }
    .btn-sm { padding: .25rem .65rem; border: 1.5px solid #d1d5db; border-radius: 5px;
              background: #fff; cursor: pointer; font-size: .8rem; }
    .btn-sm.on { border-color: #2563eb; color: #2563eb; }
    .btn-sm:hover { background: #f3f4f6; }
    ${isExpired(org) ? '.expired{background:#fff7ed;border:1px solid #fed7aa;color:#c2410c;border-radius:6px;padding:.75rem 1rem;margin-bottom:1.5rem;}' : ''}
  </style>
</head>
<body>
<div class="wrap">
  <div class="topbar">
    <div>
      <h1>🛡️ ${esc(org.name)}</h1>
      <p class="sub">Trainingsportaal · Geldig tot ${fmtDate(org.valid_until)} · ${org.difficulty === 'advanced' ? 'Gevorderd' : 'Normaal'}</p>
    </div>
    <a class="btn-export" href="/portal/${esc(token)}/export.csv">⬇ CSV exporteren</a>
  </div>

  ${isExpired(org) ? '<div class="expired">⚠️ De geldigheidsdatum van deze organisatie is verstreken.</div>' : ''}

  <div class="stats">
    <div class="stat"><div class="val">${users.length}</div><div class="lbl">Deelnemers</div></div>
    <div class="stat"><div class="val">${done}</div><div class="lbl">Afgerond</div></div>
    <div class="stat"><div class="val">${busy}</div><div class="lbl">Bezig</div></div>
    <div class="stat"><div class="val">${notyet}</div><div class="lbl">Nog niet gestart</div></div>
  </div>

  <div class="section">
    <h2>Resultaten per deelnemer</h2>
    ${users.length === 0
      ? '<p style="color:#9ca3af">Nog geen deelnemers aangemaakt.</p>'
      : `<table>
          <thead><tr>
            <th>ID</th><th>Afgerond</th><th>Score</th>
            <th>Eerste login</th><th>Laatste activiteit</th><th>Herhaling</th>
          </tr></thead>
          <tbody>${userRows}</tbody>
        </table>`}
  </div>
</div>
</body>
</html>`;
}

module.exports = { loginRouter, portalRouter };
