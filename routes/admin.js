const express = require('express');
const db = require('../db');

const router = express.Router();

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
router.post('/login', express.urlencoded({ extended: false }), (req, res) => {
  const { username, password } = req.body || {};
  const validUser = process.env.ADMIN_USER;
  const validPass = process.env.ADMIN_PASSWORD;

  if (!validUser || !validPass) {
    return res.type('html').send(loginPage('ADMIN_USER en ADMIN_PASSWORD zijn niet ingesteld op de server.'));
  }
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

// GET /admin
router.get('/', requireLogin, async (req, res, next) => {
  try {
    const [quiz, inbox, recent] = await Promise.all([
      db.query(`
        SELECT
          COUNT(*)::int                                                          AS pogingen,
          COUNT(*) FILTER (WHERE finished_at IS NOT NULL)::int                  AS afgerond,
          COALESCE(ROUND(AVG(
            CASE WHEN finished_at IS NOT NULL AND total > 0
                 THEN correct::numeric / total * 100 END
          )), 0)::int                                                            AS gemiddeld_pct
        FROM quiz_attempts
      `),
      db.query(`
        SELECT
          COUNT(*)::int                                                          AS oordelen,
          COUNT(*) FILTER (WHERE is_correct)::int                               AS correct,
          COUNT(*) FILTER (WHERE clicked_link)::int                             AS link_geklikt
        FROM inbox_judgments
      `),
      db.query(`
        SELECT
          TO_CHAR(a.started_at AT TIME ZONE 'Europe/Amsterdam', 'DD-MM-YYYY HH24:MI') AS tijdstip,
          a.total,
          a.correct,
          CASE WHEN a.finished_at IS NOT NULL THEN 'Afgerond' ELSE 'Bezig' END  AS status
        FROM quiz_attempts a
        ORDER BY a.started_at DESC
        LIMIT 20
      `),
    ]);

    res.type('html').send(dashboardPage(quiz.rows[0], inbox.rows[0], recent.rows));
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
    <form method="POST" action="/admin/login">
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

function dashboardPage(quiz, inbox, recent) {
  const rows = recent.map(r => `
    <tr>
      <td>${r.tijdstip}</td>
      <td>${r.status}</td>
      <td>${r.total}</td>
      <td>${r.total > 0 ? Math.round(r.correct / r.total * 100) : '—'}%</td>
    </tr>`).join('');

  return `<!doctype html>
<html lang="nl">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Beheer · Veilig Online</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: system-ui, sans-serif; background: #f4f6f9; color: #1a1a2e; padding: 2rem 1rem; }
    .topbar { display: flex; justify-content: space-between; align-items: center; max-width: 860px; margin: 0 auto 2rem; }
    h1 { font-size: 1.3rem; }
    form button { padding: .4rem .9rem; background: #e5e7eb; border: none; border-radius: 6px; cursor: pointer; font-size: .9rem; }
    form button:hover { background: #d1d5db; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 1rem; max-width: 860px; margin: 0 auto 2rem; }
    .stat { background: #fff; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,.07); padding: 1.25rem 1.5rem; }
    .stat .val { font-size: 2rem; font-weight: 700; color: #2563eb; }
    .stat .lbl { font-size: .85rem; color: #6b7280; margin-top: .25rem; }
    .section { max-width: 860px; margin: 0 auto; background: #fff; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,.07); padding: 1.5rem; }
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
    <form method="POST" action="/admin/logout"><button type="submit">Uitloggen</button></form>
  </div>

  <div class="grid">
    <div class="stat"><div class="val">${quiz.pogingen}</div><div class="lbl">Quiz gestart</div></div>
    <div class="stat"><div class="val">${quiz.afgerond}</div><div class="lbl">Quiz afgerond</div></div>
    <div class="stat"><div class="val">${quiz.gemiddeld_pct}%</div><div class="lbl">Gemiddelde score (quiz)</div></div>
    <div class="stat"><div class="val">${inbox.oordelen}</div><div class="lbl">Inbox beoordeeld</div></div>
    <div class="stat"><div class="val">${inbox.correct}</div><div class="lbl">Inbox correct</div></div>
    <div class="stat"><div class="val">${inbox.link_geklikt}</div><div class="lbl">Link geklikt (inbox)</div></div>
  </div>

  <div class="section">
    <h2>Laatste 20 quiz-sessies</h2>
    ${recent.length === 0 ? '<p style="color:#9ca3af">Nog geen sessies.</p>' : `
    <table>
      <thead><tr><th>Tijdstip</th><th>Status</th><th>Vragen</th><th>Score</th></tr></thead>
      <tbody>${rows}</tbody>
    </table>`}
  </div>
</body>
</html>`;
}

module.exports = router;
