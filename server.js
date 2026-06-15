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

// Render (en vergelijkbare hosts) zetten één reverse proxy vóór de app en
// sturen het echte client-IP mee in X-Forwarded-For. Zonder trust proxy
// ziet Express alleen het proxy-IP: rate limiting zou dan alle bezoekers
// als één gebruiker tellen (en express-rate-limit weigert dat terecht),
// en secure cookies zouden niet werken omdat req.secure false blijft.
// Waarde 1 = vertrouw precies één proxy-hop, niet willekeurige headers.
app.set('trust proxy', 1);

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

// Analytics: page_view event — fire-and-forget, never blocks the response.
// Admin-sessies tellen niet mee: het gaat om écht bezoek aan de training,
// niet om de beheerder die zelf rondklikt.
app.get('/', (req, _res, next) => {
  if (!req.session?.admin) {
    db.query(
      `INSERT INTO analytics_events (event) VALUES ('page_view')`
    ).catch(() => {});
  }
  next();
});

app.get(['/', '/index.html'], sendIndex);

// OG-kaart: 1200×630 SVG geserveerd als image/svg+xml.
// Zoekmachines en social-media-crawlers accepteren SVG als og:image.
app.get('/img/og-card.png', (_req, res) => {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#1a1a2e"/>
      <stop offset="100%" stop-color="#16213e"/>
    </linearGradient>
  </defs>
  <rect width="1200" height="630" fill="url(#bg)"/>
  <rect x="0" y="0" width="8" height="630" fill="#2563eb"/>
  <text x="80" y="220" font-family="system-ui,sans-serif" font-size="80" font-weight="700" fill="#ffffff">🛡️ Veilig Online</text>
  <text x="80" y="310" font-family="system-ui,sans-serif" font-size="44" fill="#93c5fd">Leer phishing herkennen in 10 minuten</text>
  <text x="80" y="390" font-family="system-ui,sans-serif" font-size="32" fill="#64748b">Gratis training · NL · EN · FR · DE</text>
  <rect x="80" y="450" width="260" height="60" rx="8" fill="#2563eb"/>
  <text x="210" y="489" font-family="system-ui,sans-serif" font-size="26" font-weight="600" fill="#ffffff" text-anchor="middle">Start de training →</text>
</svg>`;
  res.setHeader('Cache-Control', 'public, max-age=86400');
  res.type('image/svg+xml').send(svg);
});

// robots.txt: vervang __CANONICAL__ net als in index.html
const ROBOTS_TXT = fs.readFileSync(path.join(PUBLIC_DIR, 'robots.txt'), 'utf8')
  .replace('__CANONICAL__', CANONICAL);
app.get('/robots.txt', (_req, res) =>
  res.type('text/plain').send(ROBOTS_TXT));

// sitemap.xml: éénpagina-SPA met taalvarianten
app.get('/sitemap.xml', (_req, res) => {
  if (!CANONICAL) return res.status(404).end();
  const langs = ['nl', 'nl-BE', 'en', 'fr', 'fr-BE', 'de'];
  const urls = langs.map(l => `
  <url>
    <loc>${CANONICAL}?lang=${l}</loc>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>`).join('');
  res.type('application/xml').send(
    `<?xml version="1.0" encoding="UTF-8"?>\n` +
    `<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n` +
    `  <url><loc>${CANONICAL}</loc><changefreq>monthly</changefreq><priority>1.0</priority></url>` +
    urls + '\n</urlset>'
  );
});

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
const QR_TAGS = new Set(['mfa', 'tikkie', 'paypal', 'payconiq']);
const QR_LANGS = new Set(['nl', 'en', 'fr', 'de']);

function qrSessionId(req) {
  // Enterprise: sessiecookie gaat mee met het <img>-request.
  // Publiek: de frontend plakt ?s=<vo_session> aan de afbeeldings-URL.
  if (req.session?.enterpriseSessionId) return req.session.enterpriseSessionId;
  const s = String(req.query.s || '');
  return /^[a-zA-Z0-9_-]{8,64}$/.test(s) ? s : null;
}

// Basistaal van de oefening (nl-BE → nl, fr-BE → fr) voor de lespagina.
function qrLang(raw) {
  const base = String(raw || '').split('-')[0];
  return QR_LANGS.has(base) ? base : 'nl';
}

app.get('/qr-img/:tag', async (req, res) => {
  const tag = req.params.tag;
  if (!QR_TAGS.has(tag)) return res.status(404).end();
  const sid = qrSessionId(req);
  const lang = qrLang(req.query.l);
  const base = CANONICAL || `https://${req.get('host')}`;
  const target = base + '/qr?t=' + tag + '&l=' + lang
    + (sid ? '&s=' + encodeURIComponent(sid) : '');
  try {
    const svg = await QRCode.toString(target, { type: 'svg', errorCorrectionLevel: 'M', margin: 0 });
    res.set('Cache-Control', 'no-store').type('image/svg+xml').send(svg);
  } catch (err) {
    console.error('[qr-img]', err);
    res.status(500).end();
  }
});

