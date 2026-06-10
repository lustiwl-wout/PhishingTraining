require('dotenv').config();
const fs = require('node:fs');
const path = require('node:path');
const express = require('express');
const rateLimit = require('express-rate-limit');
const session = require('express-session');
const PgSession = require('connect-pg-simple')(session);
const apiRouter = require('./routes/api');
const adminRouter = require('./routes/admin');
const { loginRouter: enterpriseRouter, portalRouter } = require('./routes/enterprise');
const { initDbWithRetry } = require('./db/init');
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;
const PUBLIC_DIR = path.join(__dirname, 'public');

// Cache-bust token: alle <link>/<script> die "?v=__VER__" gebruiken krijgen
// een unieke versie per deploy/herstart, zodat browsers verse CSS/JS pakken.
const ASSET_VER = String(Date.now());
const CANONICAL = process.env.CANONICAL_URL || '';
const INDEX_HTML = fs.readFileSync(path.join(PUBLIC_DIR, 'index.html'), 'utf8')
  .replaceAll('__VER__', ASSET_VER)
  .replaceAll('__CANONICAL__', CANONICAL);

// BASE_HOST: e.g. "seethephish.com" — used for subdomain routing.
// Strip protocol and trailing slash if someone sets the full URL.
const BASE_HOST = (process.env.BASE_HOST || '')
  .toLowerCase().replace(/^https?:\/\//, '').replace(/\/$/, '');

app.disable('x-powered-by');
app.use(express.json({ limit: '64kb' }));

// In productie is een echte SESSION_SECRET verplicht — met de hardcoded
// fallback zou iedereen sessie-cookies kunnen vervalsen.
if (process.env.NODE_ENV === 'production' && !process.env.SESSION_SECRET) {
  console.error('[server] FATAL: SESSION_SECRET ontbreekt. Zet deze in de environment variables.');
  process.exit(1);
}

// Sessies in Postgres i.p.v. in-memory, zodat ingelogde gebruikers niet
// uitgelogd raken bij elke deploy/herstart. Tabel wordt automatisch aangemaakt.
app.use(session({
  store: process.env.DATABASE_URL
    ? new PgSession({ pool: db.pool, tableName: 'user_sessions', createTableIfMissing: true })
    : undefined, // zonder DB (lokaal testen): val terug op MemoryStore
  secret: process.env.SESSION_SECRET || 'alleen-voor-lokaal-ontwikkelen',
  resave: false,
  saveUninitialized: false,
  cookie: { httpOnly: true, sameSite: 'lax', maxAge: 8 * 60 * 60 * 1000 },
}));

// ── Subdomain routing ──────────────────────────────────────────────────────
// test.seethephish.com/  →  if not logged in: show enterprise login for "test"
//                           if logged in:     serve the SPA (training) as normal
// All other paths (/api/*, /css/*, etc.) are never rewritten so the
// same app works correctly on the subdomain after login.
app.use((req, res, next) => {
  if (!BASE_HOST) return next();
  const host = (req.headers.host || '').split(':')[0].toLowerCase();
  if (host === BASE_HOST || host === `www.${BASE_HOST}`) return next();
  if (!host.endsWith(`.${BASE_HOST}`)) return next();

  const sub = host.slice(0, -(BASE_HOST.length + 1));
  if (!sub || sub.includes('.')) return next(); // ignore deeper subdomains

  // Only rewrite the bare root while not authenticated; everything else
  // (static assets, /api/*, /slug/login, etc.) passes straight through.
  if (req.method === 'GET' && (req.path === '/' || req.path === '/index.html')) {
    if (!req.session?.enterpriseOrgUserId) {
      req.url = `/${encodeURIComponent(sub)}`;
    }
  }
  next();
});
// ──────────────────────────────────────────────────────────────────────────

// HTML zelf nooit cachen (kort), assets daarentegen lang (URL is versie-gestempeld).
function sendIndex(_req, res) {
  res.set('Cache-Control', 'no-store');
  res.type('html').send(INDEX_HTML);
}
app.get(['/', '/index.html'], sendIndex);

// Statische frontend (CSS/JS/afbeeldingen)
app.use(express.static(PUBLIC_DIR, {
  extensions: ['html'],
  maxAge: process.env.NODE_ENV === 'production' ? '1h' : 0,
}));

// Sta alleen requests toe die afkomstig zijn van de eigen site.
// Strikte host-vergelijking: "evil.com/onze-site.nl" of "onze-site.nl.evil.com"
// komen er niet doorheen. Geen Origin/Referer (bv. same-origin fetch in
// sommige browsers, of server-to-server health checks) laten we door.
function sameOriginOnly(req, res, next) {
  const raw = req.headers['origin'] || req.headers['referer'] || '';
  if (!raw) return next();
  const host = (req.headers['host'] || '').toLowerCase();
  try {
    if (new URL(raw).host.toLowerCase() === host) return next();
  } catch (_) { /* ongeldige URL → weigeren */ }
  return res.status(403).json({ error: 'toegang geweigerd' });
}

// Beperk het aantal API-requests per IP: max 120 per minuut voor lees-endpoints,
// max 30 per minuut voor schrijf-endpoints (POST).
const readLimit = rateLimit({ windowMs: 60_000, max: 120, standardHeaders: true, legacyHeaders: false });
const writeLimit = rateLimit({ windowMs: 60_000, max: 30, standardHeaders: true, legacyHeaders: false });
// Strenge limiet voor login-pogingen (brute-force bescherming):
// max 10 per kwartier per IP, alleen geteld op POST.
const loginLimit = rateLimit({
  windowMs: 15 * 60_000, max: 10, standardHeaders: true, legacyHeaders: false,
  skip: (req) => req.method !== 'POST',
});

// Beheer (/admin)
app.use('/admin/login', loginLimit);
app.use('/admin', adminRouter);

// Klantportaal (/portal/:token)
app.use('/portal', portalRouter);

// API
app.use('/api', sameOriginOnly);
app.use('/api', (req, res, next) => req.method === 'GET' ? readLimit(req, res, next) : writeLimit(req, res, next));
app.use('/api', apiRouter);

// ── QR-tracking (quishing-oefening) ────────────────────────────────────────
// De oefenmails tonen <img src="/qr-img/:tag">. We genereren de QR per sessie
// zodat een scan met de telefoon herleidbaar is naar de trainingssessie.
const QRCode = require('qrcode');
const QR_TAGS = new Set(['mfa', 'tikkie']);

function qrSessionId(req) {
  // Enterprise: sessiecookie gaat mee met het <img>-request.
  // Publiek: de frontend plakt ?s=<vo_session> aan de afbeeldings-URL.
  if (req.session?.enterpriseSessionId) return req.session.enterpriseSessionId;
  const s = String(req.query.s || '');
  return /^[a-zA-Z0-9_-]{8,64}$/.test(s) ? s : null;
}

app.get('/qr-img/:tag', async (req, res) => {
  const tag = req.params.tag;
  if (!QR_TAGS.has(tag)) return res.status(404).end();
  const sid = qrSessionId(req);
  const base = CANONICAL || `https://${req.get('host')}`;
  const target = base + '/qr?t=' + tag + (sid ? '&s=' + encodeURIComponent(sid) : '');
  try {
    const svg = await QRCode.toString(target, { type: 'svg', errorCorrectionLevel: 'M', margin: 0 });
    res.set('Cache-Control', 'no-store').type('image/svg+xml').send(svg);
  } catch (err) {
    console.error('[qr-img]', err);
    res.status(500).end();
  }
});

// Leermoment voor wie de QR-code uit de oefenmail écht scant.
// Mobiel-eerst: deze pagina wordt vrijwel altijd op een telefoon geopend.
app.get('/qr', (req, res) => {
  // Scan registreren (best effort — de lespagina komt er hoe dan ook).
  const tag = String(req.query.t || '');
  const sid = String(req.query.s || '');
  if (QR_TAGS.has(tag) && /^[a-zA-Z0-9_-]{8,64}$/.test(sid)) {
    db.query(
      `INSERT INTO qr_scans (session_id, tag) VALUES ($1, $2)
       ON CONFLICT (session_id, tag) DO NOTHING`,
      [sid, tag]
    ).catch((err) => console.error('[qr] scan niet opgeslagen:', err.message));
  }
  res.set('Cache-Control', 'no-store');
  res.type('html').send(`<!doctype html>
<html lang="nl">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="robots" content="noindex" />
  <title>U scande een QR-code uit een verdachte e-mail</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: system-ui, sans-serif; background: #f4f6f9; color: #1a2332;
           display: flex; align-items: center; justify-content: center;
           min-height: 100vh; padding: 1rem; }
    .card { background: #fff; border-radius: 14px; box-shadow: 0 4px 24px rgba(0,0,0,.10);
            padding: 2rem 1.5rem; width: 100%; max-width: 460px; }
    .emoji { font-size: 2.6rem; }
    h1 { font-size: 1.3rem; margin: .75rem 0 .5rem; line-height: 1.3; }
    p { line-height: 1.6; margin-bottom: .9rem; font-size: 1rem; }
    .warn { background: #fef2f2; border-left: 4px solid #dc2626; padding: .75rem 1rem;
            border-radius: 6px; margin-bottom: 1rem; }
    ul { padding-left: 1.3rem; line-height: 1.7; margin-bottom: 1rem; }
    a.btn { display: block; text-align: center; background: #2563eb; color: #fff;
            text-decoration: none; padding: .8rem; border-radius: 8px; font-weight: 600; }
    .en { color: #6b7280; font-size: .85rem; margin-top: 1rem; }
  </style>
</head>
<body>
  <div class="card">
    <div class="emoji">🎣</div>
    <h1>U scande zojuist een QR-code uit een verdachte e-mail</h1>
    <div class="warn"><strong>Dit was een oefening.</strong> In een echte aanval had hier
    een nep-betaalpagina of nep-inlogpagina gestaan die uw gegevens steelt.</div>
    <p>Een QR-code in een e-mail is als een link die u niet kunt lezen:
    u ziet pas waar hij naartoe gaat als het te laat is. E-mailfilters kunnen
    er ook niet in kijken — daarom gebruiken oplichters ze steeds vaker.</p>
    <p><strong>Onthoud:</strong></p>
    <ul>
      <li>Scan nooit een QR-code uit een onverwachte e-mail</li>
      <li>Verwacht u echt iets? Open dan zelf de app of website</li>
      <li>Echte organisaties dwingen u nooit via een QR-code in te loggen of te betalen</li>
    </ul>
    <a class="btn" href="${CANONICAL || '/'}">Naar de gratis phishing-training →</a>
    <p class="en">You scanned a QR code from a suspicious email — this was a training
    exercise. Never scan QR codes from unexpected emails.</p>
  </div>
</body>
</html>`);
});

// Enterprise login (/:slug, /:slug/login, /logout) — na statisch + API
// zodat /api/*, /admin/*, /portal/* nooit worden onderschept.
app.use('/:slug/login', loginLimit);
app.use(enterpriseRouter);

// Fallback voor onbekende routes -> SPA-startpagina
app.get('*', sendIndex);

// Centrale foutafhandeling
app.use((err, _req, res, _next) => {
  console.error('[server]', err);
  res.status(500).json({ error: 'er ging iets mis op de server' });
});

app.listen(PORT, () => {
  console.log(`[server] Veilig Online luistert op poort ${PORT}`);

  // Auto-init de database (idempotent). Op Render Free hebben we geen
  // Shell, dus dit is de manier om schema + seed binnen te krijgen.
  // Kan via SKIP_DB_INIT=1 worden uitgezet.
  if (process.env.SKIP_DB_INIT === '1') {
    console.log('[server] SKIP_DB_INIT=1 — database-init overgeslagen.');
    return;
  }
  initDbWithRetry().catch((err) => {
    console.error('[server] init-db onverwachte fout:', err);
  });
});
