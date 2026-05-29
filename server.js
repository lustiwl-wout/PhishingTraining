require('dotenv').config();
const fs = require('node:fs');
const path = require('node:path');
const express = require('express');
const rateLimit = require('express-rate-limit');
const session = require('express-session');
const apiRouter = require('./routes/api');
const adminRouter = require('./routes/admin');
const { loginRouter: enterpriseRouter, portalRouter } = require('./routes/enterprise');
const { initDbWithRetry } = require('./db/init');

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

app.use(session({
  secret: process.env.SESSION_SECRET || 'verander-dit-in-productie',
  resave: false,
  saveUninitialized: false,
  cookie: { httpOnly: true, sameSite: 'lax', maxAge: 8 * 60 * 60 * 1000 },
}));

// ── Subdomain routing ──────────────────────────────────────────────────────
// test.seethephish.com/  →  if not logged in: show enterprise login for "test"
//                           if logged in:     serve the SPA (training) as normal
// All other paths (/api/*, /css/*, /e/*, etc.) are never rewritten so the
// same app works correctly on the subdomain after login.
app.use((req, res, next) => {
  if (!BASE_HOST) return next();
  const host = (req.headers.host || '').split(':')[0].toLowerCase();
  if (host === BASE_HOST || host === `www.${BASE_HOST}`) return next();
  if (!host.endsWith(`.${BASE_HOST}`)) return next();

  const sub = host.slice(0, -(BASE_HOST.length + 1));
  if (!sub || sub.includes('.')) return next(); // ignore deeper subdomains

  // Only rewrite the bare root while not authenticated; everything else
  // (static assets, /api/*, /e/slug/login, etc.) passes straight through.
  if (req.method === 'GET' && (req.path === '/' || req.path === '/index.html')) {
    if (!req.session?.enterpriseOrgUserId) {
      req.url = `/e/${encodeURIComponent(sub)}`;
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
// Directe aanroepen (curl, scripts) hebben geen Origin/Referer en worden geblokkeerd.
function sameOriginOnly(req, res, next) {
  const origin = req.headers['origin'] || req.headers['referer'] || '';
  const host = req.headers['host'] || '';
  // Laat requests door als: geen Origin (server-to-server op zelfde machine),
  // of Origin/Referer bevat dezelfde host als de request.
  if (!origin || origin.includes(host)) return next();
  return res.status(403).json({ error: 'toegang geweigerd' });
}

// Beperk het aantal API-requests per IP: max 120 per minuut voor lees-endpoints,
// max 30 per minuut voor schrijf-endpoints (POST).
const readLimit = rateLimit({ windowMs: 60_000, max: 120, standardHeaders: true, legacyHeaders: false });
const writeLimit = rateLimit({ windowMs: 60_000, max: 30, standardHeaders: true, legacyHeaders: false });

// Beheer (/admin)
app.use('/admin', adminRouter);

// Enterprise login (/e/:slug) en klantportaal (/portal/:token)
app.use('/e', enterpriseRouter);
app.use('/portal', portalRouter);

// API
app.use('/api', sameOriginOnly);
app.use('/api', (req, res, next) => req.method === 'GET' ? readLimit(req, res, next) : writeLimit(req, res, next));
app.use('/api', apiRouter);

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
