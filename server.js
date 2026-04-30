require('dotenv').config();
const fs = require('node:fs');
const path = require('node:path');
const express = require('express');
const apiRouter = require('./routes/api');
const { initDbWithRetry } = require('./db/init');

const app = express();
const PORT = process.env.PORT || 3000;
const PUBLIC_DIR = path.join(__dirname, 'public');

// Cache-bust token: alle <link>/<script> die "?v=__VER__" gebruiken krijgen
// een unieke versie per deploy/herstart, zodat browsers verse CSS/JS pakken.
const ASSET_VER = String(Date.now());
const INDEX_HTML = fs.readFileSync(path.join(PUBLIC_DIR, 'index.html'), 'utf8')
  .replaceAll('__VER__', ASSET_VER);

app.disable('x-powered-by');
app.use(express.json({ limit: '64kb' }));

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

// API
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