// Teksten van de QR-lespagina per taal.
const QR_PAGE_I18N = {
  nl: {
    title: 'U scande een QR-code uit een verdachte e-mail',
    h1: 'U scande zojuist een QR-code uit een verdachte e-mail',
    warnStrong: 'Dit was een oefening.',
    warnRest: 'In een echte aanval had hier een nep-betaalpagina of nep-inlogpagina gestaan die uw gegevens steelt.',
    body: 'Een QR-code in een e-mail is als een link die u niet kunt lezen: u ziet pas waar hij naartoe gaat als het te laat is. E-mailfilters kunnen er ook niet in kijken — daarom gebruiken oplichters ze steeds vaker.',
    remember: 'Onthoud:',
    li1: 'Scan nooit een QR-code uit een onverwachte e-mail',
    li2: 'Verwacht u echt iets? Open dan zelf de app of website',
    li3: 'Echte organisaties dwingen u nooit via een QR-code in te loggen of te betalen',
    btn: 'Naar de phishing-training →',
  },
  en: {
    title: 'You scanned a QR code from a suspicious email',
    h1: 'You just scanned a QR code from a suspicious email',
    warnStrong: 'This was an exercise.',
    warnRest: 'In a real attack, this would have been a fake payment or login page stealing your details.',
    body: 'A QR code in an email is a link you cannot read: you only see where it leads when it is too late. Email filters cannot look inside it either — which is why scammers use them more and more.',
    remember: 'Remember:',
    li1: 'Never scan a QR code from an unexpected email',
    li2: 'Expecting something real? Open the app or website yourself',
    li3: 'Real organisations never force you to log in or pay via a QR code',
    btn: 'To the phishing training →',
  },
  fr: {
    title: 'Vous avez scanné un QR code d’un e-mail suspect',
    h1: 'Vous venez de scanner un QR code provenant d’un e-mail suspect',
    warnStrong: 'C’était un exercice.',
    warnRest: 'Dans une vraie attaque, vous seriez arrivé(e) sur une fausse page de paiement ou de connexion qui vole vos données.',
    body: 'Un QR code dans un e-mail est un lien que vous ne pouvez pas lire : vous ne voyez où il mène que lorsqu’il est trop tard. Les filtres e-mail ne peuvent pas non plus l’inspecter — c’est pourquoi les escrocs les utilisent de plus en plus.',
    remember: 'À retenir :',
    li1: 'Ne scannez jamais un QR code d’un e-mail inattendu',
    li2: 'Vous attendez vraiment quelque chose ? Ouvrez vous-même l’application ou le site',
    li3: 'Les vraies organisations ne vous forcent jamais à vous connecter ou payer via un QR code',
    btn: 'Vers la formation anti-phishing →',
  },
  de: {
    title: 'Sie haben einen QR-Code aus einer verdächtigen E-Mail gescannt',
    h1: 'Sie haben soeben einen QR-Code aus einer verdächtigen E-Mail gescannt',
    warnStrong: 'Dies war eine Übung.',
    warnRest: 'Bei einem echten Angriff wäre hier eine gefälschte Zahlungs- oder Anmeldeseite gewesen, die Ihre Daten stiehlt.',
    body: 'Ein QR-Code in einer E-Mail ist ein Link, den Sie nicht lesen können: Sie sehen erst, wohin er führt, wenn es zu spät ist. Auch E-Mail-Filter können nicht hineinschauen — deshalb nutzen Betrüger sie immer häufiger.',
    remember: 'Merken Sie sich:',
    li1: 'Scannen Sie nie einen QR-Code aus einer unerwarteten E-Mail',
    li2: 'Erwarten Sie wirklich etwas? Öffnen Sie selbst die App oder Website',
    li3: 'Echte Organisationen zwingen Sie nie, sich über einen QR-Code anzumelden oder zu zahlen',
    btn: 'Zum Phishing-Training →',
  },
};

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
  const lang = qrLang(req.query.l);
  const T = QR_PAGE_I18N[lang];
  res.set('Cache-Control', 'no-store');
  res.type('html').send(`<!doctype html>
<html lang="${lang}">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="robots" content="noindex" />
  <title>${T.title}</title>
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
  </style>
</head>
<body>
  <div class="card">
    <div class="emoji">🎣</div>
    <h1>${T.h1}</h1>
    <div class="warn"><strong>${T.warnStrong}</strong> ${T.warnRest}</div>
    <p>${T.body}</p>
    <p><strong>${T.remember}</strong></p>
    <ul>
      <li>${T.li1}</li>
      <li>${T.li2}</li>
      <li>${T.li3}</li>
    </ul>
    <a class="btn" href="${CANONICAL || '/'}">${T.btn}</a>
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
